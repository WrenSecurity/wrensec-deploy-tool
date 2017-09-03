################################################################################
# Macro for including all other includes at once
################################################################################
SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_PATH}/constants.sh"

# Must appear before the others
source "${SCRIPT_PATH}/shell_funcs.sh"

# The rest are in alphabetical order
source "${SCRIPT_PATH}/creds_funcs.sh"
source "${SCRIPT_PATH}/git_funcs.sh"
source "${SCRIPT_PATH}/package_funcs.sh"


