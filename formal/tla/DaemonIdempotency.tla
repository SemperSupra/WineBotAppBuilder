------------------------------ MODULE DaemonIdempotency ------------------------------
EXTENDS Naturals, Sequences, TLC

\* Operation status machine for idempotency and step-level retry/resume behavior.
CONSTANTS Ops, NumSteps

Steps == 1..NumSteps
Status == {"pending", "running", "succeeded", "failed"}

VARIABLES 
  opStatus,       \* Overall operation status
  stepStatus,     \* Status of each step within an operation
  currentStep,    \* The step currently being executed (or NumSteps+1 if done)
  runAttempts,    \* Number of times the operation was externally triggered
  stepRetryCount, \* Total number of retries across all steps
  everSucceeded   \* Latch for operation success

vars == <<opStatus, stepStatus, currentStep, runAttempts, stepRetryCount, everSucceeded>>

Init ==
  /\ opStatus \in [Ops -> Status]
  /\ \A op \in Ops: opStatus[op] = "pending"
  /\ stepStatus \in [Ops -> [Steps -> Status]]
  /\ \A op \in Ops: \A s \in Steps: stepStatus[op][s] = "pending"
  /\ currentStep \in [Ops -> 1..(NumSteps + 1)]
  /\ \A op \in Ops: currentStep[op] = 1
  /\ runAttempts \in [Ops -> Nat]
  /\ \A op \in Ops: runAttempts[op] = 0
  /\ stepRetryCount \in [Ops -> Nat]
  /\ \A op \in Ops: stepRetryCount[op] = 0
  /\ everSucceeded \in [Ops -> BOOLEAN]
  /\ \A op \in Ops: everSucceeded[op] = FALSE

\* External trigger: Client requests 'run op'.
Run(op) ==
  /\ op \in Ops
  \* If already succeeded, the daemon just returns the cached result (no state change in the core state machine)
  /\ opStatus[op] /= "succeeded"
  
  /\ opStatus' = [opStatus EXCEPT ![op] = "running"]
  /\ runAttempts' = [runAttempts EXCEPT ![op] = @ + 1]
  
  \* If it was 'failed', we are retrying the current step.
  /\ stepRetryCount' = [stepRetryCount EXCEPT ![op] = @ + IF opStatus[op] = "failed" THEN 1 ELSE 0]
  
  \* If we are starting (pending) or retrying (failed/running), ensure the current step is marked running.
  /\ stepStatus' = [stepStatus EXCEPT ![op][currentStep[op]] = "running"]
  
  /\ UNCHANGED <<currentStep, everSucceeded>>

\* Internal progress: The current step completes successfully.
StepSucceed(op) ==
  /\ opStatus[op] = "running"
  /\ currentStep[op] <= NumSteps
  /\ stepStatus[op][currentStep[op]] = "running"
  
  /\ stepStatus' = [stepStatus EXCEPT 
       ![op][currentStep[op]] = "succeeded",
       \* If there is a next step, mark it running immediately (continuous execution)
       ![op][IF currentStep[op] < NumSteps THEN currentStep[op] + 1 ELSE currentStep[op]] = 
         IF currentStep[op] < NumSteps THEN "running" ELSE @
     ]
     
  /\ currentStep' = [currentStep EXCEPT ![op] = @ + 1]
  /\ stepRetryCount' = stepRetryCount
  
  \* If we finished the last step, the operation succeeds.
  /\ IF currentStep[op] = NumSteps
     THEN /\ opStatus' = [opStatus EXCEPT ![op] = "succeeded"]
          /\ everSucceeded' = [everSucceeded EXCEPT ![op] = TRUE]
     ELSE /\ opStatus' = opStatus
          /\ everSucceeded' = everSucceeded
          
  /\ UNCHANGED <<runAttempts>>

\* Internal failure: The current step fails.
StepFail(op) ==
  /\ opStatus[op] = "running"
  /\ currentStep[op] <= NumSteps
  /\ stepStatus[op][currentStep[op]] = "running"
  
  /\ stepStatus' = [stepStatus EXCEPT ![op][currentStep[op]] = "failed"]
  /\ opStatus' = [opStatus EXCEPT ![op] = "failed"]
  
  /\ UNCHANGED <<currentStep, runAttempts, stepRetryCount, everSucceeded>>

Next ==
  \E op \in Ops:
    \/ Run(op)
    \/ StepSucceed(op)
    \/ StepFail(op)

Spec == Init /\ [][Next]_vars

\* Safety Properties

TypeOk ==
  /\ opStatus \in [Ops -> Status]
  /\ stepStatus \in [Ops -> [Steps -> Status]]
  /\ currentStep \in [Ops -> 1..(NumSteps + 1)]
  /\ runAttempts \in [Ops -> Nat]
  /\ stepRetryCount \in [Ops -> Nat]
  /\ everSucceeded \in [Ops -> BOOLEAN]

\* Once marked as succeeded, an operation remains succeeded.
Invariant_IdempotentOnceSucceeded ==
  \A op \in Ops: everSucceeded[op] => opStatus[op] = "succeeded"

\* Retry/resume attempts are never negative.
Invariant_AttemptsNonNegative ==
  \A op \in Ops: runAttempts[op] >= 0

\* Total retries across all steps must be non-negative.
Invariant_StepRetryCountNonNegative ==
  \A op \in Ops: stepRetryCount[op] >= 0

\* Total retries across all steps cannot exceed total run attempts.
Invariant_StepRetryCountLeRunAttempts ==
  \A op \in Ops: stepRetryCount[op] <= runAttempts[op]

\* If the operation is succeeded, all steps must be succeeded.
Invariant_AllStepsSucceededIfOpSucceeded ==
  \A op \in Ops: opStatus[op] = "succeeded" => 
    \A s \in Steps: stepStatus[op][s] = "succeeded"

\* Steps before the current one must be succeeded.
Invariant_PrefixSucceeded ==
  \A op \in Ops: \A s \in Steps:
    s < currentStep[op] => stepStatus[op][s] = "succeeded"

\* We never skip a step (current step is the first non-succeeded one, unless done).
Invariant_NoSkippedSteps ==
  \A op \in Ops: 
    (currentStep[op] <= NumSteps => stepStatus[op][currentStep[op]] /= "succeeded")

=============================================================================