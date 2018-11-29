################################################################################
# Shared Constants
################################################################################
export WRENDEPLOY_VERSION="2.1.0-SNAPSHOT"
export WRENDEPLOY_BASE_PATH=$(dirname $(dirname "$(readlink -f "$BASH_SOURCE")"))

export PGPVERIFY_VERSION="LATEST"

export WRENDEPLOY_RC=".wren-deploy.rc"

export JFROG_PROVIDER_BASE_URL="https://wrensecurity.jfrog.io/wrensecurity"

export BINTRAY_PROVIDER_BASE_URL="https://bintray.com/wrensecurity"
export BINTRAY_PROVIDER_PUBLISH_BASE_URL="https://api.bintray.com/maven/wrensecurity"

export CONSENSUS_VERIFIED_REPO_ID="bintray-wrensecurity-releases"
export CONSENSUS_VERIFIED_PATH="forgerock-archive/consensus-verified"
export CONSENSUS_VERIFIED_RELEASES_URL="${BINTRAY_PROVIDER_PUBLISH_BASE_URL}/${CONSENSUS_VERIFIED_PATH};publish=1"

export THIRD_PARTY_SIGNED_REPO_ID="wrensecurity-signed-third-party-releases"
export THIRD_PARTY_SIGNED_PATH="releases-signed-third-party"
export THIRD_PARTY_RELEASES_URL="${JFROG_PROVIDER_BASE_URL}/${THIRD_PARTY_SIGNED_PATH}"

export WREN_OFFICIAL_SIGN_KEY_ID="C081F89B"
export WREN_THIRD_PARTY_SIGN_KEY_ID="D7F749B5"

export WREN_DEP_PGP_WHITELIST_DEFAULT_PATH="${WRENDEPLOY_BASE_PATH}/../wrensec-pgp-whitelist"
export WREN_DEP_PGP_WHITELIST_FILENAME="trustedkeys.properties"
export WREN_DEP_PGP_WHITELIST_RESOURCE_PATH="src/main/resources/${WREN_DEP_PGP_WHITELIST_FILENAME}"
export WREN_DEP_PGP_WHITELIST_URL="${WREN_DEP_PGP_WHITELIST_URL:-file:///${WREN_DEP_PGP_WHITELIST_DEFAULT_PATH}/${WREN_DEP_PGP_WHITELIST_RESOURCE_PATH}}"
