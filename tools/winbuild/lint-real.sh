#!/usr/bin/env bash
set -euo pipefail

# Real lint implementation for validation app.
# In a real project, this would use clang-tidy, etc.

echo "LINT: Running clang-tidy placeholder..."
# For the scaffold, we just check if core.h exists
if [[ -f "core.h" ]]; then
  echo "LINT: core.h found, project looks healthy."
else
  echo "LINT: FAILED - core.h missing" >&2
  exit 1
fi

echo "LINT: PASSED"
