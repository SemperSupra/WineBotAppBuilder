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

audit_file="${TMP}/audit.sqlite"
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

[[ -f "${audit_file}" ]] || { echo "Expected audit log database file" >&2; exit 1; }

python3 - "${audit_file}" <<'PY'
import sqlite3
import sys
import json

conn = sqlite3.connect(sys.argv[1])
conn.row_factory = sqlite3.Row
# Filter strictly by event_type
rows = conn.execute("SELECT details FROM audit_events WHERE event_type = 'command.preflight' ORDER BY ts ASC").fetchall()

if len(rows) < 2:
    print(f"Expected at least 2 preflight events, got {len(rows)}", file=sys.stderr)
    sys.exit(1)

# Inspect the last two preflight events from this test run
penultimate = json.loads(rows[-2]["details"])["counters"]
last = json.loads(rows[-1]["details"])["counters"]

if last["failed"] != (penultimate["failed"] + 1):
    print(f"Counters did not increment: {penultimate['failed']} -> {last['failed']}", file=sys.stderr)
    sys.exit(1)
PY

[[ -s "${counters_file}" ]] || { echo "Expected persisted preflight counters file" >&2; exit 1; }
grep -q '"failed": 2' "${counters_file}" || { echo "Expected failed counter=2 in persisted counters file" >&2; exit 1; }
grep -q '"total": 2' "${counters_file}" || { echo "Expected total counter=2 in persisted counters file" >&2; exit 1; }

echo "OK: daemon preflight audit counters"
