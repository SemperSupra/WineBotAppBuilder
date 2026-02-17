# Contracts

This document defines stable interfaces that must remain consistent across CLI/GUI/API and across automation/agent usage.
Tests in `tests/contract/` validate these contracts.

## Required verbs (v1 contract)
The CLI must expose these verbs (even if some are stubbed initially):

- `lint`    : run static analysis and code style checks on the project
- `test`    : run unit and integration tests for the project
- `build`   : build Win32/Win64 artifacts using the toolchain container
- `package` : package artifacts into installers (NSIS-first)
- `sign`    : sign artifacts (dev/test self-signed now; OV/EV later)
- `smoke`   : run installer in WineBot headless and collect evidence
- `doctor`  : verify local environment prerequisites
- `plan`    : emit an execution plan (JSON) without executing

## Required environment variables
- `WBAB_TAG` (recommended): toolchain image tag to pull (e.g., `v1.0.0`)
- `WBAB_ALLOW_LOCAL_BUILD` (default `0`): allow building toolchain images locally
- `WBAB_WINEBOT_IMAGE` (default `ghcr.io/mark-e-deyoung/winebot`): WineBot image
- `WBAB_WINEBOT_TAG` (default `v0.9.5`): WineBot image tag
- `WBAB_WINEBOT_PROFILE` (default `headless`): compose profile
- `WBAB_WINEBOT_SERVICE` (default `winebot`): compose service name

## Optional environment variables (implemented in scaffold)
- `WBAB_TOOLCHAIN_IMAGE` (default `ghcr.io/sempersupra/winebotappbuilder-winbuild`): winbuild image
- `WBAB_TOOLCHAIN_DOCKERFILE` (default `tools/winbuild/Dockerfile`): local toolchain Dockerfile path
- `WBAB_BUILD_CMD` (default creates `out/FakeApp.exe` and `out/build-fixture.txt`): build command executed in toolchain container
- `WBAB_LINT_CMD` (default `wbab-lint`): lint command executed in toolchain container
- `WBAB_TEST_CMD` (default `wbab-test`): test command executed in toolchain container
- `WBAB_EXECUTION_TIMEOUT_SECS` (default `3600`): max seconds for a single execution step
- `WBAB_PACKAGER_IMAGE` (default `ghcr.io/sempersupra/winebotappbuilder-packager`): packager image
- `WBAB_PACKAGER_DOCKERFILE` (default `tools/packaging/Dockerfile`): local packager Dockerfile path
- `WBAB_PACKAGE_CMD` (default consumes `out/FakeApp.exe`, creates `dist/FakeSetup.exe` + `dist/package-fixture.txt`): package command executed in packager container
- `WBAB_SIGNER_IMAGE` (default `ghcr.io/sempersupra/winebotappbuilder-signer`): signer image
- `WBAB_LINTER_IMAGE` (default `ghcr.io/sempersupra/winebotappbuilder-linter`): linter image
- `WBAB_SIGNER_DOCKERFILE` (default `tools/signing/Dockerfile`): local signer Dockerfile path
- `WBAB_SIGN_CMD` (default consumes `dist/FakeSetup.exe`, creates `dist/FakeSetup-signed.exe` + `dist/sign-fixture.txt`): sign command executed in signer container
- `WBAB_SIGN_USE_DEV_CERT` (default `0`): enable dev-cert signing mode (uses cert lifecycle material + `osslsigncode`)
- `WBAB_SIGN_AUTOGEN_DEV_CERT` (default `1` when dev-cert mode is enabled): auto-init cert material if missing
- `WBAB_DEV_CERT_DIR` (default `.wbab/signing/dev`): location for dev cert/key/pfx/pass
- `WBAB_SIGNING_PKI_DIR` (default `.wbab/signing/pki`): production-like signing PKI helper output directory (`ca` + `codesign` material)
- `WBAB_SIGN_INPUT` (default `dist/FakeSetup.exe`): signing input for dev-cert mode
- `WBAB_SIGN_OUTPUT` (default `dist/FakeSetup-signed.exe`): signing output for dev-cert mode
- `WBAB_SMOKE_SKIP_INSTALL` (default `0`): skip WineBot install step (`1` for infrastructure-only smoke checks)
- `WBAB_SMOKE_TRUST_DEV_CERT` (default `0`): import dev cert into WineBot trust stores before installer run
- `WBAB_REAL_INSTALLER_PATH` (used by real e2e path): required when `WBAB_SMOKE_SKIP_INSTALL=0` in scaffold e2e
- `WBAB_INSTALLER_VALIDATION_ARTIFACT_DIR` (default `artifacts/e2e-real/installer-validation`): destination for installer checksum/manifest evidence
- `WBAB_SMOKE_SESSION_ID` (default UTC timestamp): logical smoke session identifier used in artifact paths
- `WBAB_ARTIFACTS_DIR` (default `artifacts/winebot/<session-id>`): output directory for smoke logs/evidence capture
- `WBABD_AUDIT_LOG_PATH` (default `agent-sandbox/state/audit-log.sqlite`): SQLite audit event database path
- `WBABD_STORE_PATH` (default `agent-sandbox/state/core-store.sqlite`): SQLite operation store path
- `WBABD_ACTOR` (default `unknown`): actor identity stamped on every audit event (user/agent/system)
- `WBABD_SESSION_ID` (default empty): correlation identifier for related command sequences
- `WBABD_AUTH_MODE` (default `token` for `wbabd serve`, `off` otherwise): daemon auth mode (`off` or `token`)
- `WBABD_API_TOKEN` (optional for local; required when `WBABD_AUTH_MODE=token` and `serve` is used): bearer token value
- `WBABD_API_TOKEN_FILE` (optional alternative to `WBABD_API_TOKEN`): path to bearer token file
- `WBABD_AUTHZ_POLICY_FILE` (optional): JSON policy file enabling AuthZ allow-list enforcement (default deny when enabled)
- `WBABD_PRINCIPAL` (default `WBABD_ACTOR` then `unknown`): principal identity for daemon AuthZ checks
- `WBABD_TLS_CERT_FILE` (optional): server certificate path for `wbabd serve` TLS mode
- `WBABD_TLS_KEY_FILE` (optional): server private key path for `wbabd serve` TLS mode
- `WBABD_TLS_CLIENT_CA_FILE` (optional): client CA bundle path enabling mTLS (`CERT_REQUIRED`)
- `WBABD_HTTP_MAX_BODY_BYTES` (default `1048576`): maximum HTTP request body size in bytes
- `WBABD_HTTP_REQUEST_TIMEOUT_SECS` (default `15`): per-request socket timeout seconds
- `WBABD_PKI_DIR` (default `agent-privileged/daemon-pki`): internal PKI helper output directory for CA/server/client material
- `WBABD_PREFLIGHT_STATUS_PATH` (default `agent-sandbox/state/preflight-status.json`): persisted startup preflight diagnostics summary path
- `WBABD_PREFLIGHT_COUNTERS_PATH` (default `agent-sandbox/state/preflight-counters.json`): persisted startup preflight pass/fail counters path
- `WBABD_PREFLIGHT_AUDIT_WINDOW` (default `50`): recent `command.preflight` audit events to include in trend report helper/daemon trend API output
- `WBABD_POLICY_PREFLIGHT_TREND_GATE` (default `0`): opt-in policy gate toggle for threshold validation against `preflight_trend` output

