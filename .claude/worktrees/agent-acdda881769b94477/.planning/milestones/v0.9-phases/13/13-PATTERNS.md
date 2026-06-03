# Phase 13: Repair Generated Operator Resolve Flow - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | exact |
| `test/parapet/generated_operator_live_paging_test.exs` | test | request-response | `test/parapet/generated_operator_live_paging_test.exs` | exact |
| `test/parapet/operator_ui_integration_test.exs` | test | request-response | `test/parapet/operator_ui_integration_test.exs` | exact |
| `test/mix/tasks/parapet.gen.ui_test.exs` | test | request-response | `test/mix/tasks/parapet.gen.ui_test.exs` | exact |
| `.planning/v0.9-phases/3/VERIFICATION.md` | config | request-response | `.planning/v0.9-phases/7/VERIFICATION.md` | role-match |
| `.planning/v0.9-phases/7/VERIFICATION.md` | config | request-response | `.planning/v0.9-phases/7/VERIFICATION.md` | exact |
| `.planning/v0.9-phases/3/03-VALIDATION.md` | config | request-response | `.planning/v0.9-phases/7/07-VALIDATION.md` | role-match |
| `.planning/v0.9-phases/7/07-VALIDATION.md` | config | request-response | `.planning/v0.9-phases/7/07-VALIDATION.md` | exact |
| `docs/operator-ui.md` | utility | request-response | `docs/operator-ui.md` | exact |

## Pattern Assignments

### `priv/templates/parapet.gen.ui/operator_live.ex.eex` (component, request-response)

**Analog:** `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`

**Imports and LiveView shell** from `priv/templates/parapet.gen.ui/operator_live.ex.eex` lines 1-8:
```elixir
defmodule <%= inspect(@web_module) %>.Parapet.OperatorLive do
  @moduledoc false
  use <%= inspect(@web_module) %>, :live_view

  import Ecto.Query
  import <%= inspect(@web_module) %>.Parapet.OperatorComponents

  @default_page_size 30
```

**Public operator seam for resolve** from `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` lines 33-47:
```elixir
def handle_event("resolve", %{"id" => id}, socket) do
  incident = <%= inspect(@repo_module) %>.get!(Parapet.Spine.Incident, id)
  payload = %Parapet.Operator.ActionPayload{
    actor: "operator_ui",
    reason: "Resolved via UI",
    correlation_id: Ecto.UUID.generate(),
    action_type: :resolve
  }

  case Parapet.Operator.resolve_incident(incident, payload) do
    {:ok, _result} ->
      {:noreply, push_navigate(socket, to: "/parapet/#{id}")}
    {:error, _reason} ->
      {:noreply, put_flash(socket, :error, "Failed to resolve")}
  end
end
```

**Queue refresh via patch + params reload** from `priv/templates/parapet.gen.ui/operator_live.ex.eex` lines 35-57 and 60-65:
```elixir
def handle_params(params, _uri, socket) do
  queue_params = queue_params(params)
  queue_page = load_queue_page(queue_params)
  ...

  {:noreply,
   socket
   |> assign(
     selected_incident: selected,
     visible_incidents: visible_incidents,
     queue_page: queue_page,
     queue_params: visible_queue_params(queue_params, queue_page),
     queue_refresh_available?: false
   )
   |> stream(:incidents, visible_incidents, reset: true)}
end

def handle_event("queue_refresh", _params, socket) do
  {:noreply,
   socket
   |> assign(:queue_refresh_available?, false)
   |> push_patch(to: queue_path(socket, %{"cursor" => nil, "direction" => "next"}))}
end
```

**Mutation ownership to preserve** from `lib/parapet/operator.ex` lines 342-382:
```elixir
def resolve_incident(%Incident{} = incident, %ActionPayload{} = payload) do
  if valid_payload?(payload) do
    entries =
      Evidence.repo().all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident.id,
          order_by: [asc: t.inserted_at]
        )
      )
    ...
    incident_changeset =
      Ecto.Changeset.change(incident, %{state: "resolved", runbook_data: runbook_data})

    timeline_attrs = %{
      type: "status_change",
      payload: %{"new_state" => "resolved"}
    }

    audit_attrs = build_audit("operator_resolve_incident", payload)

    Evidence.run_operator_command(
      incident_changeset: incident_changeset,
      timeline_attrs: timeline_attrs,
      audit_attrs: audit_attrs
    )
  else
    {:error, :invalid_payload}
  end
end
```

