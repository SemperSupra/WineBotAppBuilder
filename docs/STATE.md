# Project State

**Current date:** 2026-09-02  
**Current corrective program:** issue #58 — capability-driven product qualification and test-value correction  
**Parent implementation PR:** #59 (`corrective/testing-capability-qualification`)  
**Stacked P3 PR:** #60 (`corrective/testing-ceremony-prune`)  
**Last validated P3 documentation checkpoint:** `46db696704bf5f51ae15dcacf2d19aa0128e0200`

## Current status

P0 through P3 are **complete on the corrective stack**. WBAB now has a proven first-party product-qualification vertical, truthful ordinary build/package/sign semantics, an as-built recurring-gate inventory, and a reduced ordinary CI topology whose remaining gates each have explicit decision value.

This does **not** mean release qualification is complete. No current claim is made that exact published release images/artifacts have been qualified end-to-end or that WBAB should be labeled generally `Production Stable`.

The active durable records are:

- issue #58;
- PR #59 for P1/P2/P3.1;
- PR #60 for P3.2;
- `docs/findings/testing-value-red-team-2026-09-02.md`;
- `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`.

## Evidence semantics

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with one or more material boundaries simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime without the complete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical plus an independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts identified immutably and qualified.

A weaker evidence class never implies a stronger one, and an older PASS is not transferred to a changed candidate head.

## P1 — first-party product qualification

Status: **complete for the candidate-source first-party vertical**.

Initial exact proven checkpoint:

- candidate `04eb9e85805f629fcc2f36ab5f3428920d07be6b`;
- ordinary CI run `33620383914` passed;
- Product Qualification run `33620384011` passed.

The product vertical builds candidate-source tool images, builds and tests `samples/validation-app`, packages a real NSIS installer, performs real development signing and independent signature verification, installs the exact generated installer in WineBot, executes the installed CLI, and verifies an exact externalized postcondition.

The qualification script remains fail-closed: interrupted or failed attempts are not product qualification.

## P2 — truthful ordinary command semantics

Status: **complete on PR #59**.

Build/package checkpoint:

- candidate `f0ff0f6ef2ea43cf704733fa6c28a5e7d6e33564`;
- ordinary CI run `33628042826` passed;
- Product Qualification run `33628042831` passed.

Signing checkpoint:

- candidate `1c986051a078f870ee70c37d5088006b34239534`;
- ordinary CI run `33629015926` passed;
- Product Qualification run `33629015830` passed;
- retained artifact `product-qualification-33629015830-1`, digest `sha256:2545c8fd28aa45ca8cbb8a8390945d2a701ed88a40755a41265bb22f85bd5e32`.

Current semantics:

- `wbab build` defaults to real image-native build execution;
- `wbab package` defaults to real image-native packaging;
- `wbab sign` defaults to real development-certificate signing;
- fixture execution is explicit;
- custom overrides are explicit;
- contradictory mode selections fail closed;
- `wbab plan` reports the same resolved execution mode/command as the runtime path.

## P3 — value audit and ceremony pruning

Status: **complete**.

P3.1 plan-contract collapse:

- exact head `7a075f729257601d15f527b3686bab736cf68095`;
- six repetitive plan JSON shell validators replaced by one table-driven structured validator;
- ordinary CI run `33631623609` passed;
- final regression Product Qualification run `33631623580` passed;
- retained artifact `product-qualification-33631623580-1`, digest `sha256:22de58cf42ac7001b69de95a7a5f65787d2694da83e90d3a4e50384ec3fb325a`.

P3.2 stacked pruning in PR #60:

- core implementation-text idempotency/attempt greps removed after behavioral replacement;
- live HTTP bearer authentication semantics added before auth/TLS source greps were removed;
- release workflow line/step-name ceremony replaced by structured authority-order validation before the old order test was deleted;
- mocked build→package→sign→smoke integration signal moved into the bounded shell suite before the standalone `e2e-smoke` job/wrapper was removed;
- engineering head `4077fbd2d85a1fdd460921e4e589d3f708804961` passed five-job CI run `33633402860`;
- documentation/inventory checkpoint `46db696704bf5f51ae15dcacf2d19aa0128e0200` passed five-job CI run `33637937692`.

Current ordinary CI jobs:

1. `lint`
2. `shell-unit` — bounded shell plus mocked integration behavior
3. `contract`
4. `policy`
5. `python-unit`

Product Qualification is path-scoped/opt-in and intentionally did not run for P3.2 test/policy/documentation-only changes. That does not transfer an older product PASS to those heads; it means P3.2 makes no changed-product claim requiring product qualification.

P3 stop decision:

- the as-built inventory in `docs/TESTING_CORRECTIVE_ACTION_PLAN.md` accounts for every recurring validation/qualification workflow;
- the five remaining ordinary gates each protect a distinct material risk and have an actionable failure consequence;
- opt-in diagnostic/formal/infrastructure workflows retain distinct purposes without adding ordinary PR tax;
- repository participation controls are explicitly outside the testing inventory;
- further deletion is not earned merely to reduce the gate count.

## P4 — release and external qualification

Status: **not started as a qualification phase**.

Remaining program work is deliberately separate from P3:

- qualify exact published image digests rather than mutable tags alone;
- bind release qualification to exact release artifact hashes;
- run the first-party product vertical against exact published release identities;
- add at least one selected external compatibility target when justified;
- retain publication/security/credential gates that protect real authority boundaries.

The existing release workflow is a real publication mechanism, not by itself proof of `RELEASE_QUALIFICATION`.

## Resume checkpoint

Authoritative tracker: issue #58.  
Parent implementation PR: #59.  
Current P3 PR: #60.  
Last validated P3 documentation checkpoint: `46db696704bf5f51ae15dcacf2d19aa0128e0200`; CI `33637937692`, five jobs passed.  
Mutable branch/PR heads must still be refreshed from GitHub before mutation; do not infer them from this snapshot.  
P3 disposition: **complete; no additional ceremony pruning currently earned**.  
Next safe bounded action: make PR #60 review-ready, then reconcile the stacked PR integration path without transferring validation claims across changed heads.  
P4 is a separate future phase and begins only when exact published release identities are deliberately in scope.  
Human authority required now: **no** for review-readiness/checkpoint metadata; reassess before merge/release publication or other authority-sensitive transitions.  
Stop before release publication, production signing credentials, destructive history changes, or undeclared authority escalation.
