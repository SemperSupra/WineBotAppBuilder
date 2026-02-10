#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

[[ -f "${doc}" ]] || { echo "Missing daemon deploy profile doc: ${doc}" >&2; exit 1; }

grep -q 'scripts/security/daemon-pki.sh init' "${doc}" || { echo "Deploy profile missing PKI init mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_CERT_FILE' "${doc}" || { echo "Deploy profile missing TLS cert env mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_KEY_FILE' "${doc}" || { echo "Deploy profile missing TLS key env mapping" >&2; exit 1; }
grep -q 'WBABD_TLS_CLIENT_CA_FILE' "${doc}" || { echo "Deploy profile missing mTLS client CA env mapping" >&2; exit 1; }
grep -q 'WBABD_API_TOKEN_FILE' "${doc}" || { echo "Deploy profile missing token file mapping" >&2; exit 1; }
grep -q 'tools/wbabd serve' "${doc}" || { echo "Deploy profile missing serve command example" >&2; exit 1; }
grep -q 'scripts/security/daemon-pki.sh rotate' "${doc}" || { echo "Deploy profile missing rotate guidance" >&2; exit 1; }
# shellcheck disable=SC2016
grep -q '## 6. `systemd` Runtime Example' "${doc}" || { echo "Deploy profile missing systemd runtime section" >&2; exit 1; }
grep -q 'ExecStart=/opt/wbab/tools/wbabd serve' "${doc}" || { echo "Deploy profile missing systemd ExecStart mapping" >&2; exit 1; }
grep -q 'systemctl enable --now wbabd.service' "${doc}" || { echo "Deploy profile missing systemd enable/start guidance" >&2; exit 1; }
grep -q '## 7. Containerized Private-Network Example' "${doc}" || { echo "Deploy profile missing container runtime section" >&2; exit 1; }
grep -q 'docker run --rm' "${doc}" || { echo "Deploy profile missing docker run example" >&2; exit 1; }
grep -q '127.0.0.1:8787:8787' "${doc}" || { echo "Deploy profile missing private loopback port binding guidance" >&2; exit 1; }
grep -q '## 8. Zero-Downtime Cert/Token Rotation Playbook' "${doc}" || { echo "Deploy profile missing zero-downtime rotation section" >&2; exit 1; }
grep -q 'WBABD_PKI_DIR=.wbab/daemon-pki-next' "${doc}" || { echo "Deploy profile missing staged PKI rotation step" >&2; exit 1; }
grep -q 'systemctl restart wbabd.service' "${doc}" || { echo "Deploy profile missing systemd rotation restart step" >&2; exit 1; }
grep -q 'wbabd-next' "${doc}" || { echo "Deploy profile missing container blue/green step" >&2; exit 1; }
grep -q 'Rollback' "${doc}" || { echo "Deploy profile missing rollback section" >&2; exit 1; }
grep -q '## 11. Operator Runbook Checks' "${doc}" || { echo "Deploy profile missing operator runbook checks section" >&2; exit 1; }
grep -q "tools/wbabd api '{\"op\":\"preflight_trend\"" "${doc}" || { echo "Deploy profile missing preflight trend runbook check" >&2; exit 1; }
grep -q '/preflight-trend?window=' "${doc}" || { echo "Deploy profile missing HTTP preflight trend runbook check" >&2; exit 1; }
grep -q 'preflight_status' "${doc}" || { echo "Deploy profile missing authz example for preflight_status" >&2; exit 1; }
grep -q 'preflight_trend' "${doc}" || { echo "Deploy profile missing authz example for preflight_trend" >&2; exit 1; }
grep -q 'X-WBABD-Principal: readonly-ops' "${doc}" || { echo "Deploy profile missing diagnostics principal HTTP example" >&2; exit 1; }
# shellcheck disable=SC2016
grep -q '### 11.5 `systemd` Health Integration' "${doc}" || { echo "Deploy profile missing systemd health integration example" >&2; exit 1; }
grep -q 'wbabd-trend-health.timer' "${doc}" || { echo "Deploy profile missing systemd trend health timer example" >&2; exit 1; }
grep -q '### 11.6 Container Healthcheck Integration' "${doc}" || { echo "Deploy profile missing container healthcheck integration example" >&2; exit 1; }
grep -q -- '--health-cmd' "${doc}" || { echo "Deploy profile missing container healthcheck command example" >&2; exit 1; }
grep -q '### 11.4 Threshold Profile Quick Reference' "${doc}" || { echo "Deploy profile missing threshold profile quick reference section" >&2; exit 1; }
# shellcheck disable=SC2016
grep -q '| `strict` |' "${doc}" || { echo "Deploy profile missing strict threshold profile row" >&2; exit 1; }
# shellcheck disable=SC2016
grep -q '| `balanced` |' "${doc}" || { echo "Deploy profile missing balanced threshold profile row" >&2; exit 1; }
# shellcheck disable=SC2016
grep -q '| `permissive` |' "${doc}" || { echo "Deploy profile missing permissive threshold profile row" >&2; exit 1; }
grep -q '### 11.7 Threshold Gate Troubleshooting' "${doc}" || { echo "Deploy profile missing threshold gate troubleshooting appendix" >&2; exit 1; }
grep -q 'no recent preflight events observed' "${doc}" || { echo "Deploy profile troubleshooting missing no-events failure guidance" >&2; exit 1; }
grep -q 'recent preflight failed count' "${doc}" || { echo "Deploy profile troubleshooting missing failed-count guidance" >&2; exit 1; }
grep -q 'recent preflight success rate' "${doc}" || { echo "Deploy profile troubleshooting missing success-rate guidance" >&2; exit 1; }

echo "OK: daemon deploy profile doc policy"
