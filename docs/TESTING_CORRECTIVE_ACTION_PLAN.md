# Testing Corrective Action Plan

Status: active corrective program; P0–P3 implemented on corrective stack, P4 pending  
Tracker: #58  
Finding: `docs/findings/testing-value-red-team-2026-09-02.md`

## Objective

Replace self-referential testing ceremony with a small, capability-driven validation system that produces actionable evidence and accelerates a working WBAB solution.

The desired end state is not "more tests" or "fewer tests." It is:

> the cheapest faithful validator for each material risk, with one real vertical proving the product's central capability and targeted lower-level checks isolating specific failure modes.

## Constraints / way of working

1. **Durable authority** — GitHub issue/PR/ref/artifacts are authoritative; chat/session state is not.
2. **Deterministic first** — repeated build/test/package/sign/smoke work belongs in repository-native scripts/workflows.
3. **Least scarce eligible resource** — use public deterministic CI/local Docker before consuming human/agent review for repeatable verification.
4. **Exact identity** — bind qualification to source SHA, image identity, artifact hash, and relevant environment/version.
5. **Fail closed** — no product PASS if a required phase did not execute.
6. **Reversible progression** — introduce replacement evidence before deleting legacy checks; prune in later bounded commits/PRs.
7. **Idempotent where practical** — qualification may be re-run without corrupting shared state and should isolate temporary artifacts/session identifiers.
8. **Actionable output** — first failed phase and durable evidence should tell the next worker what to fix.
9. **No platform invention** — use GitHub Actions, shell/Python, Docker/WineBot, and existing repo artifacts; do not create a new test-management service/database.
10. **Human/agent parity** — one command should be runnable by a human, CI, or an agent with the same semantics.

## Critical path

### Phase P0 — truth and evidence alignment

Status: **complete**.

Deliverables:

- accepted red-team finding;
- program tracker #58;
- evidence taxonomy (`STATIC_CONTRACT`, `MOCKED_BEHAVIOR`, `INFRASTRUCTURE_SMOKE`, `PRODUCT_QUALIFICATION`, `RELEASE_QUALIFICATION`);
- README/STATE/AGENTS wording that no longer upgrades fixture/mock results into production/product proof;
- current execution defaults explicitly documented.

Exit criterion:

A maintainer/agent can state exactly what normal CI proves and what remains unproven without reading implementation details.

### Phase P1 — first-party product qualification vertical

Status: **complete for the candidate-source first-party vertical**.

Use `samples/validation-app` and candidate-source tool images.

Required phases and stable result codes:

1. `SOURCE_IDENTIFIED`
2. `WINBUILD_IMAGE_BUILT`
3. `BUILD_EXECUTED`
4. `BUILD_OUTPUT_VERIFIED`
5. `PACKAGER_IMAGE_BUILT`
6. `PACKAGE_EXECUTED`
7. `INSTALLER_VERIFIED`
8. `SIGNER_IMAGE_BUILT`
9. `SIGN_EXECUTED`
10. `SIGNATURE_VERIFIED`
11. `WINEBOT_STARTED`
12. `INSTALL_EXECUTED`
13. `APP_EXECUTED`
14. `POSTCONDITION_VERIFIED`
15. terminal `PRODUCT_QUALIFICATION_PASSED`

Failure terminates with the first failed phase and retains logs/artifacts.

Minimum postcondition:

- install the exact generated `ValidationSetup` artifact in WineBot;
- execute installed `ValidationCLI.exe` with a unique value;
- extract the generated file;
- exact string equality with the expected value.

Qualification receipt includes observed identities/facts and does not invent image digests or environment identities that were not measured.

Initial proven checkpoint:

- source `04eb9e85805f629fcc2f36ab5f3428920d07be6b`;
- CI `33620383914` passed;
- Product Qualification `33620384011` passed.

Current rollout:

- manual dispatch remains available;
- relevant PR changes under `core/**`, `tools/**`, `samples/validation-app/**`, the qualification script, or qualification workflow trigger candidate Product Qualification;
- unrelated documentation/test-policy-only changes do not pay the Product Qualification cost.

### Phase P2 — make product verbs truthful

Status: **complete on PR #59**.

Implemented:

- `wbab build` defaults to the real build runner;
- `wbab package` defaults to the real package runner;
- fixture execution requires explicit test/fixture mode;
- `wbab sign` defaults to actual development signing rather than copying bytes;
- custom execution is explicit;
- contradictory mode settings fail closed;
- `wbab plan` matches actual execution semantics.

