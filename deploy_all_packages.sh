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

./delete_all_deployed_packages.sh

parent_failed=1
tools_failed=1

set +e
set -x

# Workaround for cyclic dependencies...
until [[ "$parent_failed" -eq 0 && "$tools_failed" -eq 0 ]]; do
  cd ./wrensec-build-tools
  ../wrensec-deploy-tool/wren-deploy.sh compile-all-releases $@
  tools_failed=$?
  cd ..

  cd ./wrensec-parent
  ../wrensec-deploy-tool/wren-deploy.sh compile-all-releases $@
  parent_failed=$?
  cd ..
done;

set -e

cd ./wrensec-build-tools
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-parent
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-bom
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-util
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-i18n-framework
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-guice
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-http-framework
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..

cd ./wrensec-rest
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases $@
cd ..


