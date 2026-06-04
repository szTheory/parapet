# Phase 38: Scoped UI Routes - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 18
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_live.ex.eex` | exact |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact |
| `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | config | request-response | `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | exact |
| `lib/mix/tasks/parapet.gen.ui.ex` | config | file-I/O | `lib/mix/tasks/parapet.gen.ui.ex` | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` | component | request-response | `priv/templates/parapet.gen.ui/operator_live.ex.eex` | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` | component | request-response | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | component | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact |
| `examples/demo_app/lib/demo_app_web/router.ex` | route | request-response | `examples/demo_app/lib/demo_app_web/router.ex` | exact |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | test | request-response | `examples/demo_app/test/demo_app/operator_smoke_test.exs` | exact |
| `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` | test | batch | `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` | exact |
| `test/mix/tasks/parapet.gen.ui_test.exs` | test | file-I/O | `test/mix/tasks/parapet.gen.ui_test.exs` | exact |
| `test/mix/tasks/parapet.gen.ui_shift_left_test.exs` | test | transform | `test/mix/tasks/parapet.gen.ui_shift_left_test.exs` | exact |
| `test/parapet/operator_ui_compile_out_test.exs` | test | transform | `test/parapet/operator_ui_compile_out_test.exs` | exact |
| `test/parapet/operator_ui_integration_test.exs` | test | transform | `test/parapet/operator_ui_integration_test.exs` | exact |
| `test/parapet/operator_ui_demo_contract_test.exs` | test | request-response | `test/parapet/operator_ui_demo_contract_test.exs` | exact |
| `test/parapet/generated_operator_live_paging_test.exs` | test | request-response | `test/parapet/generated_operator_live_paging_test.exs` | exact |
| `docs/operator-ui.md` | utility | transform | `docs/operator-ui.md` | exact |

## Pattern Assignments

### `priv/templates/parapet.gen.ui/operator_live.ex.eex` (component, request-response)

**Analog:** `priv/templates/parapet.gen.ui/operator_live.ex.eex`

**Imports and host-owned LiveView pattern** (lines 1-8):
```elixir
defmodule <%= inspect(@web_module) %>.Parapet.OperatorLive do
  @moduledoc false
  use <%= inspect(@web_module) %>, :live_view

  import Ecto.Query
  import <%= inspect(@web_module) %>.Parapet.OperatorComponents

  @default_page_size 30
```

**State derivation pattern** (lines 36-55):
```elixir
def handle_params(params, _uri, socket) do
  page_mode = page_mode(socket.assigns.live_action)
  queue_params = queue_params(params, page_mode)
  queue_page = load_queue_page(queue_params)

  visible_incidents = Enum.map(queue_page.items, &queue_stream_item/1)
  {selected, selection_source} = selected_incident(params, page_mode, visible_incidents)

  {:noreply,
   socket
   |> assign(
     selected_incident: selected,
     selection_source: selection_source,
     visible_incidents: visible_incidents,
     queue_page: queue_page,
     queue_params: visible_queue_params(queue_params, queue_page),
     page_mode: page_mode,
     queue_refresh_available?: false
   )
   |> stream(:incidents, visible_incidents, reset: true)}
end
```

**LiveView event route pattern** (lines 58-83):
```elixir
def handle_event("queue_refresh", _params, socket) do
  {:noreply,
   socket
   |> assign(:queue_refresh_available?, false)
   |> push_patch(to: queue_path(socket, %{"cursor" => nil, "direction" => "next"}))}
end

def handle_event("acknowledge", %{"id" => id}, socket) do
  incident = <%= inspect(@repo_module) %>.get!(Parapet.Spine.Incident, id)

  payload = %Parapet.Operator.ActionPayload{
    actor: "operator_ui",
    reason: "Acknowledged via UI",
    correlation_id: Ecto.UUID.generate(),
    action_type: :acknowledge
  }

  case Parapet.Operator.acknowledge_incident(incident, payload) do
    {:ok, _result} ->
      {:noreply,
       socket
       |> put_flash(:info, "Incident acknowledged successfully")
       |> push_patch(to: queue_path(socket, %{"id" => id}))}
```

**Route-producing render surfaces** (lines 154-168 and 223-248):
```elixir
<.link navigate="/parapet" class="flex min-h-[40px] items-center justify-center rounded-lg bg-stone-950 px-4 py-2 text-sm font-semibold text-white transition-transform duration-100 ease-out active:scale-[0.96] hover:bg-stone-800">
  Return to Response
</.link>

<.link
  patch={queue_page_path(@queue_params, @queue_page.previous_cursor, "previous")}
