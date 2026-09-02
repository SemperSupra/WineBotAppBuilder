# WBAB Retirement Plan

Status: **Cooling off / feature-frozen**  
Cooling-off start: **2026-09-02**  
Earliest archive review: **2026-09-16**  
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

### Phase 1 — freeze and make intent durable — COMPLETE

The retirement plan, README notice, retired backlog, and #58 disposition are on `main`.

### Phase 2 — inventory and harvest — COMPLETE

- Accessible organization/personal repositories were searched for executable and documentation dependencies.
- The evidence taxonomy and infrastructure-retirement lesson were harvested to `SemperSupra/engineering-governance-private` ADR 0002.
- `samples/validation-app` is intentionally archived in place unless a future named consumer proves a real need.
- No speculative code migration was performed merely to keep WBAB components active.

### Phase 3 — detach consumers — COMPLETE

The strongest known consumer, `SemperSupra/WinInspect-private`, was detached through PR #366 after exact-head installer-lifecycle validation run `33641873371` passed; the change merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.

WineBot architecture documentation was corrected through `SemperSupra/WineBot#122`, merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.

No other executable WBAB consumer was found in the accessible portfolio inventory.

### Phase 4 — archival preparation — COMPLETE

- #58 P0-P3 truthful corrective baseline landed through PR #63 after exact-head CI and Product Qualification passed.
- Retirement documentation/state landed through PR #64.
- Exact GHCR image-name and release-URL searches found no accessible portfolio consumers.
- Release publication and obsolete manual E2E/policy-trend/TLA workflows were removed through PR #65 after CI passed.
- The retirement policy now fails closed if publication authority reappears.
- Existing historical releases/packages are preserved; no new publication path remains.
- Repository-visible daemon configuration is example-only and contains no committed credentials.

### Phase 5 — cooling-off and archive — ACTIVE

Cooling-off begins **2026-09-02**. The earliest archive review is **2026-09-16**, providing a two-week observation window rather than immediately archiving after dependency removal.

During cooling-off:

- do not develop new features;
- do not publish new releases/images;
- retain ordinary CI and Product Qualification as safety nets for a consequential retirement/security fix;
- retain issue/PR participation controls;
- treat any legitimate attempt to depend on WBAB as new evidence that must be evaluated against the resurrection criterion;
- otherwise make no changes merely to keep the project active.

At or after 2026-09-16, archive the repository if all of the following remain true:

1. no new live consumer or dependency has surfaced;
2. no retirement/security fix demonstrates a unique WBAB capability that lacks a successor;
3. publication remains disabled;
4. issue #61 is the only remaining active retirement tracker or is ready to close;
5. the completion criteria below remain satisfied.

If a real dependency appears, do not broadly revive WBAB. Open a bounded exception under #61 and test the narrow capability against the preferred successor architecture.

## Completion criteria

Retirement is ready for archive when:

- no live external development, CI, release, or runtime workflow depends on WBAB;
- no repository imports WBAB as a required submodule, Action, or tool;
- useful code/concepts have an identified successor owner or an explicit archive-in-place decision;
- replacement workflows have run successfully against real targets;
- no documentation recommends WBAB for new adoption;
- no WBAB-published image/release is required by another project;
- new WBAB publication is disabled;
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
- Preserve historical releases/packages unless there is a separate reason to remove them.
- Prefer links to successor repositories over duplicated documentation.
- Do not spend retirement effort improving abstractions that have no remaining consumer.
