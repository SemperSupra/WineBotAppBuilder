#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/winbuild" "${TMP}/project"
cp "${ROOT_DIR}/tools/winbuild-build.sh" "${TMP}/tools/winbuild-build.sh"
chmod +x "${TMP}/tools/winbuild-build.sh"

cat >"${TMP}/tools/winbuild/Dockerfile" <<'EOF'
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
export WBAB_TOOLCHAIN_DOCKERFILE="${TMP}/tools/winbuild/Dockerfile"

bash "${TMP}/tools/winbuild-build.sh" "${TMP}/project"

log="$(cat "${MOCK_LOG}")"

echo "${log}" | grep -q "DOCKER build " || { echo "Expected docker build when opt-in enabled" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run " || { echo "Expected docker run" >&2; exit 1; }

echo "OK: build local-build opt-in policy satisfied"
