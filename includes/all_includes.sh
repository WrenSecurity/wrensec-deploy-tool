################################################################################
# Macro for including all other includes at once
################################################################################
SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_PATH}/constants.sh"
source "${SCRIPT_PATH}/shell_funcs.sh"
source "${SCRIPT_PATH}/git_funcs.sh"
source "${SCRIPT_PATH}/package_funcs.sh"
