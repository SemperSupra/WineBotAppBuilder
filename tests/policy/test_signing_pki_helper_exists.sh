#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${ROOT_DIR}/scripts/signing/signing-pki.sh"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"

[[ -x "${script}" ]] || { echo "Missing executable signing PKI helper: ${script}" >&2; exit 1; }
grep -q 'init' "${script}" || { echo "signing-pki helper missing init command" >&2; exit 1; }
grep -q 'rotate' "${script}" || { echo "signing-pki helper missing rotate command" >&2; exit 1; }
grep -q 'status' "${script}" || { echo "signing-pki helper missing status command" >&2; exit 1; }
grep -q 'export' "${script}" || { echo "signing-pki helper missing export command" >&2; exit 1; }
grep -q 'import' "${script}" || { echo "signing-pki helper missing import command" >&2; exit 1; }
grep -q 'codeSigning' "${script}" || { echo "signing-pki helper missing code-signing EKU profile" >&2; exit 1; }
grep -q 'WBAB_SIGNING_PKI_DIR' "${script}" || { echo "signing-pki helper missing WBAB_SIGNING_PKI_DIR env handling" >&2; exit 1; }

grep -q 'scripts/signing/signing-pki.sh' "${contracts}" || { echo "Contracts missing signing PKI helper contract reference" >&2; exit 1; }
grep -q 'WBAB_SIGNING_PKI_DIR' "${contracts}" || { echo "Contracts missing WBAB_SIGNING_PKI_DIR contract reference" >&2; exit 1; }

echo "OK: signing PKI helper policy"
