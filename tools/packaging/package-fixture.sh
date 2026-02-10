#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
IN_EXE="${ROOT_DIR}/out/FakeApp.exe"
OUT_DIR="${ROOT_DIR}/dist"
OUT_SETUP="${OUT_DIR}/FakeSetup.exe"
WORK_DIR="${ROOT_DIR}/.wbab/fixtures/packaging"
NSI_FILE="${WORK_DIR}/fixture.nsi"

[[ -f "${IN_EXE}" ]] || { echo "ERROR: missing input binary: ${IN_EXE}" >&2; exit 2; }
command -v makensis >/dev/null 2>&1 || {
  echo "ERROR: makensis is required for fixture packaging" >&2
  exit 2
}

mkdir -p "${OUT_DIR}" "${WORK_DIR}"

cat > "${NSI_FILE}" <<'EOF'
!include "MUI2.nsh"
Name "FakeSetup"
OutFile "dist/FakeSetup.exe"
InstallDir "$TEMP\FakeSetup"
RequestExecutionLevel user

Section "Main"
  SetOutPath "$INSTDIR"
  File "out/FakeApp.exe"
SectionEnd
EOF

makensis -V2 "${NSI_FILE}" >/dev/null
[[ -s "${OUT_SETUP}" ]] || { echo "ERROR: fixture installer missing or empty: ${OUT_SETUP}" >&2; exit 2; }

cat > "${OUT_DIR}/package-fixture.txt" <<EOF
fixture package completed
tool=makensis
input=${IN_EXE}
output=${OUT_SETUP}
EOF

echo "OK: packaging fixture built at ${OUT_SETUP}"
