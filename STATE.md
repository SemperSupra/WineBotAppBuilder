# WBAB Project State - 2026-02-11

## Overview
The WineBotAppBuilder (WBAB) project is a production-ready containerized toolchain for Windows development on Linux. It features a modular architecture, formal modeling for idempotency, and automated release pipelines.

## Current Milestone: v0.2.0 - Bring-up Scaffold Complete
The bring-up phase is complete. The system is verified via a multi-component sample app and a formally modeled idempotent daemon.

### Key Components
- **`tools/wbab`**: Unified CLI for build, package, sign, and smoke test dispatch.
- **`core/wbab_core.py`**: Idempotent operation engine with file locking (`fcntl`) for concurrency safety.
- **`formal/tla/`**: Formal specification of the daemon's state machine and idempotency invariants.
- **`samples/validation-app/`**: Advanced sample app (DLL + CLI + GUI) used for E2E verification.
- **`.github/workflows/release.yml`**: Full CI/CD automation triggering on tag push (`v*`).

### Infrastructure
- **GHCR Images**: 
  - `ghcr.io/sempersupra/winebotappbuilder-winbuild:v0.2.0`
  - `ghcr.io/sempersupra/winebotappbuilder-packager:v0.2.0`
  - `ghcr.io/sempersupra/winebotappbuilder-signer:v0.2.0`
- **Release Assets**: `ValidationSetup.exe` (sample app installer).

## Achievements
- [x] Consolidate release automation into a single `release.yml` workflow.
- [x] Fix Hadolint and Shellcheck issues across the entire codebase (latest: SC2015 fix in policy tests).
- [x] Successfully verify the toolchain via real-world CMake/NSIS builds in CI.
- [x] Implement robust file locking in the daemon core to prevent state corruption.
- [x] Automate SBOM generation and vulnerability scanning in the release pipeline.
- [x] Full local verification suite pass (2026-02-13).
- [x] Audit for Correctness, Performance, and Security completed.
- [x] Integrated `lint` and `test` verbs into the unified `wbab` toolchain.

## Active Constraints
- **Pull-first Policy**: `tools/wbab` defaults to official GHCR images.
- **Security**: No local state or secrets in the repository.
- **Quality**: 100% pass rate on Lint, Unit, Contract, Policy, and E2E tests required for release.

## Next Steps
- [ ] Wait for community feedback on the `v0.2.0` milestone.
- [ ] Explore integration with additional signing providers (beyond dev-cert).
- [ ] Implement advanced preflight trend analysis for long-term health monitoring.
