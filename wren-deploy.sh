#!/bin/bash

################################################################################
# Wren Deployment Tool
# ====================
# A swiss-army command-line tool for managing, compiling, and publishing
# multiple versions of a Maven package and then deploying them to BinTray or
# JFrog.
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
      "verify-all-releases" \
      "verify-current-release" \
      "list-unapproved-artifact-sigs" \
      "sign-3p-artifacts" \
      "sign-tools-jar" \
    )

    if ! array_contains "${command}" ${commands_allowed[@]}; then
      return 1
    else
      shift
      parse_provider_arg $@

      return 0
    fi
  fi
}

function print_usage() {
  script_name=`basename "${0}"`

  echo_error "Wren Deploy -- A swiss-army command-line tool for managing,"
  echo_error "compiling, and publishing multiple versions of a Maven package"
  echo_error "and then deploying them to BinTray or JFrog."
  echo_error ""
  echo_error "Usage: ${script_name} <COMMAND> [--with-provider=PROVIDER]"
  echo_error ""
  echo_error "Where COMMAND can be any of the following:"
  echo_error "  - create-sustaining-branches"
  echo_error "    Creates 'sustaining/X.Y.Z' branches in the current package"
  echo_error "    from all release tags in the package."
  echo_error ""
  echo_error "  - delete-sustaining-branches"
  echo_error "    Deletes all 'sustaining/X.Y.Z' branches from the current"
  echo_error "    package."
  echo_error ""
  echo_error "  - patch-all-releases [SRC-REF] [STARTING-RELEASE-TAG]"
  echo_error "    Cherry-picks either HEAD or SRC-REF on to all release"
  echo_error "    branches, optionally targeting only the release identified by"
  echo_error "    the specified STARTING-RELEASE-TAG and later releases "
  echo_error "    (typically to resume a cherry pick after fixing conflicts)."
  echo_error ""
  echo_error "  - compile-all-releases"
  echo_error "    Sequentially checks out each release of the current package,"
  echo_error "    compiles it, and installs it to the local Maven repository."
  echo_error ""
  echo_error "  - compile-current-release"
  echo_error "    Compiles whatever version of the current package is checked"
  echo_error "    out, and then installs it to the local Maven repository."
  echo_error ""
  echo_error "  - deploy-all-releases"
  echo_error "    Sequentially checks out each release of the current package,"
  echo_error "    compiles it, signs it, and then deploys it to a provider."
  echo_error ""
  echo_error "  - deploy-current-release"
  echo_error "    Compiles whatever version of the current package is checked"
  echo_error "    out, then signs it and deploys it to a provider."
  echo_error ""
  echo_error "  - verify-all-releases"
  echo_error "    Sequentially checks out each release of the current package"
  echo_error "    and verifies the GPG signatures of all its dependencies."
  echo_error ""
  echo_error "  - verify-current-release"
  echo_error "    Verifies the GPG signatures of all dependencies for whatever"
  echo_error "    version of the current package is checked out."
  echo_error ""
  echo_error "  - list-unapproved-artifact-sigs"
  echo_error "    Lists the name and GPG signature of each artifact dependency"
  echo_error "    that is not on the Wren whitelist. The whitelist is located"
  echo_error "    at '${WREN_DEP_KEY_WHITELIST}'."
  echo_error ""
  echo_error "  - sign-3p-artifacts"
  echo_error "    Generates GPG signatures for all unsigned third-party"
  echo_error "    artifacts using the Wren Security third-party key, then"
  echo_error "    deploys the artifacts to a provider."
  echo_error ""
  echo_error "  - sign-tools-jar"
  echo_error "    Generates a GPG signature for the version of the JDK"
  echo_error "    'tools.jar' currently in use on the local machine using the"
  echo_error "    Wren Security third-party key, then deploys the artifact"
  echo_error "    signature (not the JAR itself) to a provider."
  echo_error ""
  echo_error "PROVIDER can be either of the following:"
  echo_error "  - jfrog"
  echo_error "  - bintray"
  echo_error ""
  echo_error "In addition, a '${WRENDEPLOY_RC}' file must exist in the current"
  echo_error "working directory in order for the package in the current"
  echo_error "directory to be deployable. At a minimum, the file must export"
  echo_error "the variable MAVEN_PACKAGE."
  echo_error "It can optionally export MVN_COMPILE_ARGS to modify the command"
  echo_error "line passed to Maven during compilation. Finally, it can also"
  echo_error "define the function 'package_accept_release_tag()' in order to"
  echo_error "control which release tags are processed; if the function is not"
  echo_error "defined, all releases are processed, by default."
}

prepare_subcommand_args() {
  args=()

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
  echo "Creating all missing sustaining branches"
  package_create_all_sustaining_branches "${MAVEN_PACKAGE}"
}

delete-sustaining-branches() {
  echo "Deleting all existing sustaining branches"
  package_delete_all_sustaining_branches
}

patch_all_releases() {
  local src_ref="${1:-HEAD}"
  local first_dst_rel_tag="${2:-UNSET}"

  echo "Patching all releases"
  git_bulk_cherry_pick "${src_ref}" "${first_dst_rel_tag}"
}

compile_all_releases() {
  echo "Compiling all releases"
  package_compile_all_versions
}

compile_current_release() {
  echo "Compiling current release"
  package_compile_current_version
}

deploy_all_releases() {
  echo "Deploying all releases to '${provider}'"
  package_deploy_all_versions
}

deploy_current_release() {
  echo "Deploying current release to '${provider}'"
  package_deploy_current_version
}

verify_all_releases() {
  echo "Verifying PGP keys for all dependencies of all releases"
  package_verify_keys_for_all_versions
}

verify_current_release() {
  echo "Verifying PGP keys for all dependencies of current release"
  package_verify_keys_for_current_version
}

list_unapproved_artifact_sigs() {
  echo "Listing all dependencies with signatures not on the whitelist"
  echo

  package_report_unapproved_sigs_for_current_version
}

sign_3p_artifacts() {
  echo "Signing unsigned third-party artifacts and deploying to '${provider}'"
  package_sign_3p_artifacts_for_current_version
}

sign_tools_jar() {
  echo "Signing JDK 'tools.jar' and deploying signature to '${provider}'"
  package_sign_tools_jar
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

  eval "${func_name}" ${args[@]:-}
fi
