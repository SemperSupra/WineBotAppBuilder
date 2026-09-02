#!/usr/bin/env bash
set -Eeuo pipefail

# Candidate-source first-party product qualification.
# Evidence class: PRODUCT_QUALIFICATION only when every required phase executes
# and the deterministic postcondition is verified.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

for cmd in docker git python3 sha256sum tar; do
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "ERROR: required command missing: ${cmd}" >&2
    exit 2
  }
done

docker compose version >/dev/null 2>&1 || {
  echo "ERROR: docker compose v2 is required" >&2
  exit 2
}

if [[ ! -f tools/WineBot/compose/docker-compose.yml ]]; then
  echo "ERROR: WineBot submodule is not initialized" >&2
  echo "Run: ./scripts/bootstrap-submodule.sh" >&2
  exit 2
fi

SOURCE_SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"
SHORT_SHA="${SOURCE_SHA:0:12}"
ATTEMPT_ID="${WBAB_PQ_ATTEMPT_ID:-$(date -u +%Y%m%dT%H%M%SZ)-${SHORT_SHA}-${GITHUB_RUN_ATTEMPT:-local}}"
ARTIFACT_ROOT="${WBAB_PQ_ARTIFACT_DIR:-${ROOT_DIR}/artifacts/product-qualification/${ATTEMPT_ID}}"
EVENTS_FILE="${ARTIFACT_ROOT}/events.jsonl"
RECEIPT_FILE="${ARTIFACT_ROOT}/receipt.json"
WORK_DIR="$(mktemp -d)"
PROJECT_DIR="${WORK_DIR}/validation-app"
WINEBOT_DIR="${WORK_DIR}/WineBot"
WINEBOT_OVERRIDE="${WORK_DIR}/winebot.override.yml"
EXPECTED_VALUE="WBAB-PQ-${ATTEMPT_ID}"
OUTPUT_WIN_PATH='C:\\wbab-product-qualification.txt'

WINBUILD_IMAGE="wbab-product-qualification-winbuild:${SHORT_SHA}"
PACKAGER_IMAGE="wbab-product-qualification-packager:${SHORT_SHA}"
SIGNER_IMAGE="wbab-product-qualification-signer:${SHORT_SHA}"
WINEBOT_IMAGE="${WBAB_WINEBOT_IMAGE:-ghcr.io/mark-e-deyoung/winebot}"
WINEBOT_TAG="${WBAB_WINEBOT_TAG:-stable}"

CURRENT_PHASE="INITIALIZING"
FINAL_RESULT="PRODUCT_QUALIFICATION_FAILED"
FAILED_PHASE=""
WINBUILD_IMAGE_ID=""
PACKAGER_IMAGE_ID=""
SIGNER_IMAGE_ID=""
WINEBOT_IMAGE_ID=""

mkdir -p "${ARTIFACT_ROOT}"
: > "${EVENTS_FILE}"

emit_event() {
  local phase="$1"
  local status="$2"
  local message="${3:-}"
  python3 - "${EVENTS_FILE}" "${ATTEMPT_ID}" "${phase}" "${status}" "${message}" <<'PY'
import datetime, json, sys
path, attempt, phase, status, message = sys.argv[1:]
event = {
    "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "attempt_id": attempt,
    "phase": phase,
    "status": status,
}
if message:
    event["message"] = message
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps(event, sort_keys=True) + "\n")
PY
}

start_phase() {
  CURRENT_PHASE="$1"
  emit_event "${CURRENT_PHASE}" "STARTED" "${2:-}"
  echo "[product-qualification] ${CURRENT_PHASE}"
}

pass_phase() {
  emit_event "${CURRENT_PHASE}" "PASSED" "${1:-}"
}

sha_if_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    sha256sum "${path}" | awk '{print $1}'
  fi
}

