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
export WBAB_SIGN_USE_DEV_CERT="1"
export WBAB_SIGN_AUTOGEN_DEV_CERT="1"
export WBAB_DEV_CERT_DIR="${TMP}/project/.wbab/signing/dev"

bash "${TMP}/tools/sign-dev.sh" "${TMP}/project"

log="$(cat "${MOCK_LOG}")"
echo "${log}" | grep -q "DOCKER pull " || { echo "Expected docker pull" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run " || { echo "Expected docker run" >&2; exit 1; }
echo "${log}" | grep -q "osslsigncode sign" || { echo "Expected osslsigncode command in dev-cert mode" >&2; exit 1; }
[[ -f "${TMP}/project/.wbab/signing/dev/dev.pfx" ]] || { echo "Expected autogen dev.pfx" >&2; exit 1; }

echo "OK: sign dev-cert mode"
