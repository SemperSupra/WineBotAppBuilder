# CONTEXT_BUNDLE (read this first)

## Current milestone

**WBAB retirement — issue #61.**

WBAB is feature-frozen and is being retired as a standalone build/orchestration platform. Do not resume historical feature-roadmap work.

## Current durable workset

- authoritative retirement tracker: #61;
- retirement plan: `RETIREMENT.md`;
- dependency inventory: `docs/RETIREMENT-INVENTORY.md`;
- current state/resume point: `docs/STATE.md`;
- final corrective integration candidate: PR #63;
- prepared retirement branch: `retirement/wbab-retirement-final`.

## Current exact integration state

The completed #58 P0-P3 corrective stack is represented by exact head:

`461c2704586a8bcb5d876be30322cb19bff52a60`

Replacement non-draft PR #63 targets `main` because the connected ready-for-review mutation for original draft PR #60 is broken by a connector GraphQL schema defect.

Fresh exact-head validation opened for #63:

- CI run `33643641548`;
- Product Qualification run `33643641313`.

Both must reach terminal PASS before #63 is merged. No P4/release-qualification program is authorized.

## Retirement work already completed

- WinInspect detached from WBAB through PR #366 after installer-lifecycle run `33641873371` passed; merged as `9ae0afd61d44d6c60187f57e0f3aa293d9c0a74f`.
- WineBot architecture corrected through PR #122; merged as `6f4c077ca8f89e73471acd38635d86a4ac4a4961`.
- Portfolio lessons harvested to engineering-governance-private ADR 0002 through PR #136; merged as `00363c37d5503d49c7435d66128c3af758f0d0a4`.
- First-pass indexed search found no other executable downstream WBAB consumer.
- Major expansion/backlog issues were closed as not planned.

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

## Retirement branch contents

`retirement/wbab-retirement-final` is based on the exact #63 candidate, not the old `main`, so after #63 lands it should become a small retirement-only diff.

It contains or will contain:

- `RETIREMENT.md`;
- retirement-first `README.md`;
- `docs/RETIREMENT-INVENTORY.md`;
- retirement-focused `docs/STATE.md`;
- retirement-focused `AGENTS.md`;
- this context bundle;
- final backlog/workflow/publication cleanup only where evidence shows it is safe.

## Next bounded sequence

1. Observe #63 CI and Product Qualification.
2. If both PASS and #63 remains clean, exact-head merge #63.
3. Close #59/#60 as superseded and close/complete #58 with exact final evidence.
4. Open `retirement/wbab-retirement-final` against the resulting `main`; close old retirement PR #62 as superseded.
5. Validate and merge the retirement-only delta.
6. Check whether any external consumer still uses WBAB releases/GHCR images.
7. Disable release/image publication and optional/scheduled workflows that no longer protect a retirement invariant.
8. Confirm final docs/backlog/state and enter cooling-off.
9. Archive only when #61 completion criteria are satisfied.

## Stop conditions

Stop before:

- new WBAB feature/platform development;
- release publication or production signing;
- destructive history rewrites or deletion of historical evidence;
- removing a newly discovered live dependency without replacement evidence;
- credential/licensing/security boundary changes not already authorized by retirement work.