## Output layout (target)
- `workspace/` : project source and scripts
- `agent-sandbox/` : non-elevated state and artifacts
  - `agent-sandbox/out/` : build outputs
  - `agent-sandbox/dist/`: deliverables (installers, signed artifacts)
  - `agent-sandbox/artifacts/` : test evidence and logs
  - `agent-sandbox/state/core-store.sqlite` : SQLite operation store
  - `agent-sandbox/state/audit-log.sqlite` : SQLite audit stream
- `agent-privileged/` : sensitive configuration and PKI
  - `agent-privileged/signing/` : code signing material
  - `agent-privileged/daemon-pki/` : internal daemon PKI assets
- `manual/` : human-managed documentation and archives
- `scripts/security/preflight-trend-report.sh` : summarize cumulative preflight counters + recent `command.preflight` audit window
- `scripts/security/preflight-trend-threshold-check.sh` : evaluate operator thresholds against `preflight_trend` output
- `tools/winbuild/build-fixture.sh` : fixture Win32/Win64 build implementation path for containerized `wbab build`
- `tools/packaging/package-fixture.sh` : NSIS fixture installer implementation path for containerized `wbab package`
- `scripts/signing/signing-pki.sh` : production-like signing PKI lifecycle helper (`init/rotate/status/export/import`)
- `formal/tla/DaemonIdempotency.tla` + `formal/tla/DaemonIdempotency.cfg` : initial formal model skeleton for daemon idempotency and retry/resume invariants
- `formal/tla/README.md` : model-checking run instructions and expected invariant checks for the TLA+ skeleton
- `formal/tla/DaemonIdempotencyExtended.cfg` : optional extended invariant set for step-level retry counters
- `docs/FORMAL_MODEL_HOWTO.md` : translation guide linking formal model variables/invariants to daemon store fields and audit events
- Formal-model checklist usage guidance (when to include PR checklist line for formal/retry-impacting changes): `docs/FORMAL_MODEL_HOWTO.md` and `docs/CONTEXT_BUNDLE.md` (TLA CI execution notes)
- Compact release-signoff checklist example:
  - `- [ ] Formal-model release note snippet added (workflow `tla-skeleton-contract-optin`, artifact `tla-formal-model-snapshot` reviewed).`
