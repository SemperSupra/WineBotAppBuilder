# WineBotAppBuilder (WBAB)

A containerized toolchain for building, packaging, signing, and testing Windows applications from Linux.

## Current qualification status

WBAB now has a proven **candidate-source first-party product qualification** path: candidate tool images are built, the real validation app is compiled and tested, a real NSIS installer is produced, development signing is performed and independently verified, the installer is exercised in WineBot, the installed CLI is executed, and an exact deterministic postcondition is verified.

That is materially stronger than the repository’s historical mock/fixture evidence, but it is **not yet release qualification**. Exact published image digests and release artifacts have not yet been qualified as a release set, so WBAB should not be described generically as `Production Stable` from the current evidence alone.

The 2026-09-02 testing corrective program is tracked in [issue #58](https://github.com/SemperSupra/WineBotAppBuilder/issues/58). The accepted finding is in `docs/findings/testing-value-red-team-2026-09-02.md`, the executable plan and P3 gate inventory are in `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`, and the compact working state is in `docs/STATE.md`.

## What WBAB provides

- **Containerized Windows toolchain:** MinGW/CMake/Make-based build environment.
- **Containerized lint and test runners.**
- **NSIS packaging environment.**
- **Development signing:** real `osslsigncode` signing plus development-certificate helpers.
- **WineBot validation:** installer execution, installed-application execution, screenshots/artifacts, and deterministic output extraction/verification.
- **Idempotent daemon core:** persistent operation state, retry/resume, audit, AuthN/AuthZ/TLS surfaces.
- **Structured planning:** `wbab plan` JSON for humans, automation, and agents.
- **First-party validation workload:** `samples/validation-app` includes a real DLL, CLI, GUI, tests, and NSIS installer.
- **Candidate product qualification:** `tests/e2e/product-qualification.sh` binds execution to exact candidate source and retains evidence.

## Current command semantics

Ordinary verbs are truthful by default:

- `wbab build` -> real image-native build execution;
- `wbab package` -> real image-native packaging;
- `wbab sign` -> real development-certificate signing;
- fixture execution must be selected explicitly;
- custom execution must be selected explicitly;
- contradictory mode settings fail closed;
- `wbab plan` exposes the same resolved execution mode/command used by execution.

## Evidence vocabulary

Do not treat all green checks as equivalent:

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with a material boundary simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime without the complete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical with an independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts qualified by immutable identities.

A weaker evidence class never implies a stronger class, and a PASS is tied to the exact candidate that actually executed.

## Quick start

### Prerequisites

- Docker with Compose v2
- Git
- Python 3 for daemon/discovery features

### Clone and initialize the WineBot submodule

```bash
git clone https://github.com/SemperSupra/WineBotAppBuilder.git
cd WineBotAppBuilder
./scripts/bootstrap-submodule.sh
./tools/wbab doctor
```

There is no required `workspace/` directory and the current CLI does not implement an `init` verb.

## Current commands

```bash
./tools/wbab doctor
./tools/wbab discover
./tools/wbab plan build samples/validation-app
./tools/wbab lint samples/validation-app
./tools/wbab test samples/validation-app
./tools/wbab build samples/validation-app
./tools/wbab package samples/validation-app
./tools/wbab sign samples/validation-app
./tools/wbab smoke <installer.exe>
```

## Current validation architecture

Ordinary PR CI is intentionally compact:

1. `lint`
2. `shell-unit` — bounded shell tests plus retained mocked integration behavior
3. `contract`
4. `policy`
5. `python-unit`

The former standalone mocked `e2e-smoke` job was consolidated into `shell-unit`; the mocked build→package→sign→smoke test remains, but it is not represented as product proof.

Product Qualification is a separate higher-fidelity validator. It runs on relevant product-path changes and can also be invoked manually. It is more expensive by design and should not be triggered by unrelated documentation/test-policy-only changes.

The opt-in `e2e-real` workflow remains an `INFRASTRUCTURE_SMOKE` path unless its invocation supplies the complete installer/postcondition needed for a stronger claim.

## Qualification direction

The current first-party product path is:

```text
exact candidate source
  -> candidate-source winbuild image
  -> real Validation app binaries + tests
  -> candidate-source packager image
  -> real NSIS installer
  -> candidate-source signer image
  -> real development signing + independent signature verification
  -> real WineBot installation
  -> execute installed ValidationCLI.exe
  -> extract deterministic output
  -> exact postcondition assertion
```

The next distinct phase is **release qualification**, not more ordinary test ceremony:

```text
exact published image digests
  -> exact release artifact hashes
  -> first-party product qualification against those immutable identities
  -> selected external compatibility target(s)
```

## Core reliability principles

- Pull-first from approved GHCR images for ordinary consumption; candidate-source image construction is used when qualification/development requires it.
- No secrets/private keys in the repository.
- Containers run non-root where designed.
- Durable GitHub/repository evidence is authoritative; chat/agent session state is not.
- Deterministic checks should run in repository-native automation rather than consume repeated human/agent attention.
- Validation evidence must bind to exact source/artifact identities where material.
- A recurring check earns maintenance cost only when its failure changes a real engineering decision or uniquely protects a material invariant.
- Replacement evidence is established before a legacy check is removed.

## Documentation

- `docs/TESTING_CORRECTIVE_ACTION_PLAN.md` — active testing correction program and as-built P3 gate inventory.
- `docs/findings/testing-value-red-team-2026-09-02.md` — accepted red-team finding.
- `docs/STATE.md` — compact current project state and next action.
- `docs/USER_GUIDE.md` — user-oriented reference; verify against current command contracts when editing.
- `docs/CONTRACTS.md` — CLI/environment contracts.
- `docs/DAEMON_API_SECURITY_PLAN.md` — daemon security architecture.
- `AGENTS.md` / `docs/CONTEXT_BUNDLE.md` — agent working context and interruption-resumption projection.
- `docs/FORMAL_MODEL_HOWTO.md` — TLA+ model guidance.

For historical bring-up details, use Git history rather than treating old state claims as current qualification evidence.
