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

create_tmp_file() {
  tmpfile=$(mktemp)

  echo "${tmpfile}"
}

create_tmp_dir() {
  local tmpdir=$(mktemp -d '/tmp/wren-deploy.XXXXXXXXXX')

  echo "${tmpdir}"
}

delete_on_exit() {
  local target="${1}"

  add_on_exit "rm -rf -- ${target}"
}

# Credit:
# https://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
declare -a on_exit_items

function add_on_exit() {
  set +u

  local n=${#on_exit_items[*]}

  on_exit_items[$n]="$*"

  # Setup trap on the first item added to the list
  if [[ $n -eq 0 ]]; then
    trap dispatch_on_exit_items INT TERM HUP EXIT
  fi
}

function dispatch_on_exit_items() {
  set +u

  for i in "${on_exit_items[@]}"; do
    eval $i
  done
}
