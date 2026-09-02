#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

TEST_TIMEOUT="${WBAB_SHELL_TEST_TIMEOUT:-60s}"

run_test() {
  local test_path="$1"
  local rc=0

  echo "[shell-unit] START ${test_path} timeout=${TEST_TIMEOUT}"
  if timeout --kill-after=5s "${TEST_TIMEOUT}" bash "${ROOT_DIR}/${test_path}"; then
    echo "[shell-unit] PASS  ${test_path}"
    return 0
  else
    rc=$?
  fi

  if [[ ${rc} -eq 124 || ${rc} -eq 137 ]]; then
    echo "[shell-unit] TIMEOUT ${test_path} rc=${rc}" >&2
  else
    echo "[shell-unit] FAIL ${test_path} rc=${rc}" >&2
  fi
  return "${rc}"
}

echo "[shell-unit] running..."
export WBAB_MOCK_EXECUTOR=1
run_test tests/shell/test_pull_first.sh
run_test tests/shell/test_build_pull_first.sh
run_test tests/shell/test_build_local_opt_in.sh
run_test tests/shell/test_winbuild_fixture_script.sh
run_test tests/shell/test_package_pull_first.sh
run_test tests/shell/test_package_local_opt_in.sh
run_test tests/shell/test_packaging_fixture_script.sh
run_test tests/shell/test_publish_dockerfiles_drycheck.sh
run_test tests/shell/test_sign_pull_first.sh
run_test tests/shell/test_sign_local_opt_in.sh
run_test tests/shell/test_dev_cert_lifecycle.sh
run_test tests/shell/test_signing_pki_lifecycle.sh
run_test tests/shell/test_sign_dev_cert_mode.sh
run_test tests/shell/test_smoke_trust_dev_cert.sh
run_test tests/shell/test_e2e_real_requires_installer.sh
run_test tests/shell/test_validate_installer_artifact.sh
run_test tests/shell/test_wbabd_plan.sh
run_test tests/shell/test_wbabd_idempotent.sh
run_test tests/shell/test_wbabd_retry_resume.sh
run_test tests/shell/test_wbabd_http_api.sh
run_test tests/shell/test_wbabd_concurrency.sh
run_test tests/shell/test_wbabd_audit_log.sh
run_test tests/shell/test_wbabd_store_migration.sh
run_test tests/shell/test_wbabd_serve_auth_config.sh
run_test tests/shell/test_wbabd_http_bearer_auth.sh
run_test tests/shell/test_wbabd_authz_policy.sh
run_test tests/shell/test_wbabd_serve_tls_limits_config.sh
run_test tests/shell/test_wbabd_serve_preflight_flag.sh
run_test tests/shell/test_daemon_pki_lifecycle.sh
run_test tests/shell/test_daemon_preflight.sh
run_test tests/shell/test_daemon_preflight_status_api.sh
run_test tests/shell/test_daemon_preflight_audit_counters.sh
run_test tests/shell/test_daemon_preflight_trend_report.sh
run_test tests/shell/test_daemon_preflight_trend_api.sh
run_test tests/shell/test_daemon_preflight_trend_threshold_check.sh
run_test tests/shell/test_wbab_smoke_dispatch.sh
run_test tests/shell/test_wbab_lint_dispatch.sh
run_test tests/shell/test_wbab_test_dispatch.sh
run_test tests/shell/test_wbab_package_dispatch.sh
run_test tests/shell/test_wbab_sign_dispatch.sh
run_test tests/e2e/test_wbab_pipeline_mocked.sh
echo "[shell-unit] ok"
