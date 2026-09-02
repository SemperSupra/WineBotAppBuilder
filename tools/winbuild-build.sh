#!/usr/bin/env bash
set -euo pipefail

# Containerized Windows build runner.
# Default policy is pull-first, no local image builds unless explicitly enabled,
# and real build execution unless fixture/custom mode is explicitly selected.
#
# Usage:
#   ./tools/winbuild-build.sh [project-dir]
#
# Optional env:
#   WBAB_TOOLCHAIN_IMAGE (default ghcr.io/sempersupra/winebotappbuilder-winbuild)
#   WBAB_TAG (default v0.3.7)
#   WBAB_ALLOW_LOCAL_BUILD (default 0)
#   WBAB_TOOLCHAIN_DOCKERFILE (default tools/winbuild/Dockerfile)
#   WBAB_BUILD_MODE (real|fixture|custom; default real)
#   WBAB_BUILD_CMD (required for custom mode; legacy override implies custom when mode is unset)

PROJECT_DIR="${1:-.}"
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR_ABS="$(cd "${PROJECT_DIR}" && pwd)"

TOOLCHAIN_IMAGE="${WBAB_TOOLCHAIN_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-winbuild}"
TOOLCHAIN_TAG="${WBAB_TAG:-v0.3.7}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
TOOLCHAIN_DOCKERFILE="${WBAB_TOOLCHAIN_DOCKERFILE:-${ROOT_DIR}/tools/winbuild/Dockerfile}"
LOCAL_IMAGE="${TOOLCHAIN_IMAGE}:local"
REMOTE_IMAGE="${TOOLCHAIN_IMAGE}:${TOOLCHAIN_TAG}"

BUILD_MODE="${WBAB_BUILD_MODE:-}"
if [[ -z "${BUILD_MODE}" ]]; then
  if [[ -n "${WBAB_BUILD_CMD:-}" ]]; then
    BUILD_MODE="custom"
  else
    BUILD_MODE="real"
  fi
fi

case "${BUILD_MODE}" in
  real)
    if [[ -n "${WBAB_BUILD_CMD:-}" ]]; then
      echo "ERROR: WBAB_BUILD_CMD requires WBAB_BUILD_MODE=custom" >&2
      exit 2
    fi
    BUILD_CMD="wbab-build"
    ;;
  fixture)
    if [[ -n "${WBAB_BUILD_CMD:-}" ]]; then
      echo "ERROR: WBAB_BUILD_CMD requires WBAB_BUILD_MODE=custom" >&2
      exit 2
    fi
    BUILD_CMD="wbab-build-fixture"
    ;;
  custom)
    if [[ -z "${WBAB_BUILD_CMD:-}" ]]; then
      echo "ERROR: WBAB_BUILD_MODE=custom requires WBAB_BUILD_CMD" >&2
      exit 2
    fi
    BUILD_CMD="${WBAB_BUILD_CMD}"
    ;;
  *)
    echo "ERROR: invalid WBAB_BUILD_MODE '${BUILD_MODE}' (expected real|fixture|custom)" >&2
    exit 2
    ;;
esac

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

echo "wbab-build: mode=${BUILD_MODE} image=${IMAGE_TO_RUN}"
docker run --rm \
  -v "${PROJECT_DIR_ABS}:/workspace" \
  -w /workspace \
  "${IMAGE_TO_RUN}" \
  bash -lc "${BUILD_CMD}"
