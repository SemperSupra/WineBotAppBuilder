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
chmod +x "${TMP}/tools/wbabd" "${TMP}/scripts/security/daemon-preflight.sh"

status_file="${TMP}/preflight-status.json"
counters_file="${TMP}/preflight-counters.json"
audit_file="${TMP}/audit-log.jsonl"

run_attempt() {
  set +e
  (
    cd "${TMP}"
    WBABD_PREFLIGHT_STATUS_PATH="${status_file}" \
    WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    ./tools/wbabd serve --preflight --host 127.0.0.1 --port 19999 >/dev/null 2>&1
  )
  local rc=$?
  set -e
  [[ "${rc}" -ne 0 ]] || { echo "Expected preflight serve to fail in fixture" >&2; exit 1; }
}

run_attempt
run_attempt

resp="$(
  cd "${TMP}" && \
    WBABD_PREFLIGHT_STATUS_PATH="${status_file}" \
    WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    WBABD_PREFLIGHT_AUDIT_WINDOW=2 \
    ./tools/wbabd api '{"op":"preflight_trend"}'
)"

grep -q '"status": "ok"' <<< "${resp}" || { echo "Expected status=ok from preflight_trend" >&2; exit 1; }
grep -q '"cumulative": {' <<< "${resp}" || { echo "Expected cumulative section in preflight_trend" >&2; exit 1; }
grep -q '"failed": 2' <<< "${resp}" || { echo "Expected cumulative failed=2 in preflight_trend" >&2; exit 1; }
grep -q '"total": 2' <<< "${resp}" || { echo "Expected cumulative total=2 in preflight_trend" >&2; exit 1; }
grep -q '"recent_window": {' <<< "${resp}" || { echo "Expected recent_window section in preflight_trend" >&2; exit 1; }
grep -q '"window": 2' <<< "${resp}" || { echo "Expected window=2 in preflight_trend" >&2; exit 1; }
grep -q '"events_seen": 2' <<< "${resp}" || { echo "Expected recent events_seen=2 in preflight_trend" >&2; exit 1; }

set +e
bad="$(
  cd "${TMP}" && \
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    ./tools/wbabd api '{"op":"preflight_trend","window":0}' 2>&1
)"
rc=$?
set -e
[[ "${rc}" -ne 0 ]] || { echo "Expected preflight_trend window=0 to fail" >&2; exit 1; }
grep -q 'preflight audit window must be > 0' <<< "${bad}" || {
  echo "Expected invalid window error for preflight_trend" >&2
  exit 1
}

echo "OK: daemon preflight trend API"
