#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -f .gitmodules ]]; then
  if grep -q 'path = tools/WineBot' .gitmodules; then
    echo "WineBot submodule already configured."
    git submodule update --init --recursive
    exit 0
  fi
fi

echo "Adding WineBot as submodule at tools/WineBot ..."
rm -rf tools/WineBot || true
git submodule add https://github.com/mark-e-deyoung/WineBot tools/WineBot
git submodule update --init --recursive

echo "Done."
