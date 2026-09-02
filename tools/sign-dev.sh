#!/usr/bin/env bash
set -euo pipefail

# Containerized signing runner (dev/test path).
# Default policy is pull-first, no local image builds unless explicitly enabled,
# and actual dev-certificate signing unless fixture/custom mode is explicit.
#
# Usage:
#   ./tools/sign-dev.sh [project-dir]
#
# Optional env:
#   WBAB_SIGNER_IMAGE (default ghcr.io/sempersupra/winebotappbuilder-signer)
#   WBAB_TAG (default v0.3.7)
#   WBAB_ALLOW_LOCAL_BUILD (default 0)
#   WBAB_SIGNER_DOCKERFILE (default tools/signing/Dockerfile)
#   WBAB_SIGN_MODE (dev-cert|fixture|custom; default dev-cert)
#   WBAB_SIGN_CMD (required for custom mode; legacy override implies custom when mode is unset)
#   WBAB_SIGN_USE_DEV_CERT (legacy 0|1 mode selector; conflicts fail closed)
#   WBAB_SIGN_AUTOGEN_DEV_CERT (default 1 in dev-cert mode)
#   WBAB_DEV_CERT_DIR (default ../agent-privileged/signing/dev, outside this repo)
#   WBAB_DOCKER_USER (default invoking uid:gid for dev-cert mode)
#   WBAB_SIGN_INPUT (default dist/FakeSetup.exe)
#   WBAB_SIGN_OUTPUT (default dist/FakeSetup-signed.exe)

PROJECT_DIR="${1:-.}"
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR_ABS="$(cd "${PROJECT_DIR}" && pwd)"
DEV_CERT_SCRIPT="${ROOT_DIR}/scripts/signing/dev-cert.sh"

SIGNER_IMAGE="${WBAB_SIGNER_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-signer}"
SIGNER_TAG="${WBAB_TAG:-v0.3.7}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
SIGNER_DOCKERFILE="${WBAB_SIGNER_DOCKERFILE:-${ROOT_DIR}/tools/signing/Dockerfile}"
LOCAL_IMAGE="${SIGNER_IMAGE}:local"
REMOTE_IMAGE="${SIGNER_IMAGE}:${SIGNER_TAG}"

SIGN_MODE="${WBAB_SIGN_MODE:-}"
SIGN_CMD="${WBAB_SIGN_CMD:-}"
SIGN_AUTOGEN_DEV_CERT="${WBAB_SIGN_AUTOGEN_DEV_CERT:-1}"
DEV_CERT_DIR="${WBAB_DEV_CERT_DIR:-${ROOT_DIR}/../agent-privileged/signing/dev}"
SIGN_INPUT="${WBAB_SIGN_INPUT:-dist/FakeSetup.exe}"
SIGN_OUTPUT="${WBAB_SIGN_OUTPUT:-dist/FakeSetup-signed.exe}"

if [[ -z "${SIGN_MODE}" ]]; then
  if [[ -n "${SIGN_CMD}" ]]; then
    SIGN_MODE="custom"
  elif [[ -n "${WBAB_SIGN_USE_DEV_CERT+x}" ]]; then
    case "${WBAB_SIGN_USE_DEV_CERT}" in
      1) SIGN_MODE="dev-cert" ;;
      0) SIGN_MODE="fixture" ;;
      *) echo "ERROR: WBAB_SIGN_USE_DEV_CERT must be 0 or 1" >&2; exit 2 ;;
    esac
  else
    SIGN_MODE="dev-cert"
  fi
fi

if [[ -n "${WBAB_SIGN_USE_DEV_CERT+x}" ]]; then
  case "${WBAB_SIGN_USE_DEV_CERT}" in
    1) LEGACY_SIGN_MODE="dev-cert" ;;
    0) LEGACY_SIGN_MODE="fixture" ;;
    *) echo "ERROR: WBAB_SIGN_USE_DEV_CERT must be 0 or 1" >&2; exit 2 ;;
  esac
  if [[ "${SIGN_MODE}" != "${LEGACY_SIGN_MODE}" ]]; then
    echo "ERROR: WBAB_SIGN_USE_DEV_CERT conflicts with WBAB_SIGN_MODE=${SIGN_MODE}" >&2
    exit 2
  fi
fi

