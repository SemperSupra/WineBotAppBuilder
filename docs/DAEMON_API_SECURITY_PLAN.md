# Daemon API Security Plan

## Scope
This plan covers `tools/wbabd` API surfaces:
- local adapter (`wbabd api`)
- optional HTTP adapter (`wbabd serve`)

Deployment profile (current): internal/private only.

Security goals:
- strong caller authentication (AuthN)
- explicit operation authorization (AuthZ)
- transport hardening for network paths
- auditable, revocable access with safe rollout

## Threat Model
Primary threats:
- unauthorized command execution through daemon API
- lateral movement via loopback/host-network exposure
- token leakage in logs, process args, or CI artifacts
- replay or tampering of API requests
- over-privileged callers invoking sensitive verbs

Assumptions:
- local adapter is commonly used by trusted local automation
- HTTP adapter may run on shared hosts and must be zero-trust by default
- backward compatibility is required during rollout

## Authentication (AuthN) Plan
Phase 0 (immediate, compatibility-first):
- keep local adapter available without network listener requirements
- add explicit `WBABD_AUTH_MODE` with defaults:
  - `off` for local adapter
  - `token` required for HTTP adapter

Phase 1 (token-based):
- require bearer token for HTTP endpoints:
  - env: `WBABD_API_TOKEN` (or file path `WBABD_API_TOKEN_FILE`)
  - header: `Authorization: Bearer <token>`
- enforce constant-time token comparison
- reject missing/invalid tokens with `401`

Phase 2 (mTLS-ready):
- add optional mTLS mode for HTTP deployments
- require client cert validation when enabled
- map client identity to principal for AuthZ

## Authorization (AuthZ) Plan
Policy model:
- default deny for all verbs when AuthZ is enabled
- explicit allow-list by principal and verb

Config:
- `WBABD_AUTHZ_POLICY_FILE` (JSON)
- schema:
  - principals
  - allowed verbs (`build`, `package`, `sign`, `smoke`, `doctor`, `plan`, `status`)
  - optional arg constraints (path prefixes / regex)

Enforcement:
- return `403` for disallowed operations
- include reason codes in audit log (`authz.denied`, `authz.allowed`)

## Transport Hardening Plan
Baseline:
- bind default host to `127.0.0.1`
- never expose unauthenticated HTTP listener on non-loopback interfaces
- prefer internal PKI for private deployment (no public ACME dependency)

TLS:
- provide TLS mode for `serve`:
  - `WBABD_TLS_CERT_FILE`
  - `WBABD_TLS_KEY_FILE`
  - optional `WBABD_TLS_CLIENT_CA_FILE` for mTLS
- enforce modern TLS versions and disable weak ciphers
- internal PKI lifecycle helper:
  - `scripts/security/daemon-pki.sh init`
  - `scripts/security/daemon-pki.sh rotate`
  - `scripts/security/daemon-pki.sh export <dir>`
  - `scripts/security/daemon-pki.sh import <dir>`

Operational controls:
- request body size limits
- request timeout limits
- structured rate-limiting hooks for abusive clients

## Secrets Handling
- never log raw bearer tokens or private keys
- redact auth headers and sensitive env vars in command/audit logs
- support secret file paths over inline env values in CI

## Audit and Detection
- extend audit events with security fields:
  - `principal`
  - `authn_mode`
  - `authn_result`
  - `authz_result`
  - `client_ip` (HTTP mode)
- add policy tests for denied/allowed paths and redaction checks

## Rollout Strategy
1. Add config and parser scaffolding (no behavior change by default for local adapter).
2. Enforce token auth for `serve` by default; allow explicit temporary override only in dev.
3. Add AuthZ allow-list with default-deny behind feature flag.
4. Enable TLS/mTLS options and operational limits.
5. Remove insecure compatibility overrides after one release cycle.

## Acceptance Criteria
- HTTP adapter rejects unauthorized requests (`401/403`) and logs outcomes.
- Local adapter behavior remains stable unless auth policy explicitly enables restrictions.
- Security config is documented and validated by policy tests.
- No sensitive token material appears in logs or artifacts.
- Deploy profile references are available in `docs/DAEMON_DEPLOY_PROFILE.md` for operator runbooks.
