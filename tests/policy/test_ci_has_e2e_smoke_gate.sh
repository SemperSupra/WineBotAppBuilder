#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

wf="${ROOT_DIR}/.github/workflows/ci.yml"

[[ -f "${wf}" ]] || { echo "Missing CI workflow: .github/workflows/ci.yml" >&2; exit 1; }
grep -qE '^\s*e2e-smoke:' "${wf}" || { echo "CI workflow missing e2e-smoke job" >&2; exit 1; }
grep -q 'tests/e2e/run.sh' "${wf}" || { echo "CI workflow missing tests/e2e/run.sh execution" >&2; exit 1; }
