# Daemon Idempotency Formal Model

This directory contains a TLA+ formal model (`DaemonIdempotency.tla`) describing the core state machine for the WineBotAppBuilder daemon (`wbabd`).

## Purpose
The model validates the safety properties of the daemon's operation executor, specifically:
- **Idempotency**: Once an operation succeeds, repeated requests return the same result without re-execution.
- **Resume-on-Retry**: If an operation fails and is retried, it resumes from the first non-succeeded step (skipping previously succeeded steps).
- **Prefix Consistency**: All steps preceding the current step are guaranteed to be in the `succeeded` state.

## Model Structure
- **Ops**: Set of operations (e.g., `{"op1", "op2"}`).
- **NumSteps**: Number of sequential steps per operation (e.g., `3`).
- **opStatus**: Overall status (`pending`, `running`, `succeeded`, `failed`).
- **stepStatus**: Status of individual steps.
- **currentStep**: Pointer to the step currently being executed.
- **runAttempts**: Counter for external trigger events (`Run`).
- **stepRetryCount**: Total number of retries across all steps.

## Expected Invariant Checks
1.  `TypeOk`: Variable types are correct.
2.  `Invariant_IdempotentOnceSucceeded`: Once `everSucceeded` is true, `opStatus` remains `succeeded`.
3.  `Invariant_AttemptsNonNegative`: Retry/resume attempts are never negative.
4.  `Invariant_StepRetryCountNonNegative`: Step retry count is never negative.
5.  `Invariant_StepRetryCountLeRunAttempts`: Step retry count never exceeds total run attempts.
6.  `Invariant_AllStepsSucceededIfOpSucceeded`: If the operation is done, all steps are done.
7.  `Invariant_PrefixSucceeded`: `currentStep` advances monotonically; we never go back to a previous step.
8.  `Invariant_NoSkippedSteps`: We do not skip steps; the `currentStep` is always the first one that is not `succeeded`.

## Optional Extended Invariant Set
For deeper analysis of retry behavior, the model includes:
- `Invariant_StepRetryCountNonNegative`
- `Invariant_StepRetryCountLeRunAttempts`

These are enabled in `DaemonIdempotencyExtended.cfg`.

## Running the Model
You can run this model using the TLC model checker.

```bash
# Using tlc command line (if installed)
tlc2 formal/tla/DaemonIdempotency.tla -config formal/tla/DaemonIdempotency.cfg
```

## Mapping to Implementation
- `opStatus` maps to the top-level `status` field in the Operation Store JSON.
- `stepStatus` maps to the `step_state` dictionary in the Operation Store.
- `currentStep` logic is implemented by the Executor loop in `core/wbab_core.py`.
- `Run(op)` corresponds to receiving a `wbabd run` request.

## Invariant-to-Policy Mapping Example
The formal invariants in this model are enforced by the following project policies:
- **Baseline Policy**: Verified by `tests/policy/test_tla_idempotency_skeleton.sh`.
- **Extended Policy**: Verified by `tests/policy/test_tla_extended_invariants_contract.sh`.