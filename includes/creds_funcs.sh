################################################################################
# Credential Management Functions
################################################################################
creds_prompt_for_bintray_credentials() {
  if [ "${BINTRAY_USERNAME:-UNSET}" == "UNSET" ]; then
    read -p "BinTray username: " BINTRAY_USERNAME
  else
    echo "Using BinTray username '${BINTRAY_USERNAME}'."
  fi

  if [ "${BINTRAY_PASSWORD:-UNSET}" == "UNSET" ]; then
    read -s -p "BinTray password: " BINTRAY_PASSWORD
    echo
  else
    echo "BinTray password is already set; not prompting."
  fi

  export BINTRAY_USERNAME
  export BINTRAY_PASSWORD
}

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
  if [ "${GPG_KEY_ID:-UNSET}" == "UNSET" ]; then
    read -p "Enter GPG key ID: " GPG_KEY_ID
  else
    echo "Using GPG Key ID '${GPG_KEY_ID}'."
  fi

  if [ "${GPG_PASSPHRASE:-UNSET}" == "UNSET" ]; then
    read -s -p "Enter GPG passphrase: " GPG_PASSPHRASE
    echo
  else
    echo "GPG passphrase is already set; not prompting."
  fi

  export GPG_KEY_ID
  export GPG_PASSPHRASE
}
