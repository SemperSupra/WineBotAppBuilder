# Project State

**Current date:** 2026-09-02  
**Current program:** issue #61 — retire WBAB and migrate remaining capabilities  
**Status:** feature-frozen / retiring  
**Current integration candidate:** PR #63, head `461c2704586a8bcb5d876be30322cb19bff52a60`

## Current status

WBAB is no longer an expanding product/platform. The portfolio red-team concluded that its remaining unique value does not justify maintaining a standalone build/orchestration system.

The #58 corrective work remains important because it leaves the historical implementation truthful rather than fixture-driven or overstated. P0 through P3 are complete on exact stacked head `461c2704586a8bcb5d876be30322cb19bff52a60` and are being integrated through non-draft replacement PR #63.

P4 / `RELEASE_QUALIFICATION` is **cancelled as WBAB product-development work**. No current claim is made that exact published release images/artifacts have been qualified as a release set.

## Retirement evidence already completed

- WinInspect WBAB submodule removed through `SemperSupra/WinInspect-private#366` after exact-head installer-lifecycle run `33641873371` passed; merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through `SemperSupra/WineBot#122`; merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lessons harvested to `SemperSupra/engineering-governance-private` ADR 0002 through PR #136; merged as `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- First-pass repository inventory found no other executable WBAB consumer.
- Superseded WBAB expansion issues have been closed as not planned.

## Final corrective integration

Original PRs #59/#60 were stacked. PR #60 remains draft, and the connected ready-for-review mutation is currently broken by a connector GraphQL schema defect. GitHub's REST merge correctly refuses a draft PR.

To avoid bypassing GitHub safeguards or requiring manual UI toil, replacement PR #63 presents the exact combined stacked head directly against `main` as a non-draft integration candidate.

Required evidence before #63 merge:

1. fresh ordinary CI on exact head `461c2704586a8bcb5d876be30322cb19bff52a60`;
2. fresh Product Qualification on that exact head;
3. mergeability and no unresolved review/change-request blockers;
4. exact-head guarded merge.

Fresh runs opened for #63:

- CI `33643641548`;
- Product Qualification `33643641313`.

Do not merge #63 until both are terminal PASS.

## Preserved evidence vocabulary

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

A weaker class never implies a stronger class. Strong claims bind to the exact candidate/artifact that actually executed.

## Retirement branch

`retirement/wbab-retirement-final` is based directly on the exact #63 candidate and contains the retirement-only state that should follow the corrective integration:

- `RETIREMENT.md`;
- retirement-first `README.md`;
- `docs/RETIREMENT-INVENTORY.md`;
- retirement-oriented `docs/STATE.md`, `AGENTS.md`, and `docs/CONTEXT_BUNDLE.md`;
- final backlog/workflow/publication cleanup as it is proven safe.

After #63 merges, open or retarget the final retirement delta against the resulting `main`; it should contain only retirement changes.

## Current authority boundary

Allowed without new WBAB product authority:

- retirement/migration documentation;
- dependency/reference cleanup with replacement evidence;
- closing superseded feature work;
- disabling no-longer-needed CI/publication surfaces after confirming no consumer depends on them;
- preserving/moving demonstrated-useful lessons;
- exact-head verification and guarded repository merges.

Stop for:

- new product/platform feature development;
- release publication or production signing;
- destructive history rewrites;
- deletion of historical evidence;
- newly discovered live consumer whose replacement path has not been proven;
- unresolved licensing/security/credential boundaries.

## Next bounded actions

1. Observe fresh #63 CI and Product Qualification.
2. If both PASS and the PR remains clean, exact-head squash-merge #63 to `main`.
3. Close #59/#60 as superseded integration scaffolding and close/complete #58 with exact evidence.
4. Open the prepared `retirement/wbab-retirement-final` branch against the new `main`; supersede old retirement PR #62.
5. Validate the retirement-only delta and merge it.
6. Check release/image consumers and disable publication/optional workflows that no longer protect retirement invariants.
7. Enter cooling-off period; archive only after #61 completion criteria are satisfied.
