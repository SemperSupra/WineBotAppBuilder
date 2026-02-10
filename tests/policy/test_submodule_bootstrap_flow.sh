#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${ROOT_DIR}/scripts/bootstrap-submodule.sh"
readme="${ROOT_DIR}/README.md"
context="${ROOT_DIR}/docs/CONTEXT_BUNDLE.md"
state="${ROOT_DIR}/docs/STATE.md"

[[ -x "${script}" ]] || { echo "Missing executable submodule bootstrap script" >&2; exit 1; }
grep -q 'git submodule add https://github.com/mark-e-deyoung/WineBot tools/WineBot' "${script}" || {
  echo "Bootstrap script missing WineBot submodule add command" >&2
  exit 1
}

grep -q './scripts/bootstrap-submodule.sh' "${readme}" || { echo "README missing bootstrap-submodule bring-up step" >&2; exit 1; }
grep -q './scripts/bootstrap-submodule.sh' "${context}" || { echo "CONTEXT_BUNDLE missing bootstrap-submodule bring-up command" >&2; exit 1; }
grep -q 'scripts/bootstrap-submodule.sh' "${state}" || { echo "STATE missing submodule bootstrap reference" >&2; exit 1; }

echo "OK: submodule bootstrap flow policy"
