#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_REAL="${ROOT_DIR}/tools/winbuild/build-real.sh"

echo "[contract] verifying build-real.sh output structure..."

[[ -f "${BUILD_REAL}" ]] || { echo "FAIL: build-real.sh not found" >&2; exit 1; }

# 1. Must create out/ directory
grep -q 'mkdir -p "../out"' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must create out/ directory" >&2
  exit 1
}

# 2. Must clean out/ before building (prevents stale artifact pollution)
grep -q 'rm -rf "../out"' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must clean out/ before building" >&2
  exit 1
}

# 3. Must copy .exe files to out/
grep -q '\*\.exe.*\.\.\/out\/' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must copy .exe files to out/" >&2
  exit 1
}

# 4. Must copy .dll files to out/
grep -q '\*\.dll.*\.\.\/out\/' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must copy .dll files to out/" >&2
  exit 1
}

# 5. Must handle CMakeLists.txt (CMake path)
grep -q 'CMakeLists.txt' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must support CMake builds" >&2
  exit 1
}

# 6. Must handle Makefile (alternative path)
grep -q 'Makefile' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must support Makefile builds" >&2
  exit 1
}

# 7. Must fail with clear error when no build system found
grep -q 'exit 1' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must exit with error code on failure" >&2
  exit 1
}

# 8. Must set cross-compilation variables for Makefile path
grep -q 'CC=x86_64-w64-mingw32-gcc' "${BUILD_REAL}" || {
  echo "FAIL: build-real.sh must set cross-compiler CC for Makefile path" >&2
  exit 1
}

echo "OK: build-real.sh output structure contract satisfied"