```

```elixir
<.link
  patch={history_path()}
  class="text-sm font-medium text-stone-700 underline decoration-stone-300 underline-offset-4 hover:text-stone-900"
>
  History
</.link>

<.link
  patch={queue_page_path(@queue_params, @queue_page.next_cursor, "next")}
```

**Route helper pattern to extend with base path** (lines 403-428):
```elixir
defp queue_page_path(queue_params, nil, _direction), do: queue_path(queue_params, %{})

defp queue_page_path(queue_params, cursor, direction) do
  queue_path(queue_params, %{"cursor" => cursor, "direction" => direction, "id" => nil})
end

defp queue_path(%{assigns: assigns}, extra_params) do
  queue_path(assigns.queue_params, extra_params)
end

defp queue_path(queue_params, extra_params) do
  params =
    queue_params
    |> Map.merge(extra_params)
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == "active" end)

  case params do
    [] -> queue_base_path(queue_params)
    _ -> queue_base_path(queue_params) <> "?" <> URI.encode_query(params)
  end
end

defp queue_base_path(%{"status" => "resolved"}), do: "/parapet/history"
defp queue_base_path(_queue_params), do: "/parapet"

defp history_path, do: "/parapet/history"
```

**Implementation note:** Add the generated base-path seam here by accepting `_uri` in `handle_params/3`, assigning `:operator_base_path`, passing it to components, and threading it through `queue_path`, `queue_base_path`, and `history_path`. Preserve the existing event, flash, and queue pagination shape.

---

### `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` (component, request-response)

**Analog:** `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`

**Imports and mount pattern** (lines 1-10):
```elixir
defmodule <%= inspect(@web_module) %>.Parapet.OperatorDetailLive do
  @moduledoc false
  use <%= inspect(@web_module) %>, :live_view

  import <%= inspect(@web_module) %>.Parapet.OperatorComponents

  def mount(%{"id" => id}, _session, socket) do
    selected = Parapet.Operator.incident_detail(id)

    {:ok, assign(socket, incident: selected)}
```

**Action route pattern** (lines 23-31 and 45-50):
```elixir
case Parapet.Operator.acknowledge_incident(incident, payload) do
  {:ok, _result} ->
    {:noreply,
     socket
     |> put_flash(:info, "Incident acknowledged successfully")
     |> push_navigate(to: "/parapet/incidents/#{id}")}

  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Failed to acknowledge")}
end
```

```elixir
case Parapet.Operator.resolve_incident(incident, payload) do
  {:ok, _result} ->
    {:noreply, push_navigate(socket, to: "/parapet/incidents/#{id}")}

  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Failed to resolve")}
end
```

**Back-link and nav pattern** (lines 194-204):
```elixir
def render(assigns) do
  ~H"""
  <.operator_theme_bootstrap />
  <div class="parapet-ui antialiased flex min-h-screen w-full max-w-full flex-col overflow-x-hidden bg-stone-100 text-stone-900">
    <.operator_nav active={detail_nav_active(@incident)} />

    <div class="border-b border-stone-200 bg-white px-4 py-3 md:px-6">
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <.link navigate={detail_back_path(@incident)} class="inline-flex min-h-[40px] items-center rounded-lg text-sm font-semibold text-teal-800 underline decoration-teal-200 underline-offset-4 hover:text-teal-950">
```

**Back-path helper pattern** (lines 243-250):
```elixir
defp detail_nav_active(%{incident: %{state: "resolved"}}), do: :history
defp detail_nav_active(_incident), do: :response

defp detail_back_path(%{incident: %{state: "resolved"}}), do: "/parapet/history"
defp detail_back_path(_incident), do: "/parapet"

defp detail_back_label(%{incident: %{state: "resolved"}}), do: "Back to history"
defp detail_back_label(_incident), do: "Back to active response"
```

**Implementation note:** Match the list LiveView by deriving or assigning `:operator_base_path` and using helper functions for detail refresh navigation and back links. Keep `push_navigate` for detail routes because this crosses LiveView modules.

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (component, request-response)

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Imports and component module pattern** (lines 1-5):
```elixir
defmodule <%= inspect(@web_module) %>.Parapet.OperatorComponents do
  @moduledoc false
  use <%= inspect(@web_module) %>, :html

  def operator_theme_bootstrap(assigns) do
```

**Component attr/nav pattern** (lines 361-374):
```elixir
attr(:active, :atom, required: true)

def operator_nav(assigns) do
  ~H"""
  <header class="po-operator-header border-b">
    <div class="flex flex-col gap-3 px-4 py-3 md:flex-row md:items-center md:justify-between md:px-6">
      <div>
        <p class="po-operator-brand text-xs font-semibold uppercase tracking-[0.18em]">Parapet Operator</p>
        <h1 class="po-operator-title mt-1 text-lg font-semibold">Active response workbench</h1>
      </div>
      <nav aria-label="Parapet operator sections" class="flex flex-wrap gap-2">
        <.nav_item href="/parapet" active={@active == :response}>Respond</.nav_item>
        <.nav_item href="/parapet/actions" active={@active == :actions}>Actions</.nav_item>
        <.nav_item href="/parapet/history" active={@active == :history}>History</.nav_item>
