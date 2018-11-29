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
function print_usage() {
  script_name=`basename "${0}"`

  echo_error "Wren Deploy -- A swiss-army command-line tool for managing,"
  echo_error "compiling, and publishing multiple versions of a Maven package"
  echo_error "and then deploying them to BinTray or JFrog."
  echo_error ""
  echo_error "Usage: ${script_name} <COMMAND>"
  echo_error ""
  echo_error "Where COMMAND can be any of the following:"
  echo_error ""
  echo_error "  - create-sustaining-branches"
  echo_error "    Creates 'sustaining/X.Y.Z' branches in the current package"
  echo_error "    from all release tags in the package."
  echo_error ""
  echo_error ""
  echo_error "  - tag-sustaining-branches"
  echo_error "    Tags all 'sustaining/X.Y.Z' branches of the current package."
  echo_error "    Each tag is annotated and signed with the GPG signature of"
  echo_error "    the current GIT user."
  echo_error ""
  echo_error "    Before running this command, you will need to generate a GPG"
  echo_error "    key with 'gpg --gen-key' and then set that as your GIT"
  echo_error "    signing key with:"
  echo_error ""
  echo_error "      git config --global user.signingkey KEY_ID"
  echo_error ""
  echo_error "    With KEY_ID being the ID of the key (e.g. 1FA76C5D)."
  echo_error ""
  echo_error ""
  echo_error "  - delete-sustaining-branches"
  echo_error "    Deletes all 'sustaining/X.Y.Z' branches from the current"
  echo_error "    package."
  echo_error ""
  echo_error ""
  echo_error "  - patch-all-releases [SRC-REF] [STARTING-RELEASE-TAG]"
  echo_error "    Cherry-picks either HEAD or SRC-REF on to all 'sustaining/'"
  echo_error "    release branches, optionally targeting only the release"
  echo_error "    identified by the specified STARTING-RELEASE-TAG and later"
  echo_error "    releases (typically to resume a cherry pick after fixing"
  echo_error "    conflicts)."
  echo_error ""
  echo_error ""
  echo_error "  - compile-all-releases"
  echo_error "    Sequentially checks out each sustaining release of the"
  echo_error "    current package, compiles it, and installs it to the local"
  echo_error "    Maven repository."
  echo_error ""
  echo_error ""
  echo_error "  - compile-current-release"
  echo_error "    Compiles whatever version of the current package is checked"
  echo_error "    out, and then installs it to the local Maven repository."
  echo_error ""
  echo_error ""
  echo_error "  - deploy-all-releases"
  echo_error "    Sequentially checks out each sustaining release of the"
  echo_error "    current package, compiles it, signs it, and then deploys it"
  echo_error "    to JFrog."
  echo_error ""
  echo_error ""
  echo_error "  - deploy-current-release"
  echo_error "    Compiles whatever version of the current package is checked"
  echo_error "    out, then signs it and deploys it to JFrog."
  echo_error ""
  echo_error ""
  echo_error "  - verify-all-releases"
  echo_error "    Sequentially checks out each sustaining release of the"
  echo_error "    current package and verifies the GPG signatures of all"
  echo_error "    its dependencies."
  echo_error ""
  echo_error ""
  echo_error "  - verify-current-release"
  echo_error "    Verifies the GPG signatures of all dependencies for whatever"
  echo_error "    version of the current package is checked out."
  echo_error ""
  echo_error ""
  echo_error "  - list-unapproved-artifact-sigs"
  echo_error "    Lists the name and GPG signature of each artifact dependency"
  echo_error "    that is not on the Wren whitelist. The whitelist is located"
  echo_error "    at '${WREN_DEP_PGP_WHITELIST_URL}'."
  echo_error ""
  echo_error ""
  echo_error "  - capture-unapproved-artifact-sigs WRENSEC-WHITELIST-PATH "
  echo_error "      [--push] [--force-amend] [--force]"
  echo_error "    Appends the name and GPG signature of each artifact"
  echo_error "    dependency to the whitelist in a checked-out copy of the"
  echo_error "    'wrensec-pgp-whitelist' project, then commits the change."
  echo_error "    This can be used to rapidly add multiple artifacts to the"
  echo_error "    whitelist with a minimum of manual effort."
  echo_error ""
  echo_error "    Options:"
  echo_error "      --push"
  echo_error "      Pushes the resulting changes to the default remote of the"
  echo_error "      'wrensec-pgp-whitelist' project."
  echo_error ""
  echo_error "      --force-amend"
  echo_error "      Forcibly amends the previous commit of the"
  echo_error "      'wrensec-pgp-whitelist' project, instead of creating a"
  echo_error "      new commit."
  echo_error ""
  echo_error "      Amending allows a maintainer to iterate on dependency"
  echo_error "      signatures for an artifact as he or she encounters build"
  echo_error "      failures while preparing a release of the artifact."
  echo_error ""
  echo_error "      This tool automatically determines if it should amend the"
  echo_error "      last commit or create a new commit, based on the subject"
  echo_error "      line of HEAD. Therefore, it is typically not necessary to"
  echo_error "      use this option unless automatic commit handling is not"
  echo_error "      working properly. Use with care to avoid rewriting the"
  echo_error "      history of commits that have already been shared."
  echo_error ""
  echo_error "      --force"
  echo_error "      When used with --push, the last commit of the"
  echo_error "      'wrensec-pgp-whitelist' project is force-pushed to the"
  echo_error "      default remote. This should be used with caution as it"
  echo_error "      re-writes repository history and can result in a loss of"
  echo_error "      other changes in the project if multiple maintainers are"
  echo_error "      making changes in the repository at the same time."
  echo_error ""
  echo_error ""
  echo_error "  - deploy-consensus-verified-artifacts"
  echo_error "      --repo-root=REPO-ROOT-PATH SEARCH-PATH"
  echo_error "      [--packaging=jar|pom|zip]"
  echo_error "    Searches 'SEARCH_PATH' for all deployable artifacts,"
  echo_error "    interpreting 'REPO-ROOT-PATH' as the root of the archived"
  echo_error "    repository (i.e. this is the equivalent to"
  echo_error "    '~/.m2/repository', but for an archived copy of a maven"
  echo_error "    repository). Each artifact recognized is copied to a"
  echo_error "    temporary folder, signed using the Wren Security third-party"
  echo_error "    key, then deployed to BinTray under this project:"
  echo_error "    https://bintray.com/wrensecurity/forgerock-archive/consensus-verified."
  echo_error ""
  echo_error "    For example, this would deploy 'form2js' from a local Maven"
  echo_error "    repository archive located in './forgerock-archive':"
  echo_error ""
  echo_error "      wren-deploy deploy-consensus-verified-artifact \\"
  echo_error "        --repo-root=./forgerock-archive \\"
  echo_error "        ./forgerock-archive/org/forgerock/commons/ui/libs/form2js"
  echo_error ""
  echo_error "    The optional '--packaging' parameter can be used if there is"
  echo_error "    a difference between the packaging specified in the POM file"
  echo_error "    and the desired file extension on the remote server. For"
  echo_error "    example, OSGi packages for Apache Felix often have a"
  echo_error "    POM packaging of 'bundle' but need to be deployed as a JAR."
  echo_error ""
  echo_error ""
  echo_error "  - sign-3p-artifacts"
  echo_error "    Generates GPG signatures for all unsigned third-party"
  echo_error "    artifacts using the Wren Security third-party key, then"
  echo_error "    deploys the artifacts to JFrog."
  echo_error ""
  echo_error ""
  echo_error "  - sign-tools-jar"
  echo_error "    Generates a GPG signature for the version of the JDK"
  echo_error "    'tools.jar' currently in use on the local machine using the"
  echo_error "    Wren Security third-party key, then deploys the artifact"
  echo_error "    signature (not the JAR itself) to JFrog."
  echo_error ""
  echo_error ""
  echo_error "  - version or --version"
  echo_error "    Displays the version number of Wren Deploy."
  echo_error ""
  echo_error ""
  echo_error "  - help or --help"
  echo_error "    Displays this command usage text."
  echo_error ""
  echo_error ""
  echo_error "In addition, a '${WRENDEPLOY_RC}' file must exist in the current"
  echo_error "working directory in order for the package in the current"
  echo_error "directory to be deployable. At a minimum, the file must export"
  echo_error "the variable 'MAVEN_PACKAGE'. It can optionally export"
  echo_error "'MVN_COMPILE_ARGS' to modify the command line passed to Maven"
  echo_error "during compilation. Finally, it can also define the function"
  echo_error "'package_accept_release_tag()' in order to control which release"
  echo_error "tags are processed; if the function is not defined, all releases"
  echo_error "are processed, by default."
}

