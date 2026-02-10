#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/signing" "${TMP}/project"
cp "${ROOT_DIR}/tools/sign-dev.sh" "${TMP}/tools/sign-dev.sh"
chmod +x "${TMP}/tools/sign-dev.sh"

cat >"${TMP}/tools/signing/Dockerfile" <<'EOF'
FROM scratch
EOF

mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
echo "DOCKER $*" >> "${MOCK_LOG}"
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

export PATH="${TMP}/mockbin:${PATH}"
export MOCK_LOG="${TMP}/mock.log"
export WBAB_ALLOW_LOCAL_BUILD="1"
export WBAB_SIGNER_DOCKERFILE="${TMP}/tools/signing/Dockerfile"

bash "${TMP}/tools/sign-dev.sh" "${TMP}/project"

log="$(cat "${MOCK_LOG}")"

echo "${log}" | grep -q "DOCKER build " || { echo "Expected docker build when opt-in enabled" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run " || { echo "Expected docker run" >&2; exit 1; }

echo "OK: sign local-build opt-in policy satisfied"
