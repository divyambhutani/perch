#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Perch.xcarchive}"
APP_PATH="${APP_PATH:-$ARCHIVE_PATH/Products/Applications/Perch.app}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Archive app not found at $APP_PATH" >&2
  exit 1
fi

if [[ -z "${PERCH_SIGNING_IDENTITY:-}" ]]; then
  echo "Set PERCH_SIGNING_IDENTITY to a Developer ID Application certificate before signing." >&2
  exit 1
fi

codesign --force --deep --options runtime --sign "$PERCH_SIGNING_IDENTITY" "$APP_PATH"