**Anti-pattern to remove** from `priv/templates/parapet.gen.ui/operator_live.ex.eex` lines 89-105:
```elixir
case Parapet.Operator.record_note(incident, "Resolved", payload) do
  {:ok, _result} ->
    {:noreply, push_patch(socket, to: queue_path(socket, %{"id" => id}))}

  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Failed to resolve")}
end
```

---

### `test/parapet/generated_operator_live_paging_test.exs` (test, request-response)

**Analog:** `test/parapet/generated_operator_live_paging_test.exs`

**Generated-source compile harness** from lines 142-165:
```elixir
setup_all do
  start_supervised!(Test.Repo)

  igniter =
    test_project(app_name: :test)
    |> Ui.igniter()

  operator_components_source =
    Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
    |> Rewrite.Source.get(:content)

  operator_live_source =
    Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_live.ex")
    |> Rewrite.Source.get(:content)

  Code.compile_string(operator_components_source)
  [{live_module, _bytecode}] = Code.compile_string(operator_live_source)

  Application.put_env(:parapet, :repo, Test.Repo)
  ...
end
```

**Runtime interaction pattern** from lines 177-209:
```elixir
socket = configured_socket(live_module, URI.parse("http://example.com/parapet"))

{:ok, socket} = live_module.mount(%{}, %{}, socket)
{:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
html = render_live(live_module, socket)

assert html =~ "Active incident 1"
assert html =~ "Active incident 30"
refute html =~ "Active incident 31"
refute html =~ "Resolved incident 61"
```

**Fake repo read path to extend** from lines 23-73:
```elixir
defmodule Test.Repo do
  use Agent

  alias Parapet.Spine.{ActionItem, Incident, TimelineEntry}

  def start_link(_opts) do
    Agent.start_link(fn -> %{incidents: [], entries: %{}, action_items: []} end, name: __MODULE__)
  end

  def seed!(attrs) do
    Agent.update(__MODULE__, fn _state ->
      %{
        incidents: Map.fetch!(attrs, :incidents),
        entries: Map.get(attrs, :entries, %{}),
        action_items: Map.get(attrs, :action_items, [])
      }
    end)
  end

  def get!(Incident, incident_id) do
    Agent.get(__MODULE__, fn state ->
      Enum.find(state.incidents, &(&1.id == incident_id)) ||
        raise "missing incident #{incident_id}"
    end)
  end
end
```

**Transactional fake repo pattern to borrow** from `test/parapet/evidence_test.exs` lines 26-84:
```elixir
def transaction(%Ecto.Multi{} = multi) do
  ops = Ecto.Multi.to_list(multi)

  try do
    results =
      Enum.reduce(ops, %{}, fn op, acc ->
        case op do
          {name, {:update, changeset, _opts}} when not is_function(changeset) ->
            if changeset.valid? do
              struct = Ecto.Changeset.apply_changes(changeset)
              send(self(), {:dummy_repo_update, struct.__struct__})
              Map.put(acc, name, struct)
            else
              throw({:rollback, name, changeset, acc})
            end

          {name, {:run, fun}} ->
            case fun.(__MODULE__, acc) do
              {:ok, result} -> Map.put(acc, name, result)
              {:error, reason} -> throw({:rollback, name, reason, acc})
            end
        end
      end)

    {:ok, results}
  catch
    {:rollback, name, error_val, results} ->
      {:error, name, error_val, results}
  end
end
```

**Planner note:** keep the new resolve assertion in this file unless implementation forces a nearby generated-runtime test; this is the existing quick lane.

---

### `test/parapet/operator_ui_integration_test.exs` (test, request-response)

**Analog:** `test/parapet/operator_ui_integration_test.exs`