write_receipt() {
  local unsigned="${PROJECT_DIR}/dist/ValidationSetup.exe"
  local signed="${PROJECT_DIR}/dist/ValidationSetup-signed.exe"
  local cli="${PROJECT_DIR}/out/ValidationCLI.exe"
  local extracted="${ARTIFACT_ROOT}/winebot/extracted_output.txt"
  local unsigned_sha
  local signed_sha
  local cli_sha
  local extracted_sha
  unsigned_sha="$(sha_if_file "${unsigned}")"
  signed_sha="$(sha_if_file "${signed}")"
  cli_sha="$(sha_if_file "${cli}")"
  extracted_sha="$(sha_if_file "${extracted}")"

  python3 - "${RECEIPT_FILE}" <<PY
import datetime, json
receipt = {
  "schema": "wbab.product-qualification.v1",
  "source_sha": ${SOURCE_SHA@Q},
  "attempt_id": ${ATTEMPT_ID@Q},
  "result": ${FINAL_RESULT@Q},
  "failed_phase": (${FAILED_PHASE@Q} or None),
  "evidence_class": "PRODUCT_QUALIFICATION" if ${FINAL_RESULT@Q} == "PRODUCT_QUALIFICATION_PASSED" else "UNQUALIFIED_ATTEMPT",
  "images": {
    "winbuild": {"ref": ${WINBUILD_IMAGE@Q}, "id": (${WINBUILD_IMAGE_ID@Q} or None)},
    "packager": {"ref": ${PACKAGER_IMAGE@Q}, "id": (${PACKAGER_IMAGE_ID@Q} or None)},
    "signer": {"ref": ${SIGNER_IMAGE@Q}, "id": (${SIGNER_IMAGE_ID@Q} or None)},
    "winebot": {"ref": ${WINEBOT_IMAGE@Q} + ":" + ${WINEBOT_TAG@Q}, "id": (${WINEBOT_IMAGE_ID@Q} or None)},
  },
  "artifacts": {
    "validation_cli_sha256": (${cli_sha@Q} or None),
    "installer_unsigned_sha256": (${unsigned_sha@Q} or None),
    "installer_signed_sha256": (${signed_sha@Q} or None),
    "postcondition_file_sha256": (${extracted_sha@Q} or None),
  },
  "postcondition": {
    "expected": ${EXPECTED_VALUE@Q},
    "verified": ${FINAL_RESULT@Q} == "PRODUCT_QUALIFICATION_PASSED",
  },
  "events": "events.jsonl",
  "completed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
}
with open(${RECEIPT_FILE@Q}, "w", encoding="utf-8") as f:
    json.dump(receipt, f, indent=2, sort_keys=True)
    f.write("\n")
PY
}

cleanup() {
  local rc=$?
  set +e
  if [[ ${rc} -ne 0 && -z "${FAILED_PHASE}" ]]; then
    FAILED_PHASE="${CURRENT_PHASE}"
    emit_event "${CURRENT_PHASE}" "FAILED" "command exited with rc=${rc}"
  fi

  mkdir -p "${ARTIFACT_ROOT}/candidate"
  [[ -d "${PROJECT_DIR}/out" ]] && cp -a "${PROJECT_DIR}/out" "${ARTIFACT_ROOT}/candidate/" 2>/dev/null
  [[ -d "${PROJECT_DIR}/dist" ]] && cp -a "${PROJECT_DIR}/dist" "${ARTIFACT_ROOT}/candidate/" 2>/dev/null

  write_receipt
  rm -rf "${WORK_DIR}" 2>/dev/null

  echo "[product-qualification] result=${FINAL_RESULT} receipt=${RECEIPT_FILE}"
  exit "${rc}"
}
trap cleanup EXIT

start_phase SOURCE_IDENTIFIED
printf 'source_sha=%s\nattempt_id=%s\n' "${SOURCE_SHA}" "${ATTEMPT_ID}" > "${ARTIFACT_ROOT}/identity.txt"
pass_phase

start_phase VALIDATION_WORKSET_PREPARED
cp -a "${ROOT_DIR}/samples/validation-app" "${PROJECT_DIR}"
# Candidate containers run as the image's non-root wbab user. The isolated
# temporary workset is intentionally writable by that user and is deleted on exit.
chmod -R a+rwX "${PROJECT_DIR}"
mkdir -p "${WINEBOT_DIR}"
git -C "${ROOT_DIR}/tools/WineBot" archive HEAD | tar -x -C "${WINEBOT_DIR}"
mkdir -p "${WINEBOT_DIR}/apps" "${WINEBOT_DIR}/artifacts"
pass_phase

