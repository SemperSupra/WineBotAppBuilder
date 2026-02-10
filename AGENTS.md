# Agent Playbook (AGENTS.md)

This repository is intended to be worked by humans and by agents (Codex CLI, Gemini CLI, Jules).
Agents may be used at different times; assume limited context. Follow the **Context Bundle** process.

## Start here (minimal context set)
1. `docs/CONTEXT_BUNDLE.md`
2. The GitHub issue body you are working on
3. Only the files referenced by the issue

## Global invariants (never violate)
- No secrets or private keys committed to the repo.
- `main` must stay green (CI gates pass).
- Default behavior is pull-first from GHCR; no local toolchain builds unless explicitly enabled.
- WineBot runner must prefer GHCR stable WineBot image by default.
- Core business logic must not be duplicated in CLI/GUI/API adapters.
- Commit policy: create one git commit per requested implementation change unless the user explicitly asks to batch changes.

## Local commands
```bash
./scripts/lint.sh
./tests/shell/run.sh
./tests/contract/run.sh
./tests/policy/run.sh
./tests/e2e/run.sh
# opt-in (requires real docker + WineBot submodule):
# ./tests/e2e/run-real.sh
```

## CI gates (what must pass)
- **lint**: shellcheck + basic repo checks
- **shell-unit**: mock-based shell tests for pull-first and no-build policies
- **contract**: contract checks (CLI help includes required verbs; env var docs exist)
- **policy**: static policy checks (release-only workflow constraints, etc.)
- **e2e-smoke**: mocked pipeline gate for `wbab build -> package -> sign -> smoke`
- **e2e-real**: opt-in `workflow_dispatch` gate for real Docker/WineBot pipeline checks

## Review checklist for any PR
- [ ] CI is green
- [ ] `docs/STATE.md` updated with what changed and what's next
- [ ] `docs/CONTEXT_BUNDLE.md` updated if commands/gates changed
- [ ] Tests added/updated for any new behavior
- [ ] Commit history follows policy (one commit per requested implementation change unless user-directed batching)
