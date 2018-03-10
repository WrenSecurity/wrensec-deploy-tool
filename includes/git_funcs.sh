################################################################################
# Shared GIT Functions
################################################################################
git_ref_to_rev() {
  git_ref="${1}"
  git_revision=$(git rev-parse "${git_ref}")

  if [ "${git_ref}" != "${git_revision}" ]; then
    ref_desc="'${git_ref}' (at ${git_revision:0:7})"
  else
    ref_desc="'${git_ref:0:7}'"
  fi

  export git_revision
  export ref_desc
}

git_bulk_cherry_pick() {
  local src_ref="${1:-HEAD}"
  local first_dst_rel_tag="${2:-UNSET}"

  revision_at_start=$(git symbolic-ref HEAD | sed "s/refs\/heads\///")

  git_ref_to_rev "${src_ref}"

  if [ "${first_dst_rel_tag}" != "UNSET" ]; then
    starting_target_rev=$(git rev-parse "sustaining/${first_dst_rel_tag}")
    cherry_picking_started=0
  else
    starting_target_rev="UNSET"
    cherry_picking_started=1
  fi

  for tag in $(git_list_sustaining_versions); do
    current_branch_name="sustaining/${tag}"

    if ! package_accept_release_tag "${tag}"; then
      echo "Will not cherry pick ${ref_desc} on to '${current_branch_name}'" \
           "(tag skipped by .wren-deploy.rc)."
    else
      git checkout "${current_branch_name}" >/dev/null

      current_revision=$(git rev-parse HEAD)

      if [[ "${cherry_picking_started}" -eq 0 && \
            "${current_revision}" == "${starting_target_rev}" ]]; then
        cherry_picking_started=1
      fi

      if [[ "${cherry_picking_started}" -ne 1 ]]; then
        echo "Skipping '${current_revision:0:7}'..."

      elif [ "${current_revision}" == "${git_revision}" ]; then
        echo "Will not cherry pick ${ref_desc} on to" \
             "'${current_revision:0:7}' (same revision)."

      else
        echo "Cherry picking ${ref_desc} on to '${current_revision:0:7}'"
        echo
        git cherry-pick "${git_revision}"
      fi
    fi

    echo
  done

  git checkout "${revision_at_start}"
}

git_get_sorted_tag_list() {
  git tag | sort -V
}

git_get_current_sustaining_version() {
  git_get_current_branch_name | sed "s/^sustaining\///"
}

git_list_sustaining_versions() {
  git_list_release_branches | sed "s/^sustaining\///"
}

git_list_release_branches() {
  git_get_branch_list | grep -e "^sustaining/" | sort -V
}

git_get_current_branch_name() {
  git symbolic-ref HEAD --short
}

git_get_branch_list() {
  git for-each-ref --format '%(refname:short)' refs/heads/
}

git_branch_exists() {
  local branch_name="${1}"

  branch_count=$(git branch --list "${branch_name}" | wc | awk '{ print $1 }')

  [ "${branch_count}" -ne 0 ]
  return $?
}
