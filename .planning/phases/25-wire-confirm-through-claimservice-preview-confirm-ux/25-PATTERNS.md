# Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX — Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 6 (4 modified, 2 new)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/operator.ex` (modify `confirm_runbook_step/4`) | service / operator-API | request-response with claim-protected execute | `lib/parapet/automation/executor.ex` (`perform/1` four-arm case) | exact (third caller of `claim_action/1`) |
| `lib/parapet/operator.ex` (modify `compute_preview/3`) | service helper | transform (build preview payload + hash) | `lib/parapet/operator.ex:750-780` (self — extend in place) | self (in-place edit) |
| `lib/parapet/operator.ex` (modify `find_recent_preview/3`) | service helper | data-fetch (read preview from TimelineEntry) | `lib/parapet/operator.ex:782-819` (self — extend in place) | self (in-place edit) |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` (modify `handle_event("confirm_mitigation", ...)`) | LiveView event handler | request-response (form submit → operator call → flash) | `operator_detail_live.ex:103-121` (`preview_mitigation` handler — 2-arm sibling) | exact (sibling handler, same socket → call → flash shape) |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` (modify `preview_panel/1`) | LiveView functional component | template rendering | `operator_components.ex:342-403` (self — add action name field + thread hash) | self (in-place edit) |
| `test/parapet/operator/confirm_concurrency_test.exs` (NEW) | test (integration / concurrency) | multi-process race with rendezvous | `test/parapet/automation/executor_concurrency_test.exs:1-146` | exact (clone-and-substitute) |
| `test/parapet/operator/preview_lifecycle_test.exs` (NEW — optional) OR extensions to `test/parapet/operator_test.exs` | test (unit) | request-response (synthetic time / payload mutation) | `test/parapet/operator_test.exs:495-526` (existing `confirm_runbook_step` test with `Process.put(:mock_entries, [...])` mock + expired-preview shape) | exact (sibling test, same DummyRepo harness) |

## Pattern Assignments

### `lib/parapet/operator.ex` — `confirm_runbook_step/4` (operator-API, request-response + claim-protected execute)

**Analog:** `lib/parapet/automation/executor.ex` (`perform/1`); secondary precedent `lib/parapet/escalation/worker.ex` (`perform/1`).

**Imports / aliases pattern** (`lib/parapet/automation/executor.ex:17-21`):

```elixir
alias Parapet.Automation.ClaimService
alias Parapet.Evidence
alias Parapet.Spine.Incident
alias Parapet.Operator
alias Parapet.Operator.ActionPayload
```

Operator already aliases `Evidence`, `Incident`, `ActionPayload`. **Add** `alias Parapet.Automation.ClaimService` at the top of `lib/parapet/operator.ex` (its alias block).

**Four-arm `case` template** (`lib/parapet/automation/executor.ex:29-47` — **the template**):

```elixir
case claim_service().claim_action(
       incident_id: incident_id,
       action_kind: "automation",
       action_key: step_id,
       breaker_step_id: step_id,
       idempotency_key: idempotency_key
     ) do
  {:won, claim} ->
    execute_claimed_step(incident, step_id, idempotency_key, claim)

  {:short_circuited, _claim, reason} ->
    record_short_circuit(incident_id, step_id, reason)

  {:conflicted, _claim} ->
    record_claim_conflict(incident_id, step_id)

  {:error, reason} ->
    {:error, reason}
end
```

