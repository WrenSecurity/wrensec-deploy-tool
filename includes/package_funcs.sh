################################################################################
# Shared Package Management Functions
################################################################################
package_create_all_sustaining_branches() {
  for tag in $(git_get_sorted_tag_list); do
    branch_name=$(\
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

package_deploy_all_versions() {
  local maven_package="${1}"
  
  package_prompt_for_gpg_credentials

  for tag in $(git_list_release_tags "${maven_package}"); do
    if accept_release_tag "${tag}"; then
      git checkout "sustaining/${tag}"
      deploy_current_package_version
    fi
  done
}

package_compile_current_version() {
  mvn clean install "-Duser.name=Kortanul" -Dignore-artifact-sigs
}

package_deploy_current_version() {
  package_prompt_for_gpg_credentials

  mvn clean deploy -Psign,forgerock-release \
    "-Dgpg.passphrase=${GPG_PASSPHRASE}" "-Dgpg.keyname=${GPG_KEY_ID}" \
    "-Duser.name=Kortanul" -Dignore-artifact-sigs
}

package_delete_from_bintray() {
  local maven_package="${1}"
  local bintray_package="${2}"

  package_prompt_for_bintray_credentials

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
  
  package_prompt_for_jfrog_credentials
  
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
  for argument; do
    if [[ "${argument}" == '--with-provider=bintray' ]]; then
      export provider="bintray"
    elif [[ "${argument}" == '--with-provider=jfrog' ]]; then
      export provider="jfrog"
    fi
  done

  # Default
  export provider="${provider:-jfrog}"
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
