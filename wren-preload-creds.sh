################################################################################
# Wren Deploy Credential Pre-Loader
# =================================
# Lets the user provide credentials for JFrog / GPG up-front, once during a bash
# terminal session, instead of having to enter them in every time they are
# needed for operations.
#
# Usage: source wren-preload-creds.sh
#
# Credentials are exported into environment variables that exist only for the
# remainder of the shell session. The script must be invoked through `source`
# rather than being executed as a standalone script so that the commands it
# executes occur in the user's Bash session, preserving the exported environment
# variables.
#
# @author Kortanul (kortanul@protonmail.com)
#
################################################################################

################################################################################
# Includes
################################################################################
SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_PATH}/includes/all_includes.sh"

################################################################################
# Main Script
################################################################################
creds_prompt_for_jfrog_credentials

creds_prompt_for_gpg_credentials "${WREN_OFFICIAL_SIGN_KEY_ID}"
creds_prompt_for_gpg_credentials "${WREN_THIRD_PARTY_SIGN_KEY_ID}"
