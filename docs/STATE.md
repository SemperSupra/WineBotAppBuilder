# Project State

**Date:** 2026-02-09

## Status
Bring-up scaffold created and partially implemented. `doctor`, `build`, `package`, `sign`, `smoke`, and `plan` are now
functional CLI paths. The repo currently provides scaffolding, policy scripts, CI gates, and documentation structure.
Real toolchain build/packaging logic is implemented in local scripts and Dockerfiles, pending image publication.
TLA+ formal model expanded to cover full daemon lifecycle (step-level retry/resume).
**Validation Sample App** (`samples/validation-app`) successfully verified with automated end-to-end correctness evaluation.
Dependency versions (`hadolint`, `trivy`) updated to latest stable.

## What is included
- Pull-first WineBot runner scripts (GHCR stable preferred)
- Pull-first winbuild runner script (containerized build execution)
- Pull-first packaging runner script (NSIS-first containerized packaging execution)
- Concrete winbuild fixture build implementation path (`tools/winbuild/build-fixture.sh`, default in `tools/winbuild-build.sh`)
- Concrete packaging NSIS fixture installer implementation path (`tools/packaging/package-fixture.sh`, default in `tools/package-nsis.sh`)
- Real winbuild execution logic (`tools/winbuild/build-real.sh`) supporting CMake/Makefile cross-compilation
- Real packaging execution logic (`tools/packaging/package-real.sh`) supporting NSIS
- **Advanced Validation Sample App** (`samples/validation-app`):
    - **Shared Idempotent Core** (`ValidationCore.dll`): Decoupled logic for file writing.
    - **CLI Interface** (`ValidationCLI.exe`): Uses Core DLL, verified in smoke test.
    - **GUI Interface** (`ValidationGUI.exe`): Uses Core DLL, supports interactive editing and automated timeout runs.
    - **Automated Correctness Verification**: `wbab smoke` extended to extract container artifacts and verify file content.
    - **Verified Lifecycle**: Full build/package/sign/smoke pipeline confirmed with automated content assertion.
