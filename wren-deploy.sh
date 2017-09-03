#!/bin/bash

################################################################################
# Wren Deployment Tool
# ====================
# Provides the ability to quickly compile and sign multiple versions of
# packages, then deploy them to BinTray or JFrog.
#
# @author Kortanul (kortanul@protonmail.com)
#
################################################################################

set -e
set -u

################################################################################
# Includes
################################################################################
SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_PATH}/includes/all_includes.sh"

################################################################################
# CLI Argument Parsing & Help
################################################################################
parse_args() {
  command="${1:-UNSET}"

  if array_contains "--help" $@; then
    return 1;
  else
    local commands_allowed=(\
      "create-sustaining-branches" \
      "delete-sustaining-branches" \
      "patch-all-releases" \
      "compile-all-releases" \
      "compile-current-release" \
      "deploy-all-releases" \
      "deploy-current-release" \
      "delete-all-releases" \
    )

    if ! array_contains "${command}" ${commands_allowed[*]}; then
      return 1
    else
      local with_provider="${2:-UNSET}"

      if [[ "${with_provider}" == '--with-provider=bintray' ]]; then
        export provider="bintray"
      elif [[ "${with_provider}" == '--with-provider=jfrog' ]]; then
        export provider="jfrog"
      else
        # Default
        export provider="jfrog"
      fi

      return 0
    fi
  fi
}

function print_usage() {
  script_name=`basename "${0}"`

  echo_error "Wren Deploy -- Used to quickly compile and sign multiple versions"
  echo_error "of a package and then deploy them to BinTray or JFrog."
  echo_error ""
  echo_error "Usage: ${script_name} <COMMAND> [--with-provider=PROVIDER]"
  echo_error ""
  echo_error "Where COMMAND can be any of the following:"
  echo_error "  - create-sustaining-branches"
  echo_error "    Creates 'sustaining/X.Y.Z' branches in the current package "
  echo_error "    from all release tags in the package."
  echo_error ""
  echo_error "  - delete-sustaining-branches"
  echo_error "    Deletes all 'sustaining/X.Y.Z' branches from the current "
  echo_error "    package."
  echo_error ""
  echo_error "  - patch-all-releases [SRC-REF] [STARTING-RELEASE-TAG]"
  echo_error "    Cherry-picks either HEAD or SRC-REF on to all release"
  echo_error "    branches, optionally targeting only the release identified by"
  echo_error "    the specified STARTING-RELEASE-TAG and later releases "
  echo_error "    (typically to resume a cherry pick after fixing conflicts)."
  echo_error ""
  echo_error "  - compile-all-releases:"
  echo_error "    Sequentially checks out each release of the current package"
  echo_error "    and compiles it."
  echo_error ""
  echo_error "  - compile-current-release"
  echo_error "    Compiles whatever version of the current package is checked"
  echo_error "    out."
  echo_error ""
  echo_error "  - deploy-all-releases"
  echo_error "    Sequentially checks out each release of the current package,"
  echo_error "    compiles it, signs it, and then deploys it to a provider."
  echo_error ""
  echo_error "  - deploy-current-release"
  echo_error "    Compiles whatever version of the current package is checked"
  echo_error "    out, then signs it and deploys it to a provider."
  echo_error ""
  echo_error "  - delete-all-releases"
  echo_error "    Deletes all versions of the current package from a remote"
  echo_error "    provider."
  echo_error ""
  echo_error "PROVIDER can be either of the following:"
  echo_error "  - jfrog"
  echo_error "  - bintray:"
  echo_error ""
  echo_error "In addition, a '${WRENDEPLOY_RC}' file must exist in the current"
  echo_error "working directory in order for it to be deployable. At a minimum"
  echo_error "this file must export the variables BINTRAY_PACKAGE,"
  echo_error "JFROG_PACKAGE, and MAVEN_PACKAGE, but it can also define the"
  echo_error "function 'package_accept_release_tag()' in order to control which"
  echo_error "release tags are processed. If the function is not defined, by"
  echo_error "default all release tags are processed."
}

prepare_subcommand_args() {
  export args=()

  # Skip command arg
  shift

  for argument; do
    # Skip option arguments
    if [ "${argument:0:2}" != "--" ]; then
      args+=("${argument}")
    fi
  done
}

################################################################################
# Commands
################################################################################
create_sustaining_branches() {
  package_create_all_sustaining_branches
}

delete-sustaining-branches() {
  package_delete_all_sustaining_branches
}

patch_all_releases() {
  local src_ref="${1:-HEAD}"
  local first_dst_ref="${2:-UNSET}"

  git_bulk_cherry_pick "${src_ref}" "${first_dst_ref}"
}

compile_all_releases() {
  echo "Compiling all releases"
  package_compile_all_versions "${MAVEN_PACKAGE}"
}

compile_current_release() {
  echo "Compiling current release"
  package_compile_current_version
}

deploy_all_releases() {
  echo "Deploying all releases"
  package_deploy_all_versions "${MAVEN_PACKAGE}"
}

deploy_current_release() {
  echo "Deploying current release"
  deploy_current_package_version
}

delete_all_releases() {
  echo "Deleting all releases from remote"

  if [ "${provider}" == "jfrog" ]; then
    package_delete_from_jfrog "${MAVEN_PACKAGE}" "${JFROG_PACKAGE}"
  elif [ "${provider}" == "bintray" ]; then
    package_delete_from_bintray "${MAVEN_PACKAGE}" "${BINTRAY_PACKAGE}"
  else
    echo_error "Unknown provider: ${provider}"
  fi
}

################################################################################
# Main Script
################################################################################
if ! parse_args $@; then
  print_usage
else
  package_load_config

  func_name="${command//-/_}"

  prepare_subcommand_args $@

  eval "${func_name}" ${args[*]}
fi
