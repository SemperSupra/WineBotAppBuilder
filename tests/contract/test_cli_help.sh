#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

help="$("${ROOT_DIR}/tools/wbab" --help)"
for v in build package sign smoke doctor plan; do
  echo "${help}" | grep -qE "\b${v}\b" || { echo "Missing verb in help: ${v}" >&2; exit 1; }
done
