#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:?Usage: package-dmg.sh /absolute/path/App.app [development|developer-id]}"
MODE="${2:-developer-id}"
TEAM_ID="${MACSTATE_TEAM_ID:-662TJCCT5J}"
IDENTITY="${MACSTATE_SIGNING_IDENTITY:-Developer ID Application}"
PROFILE="${MACSTATE_NOTARY_PROFILE:-}"
case "$MODE" in development|developer-id) ;; *) echo 'Invalid signing mode' >&2; exit 1;; esac
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$BUILD" =~ ^[0-9]+$ ]] || exit 1
for bundle in "$APP_PATH/Contents/Library/LoginItems/MacStateLoginHelper.app" \
              "$APP_PATH/Contents/PlugIns/MacStateWidgets.appex" "$APP_PATH"; do
  codesign --verify --strict "$bundle"
  metadata="$(codesign -dv --verbose=4 "$bundle" 2>&1)"
  grep -Fqx "TeamIdentifier=$TEAM_ID" <<< "$metadata"
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$bundle/Contents/Info.plist")
  lipo "$bundle/Contents/MacOS/$executable" -verify_arch arm64 x86_64
  if [[ "$MODE" == developer-id ]]; then
    grep -Fq 'Authority=Developer ID Application:' <<< "$metadata" || { echo 'Developer ID signature required on every bundle' >&2; exit 1; }
    grep -Fq 'runtime' <<< "$metadata" || { echo 'Hardened runtime required' >&2; exit 1; }
  fi
done
if [[ "$MODE" == developer-id && -z "$PROFILE" ]]; then
  echo 'Set MACSTATE_NOTARY_PROFILE to an existing notarytool Keychain profile' >&2; exit 1
fi
OUT="$ROOT_DIR/dist/dmg"
mkdir -p "$OUT"
FINAL="$OUT/mac-state-$VERSION-build-$BUILD-$MODE.dmg"
[[ ! -e "$FINAL" ]] || { echo "Already exists: $FINAL" >&2; exit 1; }
WORK=$(mktemp -d "$OUT/.dmg-work.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir "$WORK/staging"
ditto "$APP_PATH" "$WORK/staging/MacStateApp.app"
cp "$ROOT_DIR/LICENSE" "$WORK/staging/LICENSE.txt"
ln -s /Applications "$WORK/staging/Applications"
if [[ "$MODE" == development ]]; then
  cat > "$WORK/staging/安装前请读.txt" <<'NOTE'
mac-state 开发测试版 / Development build

此镜像不是已公证的公开发行版。内含 Apple Development 签名应用，
仅适用于签名与描述文件允许的开发测试环境，不能保证其他 Mac 可运行。
普通用户发行需要 Developer ID Application 签名及 Apple 公证。

受支持的测试环境：将 MacStateApp.app 拖入 Applications，然后从应用程序打开。
如果系统阻止运行，请联系开发者获取正式签名版本；不要关闭系统安全保护。

macOS 11+，Intel / Apple Silicon 双架构。
隐私与支持见应用设置。联系：hymghost@gmail.com
NOTE
else
  printf '%s\n' '将 MacStateApp.app 拖入 Applications，再从应用程序打开。' '支持：hymghost@gmail.com' > "$WORK/staging/安装说明.txt"
fi
hdiutil create -volname "mac-state $VERSION ($MODE)" -srcfolder "$WORK/staging" -fs HFS+ -format UDZO "$WORK/candidate.dmg"
hdiutil verify "$WORK/candidate.dmg"
if [[ "$MODE" == developer-id ]]; then
  codesign --sign "$IDENTITY" --timestamp "$WORK/candidate.dmg"
  xcrun notarytool submit "$WORK/candidate.dmg" --keychain-profile "$PROFILE" --wait
  xcrun stapler staple "$WORK/candidate.dmg"
  xcrun stapler validate "$WORK/candidate.dmg"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$WORK/candidate.dmg"
fi
mv "$WORK/candidate.dmg" "$FINAL"
(cd "$OUT" && shasum -a 256 "$(basename "$FINAL")" > "$(basename "$FINAL").sha256")
printf 'DMG (%s): %s\n' "$MODE" "$FINAL"
