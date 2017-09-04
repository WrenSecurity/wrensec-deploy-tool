################################################################################
# Macro for including all other includes at once
################################################################################
INCLUDE_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${INCLUDE_PATH}/constants.sh"

# Must appear before the others
source "${INCLUDE_PATH}/shell_funcs.sh"

# The rest are in alphabetical order
source "${INCLUDE_PATH}/creds_funcs.sh"
source "${INCLUDE_PATH}/git_funcs.sh"
source "${INCLUDE_PATH}/java_funcs.sh"
source "${INCLUDE_PATH}/package_funcs.sh"


