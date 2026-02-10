#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_BIN="${DOCKER_BIN:-docker}"
CONTEXT_DIR="${1:-${ROOT_DIR}}"

dockerfiles=(
  "${ROOT_DIR}/tools/winbuild/Dockerfile"
  "${ROOT_DIR}/tools/packaging/Dockerfile"
  "${ROOT_DIR}/tools/signing/Dockerfile"
)

for dockerfile in "${dockerfiles[@]}"; do
  [[ -f "${dockerfile}" ]] || { echo "Missing Dockerfile: ${dockerfile}" >&2; exit 1; }
  "${DOCKER_BIN}" buildx build \
    --check \
    --progress=plain \
    --file "${dockerfile}" \
    "${CONTEXT_DIR}"
done

echo "OK: publish Dockerfile dry-check"
