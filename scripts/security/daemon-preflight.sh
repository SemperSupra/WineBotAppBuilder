#!/usr/bin/env bash
set -euo pipefail

mode="${1:-serve}"

usage() {
  cat <<'EOF'
Usage:
  scripts/security/daemon-preflight.sh [serve]

Validates daemon startup configuration before launching `tools/wbabd serve`.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 2
}

require_file() {
  local label="$1"
  local path="$2"
  [[ -n "${path}" ]] || fail "${label} path is empty"
  [[ -f "${path}" ]] || fail "${label} file not found: ${path}"
  [[ -r "${path}" ]] || fail "${label} file not readable: ${path}"
}

validate_limits() {
  local max_body timeout
  max_body="${WBABD_HTTP_MAX_BODY_BYTES:-1048576}"
  timeout="${WBABD_HTTP_REQUEST_TIMEOUT_SECS:-15}"

  [[ "${max_body}" =~ ^[0-9]+$ ]] || fail "WBABD_HTTP_MAX_BODY_BYTES must be an integer: ${max_body}"
  (( max_body > 0 )) || fail "WBABD_HTTP_MAX_BODY_BYTES must be > 0"

  set +e
  python3 - "${timeout}" <<'PY'
import sys
try:
    v = float(sys.argv[1])
except Exception:
    raise SystemExit(2)
if v <= 0:
    raise SystemExit(3)
PY
  local rc=$?
  set -e
  case "${rc}" in
    0) ;;
    2) fail "WBABD_HTTP_REQUEST_TIMEOUT_SECS must be numeric: ${timeout}" ;;
    3) fail "WBABD_HTTP_REQUEST_TIMEOUT_SECS must be > 0" ;;
    *) fail "failed to validate WBABD_HTTP_REQUEST_TIMEOUT_SECS" ;;
  esac
}

resolve_token() {
  local token token_file
  token="${WBABD_API_TOKEN:-}"
  token_file="${WBABD_API_TOKEN_FILE:-}"
  if [[ -n "${token}" ]]; then
    [[ -n "${token//[[:space:]]/}" ]] || fail "WBABD_API_TOKEN is empty/whitespace"
    return 0
  fi
  [[ -n "${token_file}" ]] || fail "token auth enabled but neither WBABD_API_TOKEN nor WBABD_API_TOKEN_FILE is set"
  require_file "WBABD_API_TOKEN_FILE" "${token_file}"
  [[ -n "$(tr -d '[:space:]' < "${token_file}")" ]] || fail "WBABD_API_TOKEN_FILE is empty: ${token_file}"
}

validate_tls() {
  local cert key ca
  cert="${WBABD_TLS_CERT_FILE:-}"
  key="${WBABD_TLS_KEY_FILE:-}"
  ca="${WBABD_TLS_CLIENT_CA_FILE:-}"

  if [[ -z "${cert}" && -z "${key}" && -z "${ca}" ]]; then
    return 0
  fi

  [[ -n "${cert}" && -n "${key}" ]] || fail "WBABD_TLS_CERT_FILE and WBABD_TLS_KEY_FILE must both be set when TLS is enabled"
  require_file "WBABD_TLS_CERT_FILE" "${cert}"
  require_file "WBABD_TLS_KEY_FILE" "${key}"

  if [[ -n "${ca}" ]]; then
    require_file "WBABD_TLS_CLIENT_CA_FILE" "${ca}"
  fi
}

validate_authz_policy() {
  local path
  path="${WBABD_AUTHZ_POLICY_FILE:-}"
  [[ -n "${path}" ]] || return 0
  require_file "WBABD_AUTHZ_POLICY_FILE" "${path}"
  set +e
  python3 - "${path}" <<'PY'
import json
import sys
from pathlib import Path
p = Path(sys.argv[1])
try:
    raw = json.loads(p.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"invalid json: {exc}", file=sys.stderr)
    raise SystemExit(2)
principals = raw.get("principals")
if not isinstance(principals, dict):
    print("principals object required", file=sys.stderr)
    raise SystemExit(3)
for principal, entry in principals.items():
    if not isinstance(principal, str) or not principal:
        print("principal keys must be non-empty strings", file=sys.stderr)
        raise SystemExit(4)
    if not isinstance(entry, dict):
        print(f"principal entry must be object: {principal}", file=sys.stderr)
        raise SystemExit(5)
    verbs = entry.get("verbs")
    if not isinstance(verbs, list) or not all(isinstance(v, str) and v.strip() for v in verbs):
        print(f"principal requires verbs[]: {principal}", file=sys.stderr)
        raise SystemExit(6)
PY
  local rc=$?
  set -e
  case "${rc}" in
    0) ;;
    2) fail "WBABD_AUTHZ_POLICY_FILE is invalid json: ${path}" ;;
    3|4|5|6) fail "WBABD_AUTHZ_POLICY_FILE schema invalid: ${path}" ;;
    *) fail "WBABD_AUTHZ_POLICY_FILE validation failed: ${path}" ;;
  esac
}

case "${mode}" in
  serve)
    auth_mode="${WBABD_AUTH_MODE:-token}"
    case "${auth_mode}" in
      token) resolve_token ;;
      off) ;;
      *) fail "unsupported WBABD_AUTH_MODE for serve: ${auth_mode}" ;;
    esac
    validate_limits
    validate_tls
    validate_authz_policy
    echo "OK: daemon preflight passed for mode=serve"
    ;;
  -h|--help) usage ;;
  *) fail "unknown mode: ${mode}" ;;
esac
