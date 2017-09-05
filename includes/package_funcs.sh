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
  local compile_args=$(package_get_mvn_compile_args)

  package_invoke_maven clean install ${compile_args}
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
  local compile_args=$(package_get_mvn_compile_args)
  local passphrase_var="${WREN_OFFICIAL_SIGN_KEY_ID}_PASSPHRASE"

  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  package_invoke_maven clean deploy ${compile_args} \
    "-Psign,forgerock-release" \
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
  # TODO: Consider building this in as a separate profile in the parent POM
  # Maven can probably do a better job with this than Bash
  #
  #
  #  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"
  #
  #  package_invoke_maven verify -Pforgerock-release ${compile_args} \
  #    "-Dgpg.keyname=${WREN_OFFICIAL_SIGN_KEY_ID}" \
  #    "-Dgpg.passphrase=${GPG_PASSPHRASE}" \
  #    "-Dpgpverify.failNoSignature=false" \
  #    "-DpgpVerifyPluginVersion=1.2.0-SNAPSHOT"

  package_invoke_maven \
    com.github.s4u.plugins:pgpverify-maven-plugin:1.2.0-SNAPSHOT:check \
    "-Dpgpverify.keysMapLocation=${WREN_DEP_KEY_WHITELIST}" \
    "-Dignore-artifact-sigs"
}

package_report_unapproved_sigs_for_current_version() {
  package_verify_keys_for_current_version | \
    grep "\[ERROR\] Not allowed artifact" -A 1 | \
    grep "0x" | \
    sed -r 's/^\s+//' |
    sort |
    uniq
}

package_sign_3p_artifacts_for_current_version() {
  local target_artifact_ids=( $(package_get_all_unsigned_3p_artifacts) )

  creds_prompt_for_gpg_credentials "${WREN_THIRD_PARTY_SIGN_KEY_ID}"

  package_sign_and_deploy_artifacts target_artifact_ids
}

##
# Takes in a list of Maven artifact IDs, parses them, signs them, and deploys.
#
# Artifact IDs come in in the format:
#   com.google.collections:google-collections:pom:1.0
#
# This is parsed and converted into an index of all files that correspond to
# a given artifact. Then, all artifacts for the given artifact are signed and
# deployed to the remote provider.
#
# (Apologies in advance for the sheer length of this function. Unfortunately,
# passing arrays and hashes between functions is extremely difficult in bash.)
#
package_sign_and_deploy_artifacts() {
  # TODO: Consider building this in as a separate profile in the parent POM
  # Maven can probably do a better job with this than Bash
  #
  declare -n file_list=$1

  declare -A combined_artifact_ids
  declare -A artifact_index

  local passphrase_var="${WREN_THIRD_PARTY_SIGN_KEY_ID}_PASSPHRASE"
  local package_regex="^([^:]+):([^:]+):([^:]+):(.+)$"
  local tmpdir=$(mktemp -d '/tmp/wren-deploy.XXXXXXXXXX')

  # Index all the files, so we can find the POM
  for file in "${file_list[@]}"; do
    if [[ $file =~ $package_regex ]]; then
      local group_id="${BASH_REMATCH[1]}"
      local artifact_id="${BASH_REMATCH[2]}"
      local classifier="${BASH_REMATCH[3]}"
      local version="${BASH_REMATCH[4]}"

      local combined_id="${group_id}:${artifact_id}:${version}"
      local path="${group_id//\./\/}/${artifact_id}/${version}/${artifact_id}-${version}.${classifier}"

      # We're using a hash to de-dupe the IDs for us
      combined_artifact_ids["${combined_id}"]=1

      artifact_index["${combined_id}_group_id"]="${group_id}"
      artifact_index["${combined_id}_artifact_id"]="${artifact_id}"
      artifact_index["${combined_id}_version"]="${version}"

      artifact_index["${combined_id}_classifiers"]+="${classifier} "
      artifact_index["${combined_id}_${classifier}_path"]="${path}"
    fi
  done

  # Now, deploy each artifact
  for combined_id in "${!combined_artifact_ids[@]}"; do
    local group_id_key="${combined_id}_group_id"
    local group_id="${artifact_index[$group_id_key]}"

    local artifact_id_key="${combined_id}_artifact_id"
    local artifact_id="${artifact_index[$artifact_id_key]}"

    local version_key="${combined_id}_version"
    local version="${artifact_index[$version_key]}"

    local classifiers_key="${combined_id}_classifiers"
    local classifier_str="${artifact_index[$classifiers_key]}"
    local classifiers=()

    for classifier in $(echo "${classifier_str}"); do
      classifiers+=($classifier)
    done

    declare -a deploy_classifiers=()
    declare -a deploy_files=()

    for classifier in "${classifiers[@]}"; do
      local path_key="${combined_id}_${classifier}_path"
      local relative_file_path="${artifact_index[$path_key]}"
      local full_file_path="${HOME}/.m2/repository/${relative_file_path}"

      if [ ! -f "${full_file_path}" ]; then
        echo_error "Unable to sign '${relative_file_path}' because artifact" \
                   "was not located in the local Maven repository at" \
                   "'${full_file_path}'. Skipping..."
      else
        local base_name=$(basename "${full_file_path}")
        local tmp_file_path="${tmpdir}/${base_name}"

        # Copy to temp path because you cannot deploy out of the local M2 repo
        cp "${full_file_path}" "${tmp_file_path}"

        if [ "${classifier}" == 'pom' ]; then
          local classifier_count="${#classifiers[@]}"

          pomFile="${tmp_file_path}"

          # Special case: The POM is the only file
          if [ "${classifier_count}" -eq 1 ]; then
            deploy_files+=($tmp_file_path)
          fi
        else
          deploy_files+=($tmp_file_path)
        fi
      fi
    done

    for deploy_file in "${deploy_files[@]}"; do
      # `generatePom` is TRUE just in case we did not encounter a POM.
      # Per docs, it should not actually get generated unless `pomFile` is
      # blank.
      package_invoke_maven gpg:sign-and-deploy-file \
        "-DrepositoryId=${THIRD_PARTY_SIGNED_REPO_ID}" \
        "-Durl=${THIRD_PARTY_RELEASES_URL}" \
        "-DgeneratePom=true" \
        "-DpomFile=${pomFile:-}" \
        "-Dfile=${deploy_file}" \
        "-DgroupId=${group_id}" \
        "-DartifactId=${artifact_id}" \
        "-Dversion=${version}" \
        "-Dgpg.keyname=${WREN_THIRD_PARTY_SIGN_KEY_ID}" \
        "-Dgpg.passphrase=${!passphrase_var}"
    done
  done

  rm -rf "${tmpdir}"
}

