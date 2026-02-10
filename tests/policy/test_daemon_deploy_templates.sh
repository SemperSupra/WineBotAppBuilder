#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
sysenv="${ROOT_DIR}/deploy/daemon/wbabd.systemd.env.example"
ctrenv="${ROOT_DIR}/deploy/daemon/wbabd.container.env.example"
policy="${ROOT_DIR}/deploy/daemon/authz-policy.example.json"
doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

[[ -f "${sysenv}" ]] || { echo "Missing systemd env template: ${sysenv}" >&2; exit 1; }
[[ -f "${ctrenv}" ]] || { echo "Missing container env template: ${ctrenv}" >&2; exit 1; }
[[ -f "${policy}" ]] || { echo "Missing authz policy template: ${policy}" >&2; exit 1; }

grep -q 'WBABD_AUTH_MODE=token' "${sysenv}" || { echo "Systemd env template missing auth mode token default" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE=' "${sysenv}" || { echo "Systemd env template missing TLS cert mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_KEY_FILE=' "${sysenv}" || { echo "Systemd env template missing TLS key mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_CLIENT_CA_FILE=' "${sysenv}" || { echo "Systemd env template missing mTLS CA mapping" >&2; exit 1; }
grep -q 'WBABD_AUTHZ_POLICY_FILE=' "${sysenv}" || { echo "Systemd env template missing authz policy mapping" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_AUDIT_WINDOW=' "${sysenv}" || { echo "Systemd env template missing preflight audit window mapping" >&2; exit 1; }

grep -q 'WBABD_AUTH_MODE=token' "${ctrenv}" || { echo "Container env template missing auth mode token default" >&2; exit 1; }
grep -q 'WBABD_API_TOKEN_FILE=' "${ctrenv}" || { echo "Container env template missing token file mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE=' "${ctrenv}" || { echo "Container env template missing TLS cert mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_KEY_FILE=' "${ctrenv}" || { echo "Container env template missing TLS key mapping" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_AUDIT_WINDOW=' "${ctrenv}" || { echo "Container env template missing preflight audit window mapping" >&2; exit 1; }

grep -q '"principals"' "${policy}" || { echo "Authz policy template missing principals object" >&2; exit 1; }
grep -q '"wbabd-systemd"' "${policy}" || { echo "Authz policy template missing wbabd-systemd principal" >&2; exit 1; }
grep -q '"wbabd-container"' "${policy}" || { echo "Authz policy template missing wbabd-container principal" >&2; exit 1; }
grep -q '"verbs"' "${policy}" || { echo "Authz policy template missing verbs entries" >&2; exit 1; }
grep -q '"preflight_status"' "${policy}" || { echo "Authz policy template missing preflight_status permission example" >&2; exit 1; }
grep -q '"preflight_trend"' "${policy}" || { echo "Authz policy template missing preflight_trend permission example" >&2; exit 1; }

grep -q 'deploy/daemon/wbabd.systemd.env.example' "${doc}" || { echo "Deploy profile missing systemd template reference" >&2; exit 1; }
grep -q 'deploy/daemon/wbabd.container.env.example' "${doc}" || { echo "Deploy profile missing container template reference" >&2; exit 1; }
grep -q 'deploy/daemon/authz-policy.example.json' "${doc}" || { echo "Deploy profile missing authz template reference" >&2; exit 1; }
grep -q 'WBABD_PREFLIGHT_AUDIT_WINDOW' "${doc}" || { echo "Deploy profile missing preflight audit window reference" >&2; exit 1; }

echo "OK: daemon deploy templates policy"
