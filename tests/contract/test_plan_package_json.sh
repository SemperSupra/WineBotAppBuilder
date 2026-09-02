#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan package .)"

grep -q '"command": "package"' <<< "${plan}" || { echo "Missing package command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in package plan" >&2; exit 1; }
grep -q '"packager_image": "' <<< "${plan}" || { echo "Missing package policy in plan" >&2; exit 1; }
grep -q '"execution_mode": "real"' <<< "${plan}" || { echo "Expected real package mode by default" >&2; exit 1; }
grep -q '"execution_command": "wbab-package"' <<< "${plan}" || { echo "Expected real package command by default" >&2; exit 1; }

fixture_plan="$(WBAB_PACKAGE_MODE=fixture "${ROOT_DIR}/tools/wbab" plan package .)"
grep -q '"execution_mode": "fixture"' <<< "${fixture_plan}" || { echo "Expected explicit fixture package mode" >&2; exit 1; }
grep -q '"execution_command": "wbab-package-fixture"' <<< "${fixture_plan}" || { echo "Expected fixture package command" >&2; exit 1; }

custom_plan="$(WBAB_PACKAGE_CMD='echo custom-package' "${ROOT_DIR}/tools/wbab" plan package .)"
grep -q '"execution_mode": "custom"' <<< "${custom_plan}" || { echo "Expected legacy override to resolve to custom package mode" >&2; exit 1; }
grep -q '"execution_command": "echo custom-package"' <<< "${custom_plan}" || { echo "Expected custom package command in plan" >&2; exit 1; }
