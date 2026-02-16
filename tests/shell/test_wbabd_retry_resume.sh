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
if [[ ! -f "${WBABD_FAIL_ONCE_FLAG}" ]]; then
  echo "first-attempt-fail" > "${WBABD_FAIL_ONCE_FLAG}"
  exit 42
fi
mkdir -p out
echo "artifact" > out/FakeApp.exe
EOF
chmod +x "${TMP}/tools/winbuild-build.sh"

store="${TMP}/store.json"
flag="${TMP}/fail-once.flag"

set +e
(
  cd "${TMP}"
  WBABD_STORE_PATH="${store}" WBABD_FAIL_ONCE_FLAG="${flag}" ./tools/wbabd run op-retry-1 build .
)
rc1=$?
set -e
[[ "${rc1}" -ne 0 ]] || { echo "Expected first run to fail" >&2; exit 1; }

(
  cd "${TMP}"
  WBABD_STORE_PATH="${store}" WBABD_FAIL_ONCE_FLAG="${flag}" ./tools/wbabd run op-retry-1 build .
)

status_json="$(WBABD_STORE_PATH="${store}" "${TMP}/tools/wbabd" status op-retry-1)"
grep -q '"status": "succeeded"' <<< "${status_json}" || { echo "Expected succeeded status after retry" >&2; exit 1; }
grep -q '"retry_count": 1' <<< "${status_json}" || { echo "Expected retry_count=1" >&2; exit 1; }
grep -q '"execute_build"' <<< "${status_json}" || { echo "Expected execute_build step state" >&2; exit 1; }
grep -q '"attempts": 2' <<< "${status_json}" || { echo "Expected a step/op attempts count of 2" >&2; exit 1; }

echo "OK: wbabd retry/resume semantics"
