#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"

grep -q 'WBABD_TLS_CERT_FILE' "${daemon}" || { echo "wbabd missing WBABD_TLS_CERT_FILE handling" >&2; exit 1; }
grep -q 'WBABD_TLS_KEY_FILE' "${daemon}" || { echo "wbabd missing WBABD_TLS_KEY_FILE handling" >&2; exit 1; }
grep -q 'WBABD_TLS_CLIENT_CA_FILE' "${daemon}" || { echo "wbabd missing WBABD_TLS_CLIENT_CA_FILE handling" >&2; exit 1; }
grep -q 'WBABD_HTTP_MAX_BODY_BYTES' "${daemon}" || { echo "wbabd missing WBABD_HTTP_MAX_BODY_BYTES handling" >&2; exit 1; }
grep -q 'WBABD_HTTP_REQUEST_TIMEOUT_SECS' "${daemon}" || { echo "wbabd missing WBABD_HTTP_REQUEST_TIMEOUT_SECS handling" >&2; exit 1; }
grep -q 'ssl.SSLContext' "${daemon}" || { echo "wbabd missing TLS context construction" >&2; exit 1; }
grep -q 'wrap_socket' "${daemon}" || { echo "wbabd missing TLS socket wrapping" >&2; exit 1; }
grep -q 'CERT_REQUIRED' "${daemon}" || { echo "wbabd missing mTLS CERT_REQUIRED path" >&2; exit 1; }
grep -q 'payload_too_large' "${daemon}" || { echo "wbabd missing payload size rejection path" >&2; exit 1; }

echo "OK: daemon transport phase3 policy"
