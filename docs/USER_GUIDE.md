# WineBotAppBuilder User Guide

This guide explains how to use the **WineBotAppBuilder** toolchain to build, package, sign, and test Windows applications on Linux.

## 1. Prerequisites

- Docker and Docker Compose v2 installed.
- (Optional) `osslsigncode` and `openssl` for local signing operations.

## 2. Starting a New Project

Initialize a policy-compliant 4-tier project structure:

```bash
./tools/wbab init "My Awesome App" myapp/
cd myapp/
```

This creates:
- `workspace/`: Your source code and scripts.
- `agent-sandbox/`: Build artifacts and logs.
- `agent-privileged/`: PKI material.
- `manual/`: Documentation.

## 3. The Unified Workflow

WBAB recommends running all operations through the daemon-backed `run` verb. This ensures idempotency, concurrency control, and audit logging.

### Auto-Discovery
If a daemon is running on your network, the CLI will find it automatically:

```bash
# Start the daemon on a build server
export WBABD_AUTH_MODE=off
./tools/wbabd serve --port 8787

# On your dev machine
./tools/wbab run build workspace/
```

## 4. Linting and Static Analysis

Code quality should be verified before building.

```bash
# Local verification
./workspace/scripts/lint.sh

# Or via the daemon
./tools/wbab run lint workspace/
```

## 5. Building an Application

The toolchain supports **CMake** and **Makefile** projects.

```bash
./tools/wbab run build workspace/
```

Outputs will be placed in `agent-sandbox/out/`.

## 6. Unit Testing

Execute unit tests within the build container.

```bash
./tools/wbab run test workspace/
```

## 7. Packaging an Installer

Create an NSIS script (`installer.nsi`) in your project directory.

```bash
./tools/wbab run package workspace/
```

The installer will be created in `agent-sandbox/dist/`.

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
export WBAB_SIGN_CMD="osslsigncode sign -pkcs12 agent-privileged/signing/pki/codesign.pfx -readpass agent-privileged/signing/pki/codesign.pfx.pass -h sha256 -in ${WBAB_SIGN_INPUT} -out ${WBAB_SIGN_OUTPUT}"

./tools/wbab sign myapp/
```

## 8. Smoke Testing with WineBot

Run your signed installer in a headless Wine environment and collect evidence:

```bash
export WBAB_SMOKE_TRUST_DEV_CERT=1
export WBAB_DEV_CERT_CRT="agent-privileged/signing/pki/ca.crt.pem"
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
