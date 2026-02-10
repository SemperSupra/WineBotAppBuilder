#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

script="${ROOT_DIR}/scripts/signing/signing-pki.sh"
export WBAB_SIGNING_PKI_DIR="${TMP}/signing-pki"

bash "${script}" init

for n in ca.crt.pem ca.key.pem codesign.crt.pem codesign.key.pem codesign.pfx codesign.pfx.pass; do
  [[ -f "${WBAB_SIGNING_PKI_DIR}/${n}" ]] || { echo "Missing generated signing PKI file: ${n}" >&2; exit 1; }
done

export_dir="${TMP}/exported"
bash "${script}" export "${export_dir}"
for n in ca.crt.pem ca.key.pem codesign.crt.pem codesign.key.pem codesign.pfx codesign.pfx.pass; do
  [[ -f "${export_dir}/${n}" ]] || { echo "Missing exported signing PKI file: ${n}" >&2; exit 1; }
done

import_dir="${TMP}/imported-pki"
export WBAB_SIGNING_PKI_DIR="${import_dir}"
bash "${script}" import "${export_dir}"
for n in ca.crt.pem ca.key.pem codesign.crt.pem codesign.key.pem codesign.pfx codesign.pfx.pass; do
  [[ -f "${import_dir}/${n}" ]] || { echo "Missing imported signing PKI file: ${n}" >&2; exit 1; }
done

status_out="$(bash "${script}" status)"
grep -q 'present:' <<< "${status_out}" || { echo "Expected status output with present signing PKI files" >&2; exit 1; }

bash "${script}" rotate
find "${import_dir}" -maxdepth 1 -type d -name 'backup-*' | grep -q . || { echo "Missing rotate backup dir for signing PKI" >&2; exit 1; }

echo "OK: signing PKI lifecycle"
