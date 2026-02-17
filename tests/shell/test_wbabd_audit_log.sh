#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp -r "${ROOT_DIR}/core/"* "${TMP}/core/"
chmod +x "${TMP}/tools/wbabd"

cat > "${TMP}/tools/winbuild-build.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p out
echo "artifact" > out/FakeApp.exe
EOF
chmod +x "${TMP}/tools/winbuild-build.sh"

store="${TMP}/store.sqlite"
audit="${TMP}/audit.sqlite"

(
  cd "${TMP}"
  WBABD_STORE_PATH="${store}" \
  WBABD_AUDIT_LOG_PATH="${audit}" \
  WBABD_ACTOR="ci-shell-test" \
  WBABD_SESSION_ID="sess-audit-1" \
  ./tools/wbabd plan audit-op-1 build .
  WBABD_STORE_PATH="${store}" \
  WBABD_AUDIT_LOG_PATH="${audit}" \
  WBABD_ACTOR="ci-shell-test" \
  WBABD_SESSION_ID="sess-audit-1" \
  ./tools/wbabd run audit-op-1 build .
  WBABD_STORE_PATH="${store}" \
  WBABD_AUDIT_LOG_PATH="${audit}" \
  WBABD_ACTOR="ci-shell-test" \
  WBABD_SESSION_ID="sess-audit-1" \
  ./tools/wbabd run audit-op-1 build .
  WBABD_STORE_PATH="${store}" \
  WBABD_AUDIT_LOG_PATH="${audit}" \
  WBABD_ACTOR="ci-shell-test" \
  WBABD_SESSION_ID="sess-audit-1" \
  ./tools/wbabd status audit-op-1
) >/dev/null

[[ -f "${audit}" ]] || { echo "Expected audit log database file" >&2; exit 1; }

python3 - "${audit}" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.row_factory = sqlite3.Row

# Verify actors and session IDs
res = conn.execute("SELECT DISTINCT actor, session_id FROM audit_events").fetchall()
actors = {r["actor"] for r in res}
sessions = {r["session_id"] for r in res}

if "ci-shell-test" not in actors:
    print(f"Missing actor in audit log: {actors}", file=sys.stderr)
    sys.exit(1)
if "sess-audit-1" not in sessions:
    print(f"Missing session id in audit log: {sessions}", file=sys.stderr)
    sys.exit(1)

# Verify event types
res = conn.execute("SELECT DISTINCT event_type FROM audit_events").fetchall()
types = {r["event_type"] for r in res}

expected = {
    "command.plan", "operation.started", "step.started", 
    "step.succeeded", "operation.succeeded", "operation.cached", 
    "command.status"
}

missing = expected - types
if missing:
    print(f"Missing event types in audit log: {missing}", file=sys.stderr)
    sys.exit(1)
PY

echo "OK: wbabd audit log schema/events"
