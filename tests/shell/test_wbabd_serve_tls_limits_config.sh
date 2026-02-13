#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/core/discovery.py" "${TMP}/core/discovery.py"
chmod +x "${TMP}/tools/wbabd"

set +e
missing_pair="$(
  cd "${TMP}" && WBABD_AUTH_MODE=off WBABD_TLS_CERT_FILE=/tmp/nope.crt ./tools/wbabd serve --host 127.0.0.1 --port 19999 2>&1
)"
rc_missing_pair=$?
set -e
[[ "${rc_missing_pair}" -ne 0 ]] || { echo "Expected serve to fail with partial TLS config" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE and WBABD_TLS_KEY_FILE must both be set' <<< "${missing_pair}" || {
  echo "Expected missing TLS pair error" >&2
  exit 1
}

set +e
missing_cert="$(
  cd "${TMP}" && WBABD_AUTH_MODE=off WBABD_TLS_CERT_FILE=/tmp/nope.crt WBABD_TLS_KEY_FILE=/tmp/nope.key ./tools/wbabd serve --host 127.0.0.1 --port 19999 2>&1
)"
rc_missing_cert=$?
set -e
[[ "${rc_missing_cert}" -ne 0 ]] || { echo "Expected serve to fail with missing TLS cert file" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE does not exist' <<< "${missing_cert}" || {
  echo "Expected missing TLS cert file error" >&2
  exit 1
}

set +e
bad_body_limit="$(
  cd "${TMP}" && WBABD_AUTH_MODE=off WBABD_HTTP_MAX_BODY_BYTES=0 ./tools/wbabd serve --host 127.0.0.1 --port 19999 2>&1
)"
rc_bad_body_limit=$?
set -e
[[ "${rc_bad_body_limit}" -ne 0 ]] || { echo "Expected serve to fail with invalid body limit" >&2; exit 1; }
grep -q 'WBABD_HTTP_MAX_BODY_BYTES must be > 0' <<< "${bad_body_limit}" || {
  echo "Expected invalid body limit error" >&2
  exit 1
}

set +e
bad_timeout="$(
  cd "${TMP}" && WBABD_AUTH_MODE=off WBABD_HTTP_REQUEST_TIMEOUT_SECS=0 ./tools/wbabd serve --host 127.0.0.1 --port 19999 2>&1
)"
rc_bad_timeout=$?
set -e
[[ "${rc_bad_timeout}" -ne 0 ]] || { echo "Expected serve to fail with invalid request timeout" >&2; exit 1; }
grep -q 'WBABD_HTTP_REQUEST_TIMEOUT_SECS must be > 0' <<< "${bad_timeout}" || {
  echo "Expected invalid request timeout error" >&2
  exit 1
}

echo "OK: wbabd serve TLS/limits config enforcement"
