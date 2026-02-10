#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
plan="${ROOT_DIR}/docs/DAEMON_API_SECURITY_PLAN.md"

[[ -f "${plan}" ]] || { echo "Missing daemon API security plan doc: ${plan}" >&2; exit 1; }

grep -q '^## Threat Model' "${plan}" || { echo "Security plan missing Threat Model section" >&2; exit 1; }
grep -q '^## Authentication (AuthN) Plan' "${plan}" || { echo "Security plan missing AuthN section" >&2; exit 1; }
grep -q '^## Authorization (AuthZ) Plan' "${plan}" || { echo "Security plan missing AuthZ section" >&2; exit 1; }
grep -q '^## Transport Hardening Plan' "${plan}" || { echo "Security plan missing transport section" >&2; exit 1; }
grep -q '^## Rollout Strategy' "${plan}" || { echo "Security plan missing rollout strategy" >&2; exit 1; }
grep -q '^## Acceptance Criteria' "${plan}" || { echo "Security plan missing acceptance criteria" >&2; exit 1; }

grep -q 'WBABD_API_TOKEN' "${plan}" || { echo "Security plan missing token config detail" >&2; exit 1; }
grep -q 'WBABD_AUTHZ_POLICY_FILE' "${plan}" || { echo "Security plan missing authz policy config detail" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE' "${plan}" || { echo "Security plan missing TLS config detail" >&2; exit 1; }

echo "OK: daemon API security plan policy"
