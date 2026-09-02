# WBAB Retirement Dependency Inventory

Status: **dependency and publication-consumer inventory complete for accessible portfolio**

Authoritative retirement tracker: #61

This inventory records accessible repository references to WineBotAppBuilder and classifies whether they are live dependencies or historical/documentation references. A repository name or architecture mention alone is not treated as a live dependency.

## Confirmed references and disposition

| Repository | Reference | Classification | Disposition / evidence |
| --- | --- | --- | --- |
| `SemperSupra/WinInspect-private` | former `.gitmodules` entry `external/WineBotAppBuilder` | former build/development dependency | **Detached.** PR #366 removed the gitlink and `.gitmodules` stanza after exact-head installer-lifecycle run `33641873371` succeeded. Merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`. |
| `SemperSupra/WineBot` | architecture documentation listed WBAB as active build toolchain/ecosystem component | documentation / architecture | **Corrected.** PR #122 identifies WBAB as retiring/reference-only and assigns successor ownership. Merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`. |
| `SemperSupra/WineBotAppBuilder` | self-references across code/docs/workflows | project-internal | Preserved only as needed for truthful retirement state and historical intelligibility. |

## Repository dependency search

The retirement red-team searched indexed SemperSupra and relevant personal-repository code for:

- `WineBotAppBuilder`
- `WBAB` / `wbab`
- `external/WineBotAppBuilder`
- known submodule/repository URLs
- reusable workflow/action references
- Delphi-specific motivation/requirements

Indexed SemperSupra search found only the WineBot architecture reference outside WBAB itself. Indexed personal-repository search found no WBAB references. Separately, the private WinInspect submodule was verified directly and removed through PR #366.

Code-search absence is negative evidence, not mathematical proof that every historical/private branch has no reference. Any newly surfaced repository or workflow that claims a WBAB dependency during cooling-off must be checked before archive.

## Publication surface and consumer search

The historical WBAB release workflow publishes four GHCR image names:

- `winebotappbuilder-winbuild`
- `winebotappbuilder-packager`
- `winebotappbuilder-signer`
- `winebotappbuilder-linter`

Exact-name searches across accessible SemperSupra repositories and accessible `mark-e-deyoung` repositories returned no external consumers for any of those four images.

Separate searches for `WineBotAppBuilder/releases` returned no references in either accessible namespace.

The public GitHub release list at the retirement checkpoint contains one release:

- tag `v0.3.7`;
- published 2026-02-18;
- asset `ValidationSetup.exe`;
- asset digest `sha256:087fd9892ecf83806c365be8cd5965cca995f94b4bb588972411a80f94f69492`;
- recorded download count: 1.

No evidence was found that this release asset is an active portfolio dependency.

### Publication disposition

The negative consumer search is sufficient to stop **new** WBAB publication. Retirement does not delete historical release/package state merely to make it disappear.

The archival shutdown branch removes `.github/workflows/release.yml`, eliminating future tag/manual publication of GitHub releases and the four GHCR images.

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

## Final WBAB corrective baseline

The #58 P0-P3 corrective stack was integrated through replacement PR #63 from exact candidate head `461c2704586a8bcb5d876be30322cb19bff52a60`.

Fresh exact-head evidence before merge:

- ordinary CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

PR #63 squash-merged to `main` as `5ef09847de2770c2619592453d372f42dcf97eed`.

P4/release qualification is not part of retirement and is cancelled as WBAB product-development work.

## Operational workflow disposition

During cooling-off, retain only workflows with plausible retirement value:

- ordinary CI;
- candidate Product Qualification for a consequential product-path fix if one becomes necessary;
- issue/PR participation controls.

Remove:

- release publication;
- opt-in real-E2E infrastructure smoke;
- opt-in policy trend diagnostics;
- opt-in TLA/formal contract workflow.

Their historical definitions remain in Git history.

## Inventory conclusion

No live WBAB code, release-asset, or GHCR-image consumer remains in the accessible portfolio evidence found so far.

This satisfies the dependency/publication-consumer portion of archival preparation. The remaining work is to land operational shutdown, verify repository-visible deployment/config references, enter cooling-off, and archive only after the agreed observation period.
