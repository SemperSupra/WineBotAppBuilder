#!/usr/bin/env bash
set -euo pipefail

# Real build runner for standard projects.
# Detects CMakeLists.txt or Makefile and attempts a cross-compile build.

if [[ -f "CMakeLists.txt" ]]; then
  echo "wbab-build: Found CMakeLists.txt, building with CMake..."
  mkdir -p build
  cd build
  # Configure for x86_64-w64-mingw32 cross-compilation
  # Using -S and -B to be explicit about source/build dirs
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
  
  # Copy artifacts to out/ if they exist (heuristic)
  if [[ -d "../out" ]]; then
    echo "wbab-build: Copying .exe and .dll files to out/..."
    find . -name "*.exe" -exec cp {} "../out/" \;
    find . -name "*.dll" -exec cp {} "../out/" \;
  fi

elif [[ -f "Makefile" ]]; then
  echo "wbab-build: Found Makefile, building with Make..."
  # Assume the Makefile handles cross-compilation variables or expects CC/CXX to be set
  export CC=x86_64-w64-mingw32-gcc
  export CXX=x86_64-w64-mingw32-g++
  export WINDRES=x86_64-w64-mingw32-windres
  make
else
  echo "wbab-build: No CMakeLists.txt or Makefile found in $(pwd)"
  exit 1
fi