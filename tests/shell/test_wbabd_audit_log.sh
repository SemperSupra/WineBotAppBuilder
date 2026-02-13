#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/core/discovery.py" "${TMP}/core/discovery.py"
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

grep -q '"schema_version": "wbab.audit.v1"' "${audit}" || { echo "Missing schema version in audit log" >&2; exit 1; }
grep -q '"actor": "ci-shell-test"' "${audit}" || { echo "Missing actor in audit log" >&2; exit 1; }
grep -q '"session_id": "sess-audit-1"' "${audit}" || { echo "Missing session id in audit log" >&2; exit 1; }
grep -q '"op_id": "audit-op-1"' "${audit}" || { echo "Missing op_id in audit log" >&2; exit 1; }
grep -q '"event_type": "command.plan"' "${audit}" || { echo "Missing command.plan event" >&2; exit 1; }
grep -q '"event_type": "operation.started"' "${audit}" || { echo "Missing operation.started event" >&2; exit 1; }
grep -q '"event_type": "step.started"' "${audit}" || { echo "Missing step.started event" >&2; exit 1; }
grep -q '"event_type": "step.succeeded"' "${audit}" || { echo "Missing step.succeeded event" >&2; exit 1; }
grep -q '"event_type": "operation.succeeded"' "${audit}" || { echo "Missing operation.succeeded event" >&2; exit 1; }
grep -q '"event_type": "operation.cached"' "${audit}" || { echo "Missing operation.cached event" >&2; exit 1; }
grep -q '"event_type": "command.status"' "${audit}" || { echo "Missing command.status event" >&2; exit 1; }

echo "OK: wbabd audit log schema/events"
