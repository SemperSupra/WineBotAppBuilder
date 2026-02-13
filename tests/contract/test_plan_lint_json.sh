#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan lint .)"

grep -q '"command": "lint"' <<< "${plan}" || { echo "Missing lint command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in lint plan" >&2; exit 1; }
grep -q '"allow_local_build": "' <<< "${plan}" || { echo "Missing lint policy in plan" >&2; exit 1; }
echo "OK: lint plan"
