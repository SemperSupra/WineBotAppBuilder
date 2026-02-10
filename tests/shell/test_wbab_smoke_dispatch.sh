#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools"
cp "${ROOT_DIR}/tools/wbab" "${TMP}/tools/wbab"
chmod +x "${TMP}/tools/wbab"

cat >"${TMP}/tools/winebot-smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "SMOKE_RUNNER $*" > "${MOCK_LOG}"
EOF
chmod +x "${TMP}/tools/winebot-smoke.sh"

export MOCK_LOG="${TMP}/mock.log"
"${TMP}/tools/wbab" smoke "dist/FakeSetup.exe"

grep -q 'SMOKE_RUNNER dist/FakeSetup.exe' "${MOCK_LOG}" || { echo "wbab smoke did not dispatch correctly" >&2; exit 1; }
echo "OK: wbab smoke dispatch"
