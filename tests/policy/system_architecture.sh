#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[policy] verifying system architecture static contracts..."

# Operation-level caching, step-level idempotency, retry/resume, and attempt
# accounting are validated behaviorally in the bounded shell suite. Do not pin
# those runtime semantics to exact implementation text here.

# 1. Container Path Conventions
smoke="${ROOT_DIR}/tools/winebot-smoke.sh"
grep -q "/wineprefix/drive_c/" "${smoke}" || {
  echo "POLICY FAILURE: winebot-smoke.sh missing standard Wine drive_c mapping prefix" >&2; exit 1;
}
{ grep -q "\\\/public\\\/" "${smoke}" && grep -q "\\\/Public\\\/" "${smoke}"; } || {
  echo "POLICY FAILURE: winebot-smoke.sh missing Public folder casing retry logic" >&2; exit 1;
}

# 2. Durable architecture artifacts.
# Do not pin README prose/headings: wording is not an architecture invariant and
# caused a false-red when qualification claims were corrected under #58.
[[ -f "${ROOT_DIR}/docs/FORMAL_MODEL_HOWTO.md" ]] || {
  echo "POLICY FAILURE: missing formal model docs" >&2; exit 1;
}

# 3. Infrastructure Flow
[[ -f "${ROOT_DIR}/scripts/bootstrap-submodule.sh" ]] || {
  echo "POLICY FAILURE: missing bootstrap helper" >&2; exit 1;
}

echo "OK: system architecture static contracts satisfied"
