#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Perch.dmg}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found at $DMG_PATH" >&2
  exit 1
fi

if [[ -z "${PERCH_NOTARY_PROFILE:-}" ]]; then
  echo "Set PERCH_NOTARY_PROFILE to a notarytool keychain profile before notarizing." >&2
  exit 1
fi

xcrun notarytool submit "$DMG_PATH" --keychain-profile "$PERCH_NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
