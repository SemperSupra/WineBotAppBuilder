#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp -r "${ROOT_DIR}/core/"* "${TMP}/core/"
chmod +x "${TMP}/tools/wbabd"

store="${TMP}/store.sqlite"

# Test that wbabd initializes a valid SQLite store
WBABD_STORE_PATH="${store}" ./tools/wbabd plan sqlite-init-1 build . >/dev/null

[[ -f "${store}" ]] || { echo "Expected SQLite store file to be created" >&2; exit 1; }

python3 - "${store}" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
res = conn.execute("SELECT value FROM metadata WHERE key = 'instance_id'").fetchone()
if not res or not res[0]:
    print("instance_id not found in metadata table", file=sys.stderr)
    sys.exit(1)

res = conn.execute("SELECT op_id FROM operations WHERE op_id = 'sqlite-init-1'").fetchone()
# Plan doesn't persist, so we don't expect op here yet.
PY

echo "OK: wbabd store sqlite initialization"
