#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/scripts/signing" "${TMP}/project/dist"
cp "${ROOT_DIR}/tools/sign-dev.sh" "${TMP}/tools/sign-dev.sh"
chmod +x "${TMP}/tools/sign-dev.sh"

cat >"${TMP}/scripts/signing/dev-cert.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dir="${WBAB_DEV_CERT_DIR}"
mkdir -p "${dir}"
echo "pfx" > "${dir}/dev.pfx"
echo "pass" > "${dir}/dev.pfx.pass"
chmod 600 "${dir}/dev.pfx" "${dir}/dev.pfx.pass"
EOF
chmod +x "${TMP}/scripts/signing/dev-cert.sh"

mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
echo "DOCKER $*" >> "${MOCK_LOG}"
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

export PATH="${TMP}/mockbin:${PATH}"
export MOCK_LOG="${TMP}/mock.log"
export WBAB_SIGN_AUTOGEN_DEV_CERT="1"
export WBAB_DEV_CERT_DIR="${TMP}/privileged/signing/dev"
unset WBAB_SIGN_MODE WBAB_SIGN_CMD WBAB_SIGN_USE_DEV_CERT

output="$(bash "${TMP}/tools/sign-dev.sh" "${TMP}/project")"

log="$(cat "${MOCK_LOG}")"
echo "${log}" | grep -q "DOCKER pull " || { echo "Expected docker pull" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run " || { echo "Expected docker run" >&2; exit 1; }
echo "${log}" | grep -q -- "--user " || { echo "Expected invoking-user mapping for restrictive cert permissions" >&2; exit 1; }
echo "${log}" | grep -Fq -- "-v ${WBAB_DEV_CERT_DIR}:/run/wbab-signing:ro" || { echo "Expected read-only dev-cert mount" >&2; exit 1; }
echo "${log}" | grep -q "WBAB_DEV_CERT_DIR=/run/wbab-signing" || { echo "Expected stable in-container dev-cert path" >&2; exit 1; }
echo "${log}" | grep -q "wbab-sign" || { echo "Expected real signing command by default" >&2; exit 1; }
echo "${log}" | grep -q "wbab-sign-fixture" && { echo "Did not expect fixture signing command by default" >&2; exit 1; }
echo "${output}" | grep -q "mode=dev-cert" || { echo "Expected dev-cert mode by default" >&2; exit 1; }
[[ -f "${WBAB_DEV_CERT_DIR}/dev.pfx" ]] || { echo "Expected autogen dev.pfx" >&2; exit 1; }
[[ -f "${WBAB_DEV_CERT_DIR}/dev.pfx.pass" ]] || { echo "Expected autogen dev.pfx.pass" >&2; exit 1; }

case "${WBAB_DEV_CERT_DIR}" in
  "${TMP}/project"/*) echo "Dev cert material must not default inside project worktree" >&2; exit 1 ;;
esac

echo "OK: default sign mode is real dev-cert signing with mounted privileged material"
