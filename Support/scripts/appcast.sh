#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${PERCH_VERSION:-$(awk -F' *= *' '/^MARKETING_VERSION/{print $2}' Support/Config/Version.xcconfig | tr -d '[:space:]')}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Perch-$VERSION.dmg}"
APPCAST_DIR="${APPCAST_DIR:-$ROOT_DIR/build/appcast}"
APPCAST_URL="${APPCAST_URL:-https://divyambhutani40.github.io/perch/Perch-$VERSION.dmg}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found at $DMG_PATH — run dmg.sh + notarize.sh first." >&2
  exit 1
fi

if [[ -z "${SPARKLE_BIN:-}" ]]; then
  DERIVED=$(ls -d ~/Library/Developer/Xcode/DerivedData/Perch-*/SourcePackages/artifacts/sparkle/Sparkle/bin 2>/dev/null | head -n1 || true)
  if [[ -n "$DERIVED" && -x "$DERIVED/generate_appcast" ]]; then
    SPARKLE_BIN="$DERIVED"
  fi
fi

if [[ -z "${SPARKLE_BIN:-}" || ! -x "$SPARKLE_BIN/generate_appcast" ]]; then
  echo "Set SPARKLE_BIN to the directory containing Sparkle's generate_appcast binary." >&2
  exit 1
fi

rm -rf "$APPCAST_DIR"
mkdir -p "$APPCAST_DIR"
cp "$DMG_PATH" "$APPCAST_DIR/"

EXTRA_ARGS=()
if [[ -n "${SPARKLE_ED_PRIVATE_KEY_FILE:-}" ]]; then
  EXTRA_ARGS+=(--ed-key-file "$SPARKLE_ED_PRIVATE_KEY_FILE")
fi

"$SPARKLE_BIN/generate_appcast" \
  --download-url-prefix "$(dirname "$APPCAST_URL")/" \
  "${EXTRA_ARGS[@]}" \
  "$APPCAST_DIR"

echo "Appcast ready in $APPCAST_DIR"
