# Phase 5: Multi-Node Safety Verification - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/parapet/evidence.ex` | service | CRUD | `lib/parapet/evidence.ex` | exact |
| `lib/parapet/escalation/worker.ex` | worker/service | event-driven | `lib/parapet/automation/executor.ex` | role-match |
| `lib/parapet/operator.ex` | service | request-response | `lib/parapet/operator.ex` | exact |
| `test/parapet/escalation/worker_test.exs` | test | event-driven | `test/parapet/automation/executor_test.exs` | role-match |
| `test/mix/tasks/parapet.doctor_test.exs` | test | request-response | `test/mix/tasks/parapet.doctor_test.exs` | exact |

## Pattern Assignments

### `lib/parapet/evidence.ex` (service, CRUD)

**Primary analog:** `lib/parapet/evidence.ex`

**Transaction seam pattern** ([lib/parapet/evidence.ex](/Users/jon/projects/parapet/lib/parapet/evidence.ex:47)):
```elixir
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:incident, Incident.changeset(%Incident{}, attrs))
  |> maybe_enqueue_escalation()

case repo().transaction(multi) do
  {:ok, %{incident: incident}} -> {:ok, incident}
  {:error, :incident, changeset, _} -> {:error, changeset}
  {:error, _step, reason, _} -> {:error, reason}
end
```

**Dependent insert pattern** ([lib/parapet/evidence.ex](/Users/jon/projects/parapet/lib/parapet/evidence.ex:60)):
```elixir
Ecto.Multi.insert(multi, :escalation_job, fn %{incident: incident} ->
  Parapet.Escalation.Worker.new(%{"incident_id" => incident.id})
end)
```

**Operator-command atomic write pattern** ([lib/parapet/evidence.ex](/Users/jon/projects/parapet/lib/parapet/evidence.ex:115)):
```elixir
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.update(:incident, incident_changeset)
  |> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} ->
    %TimelineEntry{}
    |> TimelineEntry.changeset(Map.put(timeline_attrs, :incident_id, incident.id))
  end)
```

**Recommended Phase 5 use**
- Keep all race-sensitive escalation and circuit-breaker state transitions behind a single `repo().transaction/1` seam in `Evidence`.
- If circuit-breaker durability is added here, follow the existing `{:ok, ...} | {:error, step, reason, changes}` return contract instead of ad hoc tuple shapes.
- Prefer `Ecto.Multi.run/3` for lock acquisition or conditional DB checks so later steps can see the result and tests can assert the op ordering.

**Gap to call out**
- Current `Evidence` patterns are transactional, but they do not show row locks, conditional `update_all`, or `SELECT ... FOR UPDATE`.

---

### `lib/parapet/escalation/worker.ex` (worker/service, event-driven)

**Primary analog:** `lib/parapet/automation/executor.ex`

**Current worker declaration** ([lib/parapet/escalation/worker.ex](/Users/jon/projects/parapet/lib/parapet/escalation/worker.ex:1)):
```elixir
defmodule Parapet.Escalation.Worker do
  @moduledoc """
  Oban worker for durable asynchronous dispatch of escalations.
  """
  use Oban.Worker, queue: :default
```

**Uniqueness analog to copy from** ([lib/parapet/automation/executor.ex](/Users/jon/projects/parapet/lib/parapet/automation/executor.ex:6)):
```elixir
use Oban.Worker,
  queue: :default,
  unique: [period: 3600, keys: [:incident_id, :step_id]]
```

**Current execution outcome persistence** ([lib/parapet/escalation/worker.ex](/Users/jon/projects/parapet/lib/parapet/escalation/worker.ex:130)):
```elixir
multi =
  Multi.new()
  |> Multi.update(:incident, incident_changeset)
  |> Multi.insert(:timeline_entry, fn %{incident: updated_incident} ->
    %Parapet.Spine.TimelineEntry{}
    |> Parapet.Spine.TimelineEntry.changeset(
      Map.put(timeline_attrs, :incident_id, updated_incident.id)
    )
  end)
```

