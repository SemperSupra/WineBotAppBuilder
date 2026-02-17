#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/WineBot/compose" "${TMP}/tools/WineBot/apps" "${TMP}/tools" "${TMP}/agent-privileged/signing/dev"
cp "${ROOT_DIR}/tools/compose.sh" "${TMP}/tools/compose.sh"
cp "${ROOT_DIR}/tools/winebot-smoke.sh" "${TMP}/tools/winebot-smoke.sh"
cp "${ROOT_DIR}/tools/winebot-trust-dev-cert.sh" "${TMP}/tools/winebot-trust-dev-cert.sh"
chmod +x "${TMP}/tools/compose.sh" "${TMP}/tools/winebot-smoke.sh" "${TMP}/tools/winebot-trust-dev-cert.sh"

cat >"${TMP}/tools/WineBot/compose/docker-compose.yml" <<'EOF'
services:
  winebot:
    image: local-placeholder
EOF
echo "dummy-cert" > "${TMP}/agent-privileged/signing/dev/dev.crt.pem"

mkdir -p "${TMP}/dist"
echo "fake-installer" > "${TMP}/dist/FakeSetup.exe"

mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
echo "DOCKER $*" >> "${MOCK_LOG}"
if [[ "${1:-}" == "compose" && "${2:-}" == "version" ]]; then exit 0; fi
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

export PATH="${TMP}/mockbin:${PATH}"
export MOCK_LOG="${TMP}/mock.log"
export WBAB_WINEBOT_DIR="${TMP}/tools/WineBot"
export WBAB_SMOKE_TRUST_DEV_CERT="1"
export WBAB_DEV_CERT_DIR="${TMP}/agent-privileged/signing/dev"

bash "${TMP}/tools/winebot-smoke.sh" "${TMP}/dist/FakeSetup.exe" || true

log="$(cat "${MOCK_LOG}")"
echo "${log}" | grep -q "update-ca-certificates" || { echo "Expected trust import Linux CA command" >&2; exit 1; }
echo "${log}" | grep -q "certutil -A" || { echo "Expected trust import NSS certutil command" >&2; exit 1; }
echo "OK: smoke trust dev cert path"
