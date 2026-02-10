#!/usr/bin/env bash
set -euo pipefail

# Import a dev signing cert into a running WineBot container.
# This is best-effort and intended for dev/test smoke validation.
#
# Usage:
#   ./tools/winebot-trust-dev-cert.sh <base-compose> <override-compose> <profile> <service> <cert-path>

BASE_COMPOSE="${1:-}"
OVERRIDE_COMPOSE="${2:-}"
PROFILE="${3:-}"
SERVICE="${4:-}"
CERT_PATH="${5:-}"

if [[ -z "${BASE_COMPOSE}" || -z "${OVERRIDE_COMPOSE}" || -z "${PROFILE}" || -z "${SERVICE}" || -z "${CERT_PATH}" ]]; then
  echo "Usage: $0 <base-compose> <override-compose> <profile> <service> <cert-path>" >&2
  exit 2
fi

if [[ ! -f "${CERT_PATH}" ]]; then
  echo "ERROR: cert not found: ${CERT_PATH}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="${ROOT_DIR}/tools/compose.sh"

if base64 --help 2>/dev/null | grep -q -- '-w'; then
  CERT_B64="$(base64 -w 0 "${CERT_PATH}")"
else
  CERT_B64="$(base64 "${CERT_PATH}" | tr -d '\n')"
fi

# Copy cert into container and trust in Linux CA bundle (best-effort).
"${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE_COMPOSE}" --profile "${PROFILE}" \
  exec --user root "${SERVICE}" sh -lc \
  "echo '${CERT_B64}' | base64 -d > /tmp/wbab-dev.crt && \
   cp /tmp/wbab-dev.crt /usr/local/share/ca-certificates/wbab-dev.crt && \
   (update-ca-certificates || true)"

# Best-effort NSS trust import for the winebot user context.
"${COMPOSE}" -f "${BASE_COMPOSE}" -f "${OVERRIDE_COMPOSE}" --profile "${PROFILE}" \
  exec --user winebot "${SERVICE}" sh -lc \
  "if command -v certutil >/dev/null 2>&1; then \
     mkdir -p \"\$HOME/.pki/nssdb\" && \
     certutil -N --empty-password -d sql:\"\$HOME/.pki/nssdb\" >/dev/null 2>&1 || true; \
     certutil -A -n 'WBAB Dev Code Signing' -t 'C,,' -i /tmp/wbab-dev.crt -d sql:\"\$HOME/.pki/nssdb\" >/dev/null 2>&1 || true; \
   fi"

echo "OK: imported dev cert into WineBot container trust stores"