```

**Action and incident-link surfaces** (lines 545-587):
```elixir
<.link navigate="/parapet" class="flex min-h-[40px] items-center justify-center rounded-lg bg-stone-950 px-4 py-2 text-sm font-semibold text-white transition-transform duration-100 ease-out active:scale-[0.96] hover:bg-stone-800">
  Return to response
</.link>
```

```elixir
<%%= if @page_mode == :history do %>
  <.link
    navigate={incident_detail_path(incident)}
    aria-current="false"
    data-incident-id={incident.id}
```

```elixir
<.link
  patch={queue_item_path(@queue_params, incident)}
  aria-current={if @selected && @selected.id == incident.id, do: "true", else: "false"}
```

**Plain anchor surface** (lines 1058-1067):
```elixir
<%%= if @detail.incident.state == "resolved" do %>
  <section class={surface_class(:action_card)} aria-label="Resolved incident status">
    <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500">Review mode</p>
    <h3 class="mt-1 text-lg font-semibold text-stone-950">Resolved incident</h3>
    <p class="mt-2 text-sm leading-6 text-stone-600">
      This incident is closed. History keeps the final timeline, retrospective, and audit evidence together for review.
    </p>
    <a href="/parapet/history" class="mt-4 flex min-h-[40px] items-center justify-center rounded-lg bg-stone-950 px-4 py-2 text-sm font-semibold text-white transition-transform duration-100 ease-out active:scale-[0.96] hover:bg-stone-800">
```

**Component route helper pattern** (lines 1248-1257):
```elixir
|> Map.merge(%{"id" => incident.id})
|> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == "active" end)

case params do
  [] -> "/parapet"
  _ -> "/parapet?" <> URI.encode_query(params)
end
end

defp incident_detail_path(incident), do: "/parapet/incidents/#{incident.id}"
```

**Implementation note:** Add `attr(:operator_base_path, :string, default: "/parapet")` to route-producing components and route all `href`, `navigate`, and `patch` values through helpers that accept the base path. External links must stay unchanged.

---

### Demo generated-copy files (component, request-response)

**Files:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`, `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`, `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`

**Analogs:** matching templates in `priv/templates/parapet.gen.ui/`

**Drift contract source** (from `test/parapet/operator_ui_integration_test.exs` lines 194-225):
```elixir
test "demo copied LiveViews stay aligned with generated IA contract" do
  live_content =
    File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex")

  detail_content =
    File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex")

  components_content =
    File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex")

  assert live_content =~ "response_cockpit"
  assert live_content =~ "Next Safe Actions"
  refute live_content =~ "Back to Queue"
  assert detail_content =~ ~S|push_navigate(to: "/parapet/incidents/#{id}")|
  assert detail_content =~ ~S|push_navigate(socket, to: "/parapet/incidents/#{id}")|
  assert components_content =~ "surface_class(:action_card)"
  assert components_content =~ "control_class(:recovery"
  assert components_content =~ "chip_class(:state"
  assert components_content =~ "operator_theme_bootstrap"
  assert components_content =~ "parapet.operator.theme"
  assert live_content =~ "selection_source"
  assert live_content =~ "response_cockpit"
  assert live_content =~ "Next Safe Actions"
  assert components_content =~ "po-operator-header"
  assert components_content =~ "po-theme-control"
  assert components_content =~ "po-chip-warning"
  assert components_content =~ "po-link"
  assert components_content =~ "navigate={incident_detail_path(incident)}"
  assert live_content =~ "Resolved archive"
  assert detail_content =~ "Back to history"
  assert detail_content =~ "Resolved incident review"
  assert detail_content =~ "retrospective_card"
```

**Implementation note:** Apply the same route-base changes to the demo copies as to the templates, or strengthen this contract to compare route-helper/base-path strings across both surfaces. Phase 38 treats template/demo drift as failure.

---

### `priv/templates/parapet.gen.ui/router_snippet.ex.eex` and `lib/mix/tasks/parapet.gen.ui.ex` (config, request-response/file-I/O)

**Analogs:** `priv/templates/parapet.gen.ui/router_snippet.ex.eex`, `lib/mix/tasks/parapet.gen.ui.ex`

