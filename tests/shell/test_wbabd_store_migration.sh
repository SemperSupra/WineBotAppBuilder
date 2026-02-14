#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools" "${TMP}/core"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp "${ROOT_DIR}/core/wbab_core.py" "${TMP}/core/wbab_core.py"
cp "${ROOT_DIR}/core/discovery.py" "${TMP}/core/discovery.py"
cp "${ROOT_DIR}/core/scm.py" "${TMP}/core/scm.py"
chmod +x "${TMP}/tools/wbabd"

store="${TMP}/legacy-store.json"
cat > "${store}" <<'EOF'
{
  "operations": {
    "legacy-op-1": {
      "op_id": "legacy-op-1",
      "verb": "build",
      "status": "succeeded",
      "result": {
        "exit_code": 0,
        "stdout": "",
        "stderr": "",
        "command": ["tools/winbuild-build.sh", "."]
      }
    }
  }
}
EOF

status_json="$(WBABD_STORE_PATH="${store}" "${TMP}/tools/wbabd" status legacy-op-1)"
grep -q '"status": "succeeded"' <<< "${status_json}" || { echo "Expected legacy op status to remain readable" >&2; exit 1; }

grep -q '"schema_version": "wbab.store.v1"' "${store}" || { echo "Expected migrated store schema version" >&2; exit 1; }
grep -q '"from_schema": "legacy.unversioned"' "${store}" || { echo "Expected migration from legacy marker" >&2; exit 1; }
grep -q '"migrated_at":' "${store}" || { echo "Expected migration timestamp" >&2; exit 1; }
grep -q '"legacy-op-1"' "${store}" || { echo "Expected migrated store to preserve operations" >&2; exit 1; }

echo "OK: wbabd store schema migration"
