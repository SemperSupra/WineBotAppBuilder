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
out="$(
  cd "${TMP}" && WBABD_AUTH_MODE=token ./tools/wbabd serve --host 127.0.0.1 --port 19999 2>&1
)"
rc=$?
set -e

[[ "${rc}" -ne 0 ]] || { echo "Expected serve to fail closed without token config" >&2; exit 1; }
grep -q 'token auth enabled but no WBABD_API_TOKEN or WBABD_API_TOKEN_FILE provided' <<< "${out}" || {
  echo "Expected missing token config error message" >&2
  exit 1
}

set +e
out_mode="$(
  cd "${TMP}" && WBABD_AUTH_MODE=bogus ./tools/wbabd serve --host 127.0.0.1 --port 19999 2>&1
)"
rc_mode=$?
set -e
[[ "${rc_mode}" -ne 0 ]] || { echo "Expected serve to reject unsupported auth mode" >&2; exit 1; }
grep -q 'unsupported WBABD_AUTH_MODE for serve' <<< "${out_mode}" || {
  echo "Expected unsupported auth mode error message" >&2
  exit 1
}

echo "OK: wbabd serve auth config enforcement"
