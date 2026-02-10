#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
model="${ROOT_DIR}/formal/tla/DaemonIdempotency.tla"
cfg_ext="${ROOT_DIR}/formal/tla/DaemonIdempotencyExtended.cfg"
readme="${ROOT_DIR}/formal/tla/README.md"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"
state="${ROOT_DIR}/docs/STATE.md"
howto="${ROOT_DIR}/docs/FORMAL_MODEL_HOWTO.md"
ctx="${ROOT_DIR}/docs/CONTEXT_BUNDLE.md"
artifact_name="tla-formal-model-snapshot"
consistency_phrase='formal models or retry/idempotency behavior'
checklist_pattern="Formal-model release note snippet added (workflow \`tla-skeleton-contract-optin\`, artifact \`tla-formal-model-snapshot\` reviewed)\."

[[ -f "${model}" ]] || { echo "Missing TLA+ model: ${model}" >&2; exit 1; }
[[ -f "${cfg_ext}" ]] || { echo "Missing extended TLA+ config: ${cfg_ext}" >&2; exit 1; }
[[ -f "${howto}" ]] || { echo "Missing formal model how-to: ${howto}" >&2; exit 1; }
[[ -f "${ctx}" ]] || { echo "Missing context bundle doc: ${ctx}" >&2; exit 1; }

grep -q 'stepRetryCount' "${model}" || { echo "TLA+ model missing stepRetryCount variable" >&2; exit 1; }
grep -q 'Invariant_StepRetryCountNonNegative' "${model}" || { echo "TLA+ model missing step retry non-negative invariant" >&2; exit 1; }
grep -q 'Invariant_StepRetryCountLeRunAttempts' "${model}" || { echo "TLA+ model missing step retry bounded-by-attempts invariant" >&2; exit 1; }
grep -q 'Invariant_StepRetryCountNonNegative' "${cfg_ext}" || { echo "Extended TLA+ config missing step retry non-negative check" >&2; exit 1; }
grep -q 'Invariant_StepRetryCountLeRunAttempts' "${cfg_ext}" || { echo "Extended TLA+ config missing step retry bounded check" >&2; exit 1; }
grep -q 'Optional Extended Invariant Set' "${readme}" || { echo "TLA+ README missing extended invariants section" >&2; exit 1; }
grep -q 'Step Retry Counter Translation' "${howto}" || { echo "Formal model how-to missing step retry translation section" >&2; exit 1; }
grep -q 'step_state\[\*\]\.attempts' "${howto}" || { echo "Formal model how-to missing step_state[*].attempts mapping" >&2; exit 1; }
grep -q 'operation\.succeeded' "${howto}" || { echo "Formal model how-to missing operation.succeeded event linkage" >&2; exit 1; }
grep -q 'Release Sign-Off Config Selection' "${howto}" || { echo "Formal model how-to missing release sign-off config section" >&2; exit 1; }
grep -q 'DaemonIdempotency.cfg' "${howto}" || { echo "Formal model how-to missing baseline config sign-off command" >&2; exit 1; }
grep -q 'DaemonIdempotencyExtended.cfg' "${howto}" || { echo "Formal model how-to missing extended config sign-off command" >&2; exit 1; }
grep -q "${artifact_name}" "${howto}" || { echo "Formal model how-to missing release checklist artifact review note" >&2; exit 1; }
grep -q "${artifact_name}" "${ctx}" || { echo "Context bundle missing TLA snapshot artifact name" >&2; exit 1; }
grep -q 'docs/CONTRACTS.md' "${ctx}" || { echo "Context bundle missing contracts cross-reference for checklist usage" >&2; exit 1; }
grep -q 'Compact release-signoff checklist example' "${ctx}" || { echo "Context bundle missing contracts checklist wording anchor" >&2; exit 1; }
grep -q "${consistency_phrase}" "${howto}" || { echo "Formal model how-to missing canonical checklist recommendation wording" >&2; exit 1; }
grep -q "${consistency_phrase}" "${ctx}" || { echo "Context bundle missing canonical checklist recommendation wording" >&2; exit 1; }
grep -q 'Release note snippet' "${howto}" || { echo "Formal model how-to missing release note snippet section" >&2; exit 1; }
grep -q 'Formal model review: completed\.' "${howto}" || { echo "Formal model how-to missing release note snippet content" >&2; exit 1; }
grep -q 'Workflow: tla-skeleton-contract-optin' "${howto}" || { echo "Formal model how-to release note snippet must pin workflow name" >&2; exit 1; }
grep -q 'PR checklist line example' "${howto}" || { echo "Formal model how-to missing PR checklist line example section" >&2; exit 1; }
grep -q 'Formal-model release note snippet added' "${howto}" || { echo "Formal model how-to missing PR checklist release-note reference" >&2; exit 1; }
grep -q "workflow \`tla-skeleton-contract-optin\`" "${howto}" || { echo "Formal model how-to PR checklist line must pin workflow name" >&2; exit 1; }
grep -q "artifact \`${artifact_name}\` reviewed" "${howto}" || { echo "Formal model how-to PR checklist line must pin artifact name" >&2; exit 1; }
grep -q "${checklist_pattern}" "${howto}" || { echo "Formal model how-to missing canonical checklist example text" >&2; exit 1; }
grep -q 'Contributor note:' "${howto}" || { echo "Formal model how-to missing contributor note section" >&2; exit 1; }
grep -q "Use workflow \`tla-skeleton-contract-optin\` and artifact \`tla-formal-model-snapshot\`" "${howto}" || {
  echo "Formal model how-to contributor note must reference workflow and artifact names" >&2
  exit 1
}

grep -q 'DaemonIdempotencyExtended.cfg' "${contracts}" || { echo "Contracts missing extended TLA+ config reference" >&2; exit 1; }
grep -q 'FORMAL_MODEL_HOWTO.md' "${contracts}" || { echo "Contracts missing formal model how-to reference" >&2; exit 1; }
grep -q 'Formal-model checklist usage guidance' "${contracts}" || { echo "Contracts missing formal-model checklist guidance note" >&2; exit 1; }
grep -q 'docs/CONTEXT_BUNDLE.md' "${contracts}" || { echo "Contracts checklist guidance must reference context bundle" >&2; exit 1; }
grep -q 'docs/FORMAL_MODEL_HOWTO.md' "${contracts}" || { echo "Contracts checklist guidance must reference formal model how-to" >&2; exit 1; }
grep -q 'Compact release-signoff checklist example' "${contracts}" || { echo "Contracts missing compact release-signoff checklist example" >&2; exit 1; }
grep -q "workflow \`tla-skeleton-contract-optin\`" "${contracts}" || { echo "Contracts checklist example must include workflow identifier" >&2; exit 1; }
grep -q "artifact \`tla-formal-model-snapshot\` reviewed" "${contracts}" || { echo "Contracts checklist example must include artifact identifier" >&2; exit 1; }
grep -q "${checklist_pattern}" "${contracts}" || { echo "Contracts checklist example must match formal-model how-to checklist text" >&2; exit 1; }
grep -q 'step-level retry counters' "${state}" || { echo "STATE missing step-level retry counter invariant reference" >&2; exit 1; }

echo "OK: TLA+ extended invariants contract"
