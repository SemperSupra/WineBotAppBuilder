#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
OUT_DIR="${ROOT_DIR}/out"
SRC_DIR="${ROOT_DIR}/.wbab/fixtures/winbuild"
SRC_FILE="${SRC_DIR}/fake_app.c"
OUT_EXE="${OUT_DIR}/FakeApp.exe"

command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 || {
  echo "ERROR: x86_64-w64-mingw32-gcc is required for fixture build" >&2
  exit 2
}

mkdir -p "${OUT_DIR}" "${SRC_DIR}"

cat > "${SRC_FILE}" <<'EOF'
#include <windows.h>

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
  MessageBoxA(NULL, "WineBotAppBuilder fixture", "FakeApp", MB_OK);
  return 0;
}
EOF

x86_64-w64-mingw32-gcc -Os -s -o "${OUT_EXE}" "${SRC_FILE}"
[[ -s "${OUT_EXE}" ]] || { echo "ERROR: fixture output missing or empty: ${OUT_EXE}" >&2; exit 2; }

cat > "${OUT_DIR}/build-fixture.txt" <<EOF
fixture build completed
compiler=x86_64-w64-mingw32-gcc
output=${OUT_EXE}
EOF

echo "OK: winbuild fixture built at ${OUT_EXE}"