**Auth-owned router guidance pattern** (router snippet lines 1-18):
```elixir
# Ensure you place these routes inside an existing authenticated scope,
# or define a new pipeline with your app's standard authentication plugs.
# Parapet does not provide its own auth.
#
# Example:
# scope "/admin", <%= inspect(@web_module) %> do
#   pipe_through [:browser, :require_authenticated_user]
#
#   live_session :parapet_operator,
#     on_mount: [{<%= inspect(@web_module) %>.UserAuth, :ensure_authenticated}] do
#
#     live "/parapet", <%= inspect(@web_module) %>.Parapet.OperatorLive, :index
#     live "/parapet/actions", <%= inspect(@web_module) %>.Parapet.OperatorLive, :actions
#     live "/parapet/history", <%= inspect(@web_module) %>.Parapet.OperatorLive, :history
#     live "/parapet/incidents/:id", <%= inspect(@web_module) %>.Parapet.OperatorDetailLive, :show
#     live "/parapet/:id", <%= inspect(@web_module) %>.Parapet.OperatorDetailLive, :show
#   end
# end
```

**Generator template-copy pattern** (generator lines 17-67):
```elixir
def igniter(igniter) do
  web_module = Igniter.Libs.Phoenix.web_module(igniter)
  app_name = Igniter.Project.Application.app_name(igniter)

  # E.g. web_module is MyAppWeb, we want MyApp.Repo
  base_name = web_module |> inspect() |> String.trim_trailing("Web")
  repo_module = Module.concat([base_name, "Repo"])

  web_dir = Path.join(["lib", "#{app_name}_web", "live", "parapet"])

  assigns = [
    web_module: web_module,
    app_name: app_name,
    repo_module: repo_module
  ]

  igniter
  |> Igniter.copy_template(
    Path.join([
      :code.priv_dir(:parapet),
      "templates",
      "parapet.gen.ui",
      "operator_live.ex.eex"
    ]),
    Path.join([web_dir, "operator_live.ex"]),
    assigns,
    on_exists: :skip
  )
```

**Fallback router guidance pattern** (generator lines 79-108):
```elixir
guidance =
  if File.exists?(template_path) do
    EEx.eval_file(template_path, assigns: assigns)
  else
    # Fallback for testing when priv/ isn't compiled yet or when running tests
    """
    # Ensure you place these routes inside an existing authenticated scope,
    # or define a new pipeline with your app's standard authentication plugs.
    # Parapet does not provide its own auth.
```

**Implementation note:** Keep router ownership with the host and keep default generated routes mounted at `/parapet`. If guidance mentions nested scopes, do it as host-owned examples such as `scope "/ops"` plus the existing `live "/parapet"` routes, yielding `/ops/parapet` without a Parapet router module.

---

### `examples/demo_app/lib/demo_app_web/router.ex` (route, request-response)

**Analog:** `examples/demo_app/lib/demo_app_web/router.ex`

**Demo route pattern** (lines 13-25):
```elixir
# WARNING: demo only — do not copy to production.
# Parapet does not provide its own auth.
# Production deployments must protect these routes with an authenticated scope.
scope "/" do
  pipe_through(:browser)

  live_session :parapet_operator do
    live("/parapet", DemoAppWeb.Parapet.OperatorLive, :index)
    live("/parapet/actions", DemoAppWeb.Parapet.OperatorLive, :actions)
    live("/parapet/history", DemoAppWeb.Parapet.OperatorLive, :history)
    live("/parapet/incidents/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
    live("/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
  end
end
```

**Implementation note:** Add a scoped proof route shape without taking auth ownership. If adding `/ops/parapet`, prefer a nested host-owned `scope "/ops"` around the same route set.

---

### `test/mix/tasks/parapet.gen.ui_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/parapet.gen.ui_test.exs`

**Generated-file assertion pattern** (lines 8-35):
```elixir
test "creates LiveView files under lib/<host>_web/live/parapet/" do
  igniter =
    test_project(app_name: :test)
    |> Ui.igniter()

  files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

  assert Enum.any?(files, &String.contains?(&1, "lib/test_web/live/parapet/operator_live.ex"))

  assert Enum.any?(
           files,
           &String.contains?(&1, "lib/test_web/live/parapet/operator_detail_live.ex")
         )
```

**Generated-source route contract pattern** (lines 62-70 and 113-118):
```elixir
operator_components_source =
  Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
  |> Rewrite.Source.get(:content)

assert operator_components_source =~ "data-incident-id"
assert operator_components_source =~ "navigate={incident_detail_path(incident)}"

assert operator_components_source =~
         ~S|defp incident_detail_path(incident), do: "/parapet/incidents/#{incident.id}"|
```

