# Project State

**Current date:** 2026-09-02  
**Current corrective program:** issue #58 — capability-driven product qualification  
**Pre-correction main baseline:** `bd79d45ba20cc70cae9da7625c6b3605c7176655`  
**Current corrective branch:** `corrective/testing-capability-qualification`  
**Last implemented candidate:** `99dd3d7d8c98cd7d28d2715fedbe64eae056bb82`

## Current status

WBAB is an implemented toolchain candidate under capability qualification. The prior `Production Stable` label is historical and is not accepted as current product-qualification evidence.

The 2026-09-02 testing red-team is accepted by the maintainer. Durable records:

- issue #58;
- `docs/findings/testing-value-red-team-2026-09-02.md`;
- `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`.

Historical state remains available in Git history, including the pre-correction `docs/STATE.md` at `bd79d45ba20cc70cae9da7625c6b3605c7176655`. This file is intentionally a compact active working-set projection rather than an accumulating accomplishment log.

## Evidence semantics

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with one or more material boundaries simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime without the complete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical plus independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts identified immutably and qualified.

Never silently promote a weaker evidence class into a stronger PASS.

## P0 — truth/evidence alignment

Status: **implemented on corrective branch**.

Completed:

- accepted finding and corrective plan;
- README no longer claims current production qualification and no longer instructs users to enter a nonexistent `workspace/` directory or use a nonexistent `init` verb;
- AGENTS playbook states the evidence taxonomy and decision-value rule;
- organization policy reflects the actual root-level source layout;
- current fixture defaults for host `build/package/sign` wrappers are explicitly documented;
- current normal `e2e-smoke` is classified as mocked behavior and legacy `e2e-real` as infrastructure smoke by default.

Exact commits:

- `48022cc4909cb15e00ab531e0b7783abe35dea8a` — finding + corrective plan;
- `eaf1ac9af2318a176d70430953c53638eeb2ccb1` — truth/status/playbook realignment.

## P1 — first-party product qualification

Status: **candidate implementation complete; execution evidence pending**.

Candidate commit:

- `99dd3d7d8c98cd7d28d2715fedbe64eae056bb82`

New durable machinery:

- `tests/e2e/product-qualification.sh`;
- `.github/workflows/product-qualification.yml` (opt-in/non-required while stabilizing).

The candidate script is designed to execute:

```text
SOURCE_IDENTIFIED
  -> candidate-source winbuild image build
  -> real wbab-build-real on isolated samples/validation-app
  -> verify ValidationCore.dll / CLI / GUI / Tests outputs
  -> run ValidationTests.exe under Wine
  -> candidate-source packager image build
  -> real wbab-package-real installer.nsi
  -> verify real ValidationSetup.exe
  -> candidate-source signer image build
  -> ephemeral one-day dev signing certificate
  -> real wbab-sign-real
  -> osslsigncode signature verification against the ephemeral CA cert
  -> isolated WineBot workset
  -> install exact signed installer
  -> execute installed ValidationCLI.exe
  -> write unique value to C:\wbab-product-qualification.txt
  -> extract output from WineBot
  -> exact expected-content assertion
  -> events.jsonl + receipt.json + phase logs/artifacts
```

Candidate behavior is designed to fail closed: the final receipt uses `PRODUCT_QUALIFICATION` only when the script reaches the terminal success state after the deterministic postcondition. A failed/interrupted attempt is recorded as `UNQUALIFIED_ATTEMPT` with its current/failed phase.

### What has **not** yet been proven

No exact-head product-qualification run has yet been observed for `99dd3d7d8c98cd7d28d2715fedbe64eae056bb82`.

Therefore the following remain unknown/unexecuted for this candidate until actual run evidence exists:

- candidate Docker image build success;
- real validation-app MinGW/CMake compile success in the candidate image;
- Wine unit-test success;
- real NSIS packaging success;
- real dev-sign/signature-verification success;
- current WineBot `stable` pull/boot compatibility;
- silent installer behavior;
- installed CLI path correctness under current Wine;
- exact postcondition extraction/content match;
- end-to-end runtime/resource cost.

Do not infer any of those from older/mock/static green checks.

## P2 — truthful ordinary command defaults

Status: **not started; intentionally blocked on P1 evidence**.

Once the real vertical is usable enough to diagnose failures:

- real build/package becomes the normal semantic default;
- fixture mode becomes explicit/test-scoped;
- `sign` cannot silently copy bytes and call that signing;
- `wbab plan` must match actual execution semantics.

## P3 — value-audit/prune ceremony

Status: **not started; intentionally blocked on replacement evidence**.

Do not delete legacy tests merely because they are mocked. Evaluate unique decision value and prune/collapse only after stronger or cheaper evidence supersedes them.

## P4 — release/external qualification

Status: not started.

Later:

- exact published image digests;
- exact artifact hashes;
- first-party product vertical;
- selected external target (candidate: WinInspect).

## Resume checkpoint

Authoritative program: issue #58.  
Current branch/head: `corrective/testing-capability-qualification` @ `99dd3d7d8c98cd7d28d2715fedbe64eae056bb82` (before this state-checkpoint commit).  
Last completed engineering action: candidate product-qualification script/workflow implemented.  
Validation state: **NOT YET EXECUTED against the candidate; no product PASS**.  
Next safe bounded action: open/update the corrective PR, execute repository-native CI and the opt-in product-qualification workflow against its exact head, inspect the first real failure/success evidence, and use that result to choose the next implementation change.  
Human authority required now: **no** for reversible repository implementation and public deterministic CI.  
Stop before release publication, production signing credentials, destructive history changes, or other undeclared authority escalation.