**Template source-contract style** from lines 11-21:
```elixir
describe "UI generator integration" do
  test "generated UI templates align with bounded Parapet.Operator queue actions" do
    template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
    content = File.read!(template_path)

    assert content =~ "Parapet.Operator.list_incident_queue"
    assert content =~ "Parapet.Operator.incident_detail(id)"
    refute content =~ "Repo.all(Parapet.Operator.queue_query())"
    assert content =~ "def handle_params"
    assert content =~ "stream("
  end
```

**Multi-file concatenation pattern** from lines 50-60:
```elixir
live_content = File.read!("priv/templates/parapet.gen.ui/operator_live.ex.eex")
components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")
content = live_content <> "\n" <> components_content

assert content =~ "New incidents or queue changes are available."
assert content =~ "Load latest changes"
assert content =~ "History"
assert content =~ "Previous"
assert content =~ "Next"
```

**Pattern to add here:** assert queue `"resolve"` uses `Parapet.Operator.resolve_incident` and does not use `record_note/3`.

---

### `test/mix/tasks/parapet.gen.ui_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/parapet.gen.ui_test.exs`

**Generator-output contract style** from lines 8-18 and 27-43:
```elixir
test "creates LiveView files under lib/<host>_web/live/parapet/" do
  igniter =
    test_project(app_name: :test)
    |> Ui.igniter()

  files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
  ...

  operator_live_source =
    Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_live.ex")
    |> Rewrite.Source.get(:content)

  assert operator_live_source =~ "Parapet.Operator.list_incident_queue"
  refute operator_live_source =~ "Test.Repo.all(Parapet.Operator.queue_query())"
  assert operator_live_source =~ "Parapet.Operator.incident_detail(id)"
  assert operator_live_source =~ "handle_event(\"acknowledge\""
  assert operator_live_source =~ "handle_event(\"resolve\""
```

**Pattern to add here:** generated output string assertion for `Parapet.Operator.resolve_incident(` on queue resolve, plus a negative assertion against `record_note(` in that branch.

---

### `.planning/v0.9-phases/3/VERIFICATION.md` (config, request-response)

**Analog:** `.planning/v0.9-phases/7/VERIFICATION.md`

**Verification report shell** from `.planning/v0.9-phases/7/VERIFICATION.md` lines 1-15:
```markdown
---
phase: 07-close-operator-ui-performance-proof
verified: 2026-05-23T09:17:53Z
status: verified
score: 4/4 truths verified
human_verification: []
---

# Phase 7: Close Operator UI Performance Proof Verification Report

**Phase Goal:** Close the missing phase-local verification surface ...
**Verified:** 2026-05-23T09:17:53Z
**Status:** verified
**Re-verification:** Yes - this phase verifies the Phase 7 closure chain itself ...
```

**Observable truths table pattern** from `.planning/v0.9-phases/3/VERIFICATION.md` lines 20-25:
```markdown
| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `Parapet.Operator.list_incident_queue/1` is the bounded public queue seam and emits low-cardinality queue-page telemetry. | ✓ VERIFIED | `lib/parapet/operator.ex` bounds page size ... |
| 2 | The generated LiveView path renders only the current page and preserves explicit paging/history/refresh semantics instead of loading the full queue. | ✓ VERIFIED | `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_integration_test.exs`, and `test/mix/tasks/parapet.gen.ui_test.exs` prove bounded current-page rendering and the generated queue affordances. |
```

**Behavioral spot-check table pattern** from `.planning/v0.9-phases/3/VERIFICATION.md` lines 30-35:
```markdown
| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Queue seam and telemetry proof | `mix test test/parapet/operator/queue_pagination_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Generated runtime bounded-page proof | `mix test test/parapet/generated_operator_live_paging_test.exs` | 1 test, 0 failures | ✓ PASS |
| Generated source-contract and integration proof | `mix test test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | 12 tests, 0 failures | ✓ PASS |
```

**Pattern to apply:** keep this file as the canonical runtime-proof surface, but update its truths and commands so queue-side resolve is explicitly part of the proof rather than implied by bounded paging alone.