```elixir
operator_detail_source =
  Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_detail_live.ex")
  |> Rewrite.Source.get(:content)

assert operator_detail_source =~ ~S|push_navigate(to: "/parapet/incidents/#{id}")|
assert operator_detail_source =~ ~S|push_navigate(socket, to: "/parapet/incidents/#{id}")|
```

**Router notice contract pattern** (lines 132-155):
```elixir
test "emits authenticated-scope router guidance" do
  igniter =
    test_project(app_name: :test)
    |> Ui.igniter()

  assert Enum.any?(
           igniter.notices,
           &String.contains?(
             &1,
             "Ensure you place these routes inside an existing authenticated scope"
           )
         )

  assert Enum.any?(
           igniter.notices,
           &String.contains?(&1, "Parapet does not provide its own auth")
         )

  assert Enum.any?(igniter.notices, &String.contains?(&1, "live_session :parapet_operator"))
  assert Enum.any?(igniter.notices, &String.contains?(&1, "live \"/parapet\""))
```

**Implementation note:** Extend existing generated source assertions to pin `operator_base_path` helper/defaults and scoped route helpers. Keep using `Igniter.Test`, `Rewrite.source!`, and string assertions.

---

### `test/mix/tasks/parapet.gen.ui_shift_left_test.exs` (test, transform)

**Analog:** `test/mix/tasks/parapet.gen.ui_shift_left_test.exs`

**Ordering/shift-left pattern** (lines 7-38):
```elixir
defp index_of(content, needle) do
  case :binary.match(content, needle) do
    {index, _length} -> index
    :nomatch -> nil
  end
end

describe "mix parapet.gen.ui shift-left verification" do
  test "generated operator detail keeps escalation summary ahead of the canonical timeline" do
    igniter =
      test_project(app_name: :test)
      |> Ui.igniter()

    components_source =
      Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
      |> Rewrite.Source.get(:content)

    detail_live_source =
      Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_detail_live.ex")
      |> Rewrite.Source.get(:content)
```

**Implementation note:** Reuse this pattern if asserting helper definitions appear before route-producing HEEx, or if route attributes are present before use in generated components.

---

### `test/parapet/operator_ui_integration_test.exs` (test, transform)

**Analog:** `test/parapet/operator_ui_integration_test.exs`

**Template integration string contract** (lines 12-23):
```elixir
test "generated UI templates align with bounded Parapet.Operator queue actions" do
  template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
  content = File.read!(template_path)

  assert content =~ "Parapet.Operator.list_incident_queue"
  assert content =~ "Parapet.Operator.incident_detail(id)"
  assert content =~ "handle_event(\"resolve\""
  assert content =~ "Parapet.Operator.resolve_incident(incident, payload)"
  refute content =~ "Parapet.Operator.record_note(incident, \"Resolved\", payload)"
  refute content =~ "Repo.all(Parapet.Operator.queue_query())"
  assert content =~ "def handle_params"
  assert content =~ "stream("
end
```

**Router guidance route contract** (lines 60-80):
```elixir
test "generated router guidance pins the active-response route map" do
  router_content = File.read!("priv/templates/parapet.gen.ui/router_snippet.ex.eex")
  task_content = File.read!("lib/mix/tasks/parapet.gen.ui.ex")
  components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

  for route <- [
        ~S|live "/parapet"|,
        ~S|live "/parapet/actions"|,
        ~S|live "/parapet/history"|,
        ~S|live "/parapet/incidents/:id"|,
        ~S|live "/parapet/:id"|
      ] do
    assert router_content =~ route
  end

  assert task_content =~ ~S|live "/parapet/incidents/:id"|
  assert task_content =~ ~S|live "/parapet/:id"|
  assert components_content =~ "Respond"
  assert components_content =~ "Actions"
  assert components_content =~ "History"
  assert components_content =~ ~S|aria-current={if @active, do: "page", else: nil}|
end
```

**Generator-first host-owned guard** (lines 266-274):
```elixir
test "UI stays generator-first and host-owned" do
  # Parapet must not define its own Plug.Router or Phoenix.Router for the UI.
  # Let's verify no router modules exist in Parapet core.
  core_files = Path.wildcard("lib/parapet/**/*.ex")

  for file <- core_files do
    content = File.read!(file)
    refute content =~ "use Phoenix.Router", "Found Phoenix.Router in core file: #{file}"
    refute content =~ "use Plug.Router", "Found Plug.Router in core file: #{file}"
```

**Implementation note:** Add scoped route string contracts here for templates and demo copy drift. Also invert current literal-path assertions where needed so helpers are required and stray literal `/parapet` route emitters fail.

---

### `test/parapet/operator_ui_compile_out_test.exs` (test, transform)

