# Phase 2: In-App Operator UI (LiveView) - Pattern Map

**Mapped:** 2026-05-11
**Files analyzed:** 10
**Analogs found:** 6 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/operator.ex` | service/public API | CRUD | `lib/parapet/evidence.ex` | exact |
| `test/parapet/operator_test.exs` | test | CRUD | `test/parapet/evidence_test.exs` | exact |
| `lib/mix/tasks/parapet.gen.ui.ex` | utility/CLI | file-I/O | `lib/mix/tasks/parapet.install.ex` | exact |
| `test/mix/tasks/parapet.gen.ui_test.exs` | test | file-I/O | `test/mix/tasks/parapet.gen.spine_test.exs` | exact |
| `lib/mix/tasks/parapet.doctor.ex` | utility/CLI | batch | `lib/mix/tasks/parapet.doctor.ex` | exact |
| `test/mix/tasks/parapet.doctor_test.exs` | test | batch | `test/mix/tasks/parapet.doctor_test.exs` | exact |
| `priv/templates/parapet.gen.ui/*` | config/template | file-I/O | `priv/templates/parapet.gen.grafana/*` via generator lookup in `lib/mix/tasks/parapet.gen.grafana.ex` | role-match |
| `docs/operator-ui.md` | docs | transform | `docs/slo-reference.md` | exact |
| `README.md` | docs | transform | `README.md` | exact |
| `lib/<host>_web/live/parapet/*` generated files | component/LiveView | request-response | none in repo | n/a |

## Pattern Assignments

### `lib/parapet/operator.ex` (service/public API, CRUD)

**Analog:** `lib/parapet/evidence.ex`

Use a thin public boundary module, not direct schema writes from LiveView. The current repo already uses a single public context to protect storage boundaries.

**Boundary and repo lookup** (`lib/parapet/evidence.ex:1-18`):
```elixir
defmodule Parapet.Evidence do
  @moduledoc """
  Public API boundary for Spine schemas.
  Enforces a boundary that prevents high-volume telemetry from writing directly
  to the durable Ecto database.
  """

  alias Parapet.Spine.{Incident, TimelineEntry, ToolAudit}

  def repo do
    Application.get_env(:parapet, :repo) ||
      raise ArgumentError,
            "Parapet requires a :repo to be configured. Please set `config :parapet, repo: MyApp.Repo`."
  end
end
```

**Simple context function shape** (`lib/parapet/evidence.ex:20-45`):
```elixir
def create_incident(attrs \\ %{}) do
  %Incident{}
  |> Incident.changeset(attrs)
  |> repo().insert()
end
```

**Recommendation:** keep Phase 2 writes behind `Parapet.Operator` or a similarly named public context. LiveView modules should call this boundary, not `Parapet.Spine.*` changesets directly.

---

### `lib/mix/tasks/parapet.gen.ui.ex` (utility/CLI, file-I/O)

**Primary analog:** `lib/mix/tasks/parapet.install.ex`
**Secondary analog:** `lib/mix/tasks/parapet.gen.grafana.ex`

Phase 2’s UI should follow the repo’s generator-first, host-owned posture: generate host modules, patch host router/auth seams safely, keep Parapet out of tenancy/auth ownership.

**Igniter task shape** (`lib/mix/tasks/parapet.install.ex:1-22`):
```elixir
defmodule Mix.Tasks.Parapet.Install do
  @moduledoc """
  Installs Parapet into a Phoenix application by scaffolding the host-owned instrumenter
  and wiring it into the endpoint.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [with_sigra: :boolean],
      defaults: [with_sigra: false]
    }
  end
```

**Host-owned module generation** (`lib/mix/tasks/parapet.install.ex:49-65`):
```elixir
igniter
|> ProjectModule.create_module(
  instrumenter_module,
  """
  @moduledoc "Host-owned telemetry instrumentation for Parapet."
  ...
  """
)
|> Config.configure("config.exs", :parapet, [:instrumenter], instrumenter_module)
|> update_endpoint(endpoint_module, web_module)
```

**Safe AST patching of host code** (`lib/mix/tasks/parapet.install.ex:68-95`):
```elixir
ProjectModule.find_and_update_module!(igniter, endpoint_module, fn zipper ->
  has_plug? = Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"

  if has_plug? do
    {:ok, zipper}
  else
    insert_plug(zipper, web_module)
  end
end)
```

**Template lookup and file emission** (`lib/mix/tasks/parapet.gen.grafana.ex:32-55`):
```elixir
template =
  Application.app_dir(:parapet, "priv/templates/parapet.gen.grafana/main_dashboard.json.eex")

content = EEx.eval_file(template, app_name: app_name, slos: slos)

Igniter.create_new_file(
  igniter,
  "priv/parapet/grafana/dashboards/main.json",
  content
)
```

**Recommendation:** put UI templates under `priv/templates/parapet.gen.ui/`, and generate host files under `lib/<host>_web/live/parapet/`. Any router insertion should be AST-based and idempotent. The generator should mount only inside a host-authenticated scope or emit a route helper snippet the host places manually.

---

### `lib/mix/tasks/parapet.doctor.ex` (utility/CLI, batch)

**Analog:** existing `lib/mix/tasks/parapet.doctor.ex`

Doctor checks in this repo aggregate named checks, return `:ok` or halt with explicit exit codes, and support human plus CI output.

**Execution + result aggregation** (`lib/mix/tasks/parapet.doctor.ex:21-60`):
```elixir
def run(args) do
  {opts, _, _} = OptionParser.parse(args, switches: [ci: :boolean])
  is_ci = Keyword.get(opts, :ci, false)

  Application.load(:parapet)
  Mix.Task.run("app.config")

  results = %{
    runbooks: check_runbooks(),
    router: check_router(),
    endpoint: check_endpoint()
  }
  ...
  if exit_code > 0, do: halt(exit_code)
  :ok
end
```

**Router static-analysis posture** (`lib/mix/tasks/parapet.doctor.ex:79-131`):
```elixir
router_path = "lib/#{app_name}_web/router.ex"

if File.exists?(router_path) do
  source = File.read!(router_path)

  if Code.ensure_loaded?(Sourceror) do
    ast = Sourceror.parse_string!(source)
    ...
  else
    %{status: :ok, messages: ["Sourceror not available, skipping router static analysis."]}
  end
end
```

**CI/human output split** (`lib/mix/tasks/parapet.doctor.ex:163-208`):
```elixir
defp print_json(results, exit_code) do
  output = %{exit_code: exit_code, checks: results}

  if Code.ensure_loaded?(Jason) do
    Mix.shell().info(Jason.encode!(output))
  else
    Mix.shell().info(inspect(output))
  end
end
```

**Recommendation:** extend doctor with a separate `operator_ui` check instead of folding UI auth into the existing router messages. Keep it static, router-driven, and CI-friendly. Validate that generated Parapet LiveViews are mounted only inside host auth/live_session boundaries.

---

### `test/parapet/operator_test.exs` (test, CRUD)

**Analog:** `test/parapet/evidence_test.exs`

Context tests here avoid a real repo by injecting a small fake repo into application config.

**Repo stub + env setup** (`test/parapet/evidence_test.exs:4-18`):
```elixir
defmodule DummyRepo do
  def insert(changeset) do
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end

setup do
  Application.put_env(:parapet, :repo, DummyRepo)
  on_exit(fn -> Application.delete_env(:parapet, :repo) end)
  :ok
end
```

**API-level assertions** (`test/parapet/evidence_test.exs:20-64`):
```elixir
assert {:ok, incident} = Parapet.Evidence.create_incident(attrs)
assert {:error, changeset} = Parapet.Evidence.create_incident(%{title: nil})
```

**Recommendation:** Phase 2 context tests should assert public API behavior and audit payload requirements. Do not test LiveView behavior here.

---

### `test/mix/tasks/parapet.gen.ui_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/parapet.gen.spine_test.exs`

Generator tests use `Igniter.Test`, inspect the in-memory rewrite tree, and assert created files plus exact source fragments.

**Igniter test shape** (`test/mix/tasks/parapet.gen.spine_test.exs:1-31`):
```elixir
use ExUnit.Case, async: true
import Igniter.Test

igniter =
  test_project(app_name: :test)
  |> Spine.igniter()

config_source =
  Rewrite.source!(igniter.rewrite, "config/config.exs")
  |> Rewrite.Source.get(:content)
```

**Recommendation:** assert generated LiveView/component files, router patch content, and idempotency. The generator test is the right place to verify file placement conventions like `lib/test_web/live/parapet/operator_live.ex`.

---

### `test/mix/tasks/parapet.doctor_test.exs` (test, batch)

**Analog:** existing `test/mix/tasks/parapet.doctor_test.exs`

Mix task tests here run synchronously, switch to `Mix.Shell.Process`, and assert halt codes plus shell output.

**Task test posture** (`test/mix/tasks/parapet.doctor_test.exs:6-39`):
```elixir
setup do
  Mix.shell(Mix.Shell.Process)
  Application.put_env(:parapet, :slos, [])
  on_exit(fn -> Application.put_env(:parapet, :slos, []) end)
  :ok
end

assert catch_exit(Doctor.run([])) == {:shutdown, 2}
assert_receive {:mix_shell, :error, ["  - SLO :bad_slo is missing a valid runbook"]}
```

**Recommendation:** add doctor fixtures for authenticated and unauthenticated router mounts, then assert warning vs success exit behavior exactly as this test does.

---

### `docs/operator-ui.md` and `README.md` (docs, transform)

**Analogs:** `docs/slo-reference.md`, `README.md`

Docs in this repo are short, instructional, and example-led. README covers the operator loop; focused docs explain one feature deeply.

**Focused reference style** (`docs/slo-reference.md:5-36`):
```markdown
## Defining an SLO
...
## Required Fields
...
## The Importance of Runbooks
```

**README integration style** (`README.md:17-85`):
```markdown
## Installation
...
### 2. Validate your configuration
...
### 4. Generate Grafana Dashboards
```

**Recommendation:** add one focused doc for operator UI install/mount/security and keep README to a short operator-loop addition plus generator/doctor commands.

## Shared Patterns

### Public API Boundary
**Sources:** `lib/parapet/evidence.ex:1-45`, `lib/mix/tasks/verify.public_api.ex:39-58`

- Public modules live under `Parapet.*` with `@moduledoc`; internals stay under `Parapet.Internal.*`.
- New public Phase 2 modules should pass the public API docs gate implied by `mix.exs:43-46`.

### Generator-First, Host-Owned Setup
**Sources:** `lib/mix/tasks/parapet.install.ex:21-127`, `lib/mix/tasks/parapet.gen.spine.ex:12-63`

- Generators own scaffolding and idempotent host-file patching.
- Host app owns router path, auth plug chain, `live_session`, and generated LiveView modules.
- Library-owned reusable assets belong in `lib/parapet/*`; generator source templates belong in `priv/templates/parapet.gen.ui/`.

### Optional Dependency Posture
**Sources:** `mix.exs:30-40`, `lib/parapet/metrics/oban.ex:1-79`, `lib/parapet/integrations/sigra.ex:1-59`

- Optional integrations are guarded with `if Code.ensure_loaded?(...) do`.
- If Phase 2 ships any reusable `Phoenix.LiveView` or `Phoenix.Component` modules inside the library, introduce the same compile-time guard posture or add an explicit dependency decision first.

### Test Placement
**Sources:** `test/parapet/evidence_test.exs:1-65`, `test/mix/tasks/parapet.gen.spine_test.exs:1-31`, `test/mix/tasks/parapet.doctor_test.exs:1-40`

- Public contexts test under `test/parapet/`.
- Mix task and generator coverage test under `test/mix/tasks/`.
- Generated host LiveView tests are a new category and should be emitted into the host app’s `test/<app>_web/live/parapet/`.

## Missing Patterns Phase 2 Must Introduce

| Needed pattern | Why it is missing now | Recommendation |
|----------------|-----------------------|----------------|
| Host-generated LiveView module layout | Repo has no LiveView modules or components yet | Introduce `lib/<host>_web/live/parapet/operator_live.ex` and companion components under the host app, generated from `priv/templates/parapet.gen.ui/`. |
| Transactional mutation boundary | `Parapet.Evidence` only does single inserts; Phase 2 requires state change + timeline + audit together | Introduce a new context function using a transaction boundary for mutating actions. Keep LiveView free of multi-step persistence logic. |
| Router/live_session auth verification for UI mounts | Doctor only checks `/metrics` and `live_dashboard` today | Add a dedicated `operator_ui` doctor check that looks for generated Parapet LiveView mounts inside authenticated host scope/live session. |
| Library posture for optional Phoenix/LiveView helpers | Repo currently models optional integrations only for Oban/Sigra | If reusable UI helpers live in the library, wrap them with `Code.ensure_loaded?(Phoenix.LiveView)` / `Code.ensure_loaded?(Phoenix.Component)` or keep all UI code host-generated. |
| LiveView interaction tests | Current test suite has no LiveView test analog | Generate host-side LiveView tests for selection routing, disabled unauthorized actions, and mutation confirmation flows. |

## Planner Recommendations

- Prefer `Parapet.Operator` as the Phase 2 public boundary and keep `Parapet.Spine.*` as data structures, not controller-like entry points.
- Put generator code in `lib/mix/tasks/parapet.gen.ui.ex`, templates in `priv/templates/parapet.gen.ui/`, docs in `docs/operator-ui.md`, and only concise install/use guidance in `README.md`.
- Treat generated host files as the primary UI surface: `lib/<host>_web/live/parapet/*` and `test/<host>_web/live/parapet/*`.
- Extend `mix parapet.doctor` rather than creating a second doctor-style command.

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`, `lib/mix/tasks/**/*.ex`, `test/**/*.exs`, `docs/**/*.md`, `README.md`
**Files scanned:** 16
**Pattern extraction date:** 2026-05-11
