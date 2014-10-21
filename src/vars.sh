function set_halcyon_vars () {
	set_halcyon_paths

	if ! (( ${HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED:-0} )); then
		export HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED=1

		export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
		export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
		export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
		export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"

		export HALCYON_PUBLIC="${HALCYON_PUBLIC:-0}"

		export HALCYON_RECURSIVE="${HALCYON_RECURSIVE:-0}"
		export HALCYON_TOOL="${HALCYON_TOOL:-0}"

		export HALCYON_NO_BUILD="${HALCYON_NO_BUILD:-0}"
		export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
		export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"

		export HALCYON_NO_INSTALL_GHC="${HALCYON_NO_INSTALL_GHC:-0}"
		export HALCYON_NO_INSTALL_CABAL="${HALCYON_NO_INSTALL_CABAL:-0}"
		export HALCYON_NO_INSTALL_SANDBOX="${HALCYON_NO_INSTALL_SANDBOX:-0}"
		export HALCYON_NO_INSTALL_APP="${HALCYON_NO_INSTALL_APP:-0}"

		export HALCYON_NO_PREPARE_CACHE="${HALCYON_NO_PREPARE_CACHE:-0}"
		export HALCYON_NO_CLEAN_CACHE="${HALCYON_NO_CLEAN_CACHE:-0}"

		export HALCYON_NO_WARN_IMPLICIT="${HALCYON_NO_WARN_IMPLICIT:-0}"
	fi

	if ! (( ${HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET:-0} )); then
		export HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET=1

		export HALCYON_GHC_VERSION="${HALCYON_GHC_VERSION:-}"

		export HALCYON_CABAL_VERSION="${HALCYON_CABAL_VERSION:-}"
		export HALCYON_CABAL_REMOTE_REPO="${HALCYON_CABAL_REMOTE_REPO:-}"

		export HALCYON_BUILDTIME_DEPS="${HALCYON_BUILDTIME_DEPS:-}"
		export HALCYON_RUNTIME_DEPS="${HALCYON_RUNTIME_DEPS:-}"

		export HALCYON_BUILD_GHC="${HALCYON_BUILD_GHC:-0}"
		export HALCYON_BUILD_CABAL="${HALCYON_BUILD_CABAL:-0}"
		export HALCYON_BUILD_SANDBOX="${HALCYON_BUILD_SANDBOX:-0}"
		export HALCYON_BUILD_APP="${HALCYON_BUILD_APP:-0}"

		export HALCYON_UPDATE_CABAL="${HALCYON_UPDATE_CABAL:-0}"

		export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"
	else
		export HALCYON_GHC_VERSION=

		export HALCYON_CABAL_VERSION=
		export HALCYON_CABAL_REMOTE_REPO=

		export HALCYON_BUILDTIME_DEPS=
		export HALCYON_RUNTIME_DEPS=

		export HALCYON_BUILD_GHC=0
		export HALCYON_BUILD_CABAL=0
		export HALCYON_BUILD_SANDBOX=0
		export HALCYON_BUILD_APP=0

		export HALCYON_UPDATE_CABAL=0

		export HALCYON_PURGE_CACHE=0
	fi
}
