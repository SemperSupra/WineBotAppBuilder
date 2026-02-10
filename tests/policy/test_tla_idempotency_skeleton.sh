#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
model="${ROOT_DIR}/formal/tla/DaemonIdempotency.tla"
cfg="${ROOT_DIR}/formal/tla/DaemonIdempotency.cfg"
readme="${ROOT_DIR}/formal/tla/README.md"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"
state="${ROOT_DIR}/docs/STATE.md"

[[ -f "${model}" ]] || { echo "Missing TLA+ model skeleton: ${model}" >&2; exit 1; }
[[ -f "${cfg}" ]] || { echo "Missing TLA+ model config: ${cfg}" >&2; exit 1; }
[[ -f "${readme}" ]] || { echo "Missing TLA+ model README: ${readme}" >&2; exit 1; }

grep -q 'MODULE DaemonIdempotency' "${model}" || { echo "TLA+ model missing module declaration" >&2; exit 1; }
grep -q 'Invariant_IdempotentOnceSucceeded' "${model}" || { echo "TLA+ model missing idempotency invariant" >&2; exit 1; }
grep -q 'Invariant_AttemptsNonNegative' "${model}" || { echo "TLA+ model missing retry/resume attempts invariant" >&2; exit 1; }
grep -q 'TypeOk' "${cfg}" || { echo "TLA+ config missing TypeOk invariant check" >&2; exit 1; }
grep -q 'tlc2 formal/tla/DaemonIdempotency.tla -config formal/tla/DaemonIdempotency.cfg' "${readme}" || {
  echo "TLA+ README missing canonical tlc2 run command" >&2
  exit 1
}
grep -q 'Expected Invariant Checks' "${readme}" || { echo "TLA+ README missing expected invariant checks section" >&2; exit 1; }
grep -q 'Invariant_IdempotentOnceSucceeded' "${readme}" || { echo "TLA+ README missing idempotency invariant check reference" >&2; exit 1; }
grep -q 'Invariant_AttemptsNonNegative' "${readme}" || { echo "TLA+ README missing attempts invariant check reference" >&2; exit 1; }
grep -q 'Invariant-to-Policy Mapping Example' "${readme}" || { echo "TLA+ README missing invariant-to-policy mapping section" >&2; exit 1; }
grep -q 'tests/policy/test_tla_idempotency_skeleton.sh' "${readme}" || { echo "TLA+ README missing baseline policy mapping reference" >&2; exit 1; }
grep -q 'tests/policy/test_tla_extended_invariants_contract.sh' "${readme}" || { echo "TLA+ README missing extended policy mapping reference" >&2; exit 1; }

grep -q 'formal/tla/DaemonIdempotency.tla' "${contracts}" || { echo "Contracts missing TLA+ model reference" >&2; exit 1; }
grep -q 'TLA+ model skeleton' "${state}" || { echo "STATE missing TLA+ model skeleton reference" >&2; exit 1; }

echo "OK: TLA+ idempotency skeleton policy"
