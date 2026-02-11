#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

wf="${ROOT_DIR}/.github/workflows/release.yml"

[[ -f "${wf}" ]] || { echo "Missing required workflow: .github/workflows/release.yml" >&2; exit 1; }

# Release policy: must trigger on push tags v*
grep -qE '^\s*push:' "${wf}" || { echo "release.yml must trigger on push" >&2; exit 1; }
grep -qE 'tags:' "${wf}" || { echo "release.yml must restrict push to tags" >&2; exit 1; }
grep -qE "'v\*'" "${wf}" || { echo "release.yml must trigger on v* tags" >&2; exit 1; }

# Release creation and GHCR login
grep -q 'uses: docker/login-action@v3' "${wf}" || { echo "release.yml must login to GHCR" >&2; exit 1; }
grep -q 'gh release create' "${wf}" || { echo "release.yml must create GitHub Release" >&2; exit 1; }