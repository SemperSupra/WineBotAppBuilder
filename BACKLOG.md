# WBAB Reliability & Correctness Backlog

## Correctness & Reliability
- [x] **Item 1: Atomic Store Updates**: Move from truncate+write to write-and-rename for `OperationStore` to prevent data corruption.
- [x] **Item 2: Unbounded Git Timeouts**: Implement configurable timeouts for all Git operations in `GitSourceManager`.
- [x] **Item 3: Artifact Rollback**: Ensure `out/` and `dist/` directories are cleaned up on step failure to prevent partial artifact pollution.

## Performance & UX
- [x] **Item 1: SQLite for Persistence**: Implemented SQLite-backed `OperationStore` and `AuditLog` for better scalability.
- [x] **Item 2: Worker Pool Control**: Implemented `asyncio.Semaphore` in `wbabd` to limit concurrent tasks.
- [x] **Item 3: Discovery Caching**: Implemented local caching of discovered daemon URLs in `wbab` CLI.
- [ ] **Item 4: Configurable Backoff**: Expose `WBAB_RETRY_BACKOFF_BASE` for fine-tuning throttling. (Deferred)
- [ ] **Item 5: CI/CD Trivy Caching**: Implement `actions/cache` in GitHub workflows to persist the vulnerability database across runs. (Low Priority)
- [ ] **Item 6: mDNS Metadata Enhancement**: Add `version`, `auth_mode`, and `tls_enabled` to mDNS TXT records for better CLI pre-flight checks. (Deferred)
- [ ] **Item 7: Git Mirrors**: Implement persistent Git mirrors in `agent-sandbox` to speed up source preparation. (Deferred)

## Security & Safety
- [x] **Item 1: Strict Path Jailing**: Implemented `Path.resolve()` checks in `Executor` to prevent directory traversal.
- [x] **Item 3: Non-Root Containers**: Updated all Dockerfiles to run as non-root user `wbab`.
- [x] **Item 5: Remote RCE Guard**: Shifted `Executor` to direct `docker run` execution, eliminating dependency on host-side shell scripts for core verbs.
- [ ] **Item 8: TLS by Default**: Enforce HTTPS for all daemon communication using the internal PKI. (High Priority)
- [ ] **Item 9: Docker Socket Protection**: Remove `docker.sock` mount from linter; transition to host-side image verification. (Medium Priority)

## Test Engineering
- [ ] **Item 10: Modernize Shell Unit Tests**: Transition `tests/shell/` from host-side mocking to containerized verification to support Remote RCE Guard. (High Priority)
