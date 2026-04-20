#!/usr/bin/env zsh
set -euo pipefail

source "$(dirname "$0")/common.sh"

ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Perch.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/export}"
EXPORT_OPTIONS="${EXPORT_OPTIONS:-$ROOT_DIR/Support/Config/ExportOptions.plist}"

mkdir -p "$ROOT_DIR/build"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

xcodegen generate
xcodebuild \
  -project Perch.xcodeproj \
  -scheme Perch \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"
