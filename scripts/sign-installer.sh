#!/bin/bash

set -Eeuo pipefail

CURRENT_PROJECT_VERSION="$1"  # e.g. 2.75
[[ "${CURRENT_PROJECT_VERSION::1}" != "v" && "${CURRENT_PROJECT_VERSION::1}" != "V" ]] || { echo "using version name without v"; CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:1}"; }

BUILT_PRODUCTS_DIR="build/Jitouch_${CURRENT_PROJECT_VERSION}"
OBJROOT=build/staging
PKG_SCRIPTS_DIR="scripts/pkg"
PRODUCT_BUNDLE_IDENTIFIER="com.jitouch.Jitouch"
signing_cert="${SIGNING_CERTIFICATE:?Set SIGNING_CERTIFICATE to your Developer ID Installer certificate name.}"
notary_profile="${NOTARY_KEYCHAIN_PROFILE:?Set NOTARY_KEYCHAIN_PROFILE to your notarytool keychain profile.}"

echo "Notarizing Jitouch.prefPane"
( cd "$BUILT_PRODUCTS_DIR" && zip -r "Jitouch.prefPane.zip" "Jitouch.prefPane" )
xcrun notarytool submit "${BUILT_PRODUCTS_DIR}/Jitouch.prefPane.zip" --keychain-profile "${notary_profile}" --wait
xcrun stapler staple "${BUILT_PRODUCTS_DIR}/Jitouch.prefPane"

echo "Making Install-Jitouch.pkg"
rm -rf "$OBJROOT"/*
mkdir -p "$OBJROOT/pkg_staging/"
cp -rp "${BUILT_PRODUCTS_DIR}/Jitouch.prefPane" "${OBJROOT}/pkg_staging/Jitouch.prefPane"
xattr -cr "${OBJROOT}/pkg_staging/Jitouch.prefPane"
pkgbuild --root "${OBJROOT}/pkg_staging/" --component-plist prefpane/components.plist --scripts "${PKG_SCRIPTS_DIR}" --identifier "${PRODUCT_BUNDLE_IDENTIFIER}" --version "${CURRENT_PROJECT_VERSION}" --sign "${signing_cert}" --timestamp "${OBJROOT}/JitouchPrefpane.pkg" --install-location /Library/PreferencePanes
productbuild --distribution prefpane/distribution.xml --package-path "${OBJROOT}" --identifier "${PRODUCT_BUNDLE_IDENTIFIER}" --version "${CURRENT_PROJECT_VERSION}" --sign "${signing_cert}" --timestamp "${BUILT_PRODUCTS_DIR}/Install-Jitouch.pkg"

echo "Notarizing Install-Jitouch.pkg"
xcrun notarytool submit "${BUILT_PRODUCTS_DIR}/Install-Jitouch.pkg" --keychain-profile "${notary_profile}" --wait
spctl --assess -vv --type install "${BUILT_PRODUCTS_DIR}/Install-Jitouch.pkg"
