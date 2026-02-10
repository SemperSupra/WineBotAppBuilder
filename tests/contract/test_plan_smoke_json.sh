#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan smoke dist/FakeSetup.exe)"

grep -q '"command": "smoke"' <<< "${plan}" || { echo "Missing smoke command in plan" >&2; exit 1; }
grep -q '"installer": "dist/FakeSetup.exe"' <<< "${plan}" || { echo "Missing installer input in plan" >&2; exit 1; }
grep -q '"steps": \[' <<< "${plan}" || { echo "Missing steps list in plan" >&2; exit 1; }