**Analog:** `test/parapet/operator_ui_compile_out_test.exs`

**Compile-out dependency guard** (lines 4-12):
```elixir
describe "Phoenix dependency posture" do
  test "Parapet core does not depend directly on Phoenix or LiveView" do
    # Read the mix.exs file and ensure we aren't adding :phoenix directly
    # to force it on all adopters.
    mix_exs = File.read!("mix.exs")

    refute mix_exs =~ ~r/{:phoenix,/
    refute mix_exs =~ ~r/{:phoenix_live_view,/
  end
```

**Generated route guard pattern** (lines 24-37):
```elixir
test "generated detail LiveView routes escalation controls through the public operator API" do
  content = File.read!("priv/templates/parapet.gen.ui/operator_detail_live.ex.eex")

  assert content =~ "handle_event(\"trigger_next_escalation\""
  assert content =~ "handle_event(\"suppress_pending_escalation\""
  assert content =~ "Parapet.Operator.trigger_next_escalation"
  assert content =~ "Parapet.Operator.suppress_pending_escalation"
  assert content =~ "Parapet.Operator.resolve_incident"
  assert content =~ "%Parapet.Operator.ActionPayload{"
  assert content =~ "assign(incident: Parapet.Operator.incident_detail(id))"
  assert content =~ ~S|/parapet/incidents/#{id}|
  assert content =~ "Integer.parse(minutes)"
  refute content =~ "String.to_integer(minutes)"
end
```

**Implementation note:** Keep the dependency guard unchanged. Update route string assertions to require generated helper use without weakening the public operator API assertions.

---

### `test/parapet/generated_operator_live_paging_test.exs` (test, request-response)

**Analog:** `test/parapet/generated_operator_live_paging_test.exs`