---

### `.planning/v0.9-phases/7/VERIFICATION.md` (config, request-response)

**Analog:** `.planning/v0.9-phases/7/VERIFICATION.md`

**Proof-hierarchy wording** from lines 22-25:
```markdown
| 1 | Phase 7 already created the canonical runtime-proof artifact for the underlying operator UI performance work. | ✓ VERIFIED | `.planning/v0.9-phases/3/VERIFICATION.md` remains the canonical Phase 3 verification report, and this Phase 7 report cites it explicitly as the underlying proof rather than duplicating its runtime claims. |
| 2 | Phase 7 also reconciled the direct validation and traceability surfaces that depend on that proof. | ✓ VERIFIED | `.planning/v0.9-phases/7/07-VALIDATION.md` defines the closure sampling contract, `.planning/v0.9-phases/3/03-VALIDATION.md` points back to the canonical Phase 3 verification artifact ... |
| 4 | Phase 7 now has its own canonical phase-local verification surface without implying a fresh milestone audit rerun already passed. | ✓ VERIFIED | `.planning/v0.9-phases/7/VERIFICATION.md` now exists as the closure-grade proof index for Phase 7, and its wording keeps the fresh milestone audit rerun as separate work. |
```

**Audit-boundary wording** from lines 53-59:
```markdown
### Human Verification Required

None. The missing work in this scope was the absence of a Phase 7-local verification artifact, and that closure surface is now satisfied by exact file assertions and proof-link checks.

### Gaps Summary

The missing Phase 7 phase-local verification blocker is closed ...
A fresh milestone audit rerun remains separate work and is not implied by this backfilled closure artifact.
```

**Pattern to apply:** narrow reconciliation only. This file should index the repaired Phase 3 runtime proof and keep the “fresh milestone audit rerun remains separate work” boundary explicit.

---

### `.planning/v0.9-phases/3/03-VALIDATION.md` (config, request-response)

**Analog:** `.planning/v0.9-phases/7/07-VALIDATION.md`

**Quick-run command + canonical artifact pattern** from `.planning/v0.9-phases/3/03-VALIDATION.md` lines 16-32:
```markdown
## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |

## Canonical Verification Artifact

- `.planning/v0.9-phases/3/VERIFICATION.md` is now the closure-grade proof artifact for this phase.
- This validation contract remains the sampling map ...
```

**Per-task map pattern** from lines 44-52:
```markdown
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-02-01 | 02 | 2 | SCALE-01.c | T-03-04 / T-03-05 / T-03-06 | Generated LiveView loads only one page, validates params, and streams bounded rows without silent reordering | generator integration | `mix test test/parapet/generated_operator_live_paging_test.exs` and `mix test test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | ✅ | ✅ green |
```

**Pattern to apply:** expand the existing quick lane entry rather than adding a new harness. The validation row should name the queue resolve lifecycle proof directly.

---

### `.planning/v0.9-phases/7/07-VALIDATION.md` (config, request-response)

**Analog:** `.planning/v0.9-phases/7/07-VALIDATION.md`

**Closure-phase sampling pattern** from lines 12-34:
```markdown
## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix benchmark lane |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 07-01-01 | 01 | 1 | `SCALE-01.c` | unit/integration | `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | planned |
| 07-02-01 | 02 | 2 | `SCALE-01.c`, `AC-03` | doc reconciliation | `rg -n "VERIFICATION.md|Verified|Phase 7|SCALE-01.c|AC-03" ...` | planned |
```

**Manual proof-honesty check pattern** from lines 36-40:
```markdown
| Benchmark wording stays honest and does not imply a universal latency guarantee | `AC-03` | This is a documentation and proof-honesty judgment, not a pure unit-test concern | Review `.planning/v0.9-phases/3/VERIFICATION.md` and `docs/operator-ui.md` together; confirm they describe the lane as reproducible and advisory rather than a hard SLA |
```

**Pattern to apply:** keep Phase 7 as an index and reconciliation map. Do not restate Phase 13 runtime claims here as if Phase 7 reran them independently.

---

### `docs/operator-ui.md` (utility, request-response)

**Analog:** `docs/operator-ui.md`

**Proof-lane narrative style** from lines 87-118:
```markdown
## Phase 3 Performance Proof Lane

