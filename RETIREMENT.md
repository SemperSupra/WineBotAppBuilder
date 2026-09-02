# WBAB Retirement Plan

Status: **Retiring / feature-frozen**

Authoritative tracker: #61

## Decision

WineBotAppBuilder (WBAB) is being retired as a standalone build/orchestration platform.

The original problem remains legitimate: some Windows applications, especially legacy or licensed toolchains, need deterministic automation in CI or controlled Windows environments. The portfolio now has narrower, better-aligned owners for the capabilities that proved useful, while WBAB accumulated substantial orchestration and infrastructure surface beyond the unique value it still provides.

This is a retirement, not a deletion. Git history, useful qualification lessons, and reusable components should be preserved or moved to their natural owners before archival.

## Scope freeze

Effective immediately:

- no new WBAB product/platform features;
- no dashboard, discovery, daemon-scaling, dependency-vending, or generalized orchestration expansion;
- no refactoring whose primary purpose is to make WBAB a cleaner general platform;
- allowed work is limited to retirement/migration, security-critical corrections, truthful final-state documentation, and extraction of uniquely useful capability required by a named real consumer.

A proposed exception must identify the real consumer, the capability it requires, the cheaper alternatives considered, and why the exception is necessary for retirement or migration.

## Capability successor map

| WBAB capability/problem | Successor / preferred owner |
| --- | --- |
| Product-specific native Windows build/test | Product-local GitHub Actions on native Windows runners |
| Reusable Windows package/release/trust/distribution helpers | `SemperSupra/windows-package-foundry` |
| Native Windows interactive/GUI automation | `mark-e-deyoung/WinBot` |
| Persistent licensed/legacy Windows toolchains | Controlled Windows runner/VM; use WinBot only when interactive automation is actually required |
| Wine runtime/compatibility validation | `SemperSupra/WineBot` |
| Shared WineBot/WinBot API/conformance semantics | `mark-e-deyoung/winebot-contracts` |
| CMake/MinGW/NSIS product build semantics | Product repository unless demonstrated reuse justifies a small reusable helper |
| Evidence taxonomy / exact-artifact qualification discipline | Portfolio Way of Work / validation governance; apply in product and Foundry workflows |
| CI scheduling, retries, concurrency, logs, artifacts | GitHub Actions or the selected CI provider |

## Retirement phases

### Phase 1 — freeze and make intent durable

1. Publish this plan and issue #61.
2. Add a retirement notice to the README.
3. Update durable project state so humans and agents do not mistake WBAB for an expanding platform.
4. Reconcile issue #58: retain only work that makes final state truthful, preserves qualification lessons, or supports migration.

### Phase 2 — inventory and harvest

1. Search all accessible organization/personal repositories for WBAB imports, submodules, workflow calls, scripts, documentation, and stale references.
2. Classify each reference as runtime, build, test, documentation, or stale.
3. Harvest only demonstrated-useful capabilities into named successor owners.
4. Decide the disposition of `samples/validation-app`: migrate as a useful fixture or archive it in place.
5. Do not copy code merely because it exists; require a consumer or durable lesson.

### Phase 3 — detach consumers

WinInspect is the first known consumer to detach.

1. Verify that its native Windows CI/release path builds, tests, packages, and exercises the installer without WBAB.
2. Record the replacement evidence.
3. Remove the WBAB submodule/reference once replacement evidence is sufficient.
4. Repeat for any other live dependency found by the inventory.

### Phase 4 — archival preparation

1. Disable optional/scheduled/expensive WBAB workflows that no longer protect a migration or archival invariant.
2. Stop publication of WBAB images/releases when no consumer needs them.
3. Remove/revoke operational configuration and credentials that are no longer required, without destroying historical evidence.
4. Record last-known-good source/release identities.
5. Make README, STATE, AGENTS, and backlog/status material accurately describe retirement and successor systems.

### Phase 5 — cooling-off and archive

After the last consumer is detached, leave the repository unarchived but feature-frozen for one or two normal development cycles. Treat any attempted return to WBAB during this period as evidence: either the replacement architecture is missing a real capability or the caller should use the established successor path.

Archive the GitHub repository when the completion criteria below are met.

## Completion criteria

Retirement is complete when:

- no live development, CI, release, or runtime workflow requires WBAB;
- no repository imports WBAB as a required submodule, Action, or tool;
- useful code/concepts have an identified successor owner or an explicit archive-in-place decision;
- replacement workflows have run successfully against real targets;
- no documentation recommends WBAB for new adoption;
- no WBAB-published image/release is required by another project;
- final project documentation explains why WBAB existed, what was learned, what replaced it, and how narrowly scoped resurrection would be justified.

## Resurrection criterion

Do **not** revive WBAB as a general platform.

A narrowly scoped successor capability may be created or restored only if a named real application is materially easier, safer, or otherwise infeasible using the normal portfolio path:

1. product-local GitHub Actions;
2. native Windows hosted runner or controlled licensed Windows runner/VM as appropriate;
3. WinBot when native interactive GUI automation is required;
4. WineBot when Wine compatibility/runtime qualification is required; and
5. Windows Package Foundry for reusable release/trust/distribution mechanics.

The validation sample, architectural elegance, or a hypothetical future consumer is not sufficient evidence.

## Preservation rules

- Preserve Git history.
- Preserve the rationale and red-team findings.
- Preserve exact evidence needed to understand the final working state.
- Prefer links to successor repositories over duplicated documentation.
- Do not spend retirement effort improving abstractions that have no remaining consumer.

## Current first consumer migration

`SemperSupra/WinInspect-private` currently carries WBAB as `external/WineBotAppBuilder`. Its native Windows workflows already provide a candidate replacement path. Retirement work should prove that path is sufficient and then remove the stale dependency in a bounded WinInspect change.
