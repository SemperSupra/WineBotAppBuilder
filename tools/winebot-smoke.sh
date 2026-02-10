#!/usr/bin/env bash
set -euo pipefail

# Smoke test runner for installers using WineBot.
# Default: prefer GHCR stable WineBot image; do not build locally.
#
# Usage:
#   ./tools/winebot-smoke.sh dist/MySetup.exe
#
INSTALLER="${1:-}"
if [[ -z "${INSTALLER}" ]]; then
  echo "Usage: $0 <path-to-installer.exe>" >&2
  exit 2
fi
if [[ ! -f "${INSTALLER}" ]]; then
  echo "ERROR: installer not found: ${INSTALLER}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="${ROOT_DIR}/tools/compose.sh"

WINEBOT_DIR="${WBAB_WINEBOT_DIR:-${ROOT_DIR}/tools/WineBot}"
BASE_COMPOSE="${WINEBOT_DIR}/compose/docker-compose.yml"
PROFILE="${WBAB_WINEBOT_PROFILE:-headless}"

WINEBOT_IMAGE="${WBAB_WINEBOT_IMAGE:-ghcr.io/mark-e-deyoung/winebot}"
WINEBOT_TAG="${WBAB_WINEBOT_TAG:-stable}"
WINEBOT_SERVICE="${WBAB_WINEBOT_SERVICE:-winebot}"
SMOKE_SKIP_INSTALL="${WBAB_SMOKE_SKIP_INSTALL:-0}"
SMOKE_TRUST_DEV_CERT="${WBAB_SMOKE_TRUST_DEV_CERT:-0}"
INSTALLER_ARGS="${WBAB_INSTALLER_ARGS:-/S}"
APP_ARGS="${WBAB_APP_ARGS:-}"
SESSION_ID="${WBAB_SMOKE_SESSION_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
ARTIFACTS_DIR="${WBAB_ARTIFACTS_DIR:-${ROOT_DIR}/artifacts/winebot/${SESSION_ID}}"
DEV_CERT_DIR="${WBAB_DEV_CERT_DIR:-${ROOT_DIR}/.wbab/signing/dev}"
DEV_CERT_CRT="${WBAB_DEV_CERT_CRT:-${DEV_CERT_DIR}/dev.crt.pem}"

# Automated verification options
EXTRACT_PATH="${WBAB_SMOKE_EXTRACT_PATH:-}"
EXPECT_CONTENT="${WBAB_SMOKE_EXPECT_CONTENT:-}"

OVERRIDE="${ROOT_DIR}/tools/winebot.ghcr.override.yml"
TRUST_HELPER="${ROOT_DIR}/tools/winebot-trust-dev-cert.sh"

# Validate WineBot compose path (submodule expected)
if [[ ! -f "${BASE_COMPOSE}" ]]; then
  echo "ERROR: WineBot compose file not found: ${BASE_COMPOSE}" >&2
  echo "Hint: run ./scripts/bootstrap-submodule.sh to add WineBot as a submodule." >&2
  exit 3
fi

# Ensure override references requested image/tag (idempotent regeneration)
cat >"${OVERRIDE}" <<EOF
services:
  ${WINEBOT_SERVICE}:
    image: ${WINEBOT_IMAGE}:${WINEBOT_TAG}
    pull_policy: always
EOF

