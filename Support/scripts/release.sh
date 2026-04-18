#!/usr/bin/env zsh
set -euo pipefail

./Support/scripts/build.sh
./Support/scripts/archive.sh
./Support/scripts/sign.sh
./Support/scripts/notarize.sh
./Support/scripts/dmg.sh