Phase 3 keeps the generated incident queue bounded and operator-paced under large-installation load.

- The default queue remains active-only (`open` and `investigating`).
- Queue refresh is explicit.
- Performance proof is layered: bounded queue telemetry in `Parapet.Operator`, deterministic queue tests, and an opt-in advisory benchmark lane.

### Advisory 50k+ Benchmark
...
- Verifies the rendered first page still shows `30` active rows, excludes resolved incidents, and reports that additional pages remain.
...
This lane is intentionally advisory. It is for reproducible operator-UI proof at scale, not a default CI blocker.
```

**Operator API boundary wording** from lines 146-153:
```markdown
- `Trigger Next Escalation` records operator intent through the public `Parapet.Operator` API.
- `Suppress Pending Escalation` records a durable, expiring suppression window through the same audited seam.
- Escalation controls should only be offered while the incident is still open; investigating and resolved incidents remain read-oriented.
- Generated LiveView code should refresh `Parapet.Operator.incident_detail/1` after those actions rather than maintain its own escalation state machine.
```

**Pattern to apply:** any wording update should stay evidence-first and host-owned. If this file is touched, describe resolve as a durable lifecycle action backed by `Parapet.Operator`, not a UI-local shortcut.

## Shared Patterns

### Operator Mutation Seam
**Source:** `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` lines 13-47 and `lib/parapet/operator.ex` lines 317-382  
**Apply to:** `priv/templates/parapet.gen.ui/operator_live.ex.eex`, runtime tests, source-contract tests
```elixir
payload = %Parapet.Operator.ActionPayload{
  actor: "operator_ui",
  reason: "Resolved via UI",
  correlation_id: Ecto.UUID.generate(),
  action_type: :resolve
}

case Parapet.Operator.resolve_incident(incident, payload) do
  {:ok, _result} -> ...
  {:error, _reason} -> ...
end
```

### Queue Refresh Through Same-LiveView Patch
**Source:** `priv/templates/parapet.gen.ui/operator_live.ex.eex` lines 35-65  
**Apply to:** queue-side resolve flow and generated runtime proof
```elixir
{:noreply, push_patch(socket, to: queue_path(socket, %{"id" => id}))}
```

### Transactional Lifecycle Ownership
**Source:** `lib/parapet/evidence.ex` lines 107-148 and `test/parapet/evidence_test.exs` lines 26-84  
**Apply to:** fake repo extension inside `test/parapet/generated_operator_live_paging_test.exs`
```elixir
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.update(:incident, incident_changeset)
  |> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} -> ... end)

repo().transaction(multi)
```

### Verification Artifact Shell
**Source:** `.planning/v0.9-phases/3/VERIFICATION.md` lines 1-59 and `.planning/v0.9-phases/7/VERIFICATION.md` lines 1-59  
**Apply to:** Phase 3 and Phase 7 proof-surface reconciliation
```markdown
## Goal Achievement
### Observable Truths
### Behavioral Spot-Checks
### Plan Output Check
### Requirements Coverage
### Human Verification Required
### Gaps Summary
```

### Validation Map Shell
**Source:** `.planning/v0.9-phases/3/03-VALIDATION.md` lines 16-83 and `.planning/v0.9-phases/7/07-VALIDATION.md` lines 12-49  
**Apply to:** Phase 3 and Phase 7 validation updates
```markdown
## Test Infrastructure
## Canonical Verification Artifact
## Sampling Rate
## Per-Task Verification Map
## Manual-Only Verifications
## Validation Sign-Off
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `priv/templates/parapet.gen.ui/`, `lib/parapet/`, `test/parapet/`, `test/mix/tasks/`, `.planning/v0.9-phases/3/`, `.planning/v0.9-phases/7/`, `docs/`  
**Files scanned:** 12  
**Pattern extraction date:** 2026-05-23
