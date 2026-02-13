#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core" "${TMP}/scripts/security"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/core/discovery.py" "${TMP}/core/discovery.py"
cp "${ROOT_DIR}/scripts/security/daemon-preflight.sh" "${TMP}/scripts/security/daemon-preflight.sh"
chmod +x "${TMP}/tools/wbabd" "${TMP}/scripts/security/daemon-preflight.sh"

status_file="${TMP}/preflight-status.json"

set +e
(
  cd "${TMP}"
  WBABD_PREFLIGHT_STATUS_PATH="${status_file}" ./tools/wbabd serve --preflight --host 127.0.0.1 --port 19999 >/dev/null 2>&1
)
rc=$?
set -e
[[ "${rc}" -ne 0 ]] || { echo "Expected preflight serve to fail without token config" >&2; exit 1; }

resp="$(
  cd "${TMP}" && WBABD_PREFLIGHT_STATUS_PATH="${status_file}" ./tools/wbabd api '{"op":"preflight_status"}'
)"
grep -q '"status": "failed"' <<< "${resp}" || { echo "Expected failed preflight status payload" >&2; exit 1; }
grep -q '"source": "wbabd --preflight"' <<< "${resp}" || { echo "Expected source marker in preflight status payload" >&2; exit 1; }
grep -q '"checked_at":' <<< "${resp}" || { echo "Expected checked_at in preflight status payload" >&2; exit 1; }

echo "OK: daemon preflight status API"
