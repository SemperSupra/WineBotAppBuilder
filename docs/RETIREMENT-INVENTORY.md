# WBAB Retirement Dependency Inventory

Status: **first-pass inventory complete; archival verification continues**

Authoritative retirement tracker: #61

This inventory records accessible repository references to WineBotAppBuilder and classifies whether they are live dependencies or historical/documentation references. A repository name or architecture mention alone is not treated as a live dependency.

## Confirmed references and disposition

| Repository | Reference | Classification | Disposition / evidence |
| --- | --- | --- | --- |
| `SemperSupra/WinInspect-private` | former `.gitmodules` entry `external/WineBotAppBuilder` | former build/development dependency | **Detached.** PR #366 removed the gitlink and `.gitmodules` stanza after exact-head installer-lifecycle run `33641873371` succeeded. Merged to `master` as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`. |
| `SemperSupra/WineBot` | architecture documentation listed WBAB as active build toolchain/ecosystem component | documentation / architecture | **Corrected.** PR #122 identifies WBAB as retiring/reference-only and assigns successor ownership. Merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`. |
| `SemperSupra/WineBotAppBuilder` | self-references across code/docs/workflows | project-internal | Retain only as needed for truthful retirement state, migration evidence, and historical intelligibility. |

## Search results

The retirement red-team and implementation pass searched indexed SemperSupra and relevant personal-repository code for:

- `WineBotAppBuilder`
- `WBAB` / `wbab`
- `external/WineBotAppBuilder`
- known submodule/repository URLs
- reusable workflow/action references
- Delphi-specific motivation/requirements

Indexed SemperSupra search found only the WineBot architecture reference outside WBAB itself. Indexed personal-repository search found no WBAB references. Separately, the private WinInspect submodule was verified directly and removed through PR #366.

Code-search absence is negative evidence, not proof that every historical/private branch has no reference. Any newly surfaced repository or workflow that claims a WBAB dependency must be checked before archive.

## Original-motivation check

Repository code search did not find Delphi-specific requirements in WBAB or the broader indexed SemperSupra codebase. The original legacy/licensed-Windows motivation is therefore not represented as a durable WBAB requirement today.

The replacement path for that class of problem is:

1. native product build/test/package in the product repository;
2. hosted Windows runner where the toolchain is installable ephemerally;
3. controlled persistent/licensed Windows runner or VM when licensing/legacy installation requires it;
4. WinBot only when native Windows interactive/GUI automation is actually required;
5. WineBot when Wine runtime/compatibility qualification is required; and
6. Windows Package Foundry for reusable release/trust/distribution mechanics.

## WinInspect replacement evidence

Before detachment, WinInspect already performed native Windows build/test directly on `windows-latest`, including CMake/CTest and local smoke validation, while its full matrix packaged with NSIS.

The bounded detachment branch removed only WBAB's gitlink and `.gitmodules` stanza. Exact-head installer-lifecycle run `33641873371` succeeded on head `76680cccbfef8fb12279b88c72de3e5f6d3cee16` before merge. The change then merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.

This is direct evidence that WinInspect no longer requires WBAB for its packaged installer lifecycle.

## Current WBAB integration state

The #58 corrective work is being landed through replacement non-draft integration PR #63 because the connected ready-for-review mutation for stacked PR #60 is broken by a GitHub connector GraphQL schema defect.

PR #63 uses exact stacked head `461c2704586a8bcb5d876be30322cb19bff52a60`. Fresh ordinary CI and Product Qualification are required on that exact candidate before merge. P4/release qualification is not part of retirement and is cancelled as WBAB product work.

## Classification scheme

- **runtime dependency** — required while the product/application runs;
- **build dependency** — required to produce product artifacts;
- **test/qualification dependency** — required only for validation;
- **documentation/architecture** — descriptive reference, not executable;
- **stale reference** — no longer used and safe to remove after bounded verification.

## Detachment gate

A dependency is removable when:

1. its actual purpose is identified;
2. the successor path executes against a real target;
3. evidence identifies exact source/artifact identities where material;
4. removal does not silently lower the qualification claim; and
5. downstream durable docs/workflows no longer direct humans or agents back to WBAB.

## First-pass conclusion

No live WBAB consumer remains in the references found so far. The only concrete downstream code dependency found—WinInspect's submodule—has been removed with replacement evidence, and the only indexed external architecture reference found—WineBot—has been corrected.

This is sufficient to proceed with archival preparation, but not yet sufficient to archive the repository. Publication/image consumers and operational configuration still need an explicit final check after the truthful #58 stack is landed.

## Inventory completion condition

The inventory can be declared final when:

- #63 has landed or the #58 stack has otherwise been explicitly disposed;
- retirement state has landed against the resulting `main`;
- no newly surfaced accessible repository/workflow claims an executable WBAB dependency;
- WBAB release/image publication consumers have been checked; and
- each retained reusable lesson/capability has either a successor owner or an explicit archive-in-place decision linked from #61.