**Short-circuit chronology pattern** ([lib/parapet/escalation/worker.ex](/Users/jon/projects/parapet/lib/parapet/escalation/worker.ex:16)):
```elixir
%{state: state} when state in ["investigating", "resolved"] ->
  Parapet.Evidence.append_timeline(incident_id, %{
    type: "escalation_short_circuited",
    payload: %{"reason" => "already_#{state}"}
  })
```

**Recommended Phase 5 use**
- Add Oban uniqueness here using the `Executor` declaration style. Phase 5 should treat this as required, not optional.
- Move any duplicate-alert prevention into a DB-guarded transaction, not just pre-transaction in-memory branching on `incident.state` or `runbook_data`.
- If a node crashes after policy execution but before persistence, the persistence seam here is the correct place to introduce idempotent markers or compare-and-swap semantics.

**Gap to call out**
- There is no in-repo analog for race-safe escalation claiming. Current code reads the incident outside the transaction and later updates it, which is vulnerable to double execution across nodes.

---

### `lib/parapet/operator.ex` (service, request-response)

**Primary analog:** `lib/parapet/operator.ex`

**Manual escalation request pattern** ([lib/parapet/operator.ex](/Users/jon/projects/parapet/lib/parapet/operator.ex:473)):
```elixir
escalation_data =
  incident
  |> escalation_command_state()
  |> Map.put("pending_trigger", true)
  |> Map.put("triggered_by", payload.actor)
  |> Map.put("trigger_reason", payload.reason)
  |> Map.put("trigger_requested_at", DateTime.utc_now() |> DateTime.truncate(:second))
```

**Delegation into atomic seam** ([lib/parapet/operator.ex](/Users/jon/projects/parapet/lib/parapet/operator.ex:483)):
```elixir
incident_changeset =
  Ecto.Changeset.change(incident, %{
    runbook_data: put_escalation_command_state(incident.runbook_data, escalation_data)
  })

Evidence.run_operator_command(
  incident_changeset: incident_changeset,
  timeline_attrs: timeline_attrs,
  audit_attrs: audit_attrs
)
```

**Suppression update pattern** ([lib/parapet/operator.ex](/Users/jon/projects/parapet/lib/parapet/operator.ex:532)):
```elixir
escalation_data =
  incident
  |> escalation_command_state()
  |> Map.put("suppressed_until", bounded_until)
  |> Map.put("suppressed_by", payload.actor)
  |> Map.put("suppression_reason", payload.reason)
  |> Map.delete("pending_trigger")
```

**Recommended Phase 5 use**
- Keep `Operator` responsible for bounded command metadata only; put cross-node enforcement in `Evidence` or the worker transaction, not in the UI boundary.
- For manual escalation triggers and suppressions, preserve the current `runbook_data["escalation"]` shape so new race-safe logic remains compatible with `WorkbenchContract` and existing tests.
- If a new “claimed_by_node” or “last_escalation_job_id” field is added, attach it under the same `runbook_data["escalation"]` subtree.

**Gap to call out**
- `trigger_next_escalation/2` currently writes pending state without a compare-and-swap guard, so concurrent operators or nodes can overwrite each other.

---

### `test/parapet/escalation/worker_test.exs` (test, event-driven)

**Primary analog:** `test/parapet/escalation/worker_test.exs`

**DummyRepo transaction reduction pattern** ([test/parapet/escalation/worker_test.exs](/Users/jon/projects/parapet/test/parapet/escalation/worker_test.exs:13)):
```elixir
def transaction(multi) do
  multi
  |> Ecto.Multi.to_list()
  |> Enum.reduce_while({:ok, %{}}, fn
    {name, {:update, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
      updated = Ecto.Changeset.apply_changes(changeset)
      send(self(), {:update, changeset})
      {:cont, {:ok, Map.put(acc, name, updated)}}
```

