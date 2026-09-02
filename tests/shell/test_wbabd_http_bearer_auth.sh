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

PORT=""
for _ in $(seq 1 100); do
  PORT="$(python3 - "${SERVER_OUT}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if path.exists():
    for line in path.read_text(encoding="utf-8").splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("status") == "listening":
            print(event["port"])
            break
PY
)"
  if [[ -n "${PORT}" ]]; then
    break
  fi
  if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
    echo "wbabd exited before listening" >&2
    cat "${SERVER_ERR}" >&2 || true
    exit 1
  fi
  sleep 0.05
done

[[ -n "${PORT}" ]] || {
  echo "Timed out waiting for wbabd listening event" >&2
  cat "${SERVER_OUT}" >&2 || true
  cat "${SERVER_ERR}" >&2 || true
  exit 1
}

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
