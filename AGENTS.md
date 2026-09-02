# Agent Playbook (AGENTS.md)

This repository is **feature-frozen and retiring**. Durable repository/GitHub state is authoritative.

## Start here

1. `RETIREMENT.md`
2. issue #61 — authoritative retirement tracker
3. `docs/STATE.md`
4. the bounded retirement/migration issue or PR
5. `docs/RETIREMENT-INVENTORY.md`
6. `docs/CONTEXT_BUNDLE.md` only when broader historical context is required

Do not treat historical feature plans, backlog items, or architecture documents as current authority.

## Retirement invariant

Do **not** add or expand WBAB as a general build/orchestration platform.

Allowed work is limited to:

- migration/detachment of real consumers;
- truthful final-state corrections;
- security-critical fixes required during the retirement window;
- removal/disablement of operational surfaces no longer required;
- preservation or transfer of demonstrated-useful capability/lessons;
- evidence required to prove retirement completion.

A capability may be revived only under the resurrection criterion in `RETIREMENT.md`: a named real application must be materially easier, safer, or otherwise infeasible using the preferred successor stack.

## Preferred successor stack

- product-specific native Windows build/test/package -> product-local GitHub Actions;
- reusable Windows release/trust/distribution -> `SemperSupra/windows-package-foundry`;
- native Windows interactive/GUI automation -> `mark-e-deyoung/WinBot`;
- persistent licensed/legacy Windows build environment -> controlled Windows runner/VM, with WinBot only if interactive automation is required;
- Wine compatibility/runtime validation -> `SemperSupra/WineBot`;
- shared WineBot/WinBot contracts -> `mark-e-deyoung/winebot-contracts`.

Do not create a new WBAB adapter when one of these owners already fits the requirement.

## Global invariants

- No secrets or private keys committed to the repo.
- Respect `ORGANIZATION_POLICY.md` and `LINT_POLICY.md` where still applicable.
- Keep `main` truthful; do not claim a PASS that did not execute against the exact candidate discussed.
- Preserve unknowns. Mock/static evidence must not be upgraded into real product evidence.
- Replacement evidence must exist before removing a live dependency or validator that protects a still-relevant claim.
- Preserve Git history and consequential retirement evidence.
- Do not spend retirement effort improving abstractions that have no remaining consumer.

## Evidence vocabulary retained from #58

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with one or more material boundaries simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime, incomplete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical plus independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts identified immutably and qualified.

A weaker class never implies a stronger class.

The #58 Product Qualification path is preserved as historical final-state evidence. P4/release qualification is not a new WBAB roadmap item.

## Final corrective baseline

The completed P0-P3 corrective stack was validated on exact head `461c2704586a8bcb5d876be30322cb19bff52a60`:

- CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

Replacement PR #63 squash-merged this candidate to `main` as `5ef09847de2770c2619592453d372f42dcf97eed`.

Original stacked PRs #59/#60 are historical/superseded integration scaffolding. Do not resume them.

## Validation during retirement

Use the cheapest faithful validator for the claim changed.

Documentation-only retirement changes do not need Product Qualification merely because that workflow exists. Product-path changes should be avoided; if a retirement/security change does alter a product claim, validate at the appropriate evidence class and exact candidate.

Ordinary repository validators remain available for bounded verification:

```bash
./scripts/lint.sh
./tests/shell/run.sh
./tests/contract/run.sh
./tests/policy/run.sh
```

Higher-fidelity historical paths:

```bash
./tests/e2e/product-qualification.sh
./tests/e2e/run-real.sh
```

Do not run expensive validation for appearance's sake.

## PR / retirement evidence checklist

- [ ] Exact candidate/head SHA identified when material.
- [ ] Change is retirement/migration/security/final-truth work, not new platform development.
- [ ] Any live consumer removal has a proven successor path.
- [ ] Evidence class is stated truthfully.
- [ ] Result is written back to durable GitHub/repository state.
- [ ] `docs/STATE.md` and `docs/RETIREMENT-INVENTORY.md` are updated when current retirement state materially changes.
- [ ] No release/publication/production-signing authority is implied.

## Current next action

Work from `retirement/wbab-retirement-main`, which is based on corrected `main` and carries the retirement-only documentation/state delta. After that delta lands, verify release/GHCR consumers and disable unnecessary publication/optional workflows before cooling-off.

## Interruption / resumption

If retirement work stops before completion, leave durable state sufficient for the next capable human or agent to resume without transcript archaeology:

- objective and authoritative issue (#61 unless a narrower work item applies);
- exact branch/head/candidate when material;
- completed vs unexecuted validation;
- durable evidence/artifacts;
- newly discovered consumer or blocker;
- next safe bounded action.

A bare `continue` is a resume trigger. Resume from durable repository state rather than recreating the historical WBAB roadmap.
