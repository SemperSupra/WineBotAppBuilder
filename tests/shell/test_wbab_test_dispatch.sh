#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Create a temporary environment to mock the runners
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/tools"
cp "${ROOT_DIR}/tools/wbab" "${TMP_DIR}/tools/wbab"
chmod +x "${TMP_DIR}/tools/wbab"

# Create a mock for the test runner
cat > "${TMP_DIR}/tools/winbuild-test.sh" <<'EOF'
#!/usr/bin/env bash
echo "MOCK TEST RUNNER CALLED with args: $@"
EOF
chmod +x "${TMP_DIR}/tools/winbuild-test.sh"

mkdir -p "${TMP_DIR}/project"

out="$("${TMP_DIR}/tools/wbab" test "${TMP_DIR}/project")"
echo "${out}" | grep -q "MOCK TEST RUNNER CALLED with args: ${TMP_DIR}/project" || { 
  echo "Dispatch to test runner failed" >&2
  echo "Output was: ${out}"
  exit 1 
}

echo "OK: wbab test dispatch"
