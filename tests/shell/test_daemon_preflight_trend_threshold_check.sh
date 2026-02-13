#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/scripts/security"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/core/discovery.py" "${TMP}/core/discovery.py"
cp "${ROOT_DIR}/scripts/security/daemon-preflight.sh" "${TMP}/scripts/security/daemon-preflight.sh"
cp "${ROOT_DIR}/scripts/security/preflight-trend-threshold-check.sh" "${TMP}/scripts/security/preflight-trend-threshold-check.sh"
chmod +x "${TMP}/tools/wbabd" "${TMP}/scripts/security/daemon-preflight.sh" "${TMP}/scripts/security/preflight-trend-threshold-check.sh"

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
bad="$(
  cd "${TMP}" && \
    WBABD_BIN="${TMP}/tools/wbabd" \
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
    ./scripts/security/preflight-trend-threshold-check.sh --window 10 --min-success-rate 100 --max-recent-failed 0 --require-events 1 2>&1
)"
rc=$?
set -e
[[ "${rc}" -ne 0 ]] || { echo "Expected strict threshold check to fail for fixture" >&2; exit 1; }
grep -q 'below threshold\|exceeds threshold' <<< "${bad}" || { echo "Expected threshold failure message" >&2; exit 1; }

good="$(
  cd "${TMP}" && \
    WBABD_BIN="${TMP}/tools/wbabd" \
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
    ./scripts/security/preflight-trend-threshold-check.sh --window 10 --min-success-rate 0 --max-recent-failed 10 --require-events 1
)"
grep -q '^OK: preflight trend thresholds satisfied' <<< "${good}" || {
  echo "Expected permissive threshold check to pass for fixture" >&2
  exit 1
}

echo "OK: daemon preflight trend threshold check"
