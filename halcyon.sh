#!/usr/bin/env bash


set -o nounset
set -o pipefail

declare self_dir
self_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )
source "${self_dir}/src/lib/curl.sh"
source "${self_dir}/src/lib/expect.sh"
source "${self_dir}/src/lib/log.sh"
source "${self_dir}/src/lib/s3.sh"
source "${self_dir}/src/lib/tar.sh"
source "${self_dir}/src/lib/tools.sh"
source "${self_dir}/src/app.sh"
source "${self_dir}/src/cabal.sh"
source "${self_dir}/src/cache.sh"
source "${self_dir}/src/constraints.sh"
source "${self_dir}/src/ghc.sh"
source "${self_dir}/src/sandbox.sh"
source "${self_dir}/src/transfer.sh"




function set_default_vars () {
	! (( ${HALCYON_DEFAULTS_SET:-0} )) || return 0
	export HALCYON_DEFAULTS_SET=1

	export HALCYON_DIR="${HALCYON_DIR:-/app/.halcyon}"
	export HALCYON_CONFIG_DIR="${HALCYON_CONFIG_DIR:-${HALCYON_DIR}/config}"
	export HALCYON_INSTALL_DIR="${HALCYON_INSTALL_DIR:-${HALCYON_DIR}/install}"
	export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon/cache}"

	export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"
	export HALCYON_FORCE_FAIL_INSTALL="${HALCYON_FORCE_FAIL_INSTALL:-0}"
	export HALCYON_DEPENDENCIES_ONLY="${HALCYON_DEPENDENCIES_ONLY:-0}"
	export HALCYON_PREBUILT_ONLY="${HALCYON_PREBUILT_ONLY:-0}"
	export HALCYON_FORCE_GHC_VERSION="${HALCYON_FORCE_GHC_VERSION:-}"
	export HALCYON_CUT_GHC="${HALCYON_CUT_GHC:-0}"
	export HALCYON_FORCE_CABAL_VERSION="${HALCYON_FORCE_CABAL_VERSION:-}"
	export HALCYON_FORCE_CABAL_UPDATE="${HALCYON_FORCE_CABAL_UPDATE:-0}"

	export HALCYON_CUSTOMIZE_SANDBOX_SCRIPT="${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT:-}"

	export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
	export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
	export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
	export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"

	export HALCYON_SILENT="${HALCYON_SILENT:-0}"

	export PATH="${HALCYON_DIR}/ghc/bin:${PATH}"
	export PATH="${HALCYON_DIR}/cabal/bin:${PATH}"
	export PATH="${HALCYON_DIR}/sandbox/bin:${PATH}"
	export PATH="${HALCYON_INSTALL_DIR}/bin:${PATH}"
	export LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LD_LIBRARY_PATH:-}"

	export LANG="${LANG:-en_US.UTF-8}"
}


set_default_vars




function set_config_vars () {
	expect_vars HALCYON_CONFIG_DIR

	log 'Setting config vars'

	local ignored_pattern secret_pattern
	ignored_pattern='GIT_DIR|PATH|LIBRARY_PATH|LD_LIBRARY_PATH|LD_PRELOAD'
	secret_pattern='HALCYON_AWS_SECRET_ACCESS_KEY|DATABASE_URL|.*_POSTGRESQL_.*_URL'

	local var
	for var in $(
		find_spaceless "${HALCYON_CONFIG_DIR}" -maxdepth 1 |
		sed "s:^${HALCYON_CONFIG_DIR}/::" |
		sort_naturally |
		filter_not_matching "^(${ignored_pattern})$"
	); do
		local value
		value=$( match_exactly_one <"${HALCYON_CONFIG_DIR}/${var}" ) || die
		if filter_matching "^(${secret_pattern})$" <<<"${var}" |
			match_exactly_one >'/dev/null'
		then
			log_indent "${var} (secret)"
		else
			log_indent "${var}=${value}"
		fi
		export "${var}=${value}" || die
	done
}




function halcyon_install () {
	expect_vars HALCYON_CONFIG_DIR HALCYON_FORCE_FAIL_INSTALL HALCYON_DEPENDENCIES_ONLY

	while (( $# )); do
		case "$1" in
		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;
		'--config-dir='*)
			export HALCYON_CONFIG_DIR="${1#*=}";;
		'--install-dir='*)
			export HALCYON_INSTALL_DIR="${1#*=}";;
		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;

		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;
		'--force-fail-install')
			export HALCYON_FORCE_FAIL_INSTALL=1;;
		'--dependencies-only');&
		'--dep-only');&
		'--only-dependencies');&
		'--only-dep')
			export HALCYON_DEPENDENCIES_ONLY=1;;
		'--prebuilt-only');&
		'--pre-only');&
		'--only-prebuilt');&
		'--only-pre')
			export HALCYON_PREBUILT_ONLY=1;;
		'--force-ghc-version='*)
			export HALCYON_FORCE_GHC_VERSION="${1#*=}";;
		'--cut-ghc')
			export HALCYON_CUT_GHC=1;;
		'--force-cabal-version='*)
			export HALCYON_FORCE_CABAL_VERSION="${1#*=}";;
		'--force-cabal-update')
			export HALCYON_FORCE_CABAL_UPDATE=1;;

		'--customize-sandbox-script='*);&
		'--custom-sandbox-script='*)
			export HALCYON_CUSTOMIZE_SANDBOX_SCRIPT="${1#*=}";;

		'--aws-access-key-id='*)
			export HALCYON_AWS_ACCESS_KEY_ID="${1#*=}";;
		'--aws-secret-access-key='*)
			export HALCYON_AWS_SECRET_ACCESS_KEY="${1#*=}";;
		'--s3-bucket='*)
			export HALCYON_S3_BUCKET="${1#*=}";;
		'--s3-acl='*)
			export HALCYON_S3_ACL="${1#*=}";;

		'--silent')
			export HALCYON_SILENT=1;;

		'-'*)
			die "Unexpected option: $1";;
		*)
			break
		esac
		shift
	done

	local app_dir app_label
	if ! (( $# )); then
		export HALCYON_FAKE_APP=0
		app_dir='.'
		app_label=$( detect_app_label "${app_dir}" ) || die
	elif [ -d "$1" ]; then
		export HALCYON_FAKE_APP=0
		app_dir="$1"
		app_label=$( detect_app_label "${app_dir}" ) || die
	else
		export HALCYON_FAKE_APP=1
		app_label="$1"
		app_dir=''
	fi

	log "Installing ${app_label}"
	log

	if [ -d "${HALCYON_CONFIG_DIR}" ]; then
		set_config_vars || die
		log
	fi

	if (( ${HALCYON_FORCE_FAIL_INSTALL} )); then
		return 1
	fi

	prepare_cache || die
	log

	install_ghc "${app_dir}" || return 1
	log

	install_cabal || return 1
	log

	if (( ${HALCYON_FAKE_APP} )); then
		app_dir=$( fake_app_dir "${app_label}" ) || die
	fi

	install_sandbox "${app_dir}" || return 1
	log

	if (( ${HALCYON_FAKE_APP} )); then
		rm -rf "${app_dir}" || die
	elif ! (( ${HALCYON_DEPENDENCIES_ONLY} )); then
		install_app "${app_dir}" || die
		log
	fi

	clean_cache "${app_dir}" || die
	log

	log "Installed ${app_label}"
}




function log_add_config_help () {
	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log_file_indent <<-EOF
		To use explicit constraints, add cabal.config:
		$ cat >cabal.config <<EOF
EOF
	echo_constraints <<<"${sandbox_constraints}" >&2 || die
	echo 'EOF' >&2
}