**Important deviations from the template for the operator path:**
- Substitute `"automation"` → `"operator"` for `action_kind`.
- Substitute `step_id` → `to_string(step_id_atom)` for `action_key` (operator uses atom step_ids inside; ClaimService expects string).
- Add `breaker_step_id: step_id_atom` (atom — matches Executor's `breaker_step_id: step_id` shape but Operator already has it as an atom).
- Inside `{:won, claim}`: do NOT delegate to `execute_claimed_step` (Executor's pattern); instead, **inline** `capability.execute.(incident, preview_entry.target_refs)` and on `{:ok, _}`, call `ClaimService.mark_executed(claim)` followed by the existing `Evidence.run_operator_command(...)` block at `lib/parapet/operator.ex:723-727`.
- Inside `{:short_circuited, _claim, reason_string}`: **wrap** to public 2-tuple `{:short_circuited, map_short_circuit_reason(reason_string)}` (do NOT call a `record_short_circuit/3` helper — Operator returns the variant; LiveView surfaces it).
- Inside `{:conflicted, claim}`: **wrap** to public 2-tuple `{:conflicted, claim.id}` (UUID string — confirmed `:binary_id` at `lib/parapet/spine/action_claim.ex:27`).
- Do NOT add a fifth catch-all `_` arm — Dialyzer flags unreachable in Executor/Worker; same here.

**Secondary precedent — Escalation Worker** (`lib/parapet/escalation/worker.ex:37-63`):

```elixir
case ClaimService.claim_action(
       incident_id: incident_id,
       action_kind: "escalation",
       action_key: action_key,
       idempotency_key: idempotency_key,
       suppression_check: &suppression_gate/1
     ) do
  {:won, claim} ->
    execute_claim(incident_id, escalation_state, claim, policy_module, opts, job)

  {:short_circuited, claim, reason} ->
    persist_short_circuit(incident_id, escalation_state, claim, reason)

  {:conflicted, claim} ->
    resolve_conflict(incident_id, escalation_state, claim, idempotency_key, policy_module, opts, job)

  {:error, reason} ->
    {:error, reason}
end
```

Note Worker's `{:conflicted, _}` arm calls `resolve_conflict/7` which retries — **do not copy this**. The operator path is human-clicked, not retryable. Wrap and return.

**Existing structure to preserve** (`lib/parapet/operator.ex:690-744`):

```elixir
def confirm_runbook_step(
      %Incident{} = incident,
      step_id,
      preview_token,
      %ActionPayload{} = payload
    ) do
  if valid_payload?(payload) do
    with {:ok, module} <- extract_module(incident.runbook_data),
         {:ok, step_id_atom} <- parse_step_id(step_id),
         true <- function_exported?(module, :__runbook_schema__, 0) || {:error, :not_a_runbook},
         schema <- module.__runbook_schema__(),
         step <- Enum.find(schema.steps, &(&1.id == step_id_atom)),
         {:ok, step} <- validate_step_exists(step),
         capability_id <- step.capability,
         capability when not is_nil(capability) <-
           Parapet.Capabilities.get_recovery(capability_id),
         {:ok, preview_entry} <- find_recent_preview(incident.id, step_id_atom, preview_token) do
      if DateTime.compare(preview_entry.expires_at, DateTime.utc_now()) == :gt do
        # ... (the body to be replaced — currently calls capability.execute directly)
        # CURRENT direct call site at :710:
        #   case capability.execute.(incident, preview_entry.target_refs) do
        # CURRENT stale-preview return at :736:
        #   {:error, :stale_preview}  -->  REPLACE WITH {:short_circuited, :preview_expired}
      end
    else
      nil -> {:error, :capability_unwired}
      {:error, _} = error -> error
    end
  else
    {:error, :invalid_payload}
  end
end
```

The `with`-chain head and the `else` clauses do not change. The replaced block lives **between** the `if DateTime.compare(...) == :gt do` line (already at `:707`) and its `else` branch (`:735-737`).

**String→atom mapper** — **NO codebase analog** for this pattern; it is new to Phase 25. RESEARCH.md Pattern 3 provides the closed-vocab table, and RESEARCH.md Example 2 (`25-RESEARCH.md:480-488`) provides the canonical implementation pattern:

```elixir
defp map_short_circuit_reason("already_resolved"), do: :incident_resolved
defp map_short_circuit_reason("already_investigating"), do: :incident_resolved
defp map_short_circuit_reason("already_open"), do: :incident_resolved
defp map_short_circuit_reason("circuit_breaker_tripped"), do: :breaker_open
defp map_short_circuit_reason("suppressed"), do: :incident_resolved
defp map_short_circuit_reason(_other), do: :internal_error
```

Internal ClaimService source strings verified at:
- `lib/parapet/automation/claim_service.ex:163` — `"already_#{state}"` for state gate.
- `lib/parapet/automation/circuit_breaker.ex:35` — `"circuit_breaker_tripped"`.
- `lib/parapet/automation/claim_service.ex:179-181` — `to_string(reason)` from suppression gate.

Frozen atom vocab destination: `lib/parapet/telemetry/recovery_action.ex:46-51` (`:preview_expired`, `:target_refs_drift`, `:incident_resolved`, `:breaker_open`).

**`{:won, claim}` body — inlined execute path** (assembled from existing `lib/parapet/operator.ex:710-731`):

```elixir
case capability.execute.(incident, preview_entry.target_refs) do
  {:ok, exec_result} ->
    Parapet.Automation.ClaimService.mark_executed(claim)
    timeline_attrs = %{
      type: "recovery_confirmed",
      payload: %{
        "step_id" => to_string(step_id_atom),
        "capability" => to_string(capability_id),
        "result" => inspect(exec_result)
      }
    }
    audit_attrs = build_audit("operator_confirm_recovery", payload)
    Evidence.run_operator_command(
      incident_changeset: Ecto.Changeset.change(incident, %{}),
      timeline_attrs: timeline_attrs,
      audit_attrs: audit_attrs
    )

  {:error, reason} ->
    {:error, reason}
end
```

`Evidence.run_operator_command(...)` is the **existing** happy-path return shape — keep it verbatim. CONTEXT D-03 forbids changing `{:ok, _}` shape.

---

### `lib/parapet/operator.ex` — `compute_preview/3` (in-place edit, role: service helper, data flow: transform)

**Analog:** Self — `lib/parapet/operator.ex:750-780`. The edit is additive (one new field).

**Existing code to preserve** (`lib/parapet/operator.ex:750-780`):

```elixir
defp compute_preview(capability, incident, step) do
  expires_at = DateTime.utc_now() |> DateTime.add(300, :second)
  preview_token = :crypto.strong_rand_bytes(16) |> Base.encode16()

  base_preview = %{
    "capability" => to_string(capability.id),
    "step_id" => to_string(step.id),
    "target_kind" => capability.target_kind || step.target_kind,
    "target_refs" => [],
    "count" => 0,
    "preconditions" => [],
    "warnings" => [],
    "idempotency_caveats" => "Standard idempotency applies.",
    "expires_at" => expires_at,
    "preview_token" => preview_token
  }

  if is_function(capability.preview, 2) do
    case capability.preview.(incident, step) do
      {:ok, host_data} ->
        host_data_str = for {k, v} <- host_data, into: %{}, do: {to_string(k), v}
        Map.merge(base_preview, host_data_str)

      _ ->
        base_preview
    end
  else
    base_preview
  end
end
```

**Edit pattern — `target_refs_hash` must be computed AFTER the `Map.merge` (Pitfall 2 in `25-RESEARCH.md:347-355`):**

The hash must be computed against the **final** `target_refs` value, not the `[]` default. The merge at `:772` is where host-supplied `target_refs` overrides the default; compute the hash on the merged result, then `Map.put` it in. Same canonicalization invariant as the `find_recent_preview/3` consumer side.

**Hash function pattern** — no codebase analog; RESEARCH.md Example 3 (`25-RESEARCH.md:494-503`):

```elixir
defp target_refs_hash(target_refs) do
  target_refs
  |> List.wrap()
  |> Enum.map(&to_string/1)
  |> Enum.sort()
  |> :erlang.term_to_binary()
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
end
```

**Precedent for `:crypto` use in this file:** the existing line `preview_token = :crypto.strong_rand_bytes(16) |> Base.encode16()` at `:752` already imports `:crypto` and `Base.encode16/2`. Zero new deps.

---

### `lib/parapet/operator.ex` — `find_recent_preview/3` (in-place edit, role: service helper, data flow: data-fetch)

**Analog:** Self — `lib/parapet/operator.ex:782-819`. The edit surfaces one additional payload field.

**Existing return shape** (`:814`):

```elixir
{:ok, %{expires_at: expires_at, target_refs: payload["target_refs"]}}
```

**Edit pattern** — extend the map to include `target_refs_hash: payload["target_refs_hash"]`. **Backward compat:** RESEARCH.md Open Question #2 (`25-RESEARCH.md:696-699`) — existing previews lack the hash field; consumer at `confirm_runbook_step/4` must treat `nil` hash as "skip the drift gate" (one-line nil-guard). After the 5-min expiry window, all live previews have rotated through the new compute path.

The DateTime-parsing block (`:801-812`) does NOT change.

---

### `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — `handle_event("confirm_mitigation", ...)` (LiveView event handler, request-response)

**Analog:** Sibling handler `handle_event("preview_mitigation", ...)` at `operator_detail_live.ex:103-121` — same socket → call → flash shape; same `incident_id` re-fetch pattern; same `ActionPayload` build shape.

**Existing 2-arm handler** (`operator_detail_live.ex:123-142` — the edit target):

```elixir
def handle_event("confirm_mitigation", %{"step" => step, "incident_id" => incident_id, "token" => token}, socket) do
  incident = DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)
  payload = %Parapet.Operator.ActionPayload{
    actor: "operator_ui",
    reason: "Confirmed mitigation from UI",
    correlation_id: Ecto.UUID.generate(),
    action_type: :execute_mitigation,
    idempotency_key: Ecto.UUID.generate()
  }

  case Parapet.Operator.confirm_runbook_step(incident, step, token, payload) do
    {:ok, _result} ->
      {:noreply,
       socket
       |> put_flash(:info, "Mitigation confirmed and executed")
       |> assign(incident: Parapet.Operator.incident_detail(incident_id))}
    {:error, reason} ->
      {:noreply, put_flash(socket, :error, "Confirmation failed: #{inspect(reason)}")}
  end
end
```

**Sibling `preview_mitigation` handler** (`operator_detail_live.ex:103-121`) — same shape, used as the structural twin:

```elixir
def handle_event("preview_mitigation", %{"step" => step, "incident_id" => incident_id}, socket) do
  incident = DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)
  payload = %Parapet.Operator.ActionPayload{
    actor: "operator_ui",
    reason: "Previewed mitigation from UI",
    correlation_id: Ecto.UUID.generate(),
    action_type: :preview_mitigation
  }

  case Parapet.Operator.preview_runbook_step(incident, step, payload) do
    {:ok, _result} ->
      {:noreply,
       socket
       |> put_flash(:info, "Preview generated")
       |> assign(incident: Parapet.Operator.incident_detail(incident_id))}
    {:error, reason} ->
      {:noreply, put_flash(socket, :error, "Preview failed: #{inspect(reason)}")}
  end
end
```

**Edit pattern — grow 2 → 4 arms**:
- Keep the `{:ok, _result}` arm (existing info flash + re-derive incident detail).
- Keep the `{:error, reason}` arm (existing generic error flash).
- **Add** `{:short_circuited, reason}` → flash via a closed `short_circuit_flash/1` private function (CONTEXT D-11). Use `:warning` flash level (not `:error`) — operator-actionable, not failure. Re-derive incident detail via `Parapet.Operator.incident_detail(incident_id)` (same as `:ok` arm) so the Preview state clears and the Preview button reappears (the Re-Preview affordance reuses the existing `preview_mitigation` button on the runbook card — A7 in `25-RESEARCH.md:684`).
- **Add** `{:conflicted, _claim_id}` → verbatim flash text "Another node is executing this recovery — refresh to see the outcome" (CONTEXT D-11, ROADMAP success criterion #2 — do not paraphrase). Also re-derive incident detail.

RESEARCH.md Example 4 (`25-RESEARCH.md:507-547`) gives the canonical 4-arm shape.

**Closed `short_circuit_flash/1` private function pattern** — closed clauses for each frozen-vocab atom + no fallback (or `:internal_error` fallback):

```elixir
defp short_circuit_flash(:preview_expired), do: "Preview expired — please re-Preview before confirming"
defp short_circuit_flash(:incident_resolved), do: "Incident already resolved — no action needed"
defp short_circuit_flash(:breaker_open), do: "Circuit breaker open — recovery temporarily disabled"
defp short_circuit_flash(:target_refs_drift), do: "Target state changed since Preview — please re-Preview"
```

---

### `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — `preview_panel/1` (functional component, template rendering)

**Analog:** Self — `operator_components.ex:342-403`. The edit adds one rendered field (action name) and threads `target_refs_hash` through Confirm submit (CONTEXT D-12 — plan-phase picks LiveView assigns vs hidden form field; **Pitfall 6 in `25-RESEARCH.md:392-398` recommends LiveView assigns** to avoid the `phx-value-*` dash/underscore footgun).

**Existing grid pattern for rendered fields** (`operator_components.ex:355-365`):

```heex
<div class="grid grid-cols-2 gap-4 mb-4">
  <div>
    <p class="text-[10px] text-gray-500 uppercase font-bold">Target Kind</p>
    <p class="text-sm font-medium text-gray-900"><%= preview.data["target_kind"] %></p>
  </div>
  <div>
    <p class="text-[10px] text-gray-500 uppercase font-bold">Affected Count</p>
    <p class="text-sm font-medium text-gray-900"><%= preview.data["count"] %></p>
  </div>
</div>
```

**Edit pattern — add an "Action" cell with the same label/value shape.** The action name is fetched via `Parapet.Capabilities.get_recovery(capability_id).name` (CONTEXT D-12). The capability_id is already in `preview.data["capability"]` (written at `lib/parapet/operator.ex:755`). Either:
- (A) Resolve the name in the LiveView assigns and pass via `@detail.derived.active_preview.action_name` (preferred — no module call in template), OR
- (B) Call `Parapet.Capabilities.get_recovery(preview.data["capability"]).name` inline in the template (less ideal — couples the template to the registry call).

Recommendation: (A) — extend `WorkbenchContract.find_active_preview/1` (`lib/parapet/operator/workbench_contract.ex:167-206`) to surface `action_name` alongside the existing fields. Note CONTEXT D-09 says `find_active_preview/1` is "unchanged" — this is a small additive surface (one new field on the returned map), not a contract break. Plan-phase to confirm.

**Existing Confirm button** (`operator_components.ex:385-394`):

```heex
<button
  phx-click="confirm_mitigation"
  phx-value-step={preview.step_id}
  phx-value-incident_id={@detail.incident.id}
  phx-value-token={preview.preview_token}
  class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded text-sm shadow-md transition-all active:scale-95"
>
  Confirm Recovery
</button>
```

If D-12 picks "LiveView assigns" (recommended): no new `phx-value-*` attribute; the server holds `target_refs_hash` itself and re-computes against the stored `preview_entry.target_refs` on confirm.

If D-12 picks "hidden form field": add `phx-value-targethash={preview.target_refs_hash}` (single-word param to avoid dash-vs-underscore footgun — Pitfall 6).

---

### `test/parapet/operator/confirm_concurrency_test.exs` (NEW — test, multi-process race with rendezvous)

**Analog:** `test/parapet/automation/executor_concurrency_test.exs:1-146` — **the template**. Clone the file structure verbatim and substitute test target.

**`use` + alias header pattern** (`test/parapet/automation/executor_concurrency_test.exs:1-7`):

```elixir
defmodule Parapet.Automation.ExecutorConcurrencyTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Automation.Executor
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry, ToolAudit}
```

For the new file, substitute module name → `Parapet.Operator.ConfirmConcurrencyTest`; alias → `alias Parapet.Operator` and `alias Parapet.Operator.ActionPayload`. `async: false` is required because the test uses `unboxed_run` (raw Postgres, no SQL Sandbox).

**Inline runbook module pattern** (`executor_concurrency_test.exs:9-25`):

```elixir
defmodule ConcurrencyRunbook do
  use Parapet.Runbook

  step(:auto_step,
    type: :mitigation,
    auto_execute: true
  )

  def execute_mitigation(:auto_step, _incident) do
    if pid = Application.get_env(:parapet, :executor_test_pid) do
      send(pid, {:mitigated, node()})
    end

    Process.sleep(75)
    {:ok, :mitigated}
  end
end
```

For the operator-confirm test: the runbook step uses `type: :mitigation, capability: :retry_async_item, target_kind: "async_item"` (operator path uses Recovery capability, not the Runbook `execute_mitigation/2` callback). The capability must be registered via `Parapet.Capabilities.register_recovery/2` inside `unboxed_run` (Pitfall 4 — `ConcurrencyCase` does NOT reset the Capabilities Agent; must call `Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)` first).

**Application-env + on_exit setup** (`executor_concurrency_test.exs:28-36`):

```elixir
@tag :unboxed
test "concurrent executor attempts produce one executed effect path and one conflict no-op" do
  Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)
  Application.put_env(:parapet, :executor_test_pid, self())

  on_exit(fn ->
    Application.delete_env(:parapet, :automation)
    Application.delete_env(:parapet, :executor_test_pid)
    Application.delete_env(:parapet, :repo)
  end)
```

Substitute `:executor_test_pid` → `:operator_test_pid` for the operator path. `@tag :unboxed` is required so the test runs outside the SQL Sandbox; default `mix test` excludes — invoke via `mix test --include unboxed` (Validation Architecture `25-RESEARCH.md:719`).

**`unboxed_run` + ConcurrencyRepo.insert + Preview setup pattern** (`executor_concurrency_test.exs:38-52`):

```elixir
incident =
  unboxed_run(fn ->
    ConcurrencyBootstrap.reset!()

    {:ok, incident} =
      %Incident{}
      |> Incident.changeset(%{
        title: "Concurrent automation",
        correlation_key: "corr-concurrency",
        runbook_data: %{"module" => to_string(ConcurrencyRunbook)}
      })
      |> ConcurrencyRepo.insert()

    incident
  end)
```

For the operator-confirm test: add **after** `ConcurrencyBootstrap.reset!()` and **before** the incident insert:
1. `Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)` (Pitfall 4).
2. `Parapet.Capabilities.register_recovery(:retry_async_item, name: "...", preview: fn ... end, execute: fn ... end)`.
3. After insert, call `Operator.preview_runbook_step(incident, :op_step, preview_payload)` to obtain a valid preview_token.
4. Return `{incident, preview_token}` (tuple) from `unboxed_run`.

RESEARCH.md Example 5 (`25-RESEARCH.md:553-660`) gives the full skeleton.

**Task.async rendezvous + `:go` broadcast pattern** (`executor_concurrency_test.exs:54-76` — the multi-node race idiom):

```elixir
parent = self()
job = %Oban.Job{args: %{"incident_id" => incident.id, "step_id" => "auto_step"}}

contenders =
  for _ <- 1..2 do
    Task.async(fn ->
      unboxed_run(fn ->
        send(parent, {:ready, self()})

        receive do
          :go -> Executor.perform(job)
        end
      end)
    end)
  end

for _ <- 1..2 do
  assert_receive {:ready, _pid}, 1_000
end

Enum.each(contenders, fn task -> send(task.pid, :go) end)

results = Enum.map(contenders, &Task.await(&1, 5_000))
```

For the operator-confirm test: replace the `Executor.perform(job)` invocation with `Operator.confirm_runbook_step(incident, :op_step, preview_token, payload)`. Build the `ActionPayload` (with `idempotency_key: "operator_confirm_#{incident.id}_op_step"`) inside the Task.

**Result-assertion pattern** (`executor_concurrency_test.exs:78-86`):

```elixir
assert Enum.count(results, &(&1 == :ok)) == 1

assert Enum.count(results, fn
         {:discard, "Automation claim conflicted for step auto_step"} -> true
         _ -> false
       end) == 1

assert_receive {:mitigated, _node}, 1_000
refute_receive {:mitigated, _node}, 200
```

For the operator-confirm test: substitute return-shape assertions:

```elixir
assert Enum.count(results, &match?({:ok, _}, &1)) == 1
assert Enum.count(results, &match?({:conflicted, _}, &1)) == 1
assert_receive {:executed, _node}, 1_000
refute_receive {:executed, _node}, 200
```

And add the conflict-`claim_id` round-trip check from RESEARCH.md Example 5 (`25-RESEARCH.md:649-657`) — fetch the conflicted claim by id from `ConcurrencyRepo`, assert `claim.status == "executed"` (the winner's status after `mark_executed`), `claim.action_kind == "operator"`, `claim.action_key == "op_step"`.

**DB-state assertion pattern** (`executor_concurrency_test.exs:88-108`):

```elixir
unboxed_run(fn ->
  claims =
    ConcurrencyRepo.all(
      from(claim in ActionClaim,
        where:
          claim.incident_id == ^incident.id and claim.action_kind == "automation" and
            claim.action_key == "auto_step"
      )
    )

  assert length(claims) == 1
  assert hd(claims).status == "executed"
  assert hd(claims).idempotency_key == "auto_exec_#{incident.id}_auto_step"
```

For operator path: `claim.action_kind == "operator"`, `claim.action_key == "op_step"`. Idempotency key shape: `"operator_confirm_#{incident.id}_op_step"` (plan-phase confirms — adopters could supply arbitrary keys via `ActionPayload.idempotency_key`).

---

### `test/parapet/operator/preview_lifecycle_test.exs` (NEW, optional) OR extensions to `test/parapet/operator_test.exs`

**Analog:** `test/parapet/operator_test.exs:495-526` — the existing `confirm_runbook_step executes and rejects stale previews` test. Same `DummyRepo` harness, same `Process.put(:mock_entries, [entry])` mock pattern.

**`use ExUnit.Case, async: false` header pattern** (`test/parapet/operator_test.exs:1-6`):

```elixir
defmodule Parapet.OperatorTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator
  alias Parapet.Operator.ActionPayload
  alias Parapet.Spine.{Incident, TimelineEntry, ToolAudit}
```

`async: false` because `Process.put`-based mock entries leak across tests if parallel. Substitute module name for the new file.

**DummyRepo `Process.get(:mock_entries, [])` pattern** (`test/parapet/operator_test.exs:14-17`):

```elixir
def all(query) do
  send(self(), {:repo_all, query})
  source = query.from |> Map.fetch!(:source) |> elem(1)
  case source do
    Parapet.Spine.TimelineEntry -> Process.get(:mock_entries, [])
    ...
  end
end
```

The `find_recent_preview/3` consumer reads via `Evidence.repo().all(...)` which is `DummyRepo.all/1` in test (configured via `Application.put_env(:parapet, :repo, DummyRepo)` — check existing setup at `test/parapet/operator_test.exs:455` or equivalent).

**Existing expired-preview mock pattern** (`test/parapet/operator_test.exs:495-526` — the existing test to extend / update):

```elixir
test "confirm_runbook_step executes and rejects stale previews", %{
  payload: payload,
  incident: incident
} do
  {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
  token = preview["preview_token"]

  entry = %TimelineEntry{
    incident_id: incident.id,
    type: "recovery_preview",
    payload: preview,
    inserted_at: DateTime.utc_now()
  }

  Process.put(:mock_entries, [entry])

  assert {:ok, result} = Operator.confirm_runbook_step(incident, :retry, token, payload)
  assert %TimelineEntry{type: "recovery_confirmed"} = result.timeline_entry

  expired_preview =
    Map.put(preview, "expires_at", DateTime.utc_now() |> DateTime.add(-10, :second))

  expired_entry = %TimelineEntry{entry | payload: expired_preview}
  Process.put(:mock_entries, [expired_entry])

  assert {:error, :stale_preview} =
           Operator.confirm_runbook_step(incident, :retry, token, payload)
end
```

**Edit pattern for the existing test** — REPLACE the assertion at `test/parapet/operator_test.exs:524`:

```elixir
# BEFORE
assert {:error, :stale_preview} =
         Operator.confirm_runbook_step(incident, :retry, token, payload)

# AFTER
assert {:short_circuited, :preview_expired} =
         Operator.confirm_runbook_step(incident, :retry, token, payload)
```

This is the **only** existing `:stale_preview` reference outside the live source — RESEARCH.md confirms via grep at `25-RESEARCH.md:407-412`.

**New test pattern for `:target_refs_drift`** — clone the expired-preview block; instead of mutating `expires_at`, mutate `target_refs` post-write:

```elixir
test "confirm_runbook_step returns :target_refs_drift on hash mismatch", %{...} do
  {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
  token = preview["preview_token"]

  # Tamper with target_refs post-write but keep target_refs_hash from original
  tampered = Map.put(preview, "target_refs", ["tampered-ref"])
  entry = %TimelineEntry{incident_id: incident.id, type: "recovery_preview", payload: tampered, inserted_at: DateTime.utc_now()}
  Process.put(:mock_entries, [entry])

  assert {:short_circuited, :target_refs_drift} =
           Operator.confirm_runbook_step(incident, :retry, token, payload)
end
```

**New test pattern for `{:conflicted, _claim_id}` shape** — separate from the multi-node concurrency test; this is a synchronous unit test asserting return shape. Mock the `claim_service` call (or use the real `ClaimService` against the test repo with a pre-inserted conflicting claim row). RESEARCH.md does not give a concrete unit pattern for this — concurrency_test.exs handles the race semantics; this unit test only asserts the wrap-to-2-tuple translation. Plan-phase may decide the concurrency test alone is sufficient.

## Shared Patterns

### Pattern A: Five (actually four)-arm `claim_action/1` dispatch
**Source:** `lib/parapet/automation/executor.ex:29-47`
**Apply to:** `lib/parapet/operator.ex` `confirm_runbook_step/4` (third caller after `Executor.perform/1` and `Escalation.Worker.perform/1`).
**Critical:** Four arms total — `{:won, _}`, `{:short_circuited, _, _}`, `{:conflicted, _}`, `{:error, _}`. No catch-all `_` arm (Dialyzer will flag unreachable).

```elixir
case ClaimService.claim_action(...) do
  {:won, claim} -> # ... execute ... mark_executed
  {:short_circuited, _claim, reason} -> # ... wrap/handle
  {:conflicted, _claim} -> # ... wrap/handle
  {:error, reason} -> {:error, reason}
end
```

### Pattern B: Internal-3-tuple → public-2-tuple wrapping at API boundary
**Source:** `lib/parapet/automation/claim_service.ex:51-58` (internal shape) and Operator-API contract (public shape).
**Apply to:** Only the operator path — `Executor` and `Worker` use the internal shape directly because they don't expose the return to adopters. The operator API MUST unwrap.

```elixir
{:short_circuited, _claim, reason_string} ->
  {:short_circuited, map_short_circuit_reason(reason_string)}

{:conflicted, claim} ->
  {:conflicted, claim.id}  # claim.id is UUID string (:binary_id at action_claim.ex:27)
```

### Pattern C: ConcurrencyCase + `unboxed_run` + Task.async rendezvous
**Source:** `test/parapet/automation/executor_concurrency_test.exs:54-86`
**Apply to:** `test/parapet/operator/confirm_concurrency_test.exs`.

```elixir
use Parapet.TestSupport.ConcurrencyCase, async: false

@tag :unboxed
test "..." do
  # 1. Application.put_env + on_exit cleanup
  # 2. unboxed_run -> bootstrap reset -> Agent.update Capabilities -> register_recovery -> insert incident -> preview
  # 3. Task.async (x2) with send({:ready, self()}) + receive :go -> Operator.confirm_runbook_step(...)
  # 4. assert_receive {:ready, _} x2 -> send :go to all -> Task.await
  # 5. Assert exactly one {:ok, _} and one {:conflicted, _}
  # 6. Assert exactly one execute side-effect (assert_receive + refute_receive)
end
```

### Pattern D: DummyRepo + `Process.put(:mock_entries, [...])` for synchronous unit tests
**Source:** `test/parapet/operator_test.exs:8-20, :495-526`
**Apply to:** New `:target_refs_drift` and updated `:preview_expired` unit tests in `operator_test.exs` (or new `preview_lifecycle_test.exs`).

```elixir
entry = %TimelineEntry{incident_id: incident.id, type: "recovery_preview", payload: preview, inserted_at: DateTime.utc_now()}
Process.put(:mock_entries, [entry])
assert {:short_circuited, _reason} = Operator.confirm_runbook_step(incident, :retry, token, payload)
```

### Pattern E: Sibling LiveView event handler shape (socket → call → put_flash → assign)
**Source:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex:103-121` (`preview_mitigation` sibling).
**Apply to:** `confirm_mitigation` 4-arm handler.

```elixir
def handle_event("event_name", params, socket) do
  incident = DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)
  payload = %Parapet.Operator.ActionPayload{...}

  case Parapet.Operator.<call>(...) do
    {:ok, _result} ->
      {:noreply, socket |> put_flash(:info, "...") |> assign(incident: Parapet.Operator.incident_detail(incident_id))}

    # ... additive arms ...

    {:error, reason} ->
      {:noreply, put_flash(socket, :error, "...: #{inspect(reason)}")}
  end
end
```

### Pattern F: `:crypto.hash(:sha256, _)` + `Base.encode16(case: :lower)` for content addressing
**Source:** `lib/parapet/operator.ex:752` (`preview_token = :crypto.strong_rand_bytes(16) |> Base.encode16()` — same module already uses `:crypto` + `Base.encode16`).
**Apply to:** New `target_refs_hash/1` private function in `lib/parapet/operator.ex`.

```elixir
target_refs
|> List.wrap()
|> Enum.map(&to_string/1)  # jsonb roundtrip coerces atoms→strings; canonicalize at hash time (Pitfall 5)
|> Enum.sort()
|> :erlang.term_to_binary()
|> then(&:crypto.hash(:sha256, &1))
|> Base.encode16(case: :lower)
```

## No Analog Found

Files / patterns with no close match in the codebase (planner should use RESEARCH.md examples instead):

| Pattern | Location | Reason | Fallback |
|---------|----------|--------|----------|
| String→atom mapper for ClaimService short-circuit reasons | New private function in `lib/parapet/operator.ex` | First adopter-facing wrapper around `ClaimService`'s internal vocab; no other code in the project translates these strings to atoms | Use `25-RESEARCH.md:480-488` (Example 2) verbatim; closed clauses + `_other` fallback |
| `target_refs_hash` consistency gate at confirm time | New `cond`/`if` gate in `confirm_runbook_step/4` between expiry check (`:707`) and `ClaimService.claim_action` call | Net-new logic; no existing operator-path drift detection | Use `25-RESEARCH.md` Pattern 4 (`:288-311`) + Example 1 (`:422-475`); nil-guard for backward-compat |
| 4-arm LiveView `handle_event` with `{:short_circuited, _}` + `{:conflicted, _}` branches | `operator_detail_live.ex` `confirm_mitigation` handler | No existing 4-arm handler in the demo LiveView; siblings are all 2-arm | Use `25-RESEARCH.md:507-547` (Example 4); the sibling `preview_mitigation` handler at `:103-121` is the structural twin |
| Closed `short_circuit_flash/1` private function in LiveView | New private function in `operator_detail_live.ex` | No closed-vocab flash mapper exists in the demo LiveView yet | Use the four-clause shape from `25-RESEARCH.md:543-547` |

## Metadata

**Analog search scope:**
- `lib/parapet/automation/executor.ex` (full)
- `lib/parapet/escalation/worker.ex` (`:1-80`)
- `lib/parapet/automation/claim_service.ex` (`:40-130`)
- `lib/parapet/operator.ex` (`:690-820`)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` (`:100-200`)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` (`:340-410`)
- `test/parapet/automation/executor_concurrency_test.exs` (full, `:1-146`)
- `test/parapet/operator_test.exs` (`:1-60`, `:466-541`)

**Files scanned:** 8 source files + 2 phase docs (CONTEXT.md + RESEARCH.md) = 10 files.

**Pattern extraction date:** 2026-05-28

**Key cross-references for planner:**
- CONTEXT.md `<decisions>` D-01..D-23 — locked choices.
- CONTEXT.md `<canonical_refs>` — every line number cited here verified against live source.
- RESEARCH.md `## Code Examples` (`:416-660`) — five concrete examples covering the central edit, the mapper, the hash function, the 4-arm handler, and the concurrency test skeleton.
- RESEARCH.md `## Common Pitfalls` (`:334-399`) — six pitfalls; Pitfalls 1, 2, 4, 5 are MUST-handle.
- RESEARCH.md `## Assumptions Log` (`:676-686`) — A1 (four arms, not five), A2 (string→atom mapper required), A3 (`claim.id` is UUID string) are MEDIUM-IMPACT corrections to CONTEXT.md.
