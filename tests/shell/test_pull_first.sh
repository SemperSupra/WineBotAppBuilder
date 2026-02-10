#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# Create fake WineBot compose file so runner doesn't abort
mkdir -p "${TMP}/tools/WineBot/compose" "${TMP}/tools/WineBot/apps" "${TMP}/tools"
cp "${ROOT_DIR}/tools/compose.sh" "${TMP}/tools/compose.sh"
cp "${ROOT_DIR}/tools/winebot-smoke.sh" "${TMP}/tools/winebot-smoke.sh"
chmod +x "${TMP}/tools/compose.sh" "${TMP}/tools/winebot-smoke.sh"

cat >"${TMP}/tools/WineBot/compose/docker-compose.yml" <<'EOF'
services:
  winebot:
    image: local-placeholder
EOF

# Fake installer
mkdir -p "${TMP}/dist"
echo "fake-installer" > "${TMP}/dist/FakeSetup.exe"

# Mock docker + compose: capture command lines for assertions
mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
echo "DOCKER $*" >> "${MOCK_LOG}"
if [[ "$1" == "compose" && "$2" == "version" ]]; then exit 0; fi
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

export PATH="${TMP}/mockbin:${PATH}"
export MOCK_LOG="${TMP}/mock.log"

# Run smoke (should use pull-first and no-build by default)
export WBAB_WINEBOT_DIR="${TMP}/tools/WineBot"
export WBAB_WINEBOT_PROFILE="headless"
export WBAB_ALLOW_WINEBOT_LOCAL_BUILD="0"
bash "${TMP}/tools/winebot-smoke.sh" "${TMP}/dist/FakeSetup.exe" || true

log="$(cat "${MOCK_LOG}")"

# Assertions:
# 1) must call docker compose pull
echo "${log}" | grep -q "DOCKER compose .* pull" || { echo "Expected compose pull" >&2; exit 1; }

# 2) must call up with --no-build when local build not allowed
echo "${log}" | grep -q "DOCKER compose .* up .* --no-build" || { echo "Expected up --no-build" >&2; exit 1; }

# 3) must not call docker build
echo "${log}" | grep -q "DOCKER build" && { echo "Did not expect docker build" >&2; exit 1; }

echo "OK: pull-first/no-build policy satisfied"
