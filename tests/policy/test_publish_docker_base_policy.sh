#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

dockerfiles=(
  "${ROOT_DIR}/tools/winbuild/Dockerfile"
  "${ROOT_DIR}/tools/packaging/Dockerfile"
  "${ROOT_DIR}/tools/signing/Dockerfile"
)

for f in "${dockerfiles[@]}"; do
  [[ -f "${f}" ]] || { echo "Missing Dockerfile: ${f}" >&2; exit 1; }
  grep -q '^FROM debian:trixie-slim$' "${f}" || {
    echo "Dockerfile must use debian:trixie-slim base image: ${f}" >&2
    exit 1
  }
  if grep -Eiq '^FROM[[:space:]].*ubuntu' "${f}"; then
    echo "Dockerfile must not use ubuntu base images: ${f}" >&2
    exit 1
  fi
done

echo "OK: publish Dockerfile base image policy"
