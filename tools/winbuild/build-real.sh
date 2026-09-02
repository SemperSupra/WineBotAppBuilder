#!/usr/bin/env bash
set -euo pipefail

# Real build runner for standard projects.
# Detects CMakeLists.txt or Makefile and attempts a cross-compile build.

bundle_mingw_runtime() {
  local out_dir="$1"
  local dll resolved

  # Dynamically linked MinGW C++ binaries are not runnable on a clean Windows/Wine
  # environment unless their compiler runtime DLLs travel with the application.
  # Resolve the exact runtime supplied by the candidate toolchain instead of
  # hard-coding distro paths.
  for dll in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
    resolved="$(x86_64-w64-mingw32-g++ -print-file-name="${dll}")"
    if [[ -f "${resolved}" ]]; then
      cp -f "${resolved}" "${out_dir}/${dll}"
      echo "wbab-build: Bundled MinGW runtime ${dll} from ${resolved}"
    else
      echo "wbab-build: WARN: MinGW runtime ${dll} was not resolved by the toolchain" >&2
    fi
  done
}

if [[ -f "CMakeLists.txt" ]]; then
  echo "wbab-build: Found CMakeLists.txt, building with CMake..."
  mkdir -p build
  cd build
  # Configure for x86_64-w64-mingw32 cross-compilation.
  cmake -S .. -B . \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
        -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
        -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
        -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY

  cmake --build .

  # Produce a clean, self-contained runtime output directory. Project-owned DLLs
  # and MinGW runtime DLLs are copied beside the executables so both Wine tests
  # and packaged applications exercise the same deployable payload.
  rm -rf "../out"
  mkdir -p "../out"
  echo "wbab-build: Copying project .exe and .dll files to out/..."
  find . -name "*.exe" -exec cp -f {} "../out/" \;
  find . -name "*.dll" -exec cp -f {} "../out/" \;
  bundle_mingw_runtime "../out"

elif [[ -f "Makefile" ]]; then
  echo "wbab-build: Found Makefile, building with Make..."
  # Assume the Makefile handles output placement while WBAB supplies the
  # cross-compilation toolchain variables.
  export CC=x86_64-w64-mingw32-gcc
  export CXX=x86_64-w64-mingw32-g++
  export WINDRES=x86_64-w64-mingw32-windres
  make
else
  echo "wbab-build: No CMakeLists.txt or Makefile found in $(pwd)"
  exit 1
fi
