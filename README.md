# WineBotAppBuilder (WBAB)

> **Retirement notice — 2026-09-02:** WBAB is feature-frozen and being retired as a standalone build/orchestration platform. Do not adopt it for new work. See [`RETIREMENT.md`](RETIREMENT.md) and issue #61 for the migration plan, successor systems, completion criteria, and resurrection rule.

WBAB is a containerized toolchain for Windows development on Linux. It provides build, package, signing, and validation operations integrated with WineBot-style execution environments.

## Retirement status

New product/platform development has stopped. Changes are limited to bounded retirement/migration work, security-critical fixes, truthful final-state documentation, and extraction of uniquely useful capability required by a named real consumer.

Preferred successor paths are:

- **native Windows build/test:** product-local GitHub Actions on a native Windows runner;
- **reusable Windows release/trust/distribution:** `SemperSupra/windows-package-foundry`;
- **native Windows interactive/GUI automation or controlled legacy Windows environments:** `mark-e-deyoung/WinBot` plus an appropriate Windows runner/VM;
- **Wine runtime/compatibility validation:** `SemperSupra/WineBot`;
- **shared runtime/conformance contracts:** `mark-e-deyoung/winebot-contracts`.

Existing WBAB behavior remains useful as historical/reference material while consumers are detached. Retirement is not complete until no live consumer depends on WBAB and replacement paths have been proven on real targets.

## Evidence vocabulary

WBAB's retirement preserves an important lesson from its testing red-team: evidence must be named according to what actually executed.

- `STATIC_CONTRACT` — source/configuration/schema inspection only.
- `MOCKED_BEHAVIOR` — behavior checked with an intentional mock/fixture standing in for another component.
- `INFRASTRUCTURE_SMOKE` — infrastructure started or transported data but did not prove the full product claim.
- `PRODUCT_QUALIFICATION` — a real product capability chain executed against an exact source/artifact identity and checked an independent postcondition.
- `RELEASE_QUALIFICATION` — qualification of exact published release artifacts/identities.

A green static or mocked check must never be presented as product qualification.

## Historical qualification fixture

`samples/validation-app` is the first-party qualification workload used to exercise the real WBAB/WineBot vertical. During retirement its final disposition will be decided explicitly: migrate it only if another owner has a real need for the fixture; otherwise preserve it here as part of the archived engineering record.

## Project history and current authority

Durable repository state is authoritative. For current retirement work, read in this order:

1. `RETIREMENT.md`
2. issue #61 — authoritative retirement tracker
3. `STATE.md`
4. bounded migration/retirement issues or pull requests

Historical documentation and code may describe capabilities or expansion plans that are no longer active. The retirement plan supersedes feature-roadmap intent.

## License

MIT. See `LICENSE`.
