#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mock_docker="${TMP}/docker"
cat >"${mock_docker}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "${MOCK_DOCKER_LOG}"
EOF
chmod +x "${mock_docker}"

export MOCK_DOCKER_LOG="${TMP}/docker.log"
DOCKER_BIN="${mock_docker}" "${ROOT_DIR}/scripts/publish/dockerfiles-drycheck.sh"

grep -q -- 'buildx build --check --progress=plain --file .*/tools/winbuild/Dockerfile' "${MOCK_DOCKER_LOG}" || {
  echo "dry-check must validate winbuild Dockerfile with buildx --check" >&2
  exit 1
}
grep -q -- 'buildx build --check --progress=plain --file .*/tools/packaging/Dockerfile' "${MOCK_DOCKER_LOG}" || {
  echo "dry-check must validate packaging Dockerfile with buildx --check" >&2
  exit 1
}
grep -q -- 'buildx build --check --progress=plain --file .*/tools/signing/Dockerfile' "${MOCK_DOCKER_LOG}" || {
  echo "dry-check must validate signing Dockerfile with buildx --check" >&2
  exit 1
}

count="$(wc -l < "${MOCK_DOCKER_LOG}")"
[[ "${count}" == "3" ]] || {
  echo "dry-check must invoke docker exactly three times (once per Dockerfile)" >&2
  exit 1
}

echo "OK: publish Dockerfile dry-check smoke"