case "${SIGN_MODE}" in
  dev-cert|fixture)
    if [[ -n "${SIGN_CMD}" ]]; then
      echo "ERROR: WBAB_SIGN_CMD requires WBAB_SIGN_MODE=custom" >&2
      exit 2
    fi
    ;;
  custom)
    if [[ -z "${SIGN_CMD}" ]]; then
      echo "ERROR: WBAB_SIGN_MODE=custom requires WBAB_SIGN_CMD" >&2
      exit 2
    fi
    if [[ -n "${WBAB_SIGN_USE_DEV_CERT+x}" ]]; then
      echo "ERROR: legacy WBAB_SIGN_USE_DEV_CERT cannot be combined with custom signing" >&2
      exit 2
    fi
    ;;
  *)
    echo "ERROR: invalid WBAB_SIGN_MODE '${SIGN_MODE}' (expected dev-cert|fixture|custom)" >&2
    exit 2
    ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found" >&2
  exit 1
fi

IMAGE_TO_RUN="${REMOTE_IMAGE}"
if [[ "${ALLOW_LOCAL_BUILD}" == "1" ]]; then
  if [[ -f "${SIGNER_DOCKERFILE}" ]]; then
    docker build -t "${LOCAL_IMAGE}" -f "${SIGNER_DOCKERFILE}" "${ROOT_DIR}"
    IMAGE_TO_RUN="${LOCAL_IMAGE}"
  else
    echo "WARN: local build enabled but Dockerfile missing: ${SIGNER_DOCKERFILE}" >&2
    echo "WARN: falling back to pulled image ${REMOTE_IMAGE}" >&2
    docker pull "${REMOTE_IMAGE}"
  fi
else
  docker pull "${REMOTE_IMAGE}"
fi

mkdir -p "${PROJECT_DIR_ABS}/dist"

echo "wbab-sign: mode=${SIGN_MODE} image=${IMAGE_TO_RUN}"
case "${SIGN_MODE}" in
  dev-cert)
    if [[ "${SIGN_AUTOGEN_DEV_CERT}" == "1" ]]; then
      if [[ ! -x "${DEV_CERT_SCRIPT}" ]]; then
        echo "ERROR: dev cert script not found/executable: ${DEV_CERT_SCRIPT}" >&2
        exit 2
      fi
      if [[ ! -f "${DEV_CERT_DIR}/dev.pfx" || ! -f "${DEV_CERT_DIR}/dev.pfx.pass" ]]; then
        WBAB_DEV_CERT_DIR="${DEV_CERT_DIR}" "${DEV_CERT_SCRIPT}" init
      fi
    fi

    if [[ ! -f "${DEV_CERT_DIR}/dev.pfx" || ! -f "${DEV_CERT_DIR}/dev.pfx.pass" ]]; then
      echo "ERROR: dev cert material missing in ${DEV_CERT_DIR}" >&2
      exit 2
    fi

    if [[ -z "${WBAB_DOCKER_USER:-}" ]]; then
      command -v id >/dev/null 2>&1 || { echo "ERROR: id command required to map host signing permissions" >&2; exit 2; }
      DOCKER_USER="$(id -u):$(id -g)"
    else
      DOCKER_USER="${WBAB_DOCKER_USER}"
    fi

    docker run --rm \
      --user "${DOCKER_USER}" \
      -v "${PROJECT_DIR_ABS}:/workspace" \
      -v "${DEV_CERT_DIR}:/run/wbab-signing:ro" \
      -w /workspace \
      -e WBAB_DEV_CERT_DIR=/run/wbab-signing \
      -e "WBAB_SIGN_INPUT=${SIGN_INPUT}" \
      -e "WBAB_SIGN_OUTPUT=${SIGN_OUTPUT}" \
      "${IMAGE_TO_RUN}" \
      wbab-sign
    ;;
  fixture)
    docker run --rm \
      -v "${PROJECT_DIR_ABS}:/workspace" \
      -w /workspace \
      -e "WBAB_SIGN_INPUT=${SIGN_INPUT}" \
      -e "WBAB_SIGN_OUTPUT=${SIGN_OUTPUT}" \
      "${IMAGE_TO_RUN}" \
      wbab-sign-fixture
    ;;
  custom)
    docker run --rm \
      -v "${PROJECT_DIR_ABS}:/workspace" \
      -w /workspace \
      "${IMAGE_TO_RUN}" \
      bash -lc "${SIGN_CMD}"
    ;;
esac
