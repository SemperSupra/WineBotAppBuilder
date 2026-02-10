#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="${ROOT_DIR}/.github/workflows/policy-preflight-trend-gate-optin.yml"

[[ -f "${wf}" ]] || { echo "Missing opt-in preflight trend gate workflow: ${wf}" >&2; exit 1; }
grep -q 'workflow_dispatch:' "${wf}" || { echo "Opt-in trend gate workflow must be workflow_dispatch only" >&2; exit 1; }
grep -q 'inputs:' "${wf}" || { echo "Opt-in trend gate workflow must expose optional inputs" >&2; exit 1; }
grep -q 'trend_window:' "${wf}" || { echo "Workflow missing trend_window input" >&2; exit 1; }
grep -q 'min_success_rate_pct:' "${wf}" || { echo "Workflow missing min_success_rate_pct input" >&2; exit 1; }
grep -q 'max_recent_failed:' "${wf}" || { echo "Workflow missing max_recent_failed input" >&2; exit 1; }
grep -q 'require_events:' "${wf}" || { echo "Workflow missing require_events input" >&2; exit 1; }
grep -q 'WBABD_POLICY_PREFLIGHT_TREND_GATE: "1"' "${wf}" || { echo "Workflow must enable WBABD_POLICY_PREFLIGHT_TREND_GATE=1" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_TREND_WINDOW:' "${wf}" || { echo "Workflow missing WBABD_PREFLIGHT_TREND_WINDOW env wiring" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT:' "${wf}" || { echo "Workflow missing WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT env wiring" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED:' "${wf}" || { echo "Workflow missing WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED env wiring" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS:' "${wf}" || { echo "Workflow missing WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS env wiring" >&2; exit 1; }
grep -q 'tests/policy/run.sh' "${wf}" || { echo "Workflow must execute policy test suite" >&2; exit 1; }
grep -q 'Capture preflight trend diagnostics snapshot' "${wf}" || { echo "Workflow missing preflight trend diagnostics snapshot step" >&2; exit 1; }
grep -q 'tools/wbabd api "{\\"op\\":\\"preflight_trend\\"' "${wf}" || { echo "Workflow missing preflight_trend snapshot command" >&2; exit 1; }
grep -q 'actions/upload-artifact@v4' "${wf}" || { echo "Workflow missing artifact upload action" >&2; exit 1; }
grep -q 'policy-preflight-trend-gate-diagnostics' "${wf}" || { echo "Workflow missing expected diagnostics artifact name" >&2; exit 1; }
grep -q 'artifacts/policy-preflight-trend-gate/preflight-trend.json' "${wf}" || { echo "Workflow missing diagnostics artifact path" >&2; exit 1; }

echo "OK: preflight trend gate opt-in workflow policy"
