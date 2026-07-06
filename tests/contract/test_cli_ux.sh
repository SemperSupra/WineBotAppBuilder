#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WBAB="${ROOT_DIR}/tools/wbab"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "[contract] verifying CLI UX contracts..."

# 1. Help text output
echo "  [1] wbab --help produces output"
HELP_TEXT=$("${WBAB}" --help 2>&1 || true)
[[ -n "${HELP_TEXT}" ]] || { echo "FAIL: wbab --help produced no output" >&2; exit 1; }

# 2. Help mentions all required verbs
for verb in lint test build package sign smoke doctor plan; do
  echo "${HELP_TEXT}" | grep -qi "${verb}" || {
    echo "FAIL: wbab --help missing required verb '${verb}'" >&2
    exit 1
  }
done

# 3. No arguments shows usage info
echo "  [3] wbab without args shows usage"
NO_ARGS=$("${WBAB}" 2>&1 || true)
[[ -n "${NO_ARGS}" ]] || { echo "FAIL: wbab without args produced no output" >&2; exit 1; }

# 4. Invalid verb produces error message
echo "  [4] wbab nonexistent-verb produces error"
INVALID=$("${WBAB}" nonexistent-verb 2>&1 || true)
[[ -n "${INVALID}" ]] || { echo "FAIL: invalid verb produced no output" >&2; exit 1; }

# 5. Help text mentions version/tag info
echo "  [5] wbab --help references version"
echo "${HELP_TEXT}" | grep -qiE "v[0-9]+\.[0-9]+\.[0-9]+|version|tag" || {
  echo "FAIL: wbab --help missing version reference" >&2
}

# 6. Plan with invalid verb produces error
echo "  [6] wbab plan nonexistent fails"
PLAN_FAIL=$("${WBAB}" plan nonexistent 2>&1 || true)
[[ -n "${PLAN_FAIL}" ]] || { echo "FAIL: plan invalid verb produced no output" >&2; exit 1; }

# 7. wbab doctor on non-project directory produces output
echo "  [7] wbab doctor on non-project directory"
DOCTOR_OUT=$("${WBAB}" doctor "${TMP}" 2>&1 || true)
[[ -n "${DOCTOR_OUT}" ]] || { echo "FAIL: doctor on non-project produced no output" >&2; exit 1; }

# 8. The wbab executable has the expected shebang
echo "  [8] wbab has correct shebang"
SHEBANG=$(head -1 "${WBAB}")
echo "${SHEBANG}" | grep -qE "^#!/" || {
  echo "FAIL: wbab missing shebang" >&2
  exit 1
}

# 9. Doctor detects WinInspect-style project
echo "  [9] doctor detects WinInspect project type"
WI_TMP="$(mktemp -d)"
trap 'rm -rf "${WI_TMP}"' EXIT
touch "${WI_TMP}/CMakeLists.txt"
mkdir -p "${WI_TMP}/clients" "${WI_TMP}/daemon"
WI_DOCTOR=$("${WBAB}" doctor "${WI_TMP}" 2>&1 || true)
echo "${WI_DOCTOR}" | grep -qi "WinInspect" || {
  echo "FAIL: doctor did not detect WinInspect project type" >&2
  exit 1
}
echo "${WI_DOCTOR}" | grep -qi "CMake" || {
  echo "FAIL: doctor did not mention CMake for WinInspect project" >&2
  exit 1
}
rm -rf "${WI_TMP}"
trap 'rm -rf "${TMP}"' EXIT

echo "OK: CLI UX contracts satisfied"
