#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[policy] running consolidated domain policies..."

# Execute domain policies
"${ROOT_DIR}/tests/policy/release_pipeline.sh"
"${ROOT_DIR}/tests/policy/daemon_security.sh"
"${ROOT_DIR}/tests/policy/system_architecture.sh"

# Catch-all for remaining specific gates (to be consolidated further as needed)
# Opt-in gates
if [[ "${WBABD_POLICY_E2E_REAL_OPT_IN:-0}" == "1" ]]; then
  "${ROOT_DIR}/tests/policy/test_e2e_real_workflow_opt_in.sh"
fi

echo "[policy] all domain policies satisfied"