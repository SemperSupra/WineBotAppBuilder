#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[e2e] running..."
"${ROOT_DIR}/tests/e2e/test_wbab_pipeline_mocked.sh"
echo "[e2e] ok"
