# Project State

**Current date:** 2026-09-02  
**Current program:** issue #61 — retire WBAB and migrate remaining capabilities  
**Status:** cooling off / feature-frozen  
**Current main:** `0171d20b9847d0e599dbf7ddb122cbd96bdc8b6b`  
**Cooling-off start:** 2026-09-02  
**Earliest archive review:** 2026-09-16

## Final truthful product baseline

The #58 P0-P3 corrective work was validated on exact candidate `461c2704586a8bcb5d876be30322cb19bff52a60`:

- ordinary CI `33643641548` — PASS;
- Product Qualification `33643641313` — PASS.

PR #63 squash-merged that work as `5ef09847de2770c2619592453d372f42dcf97eed`. Issue #58 is closed completed. P4 / `RELEASE_QUALIFICATION` is not pursued as WBAB product development.

PR #64 landed the retirement plan/state/documentation as `d2de132e05bb0f86b01d87a1cdbb70d0c1333bb7`.

PR #65 stopped new release/GHCR publication and removed obsolete manual workflows. Its first CI run correctly failed because policy still required `release.yml`; the policy was changed to enforce the retirement invariant instead. Exact final head `b54e2fb884841c861bc1435b8e60e414d4239c22` then passed CI `33645926658` and squash-merged as `0171d20b9847d0e599dbf7ddb122cbd96bdc8b6b`.

## Consumer/migration evidence

- WinInspect detached through `SemperSupra/WinInspect-private#366` after exact-head installer-lifecycle run `33641873371` passed; merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through `SemperSupra/WineBot#122`; merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lessons harvested to engineering-governance-private ADR 0002 through PR #136; merged as `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- Accessible repository inventory found no other executable WBAB consumer.

## Publication shutdown evidence

Historical GHCR image names:

- `winebotappbuilder-winbuild`
- `winebotappbuilder-packager`
- `winebotappbuilder-signer`
- `winebotappbuilder-linter`

Exact-name searches across accessible SemperSupra and `mark-e-deyoung` repositories found no consumers. Searches for `WineBotAppBuilder/releases` likewise found none.

Last observed public release:

- tag `v0.3.7`;
- published 2026-02-18;
- asset `ValidationSetup.exe`;
- SHA-256 `087fd9892ecf83806c365be8cd5965cca995f94b4bb588972411a80f94f69492`;
- recorded download count at retirement check: 1.

New publication is disabled. Historical releases/packages remain preserved.

## Active workflow surface during cooling-off

Only four workflows remain on `main`:

- `approved-issues-only.yml`;
- `approved-prs-only.yml`;
- `ci.yml`;
- `product-qualification.yml`.

No release publisher, scheduled diagnostic workflow, registry-login workflow, or manual formal/E2E workflow remains.

The release/publication policy now fails closed in retirement mode if `release.yml`, `packages: write`, registry login, `gh release create/upload`, or push-to-registry behavior reappears in the workflow directory.

## Operational configuration

Repository-visible `deploy/daemon` configuration consists of example authz/env files. The env examples reference external token/key/cert file paths and do not contain committed credentials.

Code search on current `main` found no remaining `secrets.*` workflow reference. The removed release workflow used the repository-provided `GITHUB_TOKEN`; no separate release secret was identified in repository-visible workflow configuration.

Actual GitHub secret values cannot be enumerated through the available connector, so no claim is made about hidden account/repository settings beyond observable repository state.

## Cooling-off rule

Until 2026-09-16:

- do not add features;
- do not publish releases/images;
- make only security-critical or retirement-integrity fixes;
- use retained CI/Product Qualification when the changed claim warrants it;
- treat any newly surfaced real WBAB dependency as evidence and evaluate it against the resurrection criterion.

At or after 2026-09-16, archive if no new dependency or unique capability signal appears and issue #61 completion criteria remain satisfied.

## Next bounded action

No additional implementation is justified solely to keep work moving. The next meaningful action is the archive-gate review at or after 2026-09-16, unless a real dependency/security signal appears sooner.