**Generated compile harness pattern** (lines 292-314):
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
```

**Default route render pattern** (lines 327-349):
```elixir
test "generated operator live renders only the current bounded page and pages by URL cursor",
     %{live_module: live_module} do
  socket = configured_socket(live_module, URI.parse("http://example.com/parapet"))

  {:ok, socket} = live_module.mount(%{}, %{}, socket)
  {:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
  html = render_live(live_module, socket)

  assert html =~ "Active incident 1"
  assert html =~ "Active incident 30"
  refute html =~ "Active incident 31"
  refute html =~ "Resolved incident 61"

  assert count_queue_titles(html) == 30

  next_cursor =
    Base.url_encode64("2026-05-10T11:30:00Z|inc-030", padding: false)

  {:noreply, socket} =
    live_module.handle_params(
      %{"cursor" => next_cursor, "direction" => "next"},
      "http://example.com/parapet?cursor=#{next_cursor}&direction=next",
```

**Route output assertion pattern** (lines 391-408):
```elixir
test "generated history rows navigate to canonical incident detail instead of response queue",
     %{live_module: live_module} do
  socket = configured_socket(live_module, URI.parse("http://example.com/parapet/history"))

  {:ok, socket} = live_module.mount(%{}, %{}, socket)
  socket = Phoenix.Component.assign(socket, :live_action, :history)

  {:noreply, socket} =
    live_module.handle_params(%{}, "http://example.com/parapet/history", socket)

  html = render_live(live_module, socket)

  assert html =~ ~r/href="\/parapet\/incidents\/inc-\d{3}"/
  assert html =~ "Resolved archive"
  assert html =~ ~r/>\s*Older\s*</
  assert html =~ ~r/>\s*Newer\s*</
  refute html =~ ~r/href="\/parapet\?[^"]*id=inc-\d{3}/
  refute html =~ ~r/status=resolved[^"]*id=inc-\d{3}/
end
```

**Implementation note:** Add parallel cases for `http://example.com/ops/parapet` and `http://example.com/ops/parapet/history`, asserting emitted `href`/`patch` paths are scoped and do not include unscoped `/parapet` links.

---

### `test/parapet/operator_ui_demo_contract_test.exs` (test, request-response)

**Analog:** `test/parapet/operator_ui_demo_contract_test.exs`

**Demo route contract pattern** (lines 55-76):
```elixir
test "demo routes mirror the generated operator UI route shape" do
  router = File.read!(@router_path)
  smoke = File.read!(@smoke_path)

  for route <- [
        ~S|live("/parapet", DemoAppWeb.Parapet.OperatorLive, :index)|,
        ~S|live("/parapet/actions", DemoAppWeb.Parapet.OperatorLive, :actions)|,
        ~S|live("/parapet/history", DemoAppWeb.Parapet.OperatorLive, :history)|,
        ~S|live("/parapet/incidents/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)|,
        ~S|live("/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)|
      ] do
    assert router =~ route
  end

  for smoke_path <- [
        ~S|GET /parapet returns 200|,
        ~S|GET /parapet/actions returns 200|,
        ~S|GET /parapet/history returns 200|,
        ~S|preferred and compatibility incident detail routes render|
      ] do
    assert smoke =~ smoke_path
  end
end
```

**Browser route contract pattern** (lines 79-95):
```elixir
test "browser screenshot verification captures desktop and mobile operator paths" do
  script = File.read!(@browser_script_path)

  for path <- [
        "/parapet",
        "/parapet/actions",
        "/parapet/history",
        "/parapet/incidents/"
      ] do
    assert script =~ path
  end

  assert script =~ "1440,1100"
  assert script =~ "390,844"
  assert script =~ "operator-response-desktop"
  assert script =~ "operator-detail-mobile"
```

**Implementation note:** Add `/ops/parapet` proof to demo route and smoke/screenshot contracts if demo routes or screenshot capture are updated for scoped coverage.

---

### `examples/demo_app/test/demo_app/operator_smoke_test.exs` (test, request-response)

**Analog:** `examples/demo_app/test/demo_app/operator_smoke_test.exs`

**HTTP route smoke pattern** (lines 6-24):
```elixir
test "GET /parapet returns 200", %{conn: conn} do
  conn = get(conn, "/parapet")
  assert conn.status == 200
end

test "GET /parapet/actions returns 200", %{conn: conn} do
  conn = get(conn, "/parapet/actions")
  assert conn.status == 200
end

test "GET /parapet/history returns 200", %{conn: conn} do
  {:ok, _incident} =
    Parapet.Evidence.create_incident(%{
      title: "resolved history smoke incident",
      state: "resolved"
    })

  conn = get(conn, "/parapet/history")
  assert conn.status == 200
```

**Detail route smoke pattern** (lines 41-54):
```elixir
test "preferred and compatibility incident detail routes render", %{conn: conn} do
  {:ok, incident} =
    Parapet.Evidence.create_incident(%{
      title: "detail route smoke incident",
      state: "open"
    })

  preferred = get(conn, "/parapet/incidents/#{incident.id}")
  assert preferred.status == 200
  assert preferred.resp_body =~ "detail route smoke incident"

  compatibility = get(recycle(conn), "/parapet/#{incident.id}")
  assert compatibility.status == 200
  assert compatibility.resp_body =~ "detail route smoke incident"
end
```

**Implementation note:** Mirror these tests for `/ops/parapet` if the demo router gains scoped mounts. Keep seeding inside tests rather than relying on dev DB seeds.

---

### `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` (test, batch)

**Analog:** `examples/demo_app/scripts/capture_operator_ui_screenshots.sh`

**Base URL and reachability pattern** (lines 4-32):
```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEMO_DIR="$ROOT_DIR/examples/demo_app"
OUTPUT_DIR="${1:-$ROOT_DIR/.planning/phases/36-demo-state-coverage-browser-verification/screenshots}"
BASE_URL="${PARAPET_DEMO_URL:-http://127.0.0.1:4000}"
CHROME_BIN="${CHROME_BIN:-}"

if [[ -z "$CHROME_BIN" ]]; then
  for candidate in "$(command -v chromium || true)" "$(command -v google-chrome || true)" "$(command -v chromium-browser || true)"; do
```

```bash
if ! curl -fsS "$BASE_URL/parapet" >/dev/null; then
  echo "Demo app is not reachable at $BASE_URL. Start it with: cd $DEMO_DIR && mix phx.server" >&2
  exit 1
fi
```

**Capture route pattern** (lines 47-79):
```bash
capture() {
  local name="$1"
  local size="$2"
  local path="$3"
  local theme="${4:-system}"
  local themed_path="$path"
  if [[ "$path" == *"?"* ]]; then
    themed_path="${path}&parapet_theme=${theme}"
  else
    themed_path="${path}?parapet_theme=${theme}"
  fi
```

```bash
capture "operator-response-desktop" "1440,1100" "/parapet" "light"
capture "operator-actions-desktop" "1440,1100" "/parapet/actions" "light"
capture "operator-history-desktop" "1440,1100" "/parapet/history" "light"
capture "operator-detail-desktop" "1440,1100" "/parapet/incidents/$DETAIL_ID" "light"
```

**Implementation note:** If scoped demo verification includes screenshot capture, add equivalent `/ops/parapet` captures or parameterize the operator base path while preserving the current theme query handling.

---

### `docs/operator-ui.md` (utility, transform)

**Analog:** `docs/operator-ui.md`

**Mounting guidance pattern** (lines 56-71):
```markdown
scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do

    live "/parapet", MyAppWeb.Parapet.OperatorLive, :index
    live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions
    live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history
    live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
    live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
  end
end
```

**Targeted proof lane pattern** (lines 101-108):
```markdown
- The default queue remains active-only (`open` and `investigating`).
- Queue refresh is explicit. Background changes should surface a visible refresh affordance instead of silently reordering the list while an operator is reading it.
- Queue-side `Resolve` is a real lifecycle transition through `Parapet.Operator.resolve_incident/2`, not a UI-only note shortcut.
- Phase 3 remains the canonical runtime proof owner for this seam through the named `generated resolve-flow proof lane`.
- Performance proof is layered: bounded queue telemetry in `Parapet.Operator`, deterministic queue tests, and an opt-in advisory benchmark lane.
- The `generated resolve-flow proof lane` stays in the targeted `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` lane rather than a heavier browser harness.
```

**Implementation note:** Keep docs minimal for Phase 38. Only document the generated base-path seam and nested host scope enough to make generated code understandable; broader adoption docs belong to Phase 39.

## Shared Patterns

### Host-Owned Auth And Router Ownership
**Source:** `priv/templates/parapet.gen.ui/router_snippet.ex.eex` lines 1-18
**Apply to:** router guidance, demo router, docs, generator tests
```elixir
# Ensure you place these routes inside an existing authenticated scope,
# or define a new pipeline with your app's standard authentication plugs.
# Parapet does not provide its own auth.
```

Keep all scoped behavior in generated host-owned code, demo copies, docs, and tests. Do not add a Parapet-owned router or auth module.

### Compile-Out Boundary
**Source:** `test/parapet/operator_ui_compile_out_test.exs` lines 4-12
**Apply to:** any source or dependency change
```elixir
mix_exs = File.read!("mix.exs")

refute mix_exs =~ ~r/{:phoenix,/
refute mix_exs =~ ~r/{:phoenix_live_view,/
```

Phase 38 must not add direct `:phoenix` or `:phoenix_live_view` dependencies to Parapet core.

### Route Helper Centralization
**Source:** `priv/templates/parapet.gen.ui/operator_live.ex.eex` lines 403-428 and `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1248-1257
**Apply to:** all LiveView `push_patch`, `push_navigate`, `patch`, `navigate`, `href`, pagination, history, back, and detail links
```elixir
case params do
  [] -> queue_base_path(queue_params)
  _ -> queue_base_path(queue_params) <> "?" <> URI.encode_query(params)
end
```

```elixir
defp incident_detail_path(incident), do: "/parapet/incidents/#{incident.id}"
```

Replace literal path construction with helpers that accept or derive `operator_base_path`, while preserving query param filtering and `URI.encode_query/1`.

### Generated Source Contracts
**Source:** `test/mix/tasks/parapet.gen.ui_test.exs` lines 27-70 and 113-118
**Apply to:** generated template behavior tests
```elixir
Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
|> Rewrite.Source.get(:content)
```

Use `Igniter.Test`, `Rewrite.source!`, and string assertions to prove generated files include base-path helpers and no route-producing surface bypasses them.

### Runtime Generated LiveView Proof
**Source:** `test/parapet/generated_operator_live_paging_test.exs` lines 292-314 and 391-408
**Apply to:** scoped/default route behavior proof
```elixir
Code.compile_string(operator_components_source)
[{live_module, _bytecode}] = Code.compile_string(operator_live_source)
```

```elixir
{:noreply, socket} =
  live_module.handle_params(%{}, "http://example.com/parapet/history", socket)

html = render_live(live_module, socket)

assert html =~ ~r/href="\/parapet\/incidents\/inc-\d{3}"/
```

Add the same render assertions for `http://example.com/ops/parapet` and assert emitted links remain scoped.

### Demo Drift Protection
**Source:** `test/parapet/operator_ui_integration_test.exs` lines 194-225 and `test/parapet/operator_ui_demo_contract_test.exs` lines 55-95
**Apply to:** demo copied LiveViews, demo router, smoke tests, screenshot script
```elixir
live_content =
  File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex")

detail_content =
  File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex")

components_content =
  File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex")
```

```elixir
router = File.read!(@router_path)
smoke = File.read!(@smoke_path)
```

Any route-base helper added to templates must be reflected in demo copies and pinned in demo contracts.

## No Analog Found

None.

## Metadata

**Analog search scope:** `priv/templates/parapet.gen.ui`, `lib/mix/tasks/parapet.gen.ui.ex`, `examples/demo_app/lib`, `examples/demo_app/test`, `examples/demo_app/scripts`, `test/mix/tasks`, `test/parapet`, `docs/operator-ui.md`
**Files scanned:** 113 under target scopes
**Pattern extraction date:** 2026-06-04
