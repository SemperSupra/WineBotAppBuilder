# WineBotAppBuilder (bring-up scaffold)

This zip contains the initial bring-up files for the **WineBotAppBuilder** project:
- repo governance + agent-friendly docs
- pull-first winbuild runner script (containerized build; no local builds by default)
- pull-first packaging runner script (containerized package; no local builds by default)
- concrete winbuild fixture script (`tools/winbuild/build-fixture.sh`)
- concrete packaging fixture script (`tools/packaging/package-fixture.sh`)
- pull-first signing runner script (containerized sign; no local builds by default)
- dev signing cert lifecycle script (`scripts/signing/dev-cert.sh`)
- production-like signing PKI lifecycle script (`scripts/signing/signing-pki.sh`)
- TLA+ model skeleton for daemon idempotency/retry (`formal/tla/DaemonIdempotency.tla`)
- optional extended TLA+ invariants config for step retry counters (`formal/tla/DaemonIdempotencyExtended.cfg`)
- pull-first WineBot runner scripts (prefers official GHCR stable, no local builds by default)
- contract tests (CLI verbs, env vars)
- CI gates (lint + unit + contract + policy + mocked e2e-smoke)
- opt-in real e2e workflow (`workflow_dispatch`) for non-mocked Docker/WineBot validation
- real e2e workflow uploads `artifacts/`, `out/`, and `dist/` for post-run evidence
- real e2e path validates non-fixture installer input and records checksum/manifest evidence
- release-only GHCR publish workflow for WBAB images (`.github/workflows/release.yml`)
- core baseline planner/executor + idempotent op store (`core/wbab_core.py`, `tools/wbabd`)
- daemon shim API for non-CLI adapters via `tools/wbabd api` (optional HTTP via `tools/wbabd serve`)
- append-only audit stream for command/operation traceability (`.wbab/audit-log.jsonl`)
- daemon API security hardening plan (`docs/DAEMON_API_SECURITY_PLAN.md`)
- daemon internal PKI helper (`scripts/security/daemon-pki.sh`)
- daemon deploy profile (`docs/DAEMON_DEPLOY_PROFILE.md`)
- daemon deploy templates (`deploy/daemon/`)
- daemon preflight validation script (`scripts/security/daemon-preflight.sh`)
- daemon preflight diagnostics summary (`.wbab/preflight-status.json`, `preflight_status`)
- daemon preflight trend counters (`.wbab/preflight-counters.json`, `command.preflight` counters)
- daemon preflight trend report helper (`scripts/security/preflight-trend-report.sh`)
- daemon preflight trend threshold gate helper (`scripts/security/preflight-trend-threshold-check.sh`)
- daemon preflight trend API (`preflight_trend`, `/preflight-trend`)
- opt-in CI policy workflow enabling trend threshold gate (`.github/workflows/policy-preflight-trend-gate-optin.yml`)

## How to build your own application

See the [User Guide](docs/USER_GUIDE.md) for step-by-step instructions on building, packaging, signing, and testing your Windows apps.

## Quick start

```bash
unzip winebot-appbuilder-bringup.zip
cd winebot-appbuilder-bringup
git init
./scripts/bootstrap-submodule.sh
git add .
git commit -m "Initial bring-up scaffold"
```

### Add WineBot as a submodule
This scaffold includes a placeholder directory at `tools/WineBot/` so paths are stable, but you should replace it with a real submodule:

```bash
./scripts/bootstrap-submodule.sh
```

## Core philosophy

- The **core** must be usable concurrently by CLI/GUI/API without interference.
- Idempotency is required for all operations, regardless of activation path.
- UI-specific behavior lives outside core.
- Default policy: **prefer GHCR** (pull-first), do not build locally unless explicitly enabled.
- Toolchain build execution: pull-first runner (`tools/winbuild-build.sh`) via `wbab build`.
- Installer packaging execution: pull-first runner (`tools/package-nsis.sh`) via `wbab package`.
- Artifact signing execution: pull-first runner (`tools/sign-dev.sh`) via `wbab sign`.
- WineBot execution: **prefer official `ghcr.io/mark-e-deyoung/winebot:v0.9.5`** over local build.

See:
- `AGENTS.md`
- `docs/CONTEXT_BUNDLE.md`
- `docs/CONTRACTS.md`
