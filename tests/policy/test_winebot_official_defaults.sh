#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

runner="${ROOT_DIR}/tools/winebot-smoke.sh"
[[ -f "${runner}" ]] || { echo "Missing runner: tools/winebot-smoke.sh" >&2; exit 1; }

grep -q "WINEBOT_IMAGE=\"\${WBAB_WINEBOT_IMAGE:-ghcr.io/mark-e-deyoung/winebot}\"" "${runner}" \
  || { echo "WineBot default image must be ghcr.io/mark-e-deyoung/winebot" >&2; exit 1; }
grep -q "WINEBOT_TAG=\"\${WBAB_WINEBOT_TAG:-stable}\"" "${runner}" \
  || { echo "WineBot default tag must be stable" >&2; exit 1; }
