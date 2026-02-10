#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan package .)"

grep -q '"command": "package"' <<< "${plan}" || { echo "Missing package command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in package plan" >&2; exit 1; }
grep -q '"packager_image": "' <<< "${plan}" || { echo "Missing package policy in plan" >&2; exit 1; }
