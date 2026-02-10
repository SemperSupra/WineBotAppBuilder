#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
daemon="${ROOT_DIR}/tools/wbabd"
deploy_doc="${ROOT_DIR}/docs/DAEMON_DEPLOY_PROFILE.md"

grep -q 'parser.add_argument("--preflight"' "${daemon}" || { echo "wbabd missing serve --preflight flag" >&2; exit 1; }
grep -q '_run_inline_preflight' "${daemon}" || { echo "wbabd missing inline preflight implementation" >&2; exit 1; }
grep -q 'daemon-preflight.sh' "${daemon}" || { echo "wbabd missing daemon-preflight helper invocation" >&2; exit 1; }
grep -q 'command.preflight' "${daemon}" || { echo "wbabd missing preflight audit event emission" >&2; exit 1; }

grep -q 'serve --host 127.0.0.1 --port 8787' "${deploy_doc}" || { echo "Deploy profile missing serve command reference" >&2; exit 1; }
grep -q -- '--preflight' "${deploy_doc}" || { echo "Deploy profile missing --preflight usage" >&2; exit 1; }

echo "OK: daemon serve preflight flag policy"
