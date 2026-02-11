#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required=(
  "${ROOT_DIR}/tools/winbuild/Dockerfile"
  "${ROOT_DIR}/tools/packaging/Dockerfile"
  "${ROOT_DIR}/tools/signing/Dockerfile"
)

for f in "${required[@]}"; do
  [[ -f "${f}" ]] || { echo "Missing required Dockerfile for publish workflow: ${f}" >&2; exit 1; }
done

wf="${ROOT_DIR}/.github/workflows/release.yml"
grep -q 'tools/winbuild/Dockerfile' "${wf}" || { echo "release.yml missing winbuild Dockerfile reference" >&2; exit 1; }
grep -q 'tools/packaging/Dockerfile' "${wf}" || { echo "release.yml missing packaging Dockerfile reference" >&2; exit 1; }
grep -q 'tools/signing/Dockerfile' "${wf}" || { echo "release.yml missing signing Dockerfile reference" >&2; exit 1; }
