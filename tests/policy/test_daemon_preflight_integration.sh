#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${ROOT_DIR}/scripts/security/daemon-preflight.sh"
deploy_doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

[[ -x "${script}" ]] || { echo "Missing executable daemon preflight helper: ${script}" >&2; exit 1; }
grep -q 'WBABD_AUTH_MODE' "${script}" || { echo "Preflight script missing auth mode validation" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE' "${script}" || { echo "Preflight script missing TLS cert validation" >&2; exit 1; }
grep -q 'WBABD_AUTHZ_POLICY_FILE' "${script}" || { echo "Preflight script missing authz policy validation" >&2; exit 1; }
grep -q 'WBABD_HTTP_MAX_BODY_BYTES' "${script}" || { echo "Preflight script missing body-limit validation" >&2; exit 1; }
grep -q 'WBABD_HTTP_REQUEST_TIMEOUT_SECS' "${script}" || { echo "Preflight script missing timeout validation" >&2; exit 1; }

grep -q 'daemon-preflight.sh serve' "${deploy_doc}" || { echo "Deploy profile missing daemon-preflight usage" >&2; exit 1; }

echo "OK: daemon preflight integration policy"
