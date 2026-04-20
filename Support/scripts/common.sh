#!/usr/bin/env zsh
# Shared utilities for Perch support scripts

# Determine the repository root directory (two levels up from this script)
export ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# Change to the repo root for subsequent commands
cd "$ROOT_DIR"

# Extract MARKETING_VERSION from the xcconfig file
extract_version() {
  awk -F' *= *' '/^MARKETING_VERSION/{print $2}' Support/Config/Version.xcconfig | tr -d '[:space:]'
}
