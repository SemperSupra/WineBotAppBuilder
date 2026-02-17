#!/usr/bin/env bash
set -euo pipefail

# Containerized packaging runner (NSIS-first).
# Default policy is pull-first and no local image builds unless explicitly enabled.
#
# Usage:
#   ./tools/package-nsis.sh [project-dir]
#
# Optional env:
#   WBAB_PACKAGER_IMAGE (default ghcr.io/sempersupra/winebotappbuilder-packager)
#   WBAB_TAG (default v0.3.2)
#   WBAB_ALLOW_LOCAL_BUILD (default 0)
#   WBAB_PACKAGER_DOCKERFILE (default tools/packaging/Dockerfile)
#   WBAB_PACKAGE_CMD (default runs fixture packaging script in tools/packaging/)

PROJECT_DIR="${1:-.}"
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR_ABS="$(cd "${PROJECT_DIR}" && pwd)"

PACKAGER_IMAGE="${WBAB_PACKAGER_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-packager}"
PACKAGER_TAG="${WBAB_TAG:-v0.3.2}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
PACKAGER_DOCKERFILE="${WBAB_PACKAGER_DOCKERFILE:-${ROOT_DIR}/tools/packaging/Dockerfile}"
LOCAL_IMAGE="${PACKAGER_IMAGE}:local"
REMOTE_IMAGE="${PACKAGER_IMAGE}:${PACKAGER_TAG}"

PACKAGE_CMD="${WBAB_PACKAGE_CMD:-/workspace/tools/packaging/package-fixture.sh}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found" >&2
  exit 1
fi

IMAGE_TO_RUN="${REMOTE_IMAGE}"
if [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
  if [[ -f "${PACKAGER_DOCKERFILE}" ]]; then
    docker build -t "${LOCAL_IMAGE}" -f "${PACKAGER_DOCKERFILE}" "${ROOT_DIR}"
    IMAGE_TO_RUN="${LOCAL_IMAGE}"
  else
    echo "WARN: local build enabled but Dockerfile missing: ${PACKAGER_DOCKERFILE}" >&2
    echo "WARN: falling back to pulled image ${REMOTE_IMAGE}" >&2
    docker pull "${REMOTE_IMAGE}"
  fi
else
  docker pull "${REMOTE_IMAGE}"
fi

mkdir -p "${PROJECT_DIR_ABS}/dist"

docker run --rm \
  -v "${PROJECT_DIR_ABS}:/workspace" \
  -w /workspace \
  "${IMAGE_TO_RUN}" \
  bash -lc "${PACKAGE_CMD}"
