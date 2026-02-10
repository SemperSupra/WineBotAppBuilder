#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WBABD_BIN="${WBABD_BIN:-${ROOT_DIR}/tools/wbabd}"
WINDOW="${WBABD_PREFLIGHT_TREND_WINDOW:-${WBABD_PREFLIGHT_AUDIT_WINDOW:-25}}"
MIN_SUCCESS_RATE="${WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT:-95}"
MAX_RECENT_FAILED="${WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED:-0}"
REQUIRE_EVENTS="${WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS:-0}"

usage() {
  cat <<'EOF'
Usage:
  scripts/security/preflight-trend-threshold-check.sh [--window N] [--min-success-rate PCT] [--max-recent-failed N] [--require-events 0|1]

Validates operator-defined preflight trend thresholds using:
  tools/wbabd api '{"op":"preflight_trend","window":N}'
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --window)
      WINDOW="${2:-}"
      shift 2
      ;;
    --min-success-rate)
      MIN_SUCCESS_RATE="${2:-}"
      shift 2
      ;;
    --max-recent-failed)
      MAX_RECENT_FAILED="${2:-}"
      shift 2
      ;;
    --require-events)
      REQUIRE_EVENTS="${2:-}"
      shift 2
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

[[ "${WINDOW}" =~ ^[0-9]+$ ]] || { echo "ERROR: window must be a positive integer" >&2; exit 2; }
(( WINDOW > 0 )) || { echo "ERROR: window must be > 0" >&2; exit 2; }
[[ "${MAX_RECENT_FAILED}" =~ ^[0-9]+$ ]] || { echo "ERROR: max recent failed must be a non-negative integer" >&2; exit 2; }
[[ "${REQUIRE_EVENTS}" =~ ^[01]$ ]] || { echo "ERROR: require-events must be 0 or 1" >&2; exit 2; }

json="$("${WBABD_BIN}" api "{\"op\":\"preflight_trend\",\"window\":${WINDOW}}")"

python3 - "${json}" "${MIN_SUCCESS_RATE}" "${MAX_RECENT_FAILED}" "${REQUIRE_EVENTS}" <<'PY'
import json
import sys

doc = json.loads(sys.argv[1])
min_success_rate = float(sys.argv[2])
max_recent_failed = int(sys.argv[3])
require_events = int(sys.argv[4])

status = doc.get("status")
if status != "ok":
    print(f"ERROR: preflight_trend status is not ok: {status}", file=sys.stderr)
    raise SystemExit(2)

recent = doc.get("recent_window", {})
events_seen = int(recent.get("events_seen", 0))
recent_failed = int(recent.get("failed", 0))
success_rate = float(recent.get("success_rate_pct", 0.0))
window = int(recent.get("window", 0))

if require_events == 1 and events_seen == 0:
    print(f"ERROR: no recent preflight events observed in window={window}", file=sys.stderr)
    raise SystemExit(1)
if recent_failed > max_recent_failed:
    print(
        f"ERROR: recent preflight failed count {recent_failed} exceeds threshold {max_recent_failed} (window={window})",
        file=sys.stderr,
    )
    raise SystemExit(1)
if success_rate < min_success_rate:
    print(
        f"ERROR: recent preflight success rate {success_rate}% below threshold {min_success_rate}% (window={window})",
        file=sys.stderr,
    )
    raise SystemExit(1)

print(
    f"OK: preflight trend thresholds satisfied (window={window}, events_seen={events_seen}, failed={recent_failed}, success_rate_pct={success_rate})"
)
PY
