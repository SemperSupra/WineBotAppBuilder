#!/usr/bin/env bash
set -euo pipefail

# Internal signing script for wbab signer container.
# Supported modes:
# 1. Fixture mode (default)
# 2. Dev-cert mode (enabled by WBAB_SIGN_USE_DEV_CERT=1)

SIGN_INPUT="${WBAB_SIGN_INPUT:-dist/FakeSetup.exe}"
SIGN_OUTPUT="${WBAB_SIGN_OUTPUT:-dist/FakeSetup-signed.exe}"
DEV_CERT_DIR="${WBAB_DEV_CERT_DIR:-agent-privileged/signing/dev}"

echo "wbab-sign: Starting..."

if [[ "${WBAB_SIGN_USE_DEV_CERT:-0}" == "1" ]]; then
    echo "wbab-sign: Dev-cert mode enabled."
    
    if [[ ! -f "${SIGN_INPUT}" ]]; then
        echo "ERROR: Input file not found: ${SIGN_INPUT}" >&2
        exit 2
    fi

    if [[ ! -f "${DEV_CERT_DIR}/dev.pfx" || ! -f "${DEV_CERT_DIR}/dev.pfx.pass" ]]; then
        echo "ERROR: Dev cert material missing in ${DEV_CERT_DIR}" >&2
        exit 2
    fi

    if ! command -v osslsigncode >/dev/null 2>&1; then
        echo "ERROR: osslsigncode not found in container" >&2
        exit 3
    fi

    mkdir -p "$(dirname "${SIGN_OUTPUT}")"
    
    echo "wbab-sign: Signing ${SIGN_INPUT} with dev cert..."
    osslsigncode sign \
        -pkcs12 "${DEV_CERT_DIR}/dev.pfx" \
        -readpass "${DEV_CERT_DIR}/dev.pfx.pass" \
        -h sha256 \
        -in "${SIGN_INPUT}" \
        -out "${SIGN_OUTPUT}"
    
    echo "wbab-sign: SUCCESS (signed with dev cert)"
    echo "dev cert sign completed" > dist/sign-fixture.txt
else
    echo "wbab-sign: Fixture mode enabled."
    
    # We create a dummy if it doesn't exist for the fixture test path
    if [[ ! -f "dist/FakeSetup.exe" ]]; then
        mkdir -p dist
        echo "mock-unsigned-exe" > dist/FakeSetup.exe
    fi

    mkdir -p dist
    cp -f dist/FakeSetup.exe dist/FakeSetup-signed.exe
    echo "fixture sign completed" > dist/sign-fixture.txt
    echo "wbab-sign: SUCCESS (fixture mock)"
fi
