#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="${ROOT_DIR}/.github/workflows/release.yml"

[[ -f "${wf}" ]] || { echo "Missing release workflow: ${wf}" >&2; exit 1; }

# Release policy: trigger on push tags v*
grep -qE '^\s*push:' "${wf}" || {
  echo "release workflow must keep push trigger" >&2
  exit 1
}
grep -qE 'tags:' "${wf}" || {
  echo "release workflow must restrict push to tags" >&2
  exit 1
}
grep -qE "'v\*'" "${wf}" || {
  echo "release workflow must trigger on v* tags" >&2
  exit 1
}

grep -q 'uses: actions/checkout@v4' "${wf}" || {
  echo "release workflow must pin actions/checkout@v4" >&2
  exit 1
}
grep -q 'submodules: false' "${wf}" || {
  echo "release workflow checkout step must keep submodules: false" >&2
  exit 1
}
grep -qE '^\s*permissions:' "${wf}" || {
  echo "release workflow must declare permissions block" >&2
  exit 1
}
grep -qE '^\s*contents:\s*write' "${wf}" || {
  echo "release workflow permissions must allow contents: write" >&2
  exit 1
}
grep -qE '^\s*packages:\s*write' "${wf}" || {
  echo "release workflow permissions must keep packages: write" >&2
  exit 1
}

buildx_line="$(grep -n 'Set up Docker Buildx' "${wf}" | cut -d: -f1 | head -n1)"
drycheck_line="$(grep -n 'Dry-check publish Dockerfiles (local/CI parity)' "${wf}" | cut -d: -f1 | head -n1)"
login_line="$(grep -n 'Log in to GHCR' "${wf}" | cut -d: -f1 | head -n1)"
publish_line="$(grep -n 'Publish images' "${wf}" | cut -d: -f1 | head -n1)"

[[ -n "${buildx_line}" ]] || {
  echo "release workflow missing buildx setup step name" >&2
  exit 1
}
[[ -n "${drycheck_line}" ]] || {
  echo "release workflow missing dry-check step name" >&2
  exit 1
}
[[ -n "${publish_line}" ]] || {
  echo "release workflow missing publish-images step name" >&2
  exit 1
}
[[ -n "${login_line}" ]] || {
  echo "release workflow missing GHCR login step name" >&2
  exit 1
}

if (( buildx_line >= drycheck_line || drycheck_line >= login_line || login_line >= publish_line )); then
  echo "release workflow must keep step order buildx < dry-check < login < publish" >&2
  exit 1
fi

hadolint_pin_count="$(grep -c 'uses: hadolint/hadolint-action@v3.3.0' "${wf}")"
[[ "${hadolint_pin_count}" == "3" ]] || {
  echo "release workflow must pin hadolint/hadolint-action@v3.3.0 for all three lint steps" >&2
  exit 1
}
trivy_pin_count="$(grep -c 'uses: aquasecurity/trivy-action@0.29.0' "${wf}")"
[[ "${trivy_pin_count}" == "2" ]] || {
  echo "release workflow must pin aquasecurity/trivy-action@0.29.0 for both security and SBOM steps" >&2
  exit 1
}
grep -q 'uses: actions/upload-artifact@v4' "${wf}" || {
  echo "release workflow must pin actions/upload-artifact@v4 for metadata upload" >&2
  exit 1
}
grep -q 'name: Upload publish metadata' "${wf}" || {
  echo "release workflow must keep upload step name: Upload publish metadata" >&2
  exit 1
}

echo "OK: release workflow buildx/dry-check/login/publish ordering"