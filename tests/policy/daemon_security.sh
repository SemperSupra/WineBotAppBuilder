#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[policy] verifying daemon security durable prerequisites..."

# Runtime auth/TLS semantics are validated behaviorally in the bounded shell
# suite rather than pinned to exact implementation text here:
# - test_wbabd_serve_auth_config.sh: auth mode/token configuration fails closed
# - test_wbabd_http_bearer_auth.sh: live missing/invalid/valid bearer responses
#   including the WWW-Authenticate challenge
# - test_wbabd_authz_policy.sh: principal permission allow/deny behavior
# - test_wbabd_serve_tls_limits_config.sh: TLS pair validation, TLS-required
#   default, explicit TLS opt-out, and HTTP limit validation

# 1. PKI Infrastructure
# These helpers are durable operator capabilities with their own lifecycle tests.
[[ -x "${ROOT_DIR}/scripts/security/daemon-pki.sh" ]] || { echo "POLICY FAILURE: missing daemon-pki helper" >&2; exit 1; }
[[ -x "${ROOT_DIR}/scripts/signing/signing-pki.sh" ]] || { echo "POLICY FAILURE: missing signing-pki helper" >&2; exit 1; }

# 2. API Security Plan
# Preserve the durable architecture/security artifact without treating prose
# presence as proof that runtime controls executed.
[[ -f "${ROOT_DIR}/docs/DAEMON_API_SECURITY_PLAN.md" ]] || { echo "POLICY FAILURE: DAEMON_API_SECURITY_PLAN.md missing" >&2; exit 1; }

echo "OK: daemon security durable prerequisites satisfied"
