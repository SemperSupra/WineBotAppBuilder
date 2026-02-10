#!/usr/bin/env bash
set -euo pipefail

# Real packaging runner for NSIS projects.
# Detects .nsi files and attempts to compile them.

# Allow override of the NSI script path
NSI_SCRIPT="${1:-}"

mkdir -p dist

if [[ -n "${NSI_SCRIPT}" ]]; then
  if [[ ! -f "${NSI_SCRIPT}" ]]; then
    echo "wbab-package: ERROR: Specified NSI script not found: ${NSI_SCRIPT}"
    exit 1
  fi
  echo "wbab-package: Building specified script: ${NSI_SCRIPT}"
  makensis -V3 "${NSI_SCRIPT}"
else
  # Auto-detect package.nsi or fallback to first .nsi found
  if [[ -f "package.nsi" ]]; then
    echo "wbab-package: Found package.nsi, building..."
    makensis -V3 "package.nsi"
  elif ls *.nsi >/dev/null 2>&1; then
    # Pick the first .nsi file
    f="$(ls *.nsi | head -n 1)"
    echo "wbab-package: Found ${f}, building..."
    makensis -V3 "${f}"
  else
    echo "wbab-package: No .nsi file found in $(pwd)"
    exit 1
  fi
fi
