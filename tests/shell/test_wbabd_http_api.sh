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
echo "API_RUN" >> "${WBABD_MOCK_LOG}"
mkdir -p out
echo "artifact" > out/FakeApp.exe
EOF
chmod +x "${TMP}/tools/winbuild-build.sh"

STORE="${TMP}/store.sqlite"
LOG="${TMP}/run.log"

api() {
  local req="$1"
  (
    cd "${TMP}"
    WBABD_STORE_PATH="${STORE}" WBABD_MOCK_LOG="${LOG}" ./tools/wbabd api "${req}"
  )
}

health="$(api '{"op":"health"}')"
grep -q '"status": "ok"' <<< "${health}" || { echo "Missing health response" >&2; exit 1; }

plan_resp="$(api '{"op":"plan","op_id":"api-op-1","verb":"build","args":["."]}')"
grep -q '"op_id": "api-op-1"' <<< "${plan_resp}" || { echo "Missing op_id in plan response" >&2; exit 1; }

run_resp_1="$(api '{"op":"run","op_id":"api-op-1","verb":"build","args":["."]}')"
grep -q '"status": "succeeded"' <<< "${run_resp_1}" || { echo "Expected succeeded in first run response" >&2; exit 1; }

run_resp_2="$(api '{"op":"run","op_id":"api-op-1","verb":"build","args":["."]}')"
grep -q '"status": "cached"' <<< "${run_resp_2}" || { echo "Expected cached in second run response" >&2; exit 1; }

status_resp="$(api '{"op":"status","op_id":"api-op-1"}')"
grep -q '"status": "succeeded"' <<< "${status_resp}" || { echo "Expected succeeded status response" >&2; exit 1; }

count="$(wc -l < "${LOG}" | tr -d ' ')"
[[ "${count}" == "1" ]] || { echo "Expected one underlying execution through API adapter, got ${count}" >&2; exit 1; }

echo "OK: wbabd API adapter"
