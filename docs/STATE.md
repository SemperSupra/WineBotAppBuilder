# Project State

**Current date:** 2026-09-02  
**Current corrective program:** issue #58 — capability-driven product qualification  
**Pre-correction main baseline:** `bd79d45ba20cc70cae9da7625c6b3605c7176655`

## Current status

WBAB has substantial real implementation in its container images, daemon, packaging/signing helpers, WineBot integration, and release automation. However, the 2026-09-02 testing red-team established that the repository's recurring validation claims exceed the evidence produced by the normal test path.

Accordingly, the prior `Production Stable` label is **not current qualification evidence**. Until the corrective program establishes a real product vertical, describe WBAB as:

> implemented toolchain candidate under capability qualification.

Historical state remains available in Git history, including the full pre-correction `docs/STATE.md` at baseline `bd79d45ba20cc70cae9da7625c6b3605c7176655`. This compact file is the active working-state projection; it intentionally does not repeat the old accumulating accomplishment/checklist log.

## Accepted finding

Maintainer concurrence: the current test program is overweight on mocked Docker/fixture pipelines, source-text/policy grep checks, workflow-shape ceremony, and repetitive structural contracts relative to direct proof of the product's real capability.

Durable records:

- `docs/findings/testing-value-red-team-2026-09-02.md`
- `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`
- issue #58

## What current recurring validation does prove

Useful decision evidence currently includes:

- daemon operation-state/idempotency/retry/resume behavior under controlled workers;
- selected AuthN/AuthZ/config behavior;
- pure Python/core logic and property tests;
- CLI dispatch/contracts;
- pull-first/no-local-build orchestration policy;
- static release/policy/configuration assertions;
- mocked traversal of build -> package -> sign -> smoke.

## What current recurring validation does **not** prove

A green normal CI run does not by itself prove that the exact candidate:

1. built a real Windows application through the real WBAB build runner;
2. packaged the resulting binaries through real NSIS packaging;
3. signed the exact installer through the real signer and verified that signature;
4. installed that exact installer in real WineBot;
5. launched the installed application;
6. produced an independently verified deterministic postcondition.

The existing opt-in `e2e-real` path is currently best classified as `INFRASTRUCTURE_SMOKE` by default because it uses fixture product artifacts and can skip installation.

## Current semantic defect

The host wrappers for `wbab build`, `wbab package`, and `wbab sign` still default to fixture/scaffold behavior, even though the tool images contain real runners. Until #58 P2 changes this, success from those default wrappers must not be presented as real product build/package/sign evidence.

## Evidence classes

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

Never silently promote a weaker class into a stronger PASS.

## Current critical path

### P0 — truth/evidence alignment

Status: **in progress on corrective branch**.

Required:

- durable findings/program record;
- accurate README/AGENTS/STATE descriptions;
- remove stale `workspace/`/nonexistent `init` quick-start claims;
- make current fixture defaults explicit.

### P1 — real first-party product qualification

Next bounded implementation action.

Use `samples/validation-app` as the real product workload:

```text
exact candidate source
  -> candidate-source winbuild image
  -> real CMake/MinGW build
  -> verify Validation binaries
  -> candidate-source packager image
  -> real NSIS installer
  -> candidate-source signer image
  -> dev-sign exact installer + verify signature
  -> real WineBot
  -> install exact signed installer
  -> run installed ValidationCLI.exe
  -> extract deterministic output
  -> exact content assertion
  -> structured qualification receipt
```

Initial P1 should be opt-in/non-required until repeated execution demonstrates acceptable reliability and resource cost. Existing gates remain during stabilization.

### P2 — truthful ordinary command defaults

Blocked on P1 being usable enough to expose failures clearly.

- real build/package by default;
- fixture mode explicit/test-scoped;
- `sign` cannot silently copy bytes and call that signing;
- plan output matches actual execution semantics.

### P3 — prune/collapse ceremony

Blocked on replacement evidence from P1/P2.

Do not delete legacy checks before their unique decision value has been evaluated and replacement evidence exists.

### P4 — release/external qualification

Later:

- exact published image digests;
- exact artifact hashes;
- first-party vertical;
- selected real external target (candidate: WinInspect).

## Stop / resume checkpoint

Current authoritative program: issue #58.  
Current intended branch: `corrective/testing-capability-qualification`.  
Current next safe action: implement P1 as a bounded candidate product-qualification script/workflow, then execute it against the exact branch head and retain actual phase evidence.  
Human authority required now: **no** for reversible repository implementation and public deterministic CI.  
Stop before release publication, production signing credentials, destructive history changes, or other undeclared authority escalation.
