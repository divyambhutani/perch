#!/usr/bin/env zsh
source "$(dirname "$0")/common.sh"
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${PERCH_VERSION:-$(awk -F' *= *' '/^MARKETING_VERSION/{print $2}' Support/Config/Version.xcconfig | tr -d '[:space:]')}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Perch-$VERSION.dmg}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found at $DMG_PATH" >&2
  exit 1
fi

if [[ -z "${PERCH_NOTARY_PROFILE:-}" ]]; then
  echo "Set PERCH_NOTARY_PROFILE to a notarytool keychain profile before notarizing." >&2
  exit 1
fi

xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$PERCH_NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"

echo "DMG notarized, stapled, and Gatekeeper-accepted: $DMG_PATH"
