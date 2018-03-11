################################################################################
# Credential Management Functions
################################################################################
creds_prompt_for_jfrog_credentials() {
  if [ "${JFROG_USERNAME:-UNSET}" == "UNSET" ]; then
    read -p "JFrog username: " JFROG_USERNAME
  else
    echo "Using JFrog username '${JFROG_USERNAME}'."
  fi

  if [ "${JFROG_PASSWORD:-UNSET}" == "UNSET" ]; then
    read -s -p "JFrog password: " JFROG_PASSWORD
    echo
  else
    echo "JFrog password is already set; not prompting."
  fi

  export JFROG_USERNAME
  export JFROG_PASSWORD
}

creds_prompt_for_gpg_credentials() {
  key_id="${1}"
  passphrase_var="${key_id}_PASSPHRASE"

  if [ "${!passphrase_var:-UNSET}" == "UNSET" ]; then
    read -s -p \
      "Enter GPG passphrase for GPG Key ID '${key_id}': " "${passphrase_var}"

    echo
  else
    echo "GPG passphrase for GPG Key ID '${key_id}' is already set; not" \
      "prompting."
  fi

  export "${passphrase_var}"
}
