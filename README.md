# WineBotAppBuilder (WBAB)

A production-ready, containerized toolchain for building, packaging, signing, and testing Windows applications on Linux.

WBAB is designed for **deterministic automation**, providing a unified CLI that ensures the same environment is used across developer machines, CI/CD pipelines, and AI agents.

## Core Features
- **Containerized Build:** Cross-compile Win32/Win64 apps using a stable toolchain (`wbab build`).
- **Standardized Packaging:** Create NSIS installers in a controlled environment (`wbab package`).
- **Secure Signing:** Integrated support for self-signed dev certs and production PKI (`wbab sign`).
- **Headless Smoke Testing:** Run installers in WineBot (Docker-based Wine) and verify contents automatically (`wbab smoke`).
- **Idempotent Daemon:** A core engine that handles retries and prevents redundant operations (`wbabd`).
- **Agent-Ready:** Structured JSON planning (`wbab plan`) and audit logs for AI-driven development.

## Quick Start

### 1. Prerequisites
Ensure you have Docker and the GitHub CLI installed.

### 2. Installation
```bash
git clone https://github.com/SemperSupra/WineBotAppBuilder.git
cd WineBotAppBuilder/workspace
./scripts/bootstrap-submodule.sh
```

### 3. Usage (The WBAB Pipeline)
```bash
# Build your application
./tools/wbab build samples/validation-app

# Package into an installer
./tools/wbab package samples/validation-app

# Sign the installer (auto-generates dev cert if needed)
./tools/wbab sign samples/validation-app

# Smoke test the installer in WineBot
./tools/wbab smoke samples/validation-app
```

## Documentation for Humans
- **[User Guide](docs/USER_GUIDE.md):** Comprehensive guide on creating and testing your own apps.
- **[Contracts](docs/CONTRACTS.md):** Definition of stable CLI verbs and environment variables.
- **[Daemon Security](docs/DAEMON_API_SECURITY_PLAN.md):** Security architecture and deployment profiles.

## Documentation for Agents
- **[AGENTS.md](AGENTS.md):** The primary playbook for AI agents (context windows, commit policies).
- **[CONTEXT_BUNDLE.md](docs/CONTEXT_BUNDLE.md):** Technical deep-dive for establishing agent context.
- **[Formal Model](docs/FORMAL_MODEL_HOWTO.md):** Guidance on the TLA+ idempotency specifications.

## Project Policy
- **Pull-First:** By default, WBAB pulls official images from `ghcr.io/sempersupra`. Local builds of the toolchain are disabled unless `WBAB_ALLOW_LOCAL_BUILD=1` is set.
- **Atomic Commits:** One commit per implementation change is strictly enforced for traceability.

---
*For historical bring-up notes, see [docs/BRINGUP.md](docs/BRINGUP.md).*
