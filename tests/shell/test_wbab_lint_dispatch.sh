#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Create a temporary environment to mock the runners
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/tools"
cp "${ROOT_DIR}/tools/wbab" "${TMP_DIR}/tools/wbab"
chmod +x "${TMP_DIR}/tools/wbab"

# Create a mock for the lint runner
cat > "${TMP_DIR}/tools/winbuild-lint.sh" <<'EOF'
#!/usr/bin/env bash
echo "MOCK LINT RUNNER CALLED with args: $@"
EOF
chmod +x "${TMP_DIR}/tools/winbuild-lint.sh"

# We need to make sure wbab can find its core if needed, 
# but for lint/test dispatch it only needs the runner scripts.

mkdir -p "${TMP_DIR}/project"

out="$("${TMP_DIR}/tools/wbab" lint "${TMP_DIR}/project")"
echo "${out}" | grep -q "MOCK LINT RUNNER CALLED with args: ${TMP_DIR}/project" || { 
  echo "Dispatch to lint runner failed" >&2
  echo "Output was: ${out}"
  exit 1 
}

echo "OK: wbab lint dispatch"
