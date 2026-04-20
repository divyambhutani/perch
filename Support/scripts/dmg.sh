#!/usr/bin/env zsh
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/common.sh"
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${PERCH_VERSION:-$(awk -F' *= *' '/^MARKETING_VERSION/{print $2}' Support/Config/Version.xcconfig | tr -d '[:space:]')}"
if [[ -z "$VERSION" ]]; then
  echo "Unable to resolve MARKETING_VERSION" >&2
  exit 1
fi

EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/export}"
APP_PATH="${APP_PATH:-$EXPORT_PATH/Perch.app}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Perch-$VERSION.dmg}"
STAGING_DIR="$ROOT_DIR/build/dmg-staging"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH — run archive.sh and sign.sh first." >&2
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/Perch.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "Perch $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "${PERCH_SIGNING_IDENTITY:-}" ]]; then
  codesign --force --sign "$PERCH_SIGNING_IDENTITY" --timestamp "$DMG_PATH"
fi

echo "DMG ready: $DMG_PATH"