Backward compatibility remains subordinate to truthful semantics when compatibility would preserve a misleading claim.

Proven checkpoints:

- build/package `f0ff0f6ef2ea43cf704733fa6c28a5e7d6e33564`; CI `33628042826`; Product Qualification `33628042831`;
- signing `1c986051a078f870ee70c37d5088006b34239534`; CI `33629015926`; Product Qualification `33629015830`.

### Phase P3 — value-audit and prune legacy tests

Status: **implementation complete on PRs #59/#60; this document records the as-built inventory**.

Inventory every recurring gate with:

| Field | Meaning |
|---|---|
| risk | material failure the test protects |
| evidence_class | taxonomy above |
| faithful_boundary | real vs simulated boundary |
| decision_on_failure | concrete next engineering action |
| unique_signal | evidence not already supplied more faithfully elsewhere |
| resource_cost | rough CI/time/maintenance class |
| disposition | retain / collapse / demote / replace / delete |

Priorities applied:

- source-grep invariants were replaced with behavioral tests where practical;
- repetitive plan shell scripts were collapsed into parameterized structured JSON validation;
- workflow-step-name/adjacency checks were replaced with structured validation where the real invariant was authority ordering;
- daemon state/idempotency/authz and fault-injection mocks were retained where the mock isolates the intended variable;
- existence/hash checks are treated as inventory/provenance evidence rather than product validation;
- mocked build→package→sign→smoke integration behavior was retained but consolidated into the bounded shell job rather than represented as a separate E2E gate.

No check was removed merely because it was mocked; it was removed when it had no unique decision value or a cheaper/more faithful validator superseded it.

#### P3 as-built recurring-gate inventory — 2026-09-02

| gate/workflow | risk | evidence_class | faithful_boundary | decision_on_failure | unique_signal | resource_cost | disposition |
|---|---|---|---|---|---|---|---|
| ordinary `lint` | syntax/style/static defects and repository lint policy drift | `STATIC_CONTRACT` | real candidate source, static/containerized analysis | fix the exact lint/type/static defect before integration | yes; cheapest deterministic source-quality signal | medium runner, low interpretation cost | **retain** |
| ordinary `shell-unit` | wrapper/daemon orchestration, retry/idempotency, auth/config/error-path regressions | primarily `MOCKED_BEHAVIOR`, with selected live-local boundaries | real scripts/core with targeted substitutes; bearer AuthN includes a real localhost HTTP server | fix the named behavioral contract or isolated fault path | yes; isolates shell/runtime behaviors cheaply | medium; bounded per-test timeout | **retain, consolidated** |
| ordinary `contract` | CLI/plan/interface schema or semantic projection drift | `STATIC_CONTRACT` plus deterministic process-output validation | real candidate commands/output; external product boundary not claimed | fix interface/schema/mode projection | yes; compact consumer contract signal | low | **retain, collapsed/table-driven** |
| ordinary `policy` | release authority ordering, config/provenance/security prerequisite drift | primarily `STATIC_CONTRACT` with structured config checks | real candidate workflow/config/files; not product runtime proof | restore the protected authority/provenance invariant | yes after source-text duplicates were pruned | low | **retain, reduced** |
| ordinary `python-unit` | core algorithm/state/property regressions | unit/property behavior; not product E2E | real candidate Python/core in-process | fix core logic/property failure | yes; fastest deep core isolation | medium | **retain** |
| `Product Qualification (Candidate)` | integrated build→test→package→sign→install→execute product failure | `PRODUCT_QUALIFICATION` on terminal success | real candidate-source tool images, real validation workload, real WineBot install/execution, deterministic postcondition | repair first failed qualification phase using retained evidence | yes; strongest first-party product truth test | high, up to 45 min; path-scoped/manual | **retain; trigger only when product-path claim warrants it** |
| `E2E Real (Opt-In)` | Docker/WineBot infrastructure compatibility and operator-supplied installer smoke | `INFRASTRUCTURE_SMOKE` by default | real Docker/WineBot; completeness depends on invocation inputs | diagnose infrastructure/install compatibility | yes for manual infrastructure diagnosis; weaker than Product Qualification | high but manual only | **retain opt-in; do not promote to product proof** |
| `Policy Preflight Trend Gate (Opt-in)` | daemon preflight trend policy violation/diagnostic regression | `STATIC_CONTRACT` + bounded daemon diagnostic behavior | real policy suite and daemon trend API over available event state | inspect trend snapshot and threshold inputs | yes for operational trend-policy work; not ordinary product validation | low/medium, manual only | **retain opt-in** |
| `TLA Skeleton Contract (Opt-in)` | formal-model skeleton/config/document drift | `STATIC_CONTRACT` | real model files and snapshot artifact; no full TLC state-space claim | repair invariant/config/snapshot contract | yes as formal-model provenance/contract evidence | low, manual only | **retain opt-in; explicitly not full model proof** |
| `Release Automation` | credentialed publication ordering, GHCR/release publication, metadata retention | publication operation; not `RELEASE_QUALIFICATION` by itself | real GHCR/GitHub Release authority and artifacts when executed | stop/fix publication pipeline; P4 separately qualifies resulting immutable identities | yes; protects real publication authority boundary | high, tag/manual cadence | **retain; strengthen under P4 rather than duplicate with text checks** |

