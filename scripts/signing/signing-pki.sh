#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKI_DIR="${WBAB_SIGNING_PKI_DIR:-${ROOT_DIR}/.wbab/signing/pki}"

CA_CRT="${PKI_DIR}/ca.crt.pem"
CA_KEY="${PKI_DIR}/ca.key.pem"
SIGN_CRT="${PKI_DIR}/codesign.crt.pem"
SIGN_KEY="${PKI_DIR}/codesign.key.pem"
SIGN_PFX="${PKI_DIR}/codesign.pfx"
SIGN_PASS="${PKI_DIR}/codesign.pfx.pass"
SERIAL="${PKI_DIR}/ca.srl"

usage() {
  cat <<'EOF'
Usage:
  scripts/signing/signing-pki.sh <command> [args...]

Commands:
  init           Create internal CA + code-signing cert/key/pfx material (idempotent; no overwrite)
  rotate         Backup current material and generate a new set
  status         Print whether all expected files are present
  export <dir>   Copy signing PKI material to target directory
  import <dir>   Import signing PKI material from target directory
EOF
}

need_openssl() {
  command -v openssl >/dev/null 2>&1 || {
    echo "ERROR: openssl is required" >&2
    exit 1
  }
}

ensure_dir() {
  mkdir -p "${PKI_DIR}"
  chmod 700 "${PKI_DIR}"
}

required_files() {
  printf '%s\n' "${CA_CRT}" "${CA_KEY}" "${SIGN_CRT}" "${SIGN_KEY}" "${SIGN_PFX}" "${SIGN_PASS}"
}

gen_passphrase() {
  openssl rand -hex 16
}

write_codesign_extfile() {
  local f="$1"
  cat > "${f}" <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature
extendedKeyUsage=codeSigning
EOF
}

cmd_status() {
  echo "WBAB_SIGNING_PKI_DIR=${PKI_DIR}"
  while IFS= read -r f; do
    if [[ -f "${f}" ]]; then
      echo "present: ${f}"
    else
      echo "missing: ${f}"
    fi
  done < <(required_files)
}

cmd_init() {
  need_openssl
  ensure_dir

  while IFS= read -r f; do
    if [[ -f "${f}" ]]; then
      echo "ERROR: signing PKI material already exists in ${PKI_DIR} (use rotate)" >&2
      exit 2
    fi
  done < <(required_files)

  local pass
  pass="$(gen_passphrase)"
  printf '%s\n' "${pass}" > "${SIGN_PASS}"
  chmod 600 "${SIGN_PASS}"

  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -subj "/CN=WBAB Internal Code Signing CA/O=WineBotAppBuilder Internal" \
    -keyout "${CA_KEY}" \
    -out "${CA_CRT}" >/dev/null 2>&1

  openssl req -newkey rsa:3072 -nodes \
    -subj "/CN=WBAB Code Signing/O=WineBotAppBuilder Internal" \
    -keyout "${SIGN_KEY}" \
    -out "${PKI_DIR}/codesign.csr.pem" >/dev/null 2>&1

  write_codesign_extfile "${PKI_DIR}/codesign.ext"
  openssl x509 -req -in "${PKI_DIR}/codesign.csr.pem" \
    -CA "${CA_CRT}" -CAkey "${CA_KEY}" -CAserial "${SERIAL}" -CAcreateserial \
    -days 825 -sha256 -extfile "${PKI_DIR}/codesign.ext" \
    -out "${SIGN_CRT}" >/dev/null 2>&1

  openssl pkcs12 -export \
    -inkey "${SIGN_KEY}" \
    -in "${SIGN_CRT}" \
    -certfile "${CA_CRT}" \
    -passout "pass:${pass}" \
    -out "${SIGN_PFX}" >/dev/null 2>&1

  chmod 600 "${CA_KEY}" "${SIGN_KEY}" "${SIGN_PFX}" "${SIGN_PASS}"
  chmod 644 "${CA_CRT}" "${SIGN_CRT}"
  if [[ -f "${SERIAL}" ]]; then
    chmod 600 "${SERIAL}"
  fi
  rm -f "${PKI_DIR}/codesign.csr.pem" "${PKI_DIR}/codesign.ext"
  echo "OK: created signing PKI material at ${PKI_DIR}"
}

cmd_rotate() {
  ensure_dir
  local ts backup_dir
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_dir="${PKI_DIR}/backup-${ts}"
  mkdir -p "${backup_dir}"

  shopt -s nullglob
  for f in "${PKI_DIR}"/*.pem "${PKI_DIR}"/*.pfx "${PKI_DIR}"/*.pass "${PKI_DIR}"/*.srl; do
    mv "${f}" "${backup_dir}/"
  done
  shopt -u nullglob

  echo "OK: backed up prior signing PKI material to ${backup_dir}"
  cmd_init
}

cmd_export() {
  local out_dir="${1:-}"
  [[ -n "${out_dir}" ]] || { echo "ERROR: export requires target dir" >&2; exit 2; }
  mkdir -p "${out_dir}"

  while IFS= read -r f; do
    [[ -f "${f}" ]] || { echo "ERROR: missing source file ${f}" >&2; exit 2; }
    cp -f "${f}" "${out_dir}/"
  done < <(required_files)

  chmod 700 "${out_dir}"
  chmod 600 "${out_dir}/ca.key.pem" "${out_dir}/codesign.key.pem" "${out_dir}/codesign.pfx" "${out_dir}/codesign.pfx.pass"
  chmod 644 "${out_dir}/ca.crt.pem" "${out_dir}/codesign.crt.pem"
  echo "OK: exported signing PKI material to ${out_dir}"
}

cmd_import() {
  local in_dir="${1:-}"
  [[ -n "${in_dir}" ]] || { echo "ERROR: import requires source dir" >&2; exit 2; }
  [[ -d "${in_dir}" ]] || { echo "ERROR: source dir not found: ${in_dir}" >&2; exit 2; }
  ensure_dir

  for n in ca.crt.pem ca.key.pem codesign.crt.pem codesign.key.pem codesign.pfx codesign.pfx.pass; do
    [[ -f "${in_dir}/${n}" ]] || { echo "ERROR: missing import file ${in_dir}/${n}" >&2; exit 2; }
    cp -f "${in_dir}/${n}" "${PKI_DIR}/${n}"
  done

  chmod 600 "${CA_KEY}" "${SIGN_KEY}" "${SIGN_PFX}" "${SIGN_PASS}"
  chmod 644 "${CA_CRT}" "${SIGN_CRT}"
  echo "OK: imported signing PKI material into ${PKI_DIR}"
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
