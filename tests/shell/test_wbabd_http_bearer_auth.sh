#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
SERVER_PID=""
cleanup() {
  if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
  rm -rf "${TMP}"
}
trap cleanup EXIT

mkdir -p "${TMP}/tools" "${TMP}/core"
cp "${ROOT_DIR}/tools/wbabd" "${TMP}/tools/wbabd"
cp -r "${ROOT_DIR}/core/"* "${TMP}/core/"
chmod +x "${TMP}/tools/wbabd"

SERVER_OUT="${TMP}/server.out"
SERVER_ERR="${TMP}/server.err"
TOKEN="wbab-test-token"

(
  cd "${TMP}"
  exec env \
    PYTHONUNBUFFERED=1 \
    WBABD_TLS_DISABLE=1 \
    WBABD_AUTH_MODE=token \
    WBABD_API_TOKEN="${TOKEN}" \
    WBABD_ALLOW_MULTIPLE_INSTANCES=1 \
    WBABD_STORE_PATH="${TMP}/store.sqlite" \
    ./tools/wbabd serve --host 127.0.0.1 --port 0
) >"${SERVER_OUT}" 2>"${SERVER_ERR}" &
SERVER_PID=$!

listening_line=""
for _ in $(seq 1 100); do
  listening_line="$(grep -m1 '"'"'"status"'"'": "'"'"listening"'"'"' "${SERVER_OUT}" 2>/dev/null || true)"
  if [[ -n "${listening_line}" ]]; then
    break
  fi
  if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
    echo "wbabd exited before listening" >&2
    cat "${SERVER_ERR}" >&2 || true
    exit 1
  fi
  sleep 0.05
done

[[ -n "${listening_line}" ]] || {
  echo "Timed out waiting for wbabd listening event" >&2
  cat "${SERVER_OUT}" >&2 || true
  cat "${SERVER_ERR}" >&2 || true
  exit 1
}

PORT="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["port"])' <<< "${listening_line}")"

python3 - "${PORT}" "${TOKEN}" <<'PY'
import http.client
import json
import sys

port = int(sys.argv[1])
token = sys.argv[2]


def request(headers=None):
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=2)
    conn.request("GET", "/health", headers=headers or {})
    response = conn.getresponse()
    body = response.read().decode("utf-8")
    auth_header = response.getheader("WWW-Authenticate")
    status = response.status
    conn.close()
    return status, json.loads(body), auth_header


status, body, challenge = request()
assert status == 401, (status, body)
assert body == {"error": "missing_bearer_token"}, body
assert challenge == 'Bearer realm="wbabd"', challenge

status, body, challenge = request({"Authorization": "Bearer wrong-token"})
assert status == 401, (status, body)
assert body == {"error": "invalid_token"}, body
assert challenge == 'Bearer realm="wbabd"', challenge

status, body, challenge = request({"Authorization": f"Bearer {token}"})
assert status == 200, (status, body)
assert body == {"status": "ok"}, body
assert challenge is None, challenge
PY

echo "OK: wbabd live HTTP bearer authentication semantics"
