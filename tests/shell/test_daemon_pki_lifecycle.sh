#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

script="${ROOT_DIR}/scripts/security/daemon-pki.sh"
export WBABD_PKI_DIR="${TMP}/pki"

bash "${script}" init

for n in ca.crt.pem ca.key.pem server.crt.pem server.key.pem client.crt.pem client.key.pem; do
  [[ -f "${WBABD_PKI_DIR}/${n}" ]] || { echo "Missing generated file: ${n}" >&2; exit 1; }
done

openssl verify -CAfile "${WBABD_PKI_DIR}/ca.crt.pem" "${WBABD_PKI_DIR}/server.crt.pem" >/dev/null 2>&1 || {
  echo "Server cert failed CA verification" >&2
  exit 1
}

openssl verify -CAfile "${WBABD_PKI_DIR}/ca.crt.pem" "${WBABD_PKI_DIR}/client.crt.pem" >/dev/null 2>&1 || {
  echo "Client cert failed CA verification" >&2
  exit 1
}

export_dir="${TMP}/exported"
bash "${script}" export "${export_dir}"
for n in ca.crt.pem ca.key.pem server.crt.pem server.key.pem client.crt.pem client.key.pem; do
  [[ -f "${export_dir}/${n}" ]] || { echo "Missing exported file: ${n}" >&2; exit 1; }
done

import_dir="${TMP}/imported-pki"
WBABD_PKI_DIR="${import_dir}" bash "${script}" import "${export_dir}"
for n in ca.crt.pem ca.key.pem server.crt.pem server.key.pem client.crt.pem client.key.pem; do
  [[ -f "${import_dir}/${n}" ]] || { echo "Missing imported file: ${n}" >&2; exit 1; }
done

bash "${script}" rotate
find "${WBABD_PKI_DIR}" -maxdepth 1 -type d -name 'backup-*' | grep -q . || { echo "Missing rotate backup dir" >&2; exit 1; }
status_out="$(bash "${script}" status)"
grep -q 'present:' <<< "${status_out}" || { echo "Expected status output with present files" >&2; exit 1; }

echo "OK: daemon PKI lifecycle"
