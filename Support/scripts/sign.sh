#!/usr/bin/env zsh
set -euo pipefail

source "$(dirname "$0")/common.sh"

EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/export}"
APP_PATH="${APP_PATH:-$EXPORT_PATH/Perch.app}"
ENTITLEMENTS="${ENTITLEMENTS:-$ROOT_DIR/Support/Entitlements/Perch.entitlements}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Exported app not found at $APP_PATH" >&2
  exit 1
fi

if [[ -z "${PERCH_SIGNING_IDENTITY:-}" ]]; then
  echo "Set PERCH_SIGNING_IDENTITY to a Developer ID Application certificate before signing." >&2
  exit 1
fi

# Sign Sparkle XPC services individually (required by Gatekeeper on fresh installs).
SPARKLE_FRAMEWORK="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
  for xpc in "$SPARKLE_FRAMEWORK/Versions/Current/XPCServices/"*.xpc; do
    [[ -d "$xpc" ]] || continue
    codesign --force --options runtime --timestamp --sign "$PERCH_SIGNING_IDENTITY" "$xpc"
  done
  for helper in "$SPARKLE_FRAMEWORK/Versions/Current/Autoupdate" "$SPARKLE_FRAMEWORK/Versions/Current/Updater.app"; do
    [[ -e "$helper" ]] || continue
    codesign --force --options runtime --timestamp --sign "$PERCH_SIGNING_IDENTITY" "$helper"
  done
fi

# Sign all embedded frameworks.
find "$APP_PATH/Contents/Frameworks" -type d -name "*.framework" -maxdepth 2 -print0 2>/dev/null | \
  while IFS= read -r -d '' framework; do
    codesign --force --options runtime --timestamp --sign "$PERCH_SIGNING_IDENTITY" "$framework"
  done

# Sign the app itself with entitlements + hardened runtime.
codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$PERCH_SIGNING_IDENTITY" \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
