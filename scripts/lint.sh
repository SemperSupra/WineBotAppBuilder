#!/usr/bin/env bash
# Host-side wrapper for containerized linting.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LINTER_IMAGE="${WBAB_LINTER_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-linter}"
LINTER_TAG="${WBAB_TAG:-v0.3.6}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
LINTER_DOCKERFILE="${ROOT_DIR}/tools/linter/Dockerfile"

# If we are in the project root (containing agent-sandbox, etc), mount it.
# Otherwise mount the ROOT_DIR (workspace).
MOUNT_DIR="${ROOT_DIR}"

IMAGE_TO_RUN="${LINTER_IMAGE}:${LINTER_TAG}"

# Implementation of Pull-First Policy
if ! docker image inspect "${IMAGE_TO_RUN}" >/dev/null 2>&1; then
  echo "Linter image ${IMAGE_TO_RUN} not found locally. Attempting to pull..."
  if ! docker pull "${IMAGE_TO_RUN}"; then
    if [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
      echo "Pull failed. Building linter image locally..."
      docker build -t "${IMAGE_TO_RUN}" -f "${LINTER_DOCKERFILE}" "${ROOT_DIR}"
    else
      echo "ERROR: Linter image not found and WBAB_ALLOW_LOCAL_BUILD is disabled." >&2
      exit 1
    fi
  fi
elif [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
  echo "Rebuilding linter image locally..."
  docker build -t "${IMAGE_TO_RUN}" -f "${LINTER_DOCKERFILE}" "${ROOT_DIR}"
fi

echo "Running containerized lint..."
# Use relative paths for mounting to be more robust across different CI/local setups
docker run --rm \
  -v "${MOUNT_DIR}:/workspace" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -w /workspace \
  "${IMAGE_TO_RUN}" \
  /usr/local/bin/wbab-lint-internal
