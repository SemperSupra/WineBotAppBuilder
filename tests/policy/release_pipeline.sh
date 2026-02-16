#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="${ROOT_DIR}/.github/workflows/release.yml"

echo "[policy] verifying release pipeline integrity..."

# Helper for yq validation
check_yq() {
  local query="$1"
  local expected="$2"
  local msg="$3"
  local actual
  actual=$(yq eval "${query}" "${wf}" | tr -d '[:space:]')
  if [[ "${actual}" != "${expected}" ]]; then
    echo "POLICY FAILURE: ${msg} (Expected: ${expected}, Actual: ${actual})" >&2
    exit 1
  fi
}

# 1. Structural Security Gates (yq-based)
check_yq '.on.push.tags[0]' "v*" "release.yml must trigger on v* tags"
check_yq '.permissions.contents' "write" "release.yml must have contents:write"
check_yq '.permissions.packages' "write" "release.yml must have packages:write"

# 2. Docker Image Policy
dockerfiles=(
  "tools/winbuild/Dockerfile"
  "tools/packaging/Dockerfile"
  "tools/signing/Dockerfile"
  "tools/linter/Dockerfile"
)

for df in "${dockerfiles[@]}"; do
  full_path="${ROOT_DIR}/${df}"
  [[ -f "${full_path}" ]] || { echo "POLICY FAILURE: missing ${df}" >&2; exit 1; }
  grep -q "FROM debian:trixie-slim" "${full_path}" || { 
    echo "POLICY FAILURE: ${df} must use official debian:trixie-slim base" >&2; exit 1; 
  }
done

# 3. Official Image Defaults
runner="${ROOT_DIR}/tools/winebot-smoke.sh"
grep -q "ghcr.io/mark-e-deyoung/winebot" "${runner}" || { 
  echo "POLICY FAILURE: winebot-smoke.sh default image must be official" >&2; exit 1; 
}

echo "OK: release pipeline policies satisfied (yq-verified)"
