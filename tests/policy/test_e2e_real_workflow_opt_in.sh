#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

wf="${ROOT_DIR}/.github/workflows/e2e-real.yml"
[[ -f "${wf}" ]] || { echo "Missing workflow: .github/workflows/e2e-real.yml" >&2; exit 1; }

grep -qE '^\s*workflow_dispatch:' "${wf}" || { echo "e2e-real workflow must be opt-in via workflow_dispatch" >&2; exit 1; }
if grep -qE '^\s*push:' "${wf}"; then
  echo "e2e-real workflow must not trigger on push" >&2
  exit 1
fi
if grep -qE '^\s*pull_request:' "${wf}"; then
  echo "e2e-real workflow must not trigger on pull_request" >&2
  exit 1
fi

grep -qE 'submodules:\s*recursive' "${wf}" || { echo "e2e-real workflow must checkout submodules recursively" >&2; exit 1; }
grep -q 'tests/e2e/run-real.sh' "${wf}" || { echo "e2e-real workflow missing tests/e2e/run-real.sh execution" >&2; exit 1; }
grep -q 'tests/e2e/validate-installer-artifact.sh' "${ROOT_DIR}/tests/e2e/run-real.sh" || { echo "e2e-real runner must validate installer artifact before execution" >&2; exit 1; }
grep -q 'WBAB_WINEBOT_IMAGE: ghcr.io/mark-e-deyoung/winebot' "${wf}" || { echo "e2e-real workflow must use official WineBot image" >&2; exit 1; }
grep -q 'installer_path:' "${wf}" || { echo "e2e-real workflow must expose installer_path input" >&2; exit 1; }
grep -q 'trust_dev_cert:' "${wf}" || { echo "e2e-real workflow must expose trust_dev_cert input" >&2; exit 1; }
grep -q 'uses: actions/upload-artifact@v4' "${wf}" || { echo "e2e-real workflow must upload artifacts" >&2; exit 1; }
grep -q 'if: always()' "${wf}" || { echo "e2e-real artifact upload must run on success/failure" >&2; exit 1; }
