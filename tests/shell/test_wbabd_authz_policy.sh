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

policy="${TMP}/authz-policy.json"
cat > "${policy}" <<'EOF'
{
  "principals": {
    "builder": { "verbs": ["health", "status", "plan", "run:build"] },
    "viewer": { "verbs": ["health", "status"] },
    "*": { "verbs": ["health"] }
  }
}
EOF

store="${TMP}/store.sqlite"

# allowed principal can plan/run/status
plan_ok="$(
  cd "${TMP}" && WBABD_STORE_PATH="${store}" WBABD_AUTHZ_POLICY_FILE="${policy}" WBABD_PRINCIPAL=builder ./tools/wbabd api '{"op":"plan","op_id":"authz-op-1","verb":"build","args":["."]}'
)"
grep -q '"op_id": "authz-op-1"' <<< "${plan_ok}" || { echo "Expected plan success for builder principal" >&2; exit 1; }

run_ok="$(
  cd "${TMP}" && WBABD_STORE_PATH="${store}" WBABD_AUTHZ_POLICY_FILE="${policy}" WBABD_PRINCIPAL=builder ./tools/wbabd api '{"op":"run","op_id":"authz-op-1","verb":"build","args":["."]}'
)"
grep -q '"status": "succeeded"' <<< "${run_ok}" || { echo "Expected run success for builder principal" >&2; exit 1; }

status_ok="$(
  cd "${TMP}" && WBABD_STORE_PATH="${store}" WBABD_AUTHZ_POLICY_FILE="${policy}" WBABD_PRINCIPAL=builder ./tools/wbabd api '{"op":"status","op_id":"authz-op-1"}'
)"
grep -q '"status": "succeeded"' <<< "${status_ok}" || { echo "Expected status success for builder principal" >&2; exit 1; }

# viewer cannot run build
set +e
run_denied="$(
  cd "${TMP}" && WBABD_STORE_PATH="${store}" WBABD_AUTHZ_POLICY_FILE="${policy}" WBABD_PRINCIPAL=viewer ./tools/wbabd api '{"op":"run","op_id":"authz-op-2","verb":"build","args":["."]}' 2>&1
)"
rc_denied=$?
set -e
[[ "${rc_denied}" -ne 0 ]] || { echo "Expected run denial for viewer principal" >&2; exit 1; }
grep -q '"error": "forbidden"' <<< "${run_denied}" || { echo "Expected forbidden error for denied principal" >&2; exit 1; }

# wildcard principal can only call health in this policy
health_ok="$(
  cd "${TMP}" && WBABD_STORE_PATH="${store}" WBABD_AUTHZ_POLICY_FILE="${policy}" WBABD_PRINCIPAL=unknown ./tools/wbabd api '{"op":"health"}'
)"
grep -q '"status": "ok"' <<< "${health_ok}" || { echo "Expected health allowed by wildcard policy" >&2; exit 1; }

set +e
status_denied="$(
  cd "${TMP}" && WBABD_STORE_PATH="${store}" WBABD_AUTHZ_POLICY_FILE="${policy}" WBABD_PRINCIPAL=unknown ./tools/wbabd api '{"op":"status","op_id":"authz-op-1"}' 2>&1
)"
rc_status_denied=$?
set -e
[[ "${rc_status_denied}" -ne 0 ]] || { echo "Expected status denial for unknown principal" >&2; exit 1; }
grep -q '"error": "forbidden"' <<< "${status_denied}" || { echo "Expected forbidden status denial" >&2; exit 1; }

echo "OK: wbabd authz policy enforcement"
