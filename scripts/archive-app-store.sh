#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
archive_path="${1:-$PWD/dist/app-store/MacState.xcarchive}"
mkdir -p "$(dirname "$archive_path")"
# Do not pass connector credentials or unrelated environment secrets into Xcode.
env -i HOME="$HOME" USER="$USER" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" \
  /usr/bin/xcodebuild -workspace MacState.xcworkspace -scheme MacStateStore \
  -configuration StoreRelease -destination 'generic/platform=macOS' \
  -archivePath "$archive_path" -allowProvisioningUpdates archive
# Archive only. Validate/export/upload in Organizer after verifying distribution profiles.