Repository participation controls `Approved Issues Only` and `Approved PRs Only` are intentionally **excluded from the testing/qualification inventory**. They enforce invite-only repository participation and mutate issue/PR state; they are governance controls, not evidence about WBAB product correctness.

#### P3 removed/collapsed ceremony

- Six repetitive `tests/contract/test_plan_*_json.sh` scripts -> one table-driven structured plan validator.
- Exact-source greps for operation success caching, step idempotency, and attempt-counter mutation -> existing behavioral idempotency/retry/API evidence.
- Daemon auth/TLS implementation-string greps -> auth/config/TLS behavioral tests plus new live HTTP bearer-response coverage.
- Release workflow literal step-name/line-order test -> structured release policy validation of trigger/permissions, checkout posture, validation-before-login/push, GHCR publication target, and always-on metadata retention.
- Standalone mocked `e2e-smoke` CI job and wrapper -> same mocked integration signal retained inside bounded `shell-unit`.

P3 exact checkpoints:

- P3.1 head `7a075f729257601d15f527b3686bab736cf68095`; CI `33631623609`; regression Product Qualification `33631623580`.
- P3.2 last proven engineering head `4077fbd2d85a1fdd460921e4e589d3f708804961`; five-job CI `33633402860` passed; no Product Qualification launched because the stacked diff was test/policy-only.

P3 stop rule:

Do not continue deleting merely to reduce counts. The current remaining ordinary gates each protect a distinct risk with an actionable failure decision. Further pruning requires new evidence that one of those signals has become redundant or a cheaper/more faithful replacement exists.

### Phase P4 — release and external qualification

Status: **pending; deliberately separate from P3**.

After first-party qualification is stable:

- qualify exact published image digests rather than mutable tags alone;
- bind release qualification to exact artifact hashes;
- run the first-party product vertical against exact published release identities;
- run at least one real external target, initially WinInspect if still representative;
- preserve exact failure evidence for incompatibilities;
- keep release/security gates that protect actual publication/credential/authority boundaries;
- remove duplicate textual checks that merely restate release implementation.

## Test architecture target

```text
FAST / ordinary change
  lint/static analysis
  pure/core unit tests
  daemon behavioral state/idempotency/authz tests
  bounded shell + retained targeted mocks
  compact structured CLI/plan contract validation
  structured release/policy invariants

PRODUCT QUALIFICATION
  exact source
    -> real winbuild
    -> real package
    -> real sign + verify
    -> real WineBot install
    -> real installed executable
    -> deterministic externalized postcondition

RELEASE QUALIFICATION
  exact published images/digests
    -> exact release artifact(s)
    -> first-party product vertical
    -> selected external compatibility target

TARGETED FAULT TESTS
  pull failures
  retry/resume
  duplicate requests
  interrupted operations
  resource/timeout boundaries
  authn/authz denials
```

## Progress / stop rules

Continue autonomously through a bounded slice while repository state and tools remain available.

Stop and checkpoint when:

- a required external credential/production authority is needed;
- release publication would occur;
- a destructive/irreversible history action is proposed;
- evidence shows the architecture assumption is wrong and the critical path should be changed;
- the current slice has reached a durable, independently reviewable boundary.

At each stop, #58 or its bounded child PR must expose:

- exact source/ref;
- completed phases;
- exact validation evidence actually executed;
- unknown/unexecuted phases;
- blocker if any;
- next bounded action.

## Success metric

The corrective program succeeds when normal project momentum is driven primarily by **capability failures with direct next actions**, rather than by repairing brittle tests that only confirm the repository still resembles its previous implementation.
