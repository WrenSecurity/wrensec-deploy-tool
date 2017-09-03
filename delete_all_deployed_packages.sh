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

rm -rf ~/.m2/repository

set -x

for project in ${PROJECTS[*]}; do
  cd "./${project}"
  ../wrensec-deploy-tool/wren-deploy.sh delete-all-releases $@
  cd ..
done