**Oban worker behavior analog** ([test/parapet/automation/executor_test.exs](/Users/jon/projects/parapet/test/parapet/automation/executor_test.exs:106)):
```elixir
test "perform/1 short-circuits and enqueues escalation when circuit trips" do
  Process.put(:mock_aggregate_count, 3)
  Application.put_env(:parapet, :escalation_policy, SuccessPolicy)

  job = %Oban.Job{args: %{"incident_id" => "inc-1", "step_id" => "auto_step"}}
  assert {:discard, "Circuit breaker tripped for step auto_step"} = Executor.perform(job)
```

**Multi op inspection analog** ([test/parapet/spine/alert_processor_test.exs](/Users/jon/projects/parapet/test/parapet/spine/alert_processor_test.exs:113)):
```elixir
assert_received {:transaction, ops}
assert {:incident, {:insert, changeset, _opts}} = List.keyfind(ops, :incident, 0)
```

**Recommended Phase 5 test style**
- Keep the current fast unit style for branch coverage: dummy repo, `Application.put_env/3`, `assert_received`, and `Ecto.Multi.to_list/1` inspection.
- Add a second tier of deterministic concurrency tests for this phase using a real Repo and DB coordination primitives. The repo currently has no direct analog for this, so the new tests should become the project standard.
- For duplicate-alert and restart safety, prefer asserting durable end state (`timeline_entry` count, escalation marker, unique job presence) over mailbox-only effects.

**Concurrency test recommendation**
- Use two tasks that block on a shared barrier before entering the race window.
- Seed a real incident row, let both tasks call the same worker or breaker seam, then assert only one durable mutation wins.
- Keep `async: false` like the surrounding tests.

**Gap to call out**
- Current tests are single-process and mostly mailbox-driven. There is no existing deterministic multi-process DB race test in `test/`.

---

### `test/mix/tasks/parapet.doctor_test.exs` (test, request-response)

**Primary analog:** `test/mix/tasks/parapet.doctor_test.exs`

**Filesystem-backed task setup pattern** ([test/mix/tasks/parapet.doctor_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.doctor_test.exs:9)):
```elixir
setup do
  Mix.shell(Mix.Shell.Process)
  Application.put_env(:parapet, :slos, [])
  Application.delete_env(:parapet, :escalation_policy)
  Application.delete_env(:parapet, :doctor_cluster_probe)
  Application.delete_env(:parapet, :repo)
```

**Shell capture helper pattern** ([test/mix/tasks/parapet.doctor_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.doctor_test.exs:31)):
```elixir
defp get_all_shell_messages(acc \\ []) do
  receive do
    {:mix_shell, _type, msg} ->
      msg_str = if is_list(msg), do: Enum.join(msg), else: to_string(msg)
      get_all_shell_messages([msg_str | acc])
  after
    0 -> Enum.join(Enum.reverse(acc), "\n")
  end
end
```

**Cluster posture expectation pattern** ([test/mix/tasks/parapet.doctor_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.doctor_test.exs:162)):
```elixir
test "flags missing escalation uniqueness as an error and states the static uncertainty boundary" do
  assert catch_exit(Doctor.run(["cluster_static"])) == {:shutdown, 1}

  messages = get_all_shell_messages()
  assert String.contains?(messages, "missing Oban uniqueness")
  assert String.contains?(messages, "Static check cannot prove distributed correctness")
end
```

**Implementation analog in task code** ([lib/mix/tasks/parapet.doctor.ex](/Users/jon/projects/parapet/lib/mix/tasks/parapet.doctor.ex:289)):
```elixir
worker_source = File.read!(worker_path)

errors =
  if String.contains?(worker_source, "unique:") do
    errors
  else
    [
      "Escalation worker is missing Oban uniqueness; concurrent nodes could execute the same escalation twice."
      | errors
    ]
  end
```

**Recommended Phase 5 use**
- Extend the existing doctor style instead of adding a new harness: mutate source/config fixtures, run `Doctor.run/1`, then assert both exit code and stable human-readable output.
- Add positive checks once `Escalation.Worker` has uniqueness configured, and add new static/runtime findings for missing DB-level breaker protection if the implementation exposes a detectable config or code marker.

