#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/project"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp -r "${ROOT_DIR}/core/"* "${TMP}/core/"
chmod +x "${TMP}/tools/wbabd"

cat > "${TMP}/tools/winbuild-build.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "RUN" >> "${WBABD_MOCK_LOG}"
mkdir -p out
echo "artifact" > out/FakeApp.exe
EOF
chmod +x "${TMP}/tools/winbuild-build.sh"

store="${TMP}/store.json"
log="${TMP}/run.log"

(
  cd "${TMP}"
  WBABD_STORE_PATH="${store}" WBABD_MOCK_LOG="${log}" ./tools/wbabd run op-123 build .
  WBABD_STORE_PATH="${store}" WBABD_MOCK_LOG="${log}" ./tools/wbabd run op-123 build .
)

count="$(wc -l < "${log}" | tr -d ' ')"
[[ "${count}" == "1" ]] || { echo "Expected one underlying execution, got ${count}" >&2; exit 1; }

status_json="$(WBABD_STORE_PATH="${store}" "${TMP}/tools/wbabd" status op-123)"
grep -q '"status": "succeeded"' <<< "${status_json}" || { echo "Expected succeeded status in wbabd store" >&2; exit 1; }
echo "OK: wbabd idempotent execution"
