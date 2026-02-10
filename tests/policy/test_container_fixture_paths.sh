#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_runner="${ROOT_DIR}/tools/winbuild-build.sh"
package_runner="${ROOT_DIR}/tools/package-nsis.sh"
build_script="${ROOT_DIR}/tools/winbuild/build-fixture.sh"
package_script="${ROOT_DIR}/tools/packaging/package-fixture.sh"
winbuild_dockerfile="${ROOT_DIR}/tools/winbuild/Dockerfile"
packaging_dockerfile="${ROOT_DIR}/tools/packaging/Dockerfile"

[[ -x "${build_script}" ]] || { echo "Missing executable winbuild fixture script" >&2; exit 1; }
[[ -x "${package_script}" ]] || { echo "Missing executable packaging fixture script" >&2; exit 1; }
grep -q '/workspace/tools/winbuild/build-fixture.sh' "${build_runner}" || { echo "winbuild runner missing fixture script default command" >&2; exit 1; }
grep -q '/workspace/tools/packaging/package-fixture.sh' "${package_runner}" || { echo "package runner missing fixture script default command" >&2; exit 1; }

grep -q 'x86_64-w64-mingw32-gcc' "${build_script}" || { echo "winbuild fixture script missing mingw compiler invocation" >&2; exit 1; }
grep -q 'FakeApp.exe' "${build_script}" || { echo "winbuild fixture script missing FakeApp.exe output" >&2; exit 1; }
grep -q 'makensis' "${package_script}" || { echo "packaging fixture script missing makensis invocation" >&2; exit 1; }
grep -q 'FakeSetup.exe' "${package_script}" || { echo "packaging fixture script missing FakeSetup.exe output" >&2; exit 1; }

grep -q 'mingw-w64' "${winbuild_dockerfile}" || { echo "winbuild Dockerfile missing mingw-w64 dependency" >&2; exit 1; }
grep -q 'nsis' "${packaging_dockerfile}" || { echo "packaging Dockerfile missing nsis dependency" >&2; exit 1; }

echo "OK: container fixture paths policy"
