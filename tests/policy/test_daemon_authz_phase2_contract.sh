#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"

grep -q 'WBABD_AUTHZ_POLICY_FILE' "${daemon}" || { echo "wbabd missing WBABD_AUTHZ_POLICY_FILE handling" >&2; exit 1; }
grep -q 'WBABD_PRINCIPAL' "${daemon}" || { echo "wbabd missing WBABD_PRINCIPAL handling" >&2; exit 1; }
grep -q 'X-WBABD-Principal' "${daemon}" || { echo "wbabd missing HTTP principal header handling" >&2; exit 1; }
grep -q 'authz.denied' "${daemon}" || { echo "wbabd missing authz.denied audit event" >&2; exit 1; }
grep -q 'authz.allowed' "${daemon}" || { echo "wbabd missing authz.allowed audit event" >&2; exit 1; }
grep -q '"error": "forbidden"' "${daemon}" || { echo "wbabd missing forbidden authz response path" >&2; exit 1; }

echo "OK: daemon authz phase2 policy"
