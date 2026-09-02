#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_contract() {
  local test_path="$1"
  bash "${ROOT_DIR}/${test_path}"
}

echo "[contract] running..."
run_contract tests/contract/test_cli_help.sh
run_contract tests/contract/test_envvars_doc.sh
run_contract tests/contract/test_plan_build_json.sh
run_contract tests/contract/test_plan_lint_json.sh
run_contract tests/contract/test_plan_test_json.sh
run_contract tests/contract/test_plan_package_json.sh
run_contract tests/contract/test_plan_sign_json.sh
run_contract tests/contract/test_plan_smoke_json.sh
run_contract tests/contract/test_build_output_structure.sh
run_contract tests/contract/test_cli_ux.sh
echo "[contract] ok"
