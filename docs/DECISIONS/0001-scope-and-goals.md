# ADR 0001: Scope, Goals, and v1 Decisions

## Decision
We will build WineBotAppBuilder as a container-first toolchain for building Windows apps on Linux and validating them under Wine using WineBot.

## Scope (v1)
- Build Win32/Win64 EXEs/DLLs (C++)
- Package installers (NSIS-first for Wine compatibility)
- Dev/test signing (self-signed) with a future path to OV/EV
- WineBot runner integration (headless CI + optional interactive locally)
- GitHub Actions first (GitLab deferred)

## Out of scope (v1)
- Windows driver development and driver signing

## Key policies
- Prefer GHCR images over local builds (pull-first)
- Build/publish toolchain images only on GitHub Release (published)
- Core logic must be UI-agnostic and idempotent; CLI/GUI/API are adapters
