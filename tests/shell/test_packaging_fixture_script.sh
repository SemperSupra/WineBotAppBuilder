#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tools/packaging" "${TMP}/mockbin" "${TMP}/out"
cp "${ROOT_DIR}/tools/packaging/package-fixture.sh" "${TMP}/tools/packaging/package-fixture.sh"
chmod +x "${TMP}/tools/packaging/package-fixture.sh"
echo "fake app binary" > "${TMP}/out/FakeApp.exe"

cat > "${TMP}/mockbin/makensis" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
script="${@: -1}"
out="$(sed -n 's/^OutFile "\(.*\)"/\1/p' "${script}" | head -n1)"
[[ -n "${out}" ]] || exit 2
mkdir -p "$(dirname "${out}")"
echo "NSIS fixture" > "${out}"
EOF
chmod +x "${TMP}/mockbin/makensis"

(
  cd "${TMP}"
  PATH="${TMP}/mockbin:${PATH}" ./tools/packaging/package-fixture.sh >/dev/null
)

[[ -s "${TMP}/dist/FakeSetup.exe" ]] || { echo "Expected fixture installer output FakeSetup.exe" >&2; exit 1; }
[[ -f "${TMP}/dist/package-fixture.txt" ]] || { echo "Expected package fixture marker" >&2; exit 1; }
grep -q 'tool=makensis' "${TMP}/dist/package-fixture.txt" || {
  echo "Expected makensis marker in package fixture output" >&2
  exit 1
}

echo "OK: packaging fixture script"
