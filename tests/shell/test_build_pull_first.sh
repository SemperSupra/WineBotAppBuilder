#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/project"
cp "${ROOT_DIR}/tools/winbuild-build.sh" "${TMP}/tools/winbuild-build.sh"
chmod +x "${TMP}/tools/winbuild-build.sh"

mkdir -p "${TMP}/mockbin"
cat >"${TMP}/mockbin/docker" <<'EOF'
#!/usr/bin/env bash
echo "DOCKER $*" >> "${MOCK_LOG}"
exit 0
EOF
chmod +x "${TMP}/mockbin/docker"

export PATH="${TMP}/mockbin:${PATH}"
export MOCK_LOG="${TMP}/mock.log"
export WBAB_ALLOW_LOCAL_BUILD="0"

bash "${TMP}/tools/winbuild-build.sh" "${TMP}/project"

log="$(cat "${MOCK_LOG}")"

echo "${log}" | grep -q "DOCKER pull " || { echo "Expected docker pull" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER run " || { echo "Expected docker run" >&2; exit 1; }
echo "${log}" | grep -q "DOCKER build " && { echo "Did not expect docker build" >&2; exit 1; }

echo "OK: build pull-first/no-build policy satisfied"
