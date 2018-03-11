################################################################################
# Shared Package Management Functions
################################################################################
package_create_all_sustaining_branches() {
  local maven_package="${1}"

  # Ignores tags that have manually been moved over the legacy "forgerock/"
  # namespace.
  local version_tags=$(\
    git_get_sorted_tag_list | \
      grep --invert-match -e "^forgerock/"\
  )

  for tag in ${version_tags[@]}; do
    local branch_name=$(\
      echo $tag | \
      sed "s/${maven_package}-//" | \
      sed 's/^/sustaining\//'\
    )

    if git_branch_exists "${branch_name}"; then
      echo "Sustaining branch ${branch_name} already exists; skipping."
    else
      git branch "${branch_name}" "${tag}"
      echo "Created ${branch_name}."
    fi
  done

  echo ""
}

package_tag_all_sustaining_versions() {
  for branch in $(git_list_release_branches); do
    local version="${branch//sustaining\//}"

    git tag "${version}" "${branch}" \
      --annotate \
      --sign \
      --message "Version ${version}";

    echo "Tagged and signed '${version}'."
  done

  echo ""
}

package_delete_all_sustaining_branches() {
  for branch in $(git_list_release_branches); do
    git branch -D "${branch}"
  done

  echo ""
}

package_compile_all_versions() {
  for tag in $(git_list_sustaining_versions); do
    if package_accept_release_tag "${tag}"; then
      git checkout "sustaining/${tag}"
      package_compile_current_version
    fi
  done
}

package_compile_current_version() {
  local compile_args=$(package_get_mvn_compile_args)
  local passphrase_var="${WREN_OFFICIAL_SIGN_KEY_ID}_PASSPHRASE"

  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  package_invoke_maven clean install ${compile_args} \
    "-Psign,forgerock-release" \
    "-Dgpg.keyname=${WREN_OFFICIAL_SIGN_KEY_ID}" \
    "-Dgpg.passphrase=${!passphrase_var}"
}

