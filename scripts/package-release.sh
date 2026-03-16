#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.0.0}"
BUILD_ROOT="$ROOT_DIR/dist/release-$VERSION"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/MacStateApp.app"
ZIP_PATH="$BUILD_ROOT/mac-state-$VERSION-macos.zip"
CHECKSUM_PATH="$BUILD_ROOT/mac-state-$VERSION-macos.zip.sha256"
PKG_PATH="$BUILD_ROOT/mac-state-$VERSION-macos-unsigned.pkg"
PKG_CHECKSUM_PATH="$BUILD_ROOT/mac-state-$VERSION-macos-unsigned.pkg.sha256"

mkdir -p "$BUILD_ROOT"

xcodebuild \
  -project "$ROOT_DIR/App/MacStateApp/MacStateApp.xcodeproj" \
  -scheme MacStateApp \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle was not created at: $APP_PATH" >&2
  exit 1
fi

rm -f "$ZIP_PATH" "$CHECKSUM_PATH" "$PKG_PATH" "$PKG_CHECKSUM_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

productbuild \
  --component "$APP_PATH" \
  /Applications \
  "$PKG_PATH"
shasum -a 256 "$PKG_PATH" > "$PKG_CHECKSUM_PATH"

echo "Packaged app:"
echo "  $ZIP_PATH"
echo "ZIP SHA-256:"
cat "$CHECKSUM_PATH"
echo "Installer package:"
echo "  $PKG_PATH"
echo "PKG SHA-256:"
cat "$PKG_CHECKSUM_PATH"
echo "Binary architectures:"
lipo -info "$APP_PATH/Contents/MacOS/MacStateApp"
