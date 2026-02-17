#!/usr/bin/env bash
set -euo pipefail

# Containerized Windows build runner.
# Default policy is pull-first and no local image builds unless explicitly enabled.
#
# Usage:
#   ./tools/winbuild-build.sh [project-dir]
#
# Optional env:
#   WBAB_TOOLCHAIN_IMAGE (default ghcr.io/sempersupra/winebotappbuilder-winbuild)
#   WBAB_TAG (default v0.3.4)
#   WBAB_ALLOW_LOCAL_BUILD (default 0)
#   WBAB_TOOLCHAIN_DOCKERFILE (default tools/winbuild/Dockerfile)
#   WBAB_BUILD_CMD (default: run fixture build script in tools/winbuild/)

PROJECT_DIR="${1:-.}"
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR_ABS="$(cd "${PROJECT_DIR}" && pwd)"

TOOLCHAIN_IMAGE="${WBAB_TOOLCHAIN_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-winbuild}"
TOOLCHAIN_TAG="${WBAB_TAG:-v0.3.4}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
TOOLCHAIN_DOCKERFILE="${WBAB_TOOLCHAIN_DOCKERFILE:-${ROOT_DIR}/tools/winbuild/Dockerfile}"
LOCAL_IMAGE="${TOOLCHAIN_IMAGE}:local"
REMOTE_IMAGE="${TOOLCHAIN_IMAGE}:${TOOLCHAIN_TAG}"

BUILD_CMD="${WBAB_BUILD_CMD:-/workspace/tools/winbuild/build-fixture.sh}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found" >&2
  exit 1
fi

IMAGE_TO_RUN="${REMOTE_IMAGE}"
if [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
  if [[ -f "${TOOLCHAIN_DOCKERFILE}" ]]; then
    docker build -t "${LOCAL_IMAGE}" -f "${TOOLCHAIN_DOCKERFILE}" "${ROOT_DIR}"
    IMAGE_TO_RUN="${LOCAL_IMAGE}"
  else
    echo "WARN: local build enabled but Dockerfile missing: ${TOOLCHAIN_DOCKERFILE}" >&2
    echo "WARN: falling back to pulled image ${REMOTE_IMAGE}" >&2
    docker pull "${REMOTE_IMAGE}"
  fi
else
  docker pull "${REMOTE_IMAGE}"
fi

mkdir -p "${PROJECT_DIR_ABS}/out"

docker run --rm \
  -v "${PROJECT_DIR_ABS}:/workspace" \
  -w /workspace \
  "${IMAGE_TO_RUN}" \
  bash -lc "${BUILD_CMD}"