parse_args() {
  if array_contains "--help" $@; then
    command="help"
  elif array_contains "--version" $@; then
    command="version"
  else
    command="${1:-UNSET}"
  fi

  local commands_allowed=(\
    "help" \
    "version" \
    "create-sustaining-branches" \
    "tag-sustaining-branches" \
    "delete-sustaining-branches" \
    "patch-all-releases" \
    "compile-all-releases" \
    "compile-current-release" \
    "deploy-all-releases" \
    "deploy-current-release" \
    "verify-all-releases" \
    "verify-current-release" \
    "list-unapproved-artifact-sigs" \
    "capture-unapproved-artifact-sigs" \
    "deploy-consensus-verified-artifacts" \
    "sign-3p-artifacts" \
    "sign-tools-jar" \
  )

  if ! array_contains "${command}" ${commands_allowed[@]}; then
    return 1
  else
    shift

    return 0
  fi
}

prepare_subcommand_args() {
  SUBCOMMAND_ARGS=()

  # Skip command arg
  shift

  for argument; do
    # Handle option arguments specially
    if [ "${argument:0:2}" != "--" ]; then
      SUBCOMMAND_ARGS+=("${argument}")
    else
      local option_name
      local option_value

      full_option="${argument:2}"

      option_name="${full_option%=*}"
      option_value="${full_option##*=}"

      SUBCOMMAND_OPTIONS["${option_name}"]="${option_value}"
    fi
  done
}

