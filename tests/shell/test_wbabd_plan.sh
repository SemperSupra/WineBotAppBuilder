#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

plan="$(WBABD_STORE_PATH="${TMP}/plan-store.sqlite" "${ROOT_DIR}/tools/wbabd" plan op-plan-1 build .)"

grep -q '"op_id": "op-plan-1"' <<< "${plan}" || { echo "Missing op_id in wbabd plan output" >&2; exit 1; }
grep -q '"verb": "build"' <<< "${plan}" || { echo "Missing verb in wbabd plan output" >&2; exit 1; }
grep -q '"steps"' <<< "${plan}" || { echo "Missing steps in wbabd plan output" >&2; exit 1; }

echo "OK: wbabd plan output"
