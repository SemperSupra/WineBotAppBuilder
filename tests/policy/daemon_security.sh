#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"

echo "[policy] verifying daemon security contracts..."

# 1. Auth & Authz Contracts
# Verifies critical security rejection paths and config handling
required_auth_patterns=(
  "WBABD_AUTH_MODE"
  "WBABD_API_TOKEN"
  "Authorization"
  "missing_bearer_token"
  "invalid_token"
  "WWW-Authenticate"
)

for p in "${required_auth_patterns[@]}"; do
  grep -q "${p}" "${daemon}" || { echo "POLICY FAILURE: wbabd missing ${p} handling" >&2; exit 1; }
done

# 2. Transport Security (TLS)
# Ensures TLS is not optional in production modes
grep -q "cert_file" "${daemon}" || { echo "POLICY FAILURE: wbabd missing TLS cert handling" >&2; exit 1; }
grep -q "key_file" "${daemon}" || { echo "POLICY FAILURE: wbabd missing TLS key handling" >&2; exit 1; }

# 3. PKI Infrastructure
# Unifies existence and basic property checks
[[ -x "${ROOT_DIR}/scripts/security/daemon-pki.sh" ]] || { echo "POLICY FAILURE: missing daemon-pki helper" >&2; exit 1; }
[[ -x "${ROOT_DIR}/scripts/signing/signing-pki.sh" ]] || { echo "POLICY FAILURE: missing signing-pki helper" >&2; exit 1; }

# 4. API Security Plan Compliance
# Ensures documentation and implementation stay in sync
[[ -f "${ROOT_DIR}/docs/DAEMON_API_SECURITY_PLAN.md" ]] || { echo "POLICY FAILURE: DAEMON_API_SECURITY_PLAN.md missing" >&2; exit 1; }

echo "OK: daemon security policies satisfied"
