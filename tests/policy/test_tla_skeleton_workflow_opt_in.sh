#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="${ROOT_DIR}/.github/workflows/tla-skeleton-contract-optin.yml"
ctx="${ROOT_DIR}/docs/CONTEXT_BUNDLE.md"

[[ -f "${wf}" ]] || { echo "Missing TLA skeleton opt-in workflow: ${wf}" >&2; exit 1; }
grep -q 'workflow_dispatch:' "${wf}" || { echo "TLA skeleton workflow must be workflow_dispatch only" >&2; exit 1; }
grep -q 'test_tla_idempotency_skeleton.sh' "${wf}" || { echo "TLA skeleton workflow must run the TLA policy contract test" >&2; exit 1; }
grep -q 'actions/upload-artifact@v4' "${wf}" || { echo "TLA skeleton workflow must upload formal model snapshot artifact" >&2; exit 1; }
grep -q 'tla-formal-model-snapshot' "${wf}" || { echo "TLA skeleton workflow artifact name must be tla-formal-model-snapshot" >&2; exit 1; }
grep -q 'formal-model-snapshot/' "${wf}" || { echo "TLA skeleton workflow artifact path must include formal-model-snapshot/" >&2; exit 1; }
grep -q 'formal/tla/DaemonIdempotency.tla' "${wf}" || { echo "TLA skeleton workflow must snapshot DaemonIdempotency.tla" >&2; exit 1; }
grep -q 'formal/tla/DaemonIdempotency.cfg' "${wf}" || { echo "TLA skeleton workflow must snapshot DaemonIdempotency.cfg" >&2; exit 1; }
grep -q 'formal/tla/DaemonIdempotencyExtended.cfg' "${wf}" || { echo "TLA skeleton workflow must snapshot DaemonIdempotencyExtended.cfg" >&2; exit 1; }
grep -q 'docs/FORMAL_MODEL_HOWTO.md' "${wf}" || { echo "TLA skeleton workflow must snapshot FORMAL_MODEL_HOWTO.md" >&2; exit 1; }
grep -q 'docs/CONTRACTS.md' "${wf}" || { echo "TLA skeleton workflow must snapshot CONTRACTS.md" >&2; exit 1; }
grep -q 'GITHUB_STEP_SUMMARY' "${wf}" || { echo "TLA skeleton workflow must emit snapshot summary to GITHUB_STEP_SUMMARY" >&2; exit 1; }
grep -q 'find formal-model-snapshot' "${wf}" || { echo "TLA skeleton workflow summary must enumerate snapshot files" >&2; exit 1; }
grep -q 'gh workflow run tla-skeleton-contract-optin.yml' "${ctx}" || {
  echo "CONTEXT_BUNDLE missing TLA skeleton opt-in CI execution note" >&2
  exit 1
}
grep -q 'TLA CI execution notes' "${ctx}" || {
  echo "CONTEXT_BUNDLE missing TLA CI execution notes section" >&2
  exit 1
}
grep -Eq 'Release sign-off checklist requires reviewing the .*tla-formal-model-snapshot.*artifact contents' "${ctx}" || {
  echo "CONTEXT_BUNDLE missing TLA snapshot checklist language" >&2
  exit 1
}
grep -q 'Contributor usage criteria for the formal-model PR checklist line' "${ctx}" || {
  echo "CONTEXT_BUNDLE missing contributor-note cross-link for formal-model checklist usage" >&2
  exit 1
}
grep -q 'Recommended: include that checklist line for PRs that change formal models or retry/idempotency behavior\.' "${ctx}" || {
  echo "CONTEXT_BUNDLE missing recommendation note for formal/retry-impacting PRs" >&2
  exit 1
}
grep -q "For signoff copy/paste, use the compact checklist example in \`docs/CONTRACTS.md\` (\`Compact release-signoff checklist example\`)\." "${ctx}" || {
  echo "CONTEXT_BUNDLE missing contracts checklist example note with wording anchor" >&2
  exit 1
}
grep -q 'FORMAL_MODEL_HOWTO.md' "${ctx}" || {
  echo "CONTEXT_BUNDLE missing formal model how-to cross-link" >&2
  exit 1
}
awk '
  /^TLA CI execution notes:/ { in_tla=1; next }
  /^## / && in_tla { in_tla=0 }
  in_tla && /Contributor usage criteria for the formal-model PR checklist line/ { found=1 }
  END { exit(found ? 0 : 1) }
' "${ctx}" || {
  echo "CONTEXT_BUNDLE contributor-note cross-link must remain under TLA CI execution notes" >&2
  exit 1
}
awk '
  /^TLA CI execution notes:/ { in_tla=1; next }
  /^## / && in_tla { in_tla=0 }
  in_tla && /Contributor usage criteria for the formal-model PR checklist line/ {
    if (getline next_line) {
      if (next_line ~ /Recommended: include that checklist line for PRs that change formal models or retry\/idempotency behavior\./) {
        found=1
      }
    }
  }
  END { exit(found ? 0 : 1) }
' "${ctx}" || {
  echo "CONTEXT_BUNDLE recommendation note must remain adjacent to contributor-note cross-link" >&2
  exit 1
}
awk '
  /^TLA CI execution notes:/ { in_tla=1; next }
  /^## / && in_tla { in_tla=0 }
  in_tla && /Recommended: include that checklist line for PRs that change formal models or retry\/idempotency behavior\./ {
    if (getline next_line) {
      if (next_line ~ /For signoff copy\/paste, use the compact checklist example in `docs\/CONTRACTS.md` \(`Compact release-signoff checklist example`\)\./) {
        found=1
      }
    }
  }
  END { exit(found ? 0 : 1) }
' "${ctx}" || {
  echo "CONTEXT_BUNDLE contracts checklist note must remain adjacent to recommendation bullet" >&2
  exit 1
}
awk '
  /^TLA CI execution notes:/ { in_tla=1; next }
  /^## / && in_tla { in_tla=0 }
  in_tla && /For signoff copy\/paste, use the compact checklist example in `docs\/CONTRACTS.md` \(`Compact release-signoff checklist example`\)\./ {
    if (getline next_line) {
      if (next_line ~ /Operator note: keep checklist text synchronized between `docs\/CONTRACTS.md` \(compact example\) and `docs\/FORMAL_MODEL_HOWTO.md` \(PR checklist line example\)\./) {
        found=1
      }
    }
  }
  END { exit(found ? 0 : 1) }
' "${ctx}" || {
  echo "CONTEXT_BUNDLE synchronization note must remain adjacent to contracts checklist note" >&2
  exit 1
}
awk '
  /^TLA CI execution notes:/ { in_tla=1; next }
  /^## / && in_tla { in_tla=0 }
  in_tla && /Operator note: keep checklist text synchronized/ {
    if ($0 ~ /`docs\/CONTRACTS.md`/ && $0 ~ /`docs\/FORMAL_MODEL_HOWTO.md`/) {
      found=1
    }
  }
  END { exit(found ? 0 : 1) }
' "${ctx}" || {
  echo "CONTEXT_BUNDLE synchronization note must reference both contracts and formal-model how-to docs" >&2
  exit 1
}

echo "OK: TLA skeleton opt-in workflow policy"
