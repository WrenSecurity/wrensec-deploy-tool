################################################################################
# Shared Bash Shell Functions
################################################################################
echo_error() {
  message="$@";

  echo "$message" 1>&2;
}

function_exists() {
  function_name="${1}"

  declare -F "${function_name}" > /dev/null
}

# From: https://stackoverflow.com/questions/14366390/check-if-an-element-is-present-in-a-bash-array
array_contains() {
  local needle=$1
  shift

  local in_array=1

  for element; do
    if [[ "${element}" == "${needle}" ]]; then
      in_array=0
      break
    fi
  done

  return ${in_array}
}

array_join() {
  local delimiter="${1}"
  local IFS="${delimiter}";

  shift;
  echo "$*";
}
