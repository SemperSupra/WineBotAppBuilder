# WBAB Linting and Checking Policy

This policy ensures that all code and artifacts directly owned by the WineBotAppBuilder (WBAB) project are subject to rigorous, consistent, and containerized verification.

## Core Principles

1.  **Containerized Execution**: All linting and checking tools MUST be executed from within a standardized container environment (`tools/linter/Dockerfile`). No tools (other than Docker) should be installed directly on the host for this purpose.
2.  **Parity**: Local linting MUST use exactly the same tools, versions, and configurations as the CI/CD pipeline.
3.  **Local-First Enforcement**: Local checks MUST pass before pushing changes to the remote repository or initiating new releases.
4.  **Project-Owned Only**: Only artifacts directly part of the WBAB project are subject to these checks. External projects (e.g., `tools/WineBot` submodule) and managed dependencies are the responsibility of their respective projects and are excluded to prevent noise and scope creep.

## Standard Tools

The following tools are integrated into the unified linter:

- **Shell**: `shellcheck` for all `.sh` files.
- **Python**: `ruff` for all `.py` files.
- **Docker**: `hadolint` for all `Dockerfile`s.
- **Security**: `trivy` for high/critical filesystem vulnerability scanning.
- **Sanity**: Executable bit verification for core scripts.

## Usage

### Local Execution
```bash
# From the project root or workspace
./workspace/scripts/lint.sh
```

### CI/CD Enforcement
The `lint` job in `.github/workflows/ci.yml` and the `release` job in `release.yml` invoke the same containerized logic.

## Exclusions
The following paths are explicitly excluded from project-wide linting:
- `tools/WineBot/` (External Submodule)
- `agent-sandbox/` (Agent-managed state/artifacts)
- `agent-privileged/` (Agent-managed sensitive material)
- `manual/` (Human-managed documentation/archives)
