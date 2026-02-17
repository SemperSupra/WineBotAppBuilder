#!/usr/bin/env bash
set -euo pipefail

# Containerized Windows lint runner.
# Default policy is pull-first and no local image builds unless explicitly enabled.

PROJECT_DIR="${1:-.}"
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR_ABS="$(cd "${PROJECT_DIR}" && pwd)"

TOOLCHAIN_IMAGE="${WBAB_TOOLCHAIN_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-winbuild}"
TOOLCHAIN_TAG="${WBAB_TAG:-v0.3.1}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
TOOLCHAIN_DOCKERFILE="${WBAB_TOOLCHAIN_DOCKERFILE:-${ROOT_DIR}/tools/winbuild/Dockerfile}"
LOCAL_IMAGE="${TOOLCHAIN_IMAGE}:local"
REMOTE_IMAGE="${TOOLCHAIN_IMAGE}:${TOOLCHAIN_TAG}"

# Default lint command is wbab-lint.
LINT_CMD="${WBAB_LINT_CMD:-wbab-lint}"

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
    docker pull "${REMOTE_IMAGE}"
  fi
else
  docker pull "${REMOTE_IMAGE}"
fi

docker run --rm \
  -v "${PROJECT_DIR_ABS}:/workspace" \
  -w /workspace \
  "${IMAGE_TO_RUN}" \
  bash -lc "${LINT_CMD}"
