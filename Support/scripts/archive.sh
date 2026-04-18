#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Perch.xcarchive}"
mkdir -p "$ROOT_DIR/build"

xcodegen generate
xcodebuild -project Perch.xcodeproj -scheme Perch -configuration Release -archivePath "$ARCHIVE_PATH" archive
