#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COUNTERS_PATH="${WBABD_PREFLIGHT_COUNTERS_PATH:-${ROOT_DIR}/../agent-sandbox/state/preflight-counters.json}"
AUDIT_PATH="${WBABD_AUDIT_LOG_PATH:-${ROOT_DIR}/../agent-sandbox/state/audit-log.sqlite}"
WINDOW="${WBABD_PREFLIGHT_AUDIT_WINDOW:-50}"
FORMAT="text"

usage() {
  cat <<'EOF'
Usage:
  scripts/security/preflight-trend-report.sh [--window N] [--json]

Summarize startup preflight trend from persisted counters and recent audit events.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --window)
      [[ $# -ge 2 ]] || { echo "ERROR: --window requires a value" >&2; exit 2; }
      WINDOW="$2"
      shift 2
      ;;
    --json)
      FORMAT="json"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ "${WINDOW}" =~ ^[0-9]+$ ]] || { echo "ERROR: --window must be a positive integer" >&2; exit 2; }
(( WINDOW > 0 )) || { echo "ERROR: --window must be > 0" >&2; exit 2; }

python3 - "${COUNTERS_PATH}" "${AUDIT_PATH}" "${WINDOW}" "${FORMAT}" <<'PY'
import json
import time
from pathlib import Path
import sys

counters_path = Path(sys.argv[1])
audit_path = Path(sys.argv[2])
window = int(sys.argv[3])
fmt = sys.argv[4]

def load_counters(path: Path) -> dict:
    base = {"ok": 0, "failed": 0, "total": 0, "last_status": "", "updated_at": 0}
    if not path.exists():
        return base
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return base
    if not isinstance(raw, dict):
        return base
    try:
        ok = max(0, int(raw.get("ok", 0)))
        failed = max(0, int(raw.get("failed", 0)))
    except Exception:
        return base
    total = ok + failed
    last_status = str(raw.get("last_status", "")).strip()
    try:
        updated_at = int(raw.get("updated_at", 0))
    except Exception:
        updated_at = 0
    return {"ok": ok, "failed": failed, "total": total, "last_status": last_status, "updated_at": updated_at}

def load_preflight_events(path: Path, window: int) -> list[dict]:
    events: list[dict] = []
    if not path.exists():
        return events
    try:
        import sqlite3
        with sqlite3.connect(path) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                "SELECT status, ts FROM audit_events WHERE event_type = 'command.preflight' ORDER BY ts DESC LIMIT ?",
                (window,)
            ).fetchall()
            for row in rows:
                status = str(row["status"]).strip().lower()
                if status in {"ok", "failed"}:
                    events.append({"status": status, "ts": row["ts"]})
    except Exception:
        pass
    return events

def get_total_preflight_count(path: Path) -> int:
    if not path.exists(): return 0
    try:
        import sqlite3
        with sqlite3.connect(path) as conn:
            return conn.execute(
                "SELECT COUNT(*) FROM audit_events WHERE event_type = 'command.preflight'"
            ).fetchone()[0]
    except Exception:
        return 0

counters = load_counters(counters_path)
recent = load_preflight_events(audit_path, window)
total_audit_events = get_total_preflight_count(audit_path)
recent_ok = sum(1 for e in recent if e["status"] == "ok")
recent_failed = sum(1 for e in recent if e["status"] == "failed")
recent_total = recent_ok + recent_failed
cumulative_total = counters["total"]
rate = 0.0 if cumulative_total == 0 else round((counters["ok"] / cumulative_total) * 100.0, 2)
recent_rate = 0.0 if recent_total == 0 else round((recent_ok / recent_total) * 100.0, 2)

out = {
    "status": "ok",
    "generated_at": int(time.time()),
    "paths": {
        "counters": str(counters_path),
        "audit_log": str(audit_path),
    },
    "cumulative": {
        "ok": counters["ok"],
        "failed": counters["failed"],
        "total": cumulative_total,
        "success_rate_pct": rate,
        "last_status": counters["last_status"],
        "updated_at": counters["updated_at"],
    },
    "recent_window": {
        "window": window,
        "events_seen": recent_total,
        "ok": recent_ok,
        "failed": recent_failed,
        "success_rate_pct": recent_rate,
    },
    "audit_events_total_seen": total_audit_events,
}

if fmt == "json":
    print(json.dumps(out, indent=2, sort_keys=True))
    raise SystemExit(0)

print("preflight trend report")
print(f"cumulative: ok={out['cumulative']['ok']} failed={out['cumulative']['failed']} total={out['cumulative']['total']} success_rate_pct={out['cumulative']['success_rate_pct']}")
print(f"recent(window={window}): ok={recent_ok} failed={recent_failed} events_seen={recent_total} success_rate_pct={recent_rate}")
print(f"source: counters={counters_path} audit={audit_path}")
PY
