#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan build .)"

grep -q '"command": "build"' <<< "${plan}" || { echo "Missing build command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in build plan" >&2; exit 1; }
grep -q '"allow_local_build": "' <<< "${plan}" || { echo "Missing build policy in plan" >&2; exit 1; }
grep -q '"execution_mode": "real"' <<< "${plan}" || { echo "Expected real build mode by default" >&2; exit 1; }
grep -q '"execution_command": "wbab-build"' <<< "${plan}" || { echo "Expected real build command by default" >&2; exit 1; }

fixture_plan="$(WBAB_BUILD_MODE=fixture "${ROOT_DIR}/tools/wbab" plan build .)"
grep -q '"execution_mode": "fixture"' <<< "${fixture_plan}" || { echo "Expected explicit fixture build mode" >&2; exit 1; }
grep -q '"execution_command": "wbab-build-fixture"' <<< "${fixture_plan}" || { echo "Expected fixture build command" >&2; exit 1; }

custom_plan="$(WBAB_BUILD_CMD='echo custom-build' "${ROOT_DIR}/tools/wbab" plan build .)"
grep -q '"execution_mode": "custom"' <<< "${custom_plan}" || { echo "Expected legacy override to resolve to custom build mode" >&2; exit 1; }
grep -q '"execution_command": "echo custom-build"' <<< "${custom_plan}" || { echo "Expected custom build command in plan" >&2; exit 1; }
