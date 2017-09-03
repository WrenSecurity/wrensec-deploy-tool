#!/bin/bash

set -e
set -u

################################################################################
# Includes
################################################################################
SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_PATH}/includes/shell_funcs.sh"

################################################################################
# Main Script
################################################################################
if [ ! -d "wrensec-parent" ]; then
  echo_error "Run this from the top-level directory of Wren projects."
  exit -1
fi

rm -rf ~/.m2/repository

set -x

cd ./wrensec-build-tools
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases $@
cd ..

cd ./wrensec-parent
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases $@
cd ..

cd ./wrensec-util
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases $@
cd ..

cd ./wrensec-bom
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases $@
cd ..

cd ./wrensec-i18n-framework
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases $@
cd ..


