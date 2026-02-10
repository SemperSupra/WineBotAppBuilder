#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

SMOKE_SKIP_INSTALL="${WBAB_SMOKE_SKIP_INSTALL:-1}"
REAL_INSTALLER_PATH="${WBAB_REAL_INSTALLER_PATH:-}"
ARTIFACT_DIR="${WBAB_INSTALLER_VALIDATION_ARTIFACT_DIR:-artifacts/e2e-real/installer-validation}"

if [[ "${SMOKE_SKIP_INSTALL}" != "0" ]]; then
  echo "INFO: WBAB_SMOKE_SKIP_INSTALL=${SMOKE_SKIP_INSTALL}; installer artifact validation skipped"
  exit 0
fi

if [[ -z "${REAL_INSTALLER_PATH}" ]]; then
  echo "ERROR: WBAB_REAL_INSTALLER_PATH is required when WBAB_SMOKE_SKIP_INSTALL=0" >&2
  exit 2
fi

if [[ ! -f "${REAL_INSTALLER_PATH}" ]]; then
  echo "ERROR: installer artifact not found: ${REAL_INSTALLER_PATH}" >&2
  exit 2
fi

if [[ ! -s "${REAL_INSTALLER_PATH}" ]]; then
  echo "ERROR: installer artifact is empty: ${REAL_INSTALLER_PATH}" >&2
  exit 2
fi

mkdir -p "${ARTIFACT_DIR}"
cp -f "${REAL_INSTALLER_PATH}" "${ARTIFACT_DIR}/"

installer_basename="$(basename "${REAL_INSTALLER_PATH}")"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "${REAL_INSTALLER_PATH}" > "${ARTIFACT_DIR}/installer.sha256"
else
  shasum -a 256 "${REAL_INSTALLER_PATH}" > "${ARTIFACT_DIR}/installer.sha256"
fi

cat > "${ARTIFACT_DIR}/installer.manifest.txt" <<EOF
path=${REAL_INSTALLER_PATH}
name=${installer_basename}
size_bytes=$(wc -c < "${REAL_INSTALLER_PATH}" | tr -d ' ')
validated_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "OK: installer artifact validated: ${REAL_INSTALLER_PATH}"