start_phase WINBUILD_IMAGE_BUILT
docker build --pull -t "${WINBUILD_IMAGE}" -f tools/winbuild/Dockerfile . \
  2>&1 | tee "${ARTIFACT_ROOT}/winbuild-image.log"
WINBUILD_IMAGE_ID="$(docker image inspect --format '{{.Id}}' "${WINBUILD_IMAGE}")"
pass_phase "${WINBUILD_IMAGE_ID}"

start_phase BUILD_EXECUTED
docker run --rm \
  -v "${PROJECT_DIR}:/workspace" \
  -w /workspace \
  "${WINBUILD_IMAGE}" \
  wbab-build-real \
  2>&1 | tee "${ARTIFACT_ROOT}/build.log"
pass_phase

start_phase BUILD_OUTPUT_VERIFIED
for f in ValidationCore.dll ValidationCLI.exe ValidationGUI.exe ValidationTests.exe; do
  [[ -s "${PROJECT_DIR}/out/${f}" ]] || {
    echo "ERROR: missing/non-empty build output: out/${f}" >&2
    exit 10
  }
done
pass_phase

start_phase WINDOWS_UNIT_TEST_EXECUTED
docker run --rm \
  -v "${PROJECT_DIR}:/workspace" \
  -w /workspace \
  "${WINBUILD_IMAGE}" \
  wbab-test-real \
  2>&1 | tee "${ARTIFACT_ROOT}/windows-unit-test.log"
pass_phase

start_phase PACKAGER_IMAGE_BUILT
docker build --pull -t "${PACKAGER_IMAGE}" -f tools/packaging/Dockerfile . \
  2>&1 | tee "${ARTIFACT_ROOT}/packager-image.log"
PACKAGER_IMAGE_ID="$(docker image inspect --format '{{.Id}}' "${PACKAGER_IMAGE}")"
pass_phase "${PACKAGER_IMAGE_ID}"

start_phase PACKAGE_EXECUTED
docker run --rm \
  -v "${PROJECT_DIR}:/workspace" \
  -w /workspace \
  "${PACKAGER_IMAGE}" \
  wbab-package-real installer.nsi \
  2>&1 | tee "${ARTIFACT_ROOT}/package.log"
pass_phase

start_phase INSTALLER_VERIFIED
[[ -s "${PROJECT_DIR}/dist/ValidationSetup.exe" ]] || {
  echo "ERROR: real NSIS installer missing" >&2
  exit 11
}
pass_phase "sha256=$(sha_if_file "${PROJECT_DIR}/dist/ValidationSetup.exe")"

start_phase SIGNER_IMAGE_BUILT
docker build --pull -t "${SIGNER_IMAGE}" -f tools/signing/Dockerfile . \
  2>&1 | tee "${ARTIFACT_ROOT}/signer-image.log"
SIGNER_IMAGE_ID="$(docker image inspect --format '{{.Id}}' "${SIGNER_IMAGE}")"
pass_phase "${SIGNER_IMAGE_ID}"

start_phase DEV_SIGNING_MATERIAL_CREATED
mkdir -p "${PROJECT_DIR}/.pq-signing"
chmod 0777 "${PROJECT_DIR}/.pq-signing"
docker run --rm \
  -v "${PROJECT_DIR}:/workspace" \
  -w /workspace \
  "${SIGNER_IMAGE}" \
  bash -lc '
    set -euo pipefail
    pass="$(openssl rand -hex 16)"
    printf "%s\n" "${pass}" > .pq-signing/dev.pfx.pass
    openssl req -x509 -newkey rsa:2048 -sha256 -days 1 -nodes \
      -subj "/CN=WBAB Product Qualification Dev Signing/O=WBAB CI" \
      -keyout .pq-signing/dev.key.pem \
      -out .pq-signing/dev.crt.pem >/dev/null 2>&1
    openssl pkcs12 -export \
      -inkey .pq-signing/dev.key.pem \
      -in .pq-signing/dev.crt.pem \
      -passout "pass:${pass}" \
      -out .pq-signing/dev.pfx >/dev/null 2>&1
    chmod 644 .pq-signing/dev.crt.pem
  ' \
  2>&1 | tee "${ARTIFACT_ROOT}/dev-signing-material.log"
