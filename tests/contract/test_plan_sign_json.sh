#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

plan="$("${ROOT_DIR}/tools/wbab" plan sign .)"

grep -q '"command": "sign"' <<< "${plan}" || { echo "Missing sign command in plan" >&2; exit 1; }
grep -q '"project_dir": "."' <<< "${plan}" || { echo "Missing project_dir input in sign plan" >&2; exit 1; }
grep -q '"signer_image": "' <<< "${plan}" || { echo "Missing sign policy in plan" >&2; exit 1; }
grep -q '"execution_mode": "dev-cert"' <<< "${plan}" || { echo "Expected dev-cert sign mode by default" >&2; exit 1; }
grep -q '"execution_command": "wbab-sign"' <<< "${plan}" || { echo "Expected real signing command by default" >&2; exit 1; }
grep -q '"dev_cert_dir": "' <<< "${plan}" || { echo "Expected dev-cert host path in sign plan" >&2; exit 1; }

fixture_plan="$(WBAB_SIGN_MODE=fixture "${ROOT_DIR}/tools/wbab" plan sign .)"
grep -q '"execution_mode": "fixture"' <<< "${fixture_plan}" || { echo "Expected explicit fixture sign mode" >&2; exit 1; }
grep -q '"execution_command": "wbab-sign-fixture"' <<< "${fixture_plan}" || { echo "Expected explicit fixture signing command" >&2; exit 1; }

custom_plan="$(WBAB_SIGN_CMD='echo custom-sign' "${ROOT_DIR}/tools/wbab" plan sign .)"
grep -q '"execution_mode": "custom"' <<< "${custom_plan}" || { echo "Expected legacy command override to resolve to custom sign mode" >&2; exit 1; }
grep -q '"execution_command": "echo custom-sign"' <<< "${custom_plan}" || { echo "Expected custom sign command in plan" >&2; exit 1; }

legacy_fixture_plan="$(WBAB_SIGN_USE_DEV_CERT=0 "${ROOT_DIR}/tools/wbab" plan sign .)"
grep -q '"execution_mode": "fixture"' <<< "${legacy_fixture_plan}" || { echo "Expected legacy 0 selector to resolve to fixture" >&2; exit 1; }
