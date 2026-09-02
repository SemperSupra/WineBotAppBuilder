#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[policy] verifying system architecture and formal contracts..."

# 1. Idempotency & TLA+ Contracts
# These legacy static checks are retained during #58 stabilization but are
# classified as STATIC_CONTRACT, not proof that the runtime model was executed.
core="${ROOT_DIR}/core/wbab_core.py"

grep -q 'existing.get("status") == "succeeded"' "${core}" || {
  echo "POLICY FAILURE: core missing operation-level success caching" >&2; exit 1;
}

grep -q 'if op\["step_state"\]\[.*\]\["status"\] != "succeeded":' "${core}" || {
  echo "POLICY FAILURE: core missing step-level idempotency invariant" >&2; exit 1;
}

grep -q 'op\["attempts"\] = int(op.get("attempts", 0)) + 1' "${core}" || {
  echo "POLICY FAILURE: core missing attempt tracking counter" >&2; exit 1;
}

# 2. Container Path Conventions
smoke="${ROOT_DIR}/tools/winebot-smoke.sh"
grep -q "/wineprefix/drive_c/" "${smoke}" || {
  echo "POLICY FAILURE: winebot-smoke.sh missing standard Wine drive_c mapping prefix" >&2; exit 1;
}
{ grep -q "\\\/public\\\/" "${smoke}" && grep -q "\\\/Public\\\/" "${smoke}"; } || {
  echo "POLICY FAILURE: winebot-smoke.sh missing Public folder casing retry logic" >&2; exit 1;
}

# 3. Durable architecture artifacts.
# Do not pin README prose/headings: wording is not an architecture invariant and
# caused a false-red when qualification claims were corrected under #58.
[[ -f "${ROOT_DIR}/docs/FORMAL_MODEL_HOWTO.md" ]] || {
  echo "POLICY FAILURE: missing formal model docs" >&2; exit 1;
}

# 4. Infrastructure Flow
[[ -f "${ROOT_DIR}/scripts/bootstrap-submodule.sh" ]] || {
  echo "POLICY FAILURE: missing bootstrap helper" >&2; exit 1;
}

echo "OK: system architecture static contracts satisfied"
