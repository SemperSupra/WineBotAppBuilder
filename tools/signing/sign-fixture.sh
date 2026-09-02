#!/usr/bin/env bash
set -euo pipefail

# Explicit non-cryptographic fixture path for isolated tests only.
SIGN_INPUT="${WBAB_SIGN_INPUT:-dist/FakeSetup.exe}"
SIGN_OUTPUT="${WBAB_SIGN_OUTPUT:-dist/FakeSetup-signed.exe}"

if [[ ! -f "${SIGN_INPUT}" ]]; then
  echo "ERROR: fixture input file not found: ${SIGN_INPUT}" >&2
  exit 2
fi

mkdir -p "$(dirname "${SIGN_OUTPUT}")"
cp -f "${SIGN_INPUT}" "${SIGN_OUTPUT}"
printf 'mode=fixture\ninput=%s\noutput=%s\n' "${SIGN_INPUT}" "${SIGN_OUTPUT}" > dist/sign-fixture.txt
echo "wbab-sign-fixture: SUCCESS (copy-only fixture; not cryptographically signed)"
