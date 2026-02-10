#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"
deploy_doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

grep -q '"preflight_trend"' "${daemon}" || { echo "wbabd missing preflight_trend api op handling" >&2; exit 1; }
grep -q '/preflight-trend' "${daemon}" || { echo "wbabd missing /preflight-trend HTTP endpoint" >&2; exit 1; }
grep -q '_preflight_trend_summary' "${daemon}" || { echo "wbabd missing preflight trend summary helper" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_AUDIT_WINDOW' "${daemon}" || { echo "wbabd missing preflight trend window env handling" >&2; exit 1; }

grep -q 'preflight_trend' "${contracts}" || { echo "Contracts missing preflight trend API contract" >&2; exit 1; }
grep -q '/preflight-trend' "${contracts}" || { echo "Contracts missing preflight trend HTTP contract" >&2; exit 1; }
grep -q 'preflight-trend-report.sh' "${deploy_doc}" || { echo "Deploy profile missing preflight trend report helper usage" >&2; exit 1; }

echo "OK: daemon preflight trend API contract"
