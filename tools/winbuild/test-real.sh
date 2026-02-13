#!/usr/bin/env bash
set -euo pipefail

# Real test implementation for validation app.
# Runs the compiled unit tests in Wine.

if [[ ! -f "out/ValidationTests.exe" ]]; then
  echo "TEST: FAILED - out/ValidationTests.exe missing. Run build first." >&2
  exit 1
fi

echo "TEST: Running unit tests in Wine..."
wine out/ValidationTests.exe
echo "TEST: PASSED"
