# Formal Model How-To

This note maps the TLA+ skeleton to concrete daemon behavior so operators and contributors can interpret model checks consistently.

## Intent To Runtime Mapping
- TLA variable `opStatus` maps to operation lifecycle status in `agent-sandbox/state/core-store.sqlite` (`pending`, `running`, `succeeded`, `failed`).
- TLA variable `runAttempts` maps to operation-level retry count progression (`attempts` / `retry_count`) in stored operation payloads.
- TLA variable `everSucceeded` models idempotency lock-in once an operation reaches `succeeded`.

Audit event linkage:
- operation start/cached/success/failure: `operation.started`, `operation.cached`, `operation.succeeded`, `operation.failed`
- step lifecycle: `step.started`, `step.succeeded`, `step.failed`
- adapter request envelope: `command.run`, `command.plan`, `command.api`

## Step Retry Counter Translation
`stepRetryCount` in `formal/tla/DaemonIdempotency.tla` is the abstract counter for per-step retry activity.

Runtime translation:
- `stepRetryCount[op]` corresponds to aggregated step attempt semantics represented by `step_state[*].attempts`.
- In current runtime, each step tracks attempts independently under `step_state.<step-name>.attempts`.
- The extended invariant `Invariant_StepRetryCountLeRunAttempts` expresses that step-level retries remain bounded by operation-level attempts.

## How To Use This With Model Outputs
1. Run baseline checks (`DaemonIdempotency.cfg`) to validate idempotency and non-negative attempt growth.
2. Run extended checks (`DaemonIdempotencyExtended.cfg`) when reasoning about step-level retry bounds.
3. Compare model claims with:
   - `agent-sandbox/state/core-store.sqlite` (`operations[*].step_state`, `attempts`, `retry_count`)
   - `agent-sandbox/state/audit-log.sqlite` (`operation.*`, `step.*`, `command.*`)

## Release Sign-Off Config Selection
Use this decision rule for private/internal release sign-off:

1. Always run baseline config first:
   - `tlc2 formal/tla/DaemonIdempotency.tla -config formal/tla/DaemonIdempotency.cfg`
2. Run extended config when any retry or step-execution logic changed:
   - `tlc2 formal/tla/DaemonIdempotency.tla -config formal/tla/DaemonIdempotencyExtended.cfg`
3. Treat any invariant failure in either config as a release blocker until explained and fixed.

Release checklist item:
- For each opt-in TLA CI run, review artifact `tla-formal-model-snapshot` and confirm it contains baseline + extended config files before approving sign-off.

Release note snippet:
```text
Formal model review: completed.
Workflow: tla-skeleton-contract-optin
Artifact: tla-formal-model-snapshot reviewed (DaemonIdempotency.cfg + DaemonIdempotencyExtended.cfg present).
Outcome: no invariant regression observed.
```

PR checklist line example:
```text
- [ ] Formal-model release note snippet added (workflow `tla-skeleton-contract-optin`, artifact `tla-formal-model-snapshot` reviewed).
```

Contributor note:
- Include the PR checklist line whenever a PR changes formal models or retry/idempotency behavior (including TLA files under `formal/tla/*`), or release-signoff documentation for formal checks.
  Use workflow `tla-skeleton-contract-optin` and artifact `tla-formal-model-snapshot` in that checklist line.
- You can omit it for purely non-functional edits that cannot affect model expectations (for example spelling-only changes outside formal/runbook docs).
