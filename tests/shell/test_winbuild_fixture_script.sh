#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/winbuild" "${TMP}/mockbin"
cp "${ROOT_DIR}/tools/winbuild/build-fixture.sh" "${TMP}/tools/winbuild/build-fixture.sh"
chmod +x "${TMP}/tools/winbuild/build-fixture.sh"

cat > "${TMP}/mockbin/x86_64-w64-mingw32-gcc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "${out}" ]] || exit 2
mkdir -p "$(dirname "${out}")"
echo "PE32 fixture" > "${out}"
EOF
chmod +x "${TMP}/mockbin/x86_64-w64-mingw32-gcc"

(
  cd "${TMP}"
  PATH="${TMP}/mockbin:${PATH}" ./tools/winbuild/build-fixture.sh >/dev/null
)

[[ -s "${TMP}/out/FakeApp.exe" ]] || { echo "Expected fixture build output FakeApp.exe" >&2; exit 1; }
[[ -f "${TMP}/out/build-fixture.txt" ]] || { echo "Expected build fixture marker" >&2; exit 1; }
grep -q 'compiler=x86_64-w64-mingw32-gcc' "${TMP}/out/build-fixture.txt" || {
  echo "Expected compiler marker in build fixture output" >&2
  exit 1
}

echo "OK: winbuild fixture script"
