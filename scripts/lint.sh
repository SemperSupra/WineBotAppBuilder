#!/usr/bin/env bash
# Host-side wrapper for containerized linting.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "${ROOT_DIR}/.." && pwd)"

LINTER_IMAGE="${WBAB_LINTER_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-linter}"
LINTER_TAG="${WBAB_TAG:-v0.2.0}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
LINTER_DOCKERFILE="${ROOT_DIR}/tools/linter/Dockerfile"

# If we are in the project root (containing agent-sandbox, etc), mount it.
# Otherwise mount the ROOT_DIR (workspace).
MOUNT_DIR="${PROJECT_ROOT}"

IMAGE_TO_RUN="${LINTER_IMAGE}:${LINTER_TAG}"

if [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
  echo "Building linter image locally..."
  docker build -t "${LINTER_IMAGE}:local" -f "${LINTER_DOCKERFILE}" "${PROJECT_ROOT}"
  IMAGE_TO_RUN="${LINTER_IMAGE}:local"
else
  # Check if image exists locally or try to pull
  if ! docker image inspect "${IMAGE_TO_RUN}" >/dev/null 2>&1; then
    echo "Pulling linter image ${IMAGE_TO_RUN}..."
    docker pull "${IMAGE_TO_RUN}" || {
      echo "WARN: Failed to pull ${IMAGE_TO_RUN}. Falling back to local build if allowed."
      if [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
        docker build -t "${LINTER_IMAGE}:local" -f "${LINTER_DOCKERFILE}" "${PROJECT_ROOT}"
        IMAGE_TO_RUN="${LINTER_IMAGE}:local"
      else
        echo "ERROR: Image not found and local build not enabled." >&2
        exit 1
      fi
    }
  fi
fi

echo "Running containerized lint..."
docker run --rm \
  -v "${MOUNT_DIR}:/workspace" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -w /workspace/workspace \
  "${IMAGE_TO_RUN}" \
  /workspace/workspace/scripts/lint-container.sh
