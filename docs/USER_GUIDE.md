# WineBotAppBuilder User Guide

This guide explains how to use the **WineBotAppBuilder** toolchain to build, package, sign, and test Windows applications on Linux.

## 1. Prerequisites

- Docker and Docker Compose v2 installed.
- (Optional) `osslsigncode` and `openssl` for local signing operations.

## 2. Environment Setup

Initialize the toolchain and dependencies:

```bash
./scripts/bootstrap-submodule.sh
./tools/wbab doctor
```

## 3. Linting and Static Analysis

Code quality should be verified before building. The toolchain provides a `lint` command:

```bash
export WBAB_LINT_CMD="wbab-lint-real"
./tools/wbab lint myapp/
```

By default, the `winbuild` toolchain includes `clang-tidy` for C++ analysis.

## 4. Building an Application

The toolchain supports **CMake** and **Makefile** projects. Place your source in a directory (e.g., `myapp/`) and run:

```bash
# Enable local image builds if you haven't published images to GHCR
export WBAB_ALLOW_LOCAL_BUILD=1
export WBAB_BUILD_CMD="wbab-build-real"

./tools/wbab build myapp/
```

Outputs will be placed in `myapp/out/`.

## 5. Unit Testing

Execute unit tests within the build container. If your tests are Windows binaries, the toolchain uses **Wine** to run them:

```bash
export WBAB_TEST_CMD="wbab-test-real"
./tools/wbab test myapp/
```

## 6. Packaging an Installer

Create an NSIS script (`installer.nsi`) in your project directory. Then package it:

```bash
export WBAB_PACKAGE_CMD="wbab-package-real installer.nsi"
./tools/wbab package myapp/
```

The installer will be created in `myapp/dist/`.

## 7. Code Signing

### Initialize PKI
Before signing, initialize the internal CA:

```bash
./scripts/signing/signing-pki.sh init
```

### Sign the Installer
```bash
export WBAB_SIGN_INPUT="dist/MySetup.exe"
export WBAB_SIGN_OUTPUT="dist/MySetup-signed.exe"
export WBAB_SIGN_CMD="osslsigncode sign -pkcs12 .wbab/signing/pki/codesign.pfx -readpass .wbab/signing/pki/codesign.pfx.pass -h sha256 -in ${WBAB_SIGN_INPUT} -out ${WBAB_SIGN_OUTPUT}"

./tools/wbab sign myapp/
```

## 8. Smoke Testing with WineBot

Run your signed installer in a headless Wine environment and collect evidence:

```bash
export WBAB_SMOKE_TRUST_DEV_CERT=1
export WBAB_DEV_CERT_CRT=".wbab/signing/pki/ca.crt.pem"
export WBAB_SANITY_EXE="C:\Program Files\MyApp\App.exe"
export WBAB_INSTALLER_ARGS="/S"

./tools/wbab smoke myapp/dist/MySetup-signed.exe
```

### Automated Verification
To automatically verify that your app wrote a specific file with expected content:

```bash
export WBAB_SMOKE_EXTRACT_PATH="C:\users\public\Documents\output.txt"
export WBAB_SMOKE_EXPECT_CONTENT="Success"

./tools/wbab smoke myapp/dist/MySetup-signed.exe
```

Artifacts (logs, extracted files, screenshots) are saved in `artifacts/winebot/<timestamp>/`.

## 9. Using the Daemon (API)

For non-CLI automation, use `wbabd`:

```bash
# Start the HTTP API
export WBABD_API_TOKEN="secret-token"
./tools/wbabd serve --port 8787

# Or use the local JSON adapter
./tools/wbabd api '{"op": "health"}'
```

See `docs/CONTRACTS.md` for full API schema.
