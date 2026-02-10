#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[e2e-real] running..."
"${ROOT_DIR}/tests/e2e/validate-installer-artifact.sh"
"${ROOT_DIR}/tests/e2e/test_wbab_pipeline_real.sh"
echo "[e2e-real] ok"
