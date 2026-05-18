---
phase: "1"
plan: "1"
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/parapet/escalation/policy.ex
  - test/parapet/escalation/policy_test.exs
  - lib/parapet/escalation/worker.ex
  - lib/parapet/evidence.ex
  - test/parapet/escalation/worker_test.exs
autonomous: true
requirements: 
  - ESC-01
must_haves:
  truths:
    - "System schedules an Oban job upon incident creation if an escalation policy is configured"
    - "System executes the escalation policy via an Oban worker when the job runs"
    - "System gracefully short-circuits the escalation job if the incident state is no longer 'open'"
    - "System records TimelineEntries for escalation short-circuits"
    - "System records TimelineEntries for successful escalations"
  artifacts:
    - path: "lib/parapet/escalation/policy.ex"
      provides: "Parapet.Escalation.Policy behaviour contract"
    - path: "lib/parapet/escalation/worker.ex"
      provides: "Oban worker for durable dispatch and short-circuiting"
    - path: "lib/parapet/evidence.ex"
      provides: "Transactional Oban enqueue via Ecto.Multi on incident creation"
  key_links:
    - from: "lib/parapet/evidence.ex"
      to: "lib/parapet/escalation/worker.ex"
      via: "Ecto.Multi.insert for job enqueuing"
    - from: "lib/parapet/escalation/worker.ex"
      to: "Parapet.Evidence"
      via: "DB state check and Parapet.Evidence.append_timeline"
---

<objective>
Build the underlying Oban-backed routing logic for incidents (Durable Escalation Engine).

Purpose: Guarantee that incidents are routed to human operators durably unless resolved or acknowledged first.
Output: Escalation Policy behaviour, Oban worker implementation, and lifecycle integration in `Parapet.Evidence`.
</objective>

<context>
@.planning/v0.8-ROADMAP.md
@.planning/v0.8-REQUIREMENTS.md
@.planning/phases/1/PATTERNS.md
@.planning/phases/1/RESEARCH.md
</context>

<dependency_analysis>
- **Task 1 & 2** (Policy & Worker) are independent of other systems and provide the required execution targets.
- **Task 3** (Lifecycle Integration) depends on the Worker existing to enqueue it safely.
- All three can be executed in a single plan as they touch distinct but tightly coupled files and fit within a standard context budget.
</dependency_analysis>

<tasks>
  <task type="auto" tdd="true">
    <name>Task 1: Define Escalation Policy Behaviour</name>
    <files>lib/parapet/escalation/policy.ex, test/parapet/escalation/policy_test.exs</files>
    <behavior>
      - Defines an @callback for `escalate(incident, opts)` returning `{:ok, term()} | {:error, term()}`.
    </behavior>
    <action>Create `Parapet.Escalation.Policy`. Define a generic behaviour for host applications to implement custom routing logic (PagerDuty, SMS). Use `Parapet.Spine.Incident.t()` for type specs if available. Reference the analog `lib/parapet/notifier.ex` from `PATTERNS.md` for defining the behaviour. Write a dummy test module in `test/parapet/escalation/policy_test.exs` to verify the behaviour definition.</action>
    <verify>
      <automated>mix test test/parapet/escalation/policy_test.exs</automated>
    </verify>
    <done>Behaviour module compiles without errors and test passes.</done>
  </task>

  <task type="auto" tdd="true">
    <name>Task 2: Implement Escalation Worker</name>
    <files>lib/parapet/escalation/worker.ex, test/parapet/escalation/worker_test.exs</files>
    <behavior>
      - Returns `{:discard, reason}` if Incident is not found.
      - Returns `{:discard, reason}` and calls `Parapet.Evidence.append_timeline` if Incident state is "investigating" or "resolved".
      - Executes configured policy via `Application.get_env` if Incident state is "open" and calls `Parapet.Evidence.append_timeline` to emit a timeline entry upon execution.
    </behavior>
    <action>Implement `Parapet.Escalation.Worker` using `Oban.Worker`. Reference `lib/parapet/notifier/oban_worker.ex` from `PATTERNS.md` as an analog. In `perform/1`, fetch the incident by ID. If state is `"investigating"` or `"resolved"`, call `Parapet.Evidence.append_timeline/2` with type `"escalation_short_circuited"` and return discard. If `"open"`, execute the policy via `Application.get_env(:parapet, :escalation_policy)`. Wrap the policy execution logic using the "Error Handling / Safe Execution" pattern from `PATTERNS.md` to ensure safe execution. Emit a timeline entry via `Parapet.Evidence.append_timeline/2` when the policy executes (e.g. type `"escalation_executed"`). Write tests verifying these state branches.</action>
    <verify>
      <automated>mix test test/parapet/escalation/worker_test.exs</automated>
    </verify>
    <done>Worker logic handles short-circuits, policy dispatch, safe execution, and timeline appends properly with passing tests.</done>
  </task>

  <task type="auto" tdd="true">
    <name>Task 3: Integrate Incident Lifecycle</name>
    <files>lib/parapet/evidence.ex, test/parapet/evidence_test.exs</files>
    <behavior>
      - `create_incident` uses `Ecto.Multi` to insert incident and maybe enqueue job.
      - Job is only enqueued if Oban is loaded and `escalation_policy` is configured.
      - Return signature remains `{:ok, %Incident{}}` or `{:error, changeset}`.
    </behavior>
    <action>Refactor `Parapet.Evidence.create_incident/1` to use `Ecto.Multi`. Insert the incident, then conditionally insert an `Oban.Job` for `Parapet.Escalation.Worker` if `Code.ensure_loaded?(Oban)` and an escalation policy is configured. Crucially, unwrap the `repo().transaction(multi)` result to match the original API signature (`{:ok, incident}` or `{:error, changeset}`). Update `evidence_test.exs` to ensure correct returns.</action>
    <verify>
      <automated>mix test test/parapet/evidence_test.exs</automated>
    </verify>
    <done>Incident creation transactionally schedules the Oban worker without breaking upstream callers.</done>
  </task>
</tasks>

<threat_model>
## Trust Boundaries
| Boundary | Description |
|----------|-------------|
| Job Queue -> Worker | Escaping DB bounds to execute custom policy code |

## STRIDE Threat Register
| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-01 | Tampering | `Evidence.create_incident` | mitigate | Bind incident creation and job enqueueing tightly via Ecto.Multi to prevent orphaned state. |
| T-1-02 | Info Disclosure / Tampering | `Escalation.Worker` | mitigate | Explicitly requery the DB for the incident state in the worker to ensure stale jobs don't escalate acknowledged incidents. |
</threat_model>

<verification>
- `mix test` passes
- `Parapet.Evidence.create_incident` transactional logic does not change external API.
</verification>

<success_criteria>
- Oban job scheduling is transactional and durable.
- Short-circuit correctly prevents unnecessary escalations on already handled incidents.
- Timeline entries capture system actions (short circuits and escalations).
</success_criteria>