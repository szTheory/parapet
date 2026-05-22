# Phase 1: Task Breakdown

This document provides a sequential task breakdown for the Phase 1 implementation of the Durable Escalation Engine.

## Dependency Analysis
- **Task 1** and **Task 2** establish the foundation (the policy contract and the worker that consumes it).
- **Task 3** acts as the integration point, wiring the worker into the existing `Parapet.Evidence` lifecycle. Task 3 explicitly requires Task 2's Oban worker to exist.

## Tasks

### Task 1: Define Escalation Policy Behaviour
- **Files Modified:** `lib/parapet/escalation/policy.ex`, `test/parapet/escalation/policy_test.exs`
- **Action:** Create the module `Parapet.Escalation.Policy` containing a single `@callback escalate(incident :: Parapet.Spine.Incident.t(), opts :: keyword()) :: {:ok, term()} | {:error, term()}`. Reference the analog `lib/parapet/notifier.ex` from `PATTERNS.md`. Write a dummy test module in `test/parapet/escalation/policy_test.exs`.
- **Verification:** `mix test test/parapet/escalation/policy_test.exs` succeeds.

### Task 2: Implement Escalation Worker
- **Files Modified:** `lib/parapet/escalation/worker.ex`, `test/parapet/escalation/worker_test.exs`
- **Action:** 
  1. Define an Oban worker that receives an `incident_id`. Reference `lib/parapet/notifier/oban_worker.ex` from `PATTERNS.md`.
  2. Query the DB for the incident.
  3. If state is `"investigating"` or `"resolved"`, discard the job and emit a timeline entry (`escalation_short_circuited`) via `Parapet.Evidence.append_timeline/2`.
  4. If state is `"open"`, load the configured policy from `Application.get_env(:parapet, :escalation_policy)` and call `escalate/2`. Apply the "Error Handling / Safe Execution" pattern from `PATTERNS.md` to safely wrap the execution. Emit a timeline entry (`escalation_executed`) upon executing the policy.
- **Verification:** `mix test test/parapet/escalation/worker_test.exs` passes.

### Task 3: Integrate Incident Lifecycle
- **Files Modified:** `lib/parapet/evidence.ex`, `test/parapet/evidence_test.exs`
- **Action:** 
  1. Refactor `Parapet.Evidence.create_incident/1` to use `Ecto.Multi`.
  2. Append an `Ecto.Multi.insert` step to conditionally schedule the `Parapet.Escalation.Worker` if `Code.ensure_loaded?(Oban)` and an escalation policy is configured.
  3. Map the `repo().transaction` result back to the expected `{:ok, incident}` or `{:error, changeset}`.
- **Verification:** `mix test test/parapet/evidence_test.exs` passes, ensuring the transactional queue logic and API contract hold.