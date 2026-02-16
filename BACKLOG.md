# WBAB Reliability & Correctness Backlog

## Correctness & Reliability
- [x] **Item 1: Atomic Store Updates**: Move from truncate+write to write-and-rename for `OperationStore` to prevent data corruption.
- [x] **Item 2: Unbounded Git Timeouts**: Implement configurable timeouts for all Git operations in `GitSourceManager`.
- [x] **Item 3: Artifact Rollback**: Ensure `out/` and `dist/` directories are cleaned up on step failure to prevent partial artifact pollution.

## Performance & UX
- [ ] **Item 4: Configurable Backoff**: Expose `WBAB_RETRY_BACKOFF_BASE` for fine-tuning throttling. (Deferred)
- [ ] **Item 5: CI/CD Trivy Caching**: Implement `actions/cache` in GitHub workflows to persist the vulnerability database across runs. (Low Priority)
- [ ] **Item 6: mDNS Metadata Enhancement**: Add `version`, `auth_mode`, and `tls_enabled` to mDNS TXT records for better CLI pre-flight checks. (Deferred)
