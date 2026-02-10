#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"

grep -q 'WBABD_AUTH_MODE' "${daemon}" || { echo "wbabd missing WBABD_AUTH_MODE handling" >&2; exit 1; }
grep -q 'WBABD_API_TOKEN' "${daemon}" || { echo "wbabd missing WBABD_API_TOKEN handling" >&2; exit 1; }
grep -q 'WBABD_API_TOKEN_FILE' "${daemon}" || { echo "wbabd missing WBABD_API_TOKEN_FILE handling" >&2; exit 1; }
grep -q 'Authorization' "${daemon}" || { echo "wbabd missing Authorization header validation" >&2; exit 1; }
grep -q 'missing_bearer_token' "${daemon}" || { echo "wbabd missing bearer-token rejection path" >&2; exit 1; }
grep -q 'invalid_token' "${daemon}" || { echo "wbabd missing invalid-token rejection path" >&2; exit 1; }
grep -q 'WWW-Authenticate' "${daemon}" || { echo "wbabd missing WWW-Authenticate response header" >&2; exit 1; }

echo "OK: daemon auth phase1 policy"
