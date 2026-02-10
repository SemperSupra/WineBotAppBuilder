#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gate_script="${ROOT_DIR}/scripts/security/preflight-trend-threshold-check.sh"

[[ -x "${gate_script}" ]] || { echo "Missing executable threshold gate script: ${gate_script}" >&2; exit 1; }

if [[ "${WBABD_POLICY_PREFLIGHT_TREND_GATE:-0}" != "1" ]]; then
  echo "SKIP: optional preflight trend threshold gate disabled (set WBABD_POLICY_PREFLIGHT_TREND_GATE=1 to enable)"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/scripts/security"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/scripts/security/daemon-preflight.sh" "${TMP}/scripts/security/daemon-preflight.sh"
chmod +x "${TMP}/tools/wbabd" "${TMP}/scripts/security/daemon-preflight.sh"

status_file="${TMP}/preflight-status.json"
counters_file="${TMP}/preflight-counters.json"
audit_file="${TMP}/audit-log.jsonl"

set +e
(
  cd "${TMP}"
  WBABD_PREFLIGHT_STATUS_PATH="${status_file}" \
  WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
  WBABD_AUDIT_LOG_PATH="${audit_file}" \
  ./tools/wbabd serve --preflight --host 127.0.0.1 --port 19999 >/dev/null 2>&1
)
rc=$?
set -e
[[ "${rc}" -ne 0 ]] || { echo "Expected fixture preflight failure" >&2; exit 1; }

set +e
out="$(
  cd "${TMP}" && \
    WBABD_BIN="${TMP}/tools/wbabd" \
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
    "${gate_script}" --window 10 --min-success-rate 100 --max-recent-failed 0 --require-events 1 2>&1
)"
rc=$?
set -e
[[ "${rc}" -ne 0 ]] || { echo "Expected strict threshold gate to fail for fixture" >&2; exit 1; }
grep -q 'below threshold\|exceeds threshold' <<< "${out}" || {
  echo "Expected threshold violation message from optional gate" >&2
  exit 1
}

echo "OK: optional daemon preflight trend threshold gate"