pass_phase

start_phase SIGN_EXECUTED
docker run --rm \
  -v "${PROJECT_DIR}:/workspace" \
  -w /workspace \
  -e WBAB_SIGN_USE_DEV_CERT=1 \
  -e WBAB_SIGN_INPUT=dist/ValidationSetup.exe \
  -e WBAB_SIGN_OUTPUT=dist/ValidationSetup-signed.exe \
  -e WBAB_DEV_CERT_DIR=/workspace/.pq-signing \
  "${SIGNER_IMAGE}" \
  wbab-sign-real \
  2>&1 | tee "${ARTIFACT_ROOT}/sign.log"
pass_phase

start_phase SIGNATURE_VERIFIED
[[ -s "${PROJECT_DIR}/dist/ValidationSetup-signed.exe" ]] || {
  echo "ERROR: signed installer missing" >&2
  exit 12
}
docker run --rm \
  -v "${PROJECT_DIR}:/workspace:ro" \
  -w /workspace \
  "${SIGNER_IMAGE}" \
  osslsigncode verify \
    -CAfile /workspace/.pq-signing/dev.crt.pem \
    -in /workspace/dist/ValidationSetup-signed.exe \
  2>&1 | tee "${ARTIFACT_ROOT}/signature-verify.log"
pass_phase "sha256=$(sha_if_file "${PROJECT_DIR}/dist/ValidationSetup-signed.exe")"

start_phase WINEBOT_INSTALL_RUN_POSTCONDITION
export WBAB_WINEBOT_DIR="${WINEBOT_DIR}"
export WBAB_WINEBOT_OVERRIDE="${WINEBOT_OVERRIDE}"
export WBAB_WINEBOT_IMAGE="${WINEBOT_IMAGE}"
export WBAB_WINEBOT_TAG="${WINEBOT_TAG}"
export WBAB_WINEBOT_PROFILE="headless"
export WBAB_SMOKE_SKIP_INSTALL=0
export WBAB_SMOKE_TRUST_DEV_CERT=1
export WBAB_DEV_CERT_CRT="${PROJECT_DIR}/.pq-signing/dev.crt.pem"
export WBAB_SMOKE_SESSION_ID="${ATTEMPT_ID}"
export WBAB_ARTIFACTS_DIR="${ARTIFACT_ROOT}/winebot"
export WBAB_SANITY_EXE='C:\Program Files\WineBotValidation\ValidationCLI.exe'
export WBAB_APP_ARGS="--message ${EXPECTED_VALUE} --output ${OUTPUT_WIN_PATH}"
export WBAB_SMOKE_EXTRACT_PATH="${OUTPUT_WIN_PATH}"
export WBAB_SMOKE_EXPECT_CONTENT="${EXPECTED_VALUE}"

"${ROOT_DIR}/tools/winebot-smoke.sh" "${PROJECT_DIR}/dist/ValidationSetup-signed.exe" \
  2>&1 | tee "${ARTIFACT_ROOT}/winebot-product-check.log"
WINEBOT_IMAGE_ID="$(docker image inspect --format '{{.Id}}' "${WINEBOT_IMAGE}:${WINEBOT_TAG}" 2>/dev/null || true)"
pass_phase

start_phase POSTCONDITION_VERIFIED
[[ -s "${ARTIFACT_ROOT}/winebot/extracted_output.txt" ]] || {
  echo "ERROR: WineBot postcondition artifact missing" >&2
  exit 13
}
ACTUAL_VALUE="$(tr -d '\r\n' < "${ARTIFACT_ROOT}/winebot/extracted_output.txt" | xargs)"
[[ "${ACTUAL_VALUE}" == "${EXPECTED_VALUE}" ]] || {
  echo "ERROR: product postcondition mismatch: expected=${EXPECTED_VALUE} actual=${ACTUAL_VALUE}" >&2
  exit 14
}
pass_phase "exact content matched"

CURRENT_PHASE="PRODUCT_QUALIFICATION_PASSED"
FINAL_RESULT="PRODUCT_QUALIFICATION_PASSED"
emit_event "${CURRENT_PHASE}" "PASSED" "all required phases executed and deterministic postcondition matched"
