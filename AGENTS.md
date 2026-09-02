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
- Default ordinary distribution policy is pull-first from approved GHCR images; local toolchain builds require an explicit qualification/development reason.
- WineBot runner prefers an approved published WineBot image by default.
- Core business logic must not be duplicated in CLI/GUI/API adapters.
- One git commit per requested implementation change unless the user explicitly asks to batch changes.
- Preserve unknowns. Mock/static evidence must not be upgraded into real product evidence.

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

## Current command caveat

Until issue #58 P2 is complete, `wbab build`, `wbab package`, and `wbab sign` host wrappers have fixture/scaffold defaults even though their container images contain real runners. Therefore a successful default invocation is not, by itself, evidence of a real build/package/sign operation.

For product claims, use the dedicated capability-qualification path introduced under #58 or explicitly select the real runner and record that fact.

## Incremental development

For application changes, prefer the cheapest faithful validation sequence:

1. deterministic lint/static checks appropriate to the change;
2. real build/test behavior when compilation/runtime is part of the claim;
3. product qualification when installer/runtime integration is part of the claim;
4. targeted fault/mocked tests only for the isolated behavior they are designed to exercise.

Do not add a new mock merely to make a pipeline green when the real environment is available and is the subject of the acceptance decision.

## Local validation commands

Legacy/fast gates:

```bash
./scripts/lint.sh
./tests/shell/run.sh
./tests/contract/run.sh
./tests/policy/run.sh
./tests/e2e/run.sh
```

Evidence semantics:

- `tests/e2e/run.sh` is `MOCKED_BEHAVIOR`, not product E2E.
- the existing `tests/e2e/run-real.sh` is currently `INFRASTRUCTURE_SMOKE` unless configured to execute a real installer/postcondition.
- the #58 corrective program will introduce/strengthen `PRODUCT_QUALIFICATION` without deleting legacy gates until replacement evidence is established.

## CI gates — current meaning

- **lint** — deterministic static/repository checks.
- **shell-unit** — predominantly mock-based shell behavior/policy checks; `MOCKED_BEHAVIOR` unless a specific test documents a real boundary.
- **contract** — predominantly `STATIC_CONTRACT`.
- **policy** — predominantly `STATIC_CONTRACT`, with some behavioral checks; inspect the specific test before making a stronger claim.
- **python-unit** — pure/core behavioral unit/property checks; useful for the code under test but not product E2E.
- **e2e-smoke** — mocked orchestration only; `MOCKED_BEHAVIOR`.
- **e2e-real** — opt-in real Docker/WineBot infrastructure path; currently `INFRASTRUCTURE_SMOKE` by default, not full product qualification.

## PR/review evidence checklist

- [ ] Exact candidate/head SHA identified.
- [ ] The issue/PR states what capability or risk is being changed.
- [ ] Validation evidence is classified accurately; no inherited/older PASS substitutes for exact-head evidence.
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