- Pull-first signing runner script (dev/test containerized signing execution)
- Compose wrapper
- Contract docs + tests
- `wbab doctor` environment checks
- `wbab build` dispatch to winbuild runner
- `wbab package` dispatch to packaging runner
- `wbab sign` dispatch to signing runner
- `wbab smoke` dispatch to WineBot smoke runner
- `wbab plan` JSON output for `build`, `package`, `sign`, `smoke`, and `doctor`
- CI gates (lint/shell-unit/contract/policy/e2e-smoke)
- Mocked e2e pipeline test (`build -> package -> sign -> smoke`)
- Opt-in real Docker/WineBot e2e workflow (`.github/workflows/e2e-real.yml`)
- Policy checks enforcing official WineBot source (`ghcr.io/mark-e-deyoung/winebot:stable`)
- Real e2e workflow artifact upload (`actions/upload-artifact`) for `artifacts/`, `out/`, and `dist/`
- Default fixture wiring across pipeline: `out/FakeApp.exe` -> `dist/FakeSetup.exe` -> `dist/FakeSetup-signed.exe`
- Dev signing certificate lifecycle scripts (`scripts/signing/dev-cert.sh`) with init/rotate/export/import/status
- Production-like signing PKI lifecycle helper (`scripts/signing/signing-pki.sh`) with init/rotate/status/export/import
- Expanded TLA+ model skeleton (`formal/tla/DaemonIdempotency.tla`) covering full daemon lifecycle (step-level states, resume-on-retry) with optional extended step-level retry counters
- Release-only GHCR publish workflow for WBAB images (`.github/workflows/release.yml`)
- WineBot cert trust/import helper (`tools/winebot-trust-dev-cert.sh`) and real-e2e installer requirement when install is enabled
- Concrete publish Dockerfiles: `tools/winbuild/Dockerfile`, `tools/packaging/Dockerfile`, `tools/signing/Dockerfile`
- Policy gate enforces publish Dockerfiles use `debian:trixie-slim` and disallow `ubuntu` base images
- Publish Dockerfile dry-check helper validates all publish Dockerfiles via `docker buildx build --check` (`scripts/publish/dockerfiles-drycheck.sh`)
- Publish workflow references dry-check helper for local/CI parity before push (`.github/workflows/release.yml`)
- Shell gate validates publish workflow order keeps dry-check step before image push step (`tests/shell/test_publish_workflow_drycheck_order.sh`)
- Policy gate validates publish workflow order keeps dry-check step before image push step (`tests/policy/test_publish_security_gates.sh`)
- Policy gate enforces dry-check step runs before GHCR login (fail-fast before credentials) and login runs before image push step
- Shell parity gate enforces publish workflow sequencing `dry-check < GHCR login < publish` (`tests/shell/test_publish_workflow_drycheck_order.sh`)
- Shell parity gate enforces dry-check helper path usage in publish workflow (`scripts/publish/dockerfiles-drycheck.sh`)
- Policy gate keeps dry-check step name stable (`Dry-check publish Dockerfiles (local/CI parity)`) for workflow contract consistency
- Policy gate keeps GHCR login and publish step names stable for workflow contract consistency
- Policy and shell gates enforce publish workflow ordering `buildx < dry-check < GHCR login < publish`
- Policy gate pins Buildx setup action version in publish workflow (`docker/setup-buildx-action@v3`)
- Shell parity gate pins Buildx setup action version in publish workflow (`docker/setup-buildx-action@v3`)
- Shell parity gate pins GHCR login action version in publish workflow (`docker/login-action@v3`)
- Policy + shell parity gates pin Hadolint action version (`hadolint/hadolint-action@v3.3.0`) across all three publish lint steps
- Policy + shell parity gates pin Trivy action version (`aquasecurity/trivy-action@0.29.0`) across both security and SBOM steps
- Policy + shell parity gates pin publish metadata upload action version (`actions/upload-artifact@v4`)
- Policy + shell parity gates pin checkout action version in publish workflow (`actions/checkout@v4`)
- Policy + shell parity gates pin checkout setting `submodules: false` in publish workflow
- Policy + shell parity gates enforce publish workflow permissions (`contents: read`, `packages: write`)
- Policy + shell parity gates pin publish trigger contract (`release` + `types: [published]`, no `push`)
- Policy + shell parity gates pin publish metadata artifact contract (`publish-ghcr-metadata`, `artifacts/**`, `if-no-files-found: warn`)
- Policy + shell parity gates pin Buildx step/action adjacency (`Set up Docker Buildx` + `docker/setup-buildx-action@v3` in same step block)
- Policy + shell parity gates pin GHCR login step/action adjacency (`Log in to GHCR` + `docker/login-action@v3` in same step block)
- Policy + shell parity gates pin dry-check step/command adjacency (`Dry-check publish Dockerfiles (local/CI parity)` + `scripts/publish/dockerfiles-drycheck.sh` in same step block)
- Policy + shell parity gates pin upload step/action adjacency (`Upload publish metadata` + `actions/upload-artifact@v4` in same step block)
- Policy + shell parity gates pin upload metadata fields adjacency (`name/path/if-no-files-found`) inside `Upload publish metadata` step block
- Policy + shell parity gates pin publish step command adjacency (`Publish images...` keeps `docker buildx build` with `--push` in the same step block)
- Policy + shell parity gates pin publish metadata-digest handling adjacency (`--metadata-file`, `containerimage.digest`, `artifacts/publish-digests.txt`) inside publish step block
- Policy + shell parity gates pin GHCR login credential-field adjacency (`registry: ghcr.io`, `username: ${{ github.actor }}`, `password: ${{ secrets.GITHUB_TOKEN }}`) inside login step block
- Policy + shell parity gates pin publish env contract adjacency (`OWNER`, `TAG`, `REPO`, `SHA`) inside publish step block
- Policy + shell parity gates pin publish OCI label adjacency (`source`, `revision`, `version`, `title`) inside publish step block
- Policy + shell parity gates pin publish mapping adjacency (`publish_if_exists` calls for winbuild/packager/signer) inside publish step block
- Policy + shell parity gates pin publish owner/image construction adjacency (`owner_lc` normalization + `ghcr.io/${owner_lc}/${image_name}`) inside publish step block
- Policy + shell parity gates pin publish missing-Dockerfile guard adjacency (`[[ ! -f "${dockerfile}" ]]`, `SKIP: missing`, `return 0`) inside `publish_if_exists`
- Policy + shell parity gates pin publish missing-digest fail-closed adjacency (`[[ -z "${digest}" ]]`, error message, `exit 1`) inside `publish_if_exists`
- Policy + shell parity gates pin `publish_if_exists` argument contract adjacency (`local dockerfile="$1"`, `local image_name="$2"`) inside function block
- Policy + shell parity gates pin publish artifact-manifest prep adjacency (`mkdir -p artifacts`, `: > artifacts/publish-digests.txt`) inside publish step block
- Policy + shell parity gates pin publish metadata-file path adjacency (`local metadata_file="artifacts/${image_name}.metadata.json"`) inside publish step block
- Policy + shell parity gates pin digest-manifest line format adjacency (`"${image}:${TAG}@${digest}" >> artifacts/publish-digests.txt`) inside publish step block
- Policy + shell parity gates pin digest extraction command adjacency (`jq -r '.["containerimage.digest"] // empty' "${metadata_file}"`) inside `publish_if_exists`
- Policy + shell parity gates pin `publish_if_exists` definition-before-call adjacency inside publish step block
- Policy + shell parity gates pin publish step fail-fast command adjacency (`set -euo pipefail`) inside publish step block
- Policy + shell parity gates pin dry-check step fail-fast adjacency (`set -euo pipefail` + `scripts/publish/dockerfiles-drycheck.sh`) inside dry-check step block
- Policy + shell parity gates pin upload step `if: always()` adjacency inside `Upload publish metadata` step block
- Policy + shell parity gates pin publish provenance flag adjacency (`--provenance=true`) inside publish step block
- Policy + shell parity gates pin publish SBOM flag adjacency (`--sbom=true`) inside publish step block
- Policy + shell parity gates pin publish tag adjacency (`--tag "${image}:${TAG}"` + `--tag "${image}:latest"`) inside publish step block
- Policy + shell parity gates pin publish announce-log adjacency (`echo "Publishing ${image}:${TAG}"`) inside publish step block
- Policy + shell parity gates pin publish Dockerfile-flag adjacency (`--file "${dockerfile}"`) inside publish step block
- Policy + shell parity gates pin publish build-context adjacency (`.`) inside publish step block
- Policy + shell parity gates pin publish digest-assignment adjacency (`digest="$(jq -r ... "${metadata_file}")"`) inside `publish_if_exists`
- Policy + shell parity gates pin publish mapping call-order adjacency (`winbuild -> packaging -> signing`) inside publish step block
- Policy + shell parity gates pin publish OCI label value adjacency (source/revision/version/title using `REPO`, `SHA`, `TAG`, `image_name`) inside publish step block
- Validated real-installer artifact gate in opt-in e2e path (`tests/e2e/validate-installer-artifact.sh`)
- Core baseline planner/executor with idempotent operation store (`core/wbab_core.py`, `tools/wbabd`)
- Core baseline extended with persistent step-level state and retry/resume semantics
- Core store schema versioning + legacy migration hook (`schema_version: wbab.store.v1`)
- Core daemon shim API surface for non-CLI adapters (`tools/wbabd api`, optional `tools/wbabd serve`)
- Phase 1 token auth enforcement for `wbabd serve` (fail-closed startup + bearer-token `401` paths)
- Phase 2 AuthZ allow-list enforcement (`WBABD_AUTHZ_POLICY_FILE`, `WBABD_PRINCIPAL`, `403` + `authz.denied`)
- Phase 3 transport hardening (`wbabd serve` TLS/mTLS + request size/timeout limits)
- Internal PKI bootstrap/rotation helper for daemon TLS assets (`scripts/security/daemon-pki.sh`)
- Daemon deploy profile doc mapping PKI outputs to `wbabd serve` TLS/mTLS env vars (`docs/DAEMON_DEPLOY_PROFILE.md`)
- Daemon runtime examples for `systemd` and containerized private-network deployment (`docs/DAEMON_DEPLOY_PROFILE.md`)
- Deploy-time cert/token rotation playbook steps for zero-downtime daemon restarts (`docs/DAEMON_DEPLOY_PROFILE.md`)
- Machine-readable deploy templates for systemd/container env and authz policy (`deploy/daemon/`)
- Daemon preflight validation helper for TLS/authz/token/limit startup checks (`scripts/security/daemon-preflight.sh`)
- CI smoke check for daemon preflight against deploy templates (`tests/policy/test_daemon_preflight_templates_smoke.sh`)
- Optional `wbabd serve --preflight` inline startup validation before listener bind
- Preflight diagnostics summary surface (`.wbab/preflight-status.json`, API `preflight_status`, HTTP `/preflight-status`)
- Startup preflight trend counters (`.wbab/preflight-counters.json`, `command.preflight` audit counters)
- Startup preflight trend summary helper (`scripts/security/preflight-trend-report.sh`)
- Daemon trend diagnostics API surface (`preflight_trend`, `GET /preflight-trend`)
- Optional trend threshold gate helper + opt-in policy hook (`scripts/security/preflight-trend-threshold-check.sh`, `WBABD_POLICY_PREFLIGHT_TREND_GATE`)
- Systemd/container trend-threshold health integration examples in operator runbook (`docs/DAEMON_DEPLOY_PROFILE.md`)
- Cross-agent command/event audit stream (`.wbab/audit-log.jsonl`, schema `wbab.audit.v1`)
- Daemon API authn/authz + transport hardening plan (`docs/DAEMON_API_SECURITY_PLAN.md`)
- Publish-image contract checks for tags/labels/digest metadata (`tests/policy/test_publish_image_contracts.sh`)
- Publish workflow hardening/security gates (Hadolint + Trivy vulnerability gate + CycloneDX SBOM output)
- WineBot submodule bootstrap integrated into active bring-up flow (`scripts/bootstrap-submodule.sh`, `README.md`, `docs/CONTEXT_BUNDLE.md`)
- Minimal opt-in CI workflow to run policy suite with trend threshold gate enabled (`.github/workflows/policy-preflight-trend-gate-optin.yml`)
- Commit-history policy documented and enforced by policy gate (`AGENTS.md`, `docs/CONTRACTS.md`, `tests/policy/test_commit_policy_documented.sh`)
- TLA opt-in workflow artifact upload for formal-model review snapshot (`tla-formal-model-snapshot`)
- TLA README example mapping invariants to policy assertions (`formal/tla/README.md`)
- TLA release sign-off runbook note for baseline vs extended config (`docs/FORMAL_MODEL_HOWTO.md`)
- TLA opt-in workflow step-summary file listing for artifact contents (`${GITHUB_STEP_SUMMARY}`)
- TLA snapshot contract checks for required configs/docs in opt-in workflow policy
- TLA release checklist item to review `tla-formal-model-snapshot` during sign-off
- TLA policy linkage enforcing snapshot checklist language in context docs
- TLA release-note snippet template for formal-model review completion (`docs/FORMAL_MODEL_HOWTO.md`)
- TLA contract check enforcing consistent snapshot artifact naming across runbook/context docs
- TLA runbook includes PR checklist example that references release-note snippet usage
- TLA policy assertion pins release-note snippet workflow name (`tla-skeleton-contract-optin`)
- TLA policy assertion pins PR checklist artifact name (`tla-formal-model-snapshot`)
- TLA policy assertion pins PR checklist workflow name (`tla-skeleton-contract-optin`)
- Contributor note describes when to include formal-model PR checklist line (`docs/FORMAL_MODEL_HOWTO.md`)
- TLA policy assertion ensures contributor note references workflow + artifact names
- CONTEXT_BUNDLE cross-links to formal-model contributor-note usage criteria
- TLA policy assertion keeps contributor-note cross-link inside TLA CI execution notes section
- CONTEXT_BUNDLE includes recommendation note for formal/retry-impacting PR checklist usage
- TLA policy assertion keeps recommendation note adjacent to contributor-note cross-link
- TLA policy check enforces consistent recommendation wording across context + contributor note
- Contracts doc points to formal-model checklist usage guidance in context + how-to docs
- TLA policy assertion enforces contracts guidance references both context + how-to docs
- Contracts doc includes compact release-signoff checklist example for formal-model review
- TLA policy assertion enforces contracts example includes workflow + artifact identifiers
- CONTEXT_BUNDLE points to contracts checklist example for signoff copy/paste
- TLA policy assertion keeps context contracts-note path + wording anchor stable
- TLA policy assertion keeps context contracts-note adjacent to recommendation bullet
- TLA extended-invariants policy includes compact contracts-to-context cross-reference checks
- TLA policy parity check enforces contracts/how-to checklist example text alignment
- CONTEXT_BUNDLE includes operator note to keep contracts/how-to checklist text synchronized
- TLA policy assertion keeps context synchronization note adjacent to contracts checklist cross-reference
- TLA policy assertion enforces synchronization note references both contracts + formal-model how-to docs

## What is not included (yet)
- Model-based tests
- Public release of toolchain images

## Next actions
1. Publish toolchain images to GHCR
