# CONTEXT_BUNDLE (read this first)

## Current milestone

**WBAB cooling-off — issue #61.**

WBAB is feature-frozen and operationally retired as a standalone build/orchestration platform. Do not resume historical feature-roadmap work merely because an agent or human is told to `continue`.

Cooling-off start: **2026-09-02**  
Earliest archive review: **2026-09-16**

## Durable authority

Read in this order:

1. `RETIREMENT.md`
2. issue #61
3. `docs/STATE.md`
4. `docs/RETIREMENT-INVENTORY.md`
5. a bounded retirement/security issue or PR, if one exists

If those sources show no bounded work before the archive gate, continuation means preserve the frozen state rather than invent implementation work.

## Landed baselines

Final truthful product candidate before retirement:

`461c2704586a8bcb5d876be30322cb19bff52a60`

Exact evidence:

- CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

PR #63 squash-merged the corrective work as `5ef09847de2770c2619592453d372f42dcf97eed`.

PR #64 landed the retirement plan/state/documentation as `d2de132e05bb0f86b01d87a1cdbb70d0c1333bb7`.

PR #65 stopped new WBAB GitHub Release/GHCR publication and removed obsolete manual E2E, policy-trend, and TLA workflows. Its first CI run correctly failed because the old policy still required `release.yml`; the policy was corrected to enforce publication shutdown in retirement mode. Exact final head `b54e2fb884841c861bc1435b8e60e414d4239c22` passed CI `33645926658` and squash-merged as `0171d20b9847d0e599dbf7ddb122cbd96bdc8b6b`.

Issue #58 is closed completed. P4/release qualification is not WBAB retirement work.

## Completed migrations / harvested value

- WinInspect detached through PR #366 after installer-lifecycle run `33641873371` passed; merge `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through PR #122; merge `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lesson harvested to engineering-governance-private ADR 0002 through PR #136; merge `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- `samples/validation-app` disposition: archive in place unless a future named consumer proves a real need.
- Accessible repository inventory found no other executable WBAB consumer.

## Publication / operational shutdown result

The historical release workflow published:

- `winebotappbuilder-winbuild`
- `winebotappbuilder-packager`
- `winebotappbuilder-signer`
- `winebotappbuilder-linter`

Exact-name searches across accessible SemperSupra and `mark-e-deyoung` repositories found no consumers. Searches for WBAB release URLs found none.

The final public release observed during retirement is `v0.3.7` (2026-02-18), with one `ValidationSetup.exe` asset, SHA-256 `087fd9892ecf83806c365be8cd5965cca995f94b4bb588972411a80f94f69492`, recorded download count 1.

New publication is disabled; historical releases/packages remain preserved.

Repository-visible `deploy/daemon` material is example configuration only. It references external token/key/cert file paths and contains no committed credential material. Current workflow code search found no remaining `secrets.*` reference.

## Workflow surface during cooling-off

Only four GitHub workflows remain on `main`:

- `approved-issues-only.yml`;
- `approved-prs-only.yml`;
- `ci.yml`;
- `product-qualification.yml`.

There is no release publisher, GHCR registry-login workflow, scheduled diagnostic workflow, or manual formal/E2E workflow.

The retirement-aware release policy fails closed if publication authority reappears, including `release.yml`, `packages: write`, registry login, `gh release create/upload`, or push-to-registry behavior.

## Evidence classes retained

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

Never promote a weaker class into a stronger claim. Strong evidence belongs to the exact candidate/artifact that executed.

## Cooling-off rule

Until **2026-09-16**:

- do not add WBAB features;
- do not publish releases/images;
- make only security-critical or retirement-integrity fixes;
- use retained CI/Product Qualification when the changed claim warrants it;
- treat any newly surfaced real WBAB dependency as evidence and evaluate it against the resurrection criterion;
- otherwise make no repository change merely to keep work moving.

At or after **2026-09-16**, perform the archive-gate review. Archive if:

1. no new live consumer/dependency surfaced;
2. no security/retirement fix demonstrated a unique WBAB capability lacking a successor;
3. publication remains disabled;
4. issue #61 completion criteria remain satisfied;
5. no repository state again recommends WBAB for new adoption.

If a real dependency appears, do not broadly revive WBAB. Open a bounded exception under #61 and test the narrow need against the preferred successor architecture in `RETIREMENT.md`.

## Next bounded action

No implementation action is currently justified. The next planned action is the **archive-gate review on or after 2026-09-16**, unless a real dependency or security signal appears sooner.

## Stop conditions

Stop before:

- new WBAB product/platform development;
- new release publication or production signing;
- destructive history rewrites or deletion of historical evidence;
- removing a newly surfaced live dependency without replacement evidence;
- credential/licensing/security changes beyond retirement authority.
