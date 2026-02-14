#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/scripts/security"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/core/discovery.py" "${TMP}/core/discovery.py"
cp "${ROOT_DIR}/core/scm.py" "${TMP}/core/scm.py"
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
grep -q '"event_type": "command.preflight"' "${audit_file}" || { echo "Expected command.preflight audit event" >&2; exit 1; }
grep -q '"counters": {"failed": 1, "last_status": "failed", "ok": 0, "total": 1' "${audit_file}" || {
  echo "Expected first preflight counter snapshot in audit event" >&2
  exit 1
}
grep -q '"counters": {"failed": 2, "last_status": "failed", "ok": 0, "total": 2' "${audit_file}" || {
  echo "Expected second preflight counter snapshot in audit event" >&2
  exit 1
}

[[ -s "${counters_file}" ]] || { echo "Expected persisted preflight counters file" >&2; exit 1; }
grep -q '"failed": 2' "${counters_file}" || { echo "Expected failed counter=2 in persisted counters file" >&2; exit 1; }
grep -q '"total": 2' "${counters_file}" || { echo "Expected total counter=2 in persisted counters file" >&2; exit 1; }

echo "OK: daemon preflight audit counters"
