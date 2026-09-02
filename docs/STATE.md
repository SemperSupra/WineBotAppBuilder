# Project State

**Current date:** 2026-09-02  
**Current corrective program:** issue #58 — capability-driven product qualification and test-value correction  
**Parent implementation PR:** #59 (`corrective/testing-capability-qualification`)  
**Stacked P3 PR:** #60 (`corrective/testing-ceremony-prune`)

## Current status

P0 through P3 are **complete on the corrective stack**. WBAB has:

- a proven candidate-source first-party Product Qualification vertical;
- truthful real-by-default `build`, `package`, and development-signing semantics;
- structured plan/contract validation;
- behavioral replacement for superseded implementation-text policy checks;
- a five-job ordinary CI topology whose remaining gates have explicit decision value;
- an as-built gate inventory in `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`.

P4 / `RELEASE_QUALIFICATION` is deliberately separate and has **not** started. No current claim is made that exact published release images/artifacts have been qualified as a release set or that WBAB is generally `Production Stable`.

## Proven checkpoints

- P1 Product Qualification: `04eb9e85805f629fcc2f36ab5f3428920d07be6b`; CI `33620383914`; Product Qualification `33620384011`.
- P2 build/package: `f0ff0f6ef2ea43cf704733fa6c28a5e7d6e33564`; CI `33628042826`; Product Qualification `33628042831`.
- P2 signing: `1c986051a078f870ee70c37d5088006b34239534`; CI `33629015926`; Product Qualification `33629015830`.
- P3.1 plan-contract collapse: `7a075f729257601d15f527b3686bab736cf68095`; CI `33631623609`; regression Product Qualification `33631623580`.
- P3.2 five-job engineering checkpoint: `4077fbd2d85a1fdd460921e4e589d3f708804961`; CI `33633402860`.
- P3 documentation/inventory checkpoint: `46db696704bf5f51ae15dcacf2d19aa0128e0200`; CI `33637937692`.
- P3 closeout checkpoint before deterministic integration fallback: `c903530aad7b5aeb2c4d48ce43637548f337f10c`; CI `33638302757`.

## Ordinary validation topology

1. `lint`
2. `shell-unit` — bounded shell + targeted mocks + retained mocked integration
3. `contract`
4. `policy`
5. `python-unit`

Product Qualification is path-scoped/manual and is required when the changed claim crosses the real build/package/sign/install/runtime product boundary.

## Execution / delegation correction

Routine mechanical repository operations MUST NOT be returned to the maintainer merely because one interactive connector or UI action is unavailable.

For deterministic, already-authorized operations, prefer:

```text
durable GitHub baton
    -> repository-native deterministic script
    -> local credentialed executor/agent when local GitHub authority is required
    -> exact result/evidence written back to GitHub
```

The current fallback is `scripts/ops/complete-issue-58-stack.py`.

It is intentionally fail-closed and idempotent where practical. It verifies exact PR heads/base state, review/change-request state, checks, and mergeability before mutation.

### Stack-safe integration order

Do **not** squash #59 to `main` first and then retarget #60. #60 is stacked on #59's commit ancestry; squashing the parent first can destroy the shared ancestry and make the child appear to reintroduce parent changes.

The deterministic executor therefore performs:

```text
validated PR #60 exact head
    -> mark #60 ready
    -> squash #60 into its existing parent branch (#59 head branch)
    -> observe the new combined #59 head
    -> require a NEW ordinary CI run on that combined head
    -> require a NEW Product Qualification run on that combined head
    -> mark #59 ready
    -> squash the fully revalidated #59 once into main
    -> verify main advanced
    -> write exact evidence back to #58
```

This keeps the stack ancestry intact until the combined candidate has been independently validated and preserves the repository's normal squash-style final integration into `main`.

The script requires `--execute` plus the exact #60 head supplied by the durable #58 baton. That guard prevents a stale local session from silently integrating a changed candidate.

## Current authority boundary

The maintainer has delegated the routine #58 stack-integration mechanics to automation/local-agent execution. Human manual clicking is **not required** for:

- marking #60 ready for review;
- merging #60 into the existing #59 parent branch after its exact checks remain green;
- waiting for and evaluating the new combined-head CI and Product Qualification on #59;
- marking #59 ready for review;
- merging the revalidated combined #59 to `main`;
- writing the resulting exact evidence back to #58.

The executor MUST stop for:

- unexpected main/head/base drift;
- failed or missing required validation;
- changes requested or unresolved review threads;
- merge conflicts;
- new credential/authority requirements;
- release/publication;
- production signing credentials;
- destructive/irreversible history operations;
- unresolved security/licensing/value-classification boundaries.

## Resume checkpoint

Authoritative tracker: **issue #58**.  
Parent PR: **#59**.  
Stacked P3 PR: **#60**.  
Current next executor: **local deterministic script, optionally supervised by the local agent**.  
Work packet: the latest #58 integration-baton comment.  
Command: `python scripts/ops/complete-issue-58-stack.py --execute --expected-child-head <exact-head-from-#58-baton>`  
Human input required for this routine integration: **no**.  
P4 remains out of scope until deliberately opened as a separate release-qualification workset.
