#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"
deploy_doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

grep -q 'WBABD_PREFLIGHT_COUNTERS_PATH' "${daemon}" || { echo "wbabd missing preflight counters env var handling" >&2; exit 1; }
grep -q '_read_preflight_counters' "${daemon}" || { echo "wbabd missing preflight counters read helper" >&2; exit 1; }
grep -q '_update_preflight_counters' "${daemon}" || { echo "wbabd missing preflight counters update helper" >&2; exit 1; }
grep -q '"counters": counters' "${daemon}" || { echo "wbabd missing counters in preflight status payload" >&2; exit 1; }
grep -q 'details={"message": msg, "counters": counters}' "${daemon}" || {
  echo "wbabd missing success counters in command.preflight audit event" >&2
  exit 1
}
grep -q 'details={"error": msg, "counters": counters}' "${daemon}" || {
  echo "wbabd missing failure counters in command.preflight audit event" >&2
  exit 1
}

grep -q 'WBABD_PREFLIGHT_COUNTERS_PATH' "${contracts}" || { echo "Contracts missing preflight counters env var" >&2; exit 1; }
grep -q 'preflight-counters.json' "${contracts}" || { echo "Contracts missing preflight counters output path" >&2; exit 1; }
grep -q 'command.preflight' "${contracts}" || { echo "Contracts missing preflight audit counters mention" >&2; exit 1; }
grep -q 'preflight-counters.json' "${deploy_doc}" || { echo "Deploy profile missing preflight counters diagnostics path" >&2; exit 1; }

echo "OK: daemon preflight counters contract"
