# WineBotAppBuilder (WBAB)

A production-ready, containerized toolchain for building, packaging, signing, and testing Windows applications on Linux.

WBAB is designed for **deterministic automation**, providing a unified CLI that ensures the same environment is used across developer machines, CI/CD pipelines, and AI agents.

## Core Features
- **Containerized Build:** Cross-compile Win32/Win64 apps using a stable toolchain (`wbab build`).
- **Integrated Linting:** Run project-specific static analysis within the toolchain (`wbab lint`).
- **Unit Testing:** Execute unit tests (including Windows binaries via Wine) (`wbab test`).
- **Standardized Packaging:** Create NSIS installers in a controlled environment (`wbab package`).
- **Secure Signing:** Integrated support for self-signed dev certs and production PKI (`wbab sign`).
- **Headless Smoke Testing:** Run installers in WineBot (Docker-based Wine) and verify contents automatically (`wbab smoke`).
- **Idempotent Daemon:** A core engine that handles retries and prevents redundant operations (`wbabd`).
- **Network Discovery:** Zero-configuration local network discovery using mDNS (`wbab discover`).
- **Agent-Ready:** Structured JSON planning (`wbab plan`) and audit logs for AI-driven development.
- **Dev Container:** Full-featured VS Code development environment with all tools pre-installed.

## Quick Start

### 1. Prerequisites
Ensure you have Docker and the GitHub CLI installed.

### 2. Installation
```bash
git clone https://github.com/SemperSupra/WineBotAppBuilder.git
cd WineBotAppBuilder/workspace
./scripts/bootstrap-submodule.sh
```

### 3. Initialize a New Project
```bash
# Initialize a new policy-compliant project
./tools/wbab init "My Awesome App" /path/to/my-project
```

### 4. Usage (The WBAB Pipeline)
```bash
# Run operations through the daemon (with auto-discovery)
./tools/wbab build samples/validation-app
./tools/wbab package samples/validation-app
```

## Core philosophy & Reliability
- **Non-Root Runtime**: All toolchain containers run as restricted user `wbab` (UID 1000).
- **SQLite Storage**: All operation state and audit logs use SQLite for persistence and atomicity.
- **Remote RCE Guard**: The core engine directly constructs `docker run` commands; host-side scripts are not used for execution in production.
- **Workspace Isolation**: Built-in cleanup of `out/` and `dist/` directories ensures no stale artifacts pollute new builds.

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
