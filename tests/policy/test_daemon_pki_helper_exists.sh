#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${ROOT_DIR}/scripts/security/daemon-pki.sh"

[[ -x "${script}" ]] || { echo "Missing executable daemon PKI helper: ${script}" >&2; exit 1; }
grep -q 'cmd_init' "${script}" || { echo "Daemon PKI helper missing init command" >&2; exit 1; }
grep -q 'cmd_rotate' "${script}" || { echo "Daemon PKI helper missing rotate command" >&2; exit 1; }
grep -q 'cmd_status' "${script}" || { echo "Daemon PKI helper missing status command" >&2; exit 1; }
grep -q 'cmd_export' "${script}" || { echo "Daemon PKI helper missing export command" >&2; exit 1; }
grep -q 'cmd_import' "${script}" || { echo "Daemon PKI helper missing import command" >&2; exit 1; }

echo "OK: daemon PKI helper policy"
