#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

doc="${ROOT_DIR}/docs/CONTRACTS.md"
req=(WBAB_TAG WBAB_ALLOW_LOCAL_BUILD WBAB_WINEBOT_IMAGE WBAB_WINEBOT_TAG WBAB_WINEBOT_PROFILE WBAB_WINEBOT_SERVICE)
for k in "${req[@]}"; do
  grep -q "${k}" "${doc}" || { echo "Missing env var in docs: ${k}" >&2; exit 1; }
done
