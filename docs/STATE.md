# Project State

**Current date:** 2026-09-02  
**Current program:** issue #61 — retire WBAB and migrate remaining capabilities  
**Status:** feature-frozen / retiring  
**Final corrective baseline on main:** `5ef09847de2770c2619592453d372f42dcf97eed`

## Current status

WBAB is no longer an expanding product/platform. The portfolio red-team concluded that its remaining unique value does not justify maintaining a standalone build/orchestration system.

The #58 corrective work was completed because it leaves the historical implementation truthful rather than fixture-driven or overstated. P0 through P3 were validated on exact candidate head `461c2704586a8bcb5d876be30322cb19bff52a60` and integrated through replacement PR #63.

Fresh pre-merge evidence for #63:

- ordinary CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

PR #63 squash-merged to `main` as `5ef09847de2770c2619592453d372f42dcf97eed`.

P4 / `RELEASE_QUALIFICATION` is **cancelled as WBAB product-development work**. No claim is made that exact published release images/artifacts were qualified as a release set.

## Retirement evidence completed

- WinInspect WBAB submodule removed through `SemperSupra/WinInspect-private#366` after exact-head installer-lifecycle run `33641873371` passed; merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through `SemperSupra/WineBot#122`; merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lessons harvested to `SemperSupra/engineering-governance-private` ADR 0002 through PR #136; merged as `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- First-pass repository inventory found no other executable WBAB consumer.
- Superseded WBAB expansion issues have been closed as not planned.
- Original stacked PRs #59/#60 and old retirement PR #62 have been closed as superseded.

## Preserved evidence vocabulary

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

A weaker class never implies a stronger class. Strong claims bind to the exact candidate/artifact that actually executed.

## Current retirement branch

`retirement/wbab-retirement-main` is based directly on corrected `main` commit `5ef09847de2770c2619592453d372f42dcf97eed` and contains the retirement-only state intended to land next:

- `RETIREMENT.md`;
- retirement-first `README.md`;
- `docs/RETIREMENT-INVENTORY.md`;
- retirement-oriented `docs/STATE.md`, `AGENTS.md`, and `docs/CONTEXT_BUNDLE.md`;
- retired `BACKLOG.md`;
- further publication/workflow cleanup only after consumer checks make it safe.

## Current authority boundary

Allowed without new WBAB product authority:

- retirement/migration documentation;
- dependency/reference cleanup with replacement evidence;
- closing superseded feature work;
- disabling no-longer-needed CI/publication surfaces after confirming no consumer depends on them;
- preserving/moving demonstrated-useful lessons;
- exact-state verification and guarded repository merges.

Stop for:

- new product/platform feature development;
- release publication or production signing;
- destructive history rewrites;
- deletion of historical evidence;
- newly discovered live consumer whose replacement path has not been proven;
- unresolved licensing/security/credential boundaries.

## Next bounded actions

1. Open `retirement/wbab-retirement-main` against `main` and verify it is retirement-only.
2. Run the ordinary validation appropriate to its documentation/governance delta and merge when clean.
3. Close issue #58 as completed/superseded by the final corrective baseline with exact evidence.
4. Check WBAB release/GHCR image consumers and operational configuration.
5. Disable release/image publication and optional workflows that no longer protect a retirement invariant.
6. Update #61 completion checklist and enter cooling-off.
7. Archive only after #61 completion criteria are satisfied.
