#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKI_DIR="${WBABD_PKI_DIR:-${ROOT_DIR}/../agent-privileged/daemon-pki}"

CA_CRT="${PKI_DIR}/ca.crt.pem"
CA_KEY="${PKI_DIR}/ca.key.pem"
SRV_CRT="${PKI_DIR}/server.crt.pem"
SRV_KEY="${PKI_DIR}/server.key.pem"
CLI_CRT="${PKI_DIR}/client.crt.pem"
CLI_KEY="${PKI_DIR}/client.key.pem"
SERIAL="${PKI_DIR}/ca.srl"

usage() {
  cat <<'EOF'
Usage:
  scripts/security/daemon-pki.sh <command> [args...]

Commands:
  init           Create internal CA + server/client cert material (idempotent; no overwrite)
  rotate         Backup current material and generate a new set
  status         Print whether all expected files are present
  export <dir>   Copy PKI material to target directory
  import <dir>   Import PKI material from target directory
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
  printf '%s\n' "${CA_CRT}" "${CA_KEY}" "${SRV_CRT}" "${SRV_KEY}" "${CLI_CRT}" "${CLI_KEY}"
}

write_server_extfile() {
  local f="$1"
  cat > "${f}" <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,IP:127.0.0.1
EOF
}

write_client_extfile() {
  local f="$1"
  cat > "${f}" <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF
}

cmd_status() {
  echo "WBABD_PKI_DIR=${PKI_DIR}"
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
      echo "ERROR: PKI material already exists in ${PKI_DIR} (use rotate)" >&2
      exit 2
    fi
  done < <(required_files)

  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -subj "/CN=WBABD Internal CA/O=WineBotAppBuilder Internal" \
    -keyout "${CA_KEY}" \
    -out "${CA_CRT}" >/dev/null 2>&1

  openssl req -newkey rsa:2048 -nodes \
    -subj "/CN=wbabd-server/O=WineBotAppBuilder Internal" \
    -keyout "${SRV_KEY}" \
    -out "${PKI_DIR}/server.csr.pem" >/dev/null 2>&1

  openssl req -newkey rsa:2048 -nodes \
    -subj "/CN=wbabd-client/O=WineBotAppBuilder Internal" \
    -keyout "${CLI_KEY}" \
    -out "${PKI_DIR}/client.csr.pem" >/dev/null 2>&1

  write_server_extfile "${PKI_DIR}/server.ext"
  write_client_extfile "${PKI_DIR}/client.ext"

  openssl x509 -req -in "${PKI_DIR}/server.csr.pem" \
    -CA "${CA_CRT}" -CAkey "${CA_KEY}" -CAserial "${SERIAL}" -CAcreateserial \
    -days 825 -sha256 -extfile "${PKI_DIR}/server.ext" \
    -out "${SRV_CRT}" >/dev/null 2>&1

  openssl x509 -req -in "${PKI_DIR}/client.csr.pem" \
    -CA "${CA_CRT}" -CAkey "${CA_KEY}" -CAserial "${SERIAL}" \
    -days 825 -sha256 -extfile "${PKI_DIR}/client.ext" \
    -out "${CLI_CRT}" >/dev/null 2>&1

  chmod 600 "${CA_KEY}" "${SRV_KEY}" "${CLI_KEY}"
  chmod 644 "${CA_CRT}" "${SRV_CRT}" "${CLI_CRT}"
  if [[ -f "${SERIAL}" ]]; then
    chmod 600 "${SERIAL}"
  elif [[ -f "${CA_CRT%.pem}.srl" ]]; then
    chmod 600 "${CA_CRT%.pem}.srl"
  fi
  rm -f "${PKI_DIR}/server.csr.pem" "${PKI_DIR}/client.csr.pem" "${PKI_DIR}/server.ext" "${PKI_DIR}/client.ext"

  echo "OK: created daemon internal PKI material at ${PKI_DIR}"
}

cmd_rotate() {
  ensure_dir
  local ts backup_dir
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_dir="${PKI_DIR}/backup-${ts}"
  mkdir -p "${backup_dir}"

  shopt -s nullglob
  for f in "${PKI_DIR}"/*.pem "${PKI_DIR}"/*.srl; do
    mv "${f}" "${backup_dir}/"
  done
  shopt -u nullglob

  echo "OK: backed up prior PKI material to ${backup_dir}"
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
  chmod 600 "${out_dir}/ca.key.pem" "${out_dir}/server.key.pem" "${out_dir}/client.key.pem"
  chmod 644 "${out_dir}/ca.crt.pem" "${out_dir}/server.crt.pem" "${out_dir}/client.crt.pem"
  echo "OK: exported daemon PKI material to ${out_dir}"
}

cmd_import() {
  local in_dir="${1:-}"
  [[ -n "${in_dir}" ]] || { echo "ERROR: import requires source dir" >&2; exit 2; }
  [[ -d "${in_dir}" ]] || { echo "ERROR: source dir not found: ${in_dir}" >&2; exit 2; }
  ensure_dir

  for n in ca.crt.pem ca.key.pem server.crt.pem server.key.pem client.crt.pem client.key.pem; do
    [[ -f "${in_dir}/${n}" ]] || { echo "ERROR: missing import file ${in_dir}/${n}" >&2; exit 2; }
    cp -f "${in_dir}/${n}" "${PKI_DIR}/${n}"
  done

  chmod 600 "${CA_KEY}" "${SRV_KEY}" "${CLI_KEY}"
  chmod 644 "${CA_CRT}" "${SRV_CRT}" "${CLI_CRT}"
  echo "OK: imported daemon PKI material into ${PKI_DIR}"
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
