#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan sign .)"

grep -q '"command": "sign"' <<< "${plan}" || { echo "Missing sign command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in sign plan" >&2; exit 1; }
grep -q '"signer_image": "' <<< "${plan}" || { echo "Missing sign policy in plan" >&2; exit 1; }
