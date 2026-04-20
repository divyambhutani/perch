#!/usr/bin/env zsh
set -euo pipefail

source "$(dirname "$0")/common.sh"

# VERSION is already exported in common.sh via extract_version, but let's ensure it's available
# If PERCH_VERSION is explicitly set, use it; otherwise use the extracted version
VERSION="${PERCH_VERSION:-$(extract_version)}"
export PERCH_VERSION="$VERSION"

echo "==> Releasing Perch $VERSION"

for var in PERCH_SIGNING_IDENTITY PERCH_NOTARY_PROFILE; do
  if [[ -z "${(P)var:-}" ]]; then
    echo "Missing required env var: $var" >&2
    exit 1
  fi
done

./Support/scripts/archive.sh
./Support/scripts/sign.sh
./Support/scripts/dmg.sh
./Support/scripts/notarize.sh
./Support/scripts/appcast.sh

DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Perch-$VERSION.dmg}"
APPCAST_DIR="${APPCAST_DIR:-$ROOT_DIR/build/appcast}"

if [[ "${PERCH_PUBLISH_GITHUB:-0}" == "1" ]]; then
  if ! command -v gh >/dev/null; then
    echo "gh CLI not found — skip GitHub release upload." >&2
    exit 1
  fi
  TAG="v$VERSION"
  git tag -a "$TAG" -m "Perch $VERSION" 2>/dev/null || true
  git push origin "$TAG" 2>/dev/null || true
  gh release create "$TAG" \
    --title "Perch $VERSION" \
    --notes "Perch $VERSION" \
    "$DMG_PATH" \
    "$APPCAST_DIR/appcast.xml"
fi

echo "==> Release artifacts ready"
echo "    DMG:     $DMG_PATH"
echo "    Appcast: $APPCAST_DIR/appcast.xml"
