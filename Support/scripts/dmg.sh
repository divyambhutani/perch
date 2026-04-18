#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Perch.xcarchive}"
APP_PATH="${APP_PATH:-$ARCHIVE_PATH/Products/Applications/Perch.app}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Perch.dmg}"
STAGING_DIR="$ROOT_DIR/build/dmg-staging"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Archive app not found at $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/Perch.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "Perch" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