package_get_all_unsigned_3p_artifacts() {
  package_verify_keys_for_current_version | \
  grep "\[WARNING\] No signature for" | \
  sed -r 's/^\[WARNING\] No signature for (.*)$/\1/' |
  sort
}

package_sign_tools_jar() {
  local tmpdir=$(mktemp -d '/tmp/wren-deploy.XXXXXXXXXX')

  local java_version=$(java_get_version)
  local tools_jar_path=$(java_get_jdk_tools_path)
  local tools_jar_deploy_path="${THIRD_PARTY_SIGNED_PATH}/com/sun/tools/${java_version}/tools-${java_version}.jar"
  local tools_jar_tmp_path="${tmpdir}/tools.jar"

  local passphrase_var="${WREN_THIRD_PARTY_SIGN_KEY_ID}_PASSPHRASE"

  cp "${tools_jar_path}" "${tools_jar_tmp_path}"

  package_invoke_maven gpg:sign-and-deploy-file \
    "-DrepositoryId=${THIRD_PARTY_SIGNED_REPO_ID}" \
    "-Durl=${THIRD_PARTY_RELEASES_URL}" \
    "-Dfile=${tools_jar_tmp_path}" \
    "-DgroupId=com.sun" \
    "-DartifactId=tools" \
    "-Dversion=${java_version}" \
    "-Dgpg.keyname=${WREN_THIRD_PARTY_SIGN_KEY_ID}" \
    "-Dgpg.passphrase=${!passphrase_var}"

  rm -rf "${tmpdir}"

  # Per Oracle licensing, we CANNOT actually publish the JAR file itself.
  package_delete_file_from_jfrog "${tools_jar_deploy_path}"
}

package_delete_from_bintray() {
  local maven_package="${1}"
  local bintray_package="${2}"

  creds_prompt_for_bintray_credentials

  for tag in $(git_list_release_tags "${maven_package}"); do
    curl -X "DELETE" -u "${BINTRAY_USERNAME}:${BINTRAY_PASSWORD}" \
      "${BINTRAY_PROVIDER_BASE_URL}/${bintray_package}/versions/${tag}"
  done
}

package_delete_from_jfrog() {
  local jfrog_package="${1}"

  package_delete_file_from_jfrog "releases-local/${jfrog_package}"
}

package_delete_file_from_jfrog() {
  local file_path="${1}"

  creds_prompt_for_jfrog_credentials

  curl -X "DELETE" -u "${JFROG_USERNAME}:${JFROG_PASSWORD}" \
    "${JFROG_PROVIDER_BASE_URL}/${file_path}"
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

package_get_mvn_compile_args() {
  local default_compile_args=${WREN_DEFAULT_MVN_COMPILE_ARGS:-}
  local compile_args=${MVN_COMPILE_ARGS:-${default_compile_args}}

  echo $compile_args
}

package_invoke_maven() {
  local maven_args=( "$@" )
  local clean_args=()

  for arg in ${maven_args[@]}; do
    # Exclude passphrase from appearing in the log
    if [[ "${arg}" =~ ^\-Dgpg\.passphrase=.*$ ]]; then
      clean_args+=('-Dgpg.passphrase=XXXXXXXXXX')
    else
      clean_args+=($arg)
    fi
  done

  echo mvn ${clean_args[@]}
  mvn ${maven_args[@]}
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
