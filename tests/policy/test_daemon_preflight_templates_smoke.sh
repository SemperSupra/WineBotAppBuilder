#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

preflight="${ROOT_DIR}/scripts/security/daemon-preflight.sh"
policy="${ROOT_DIR}/deploy/daemon/authz-policy.example.json"

mk_fixtures() {
  local dir="$1"
  mkdir -p "${dir}"
  printf 'token-value\n' > "${dir}/token.txt"
  printf 'cert\n' > "${dir}/server.crt.pem"
  printf 'key\n' > "${dir}/server.key.pem"
  printf 'ca\n' > "${dir}/ca.crt.pem"
  chmod 600 "${dir}/token.txt" "${dir}/server.key.pem"
  chmod 644 "${dir}/server.crt.pem" "${dir}/ca.crt.pem"
}

run_with_template() {
  local template="$1"
  local env_name="$2"
  local base="${TMP}/${env_name}"
  mkdir -p "${base}"
  mk_fixtures "${base}"

  set -a
  # shellcheck disable=SC1090
  source "${template}"
  set +a

  WBABD_API_TOKEN_FILE="${base}/token.txt" \
  WBABD_TLS_CERT_FILE="${base}/server.crt.pem" \
  WBABD_TLS_KEY_FILE="${base}/server.key.pem" \
  WBABD_TLS_CLIENT_CA_FILE="${base}/ca.crt.pem" \
  WBABD_AUTHZ_POLICY_FILE="${policy}" \
  WBABD_HTTP_MAX_BODY_BYTES=2048 \
  WBABD_HTTP_REQUEST_TIMEOUT_SECS=5 \
  bash "${preflight}" serve >/dev/null
}

run_with_template "${ROOT_DIR}/deploy/daemon/wbabd.systemd.env.example" "systemd"
run_with_template "${ROOT_DIR}/deploy/daemon/wbabd.container.env.example" "container"

echo "OK: daemon preflight template smoke"