package_deploy_all_versions() {
  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  for tag in $(git_list_sustaining_versions); do
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
  creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"

  for tag in $(git_list_sustaining_versions); do
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
  package_invoke_maven \
    com.github.s4u.plugins:pgpverify-maven-plugin:${PGPVERIFY_VERSION}:check \
    "-Dpgpverify.keysMapLocation=${WREN_DEP_KEY_WHITELIST_URL}" \
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
  creds_prompt_for_gpg_credentials "${WREN_THIRD_PARTY_SIGN_KEY_ID}"

  # TODO: Consider building this in as a separate profile in the parent POM
  # Maven can probably do a better job with this than Bash
  #
  declare -n artifact_list=$1

  declare -A combined_artifact_ids
  declare -A artifact_index

  local passphrase_var="${WREN_THIRD_PARTY_SIGN_KEY_ID}_PASSPHRASE"
  local package_regex="^([^:]+):([^:]+):([^:]+):(.+)$"
  local tmpdir=$(mktemp -d '/tmp/wren-deploy.XXXXXXXXXX')

  # Index all the artifact files, so we can find the POM
  for artifact in "${artifact_list[@]}"; do
    if [[ $artifact =~ $package_regex ]]; then
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
    declare -A deploy_files=()

    # Very special case: POM is signed, but everything else isn't (e.g. xercesImpl:2.9.1).
    # Go figure that one out...
    if ! array_contains 'pom' ${classifiers[@]}; then
      local path_key="${combined_id}_pom_path"
      local pom_path=""${group_id//\./\/}/${artifact_id}/${version}/${artifact_id}-${version}.pom""

      classifiers+=( 'pom' )
      artifact_index[$path_key]="${pom_path}"

      echo_error "WARNING: '${artifact_id}:${version}' has a signed POM but" \
                 "unsigned artifacts. This is an unusual situation. The" \
                 "current signature on the POM is going to be disregarded so" \
                 "that the POM can be signed along with all of its artifacts."
      echo_error ""
    fi

    for classifier in "${classifiers[@]}"; do
      local path_key="${combined_id}_${classifier}_path"
      local relative_file_path="${artifact_index[$path_key]}"
      local full_file_path="${HOME}/.m2/repository/${relative_file_path}"

      if [ ! -f "${full_file_path}" ]; then
        echo_error "ERROR: Unable to sign '${relative_file_path}' because "\
                   "artifact was not located in the local Maven repository at" \
                   "'${full_file_path}'. Skipping..."
        echo_error ""
      else
        local base_name=$(basename "${full_file_path}")
        local tmp_file_path="${tmpdir}/${base_name}"

        # Copy to temp path because you cannot deploy out of the local M2 repo
        cp "${full_file_path}" "${tmp_file_path}"

        if [ "${classifier}" == 'pom' ]; then
          pom_file="${tmp_file_path}"
        fi

        deploy_files["${classifier}"]=$tmp_file_path
      fi
    done

    local classifier_count="${#classifiers[@]}"

    for classifier in "${classifiers[@]}"; do
      local deploy_file="${deploy_files[${classifier}]}"

      # Special case: Handle a situation in which the POM is the *only* file we're deploying
      if [[ "${classifier}" == "pom" && "${classifier_count}" -eq 1 ]]; then
        package_invoke_maven gpg:sign-and-deploy-file \
          "-DrepositoryId=${THIRD_PARTY_SIGNED_REPO_ID}" \
          "-Durl=${THIRD_PARTY_RELEASES_URL}" \
          "-Dfile=${deploy_file}" \
          "-Dgpg.keyname=${WREN_THIRD_PARTY_SIGN_KEY_ID}" \
          "-Dgpg.passphrase=${!passphrase_var}"

      elif [[ "${classifier}" != "pom" ]]; then
        package_invoke_maven gpg:sign-and-deploy-file \
          "-DrepositoryId=${THIRD_PARTY_SIGNED_REPO_ID}" \
          "-Durl=${THIRD_PARTY_RELEASES_URL}" \
          "-Dfile=${deploy_file}" \
          "-DpomFile=${pom_file}" \
          "-Dgpg.keyname=${WREN_THIRD_PARTY_SIGN_KEY_ID}" \
          "-Dgpg.passphrase=${!passphrase_var}"
      fi
    done
  done

  rm -rf "${tmpdir}"
}

##
# Takes in repo base path and a search page, search for artifact files, signs
# them, and deploys them to BinTray.
#
# This is used for so-called "consensus verified" artifacts -- copies of
# binaries from ForgeRock for which Wren does not yet have source code, that are
# being trusted because multiple independent copies of the binaries have the
# same hash (thus indicating it is unlikely that they were tampered with).
#
# Unlike `package_sign_and_deploy_artifacts`, this takes in a search path rather
# than a defined list of artifacts. A base path is necessary for determining
# which part of the search path represents the path to the repository, so that
# the rest can be interpreted as part of the package name (per Maven
# conventions (e.g. `org/forgerock/thing/3.0/thing-3.0` would be the path for
# `org.forgerock:thing:3.0` within a repo).
#
# (Apologies in advance for the sheer length of this function. Unfortunately,
# passing arrays and hashes between functions is extremely difficult in bash.)
#
package_sign_and_deploy_consensus_signed_artifact() {
  creds_prompt_for_gpg_credentials "${WREN_THIRD_PARTY_SIGN_KEY_ID}"

  local repo_base_path=$(realpath "${1}")
  local search_path=$(realpath "${2}")

  local file_list=$(\
    find "${search_path}" \
      -type f \
      -not -name '*.md5' \
      -not -name '*.sha1' \
      -not -name '*.lastUpdated' \
      -not -name '_*.*' | \
    sed "s!${repo_base_path}\/!!" \
  )

  declare -A combined_artifact_ids
  declare -A artifact_index

  local passphrase_var="${WREN_THIRD_PARTY_SIGN_KEY_ID}_PASSPHRASE"
  local path_regex="^(.+)\/([^\/]+)\/([^\/]+)\/(.+)-([0-9\.]+)(-(.*))?\.(.*)$"
  local tmp_dir=$(mktemp -d '/tmp/wren-deploy.XXXXXXXXXX')

  # Index all the files and locate the POM
  for file in ${file_list}; do
    if [[ $file =~ $path_regex ]]; then
      local group_id="${BASH_REMATCH[1]//\//.}"
      local artifact_id="${BASH_REMATCH[2]}"
      local classifier="${BASH_REMATCH[7]}"
      local version="${BASH_REMATCH[5]}"
      local extension="${BASH_REMATCH[8]}"

      local combined_id="${group_id}:${artifact_id}:${version}"
      local path="${repo_base_path}/${file}"

      # We're using a hash to de-dupe the IDs for us
      combined_artifact_ids["${combined_id}"]=1

      artifact_index["${combined_id}_group_id"]="${group_id}"
      artifact_index["${combined_id}_artifact_id"]="${artifact_id}"
      artifact_index["${combined_id}_version"]="${version}"

      if [ "${extension}" == "pom" ]; then
        artifact_index["${combined_id}_pom_file"]="${path}"
      else
        local classifier_and_ext="${classifier}-${extension}"

        artifact_index["${combined_id}_classifiers"]+="${classifier_and_ext} "
        artifact_index["${combined_id}_${classifier_and_ext}_path"]="${path}"
      fi
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

    local pom_key="${combined_id}_pom_file"
    local pom_file="${artifact_index[$pom_key]:-}" # Missing POM handled below

    local classifiers_key="${combined_id}_classifiers"
    local classifier_str="${artifact_index[$classifiers_key]:-}"
    local classifiers=()

    echo ""
    echo "Found ${combined_id}"
    echo ""

    for classifier in $(echo "${classifier_str}"); do
      classifiers+=($classifier)
    done

    declare -a deploy_classifiers=()
    declare -A deploy_files=()

    for classifier in "${classifiers[@]}"; do
      local path_key="${combined_id}_${classifier}_path"
      local file_path="${artifact_index[$path_key]}"

      if [ ! -f "${file_path}" ]; then
        echo_error "ERROR: Unable to publish '${combined_id}' because the" \
                   "artifact was unexpectedly not found at '${file_path}'." \
                   "Skipping..."
        echo_error ""
      else
        local base_name=$(basename "${file_path}")
        local tmp_file_path="${tmp_dir}/${base_name}"

        # Copy to temp path to avoid modifying the source files
        cp "${file_path}" "${tmp_file_path}"

        deploy_files["${classifier}"]=$tmp_file_path
      fi
    done

    local classifier_count="${#classifiers[@]}"

    if [ -f "${pom_file}" ]; then
      local base_pom_name=$(basename "${pom_file}")
      local tmp_pom_file_path="${tmp_dir}/${base_pom_name}"

      # Copy to temp path to avoid modifying the source files
      cp "${pom_file}" "${tmp_pom_file_path}"

      # Special case: Handle a situation in which the POM is the *only* file we're deploying
      if [ "${classifier_count}" -eq 0 ]; then
        package_invoke_maven gpg:sign-and-deploy-file \
          "-DrepositoryId=${CONSENSUS_VERIFIED_REPO_ID}" \
          "-Durl=${CONSENSUS_VERIFIED_RELEASES_URL}" \
          "-Dfile=${tmp_pom_file_path}" \
          "-Dgpg.keyname=${WREN_THIRD_PARTY_SIGN_KEY_ID}" \
          "-Dgpg.passphrase=${!passphrase_var}"
      else
        for classifier in "${classifiers[@]}"; do
          local deploy_file="${deploy_files[${classifier}]}"

          package_invoke_maven gpg:sign-and-deploy-file \
            "-DrepositoryId=${CONSENSUS_VERIFIED_REPO_ID}" \
            "-Durl=${CONSENSUS_VERIFIED_RELEASES_URL}" \
            "-Dfile=${deploy_file}" \
            "-DpomFile=${tmp_pom_file_path}" \
            "-Dgpg.keyname=${WREN_THIRD_PARTY_SIGN_KEY_ID}" \
            "-Dgpg.passphrase=${!passphrase_var}"
        done
      fi

      echo ""
    else
      pom_search_folder=$(dirname "${file_path}")

      echo_error "ERROR: Unable to publish '${combined_id}' because the POM " \
                 "was not found in '${pom_search_folder}'. Skipping..."
      echo_error ""
    fi
  done

  rm -rf "${tmp_dir}"
}

package_get_all_unsigned_3p_artifacts() {
  package_verify_keys_for_current_version | \
    grep "\[WARNING\] No signature for" | \
    sed -r 's/^\[WARNING\] No signature for (.*)$/\1/' |
    sort
}

package_capture_unapproved_sigs_for_current_version() {
  local wrensec_home_path="${1}"

  local should_amend="${2}"
  local should_push="${3}"
  local should_force="${4}"

  local trusted_key_path=$(\
    realpath "${wrensec_home_path}/${WREN_DEP_KEY_WHITELIST_FILENAME}" \
  )

  local git_dir=$(\
    realpath "${wrensec_home_path}/.git" \
  )

  local git_cmd="git --work-tree=${wrensec_home_path} --git-dir=${git_dir}"

  local package_name="${MAVEN_PACKAGE}"
  local package_version=$(package_get_mvn_version)

  echo "Appending dependencies to '${trusted_key_path}'"
  echo ""
  package_get_all_unsigned_3p_artifacts >> "${trusted_key_path}"

  echo "Changes:"
  echo ""
  ${git_cmd} diff

  echo ""
  echo "Committing..."
  echo ""
  ${git_cmd} add "${trusted_key_path}"

  if [ "${should_amend}" == "1" ]; then
    ${git_cmd} commit --amend --no-edit
  else
    commit_message="Add deps for \`${package_name}\` ${package_version}"

    ${git_cmd} commit "--message=${commit_message}" --no-edit
  fi

  if [ "${should_push}" == "1" ]; then
    if [ "${should_force}" == "1" ]; then
      local push_option="--force-with-lease"
    else
      local push_option=""
    fi

    echo "Pushing..."
    echo ""
    ${git_cmd} push ${push_option} origin
  fi
}

package_sign_tools_jar() {
  local tmp_dir=$(mktemp -d '/tmp/wren-deploy.XXXXXXXXXX')

  local java_version=$(java_get_version)
  local tools_jar_path=$(java_get_jdk_tools_path)
  local tools_jar_deploy_path="${THIRD_PARTY_SIGNED_PATH}/com/sun/tools/${java_version}/tools-${java_version}.jar"
  local tools_jar_tmp_path="${tmp_dir}/tools.jar"

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

  rm -rf "${tmp_dir}"

  # Per Oracle licensing, we CANNOT actually publish the JAR file itself.
  package_delete_file_from_jfrog "${tools_jar_deploy_path}"
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
    echo_error "A '${WRENDEPLOY_RC}' file must exist in this package in order" \
               "to be deployable."
    return 1
  else
    source "${WRENDEPLOY_RC}"
  fi
}

package_get_mvn_version() {
  mvn com.smartcodeltd:release-candidate-maven-plugin:LATEST:version --quiet
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
