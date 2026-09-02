# WBAB Retirement Plan

Status: **Retiring / feature-frozen**

Authoritative tracker: #61

## Decision

WineBotAppBuilder (WBAB) is being retired as a standalone build/orchestration platform.

The original problem remains legitimate: some Windows applications, especially legacy or licensed toolchains, need deterministic automation in CI or controlled Windows environments. The portfolio now has narrower, better-aligned owners for the capabilities that proved useful, while WBAB accumulated substantial orchestration and infrastructure surface beyond the unique value it still provides.

This is a retirement, not a deletion. Git history, useful qualification lessons, and reusable components are preserved or moved to their natural owners before archival.

## Scope freeze

Effective 2026-09-02:

- no new WBAB product/platform features;
- no dashboard, discovery, daemon-scaling, dependency-vending, cloud-lab, publisher, or generalized orchestration expansion;
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
| Evidence taxonomy / exact-artifact qualification discipline | Portfolio engineering governance / product and Foundry validation |
| CI scheduling, retries, concurrency, logs, artifacts | GitHub Actions or the selected CI provider |

## Retirement phases

### Phase 1 — freeze and make intent durable

1. Publish this plan and issue #61.
2. Put the retirement notice at the top of the README.
3. Stop feature-roadmap work and close superseded expansion issues as not planned.
4. Finish only the already-earned #58 corrective work needed to leave WBAB truthful.

### Phase 2 — inventory and harvest

1. Search accessible organization/personal repositories for imports, submodules, workflow calls, scripts, documentation, and stale references.
2. Classify each reference as runtime, build, test/qualification, documentation, or stale.
3. Harvest demonstrated-useful lessons/capabilities into named successor owners.
4. Do not copy code merely because it exists; require a consumer or durable lesson.

### Phase 3 — detach consumers

The strongest known consumer, `SemperSupra/WinInspect-private`, has been detached. PR #366 removed the WBAB submodule after exact-head installer-lifecycle validation run `33641873371` passed; the change merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.

WineBot's architecture documentation was then corrected in `SemperSupra/WineBot#122`, merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.

No other executable WBAB consumer was found in the first-pass indexed repository search.

### Phase 4 — archival preparation

1. Land the completed #58 truthfulness stack through the replacement integration PR #63.
2. Reconcile retirement state against that truthful `main`.
3. Disable optional/scheduled/expensive WBAB workflows that no longer protect a migration or archival invariant.
4. Stop publication of WBAB images/releases after confirming no consumer requires them.
5. Remove/revoke operational configuration or credentials no longer required, without destroying historical evidence.
6. Record last-known-good source/release identities and successor paths.
7. Make README, STATE, AGENTS, and backlog/status material accurately describe retirement.

### Phase 5 — cooling-off and archive

After the last consumer is detached and archival preparation is complete, leave the repository unarchived but feature-frozen for one or two normal development cycles. Treat any attempted return to WBAB during this period as evidence: either the replacement architecture is missing a real capability or the caller should use the established successor path.

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

A narrowly scoped successor capability may be created or restored only if a named real application is materially easier, safer, or otherwise infeasible using:

1. product-local GitHub Actions;
2. native Windows hosted runner or controlled licensed Windows runner/VM as appropriate;
3. WinBot when native interactive GUI automation is required;
4. WineBot when Wine compatibility/runtime qualification is required; and
5. Windows Package Foundry for reusable release/trust/distribution mechanics.

The validation sample, architectural elegance, or a hypothetical future consumer is not sufficient evidence.

## Preserved lessons

The #58 corrective work established evidence classes that remain useful beyond WBAB:

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

A weaker class never implies a stronger one. A PASS belongs to the exact candidate/artifact that actually executed.

The broader portfolio lesson is recorded in `SemperSupra/engineering-governance-private` ADR 0002, merged through PR #136.

## Preservation rules

- Preserve Git history.
- Preserve the rationale and red-team findings.
- Preserve exact evidence needed to understand the final working state.
- Prefer links to successor repositories over duplicated documentation.
- Do not spend retirement effort improving abstractions that have no remaining consumer.
