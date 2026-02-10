#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools"
cp "${ROOT_DIR}/tools/wbab" "${TMP}/tools/wbab"
chmod +x "${TMP}/tools/wbab"

cat >"${TMP}/tools/sign-dev.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "SIGN_RUNNER $*" > "${MOCK_LOG}"
EOF
chmod +x "${TMP}/tools/sign-dev.sh"

export MOCK_LOG="${TMP}/mock.log"
"${TMP}/tools/wbab" sign "."

grep -q 'SIGN_RUNNER \.' "${MOCK_LOG}" || { echo "wbab sign did not dispatch correctly" >&2; exit 1; }
echo "OK: wbab sign dispatch"
