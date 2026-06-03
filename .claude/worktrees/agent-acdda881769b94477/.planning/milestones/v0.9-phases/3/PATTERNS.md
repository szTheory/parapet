# Phase 3: Operator UI Performance - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 6
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/operator.ex` | public query API | repo/query -> UI contract | `lib/parapet/operator.ex` | exact |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | generated LiveView | URL params -> operator API -> assigns/stream | `priv/templates/parapet.gen.ui/operator_live.ex.eex` | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | generated components | assigns -> queue/detail rendering | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact |
| `test/parapet/operator_test.exs` | public boundary tests | dummy repo -> query/API assertions | `test/parapet/operator_test.exs` | exact |
| `test/parapet/operator_ui_integration_test.exs` | generator integration tests | template source -> static assertions | `test/parapet/operator_ui_integration_test.exs` | exact |
| `bench/operator_ui_perf.exs` | advisory perf harness | seeded repo -> benchmark output | no close analog in repo | none |

## Pattern Assignments

### `lib/parapet/operator.ex` (public query API)

**Analog:** `lib/parapet/operator.ex`

**Phoenix-free Ecto boundary pattern**:
```elixir
def queue_query do
  from(i in Incident,
    order_by: [
      asc: fragment("case when ? in ('open', 'investigating') then 1 else 2 end", i.state),
      desc: i.updated_at
    ]
  )
end
```

**Evidence repo indirection pattern**:
```elixir
incident = Evidence.repo().get!(Incident, incident_id)

entries =
  Evidence.repo().all(
    from(t in Parapet.Spine.TimelineEntry,
      where: t.incident_id == ^incident_id,
      order_by: [asc: t.inserted_at]
    )
  )
```

Apply this by keeping queue pagination inside `Parapet.Operator` rather than in generated LiveViews, and by expanding the API surface with explicit bounded page helpers instead of leaking repo concerns into templates.

### `priv/templates/parapet.gen.ui/operator_live.ex.eex` (generated LiveView)

**Analog:** `priv/templates/parapet.gen.ui/operator_live.ex.eex`

**Host-owned generator seam pattern**:
```elixir
def mount(_params, _session, socket) do
  incidents = <%= inspect(@repo_module) %>.all(Parapet.Operator.queue_query())
  action_items = <%= inspect(@repo_module) %>.all(Parapet.Operator.action_items_query())

  {:ok, assign(socket, incidents: incidents, action_items: action_items, journeys: journeys, selected_incident: nil)}
end

def handle_params(params, _uri, socket) do
  selected =
    if id = params["id"] do
      Parapet.Operator.incident_detail(id)
    else
      nil
    end
```

Refactor by preserving URL-owned state in `handle_params/3`, but moving queue loading out of `mount/3` and into a bounded page load path that can stream only the current window.

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (queue/detail rendering)

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Bounded queue row renderer pattern**:
```elixir
attr :incidents, :list, required: true
attr :selected, :map, default: nil
def incident_list(assigns) do
  ~H"""
  <div class="divide-y divide-gray-200">
    <%%= for incident <- @incidents do %>
      <.link navigate={"/parapet/#{incident.id}"} class={["block p-4 hover:bg-gray-50", ...]}>
```

Keep the existing component seam, but switch from plain list iteration over a full assign to a stream-aware container and medium-density row contract driven by bounded derived queue facts.

### `test/parapet/operator_test.exs` (public boundary tests)

**Analog:** `test/parapet/operator_test.exs`

**Repo double + query inspection pattern**:
```elixir
def all(query) do
  send(self(), {:repo_all, query})
  ...
end

test "queue_query keeps open and investigating incidents ahead of resolved incidents" do
  query = Operator.queue_query()
  query_str = inspect(query)

  assert %Ecto.Query{} = query
  assert query_str =~ "order_by:"
  assert query_str =~ "updated_at"
end
```

Use the same dummy repo and query inspection approach for pagination helpers, cursor validation, and active-only scope tests before adding heavier integration coverage.

### `test/parapet/operator_ui_integration_test.exs` (generator integration tests)

**Analog:** `test/parapet/operator_ui_integration_test.exs`

**Static template contract testing pattern**:
```elixir
template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
content = File.read!(template_path)

assert content =~ "Parapet.Operator.queue_query"
assert content =~ "Parapet.Operator.incident_detail(id)"
```

Extend this style for stream wiring, `handle_params/3` queue loading, pagination affordances, and the removal of unbounded mount-time queue fetches.

## Shared Patterns

### Generated UI stays host-owned
**Sources:** `docs/operator-ui.md`, `priv/templates/parapet.gen.ui/operator_live.ex.eex`

Plans should keep Parapet exposing Phoenix-free query helpers while the host-generated LiveView owns routing, auth placement, and rendered affordances.

### Evidence-first detail remains richer than the queue
**Sources:** `lib/parapet/operator/workbench_contract.ex`, `priv/templates/parapet.gen.ui/operator_components.ex.eex`

Compact queue rows should reuse derived triage facts, while full impact, chronology, and escalation evidence remain in the detail pane.

### Query semantics belong in public operator APIs
**Sources:** `lib/parapet/operator.ex`, `test/parapet/operator_test.exs`

Add new pagination helpers to `Parapet.Operator` and verify them through public tests rather than hiding keyset logic inside templates or controller-ish modules.

## No Analog Found

| File / Feature | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| `bench/operator_ui_perf.exs` advisory harness | perf benchmark | seeded incidents -> measured output | The repo has no existing benchmark lane, so this should follow standard Mix script conventions from RESEARCH.md rather than mimic a local analog that does not exist. |

## Metadata

**Analog search scope:** `lib/parapet/operator*`, `priv/templates/parapet.gen.ui/*`, `test/parapet/operator*`
**Files scanned:** 8
**Pattern extraction date:** 2026-05-20
