# WineBotAppBuilder (WBAB)

A containerized toolchain for building, packaging, signing, and testing Windows applications from Linux.

## Current qualification status

WBAB contains real build, package, signing, Wine/WineBot, daemon, and release machinery, but the repository is **not currently qualified to claim the complete product path as production-proven**.

The 2026-09-02 testing red-team found that normal CI over-relies on fixtures, mocks, source-text policy checks, and workflow-shape checks. The corrective program is tracked in [issue #58](https://github.com/SemperSupra/WineBotAppBuilder/issues/58), with the accepted finding in `docs/findings/testing-value-red-team-2026-09-02.md` and the execution plan in `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`.

Important current limitation: the host wrappers for `wbab build`, `wbab package`, and `wbab sign` still default to fixture/scaffold behavior unless real execution is explicitly selected. The container images already contain real runners, but fixture defaults will not be treated as product qualification and are scheduled for correction under #58.

## What WBAB provides

- **Containerized Windows toolchain:** MinGW/CMake/Make-based build environment.
- **Containerized lint and test runners.**
- **NSIS packaging environment.**
- **Development signing path:** `osslsigncode` plus dev-certificate helpers.
- **WineBot smoke environment:** installer execution, optional application sanity run, screenshots/artifacts, and deterministic output extraction/verification.
- **Idempotent daemon core:** persistent operation state, retry/resume, audit, AuthN/AuthZ/TLS surfaces.
- **Structured planning:** `wbab plan` JSON for automation/agents.
- **First-party validation workload:** `samples/validation-app` includes a real DLL, CLI, GUI, tests, and NSIS installer.

## Evidence vocabulary

Do not treat all green checks as equivalent:

- `STATIC_CONTRACT` — source/config/schema shape only.
- `MOCKED_BEHAVIOR` — behavior with a material boundary simulated.
- `INFRASTRUCTURE_SMOKE` — real infrastructure/runtime without the complete product postcondition.
- `PRODUCT_QUALIFICATION` — real first-party product vertical with independent deterministic postcondition.
- `RELEASE_QUALIFICATION` — exact published images/artifacts qualified by immutable identities.

Normal CI currently produces primarily the first two classes. The existing opt-in `e2e-real` path is best described as infrastructure smoke until #58 P1 is complete.

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

Until #58 P2 lands, `build`, `package`, and `sign` must not be assumed to mean real product execution merely because the command returned success; inspect the selected runner/evidence class.

## Validation direction

The primary qualification target is the existing `samples/validation-app`:

```text
exact candidate source
  -> real winbuild image/toolchain
  -> real Validation app binaries
  -> real NSIS installer
  -> real dev signing + signature verification
  -> real WineBot installation
  -> execute installed ValidationCLI.exe
  -> extract deterministic output
  -> exact postcondition assertion
```

The intent is one actionable product truth test rather than many overlapping ceremony gates.

## Core reliability principles

- Pull-first from approved GHCR images by default for ordinary use; local toolchain image builds require explicit authority.
- No secrets/private keys in the repository.
- Containers run non-root where designed.
- Durable GitHub/repository evidence is authoritative; chat/agent session state is not.
- Deterministic checks should run in repository-native automation rather than consume repeated human/agent attention.
- Validation evidence must bind to exact source/artifact identities where material.
- A check earns recurring maintenance cost only when its failure changes a real engineering decision or uniquely protects a material invariant.

## Documentation

- `docs/TESTING_CORRECTIVE_ACTION_PLAN.md` — active testing correction program.
- `docs/findings/testing-value-red-team-2026-09-02.md` — accepted red-team finding.
- `docs/STATE.md` — compact current project state and next action.
- `docs/USER_GUIDE.md` — user-oriented reference (subject to current-state verification).
- `docs/CONTRACTS.md` — CLI/environment contracts.
- `docs/DAEMON_API_SECURITY_PLAN.md` — daemon security architecture.
- `AGENTS.md` / `docs/CONTEXT_BUNDLE.md` — agent working context.
- `docs/FORMAL_MODEL_HOWTO.md` — TLA+ model guidance.

For historical bring-up details, use Git history rather than treating old state claims as current qualification evidence.
