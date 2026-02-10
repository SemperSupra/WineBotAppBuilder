#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

script="${ROOT_DIR}/scripts/signing/dev-cert.sh"
export WBAB_DEV_CERT_DIR="${TMP}/devcert"

bash "${script}" init

for n in dev.crt.pem dev.key.pem dev.pfx dev.pfx.pass; do
  [[ -f "${WBAB_DEV_CERT_DIR}/${n}" ]] || { echo "Missing generated file: ${n}" >&2; exit 1; }
done

bash "${script}" rotate
find "${WBAB_DEV_CERT_DIR}" -maxdepth 1 -type d -name 'backup-*' | grep -q . || { echo "Missing rotate backup dir" >&2; exit 1; }

bash "${script}" status | grep -q 'present:' || { echo "Expected status output with present files" >&2; exit 1; }
echo "OK: dev cert lifecycle"
