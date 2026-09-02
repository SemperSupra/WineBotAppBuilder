# WBAB Project Organization Policy

This policy describes the current repository layout and authority boundaries. It supersedes the earlier assumption that source code lives under a required `workspace/` directory; the current repository develops directly from its root-level source directories.

## Authoritative source/workset

The Git repository is the durable engineering authority. Primary source and validation areas are:

- `core/` — reusable core/daemon business logic;
- `tools/` — CLI/daemon entry points and container/tool runners;
- `scripts/` — deterministic repository/operator helpers;
- `samples/` — first-party validation/example projects;
- `tests/` — validation code, classified by the evidence it actually produces;
- `formal/` — formal-model artifacts;
- `deploy/` — deployment examples/templates;
- `docs/` — current durable project state, decisions, findings and runbooks;
- `.github/` — repository-native CI/release/governance automation.

There is no required repository-root `workspace/` directory. An external project passed to WBAB may of course be mounted as `/workspace` inside a container; that runtime mount name is not the repository source layout.

## Agent/runtime state

### `agent-sandbox/`

Purpose: non-secret durable or transient automation/agent state when repository-local state is justified.

Rules:

- do not treat it as the canonical project-plan database when an issue/PR/artifact is sufficient;
- transient build outputs belong in ignored `out/`, `dist/`, or `artifacts/` locations rather than being committed;
- committed entries must be intentionally durable and non-sensitive.

### `agent-privileged/`

Purpose: local privileged/sensitive runtime material such as development/production signing or daemon PKI when generated for an execution environment.

Rules:

- secrets/private keys must not be committed;
- privileged material is local/runtime authority, not ordinary source;
- production credential use requires explicit authority beyond routine repository implementation.

### `manual/`

If present, `manual/` is human-managed material. Agents must not modify it unless explicitly directed.

## Separation-of-concerns invariants

- Core business logic belongs in `core/`, not duplicated across CLI/API/GUI adapters.
- Product/tool runners belong in `tools/`; reusable operational helpers belong in `scripts/`.
- Tests should validate observable behavior at the cheapest faithful boundary and must not mislabel mock/static evidence as product qualification.
- Durable working state should prefer GitHub issues/PRs/refs/artifacts and compact `docs/STATE.md` pointers over growing parallel task databases.
- Generated build/package/smoke artifacts are not source and should remain outside committed source paths unless intentionally captured as a small non-sensitive evidence fixture.
- No hidden directory may be used to bypass these authority/secrecy boundaries.

## Testing corrective program

Issue #58 is the current authority for the testing-value correction. The accepted finding and plan are:

- `docs/findings/testing-value-red-team-2026-09-02.md`
- `docs/TESTING_CORRECTIVE_ACTION_PLAN.md`

The organization policy does not require a separate testing platform; the preferred architecture remains repository-native deterministic scripts/workflows plus exact durable evidence.
