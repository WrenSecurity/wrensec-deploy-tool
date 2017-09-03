#!/bin/bash

set -e
set -u

PACKAGE_PROVIDER="jfrog"

set -x

rm -rf ~/.m2/repository

cd ..

cd ./wrensec-build-tools
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-parent
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-util
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-bom
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..

cd ./wrensec-i18n-framework
../wrensec-deploy-tool/wren-deploy.sh delete-all-releases "--with-provider=${PACKAGE_PROVIDER}"
cd ..