**Gap to call out**
- Current doctor checks only prove presence of a `unique:` string and runtime env facts. They do not verify breaker atomicity or duplicate-alert suppression behavior.

## Shared Patterns

### Ecto.Multi Transaction Boundaries
**Source:** [lib/parapet/evidence.ex](/Users/jon/projects/parapet/lib/parapet/evidence.ex:47), [lib/parapet/spine/alert_processor.ex](/Users/jon/projects/parapet/lib/parapet/spine/alert_processor.ex:64)

```elixir
Ecto.Multi.new()
|> Ecto.Multi.update(:incident, incident_changeset)
|> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} ->
  TimelineEntry.changeset(%TimelineEntry{}, %{incident_id: incident.id, ...})
end)
|> repo.transaction()
```

Apply to:
- Race-safe escalation claims
- Circuit-breaker consumption/writeback
- “mark executed + append timeline” atomic updates

### Oban Uniqueness
**Source:** [lib/parapet/automation/executor.ex](/Users/jon/projects/parapet/lib/parapet/automation/executor.ex:6)

```elixir
use Oban.Worker,
  queue: :default,
  unique: [period: 3600, keys: [:incident_id, :step_id]]
```

Apply to:
- `Parapet.Escalation.Worker`
- Any crash/restart-sensitive escalation fanout jobs

### Mailbox-Driven Transaction Tests
**Source:** [test/parapet/evidence_test.exs](/Users/jon/projects/parapet/test/parapet/evidence_test.exs:26), [test/parapet/spine/alert_processor_test.exs](/Users/jon/projects/parapet/test/parapet/spine/alert_processor_test.exs:34)

```elixir
ops = Ecto.Multi.to_list(multi)
send(self(), {:transaction, ops})
assert_received {:transaction, ops}
assert {:incident, {:update, changeset, _opts}} = List.keyfind(ops, :incident, 0)
```

Apply to:
- Unit assertions that a race-safe path uses the intended transaction steps
- Verifying lock/claim ops are placed before side effects

### Doctor Output Assertions
**Source:** [test/mix/tasks/parapet.doctor_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.doctor_test.exs:31)

```elixir
assert catch_exit(Doctor.run(["cluster_static"])) == {:shutdown, 1}
messages = get_all_shell_messages()
assert String.contains?(messages, "missing Oban uniqueness")
```

Apply to:
- New multi-node doctor checks
- Runtime probe error-path coverage

## No Direct Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/parapet/automation/circuit_breaker.ex` DB-level atomic breaker claim | service | CRUD | Current breaker only counts prior audits via `aggregate/3`; there is no existing lock, compare-and-swap, or atomic decrement/update pattern. |
| `lib/parapet/escalation/worker.ex` duplicate-alert prevention across node crashes | worker | event-driven | Worker reads incident outside the transaction and lacks uniqueness or execution claim markers. |
| New concurrency integration tests | test | event-driven | Repo has no real multi-process Ecto race test; current patterns stop at DummyRepo simulation. |

## Recommended Test Styles For Phase 5

1. Keep fast branch tests in `test/parapet/escalation/worker_test.exs` using the existing `DummyRepo` + `assert_received` style for policy/suppression/manual-trigger branches.
2. Add real-Repo deterministic race tests for breaker/escalation paths. Use two tasks, a barrier, and `async: false` so both tasks hit the same DB row at the same time.
3. Assert durable invariants, not just function returns: one timeline entry, one escalation marker, one surviving job, one alert dispatch.
4. Extend `test/mix/tasks/parapet.doctor_test.exs` with one failing static check before uniqueness/atomicity markers exist and one passing check after the new configuration is present.

## Metadata

**Analog search scope:** `lib/parapet`, `lib/mix/tasks`, `test/parapet`, `test/mix/tasks`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-20
