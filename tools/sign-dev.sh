#!/usr/bin/env bash
set -euo pipefail

# Containerized signing runner (dev/test path).
# Default policy is pull-first and no local image builds unless explicitly enabled.
#
# Usage:
#   ./tools/sign-dev.sh [project-dir]
#
# Optional env:
#   WBAB_SIGNER_IMAGE (default ghcr.io/sempersupra/winebotappbuilder-signer)
#   WBAB_TAG (default v0.3.4)
#   WBAB_ALLOW_LOCAL_BUILD (default 0)
#   WBAB_SIGNER_DOCKERFILE (default tools/signing/Dockerfile)
#   WBAB_SIGN_CMD (default creates a fixture output in dist/)
#   WBAB_SIGN_USE_DEV_CERT (default 0): use dev cert + osslsigncode path
#   WBAB_SIGN_AUTOGEN_DEV_CERT (default 1 when WBAB_SIGN_USE_DEV_CERT=1): auto-init dev cert
#   WBAB_DEV_CERT_DIR (default agent-privileged/signing/dev): cert material dir
#   WBAB_SIGN_INPUT (default dist/FakeSetup.exe): sign input for dev-cert mode
#   WBAB_SIGN_OUTPUT (default dist/FakeSetup-signed.exe): sign output for dev-cert mode

PROJECT_DIR="${1:-.}"
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR_ABS="$(cd "${PROJECT_DIR}" && pwd)"
DEV_CERT_SCRIPT="${ROOT_DIR}/scripts/signing/dev-cert.sh"

SIGNER_IMAGE="${WBAB_SIGNER_IMAGE:-ghcr.io/sempersupra/winebotappbuilder-signer}"
SIGNER_TAG="${WBAB_TAG:-v0.3.4}"
ALLOW_LOCAL_BUILD="${WBAB_ALLOW_LOCAL_BUILD:-0}"
SIGNER_DOCKERFILE="${WBAB_SIGNER_DOCKERFILE:-${ROOT_DIR}/tools/signing/Dockerfile}"
LOCAL_IMAGE="${SIGNER_IMAGE}:local"
REMOTE_IMAGE="${SIGNER_IMAGE}:${SIGNER_TAG}"

SIGN_CMD="${WBAB_SIGN_CMD:-if [[ ! -f dist/FakeSetup.exe ]]; then echo 'missing dist/FakeSetup.exe' >&2; exit 2; fi; mkdir -p dist && cp -f dist/FakeSetup.exe dist/FakeSetup-signed.exe && echo 'fixture sign completed' > dist/sign-fixture.txt}"
SIGN_USE_DEV_CERT="${WBAB_SIGN_USE_DEV_CERT:-0}"
SIGN_AUTOGEN_DEV_CERT="${WBAB_SIGN_AUTOGEN_DEV_CERT:-1}"
DEV_CERT_DIR="${WBAB_DEV_CERT_DIR:-${ROOT_DIR}/agent-privileged/signing/dev}"
SIGN_INPUT="${WBAB_SIGN_INPUT:-dist/FakeSetup.exe}"
SIGN_OUTPUT="${WBAB_SIGN_OUTPUT:-dist/FakeSetup-signed.exe}"

if [[ "${SIGN_USE_DEV_CERT}" == "1" && -z "${WBAB_SIGN_CMD:-}" ]]; then
  if [[ "${SIGN_AUTOGEN_DEV_CERT}" == "1" ]]; then
    if [[ ! -x "${DEV_CERT_SCRIPT}" ]]; then
      echo "ERROR: dev cert script not found/executable: ${DEV_CERT_SCRIPT}" >&2
      exit 2
    fi
    if [[ ! -f "${DEV_CERT_DIR}/dev.pfx" || ! -f "${DEV_CERT_DIR}/dev.pfx.pass" ]]; then
      WBAB_DEV_CERT_DIR="${DEV_CERT_DIR}" "${DEV_CERT_SCRIPT}" init
    fi
  fi

  SIGN_CMD="if [[ ! -f ${SIGN_INPUT} ]]; then echo 'missing ${SIGN_INPUT}' >&2; exit 2; fi; if [[ ! -f ${DEV_CERT_DIR}/dev.pfx || ! -f ${DEV_CERT_DIR}/dev.pfx.pass ]]; then echo 'missing dev cert material in ${DEV_CERT_DIR}' >&2; exit 2; fi; if ! command -v osslsigncode >/dev/null 2>&1; then echo 'osslsigncode not found in signer image' >&2; exit 3; fi; mkdir -p \"\$(dirname ${SIGN_OUTPUT})\"; osslsigncode sign -pkcs12 ${DEV_CERT_DIR}/dev.pfx -readpass ${DEV_CERT_DIR}/dev.pfx.pass -h sha256 -in ${SIGN_INPUT} -out ${SIGN_OUTPUT}; echo 'dev cert sign completed' > dist/sign-fixture.txt"
fi

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

docker run --rm \
  -v "${PROJECT_DIR_ABS}:/workspace" \
  -w /workspace \
  "${IMAGE_TO_RUN}" \
  bash -lc "${SIGN_CMD}"
