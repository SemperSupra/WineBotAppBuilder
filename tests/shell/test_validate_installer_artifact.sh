#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/tests/e2e" "${TMP}/artifacts"
cp "${ROOT_DIR}/tests/e2e/validate-installer-artifact.sh" "${TMP}/tests/e2e/validate-installer-artifact.sh"
chmod +x "${TMP}/tests/e2e/validate-installer-artifact.sh"

echo "real-installer-bytes" > "${TMP}/RealInstaller.exe"

(
  cd "${TMP}"
  WBAB_SMOKE_SKIP_INSTALL=0 \
  WBAB_REAL_INSTALLER_PATH="${TMP}/RealInstaller.exe" \
  ./tests/e2e/validate-installer-artifact.sh
)

[[ -f "${TMP}/artifacts/e2e-real/installer-validation/installer.sha256" ]] || { echo "Missing installer sha256 artifact" >&2; exit 1; }
[[ -f "${TMP}/artifacts/e2e-real/installer-validation/installer.manifest.txt" ]] || { echo "Missing installer manifest artifact" >&2; exit 1; }
grep -q "name=RealInstaller.exe" "${TMP}/artifacts/e2e-real/installer-validation/installer.manifest.txt" || { echo "Manifest missing installer name" >&2; exit 1; }

echo "OK: installer artifact validation"
