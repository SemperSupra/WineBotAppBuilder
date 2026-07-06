# WBAB Reliability & Correctness Backlog

## Correctness & Reliability
- [x] **Item 1: Atomic Store Updates**: Move from truncate+write to write-and-rename for `OperationStore` to prevent data corruption.
- [x] **Item 2: Unbounded Git Timeouts**: Implement configurable timeouts for all Git operations in `GitSourceManager`.
- [x] **Item 3: Artifact Rollback**: Ensure `out/` and `dist/` directories are cleaned up on step failure to prevent partial artifact pollution.

## Performance & UX
- [x] **Item 1: SQLite for Persistence**: Implemented SQLite-backed `OperationStore` and `AuditLog` for better scalability.
- [x] **Item 2: Worker Pool Control**: Implemented `asyncio.Semaphore` in `wbabd` to limit concurrent tasks.
- [x] **Item 3: Discovery Caching**: Implemented local caching of discovered daemon URLs in `wbab` CLI.
- [x] **Item 4: Configurable Backoff**: Expose `WBAB_RETRY_BACKOFF_BASE` and `WBAB_RETRY_BACKOFF_MAX` for fine-tuning retry throttling.
- [ ] **Item 5: CI/CD Trivy Caching**: Implement `actions/cache` in GitHub workflows to persist the vulnerability database across runs. (Low Priority)
- [ ] **Item 6: mDNS Metadata Enhancement**: Add `version`, `auth_mode`, and `tls_enabled` to mDNS TXT records for better CLI pre-flight checks. (Deferred)
- [ ] **Item 7: Git Mirrors**: Implement persistent Git mirrors in `agent-sandbox` to speed up source preparation. (Deferred)

## Security & Safety
- [x] **Item 1: Strict Path Jailing**: Implemented `Path.resolve()` checks in `Executor` to prevent directory traversal.
- [x] **Item 3: Non-Root Containers**: Updated all Dockerfiles to run as non-root user `wbab`.
- [x] **Item 5: Remote RCE Guard**: Shifted `Executor` to direct `docker run` execution, eliminating dependency on host-side shell scripts for core verbs.
- [x] **Item 8: TLS by Default**: Enforce HTTPS for all daemon communication using the internal PKI.
- [x] **Item 9: Docker Socket Protection**: Remove `docker.sock` mount from linter; linter tools only do filesystem-level scans.

## Test Engineering
- [x] **Item 10: Modernize Shell Unit Tests**: Transitioned `tests/shell/` and `tests/e2e/` to support containerized verification and Remote RCE Guard.
- [x] **Item 11: Python Unit Tests in CI**: Added `python-unit` job to `ci.yml` running `test_scm.py` and `test_wbabd_concurrency.py` with code coverage.
- [x] **Item 12: Code Coverage Measurement**: Added `coverage.py` to CI pipeline generating HTML reports uploaded as CI artifacts.
- [x] **Item 13: SBOM Validation**: Added `cyclonedx-cli` to linter container; SBOM is validated after generation during lint.
- [x] **Item 14: Image Vulnerability Scanning**: Added `trivy image` scan to release workflow, scanning each image after publish.
- [x] **Item 15: Build Output Structure Contract Test**: Added `tests/contract/test_build_output_structure.sh` validating build-real.sh output paths.
- [x] **Item 16: CLI UX Contract Tests**: Added `tests/contract/test_cli_ux.sh` validating help text, error messages, and command behavior.
- [x] **Item 17: Dependabot Configuration**: Added `.github/dependabot.yml` tracking pip, docker, and GitHub Actions dependencies weekly.

## Deferred Testing Improvements (GitHub Issues)
- [#20](https://github.com/SemperSupra/WineBotAppBuilder/issues/20) — **SLSA Build Provenance**: Add cryptographic attestation to release artifacts.
- [#21](https://github.com/SemperSupra/WineBotAppBuilder/issues/21) — **Local CI Workflow Testing**: Add nektos/act config for running GitHub Actions locally.
- [#22](https://github.com/SemperSupra/WineBotAppBuilder/issues/22) — **Property-Based Testing**: Add Hypothesis for fuzz-testing store/audit operations.

## Cross-Project Integration (2026-07-05 Analysis)
### WineBot → WBAB Improvements
- [ ] **Item W1: WineBot v0.9.5→v0.9.7 Upgrade**: Bump default tag across 6+ files. Requires validating v0.9.7's new recording API contract, resource guardrails, and temporal correctness features work with WBAB's existing smoke pipeline.
- [ ] **Item W2: Request Readiness Endpoint from WineBot**: Add `GET /ready` to WineBot API for deterministic smoke startup sequencing. WBAB would poll before exec-ing installer commands.
- [ ] **Item W3: Request Install API from WineBot**: Structured `POST /apps/install` replacing multi-step compose-exec installer dance with single API call returning exit code + file manifest.
- [ ] **Item W4: Request File Extraction API from WineBot**: `POST /files/read` replacing fragile `docker cp` + path-guessing logic in winebot-smoke.sh.
- [ ] **Item W5: Request User-Mode Cert Trust API from WineBot**: Single `POST /certs/trust` replacing dual-user (root+winebot) exec in winebot-trust-dev-cert.sh.
- [ ] **Item W6: Request CI Smoke Profile from WineBot**: `ci-smoke` compose profile that auto-captures evidence and produces structured `smoke-result.json`.
- [ ] **Item W7: Request Versioned API Contract from WineBot**: `GET /version` returning capabilities list for compatibility detection.

### WBAB → WinInspect Improvements
- [ ] **Item B1: WinInspect v0.4.0 Build Verification**: WinInspect v0.4.0 includes Wine 10.0 compatibility fixes with proven daemon stability on Wine (both platforms, 60s+ uptime). The MinGW cross-compilation path in `tools/winbuild/Dockerfile` may now be sufficient. Verify by attempting a build with WBAB's existing toolchain before pursuing MSVC options.
- [ ] **Item B2: C++ Linting in Linter Image**: Add `clang-format` and `clang-tidy` to `tools/linter/Dockerfile` for WinInspect's C++ codebase. Add C++ file detection to `scripts/lint-container.sh`. (Deferred — blocked on WinInspect build verification)
- [x] **Item B3: Go Toolchain in Winbuild Image**: Added `golang-go` package for WinInspect's Go components.
- [ ] **Item B4: Daemon-Aware Test Lifecycle**: Extend `test-real.sh` with pre/post command hooks for daemon-based test suites (required for WinInspect's daemon→client test pattern).
- [x] **Item B5: Recursive Submodule Support**: Added `WBAB_GIT_CLONE_RECURSIVE` env var to `GitSourceManager.prepare_source()`.
- [ ] **Item B6: WinInspect Contract Tests**: Add `tests/contract/test_wininspect_pipeline.sh` validating plan JSON shape for C++/CMake project type.
- [x] **Item B7: Project Type Auto-Detection**: Extended `wbab doctor` to recognize WinInspect-style projects (CMakeLists.txt + clients/ + daemon/) with targeted diagnostics.
