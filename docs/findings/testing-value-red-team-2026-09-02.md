# Testing Value Red-Team — 2026-09-02

Status: accepted finding  
Decision authority: maintainer concurrence  
Program tracker: #58

## Question

Does the current WBAB test/smoke program produce decision-useful evidence about the real product, or has it accumulated mocks, source-text checks, and workflow ceremony that consume maintenance and human attention without materially accelerating a working solution?

## Finding

The current program is materially imbalanced.

It contains useful behavioral checks for bounded concerns such as daemon state, idempotency, retry/resume, authorization, and pure logic. Those tests appropriately use cheap/mocked workers when the worker is not the subject under test.

However, the recurring validation surface is overweight on:

- mocked Docker/compose command emission;
- fixture executables/installers/signatures;
- grep-based source and policy conformance;
- exact workflow step names/order/adjacency;
- repetitive shell tests for structurally similar JSON plans;
- evidence labels that imply stronger validation than actually occurred.

At the same time, the default CI does not prove the central user-facing capability end-to-end:

> an actual Windows project can be compiled by the intended WBAB toolchain, packaged into a real installer, signed through the intended signer path, installed into real WineBot, executed, and checked through an independent deterministic postcondition.

## What current green CI actually establishes

The normal CI is useful evidence for several internal properties:

- CLI dispatch and basic command contracts;
- pull-first/no-local-build wiring;
- daemon operation-store, retry/resume, idempotency and API behavior under controlled workers;
- selected security/authz rejection behavior;
- pure Python logic;
- shell/static policy conformance;
- ability of the mocked pipeline to traverse expected orchestration stages.

The normal `e2e-smoke` does **not** establish product E2E behavior. It replaces Docker with a fake command recorder and manufactures fake artifacts.

The opt-in `e2e-real` is better described as a **real Docker/WineBot infrastructure smoke** in its current form. It defaults to fixture build/package/sign outputs and can skip installer execution. A passing result therefore does not establish that the real WBAB product chain produced and ran a real application.

## Specific evidence-strength problems

### Default product verbs silently use fixtures

The host wrappers for build and package default to fixture commands even though the corresponding container images already install real runners (`wbab-build-real`, `wbab-package-real`). Signing defaults to a fixture copy unless dev-cert mode is explicitly selected.

This is a semantic mismatch: ordinary product verbs present production-like names while defaulting to scaffold behavior.

### Source-text gates claim behavioral assurance

Examples include tests that grep for exact shell/Python lines to infer output-cleaning, idempotency, path conventions, TLS handling, or formal-model implementation. These checks can fail on harmless refactoring while passing code that still contains the expected text but behaves incorrectly.

Where a material invariant matters, observable behavioral evidence or structured configuration validation is stronger and usually less brittle.

### Artifact inventory is labeled validation

The current installer artifact check establishes that a file exists, is non-empty, and has a recorded hash/manifest. That is useful provenance/inventory evidence, but it does not establish PE/installer validity, signature validity, installability, provenance from the tested source, or successful execution. The evidence should be named accordingly.

### Documentation/status exceeds evidence

The repository describes v0.3.7 as `Production Stable` while also documenting fixture defaults / bring-up behavior. README quick-start instructions refer to a `workspace/` layout and an `init` verb that are not present in the current repository/CLI. This demonstrates that high internal test volume is not protecting the real user journey.

## Existing high-value qualification asset

`samples/validation-app` is already a strong first-party test workload:

- real Windows DLL;
- real CLI executable;
- real GUI executable;
- real unit-test executable;
- real NSIS installer;
- CLI accepts a deterministic message/output path;
- WineBot smoke tooling can install, run an executable, extract an output file, and compare exact content.

The project therefore does not need another mock application. It needs to make this existing workload the primary real capability vertical.

## Decision rule

For recurring test/gate maintenance:

> A test earns its recurring cost only when its failure changes a real engineering decision or protects a material invariant that cheaper evidence cannot protect.

This does **not** mean "no mocks." It means the mock must isolate the variable actually under test and must not substitute for the environment/capability being claimed.

Examples:

- daemon idempotency with a fake cheap worker: retain;
- authz policy with a fake build worker: retain;
- fake Docker returning success to claim product E2E: do not treat as product qualification;
- source grep for an implementation line when the behavior can be exercised directly: replace/demote;
- fault injection requiring deterministic simulated failures: retain as targeted fault test.

## Target evidence taxonomy

Use evidence names that reflect what actually executed:

- `STATIC_CONTRACT` — source/config/schema shape only;
- `MOCKED_BEHAVIOR` — behavior with one or more material boundaries simulated;
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime exercised but not the full product postcondition;
- `PRODUCT_QUALIFICATION` — real first-party product vertical with independent postcondition;
- `RELEASE_QUALIFICATION` — exact published images/artifacts qualified by immutable identities.

A weaker class must never be silently promoted into a stronger PASS.

## Way-of-working alignment

This finding is consistent with `GOV-EXEC-001`:

- deterministic-first;
- least scarce eligible resource;
- exact evidence identity;
- fail-closed execution/evidence semantics;
- durable repository state as authority;
- bounded/reversible progression;
- human/agent attention focused on novel design/diagnosis rather than repeated deterministic ceremony.

The corrective program is tracked in #58 and detailed in `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`.
