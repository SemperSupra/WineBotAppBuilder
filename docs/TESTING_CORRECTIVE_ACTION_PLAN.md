# Testing Corrective Action Plan

Status: active corrective program  
Tracker: #58  
Finding: `docs/findings/testing-value-red-team-2026-09-02.md`

## Objective

Replace self-referential testing ceremony with a small, capability-driven validation system that produces actionable evidence and accelerates a working WBAB solution.

The desired end state is not "more tests" or "fewer tests." It is:

> the cheapest faithful validator for each material risk, with one real vertical proving the product's central capability and targeted lower-level checks isolating specific failure modes.

## Constraints / way of working

1. **Durable authority** — GitHub issue/PR/ref/artifacts are authoritative; chat/session state is not.
2. **Deterministic first** — repeated build/test/package/sign/smoke work belongs in repository-native scripts/workflows.
3. **Least scarce eligible resource** — use public deterministic CI/local Docker before consuming human/agent review for repeatable verification.
4. **Exact identity** — bind qualification to source SHA, image identity, artifact hash, and relevant environment/version.
5. **Fail closed** — no product PASS if a required phase did not execute.
6. **Reversible progression** — introduce replacement evidence before deleting legacy checks; prune in later bounded commits/PRs.
7. **Idempotent where practical** — qualification may be re-run without corrupting shared state and should isolate temporary artifacts/session identifiers.
8. **Actionable output** — first failed phase and durable evidence should tell the next worker what to fix.
9. **No platform invention** — use GitHub Actions, shell/Python, Docker/WineBot, and existing repo artifacts; do not create a new test-management service/database.
10. **Human/agent parity** — one command should be runnable by a human, CI, or an agent with the same semantics.

## Critical path

### Phase P0 — truth and evidence alignment

Deliverables:

- accepted red-team finding;
- program tracker #58;
- evidence taxonomy (`STATIC_CONTRACT`, `MOCKED_BEHAVIOR`, `INFRASTRUCTURE_SMOKE`, `PRODUCT_QUALIFICATION`, `RELEASE_QUALIFICATION`);
- README/STATE/AGENTS wording that no longer upgrades fixture/mock results into production/product proof;
- current fixture defaults explicitly documented until P2 changes them.

Exit criterion:

A maintainer/agent can state exactly what normal CI proves and what remains unproven without reading implementation details.

### Phase P1 — first-party product qualification vertical

Use `samples/validation-app` and candidate-source tool images.

Required phases and stable result codes:

1. `SOURCE_IDENTIFIED`
2. `WINBUILD_IMAGE_BUILT`
3. `BUILD_EXECUTED`
4. `BUILD_OUTPUT_VERIFIED`
5. `PACKAGER_IMAGE_BUILT`
6. `PACKAGE_EXECUTED`
7. `INSTALLER_VERIFIED`
8. `SIGNER_IMAGE_BUILT`
9. `SIGN_EXECUTED`
10. `SIGNATURE_VERIFIED`
11. `WINEBOT_STARTED`
12. `INSTALL_EXECUTED`
13. `APP_EXECUTED`
14. `POSTCONDITION_VERIFIED`
15. terminal `PRODUCT_QUALIFICATION_PASSED`

Failure should terminate with the first failed phase and retain logs/artifacts.

Minimum postcondition:

- install the exact generated `ValidationSetup` artifact in WineBot;
- execute installed `ValidationCLI.exe` with a unique value;
- extract the generated file;
- exact string equality with the expected value.

Qualification receipt should include, where available:

```json
{
  "schema": "wbab.product-qualification.v1",
  "source_sha": "...",
  "attempt_id": "...",
  "result": "PRODUCT_QUALIFICATION_PASSED|FAILED",
  "failed_phase": null,
  "images": {},
  "artifacts": {},
  "winebot": {},
  "postcondition": {},
  "timestamps": {}
}
```

The receipt records observed facts; it must not invent image digests or environment identities that were not measured.

Initial rollout:

- workflow-dispatch / non-required candidate gate while stabilizing;
- promote to ordinary PR gate only after repeated successful operation and acceptable runtime/resource cost;
- keep existing gates during stabilization.

### Phase P2 — make product verbs truthful

Once P1 exposes the real path reliably:

- `wbab build` defaults to the real build runner;
- `wbab package` defaults to the real package runner;
- fixture execution requires explicit test/fixture mode;
- `wbab sign` must distinguish actual signing from fixture/unsigned handling;
- no default "sign" operation may silently copy bytes and call that signing;
- update `wbab plan` so the declared plan matches actual execution semantics.

Backward compatibility is subordinate to truthful semantics when compatibility would preserve a misleading claim.

### Phase P3 — value-audit and prune legacy tests

Inventory every recurring gate with:

| Field | Meaning |
|---|---|
| risk | material failure the test protects |
| evidence_class | taxonomy above |
| faithful_boundary | real vs simulated boundary |
| decision_on_failure | concrete next engineering action |
| unique_signal | evidence not already supplied more faithfully elsewhere |
| resource_cost | rough CI/time/maintenance class |
| disposition | retain / collapse / demote / replace / delete |

Priorities:

- replace source-grep invariants with behavioral tests where practical;
- collapse repetitive `plan` shell scripts into parameterized JSON/schema validation;
- replace mocked Git subprocess semantics with local real Git fixtures;
- demote workflow-step-name/adjacency checks unless they protect a real authority/security boundary not covered by structured validation;
- retain daemon state/idempotency/authz and fault-injection mocks where the mock isolates the intended variable;
- rename existence/hash checks as inventory/provenance evidence rather than product validation.

No check is removed merely because it is mocked; it is removed when it has no unique decision value or a cheaper/more faithful validator supersedes it.

### Phase P4 — release and external qualification

After first-party qualification is stable:

- qualify exact published image digests rather than mutable tags alone;
- bind release qualification to exact artifact hashes;
- run at least one real external target, initially WinInspect if still representative;
- preserve exact failure evidence for incompatibilities;
- keep release/security gates that protect actual publication/credential/authority boundaries;
- remove duplicate textual checks that merely restate the release workflow implementation.

## Test architecture target

```text
FAST / ordinary change
  lint/static analysis
  pure/core unit tests
  daemon behavioral state/idempotency/authz tests
  local-real Git behavior tests
  compact structured CLI/plan contract validation

PRODUCT QUALIFICATION
  exact source
    -> real winbuild
    -> real package
    -> real sign + verify
    -> real WineBot install
    -> real installed executable
    -> deterministic externalized postcondition

RELEASE QUALIFICATION
  exact published images/digests
    -> exact release artifact(s)
    -> first-party product vertical
    -> selected external compatibility target

TARGETED FAULT TESTS
  pull failures
  retry/resume
  duplicate requests
  interrupted operations
  resource/timeout boundaries
  authn/authz denials
```

## Progress / stop rules

Continue autonomously through a bounded slice while repository state and tools remain available.

Stop and checkpoint when:

- a required external credential/production authority is needed;
- release publication would occur;
- a destructive/irreversible history action is proposed;
- evidence shows the architecture assumption is wrong and the critical path should be changed;
- the current slice has reached a durable, independently reviewable boundary.

At each stop, #58 or its bounded child issue/PR must expose:

- exact source/ref;
- completed phases;
- exact validation evidence actually executed;
- unknown/unexecuted phases;
- blocker if any;
- next bounded action.

## Success metric

The corrective program succeeds when normal project momentum is driven primarily by **capability failures with direct next actions**, rather than by repairing brittle tests that only confirm the repository still resembles its previous implementation.
