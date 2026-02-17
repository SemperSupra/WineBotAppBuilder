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

store="${TMP}/store.json"
audit="${TMP}/audit.jsonl"

(
  cd "${TMP}"
  export WBAB_MOCK_EXECUTION=1
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

[[ -s "${audit}" ]] || { echo "Expected non-empty audit log" >&2; exit 1; }

check_count() {
  local query="$1"
  local msg="$2"
  local count
  count="$(sqlite3 "${audit}" "${query}")"
  if [[ "${count}" -lt 1 ]]; then
    echo "${msg}" >&2
    exit 1
  fi
}

check_count "SELECT COUNT(*) FROM audit_events WHERE actor='ci-shell-test';" "Missing actor in audit log"
check_count "SELECT COUNT(*) FROM audit_events WHERE session_id='sess-audit-1';" "Missing session id in audit log"
check_count "SELECT COUNT(*) FROM audit_events WHERE op_id='audit-op-1';" "Missing op_id in audit log"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='command.plan';" "Missing command.plan event"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='operation.started';" "Missing operation.started event"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='step.started';" "Missing step.started event"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='step.succeeded';" "Missing step.succeeded event"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='operation.succeeded';" "Missing operation.succeeded event"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='operation.cached';" "Missing operation.cached event"
check_count "SELECT COUNT(*) FROM audit_events WHERE event_type='command.status';" "Missing command.status event"

echo "OK: wbabd audit log schema/events"
