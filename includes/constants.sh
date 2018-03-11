################################################################################
# Shared Constants
################################################################################
export WRENDEPLOY_VERSION="2.1.0"
export PGPVERIFY_VERSION="1.2.0-wren1"

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

export WREN_DEP_KEY_WHITELIST_FILENAME="trustedkeys.properties"
export WREN_DEP_KEY_WHITELIST_URL="http://wrensecurity.org/${WREN_DEP_KEY_WHITELIST_FILENAME}"
