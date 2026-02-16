# WBAB Project Organization Policy

This document defines the organizational structure of the WineBotAppBuilder (WBAB) project folder to ensure a clear separation of concerns between human-managed and agent-managed files.

## Directory Structure

The project root is organized into the following top-level directories:

### 1. `workspace/` (Shared/Human & Agent)
- **Purpose:** Contains the project source code, scripts, tools, and documentation.
- **Management:** Shared responsibility. Both humans and agents can modify files here according to project needs.
- **Status:** Primary development area.

### 2. `agent-sandbox/` (Agent Managed - Sandbox)
- **Purpose:** Persistent and transient state used by AI agents and the WBAB toolchain that does NOT require elevated privileges.
- **Contents:**
  - `state/`: Idempotent operation store (`core-store.json`), audit logs (`audit-log.jsonl`), and preflight diagnostics.
  - `artifacts/`: Build artifacts produced by the toolchain.
  - `out/`: Compilation outputs.
  - `dist/`: Packaging and signing outputs.
- **Management:** Managed exclusively by agents and automation tools. Humans should generally not modify files here.
- **Privilege Level:** Standard user (No elevation).

### 3. `agent-privileged/` (Agent Managed - Privileged)
- **Purpose:** Sensitive or system-level configuration managed by agents that may require elevation or careful handling.
- **Contents:**
  - `signing/`: PKI material for code signing (dev certificates, CA material).
  - `daemon-pki/`: Internal PKI for `wbabd` daemon communication.
- **Management:** Managed by agents. Access should be restricted.
- **Privilege Level:** Elevated/Privileged.

### 4. `manual/` (Human Managed)
- **Purpose:** Miscellaneous files, documentation, or archives that are managed exclusively by humans and are not part of the core workspace.
- **Contents:** Bring-up notes, specific development guides, zip archives.
- **Management:** Exclusively human-managed. Agents should NOT modify files in this directory unless explicitly directed.

## Enforcement

- **Tools:** The WBAB toolchain (`wbab`, `wbabd`) and core logic (`wbab_core.py`) are configured to use these directories by default.
- **Hidden Files:** No hidden files or directories (starting with `.`) should be used for agent-managed state in the project root.
- **Invariants:**
  - Agents must respect the boundaries of the `manual/` directory.
  - Source code must remain in `workspace/`.
  - All non-code state must be stored in `agent-sandbox/` or `agent-privileged/`.
