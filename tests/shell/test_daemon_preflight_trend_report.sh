#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/scripts/security"
cp "${ROOT_DIR}/scripts/security/preflight-trend-report.sh" "${TMP}/scripts/security/preflight-trend-report.sh"
chmod +x "${TMP}/scripts/security/preflight-trend-report.sh"

counters="${TMP}/preflight-counters.json"
audit="${TMP}/audit-log.jsonl"

cat > "${counters}" <<'EOF'
{
  "ok": 2,
  "failed": 1,
  "total": 3,
  "last_status": "ok",
  "updated_at": 1700000123
}
EOF

cat > "${audit}" <<'EOF'
{"event_type":"command.preflight","status":"ok","ts":"2026-02-08T00:00:00Z"}
{"event_type":"command.preflight","status":"failed","ts":"2026-02-08T00:01:00Z"}
{"event_type":"command.run","status":"started","ts":"2026-02-08T00:01:10Z"}
{"event_type":"command.preflight","status":"failed","ts":"2026-02-08T00:02:00Z"}
{"event_type":"command.preflight","status":"ok","ts":"2026-02-08T00:03:00Z"}
EOF

json_out="$(
  WBABD_PREFLIGHT_COUNTERS_PATH="${counters}" \
  WBABD_AUDIT_LOG_PATH="${audit}" \
  WBABD_PREFLIGHT_AUDIT_WINDOW=3 \
  "${TMP}/scripts/security/preflight-trend-report.sh" --json
)"

python3 - "${json_out}" <<'PY'
import json
import sys

doc = json.loads(sys.argv[1])
assert doc["status"] == "ok"
assert doc["cumulative"]["ok"] == 2
assert doc["cumulative"]["failed"] == 1
assert doc["cumulative"]["total"] == 3
assert doc["recent_window"]["window"] == 3
assert doc["recent_window"]["events_seen"] == 3
assert doc["recent_window"]["ok"] == 1
assert doc["recent_window"]["failed"] == 2
assert doc["audit_events_total_seen"] == 4
PY

text_out="$(
  WBABD_PREFLIGHT_COUNTERS_PATH="${counters}" \
  WBABD_AUDIT_LOG_PATH="${audit}" \
  "${TMP}/scripts/security/preflight-trend-report.sh" --window 2
)"
grep -q 'preflight trend report' <<< "${text_out}" || { echo "Expected text report header" >&2; exit 1; }
grep -q 'recent(window=2): ok=1 failed=1 events_seen=2' <<< "${text_out}" || {
  echo "Expected text report recent window summary" >&2
  exit 1
}

echo "OK: daemon preflight trend report"
