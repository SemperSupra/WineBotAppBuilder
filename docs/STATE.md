# Project State

**Current date:** 2026-09-02  
**Current program:** issue #61 — retire WBAB and migrate remaining capabilities  
**Status:** archival preparation / feature-frozen  
**Retirement baseline on main:** `d2de132e05bb0f86b01d87a1cdbb70d0c1333bb7`

## Final truthful product baseline

The #58 P0-P3 corrective work was validated on exact candidate `461c2704586a8bcb5d876be30322cb19bff52a60`:

- ordinary CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

PR #63 squash-merged that work to `main` as `5ef09847de2770c2619592453d372f42dcf97eed`. Issue #58 is closed completed. P4 / `RELEASE_QUALIFICATION` is not pursued as WBAB product development.

PR #64 then landed the retirement plan/state/documentation as `d2de132e05bb0f86b01d87a1cdbb70d0c1333bb7`.

## Consumer/migration evidence

- WinInspect detached through `SemperSupra/WinInspect-private#366` after exact-head installer-lifecycle run `33641873371` passed; merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through `SemperSupra/WineBot#122`; merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lessons harvested to engineering-governance-private ADR 0002 through PR #136; merged as `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- First-pass indexed repository search found no other executable WBAB consumer.

## Publication consumer check

The historical release workflow publishes these GHCR image names:

- `winebotappbuilder-winbuild`
- `winebotappbuilder-packager`
- `winebotappbuilder-signer`
- `winebotappbuilder-linter`

Exact-name searches across accessible SemperSupra and `mark-e-deyoung` repositories found no consumers of any of the four image names. Searches for `WineBotAppBuilder/releases` likewise found no portfolio consumer.

The current GitHub release list contains one historical release:

- tag: `v0.3.7`;
- published: 2026-02-18;
- asset: `ValidationSetup.exe`;
- asset SHA-256: `087fd9892ecf83806c365be8cd5965cca995f94b4bb588972411a80f94f69492`;
- recorded download count at retirement check: 1.

This is sufficient negative evidence to stop **new** WBAB publication. Existing releases/packages are preserved as historical state rather than deleted.

## Current archival shutdown branch

`retirement/disable-publication` removes four workflow files that no longer protect an active retirement invariant:

- `.github/workflows/release.yml` — stops new GitHub Release and GHCR publication;
- `.github/workflows/e2e-real.yml` — obsolete opt-in infrastructure-smoke workflow;
- `.github/workflows/policy-preflight-trend-gate-optin.yml` — obsolete manual policy-trend workflow;
- `.github/workflows/tla-skeleton-contract-optin.yml` — obsolete manual formal-contract workflow.

Cooling-off safety surfaces intentionally retained:

- `.github/workflows/ci.yml`;
- `.github/workflows/product-qualification.yml`;
- approved-issue and approved-PR participation controls.

## Preserved evidence vocabulary

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

A weaker class never implies a stronger class. Strong claims bind to the exact candidate/artifact that actually executed.

## Remaining authority boundary

Allowed:

- merge the bounded publication/workflow shutdown after repository validation;
- document final release/source identities;
- verify visible configuration references;
- enter cooling-off;
- archive after #61 completion criteria remain satisfied.

Do not:

- add new WBAB platform/product features;
- publish a new release merely as a retirement marker;
- delete historical releases/packages/evidence without a separate reason;
- use production signing credentials;
- perform destructive history rewrites.

Actual GitHub secret values/configuration cannot be enumerated through the available connector. Removal of the publication workflow eliminates the repository path that consumes `GITHUB_TOKEN` with package/content write permissions; no separate secret material is identified in the workflow.

## Next bounded actions

1. Open and validate the publication/workflow shutdown PR.
2. Merge it if exact changed files and CI are clean.
3. Update issue #61 completion checklist with the publication-consumer result and workflow shutdown.
4. Verify no remaining repository-visible config points to active WBAB deployment/publication.
5. Enter cooling-off; archive only after the agreed observation period and completion criteria are satisfied.