# Ensure cleanup even on failure
cleanup() {
  set +e
  mkdir -p "${ARTIFACTS_DIR}"
  
  # Automated verification (before down)
  if [[ -n "${EXTRACT_PATH}" ]]; then
    echo "INFO: Extracting ${EXTRACT_PATH} from container..."
    # Get container ID
    CID="$("${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" ps -q "${WINEBOT_SERVICE}")"
    if [[ -n "${CID}" ]]; then
      # Convert Windows path to Linux path (best effort)
      CONTAINER_PATH="${EXTRACT_PATH}"
      if [[ "${CONTAINER_PATH}" =~ ^[Cc]:[\\/] ]]; then
         RELATIVE_PATH="${CONTAINER_PATH:3}"
         RELATIVE_PATH="${RELATIVE_PATH//\\//}"
         CONTAINER_PATH="/wineprefix/drive_c/${RELATIVE_PATH}"
      fi
      
      # We try two casings for 'Public' if needed, or just rely on the user providing correct casing for now.
      # Actually, since we can't 'find' easily on a potentially stopped container via docker cp, 
      # we'll try the most common mappings.
      
      echo "INFO: Attempting to copy from ${CID}:${CONTAINER_PATH}"
      docker cp "${CID}:${CONTAINER_PATH}" "${ARTIFACTS_DIR}/extracted_output.txt" 2>/dev/null
      
      # Try capital 'Public' if the first one failed
      if [[ ! -s "${ARTIFACTS_DIR}/extracted_output.txt" && "${CONTAINER_PATH}" == *"/public/"* ]]; then
         ALT_PATH="${CONTAINER_PATH/\/public\//\/Public\/}"
         echo "INFO: Retrying with ${CID}:${ALT_PATH}"
         docker cp "${CID}:${ALT_PATH}" "${ARTIFACTS_DIR}/extracted_output.txt" 2>/dev/null
      fi
    else
      echo "WARN: Container not found, skipping extraction."
    fi
  fi

  "${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" logs --no-color \
    > "${ARTIFACTS_DIR}/compose.log" 2>&1 || true
  cp -f "${OVERRIDE}" "${ARTIFACTS_DIR}/winebot.override.yml" 2>/dev/null || true
  cp -f "${INSTALLER}" "${ARTIFACTS_DIR}/$(basename "${INSTALLER}")" 2>/dev/null || true
  if [[ -d "${WINEBOT_DIR}/artifacts" ]]; then
    cp -a "${WINEBOT_DIR}/artifacts/." "${ARTIFACTS_DIR}/" 2>/dev/null || true
  fi
  "${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" down -v >/dev/null 2>&1

  # Final verification check
  if [[ -n "${EXTRACT_PATH}" && -n "${EXPECT_CONTENT}" ]]; then
    if [[ -f "${ARTIFACTS_DIR}/extracted_output.txt" ]]; then
      actual="$(tr -d '\r\n' < "${ARTIFACTS_DIR}/extracted_output.txt" | xargs)"
      expected="$(echo "${EXPECT_CONTENT}" | xargs)"
      echo "INFO: Verifying content..."
      echo "DEBUG: Expected: [${expected}]"
      echo "DEBUG: Actual:   [${actual}]"
      if [[ "${actual}" == "${expected}" ]]; then
        echo "SUCCESS: Content matches expected value."
      else
        echo "ERROR: Content mismatch!" >&2
        exit 5
      fi
    else
      echo "ERROR: Extraction failed, cannot verify content." >&2
      exit 6
    fi
  fi
}
trap cleanup EXIT

# Stage installer into WineBot apps folder (expected by WineBot install scripts)
mkdir -p "${WINEBOT_DIR}/apps"
cp -f "${INSTALLER}" "${WINEBOT_DIR}/apps/"

# Pull-first policy (local WineBot builds are intentionally disabled)
"${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" pull
"${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" up -d --no-build --pull always

if [[ "${SMOKE_TRUST_DEV_CERT}" == "1" ]]; then
  if [[ ! -x "${TRUST_HELPER}" ]]; then
    echo "ERROR: trust helper not executable: ${TRUST_HELPER}" >&2
    exit 2
  fi
  "${TRUST_HELPER}" "${BASE_COMPOSE}" "${OVERRIDE}" "${PROFILE}" "${WINEBOT_SERVICE}" "${DEV_CERT_CRT}"
fi

# Install the app unless explicitly skipped (useful for infrastructure-only smoke checks)
if [[ "${SMOKE_SKIP_INSTALL}" != "1" ]]; then
  echo "INFO: Installing ${INSTALLER} with args: ${INSTALLER_ARGS}..."
  # shellcheck disable=SC2086
  "${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" \
    exec --user winebot "${WINEBOT_SERVICE}" \
    timeout 60s wine "apps/$(basename "${INSTALLER}")" ${INSTALLER_ARGS}
else
  echo "INFO: WBAB_SMOKE_SKIP_INSTALL=1; skipping installation"
fi

# Optional sanity run (set WBAB_SANITY_EXE to a Windows path)
if [[ -n "${WBAB_SANITY_EXE:-}" ]]; then
  echo "INFO: Running sanity check: ${WBAB_SANITY_EXE} with args: ${APP_ARGS}..."
  # shellcheck disable=SC2086
  "${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" \
    exec --user winebot "${WINEBOT_SERVICE}" \
    timeout 60s wine "${WBAB_SANITY_EXE}" ${APP_ARGS}
fi

# Capture at least one screenshot if WineBot supports it; do not fail smoke if screenshot fails
"${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE}" --profile "${PROFILE}" exec --user winebot "${WINEBOT_SERVICE}" \
  ./automation/screenshot.sh || true
