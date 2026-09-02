# Agent Playbook (AGENTS.md)

This repository is intended to be worked by humans and by agents (Codex CLI, Gemini CLI, Jules). Agents may be used at different times; assume limited context and interruption. Durable repository state is authoritative.

## Start here (minimal context set)

1. `docs/STATE.md`
2. The GitHub issue/PR for the bounded task
3. Files explicitly referenced by that issue/PR
4. `docs/CONTEXT_BUNDLE.md` only when broader system context is required

Do not load the entire repository history into working context when the current task can be resumed from these durable pointers.

## Global invariants

- No secrets or private keys committed to the repo.
- Respect `ORGANIZATION_POLICY.md` and `LINT_POLICY.md`.
- Keep `main` green; do not claim a PASS that did not execute against the exact candidate being discussed.
- Default ordinary distribution policy is pull-first from approved GHCR images; candidate-source/local image construction requires an explicit qualification/development reason.
- WineBot runner prefers an approved published WineBot image by default.
- Core business logic must not be duplicated in CLI/GUI/API adapters.
- One git commit per requested implementation change unless the user explicitly asks to batch changes.
- Preserve unknowns. Mock/static evidence must not be upgraded into real product evidence.
- Replacement evidence must exist before deleting a legacy validator.

## Testing/validation value rule

The active testing correction is tracked in issue #58.

> A recurring test/gate earns maintenance cost only when its failure changes a real engineering decision or protects a material invariant that cheaper evidence cannot protect.

Mocks are acceptable when they isolate the subject under test. A mocked service/tool must not stand in for the real boundary when the claimed result is about that boundary.

Use these evidence classes in PRs/issues/state:

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with one or more material boundaries simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime, incomplete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical plus independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts identified immutably and qualified.

A weaker class never implies a stronger class.

## Current command semantics

The P2 corrective work made ordinary verbs truthful by default:

- `wbab build` uses real image-native build execution;
- `wbab package` uses real image-native packaging;
- `wbab sign` uses real development-certificate signing;
- fixture mode is explicit;
- custom execution is explicit;
- contradictory mode settings fail closed;
- `wbab plan` reports the same resolved mode/command used by execution.

Do not reintroduce fixture defaults merely for compatibility. If a test needs fixture behavior, select the fixture path explicitly and classify the resulting evidence accordingly.

## Incremental development

Prefer the cheapest faithful validation sequence for the claim being changed:

1. deterministic lint/static checks appropriate to the change;
2. pure/core or bounded behavioral tests for isolated logic/contracts;
3. real build/test behavior when compilation/runtime is part of the claim;
4. Product Qualification when build/package/sign/install/runtime integration is part of the claim;
5. release qualification only when exact published identities are the subject of the claim;
6. targeted fault/mocked tests for the isolated behavior they are designed to exercise.

Do not add a new mock merely to make a pipeline green when the real environment is available and is the subject of the acceptance decision.

## Local validation commands

Ordinary repository validators:

```bash
./scripts/lint.sh
./tests/shell/run.sh
./tests/contract/run.sh
./tests/policy/run.sh
```

The bounded shell suite includes the retained mocked build→package→sign→smoke integration test. There is no separate ordinary `tests/e2e/run.sh` gate anymore.

Higher-fidelity/opt-in paths:

```bash
# Candidate-source first-party product qualification
./tests/e2e/product-qualification.sh

# Real Docker/WineBot infrastructure smoke; invocation-specific inputs apply
./tests/e2e/run-real.sh
```

Do not run Product Qualification casually for documentation/test-policy-only changes. The GitHub workflow is path-scoped so changes to product-path code/tooling receive the expensive vertical while unrelated P3 pruning does not.

## CI gates — current meaning

Ordinary PR CI has five jobs:

- **lint** — deterministic static/repository checks against the candidate.
- **shell-unit** — bounded shell behavior plus targeted mocks and selected live local boundaries; evidence class depends on the individual test. The retained mocked integration pipeline is `MOCKED_BEHAVIOR`, not product E2E.
- **contract** — structured CLI/plan/interface validation; primarily `STATIC_CONTRACT` plus deterministic process-output checks.
- **policy** — structured authority/config/provenance invariants; primarily `STATIC_CONTRACT`, with selected behavior-backed prerequisites.
- **python-unit** — pure/core behavioral unit/property tests; real code in-process, not product E2E.

Separate workflows:

- **Product Qualification (Candidate)** — `PRODUCT_QUALIFICATION`; path-scoped PR trigger plus manual dispatch; exact candidate checkout and retained evidence.
- **E2E Real (Opt-In)** — `INFRASTRUCTURE_SMOKE` by default; manual real Docker/WineBot path.
- **Policy Preflight Trend Gate (Opt-in)** — manual daemon-policy/diagnostic check; not product proof.
- **TLA Skeleton Contract (Opt-in)** — manual formal-model contract/snapshot check; it does not claim full TLC model checking.
- **Release Automation** — real publication/credential authority path; publication success alone is not `RELEASE_QUALIFICATION`.

The approved-issue/approved-PR workflows are repository participation controls, not testing/qualification gates.

## Product-qualification checkpoint discipline

A Product Qualification PASS must identify the exact source SHA and retained evidence. Do not inherit a previous product PASS after changing product-path code.

Conversely, a documentation/test-policy-only P3 commit that does not change the product surface does not need a gratuitous Product Qualification rerun merely to prove documentation changed; validate it at the boundary actually changed and preserve the last product qualification as historical evidence for the unchanged product candidate.

## PR/review evidence checklist

- [ ] Exact candidate/head SHA identified.
- [ ] The issue/PR states what capability or risk is being changed.
- [ ] Validation evidence is classified accurately; no inherited/older PASS substitutes for exact-head evidence when that evidence class is required.
- [ ] A failing recurring gate has an actionable engineering consequence; otherwise consider demotion/removal under #58.
- [ ] `docs/STATE.md` records current completed gate, unknown/unexecuted gate, blocker (if any), and next bounded action.
- [ ] `docs/CONTEXT_BUNDLE.md` is updated if commands/authority/continuation semantics materially change.
- [ ] Tests are added/updated for new behavior only when they provide unique decision value.
- [ ] Commit history follows the one-change-per-commit policy unless user-directed otherwise.

## Interruption/resumption

If execution stops before the objective is complete, leave durable repository state sufficient for the next human/agent to resume without replaying discovery:

- objective/issue;
- exact branch/head/candidate;
- completed vs unexecuted validation;
- durable evidence/artifacts;
- known unknowns/blocker;
- next safe bounded action.

A bare `continue` is a resume trigger, not a substitute for this checkpoint.
