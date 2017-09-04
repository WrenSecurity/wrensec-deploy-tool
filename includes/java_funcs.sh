java_get_jdk_tools_path() {
  local jdk_path=$(java_get_jdk_path)
  local jdk_tools_path="${jdk_path}/lib/tools.jar"

  if [ ! -f "${jdk_tools_path}" ]; then
    echo_error "Could not locate 'tools.jar'. Expected to find it at" \
               "'${jdk_tools_path}'."
    return -1
  else
    echo "${jdk_tools_path}"
  fi
}

java_get_jdk_path() {
  local javac_run_path=$(type -P javac || echo "MISSING")

  if [ "${javac_run_path}" == 'MISSING' ]; then
    echo_error "The location of the JDK could not be detected."
    return -1
  else
    local javac_actual_path=$(readlink -f "${javac_run_path}")
    local bin_path=$(dirname "${javac_actual_path}")
    local jdk_path=$(dirname "${bin_path}")

    echo "${jdk_path}"
  fi
}

java_get_version() {
  java -version 2>&1 | head -n 1 | sed -r 's/.* version "(.*)"/\1/'
}
