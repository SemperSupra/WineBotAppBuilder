#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_contract() {
  local test_path="$1"
  case "${test_path}" in
    *.py) python3 "${ROOT_DIR}/${test_path}" ;;
    *) bash "${ROOT_DIR}/${test_path}" ;;
  esac
}

echo "[contract] running..."
run_contract tests/contract/test_cli_help.sh
run_contract tests/contract/test_envvars_doc.sh
run_contract tests/contract/test_plan_json.py
run_contract tests/contract/test_build_output_structure.sh
run_contract tests/contract/test_cli_ux.sh
echo "[contract] ok"
