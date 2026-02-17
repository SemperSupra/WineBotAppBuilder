#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/WineBot/compose" "${TMP}/tools/WineBot/apps" "${TMP}/project/dist"
cp "${ROOT_DIR}/tools/wbab" "${TMP}/tools/wbab"
cp "${ROOT_DIR}/tools/winbuild-build.sh" "${TMP}/tools/winbuild-build.sh"
cp "${ROOT_DIR}/tools/package-nsis.sh" "${TMP}/tools/package-nsis.sh"
cp "${ROOT_DIR}/tools/sign-dev.sh" "${TMP}/tools/sign-dev.sh"
cp "${ROOT_DIR}/tools/winebot-smoke.sh" "${TMP}/tools/winebot-smoke.sh"
cp "${ROOT_DIR}/tools/compose.sh" "${TMP}/tools/compose.sh"
chmod +x "${TMP}/tools/wbab" \
  "${TMP}/tools/winbuild-build.sh" \
  "${TMP}/tools/package-nsis.sh" \
  "${TMP}/tools/sign-dev.sh" \
  "${TMP}/tools/winebot-smoke.sh" \
  "${TMP}/tools/compose.sh"

cat >"${TMP}/tools/WineBot/compose/docker-compose.yml" <<'EOF'
services:
  winebot:
    image: local-placeholder
EOF

mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "DOCKER $*" >> "${MOCK_LOG}"
if [[ "${1:-}" == "compose" && "${2:-}" == "version" ]]; then
  exit 0
fi
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

export PATH="${TMP}/mockbin:${PATH}"
export MOCK_LOG="${TMP}/mock.log"

export WBAB_ALLOW_LOCAL_BUILD="0"
export WBAB_WINEBOT_DIR="${TMP}/tools/WineBot"
export WBAB_BUILD_CMD="mkdir -p out && echo built > out/FakeApp.exe"
export WBAB_PACKAGE_CMD="mkdir -p dist && echo packaged > dist/FakeSetup.exe"
export WBAB_SIGN_CMD="mkdir -p dist && echo signed > dist/FakeSetup-signed.exe"

(
  cd "${TMP}/project"
  "${TMP}/tools/wbab" build .
  "${TMP}/tools/wbab" package .
  "${TMP}/tools/wbab" sign .
)

# In this mocked test, docker run is intercepted, so container commands do not
# generate real files. Stage a fixture installer to exercise smoke flow.
echo "fixture-installer" > "${TMP}/project/dist/FakeSetup.exe"

"${TMP}/tools/wbab" smoke "${TMP}/project/dist/FakeSetup.exe"

log="$(cat "${MOCK_LOG}")"

echo "${log}" | grep -q "DOCKER pull ghcr.io/sempersupra/winebotappbuilder-winbuild:v0.3.4" || { echo "Missing build pull-first action" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER pull ghcr.io/sempersupra/winebotappbuilder-packager:v0.3.4" || { echo "Missing package pull-first action" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER pull ghcr.io/sempersupra/winebotappbuilder-signer:v0.3.4" || { echo "Missing sign pull-first action" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run .*ghcr.io/sempersupra/winebotappbuilder-winbuild:v0.3.4" || { echo "Missing build container run action" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run .*ghcr.io/sempersupra/winebotappbuilder-packager:v0.3.4" || { echo "Missing package container run action" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run .*ghcr.io/sempersupra/winebotappbuilder-signer:v0.3.4" || { echo "Missing sign container run action" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER compose .* pull" || { echo "Missing WineBot compose pull action" >&2; exit 1; }

echo "OK: e2e mocked pipeline (build->package->sign->smoke) passed"
