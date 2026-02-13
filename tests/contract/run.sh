#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[contract] running..."
"${ROOT_DIR}/tests/contract/test_cli_help.sh"
"${ROOT_DIR}/tests/contract/test_envvars_doc.sh"
"${ROOT_DIR}/tests/contract/test_plan_build_json.sh"
"${ROOT_DIR}/tests/contract/test_plan_lint_json.sh"
"${ROOT_DIR}/tests/contract/test_plan_test_json.sh"
"${ROOT_DIR}/tests/contract/test_plan_package_json.sh"
"${ROOT_DIR}/tests/contract/test_plan_sign_json.sh"
"${ROOT_DIR}/tests/contract/test_plan_smoke_json.sh"
echo "[contract] ok"
