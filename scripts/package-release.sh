#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.1.0}"
MODE="${MACSTATE_SIGNING_MODE:-developer-id}"
TEAM_ID="${MACSTATE_TEAM_ID:-662TJCCT5J}"
# Keychain identity names/profile names only; never put passwords or private keys here.
IDENTITY="${MACSTATE_SIGNING_IDENTITY:-Developer ID Application}"
NOTARY_PROFILE="${MACSTATE_NOTARY_PROFILE:-}"
INSTALLER_IDENTITY="${MACSTATE_INSTALLER_IDENTITY:-}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must have the form 1.2.3" >&2
  exit 1
fi
case "$MODE" in
  development) IDENTITY="${MACSTATE_SIGNING_IDENTITY:-Apple Development}" ;;
  developer-id)
    if [[ -z "$NOTARY_PROFILE" ]]; then
      echo "Set MACSTATE_NOTARY_PROFILE to an existing notarytool Keychain profile." >&2
      exit 1
    fi
    ;;
  *) echo "MACSTATE_SIGNING_MODE must be development or developer-id" >&2; exit 1 ;;
esac
if ! security find-identity -v -p codesigning | grep -Fq "$IDENTITY"; then
  echo "No usable signing identity: $IDENTITY" >&2
  exit 1
fi

BUILD_ROOT="$ROOT_DIR/dist/release-$VERSION-$MODE"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/MacStateApp.app"
ZIP_PATH="$BUILD_ROOT/mac-state-$VERSION-macos-$MODE.zip"
mkdir -p "$BUILD_ROOT"

SIGNING_FLAGS="--timestamp"
if [[ "$MODE" == development ]]; then SIGNING_FLAGS="--timestamp=none"; fi

# Do not allow unrelated shell credentials to appear in Xcode failure diagnostics.
env -i HOME="$HOME" USER="$USER" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" \
  /usr/bin/xcodebuild \
  -workspace "$ROOT_DIR/MacState.xcworkspace" \
  -scheme MacStateApp -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -allowProvisioningUpdates \
  build \
  "DEVELOPMENT_TEAM=$TEAM_ID" \
  "CODE_SIGN_IDENTITY=$IDENTITY" \
  "MARKETING_VERSION=$VERSION" \
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  ENABLE_HARDENED_RUNTIME=YES CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  "OTHER_CODE_SIGN_FLAGS=$SIGNING_FLAGS"

# Validate every nested executable, not just the outer app.
for bundle in "$APP_PATH/Contents/Library/LoginItems/MacStateLoginHelper.app" \
              "$APP_PATH/Contents/PlugIns/MacStateWidgets.appex" "$APP_PATH"; do
  codesign --verify --strict --verbose=2 "$bundle"
  metadata="$(codesign -dv --verbose=4 "$bundle" 2>&1)"
  if ! grep -Fqx "TeamIdentifier=$TEAM_ID" <<< "$metadata"; then
    echo "Unexpected signing team: $bundle" >&2; exit 1
  fi
  if [[ "$MODE" == developer-id ]] && ! grep -Fq 'Authority=Developer ID Application:' <<< "$metadata"; then
    echo "Distribution requires Developer ID Application: $bundle" >&2; exit 1
  fi
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$bundle/Contents/Info.plist")
  lipo "$bundle/Contents/MacOS/$executable" -verify_arch arm64 x86_64
done
codesign --verify --deep --strict "$APP_PATH"

# A failed notarization never leaves a ZIP advertised as a finished release.
TEMP_ZIP="$BUILD_ROOT/notarization-upload.zip"
trap 'rm -f "$TEMP_ZIP"' EXIT
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$TEMP_ZIP"
if [[ "$MODE" == developer-id ]]; then
  xcrun notarytool submit "$TEMP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
  xcrun stapler validate "$APP_PATH"
  spctl --assess --type execute --verbose=2 "$APP_PATH"
fi
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

if [[ "$MODE" == developer-id && -n "$INSTALLER_IDENTITY" ]]; then
  PKG_PATH="$BUILD_ROOT/mac-state-$VERSION-macos.pkg"
  productbuild --component "$APP_PATH" /Applications --sign "$INSTALLER_IDENTITY" "$PKG_PATH"
  pkgutil --check-signature "$PKG_PATH"
  xcrun notarytool submit "$PKG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$PKG_PATH"
  xcrun stapler validate "$PKG_PATH"
  shasum -a 256 "$PKG_PATH" > "$PKG_PATH.sha256"
fi
printf 'Packaged (%s): %s\n' "$MODE" "$ZIP_PATH"
if [[ "$MODE" == development ]]; then
  echo 'Development build only; this is not a notarized public release.'
fi
