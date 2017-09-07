################################################################################
# Shared Constants
################################################################################
export PROJECTS=( \
  "wrensec-parent" \
  "wrensec-build-tools" \
  "wrensec-bom" \
  "wrensec-util" \
  "wrensec-i18n-framework" \
  "wrensec-guice" \
  "wrensec-http-framework" \
  "wrensec-rest" \
  "wrensec-audit" \
  "wrensec-persistit" \
  "wrends-sdk" \
  "wrends" \
)

export WRENDEPLOY_RC=".wren-deploy.rc"

export DEFAULT_PACKAGE_PROVIDER="jfrog"

export JFROG_PROVIDER_BASE_URL="https://wrensecurity.jfrog.io/wrensecurity"
export BINTRAY_PROVIDER_BASE_URL="https://api.bintray.com/packages/wrensecurity/releases"

export THIRD_PARTY_SIGNED_REPO_ID="wrensecurity-signed-third-party-releases"
export THIRD_PARTY_SIGNED_PATH="releases-signed-third-party"
export THIRD_PARTY_RELEASES_URL="${JFROG_PROVIDER_BASE_URL}/${THIRD_PARTY_SIGNED_PATH}"

export WREN_OFFICIAL_SIGN_KEY_ID="C081F89B"
export WREN_THIRD_PARTY_SIGN_KEY_ID="D7F749B5"

export WREN_DEP_KEY_WHITELIST="http://wrensecurity.org/trustedkeys.properties"

