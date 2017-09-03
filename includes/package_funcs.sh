################################################################################
# Shared Package Management Functions
################################################################################
package_compile_all_versions() {
  local maven_package="${1}"

  for tag in $(git tag | sed "s/${maven_package}-//" | sort -V); do
    if package_accept_release_tag "${tag}"; then
      git checkout "sustaining/${tag}"
      package_compile_current_version
    fi
  done
}

package_deploy_all_versions() {
  local maven_package="${1}"
  
  package_prompt_for_gpg_credentials

  for tag in $(git tag | sed "s/${maven_package}-//" | sort -V); do
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

  for tag in $(git tag | sed "s/${maven_package}-//" | sort -V); do
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

package_prompt_for_bintray_credentials() {
  if [ "${BINTRAY_USERNAME:-UNSET}" == "UNSET" ]; then
    read -p "BinTray username: " BINTRAY_USERNAME
  fi

  if [ "${BINTRAY_PASSWORD:-UNSET}" == "UNSET" ]; then
    read -s -p "JFrog password: " BINTRAY_PASSWORD
  fi

  export BINTRAY_USERNAME
  export BINTRAY_PASSWORD
}

package_prompt_for_jfrog_credentials() {
  if [ "${JFROG_USERNAME:-UNSET}" == "UNSET" ]; then
    read -p "JFrog username: " JFROG_USERNAME
  fi

  if [ "${JFROG_PASSWORD:-UNSET}" == "UNSET" ]; then
    read -s -p "JFrog password: " JFROG_PASSWORD
  fi

  export JFROG_USERNAME
  export JFROG_PASSWORD
}

package_prompt_for_gpg_credentials() {
  if [ "${GPG_KEY_ID:-UNSET}" == "UNSET" ]; then
    read -p "Enter GPG key ID: " GPG_KEY_ID
  fi

  if [ "${GPG_PASSPHRASE:-UNSET}" == "UNSET" ]; then
    read -s -p "Enter GPG passphrase: " GPG_PASSPHRASE
    echo
  fi

  export GPG_KEY_ID
  export GPG_PASSPHRASE
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
