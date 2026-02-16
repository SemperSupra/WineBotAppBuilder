#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV_CERT_DIR="${WBAB_DEV_CERT_DIR:-${ROOT_DIR}/../agent-privileged/signing/dev}"

CRT="${DEV_CERT_DIR}/dev.crt.pem"
KEY="${DEV_CERT_DIR}/dev.key.pem"
PFX="${DEV_CERT_DIR}/dev.pfx"
PASS_FILE="${DEV_CERT_DIR}/dev.pfx.pass"

usage() {
  cat <<'EOF'
Usage:
  scripts/signing/dev-cert.sh <command> [args...]

Commands:
  init           Create dev signing cert/key/pfx (idempotent; no overwrite)
  rotate         Backup current cert material and generate a new set
  status         Print whether cert/key/pfx/pass are present
  export <dir>   Copy cert material to target directory
  import <dir>   Import cert material from target directory
EOF
}

need_openssl() {
  command -v openssl >/dev/null 2>&1 || {
    echo "ERROR: openssl is required" >&2
    exit 1
  }
}

ensure_dir() {
  mkdir -p "${DEV_CERT_DIR}"
  chmod 700 "${DEV_CERT_DIR}"
}

gen_passphrase() {
  openssl rand -hex 16
}

cmd_status() {
  echo "DEV_CERT_DIR=${DEV_CERT_DIR}"
  for f in "${CRT}" "${KEY}" "${PFX}" "${PASS_FILE}"; do
    if [[ -f "${f}" ]]; then
      echo "present: ${f}"
    else
      echo "missing: ${f}"
    fi
  done
}

cmd_init() {
  need_openssl
  ensure_dir

  if [[ -f "${CRT}" || -f "${KEY}" || -f "${PFX}" || -f "${PASS_FILE}" ]]; then
    echo "ERROR: cert material already exists in ${DEV_CERT_DIR} (use rotate)" >&2
    exit 2
  fi

  local pass
  pass="$(gen_passphrase)"
  printf '%s\n' "${pass}" > "${PASS_FILE}"
  chmod 600 "${PASS_FILE}"

  openssl req -x509 -newkey rsa:2048 -sha256 -days 365 \
    -nodes \
    -subj "/CN=WBAB Dev Code Signing/O=WineBotAppBuilder Dev" \
    -keyout "${KEY}" \
    -out "${CRT}" >/dev/null 2>&1

  chmod 600 "${KEY}"
  chmod 644 "${CRT}"

  openssl pkcs12 -export \
    -inkey "${KEY}" \
    -in "${CRT}" \
    -passout "pass:${pass}" \
    -out "${PFX}" >/dev/null 2>&1

  chmod 600 "${PFX}"
  echo "OK: created dev cert material at ${DEV_CERT_DIR}"
}

cmd_rotate() {
  ensure_dir
  local ts backup_dir
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_dir="${DEV_CERT_DIR}/backup-${ts}"
  mkdir -p "${backup_dir}"

  for f in "${CRT}" "${KEY}" "${PFX}" "${PASS_FILE}"; do
    if [[ -f "${f}" ]]; then
      mv "${f}" "${backup_dir}/"
    fi
  done
  echo "OK: backed up prior cert material to ${backup_dir}"
  cmd_init
}

cmd_export() {
  local out_dir="${1:-}"
  [[ -n "${out_dir}" ]] || { echo "ERROR: export requires target dir" >&2; exit 2; }
  mkdir -p "${out_dir}"

  for f in "${CRT}" "${KEY}" "${PFX}" "${PASS_FILE}"; do
    [[ -f "${f}" ]] || { echo "ERROR: missing source file ${f}" >&2; exit 2; }
    cp -f "${f}" "${out_dir}/"
  done
  chmod 700 "${out_dir}"
  chmod 600 "${out_dir}/$(basename "${KEY}")" "${out_dir}/$(basename "${PFX}")" "${out_dir}/$(basename "${PASS_FILE}")"
  chmod 644 "${out_dir}/$(basename "${CRT}")"
  echo "OK: exported dev cert material to ${out_dir}"
}

cmd_import() {
  local in_dir="${1:-}"
  [[ -n "${in_dir}" ]] || { echo "ERROR: import requires source dir" >&2; exit 2; }
  [[ -d "${in_dir}" ]] || { echo "ERROR: source dir not found: ${in_dir}" >&2; exit 2; }
  ensure_dir

  for n in dev.crt.pem dev.key.pem dev.pfx dev.pfx.pass; do
    [[ -f "${in_dir}/${n}" ]] || { echo "ERROR: missing import file ${in_dir}/${n}" >&2; exit 2; }
  done

  cp -f "${in_dir}/dev.crt.pem" "${CRT}"
  cp -f "${in_dir}/dev.key.pem" "${KEY}"
  cp -f "${in_dir}/dev.pfx" "${PFX}"
  cp -f "${in_dir}/dev.pfx.pass" "${PASS_FILE}"
  chmod 644 "${CRT}"
  chmod 600 "${KEY}" "${PFX}" "${PASS_FILE}"
  echo "OK: imported dev cert material into ${DEV_CERT_DIR}"
}

cmd="${1:-}"
shift || true

case "${cmd}" in
  init) cmd_init "$@" ;;
  rotate) cmd_rotate "$@" ;;
  status) cmd_status "$@" ;;
  export) cmd_export "$@" ;;
  import) cmd_import "$@" ;;
  -h|--help|"") usage; exit 0 ;;
  *) echo "ERROR: unknown command: ${cmd}" >&2; usage >&2; exit 2 ;;
esac
