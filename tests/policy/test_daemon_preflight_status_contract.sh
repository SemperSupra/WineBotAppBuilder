#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"

grep -q 'WBABD_PREFLIGHT_STATUS_PATH' "${daemon}" || { echo "wbabd missing preflight status path handling" >&2; exit 1; }
grep -q '/preflight-status' "${daemon}" || { echo "wbabd missing /preflight-status HTTP endpoint" >&2; exit 1; }
grep -q '"preflight_status"' "${daemon}" || { echo "wbabd missing preflight_status api op handling" >&2; exit 1; }
grep -q '_write_preflight_status' "${daemon}" || { echo "wbabd missing preflight status writer" >&2; exit 1; }
grep -q '_read_preflight_status' "${daemon}" || { echo "wbabd missing preflight status reader" >&2; exit 1; }

grep -q 'preflight-status.json' "${contracts}" || { echo "Contracts missing preflight status file contract" >&2; exit 1; }
grep -q 'preflight_status' "${contracts}" || { echo "Contracts missing preflight status API contract" >&2; exit 1; }

echo "OK: daemon preflight status contract"
