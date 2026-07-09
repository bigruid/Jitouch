#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DERIVED_DATA="${ROOT_DIR}/.derived-jitouch"
PREFPANE_DERIVED_DATA="${ROOT_DIR}/.derived-prefpane"
APP_PROJECT="${ROOT_DIR}/jitouch/Jitouch/Jitouch.xcodeproj"
PREFPANE_PROJECT="${ROOT_DIR}/prefpane/Jitouch.xcodeproj"
APP_PRODUCT="${APP_DERIVED_DATA}/Build/Products/Release/Jitouch.app"
PREFPANE_STAGING_APP="${ROOT_DIR}/prefpane/Jitouch.app"
PREFPANE_PRODUCT="${PREFPANE_DERIVED_DATA}/Build/Products/Release/Jitouch.prefPane"
COMPONENTS_PLIST="${ROOT_DIR}/prefpane/components.plist"
DISTRIBUTION_XML="${ROOT_DIR}/prefpane/distribution.xml"
PRODUCT_BUNDLE_IDENTIFIER="com.jitouch.Jitouch"

build_app() {
  echo "Building Jitouch.app (Release)"
  xcodebuild \
    -project "${APP_PROJECT}" \
    -scheme Jitouch \
    -configuration Release \
    -derivedDataPath "${APP_DERIVED_DATA}" \
    build
}

stage_prefpane_app() {
  echo "Updating prefpane/Jitouch.app"
  rm -rf "${PREFPANE_STAGING_APP}"
  cp -Rp "${APP_PRODUCT}" "${PREFPANE_STAGING_APP}"
}

build_prefpane() {
  echo "Building Jitouch.prefPane (Release)"
  xcodebuild \
    -project "${PREFPANE_PROJECT}" \
    -scheme Jitouch \
    -configuration Release \
    -derivedDataPath "${PREFPANE_DERIVED_DATA}" \
    build
}

package_installer() {
  local version built_products_dir objroot

  version="$(plutil -extract CFBundleShortVersionString raw -o - "${PREFPANE_PRODUCT}/Contents/Info.plist")"
  built_products_dir="${ROOT_DIR}/build/Jitouch_${version}"
  objroot="${ROOT_DIR}/build/staging"

  echo "Packaging Install-Jitouch.pkg (${version})"
  rm -rf "${built_products_dir}" "${objroot}"
  mkdir -p "${built_products_dir}" "${objroot}/pkg_staging"

  cp -Rp "${PREFPANE_PRODUCT}" "${built_products_dir}/Jitouch.prefPane"
  cp -Rp "${built_products_dir}/Jitouch.prefPane" "${objroot}/pkg_staging/Jitouch.prefPane"

  pkgbuild \
    --root "${objroot}/pkg_staging/" \
    --component-plist "${COMPONENTS_PLIST}" \
    --identifier "${PRODUCT_BUNDLE_IDENTIFIER}" \
    --version "${version}" \
    "${objroot}/JitouchPrefpane.pkg" \
    --install-location /Library/PreferencePanes

  productbuild \
    --distribution "${DISTRIBUTION_XML}" \
    --package-path "${objroot}" \
    --identifier "${PRODUCT_BUNDLE_IDENTIFIER}" \
    --version "${version}" \
    "${built_products_dir}/Install-Jitouch.pkg"

  echo "Created:"
  echo "  ${built_products_dir}/Jitouch.prefPane"
  echo "  ${built_products_dir}/Install-Jitouch.pkg"
}

build_app
stage_prefpane_app
build_prefpane
package_installer