fail_on_command_args() {
  echo_error ""
  echo_error "Try the '--help' option to see command usage."

  exit 1;
}

################################################################################
# Commands
################################################################################
create_sustaining_branches() {
  package_load_config

  echo "Creating all missing sustaining branches"
  echo ""
  package_create_all_sustaining_branches "${MAVEN_PACKAGE}"
}

tag_sustaining_branches() {
  package_load_config

  echo "Tagging all sustaining branches as signed releases"
  echo ""
  package_tag_all_sustaining_versions
}

delete_sustaining_branches() {
  package_load_config

  echo "Deleting all existing sustaining branches"
  echo ""
  package_delete_all_sustaining_branches
}

patch_all_releases() {
  package_load_config

  local src_ref="${1:-HEAD}"
  local first_dst_rel_tag="${2:-UNSET}"

  echo "Patching all releases"
  echo ""

  git_bulk_cherry_pick "${src_ref}" "${first_dst_rel_tag}"
}

compile_all_releases() {
  package_load_config

  echo "Compiling all releases"
  echo ""

  package_compile_all_versions
}

compile_current_release() {
  package_load_config

  echo "Compiling current release"
  echo ""

  package_compile_current_version
}

deploy_all_releases() {
  package_load_config

  echo "Deploying all releases to JFrog"
  echo ""

  package_deploy_all_versions
}

deploy_current_release() {
  package_load_config

  echo "Deploying current release to JFrog"
  echo ""

  package_deploy_current_version
}

verify_all_releases() {
  package_load_config

  echo "Verifying PGP keys for all dependencies of all releases"
  echo ""

  package_verify_keys_for_all_versions
}

verify_current_release() {
  package_load_config

  echo "Verifying PGP keys for all dependencies of current release"
  echo ""

  package_verify_keys_for_current_version
}

list_unapproved_artifact_sigs() {
  package_load_config

  echo "Listing all dependencies with signatures not on the whitelist"
  echo ""

  package_get_all_unapproved_sigs_for_current_version
}

capture_unapproved_artifact_sigs() {
  package_load_config

  local wrensec_whitelist_path="${1:-UNSET}"

  if [ "${wrensec_whitelist_path}" == "UNSET" ]; then
    echo_error "ERROR: WRENSEC-WHITELIST-PATH must be specified."
    fail_on_command_args
  fi;

  if [ ! -d "${wrensec_whitelist_path}/.git" ]; then
    echo_error "ERROR: WRENSEC-WHITELIST-PATH must exist and contain a GIT" \
               "repository."
    fail_on_command_args
  fi;

  local force_amend=${SUBCOMMAND_OPTIONS['force-amend']+1}
  local push=${SUBCOMMAND_OPTIONS['push']+1}
  local force=${SUBCOMMAND_OPTIONS['force']+1}

  echo "Capturing all dependencies with signatures not on the whitelist"
  echo ""

  package_capture_unapproved_sigs_for_current_version \
    "${wrensec_whitelist_path}" "${force_amend}" "${push}" "${force}"
}

deploy_consensus_verified_artifacts() {
  local repo_root="${SUBCOMMAND_OPTIONS['repo-root']:-UNSET}"
  local search_path="${1:-UNSET}"
  local packaging_override="${SUBCOMMAND_OPTIONS['packaging']:-UNSET}"

  if [ "${repo_root}" == "UNSET" ]; then
    echo_error "ERROR: '--repo-root' must be specified."
    fail_on_command_args
  fi;

  if [ ! -d "${repo_root}" ]; then
    echo_error "ERROR: '--repo-root' must point to an existing directory."
    fail_on_command_args
  fi;

  if [ "${search_path}" == "UNSET" ]; then
    echo_error "ERROR: 'SEARCH-PATH' must be specified."
    fail_on_command_args
  fi;

  if [ ! -d "${search_path}" ]; then
    echo_error "ERROR: 'SEARCH-PATH' must point to an existing directory."
    fail_on_command_args
  fi;

  echo "Searching for archived artifacts to deploy to BinTray"
  echo ""
  echo "Repo Root:   ${repo_root}"
  echo "Search Path: ${search_path}"
  echo ""

  package_sign_and_deploy_consensus_signed_artifact \
    "${repo_root}" "${search_path}" "${packaging_override}"
}

sign_3p_artifacts() {
  package_load_config

  echo "Signing unsigned third-party artifacts and deploying to JFrog"
  echo ""

  package_sign_3p_artifacts_for_current_version
}

sign_tools_jar() {
  echo "Signing JDK 'tools.jar' and deploying signature to JFrog"
  echo ""

  package_sign_tools_jar
}

version() {
  echo "Wren Deploy version ${WRENDEPLOY_VERSION}"
  echo ""
}

help() {
  print_usage
}
################################################################################
# Main Script
################################################################################
if ! parse_args "$@"; then
  print_usage
  exit 1
else
  func_name="${command//-/_}"

  declare -a SUBCOMMAND_ARGS
  declare -A SUBCOMMAND_OPTIONS

  prepare_subcommand_args "$@"

  eval "${func_name} '${SUBCOMMAND_ARGS[@]:-}'"
fi
