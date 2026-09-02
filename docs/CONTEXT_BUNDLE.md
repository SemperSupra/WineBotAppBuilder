# CONTEXT_BUNDLE (read this first)

## Current milestone

**WBAB retirement — issue #61.**

WBAB is feature-frozen and is being retired as a standalone build/orchestration platform. Do not resume historical feature-roadmap work.

## Current durable workset

- authoritative retirement tracker: #61;
- retirement plan: `RETIREMENT.md`;
- dependency inventory: `docs/RETIREMENT-INVENTORY.md`;
- current state/resume point: `docs/STATE.md`;
- final corrective baseline on `main`: `5ef09847de2770c2619592453d372f42dcf97eed`;
- current retirement branch: `retirement/wbab-retirement-main`.

## Final corrective baseline

The completed #58 P0-P3 corrective stack was validated on exact head:

`461c2704586a8bcb5d876be30322cb19bff52a60`

Fresh exact-head validation:

- CI run `33643641548` — PASS;
- Product Qualification run `33643641313` — PASS.

Replacement PR #63 squash-merged to `main` as `5ef09847de2770c2619592453d372f42dcf97eed`.

Original PRs #59/#60 are superseded historical integration scaffolding. P4/release qualification is not authorized as WBAB product work.

## Retirement work completed

- WinInspect detached from WBAB through PR #366 after installer-lifecycle run `33641873371` passed; merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through PR #122; merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lessons harvested to engineering-governance-private ADR 0002 through PR #136; merged as `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- First-pass indexed search found no other executable downstream WBAB consumer.
- Major expansion/backlog issues were closed as not planned.
- Old retirement PR #62 was closed as superseded by a fresh branch based on corrected `main`.

## Preferred successor architecture

- native product build/test/package -> product-local GitHub Actions on Windows;
- reusable Windows release/trust/distribution -> Windows Package Foundry;
- native Windows GUI/interactive automation -> WinBot;
- licensed/legacy persistent Windows toolchain -> controlled Windows runner/VM;
- Wine compatibility/runtime qualification -> WineBot;
- shared runtime/API conformance -> winebot-contracts.

## Preserved final WBAB capability truth

Before retirement, #58 established:

- real candidate-source build/package/sign behavior;
- real first-party validation app build and tests;
- real NSIS installer;
- real development signing plus independent verification;
- WineBot install and execution of the installed CLI;
- deterministic external postcondition;
- structured execution planning;
- reduced five-job ordinary CI.

This is `PRODUCT_QUALIFICATION` evidence, not `RELEASE_QUALIFICATION`.

## Evidence classes

- `STATIC_CONTRACT`
- `MOCKED_BEHAVIOR`
- `INFRASTRUCTURE_SMOKE`
- `PRODUCT_QUALIFICATION`
- `RELEASE_QUALIFICATION`

Never upgrade a weaker class into a stronger claim. Strong evidence belongs to the exact candidate/artifact that executed.

## Current retirement branch contents

`retirement/wbab-retirement-main` is based directly on corrected `main`, so its intended PR is a retirement-only delta.

It contains:

- `RETIREMENT.md`;
- retirement-first `README.md`;
- `docs/RETIREMENT-INVENTORY.md`;
- retirement-focused `docs/STATE.md`;
- retirement-focused `AGENTS.md`;
- this context bundle;
- retired `BACKLOG.md`.

Further workflow/publication changes should be added only after checking that no external consumer still needs WBAB release/GHCR outputs.

## Next bounded sequence

1. Open `retirement/wbab-retirement-main` against `main`.
2. Confirm the diff is retirement-only and run ordinary validation appropriate to docs/governance changes.
3. Merge the retirement state when clean.
4. Close/complete #58 with exact final evidence.
5. Check whether any external consumer still uses WBAB releases/GHCR images.
6. Disable release/image publication and optional/scheduled workflows that no longer protect a retirement invariant.
7. Update #61 completion checklist and enter cooling-off.
8. Archive only when #61 completion criteria are satisfied.

## Stop conditions

Stop before:

- new WBAB feature/platform development;
- release publication or production signing;
- destructive history rewrites or deletion of historical evidence;
- removing a newly discovered live dependency without replacement evidence;
- credential/licensing/security boundary changes not already authorized by retirement work.
