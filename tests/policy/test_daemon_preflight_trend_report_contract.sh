#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${ROOT_DIR}/scripts/security/preflight-trend-report.sh"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"
deploy_doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

[[ -x "${script}" ]] || { echo "Missing executable preflight trend report helper" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_COUNTERS_PATH' "${script}" || { echo "report helper missing counters path env handling" >&2; exit 1; }
grep -q 'WBABD_AUDIT_LOG_PATH' "${script}" || { echo "report helper missing audit path env handling" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_AUDIT_WINDOW' "${script}" || { echo "report helper missing audit window env handling" >&2; exit 1; }
grep -q 'command.preflight' "${script}" || { echo "report helper missing command.preflight aggregation" >&2; exit 1; }

grep -q 'preflight-trend-report.sh' "${contracts}" || { echo "Contracts missing preflight trend report helper contract" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_AUDIT_WINDOW' "${contracts}" || { echo "Contracts missing preflight audit window env var" >&2; exit 1; }
grep -q 'preflight-trend-report.sh' "${deploy_doc}" || { echo "Deploy profile missing preflight trend report usage" >&2; exit 1; }

echo "OK: daemon preflight trend report contract"
