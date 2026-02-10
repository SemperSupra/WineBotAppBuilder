#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

preflight="${ROOT_DIR}/scripts/security/daemon-preflight.sh"
pki_script="${ROOT_DIR}/scripts/security/daemon-pki.sh"

WBABD_PKI_DIR="${TMP}/pki" bash "${pki_script}" init >/dev/null
token_file="${TMP}/token.txt"
printf 'abc123token\n' > "${token_file}"
chmod 600 "${token_file}"

policy_file="${TMP}/authz.json"
cat > "${policy_file}" <<'EOF'
{
  "principals": {
    "wbabd-systemd": { "verbs": ["health", "status", "plan", "run:build"] },
    "*": { "verbs": ["health"] }
  }
}
EOF

WBABD_AUTH_MODE=token \
WBABD_API_TOKEN_FILE="${token_file}" \
WBABD_TLS_CERT_FILE="${TMP}/pki/server.crt.pem" \
WBABD_TLS_KEY_FILE="${TMP}/pki/server.key.pem" \
WBABD_TLS_CLIENT_CA_FILE="${TMP}/pki/ca.crt.pem" \
WBABD_AUTHZ_POLICY_FILE="${policy_file}" \
WBABD_HTTP_MAX_BODY_BYTES=2048 \
WBABD_HTTP_REQUEST_TIMEOUT_SECS=5 \
bash "${preflight}" serve >/dev/null

set +e
missing_token_out="$(WBABD_AUTH_MODE=token bash "${preflight}" serve 2>&1)"
missing_token_rc=$?
set -e
[[ "${missing_token_rc}" -ne 0 ]] || { echo "Expected failure for missing token config" >&2; exit 1; }
grep -q 'token auth enabled' <<< "${missing_token_out}" || { echo "Expected missing token error" >&2; exit 1; }

set +e
bad_limit_out="$(WBABD_AUTH_MODE=off WBABD_HTTP_MAX_BODY_BYTES=0 bash "${preflight}" serve 2>&1)"
bad_limit_rc=$?
set -e
[[ "${bad_limit_rc}" -ne 0 ]] || { echo "Expected failure for invalid body limit" >&2; exit 1; }
grep -q 'WBABD_HTTP_MAX_BODY_BYTES must be > 0' <<< "${bad_limit_out}" || { echo "Expected body-limit error" >&2; exit 1; }

bad_policy="${TMP}/bad-authz.json"
cat > "${bad_policy}" <<'EOF'
{"principals":{"broken":{"verbs":"not-a-list"}}}
EOF
set +e
bad_policy_out="$(
  WBABD_AUTH_MODE=off WBABD_AUTHZ_POLICY_FILE="${bad_policy}" bash "${preflight}" serve 2>&1
)"
bad_policy_rc=$?
set -e
[[ "${bad_policy_rc}" -ne 0 ]] || { echo "Expected failure for invalid authz policy schema" >&2; exit 1; }
grep -q 'WBABD_AUTHZ_POLICY_FILE schema invalid' <<< "${bad_policy_out}" || { echo "Expected authz schema error" >&2; exit 1; }

echo "OK: daemon preflight validation"
