#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/scripts/security"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp -r "${ROOT_DIR}/core/"* "${TMP}/core/"
cp "${ROOT_DIR}/scripts/security/daemon-preflight.sh" "${TMP}/scripts/security/daemon-preflight.sh"
chmod +x "${TMP}/tools/wbabd" "${TMP}/scripts/security/daemon-preflight.sh"

set +e
out="$(
  cd "${TMP}" && ./tools/wbabd serve --preflight --host 127.0.0.1 --port 19999 2>&1
)"
rc=$?
set -e

[[ "${rc}" -ne 0 ]] || { echo "Expected serve --preflight to fail when preflight requirements are unmet" >&2; exit 1; }
grep -q 'preflight failed' <<< "${out}" || { echo "Expected preflight failure message" >&2; exit 1; }
grep -q 'token auth enabled' <<< "${out}" || { echo "Expected token-auth preflight validation error" >&2; exit 1; }

echo "OK: wbabd serve --preflight flag"
