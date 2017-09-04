################################################################################
# Shared Package Management Functions
################################################################################
package_create_all_sustaining_branches() {
  for tag in $(git_get_sorted_tag_list); do
    local branch_name=$(\
      echo $tag | \
      sed "s/${MAVEN_PACKAGE}-//" | \
      sed 's/^/sustaining\//'\
    )

    if git_branch_exists "${branch_name}"; then
      echo "Sustaining branch ${branch_name} already exists; skipping."
    else
      git branch "${branch_name}" "${tag}"
    fi
  done
}

package_delete_all_sustaining_branches() {
  for branch in $(git branch --list | grep "sustaining"); do
    git branch -D "${branch}"
  done
}

package_compile_all_versions() {
  local maven_package="${1}"

  for tag in $(git_list_release_tags "${maven_package}"); do
    if package_accept_release_tag "${tag}"; then
      git checkout "sustaining/${tag}"
      package_compile_current_version
    fi
  done
}

package_compile_current_version() {
  mvn clean install "-Duser.name=Kortanul"
}

package_deploy_all_versions() {
  local maven_package="${1}"
  
  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  for tag in $(git_list_release_tags "${maven_package}"); do
    if package_accept_release_tag "${tag}"; then
      git checkout "sustaining/${tag}"
      package_deploy_current_version
    fi
  done
}

package_deploy_current_version() {
  local passphrase_var="${WREN_OFFICIAL_SIGN_KEY_ID}_PASSPHRASE"

  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  mvn clean deploy -Psign,forgerock-release "-Duser.name=Kortanul" \
    "-Dgpg.keyname=${WREN_OFFICIAL_SIGN_KEY_ID}" \
    "-Dgpg.passphrase=${!passphrase_var}"
}

package_verify_keys_for_all_versions() {
  local maven_package="${1}"

  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  for tag in $(git_list_release_tags "${maven_package}"); do
    if package_accept_release_tag "${tag}"; then
      git checkout "sustaining/${tag}"
      package_verify_keys_for_current_version
    fi
  done
}

package_verify_keys_for_current_version() {
# TODO: Build this in as a separate parent POM profile
#
#  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"
#
#  mvn verify -Pforgerock-release "-Duser.name=Kortanul" \
#    "-Dgpg.keyname=${WREN_OFFICIAL_SIGN_KEY_ID}" "-Dgpg.passphrase=${GPG_PASSPHRASE}" \
#    "-Dpgpverify.failNoSignature=false" \
#    "-DpgpVerifyPluginVersion=1.2.0-SNAPSHOT"
#
  mvn com.github.s4u.plugins:pgpverify-maven-plugin:1.2.0-SNAPSHOT:check \
    "-Dignore-artifact-sigs"
}

package_sign_3p_artifacts_for_current_version() {
  local passphrase_var="${WREN_3P_SIGN_KEY_ID}_PASSPHRASE"

  creds_prompt_for_gpg_credentials "${WREN_3P_SIGN_KEY_ID}"

  # Converts:
  #   com.google.collections:google-collections:pom:1.0
  #
  # Into:
  #   com/google/collections/google-collections/1.0/google-collections-1.0.pom
  #
  local target_3p_package_paths=$( \
    package_get_all_unsigned_3p_artifacts | \
    awk 'BEGIN { FS=":"; OFS=":" } { gsub(/\./, "/", $1) } { print }' | \
    sed -r 's/([^:]+):([^:]+):([^:]+):(.*)/\1\/\2\/\4\/\2-\4.\3/'
  )

  for path in ${target_3p_package_paths[@]}; do
    local full_path="${HOME}/.m2/repository/${path}"

    gpg -u "0x${WREN_3P_SIGN_KEY_ID}" --passphrase "${!passphrase_var}" \
      --armor --detach-sign "${full_path}"
  done
}

package_get_all_unsigned_3p_artifacts() {
  package_verify_keys_for_current_version | \
  grep "\[WARNING\] No signature for" | \
  sed -r 's/^\[WARNING\] No signature for (.*)$/\1/' |
  sort
}

package_delete_from_bintray() {
  local maven_package="${1}"
  local bintray_package="${2}"

  creds_prompt_for_bintray_credentials

  for tag in $(git_list_release_tags "${maven_package}"); do
    set -x
    curl -X "DELETE" -u "${BINTRAY_USERNAME}:${BINTRAY_PASSWORD}" \
      "https://api.bintray.com/packages/wrensecurity/releases/${bintray_package}/versions/${tag}"
    set +x
  done
}

package_delete_from_jfrog() {
  local maven_package="${1}"
  local jfrog_package="${2}"
  
  creds_prompt_for_jfrog_credentials
  
  set -x
  curl -X "DELETE" -u "${JFROG_USERNAME}:${JFROG_PASSWORD}" \
    "https://wrensecurity.jfrog.io/wrensecurity/releases-local/${jfrog_package}"
  set +x
}

package_load_config() {
  if [ ! -f "${WRENDEPLOY_RC}" ]; then
    echo_error "A '${WRENDEPLOY_RC}' file must exist in this package in order "
    echo_error "to be deployable."
    return 1
  else
    source "${WRENDEPLOY_RC}"
  fi
}

parse_provider_arg() {
  # Default
  provider="${DEFAULT_PACKAGE_PROVIDER}"

  for argument; do
    if [[ "${argument}" == '--with-provider=bintray' ]]; then
      provider="bintray"
    elif [[ "${argument}" == '--with-provider=jfrog' ]]; then
      provider="jfrog"
    fi
  done
}

################################################################################
# Hooks (can be overridden in .rc by being defined)
################################################################################
if ! function_exists 'package_accept_release_tag'; then
  package_accept_release_tag() {
    local tag_name="${1}"

    # Default
    return 0;
  }
fi
