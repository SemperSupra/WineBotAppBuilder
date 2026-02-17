#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/scripts/security"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp -r "${ROOT_DIR}/core/"* "${TMP}/core/"
cp "${ROOT_DIR}/scripts/security/daemon-preflight.sh" "${TMP}/scripts/security/daemon-preflight.sh"
chmod +x "${TMP}/tools/wbabd" "${TMP}/scripts/security/daemon-preflight.sh"

audit_file="${TMP}/audit.jsonl"
status_file="${TMP}/preflight-status.json"
counters_file="${TMP}/preflight-counters.json"

run_attempt() {
  set +e
  (
    cd "${TMP}"
    WBABD_AUDIT_LOG_PATH="${audit_file}" \
    WBABD_PREFLIGHT_STATUS_PATH="${status_file}" \
    WBABD_PREFLIGHT_COUNTERS_PATH="${counters_file}" \
    ./tools/wbabd serve --preflight --host 127.0.0.1 --port 19999 >/dev/null 2>&1
  )
  local rc=$?
  set -e
  [[ "${rc}" -ne 0 ]] || { echo "Expected serve --preflight to fail in test fixture" >&2; exit 1; }
}

run_attempt
run_attempt

[[ -s "${audit_file}" ]] || { echo "Expected audit log with preflight events" >&2; exit 1; }

check_count() {
  local query="$1"
  local msg="$2"
  local count
  count="$(sqlite3 "${audit_file}" "${query}")"
  if [[ "${count}" -lt 1 ]]; then
    echo "${msg}" >&2
    exit 1
  fi
}

check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='command.preflight';" "Expected command.preflight audit event"

# Check for JSON details using LIKE since sqlite doesn't support JSON operators natively in older versions without extensions
check_count "SELECT COUNT(*) FROM audit_events WHERE details LIKE '%\"failed\": 1%' AND details LIKE '%\"total\": 1%';" "Expected first preflight counter snapshot in audit event"
check_count "SELECT COUNT(*) FROM audit_events WHERE details LIKE '%\"failed\": 2%' AND details LIKE '%\"total\": 2%';" "Expected second preflight counter snapshot in audit event"

[[ -s "${counters_file}" ]] || { echo "Expected persisted preflight counters file" >&2; exit 1; }
grep -q '"failed": 2' "${counters_file}" || { echo "Expected failed counter=2 in persisted counters file" >&2; exit 1; }
grep -q '"total": 2' "${counters_file}" || { echo "Expected total counter=2 in persisted counters file" >&2; exit 1; }

echo "OK: daemon preflight audit counters"
