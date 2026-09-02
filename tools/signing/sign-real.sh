#!/usr/bin/env bash
set -euo pipefail

# Internal real signing command for the wbab signer container.
# This script performs cryptographic signing only. Fixture/copy behavior lives
# in wbab-sign-fixture and must be selected explicitly by the host wrapper.

SIGN_INPUT="${WBAB_SIGN_INPUT:-dist/FakeSetup.exe}"
SIGN_OUTPUT="${WBAB_SIGN_OUTPUT:-dist/FakeSetup-signed.exe}"
DEV_CERT_DIR="${WBAB_DEV_CERT_DIR:-/run/wbab-signing}"

echo "wbab-sign: mode=dev-cert input=${SIGN_INPUT} output=${SIGN_OUTPUT}"

if [[ ! -f "${SIGN_INPUT}" ]]; then
  echo "ERROR: input file not found: ${SIGN_INPUT}" >&2
  exit 2
fi

if [[ ! -f "${DEV_CERT_DIR}/dev.pfx" || ! -f "${DEV_CERT_DIR}/dev.pfx.pass" ]]; then
  echo "ERROR: dev cert material missing in ${DEV_CERT_DIR}" >&2
  exit 2
fi

if ! command -v osslsigncode >/dev/null 2>&1; then
  echo "ERROR: osslsigncode not found in container" >&2
  exit 3
fi

mkdir -p "$(dirname "${SIGN_OUTPUT}")"
osslsigncode sign \
  -pkcs12 "${DEV_CERT_DIR}/dev.pfx" \
  -readpass "${DEV_CERT_DIR}/dev.pfx.pass" \
  -h sha256 \
  -in "${SIGN_INPUT}" \
  -out "${SIGN_OUTPUT}"

printf 'mode=dev-cert\ninput=%s\noutput=%s\n' "${SIGN_INPUT}" "${SIGN_OUTPUT}" > dist/sign-receipt.txt
echo "wbab-sign: SUCCESS (cryptographically signed with dev cert)"
