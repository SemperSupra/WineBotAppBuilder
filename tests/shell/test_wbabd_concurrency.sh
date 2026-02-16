#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Running wbabd concurrency test..."
python3 "${ROOT_DIR}/tests/test_wbabd_concurrency.py"
echo "OK: wbabd concurrency test"
