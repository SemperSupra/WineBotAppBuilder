# WBAB Project State - 2026-07-05

## Overview
The WineBotAppBuilder (WBAB) project has transitioned from a bring-up scaffold to a production-hardened, scalable, and secure containerized toolchain for Windows development.

## Current Milestone: v0.3.7 - Production Stable
The system is now fully stabilized, featuring a hardened CI/CD pipeline, SQLite persistence, and non-root container security.

### Key Components
- **`tools/wbab`**: Production CLI with **Auto-Discovery** (mDNS), discovery caching, and `v0.3.x` container integration.
- **`tools/wbabd`**: Async daemon with **Worker Pool Control** and SQLite-backed `OperationStore` and `AuditLog`.
- **`core/wbab_core.py`**: Hardened core with **Strict Path Jailing** and **Remote RCE Guard** (direct Docker execution).
- **`agent-sandbox/`**: Standardized directory for all agent-managed state and build artifacts.
- **`.github/workflows/`**: Robust **Release Automation** workflow with workspace permission normalization.

### Infrastructure
- **GHCR Images (v0.3.7 / latest)**: 
  - `ghcr.io/sempersupra/winebotappbuilder-winbuild`
  - `ghcr.io/sempersupra/winebotappbuilder-packager`
  - `ghcr.io/sempersupra/winebotappbuilder-signer`
  - `ghcr.io/sempersupra/winebotappbuilder-linter`
- **Security**: All containers run as restricted user `wbab` (UID 1000).

## Achievements
- [x] **CI/CD Reliability**: Resolved all workspace permission issues and synchronized local/remote test environments.
- [x] **Correctness**: Implemented atomic state updates via SQLite and clean artifact rollbacks.
- [x] **Security**: Enforced strict path jailing, non-root containers, and Remote RCE guards.
- [x] **Test Engineering**: Modernized 100% of test suites to support the hardened architecture.

## Active Constraints
- **Policy Enforcement**: Strict adherence to `ORGANIZATION_POLICY.md` (4-tier structure) and `LINT_POLICY.md`.
- **Security**: No host-side script execution for core verbs in production.
- **WineBot version pin**: WBAB pins WineBot at `v0.9.5` in 6+ files; upstream is `v0.9.7`. Gap includes resource guardrails, temporal correctness, recording contracts, and lifecycle hardening.
- **MSVC/MinGW blocker**: `tools/winbuild/Dockerfile` provides MinGW cross-compilation only (`x86_64-w64-mingw32-gcc/g++`). WinInspect requires MSVC (Visual Studio Build Tools + Windows SDK). This is the fundamental architecture mismatch preventing WBAB from building WinInspect.

## Next Steps
- [ ] **Issue #7**: Implement Web-Based Operations Dashboard.
- [ ] **Issue #8**: Enable TLS by default for daemon communication.
- [ ] **Issue #3**: Implement Declarative Dependency Management ("Vending Machine").
- [ ] **WineBot v0.9.7 upgrade**: Bump `WBAB_WINEBOT_TAG` default to `v0.9.7` across all integration points and validate recording API convergence model works with existing winebot-smoke.sh.
- [ ] **MSVC build path for WinInspect**: Create MSVC-capable winbuild variant (`tools/winbuild/Dockerfile.msvc` or separate image) using `msvc-wine` or native Windows runner to enable building WinInspect within WBAB's pipeline.
- [ ] **C++ linting support**: Extend linter image with `clang-format` and `clang-tidy` for WinInspect's C++ codebase.
- [ ] **WinInspect contract tests**: Add pipeline shape validation for C++/CMake projects following WinInspect's daemon/client architecture.
