#!/bin/bash

set -e
set -u

PACKAGE_PROVIDER="jfrog"

set +e

./delete_all_deployed_packages.sh || exit

cd ..

parent_failed=1
tools_failed=1

set -x

# Workaround for cyclic dependencies...
until [[ "$parent_failed" -eq 0 && "$tools_failed" -eq 0 ]]; do
  cd ./wrensec-build-tools
  ../wrensec-deploy-tool/wren-deploy.sh compile-all-releases
  tools_failed=$?
  cd ..

  cd ./wrensec-parent
  ../wrensec-deploy-tool/wren-deploy.sh compile-all-releases
  parent_failed=$?
  cd ..
done;

set -e

cd ./wrensec-build-tools
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-parent
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-bom
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-util
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-i18n-framework
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-guice
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-http-framework
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-rest
../wrensec-deploy-tool/wren-deploy.sh deploy-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..


