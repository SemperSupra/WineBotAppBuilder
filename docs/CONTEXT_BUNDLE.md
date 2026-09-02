# CONTEXT_BUNDLE (read this first)

## Current milestone

**WBAB archival preparation — issue #61.**

WBAB is feature-frozen and retiring. Do not resume historical feature-roadmap work.

## Durable authority

Read in this order:

1. `RETIREMENT.md`
2. issue #61
3. `docs/STATE.md`
4. `docs/RETIREMENT-INVENTORY.md`
5. the bounded retirement PR being executed

## Landed baselines

Final truthful product candidate before retirement:

`461c2704586a8bcb5d876be30322cb19bff52a60`

Exact evidence:

- CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

PR #63 squash-merged the corrective work as `5ef09847de2770c2619592453d372f42dcf97eed`.

PR #64 then landed the retirement plan/state/documentation as `d2de132e05bb0f86b01d87a1cdbb70d0c1333bb7`.

Issue #58 is complete. P4/release qualification is not WBAB retirement work.

## Completed migrations / harvested value

- WinInspect detached through PR #366 after installer-lifecycle run `33641873371` passed; merge `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through PR #122; merge `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lesson harvested to engineering-governance-private ADR 0002 through PR #136; merge `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- `samples/validation-app` disposition: archive in place unless a future named consumer proves a real need.

## Publication consumer result

The historical release workflow published:

- `winebotappbuilder-winbuild`
- `winebotappbuilder-packager`
- `winebotappbuilder-signer`
- `winebotappbuilder-linter`

Exact-name searches across accessible SemperSupra and `mark-e-deyoung` repositories found no consumers. Searches for WBAB release URLs found none.

The final public release observed during retirement is `v0.3.7` (2026-02-18), with one `ValidationSetup.exe` asset, SHA-256 `087fd9892ecf83806c365be8cd5965cca995f94b4bb588972411a80f94f69492`, recorded download count 1.

No active portfolio dependency on the release asset or GHCR images was found.

## Current bounded work

Branch: `retirement/disable-publication`.

Remove obsolete operational workflows:

- release publication;
- opt-in real-E2E infrastructure smoke;
- opt-in policy-trend diagnostics;
- opt-in TLA/formal contract workflow.

Retain through cooling-off:

- ordinary CI;
- candidate Product Qualification for any consequential product-path fix;
- approved-issue / approved-PR participation controls.

Existing GitHub releases/packages are preserved; the change stops future publication rather than deleting history.

## Evidence classes retained

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

Never promote a weaker class into a stronger claim.

## Next bounded sequence

1. Open and inspect the operational-shutdown PR.
2. Validate workflow removal and retained safety surfaces.
3. Merge when clean.
4. Update #61 with publication shutdown and final identities.
5. Check remaining repository-visible deploy/config references for active operational dependency.
6. Enter cooling-off.
7. Archive only after the agreed observation period and #61 completion criteria remain satisfied.

## Stop conditions

Stop before:

- new WBAB product/platform development;
- new release publication or production signing;
- destructive history rewrites or deletion of historical evidence;
- removing a newly surfaced live dependency without replacement evidence;
- credential/licensing/security changes beyond retirement authority.
