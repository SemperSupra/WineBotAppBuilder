#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

wf="${ROOT_DIR}/.github/workflows/publish-ghcr.yml"

[[ -f "${wf}" ]] || { echo "Missing required workflow: .github/workflows/publish-ghcr.yml" >&2; exit 1; }

# Basic policy: must not contain 'push:' trigger
if grep -qE '^\s*push:' "${wf}"; then
  echo "publish-ghcr.yml must not trigger on push" >&2
  exit 1
fi

# Must trigger on release published
grep -qE '^\s*release:' "${wf}" || { echo "publish-ghcr.yml must trigger on release" >&2; exit 1; }
grep -qE 'types:\s*\[\s*published\s*\]' "${wf}" || { echo "publish-ghcr.yml must include release.types: [published]" >&2; exit 1; }
grep -q 'uses: docker/login-action@v3' "${wf}" || { echo "publish-ghcr.yml must login to GHCR" >&2; exit 1; }
