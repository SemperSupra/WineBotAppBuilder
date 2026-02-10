#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan build .)"

grep -q '"command": "build"' <<< "${plan}" || { echo "Missing build command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in build plan" >&2; exit 1; }
grep -q '"allow_local_build": "' <<< "${plan}" || { echo "Missing build policy in plan" >&2; exit 1; }
