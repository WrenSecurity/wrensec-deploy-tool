#!/bin/bash

set -e
set -u

################################################################################
# Includes
################################################################################
SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_PATH}/includes/all_includes.sh"

################################################################################
# Main Script
################################################################################
if [ ! -d "wrensec-parent" ]; then
  echo_error "Run this from the top-level directory of Wren projects."
  exit -1
fi

# Don't allow a failure to delete to hold up deployment.
#"${SCRIPT_PATH}/delete_all_deployed_packages.sh" || true

parent_failed=1
tools_failed=1

# We expect failures until we're done with the cycle
set +e

# Workaround for cyclic dependencies...
until [[ "$parent_failed" -eq 0 && "$tools_failed" -eq 0 ]]; do
  echo "======================================================================="
  echo "Pre-compiling WrenSec Build Tools and WrenSec Parent POM"
  echo "======================================================================="
  echo "Due to cyclic dependencies between these two projects, it is safe to"
  echo "ignore any intermittent failures you see below until all versions of "
  echo "both projects compile."
  echo

  cd ./wrensec-parent
  ../wrensec-deploy-tool/wren-deploy.sh compile-all-releases $@
  parent_failed=$?
  cd ..

  cd ./wrensec-build-tools
  ../wrensec-deploy-tool/wren-deploy.sh compile-all-releases $@
  tools_failed=$?
  cd ..
done

set -e

for project in ${PROJECTS[@]}; do
  echo "======================================================================="
  echo "Deploying ${project}"
  echo "======================================================================="

  cd "./${project}"
  ../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
  cd ..

  echo
  echo
done
