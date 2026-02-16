#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

if [[ ! -f "tools/WineBot/compose/docker-compose.yml" ]]; then
  echo "ERROR: WineBot submodule/compose file missing at tools/WineBot/compose/docker-compose.yml" >&2
  echo "Hint: ensure checkout uses submodules: recursive" >&2
  exit 1
fi

mkdir -p out dist artifacts

# Real Docker execution for build/package/sign using public Debian trixie-slim
# so the opt-in workflow can run without project-specific private images.
export WBAB_ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
export WBAB_TAG="${WBAB_TAG:-trixie-slim}"
export WBAB_TOOLCHAIN_IMAGE="${WBAB_TOOLCHAIN_IMAGE:-debian}"
export WBAB_PACKAGER_IMAGE="${WBAB_PACKAGER_IMAGE:-debian}"
export WBAB_SIGNER_IMAGE="${WBAB_SIGNER_IMAGE:-debian}"

# Real WineBot run in headless mode. For scaffold fixtures, skip install and
# validate infrastructure boot/pull/exec path.
export WBAB_WINEBOT_PROFILE="${WBAB_WINEBOT_PROFILE:-headless}"
export WBAB_WINEBOT_IMAGE="${WBAB_WINEBOT_IMAGE:-ghcr.io/mark-e-deyoung/winebot}"
export WBAB_WINEBOT_TAG="${WBAB_WINEBOT_TAG:-v0.9.5}"
export WBAB_SMOKE_SKIP_INSTALL="${WBAB_SMOKE_SKIP_INSTALL:-1}"
export WBAB_SMOKE_TRUST_DEV_CERT="${WBAB_SMOKE_TRUST_DEV_CERT:-0}"
export WBAB_SMOKE_SESSION_ID="${WBAB_SMOKE_SESSION_ID:-e2e-real}"
export WBAB_ARTIFACTS_DIR="${WBAB_ARTIFACTS_DIR:-${ROOT_DIR}/artifacts/e2e-real/winebot}"
REAL_INSTALLER_PATH="${WBAB_REAL_INSTALLER_PATH:-}"

./tools/wbab build .
./tools/wbab package .
./tools/wbab sign .

SMOKE_INSTALLER="dist/FakeSetup.exe"
if [[ "${WBAB_SMOKE_SKIP_INSTALL}" == "0" ]]; then
  if [[ -n "${REAL_INSTALLER_PATH}" ]]; then
    [[ -f "${REAL_INSTALLER_PATH}" ]] || { echo "Missing WBAB_REAL_INSTALLER_PATH file: ${REAL_INSTALLER_PATH}" >&2; exit 2; }
    cp -f "${REAL_INSTALLER_PATH}" dist/RealSetup.exe
    SMOKE_INSTALLER="dist/RealSetup.exe"
  else
    echo "ERROR: WBAB_SMOKE_SKIP_INSTALL=0 requires WBAB_REAL_INSTALLER_PATH to a real installer" >&2
    exit 2
  fi
fi

./tools/wbab smoke "${SMOKE_INSTALLER}"

[[ -f out/FakeApp.exe ]] || { echo "Missing out/FakeApp.exe" >&2; exit 1; }
[[ -f out/build-fixture.txt ]] || { echo "Missing out/build-fixture.txt" >&2; exit 1; }
[[ -f dist/FakeSetup.exe ]] || { echo "Missing dist/FakeSetup.exe" >&2; exit 1; }
[[ -f dist/package-fixture.txt ]] || { echo "Missing dist/package-fixture.txt" >&2; exit 1; }
[[ -f dist/FakeSetup-signed.exe ]] || { echo "Missing dist/FakeSetup-signed.exe" >&2; exit 1; }
[[ -f dist/sign-fixture.txt ]] || { echo "Missing dist/sign-fixture.txt" >&2; exit 1; }
[[ -d artifacts/e2e-real/winebot ]] || { echo "Missing artifacts/e2e-real/winebot" >&2; exit 1; }

echo "OK: real e2e pipeline (build->package->sign->smoke infra) passed"
