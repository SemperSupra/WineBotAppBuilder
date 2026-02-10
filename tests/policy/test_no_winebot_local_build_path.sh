#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

runner="${ROOT_DIR}/tools/winebot-smoke.sh"
[[ -f "${runner}" ]] || { echo "Missing runner: tools/winebot-smoke.sh" >&2; exit 1; }

if grep -q 'WBAB_ALLOW_WINEBOT_LOCAL_BUILD' "${runner}"; then
  echo "winebot-smoke.sh must not support WBAB_ALLOW_WINEBOT_LOCAL_BUILD" >&2
  exit 1
fi

if grep -q -- '--build' "${runner}"; then
  echo "winebot-smoke.sh must not invoke docker compose --build path" >&2
  exit 1
fi
