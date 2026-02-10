#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/WineBot/compose" "${TMP}/tools/WineBot/apps" "${TMP}/project" "${TMP}/tests/e2e"
cp "${ROOT_DIR}/tests/e2e/test_wbab_pipeline_real.sh" "${TMP}/tests/e2e/test_wbab_pipeline_real.sh"
chmod +x "${TMP}/tests/e2e/test_wbab_pipeline_real.sh"

cat >"${TMP}/tools/WineBot/compose/docker-compose.yml" <<'EOF'
services:
  winebot:
    image: local-placeholder
EOF

mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

mkdir -p "${TMP}/tools"
cat >"${TMP}/tools/wbab" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  build) mkdir -p out dist && echo x > out/FakeApp.exe && echo x > out/build-fixture.txt ;;
  package) mkdir -p dist && cp -f out/FakeApp.exe dist/FakeSetup.exe && echo x > dist/package-fixture.txt ;;
  sign) mkdir -p dist && cp -f dist/FakeSetup.exe dist/FakeSetup-signed.exe && echo x > dist/sign-fixture.txt ;;
  smoke) exit 0 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "${TMP}/tools/wbab"

export PATH="${TMP}/mockbin:${PATH}"
export WBAB_SMOKE_SKIP_INSTALL="0"

set +e
(
  cd "${TMP}"
  ./tests/e2e/test_wbab_pipeline_real.sh
) >"${TMP}/wbab-e2e-real-req.log" 2>&1
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "Expected failure when WBAB_SMOKE_SKIP_INSTALL=0 and WBAB_REAL_INSTALLER_PATH missing" >&2
  exit 1
fi
grep -q "requires WBAB_REAL_INSTALLER_PATH" "${TMP}/wbab-e2e-real-req.log" || { echo "Missing expected error message" >&2; exit 1; }
echo "OK: e2e real installer requirement enforced"
