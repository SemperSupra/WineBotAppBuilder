# CONTEXT_BUNDLE (read this first)

## Current milestone

**Testing corrective program #58 — P0 through P3 implemented on the corrective stack.**

Current durable workset:

- parent PR #59: `corrective/testing-capability-qualification`;
- stacked P3 PR #60: `corrective/testing-ceremony-prune`;
- last proven engineering head: `4077fbd2d85a1fdd460921e4e589d3f708804961`;
- exact ordinary CI run at that head: `33633402860`, five jobs passed.

Implemented capability state:

- real candidate-source winbuild/product qualification vertical;
- real candidate-source NSIS packaging;
- real development signing with independent signature verification;
- WineBot install + installed CLI execution + deterministic externalized postcondition;
- ordinary `build`, `package`, and `sign` verbs use truthful real defaults;
- explicit fixture/custom modes and fail-closed contradictory-mode handling;
- structured `wbab plan` aligned with runtime execution mode;
- idempotent daemon state, retry/resume, audit, AuthN/AuthZ/TLS surfaces;
- live HTTP bearer-auth behavioral coverage;
- structured release authority-order policy checks;
- compact five-job ordinary CI with mocked integration retained inside the bounded shell suite;
- candidate Product Qualification path-scoped to product-path changes and manually dispatchable.

Release qualification is **not** complete. The release workflow publishes real artifacts/images, but exact published identities have not yet been qualified as a release set.

## Directory map

- `tools/` — user/automation-facing commands and runtime adapters
- `core/` — shared business logic
- `scripts/` — repository maintenance/security/publish helpers
- `tests/shell/` — bounded shell behavior, targeted mocks, selected live-local behavior
- `tests/contract/` — structured CLI/interface contracts
- `tests/policy/` — authority/config/provenance/formal-model policy checks
- `tests/unit/` — Python/core unit/property tests
- `tests/e2e/product-qualification.sh` — real first-party candidate product vertical
- `tests/e2e/run-real.sh` — opt-in real Docker/WineBot infrastructure smoke
- `.github/workflows/` — CI, qualification, manual diagnostic/formal/release workflows
- `docs/` — durable contracts, current state, corrective plan, security/formal guidance

## Canonical contracts

- Current state/resume point: `docs/STATE.md`
- Testing corrective plan and gate inventory: `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`
- CLI/environment contracts: `docs/CONTRACTS.md`
- Daemon security architecture: `docs/DAEMON_API_SECURITY_PLAN.md`
- Formal model interpretation: `docs/FORMAL_MODEL_HOWTO.md`
- Agent working rules: `AGENTS.md`

## Commands to run locally

Ordinary validators:

```bash
./scripts/bootstrap-submodule.sh
./scripts/lint.sh
./tests/shell/run.sh
./tests/contract/run.sh
./tests/policy/run.sh
```

The mocked build→package→sign→smoke integration test is now invoked by `tests/shell/run.sh`; there is no separate ordinary `tests/e2e/run.sh` gate.

Higher-fidelity paths:

```bash
# Candidate-source first-party product qualification
./tests/e2e/product-qualification.sh

# Opt-in real Docker/WineBot infrastructure smoke
./tests/e2e/run-real.sh
```

## Current command semantics

- `./tools/wbab build <project>` — real image-native build by default.
- `./tools/wbab package <project>` — real image-native package by default.
- `./tools/wbab sign <project>` — real development-certificate signing by default.
- fixture mode — explicit test selection only.
- custom command mode — explicit override only.
- contradictory mode settings — fail closed.
- `./tools/wbab plan ...` — reports the same resolved execution mode/command used by runtime execution.

Ordinary consumption remains pull-first from approved GHCR images. Candidate-source/local image construction is permitted when qualification/development requires it; do not treat that as the ordinary distribution default.

## CI / workflow map

### Ordinary PR CI — five recurring jobs

1. `lint`
2. `shell-unit` — bounded shell + retained mocked integration
3. `contract`
4. `policy`
5. `python-unit`

### Product qualification

`Product Qualification (Candidate)`:

- triggers on relevant `core/**`, `tools/**`, validation-app, qualification-script, or qualification-workflow PR changes;
- can also be manually dispatched;
- checks out the exact candidate head;
- runs the full candidate-source first-party product vertical;
- uploads retained qualification evidence;
- evidence class: `PRODUCT_QUALIFICATION` only on terminal success.

### Opt-in/manual workflows

- `E2E Real (Opt-In)` — real Docker/WineBot infrastructure path; normally `INFRASTRUCTURE_SMOKE`.
- `Policy Preflight Trend Gate (Opt-in)` — daemon trend-policy/diagnostic workflow.
- `TLA Skeleton Contract (Opt-in)` — TLA skeleton contract + formal-model snapshot; not full TLC state-space proof.
- `Release Automation` — real publication path with credential/authority boundaries; publication success is not by itself `RELEASE_QUALIFICATION`.

`Approved Issues Only` and `Approved PRs Only` are participation/governance controls, not testing gates.

## Evidence rules

Use:

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

Do not silently promote a weaker class. Bind stronger claims to exact source/artifact identities. A P3 documentation/test-policy-only change does not inherit a new product PASS, but it also should not trigger Product Qualification when no product surface changed.

## Proven corrective checkpoints

- P1 first-party product qualification: `04eb9e85805f629fcc2f36ab5f3428920d07be6b`; CI `33620383914`; Product Qualification `33620384011`.
- P2 build/package truthful defaults: `f0ff0f6ef2ea43cf704733fa6c28a5e7d6e33564`; CI `33628042826`; Product Qualification `33628042831`.
- P2 signing truthful default: `1c986051a078f870ee70c37d5088006b34239534`; CI `33629015926`; Product Qualification `33629015830`.
- P3.1 structured plan-contract collapse: `7a075f729257601d15f527b3686bab736cf68095`; CI `33631623609`; Product Qualification `33631623580`.
- P3.2 five-job consolidated CI: `4077fbd2d85a1fdd460921e4e589d3f708804961`; CI `33633402860`.

## Next bounded work

1. Finish durable P3 gate inventory/document reconciliation and validate the exact documentation checkpoint.
2. If no remaining recurring gate lacks decision value, mark P3 complete and make PR #60 review-ready.
3. Reconcile/merge the stacked PRs according to repository policy without transferring validation claims across changed heads.
4. Scope P4 separately: exact published image digests, exact release artifact hashes, release-qualified first-party vertical, and selected external target(s).

Stop before release publication, production signing credentials, destructive history changes, or undeclared authority escalation.
