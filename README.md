# WineBotAppBuilder (WBAB)

> **Retirement notice — 2026-09-02:** WBAB is feature-frozen and being retired as a standalone build/orchestration platform. Do not adopt it for new work. See [`RETIREMENT.md`](RETIREMENT.md) and issue #61 for the authoritative migration plan, successor systems, completion criteria, and resurrection rule.

WBAB is a containerized toolchain for building, packaging, signing, and testing Windows applications from Linux. Its remaining value is being preserved as qualification evidence, reusable lessons, and historical/reference implementation rather than developed into a larger platform.

## Retirement status

New product/platform development has stopped. Changes are limited to bounded retirement/migration work, security-critical fixes, truthful final-state documentation, and extraction of uniquely useful capability required by a named real consumer.

Preferred successor paths are:

- **native Windows build/test/package:** product-local GitHub Actions on native Windows runners;
- **reusable Windows release/trust/distribution:** `SemperSupra/windows-package-foundry`;
- **native Windows interactive/GUI automation or controlled legacy Windows environments:** `mark-e-deyoung/WinBot` plus an appropriate Windows runner/VM;
- **Wine runtime/compatibility validation:** `SemperSupra/WineBot`;
- **shared runtime/conformance contracts:** `mark-e-deyoung/winebot-contracts`.

The strongest known downstream consumer, WinInspect, has already been detached after exact-head installer-lifecycle validation. See `docs/RETIREMENT-INVENTORY.md`.

WBAB no longer publishes new GitHub releases or GHCR build/package/sign/lint images. The release workflow and obsolete manual diagnostic/formal/infrastructure workflows were removed during archival preparation after the accessible portfolio showed no consumers of those publication surfaces. Existing historical releases and packages are not deleted by this retirement change.

## Final qualification state

Before retirement, the #58 corrective program established a proven **candidate-source first-party product qualification** path: candidate tool images are built, the real validation app is compiled and tested, a real NSIS installer is produced, development signing is performed and independently verified, the installer is exercised in WineBot, the installed CLI is executed, and an exact deterministic postcondition is verified.

This is materially stronger than WBAB's historical mock/fixture evidence. It is **not release qualification**: exact published image digests and release artifacts were not qualified as a release set. Retirement intentionally does not continue into a new P4/release-qualification program merely to make WBAB more complete.

The accepted testing finding is in `docs/findings/testing-value-red-team-2026-09-02.md`; the corrective plan and final gate inventory are in `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`.

## Preserved evidence vocabulary

Do not treat all green checks as equivalent:

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with a material boundary simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime without the complete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical with an independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts qualified by immutable identities.

A weaker evidence class never implies a stronger class, and a PASS is tied to the exact candidate that actually executed.

These lessons have been harvested to portfolio engineering governance rather than kept as a reason to maintain WBAB indefinitely.

## Historical command semantics

The final corrected ordinary verbs are truthful by default:

- `wbab build` -> real image-native build execution;
- `wbab package` -> real image-native packaging;
- `wbab sign` -> real development-certificate signing;
- fixture execution must be selected explicitly;
- custom execution must be selected explicitly;
- contradictory mode settings fail closed;
- `wbab plan` exposes the same resolved execution mode/command used by execution.

These commands remain documented for historical/reference use during the retirement window. They are not an invitation for new adoption.

## Qualification fixture

`samples/validation-app` is the first-party workload used to exercise the real WBAB/WineBot vertical. It includes a real DLL, CLI, GUI, tests, and NSIS installer.

Its retirement disposition is **archive in place** unless a successor owner later demonstrates a real need for the fixture. Do not migrate it merely to keep it active.

## Cooling-off validation surface

During cooling-off, the repository intentionally retains only the validation/governance workflows that still protect plausible retirement changes:

- ordinary CI for non-documentation code/config changes;
- candidate Product Qualification for relevant product-path changes;
- approved-issue / approved-PR participation controls.

The release publisher, opt-in real-E2E workflow, policy-trend diagnostic workflow, and TLA opt-in workflow are retired. Their history remains available in Git.

## Core lessons retained

- Prefer native/provider capabilities before creating a new orchestration platform.
- Require demonstrated consumer demand before generalizing reusable infrastructure.
- Durable GitHub/repository evidence is authoritative; chat/agent session state is not.
- Deterministic checks should run in repository-native automation rather than consume repeated human/agent attention.
- Validation evidence must bind to exact source/artifact identities where material.
- A recurring check earns maintenance cost only when its failure changes a real engineering decision or uniquely protects a material invariant.
- Replacement evidence should exist before removing a live dependency or validator.
- A working experiment can still be retired when narrower successor systems provide the capability with lower maintenance cost.

## Current authority

For retirement work, read in this order:

1. [`RETIREMENT.md`](RETIREMENT.md)
2. issue #61 — authoritative retirement tracker
3. `docs/RETIREMENT-INVENTORY.md`
4. `docs/STATE.md`
5. bounded migration/retirement PRs

Historical documentation and code may describe expansion plans that are no longer active. The retirement decision supersedes feature-roadmap intent.

## License

MIT. See `LICENSE`.