- `wbabd` API surface (local JSON adapter, optional HTTP adapter):
  - local adapter: `wbabd api '{"op":"health"}'`
  - local adapter: `wbabd api '{"op":"preflight_status"}'`
  - local adapter: `wbabd api '{"op":"preflight_trend","window":25}'`
  - local adapter: `wbabd api '{"op":"plan","op_id":"...","verb":"...","args":[]}'`
  - local adapter: `wbabd api '{"op":"run","op_id":"...","verb":"...","args":[]}'`
  - local adapter: `wbabd api '{"op":"status","op_id":"..."}'`
  - optional HTTP adapter (`wbabd serve`): `GET /health`, `GET /preflight-status`, `GET /preflight-trend`, `POST /plan`, `POST /run`, `GET /status/<op_id>`

## Policy constraints (must hold)
- If `WBAB_ALLOW_LOCAL_BUILD != 1`, the system must not invoke `docker build` for build/package/sign images.
- WineBot runs are pull-first from GHCR; local WineBot build path is disabled.
- CI policy: prefer official `ghcr.io/mark-e-deyoung/winebot:v0.9.5` for WineBot runs.
- Commit policy: one git commit per requested implementation change unless the user explicitly requests batching.
- Build/package default fixture commands must use concrete container scripts (`tools/winbuild/build-fixture.sh`, `tools/packaging/package-fixture.sh`) with output validation.
- Core baseline policy: repeated `wbabd run <same-op-id> ...` must not re-execute succeeded operations.
  - step-level resume: on retry, steps marked `succeeded` must be skipped; failed step is retried
  - persistent step state must include per-step status/attempt counters
  - API/CLI parity: API `run` for a succeeded `op_id` must return cached result semantics (local adapter and HTTP adapter)
  - store schema: `.wbab/core-store.json` uses `schema_version: "wbab.store.v1"`
  - migration hook: unversioned legacy store files must auto-migrate in place while preserving `operations`
- Audit policy:
  - audit stream is append-only JSONL with schema `wbab.audit.v1`
  - every event includes `event_id`, `ts`, `source`, `actor`, `session_id`, `event_type`, `op_id`, and `verb`
  - command and operation lifecycle events must be emitted (`command.*`, `operation.*`, `step.*`)
  - startup preflight audit events (`command.preflight`) must include cumulative pass/fail counters in `details.counters`
- Daemon API security policy:
  - hardening plan must exist at `docs/DAEMON_API_SECURITY_PLAN.md`
  - plan must define threat model, AuthN/AuthZ controls, transport hardening, rollout strategy, and acceptance criteria
  - Phase 1: `wbabd serve` must fail closed when token auth is enabled and no token config is provided
  - Phase 1: token-protected HTTP endpoints must return `401` for missing/invalid bearer tokens
  - Phase 2: when `WBABD_AUTHZ_POLICY_FILE` is set, daemon operations must enforce allow-list permissions per principal
  - Phase 2: denied operations must return `403` and emit `authz.denied` audit events
  - Phase 3: TLS mode must require cert+key pair and support optional mTLS client CA enforcement
  - Phase 3: HTTP adapter must enforce request body size and request timeout limits
  - Internal PKI helper script `scripts/security/daemon-pki.sh` must support init/rotate/status/export/import lifecycle commands
  - Deploy profile doc `docs/DAEMON_DEPLOY_PROFILE.md` must map PKI outputs to `WBABD_TLS_*` and token env vars for `wbabd serve`
  - Deploy profile doc must include `systemd` and containerized private-network runtime examples
  - Deploy profile doc must include zero-downtime cert/token rotation steps with rollback guidance
  - Machine-readable deploy templates must exist under `deploy/daemon/` for systemd env, container env, and authz policy
  - Startup validation helper `scripts/security/daemon-preflight.sh` must validate TLS/authz/token/limit config before daemon start
  - Policy gate must include a smoke check that executes preflight against deploy templates
  - `wbabd serve --preflight` must execute inline preflight checks before binding listener sockets
  - daemon API must expose preflight trend summary via local op `preflight_trend` and HTTP `GET /preflight-trend`
  - `scripts/security/preflight-trend-report.sh` must summarize trend from `.wbab/preflight-counters.json` and recent `command.preflight` audit events
  - optional policy gate must support threshold validation against daemon `preflight_trend` output when explicitly enabled
- Publish-image contract:
  - publish workflow must tag images with release tag and `latest`
  - publish workflow must set OCI source/revision/version labels
  - publish workflow must capture and upload image digest metadata
  - publish workflow must include Dockerfile hardening lint and a blocking vulnerability scan
  - publish workflow must emit CycloneDX SBOM evidence
