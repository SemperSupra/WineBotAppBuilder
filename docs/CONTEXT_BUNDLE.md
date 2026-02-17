# CONTEXT_BUNDLE (read this first)

## Current milestone
**Bring-up scaffold (increments 0–3)**:
- repo structure + CI gates
- pull-first winbuild runner (GHCR)
- pull-first packaging runner (GHCR)
- concrete winbuild fixture build implementation (`tools/winbuild/build-fixture.sh`)
- concrete packaging NSIS fixture implementation (`tools/packaging/package-fixture.sh`)
- pull-first signing runner (GHCR)
- dev signing cert lifecycle script (`scripts/signing/dev-cert.sh`)
- production-like signing PKI lifecycle script (`scripts/signing/signing-pki.sh`)
- TLA+ idempotency/retry model skeleton (`formal/tla/DaemonIdempotency.tla`)
- optional extended TLA+ retry-counter invariants (`formal/tla/DaemonIdempotencyExtended.cfg`)
- pull-first WineBot runner (GHCR stable)
- contract docs + partially implemented CLI (`doctor`, `build`, `package`, `sign`, `smoke`, `plan`)
- unit tests for policies
- concrete publish Dockerfiles for winbuild/packaging/signing images
- core baseline library+daemon shim (`core/wbab_core.py`, `tools/wbabd`)
- `wbabd` API adapter surface for non-CLI clients (`tools/wbabd api`, optional `tools/wbabd serve`)
- append-only audit stream for cross-agent traceability (`agent-sandbox/state/audit-log.sqlite`)
- daemon API security hardening plan (`docs/DAEMON_API_SECURITY_PLAN.md`)
- daemon internal PKI helper for TLS/mTLS assets (`scripts/security/daemon-pki.sh`)
- daemon deploy profile for TLS/mTLS env mapping (`docs/DAEMON_DEPLOY_PROFILE.md`)
- daemon machine-readable deploy templates (`deploy/daemon/`)
- daemon startup preflight validator (`scripts/security/daemon-preflight.sh`)
- daemon preflight diagnostics surface (`agent-sandbox/state/preflight-status.json`, API ops, HTTP endpoints)
- daemon startup preflight trend counters (`agent-sandbox/state/preflight-counters.json`, `command.preflight` audit details)
- daemon preflight trend summary helper (`scripts/security/preflight-trend-report.sh`)
- daemon preflight trend threshold helper (`scripts/security/preflight-trend-threshold-check.sh`)

## Directory map
- `tools/` scripts intended to be used by consumers and CI
- `scripts/` repo maintenance scripts (lint, bootstrap)
- `tests/` unit/contract/policy tests
- `.github/workflows/` CI workflows
- `docs/` durable specs, contracts, state, decisions

## Canonical contracts
See `docs/CONTRACTS.md`.
This repo’s contract is tested by `tests/contract/`.
Formal model interpretation guide: `docs/FORMAL_MODEL_HOWTO.md`.

## Commands to run locally
```bash
./scripts/bootstrap-submodule.sh
./scripts/lint.sh
./tests/shell/run.sh
./tests/contract/run.sh
./tests/policy/run.sh
./tests/e2e/run.sh
# opt-in (requires real docker + WineBot submodule):
# ./tests/e2e/run-real.sh
# opt-in CI check for TLA+ skeleton contract:
# gh workflow run tla-skeleton-contract-optin.yml
```

TLA CI execution notes:
- Trigger the opt-in workflow manually from GitHub Actions, or run `gh workflow run tla-skeleton-contract-optin.yml`.
- The workflow validates `tests/policy/test_tla_idempotency_skeleton.sh` only (naming/invariant contract, not full TLC state-space checks).
- The workflow uploads `tla-formal-model-snapshot` with explicit TLA files (`DaemonIdempotency.tla`, `DaemonIdempotency.cfg`, `DaemonIdempotencyExtended.cfg`, `README.md`) plus `docs/FORMAL_MODEL_HOWTO.md` and `docs/CONTRACTS.md`.
- The workflow writes a file-list summary for that snapshot to `${GITHUB_STEP_SUMMARY}`.
- Release sign-off checklist requires reviewing the `tla-formal-model-snapshot` artifact contents for each opt-in run.
- Contributor usage criteria for the formal-model PR checklist line: see `docs/FORMAL_MODEL_HOWTO.md` (Contributor note).
- Recommended: include that checklist line for PRs that change formal models or retry/idempotency behavior.
- For signoff copy/paste, use the compact checklist example in `docs/CONTRACTS.md` (`Compact release-signoff checklist example`).
- Operator note: keep checklist text synchronized between `docs/CONTRACTS.md` (compact example) and `docs/FORMAL_MODEL_HOWTO.md` (PR checklist line example).

## CI gates
- lint
- shell-unit
- contract
- policy
- e2e-smoke (mocked pipeline)
- e2e-real (opt-in workflow_dispatch; real Docker/WineBot + artifact upload)
- policy-preflight-trend-gate-optin (opt-in workflow_dispatch; runs policy suite with `WBABD_POLICY_PREFLIGHT_TREND_GATE=1`)
- tla-skeleton-contract-optin (opt-in workflow_dispatch; validates TLA+ skeleton contract checks)
- tla-skeleton-contract-optin artifact (`tla-formal-model-snapshot`) includes formal model docs/config snapshot

## Default policies
- Prefer `docker compose` over `docker-compose`, but support both.
- Prefer official WineBot image `ghcr.io/mark-e-deyoung/winebot:v0.9.5` over local builds.
- No local builds unless explicitly enabled by env flags.

## Next increments (planned)
- Add winbuild container + fixture build
- Add packaging container + NSIS fixture installer
- Add artifact publishing for opt-in real e2e runs
- Add concrete Dockerfiles for release GHCR publish workflow outputs
- Add core daemon/library with idempotent command processing
- Add formal model (TLA+) and model-validated tests
