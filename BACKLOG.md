# WBAB Backlog — Retired

Status: **feature-frozen / retiring**  
Authoritative retirement tracker: #61  
Retirement plan: `RETIREMENT.md`

This file is retained as historical context. It is **not an active feature roadmap**.

The 2026-09-02 red-team concluded that WBAB should not continue growing as a standalone build/orchestration platform. Open platform-expansion work is therefore cancelled or moved conceptually to narrower successor owners. Do not reopen an item here merely because the historical need still exists.

## Completed historical reliability work

The following work was implemented before retirement and remains part of the historical final state:

- atomic operation-store updates;
- bounded Git timeouts;
- artifact cleanup/rollback behavior;
- SQLite persistence;
- worker-pool concurrency control;
- discovery caching;
- configurable retry backoff;
- strict path jailing;
- non-root containers;
- host-side remote-RCE reduction;
- TLS/authentication/authorization surfaces;
- Docker-socket reduction in linting;
- shell/Python test modernization;
- coverage/SBOM/vulnerability checks;
- build-output and CLI contract validation;
- Dependabot configuration;
- Go toolchain support;
- recursive submodule support;
- WinInspect-style project detection.

Git history and closed issues remain the authority for implementation detail.

## Cancelled WBAB-specific work

These items are **not planned for WBAB** unless the narrow resurrection criterion in `RETIREMENT.md` is satisfied by a named real consumer:

- Trivy database caching and other CI optimization whose only consumer is WBAB;
- mDNS metadata expansion;
- persistent Git mirrors in WBAB;
- WineLib target/platform expansion;
- cloud/remote Windows test-lab orchestration;
- declarative Windows dependency "vending machine";
- WBAB-owned app-store/update-repository generation;
- `wbab init` project wizard;
- WBAB-owned cloud-HSM/PKCS#11 signing abstraction;
- WBAB web operations dashboard;
- first-class Go/SupraGoFlow integration as a generalized WBAB project type;
- additional WBAB SLSA/attestation infrastructure;
- local-Action simulation infrastructure;
- additional property/fuzz testing for WBAB's retiring orchestration core;
- WinInspect-specific MinGW/OpenSSL/toolchain work;
- WinInspect daemon-lifecycle hooks/contracts inside WBAB;
- WBAB release-automation repair for future WBAB releases;
- P4 release qualification as a WBAB product-development phase.

Where the underlying need still matters, use the successor owner:

- product-local native Windows CI;
- Windows Package Foundry for release/trust/distribution;
- WinBot for native interactive Windows automation;
- controlled Windows runner/VM for licensed or legacy toolchains;
- WineBot for Wine runtime/compatibility validation;
- winebot-contracts for shared API/conformance semantics.

## Cross-project requests discovered during WBAB development

Historical WineBot capability requests such as readiness, structured install, file extraction, certificate trust, CI-smoke receipts, or version/capability reporting should be evaluated **in WineBot on their own merits**. They are not WBAB retirement blockers and should not be implemented merely to preserve WBAB.

Historical WinInspect requests are superseded by WinInspect's native Windows CI/release path. WinInspect removed its WBAB submodule through PR #366 after exact-head installer-lifecycle validation passed.

## Active work

The only active WBAB work is retirement work tracked in #61:

1. land the completed #58 truthfulness stack through PR #63;
2. land retirement documentation/state against the truthful `main`;
3. verify no release/image consumer remains;
4. disable unnecessary publication and optional workflows;
5. preserve useful lessons/evidence;
6. enter cooling-off and archive when #61 completion criteria are met.

Any proposed new backlog item must first explain why the requirement cannot be satisfied more cheaply by the preferred successor architecture and why it is necessary during retirement.
