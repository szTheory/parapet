# Phase 4: Unified Install Path (DX) - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 6 likely modified files
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/parapet.install.ex` | utility | batch | `lib/mix/tasks/parapet.install.ex` | exact |
| `test/mix/tasks/parapet.install_test.exs` | test | batch | `test/mix/tasks/parapet.install_test.exs` | exact |
| `lib/mix/tasks/parapet.doctor.ex` | utility | batch | `lib/mix/tasks/parapet.doctor.ex` | exact |
| `test/mix/tasks/parapet.doctor_test.exs` | test | batch | `test/mix/tasks/parapet.doctor_test.exs` | exact |
| `README.md` | doc | transform | `docs/operator-ui.md` | role-match |
| `docs/operator-ui.md` | doc | transform | `README.md` | role-match |

## Pattern Assignments

### `lib/mix/tasks/parapet.install.ex` (utility, batch)

**Primary analog:** `lib/mix/tasks/parapet.install.ex`

**Secondary analogs:** `lib/mix/tasks/parapet.gen.spine.ex`, `lib/mix/tasks/parapet.gen.prometheus.ex`, `lib/mix/tasks/parapet.gen.ui.ex`, `lib/mix/tasks/parapet.gen.runbooks.ex`

**Imports and task metadata** (`lib/mix/tasks/parapet.install.ex:6-18`):
```elixir
use Igniter.Mix.Task

alias Igniter.Code.Common
alias Igniter.Code.Module, as: CodeModule
alias Igniter.Project.Config
alias Igniter.Project.Module, as: ProjectModule

@impl Igniter.Mix.Task
def info(_argv, _composing_task) do
  %Igniter.Mix.Task.Info{
    schema: [with_sigra: :boolean],
    defaults: [with_sigra: false]
  }
end
```

**Core orchestration pattern** (`lib/mix/tasks/parapet.install.ex:21-95`):
```elixir
def igniter(igniter) do
  app_module = ProjectModule.module_name_prefix(igniter)
  instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
  web_module = Module.concat([inspect(app_module) <> "Web"])
  endpoint_module = Module.concat([web_module, Endpoint])

  with_sigra? = igniter.args.options[:with_sigra] || false
  with_scoria? = igniter.args.options[:with_scoria] || false

  ...

  igniter =
    if with_scoria? do
      Igniter.compose_task(igniter, "parapet.gen.scoria", [])
    else
      igniter
    end

  igniter
  |> ProjectModule.create_module(...)
  |> Config.configure("config.exs", :parapet, [:instrumenter], instrumenter_module)
  |> update_endpoint(endpoint_module, web_module)
  |> update_deploy_hook()
end
```

**Idempotent endpoint patching** (`lib/mix/tasks/parapet.install.ex:98-125`):
```elixir
defp update_endpoint(igniter, endpoint_module, web_module) do
  ProjectModule.find_and_update_module!(igniter, endpoint_module, fn zipper ->
    has_plug? = Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"

    if has_plug? do
      {:ok, zipper}
    else
      insert_plug(zipper, web_module)
    end
  end)
end

defp insert_plug(zipper, web_module) do
  case find_insertion_point(zipper, web_module) do
    {:ok, insert_zipper} ->
      {:ok, Common.add_code(insert_zipper, "plug Parapet.Plug.Metrics", placement: :after)}

    :error ->
      {:ok, zipper}
  end
end
```

**Create-or-update file pattern for rerunnable installs** (`lib/mix/tasks/parapet.install.ex:128-156`):
```elixir
Igniter.create_or_update_file(
  igniter,
  "rel/hooks/post_start.sh",
  initial_content,
  updater
)
```

**Compose small generators, do not duplicate them**:
- Copy `Igniter.Project.Config.configure/4` + migration generation from `lib/mix/tasks/parapet.gen.spine.ex:13-24`.
- Copy artifact generation chaining from `lib/mix/tasks/parapet.gen.prometheus.ex:18-33`.
- Copy optional generated notice pattern from `lib/mix/tasks/parapet.gen.ui.ex:70-105` and `lib/mix/tasks/parapet.gen.runbooks.ex:57-60`.

**Host-owned auth boundary for UI offer step** (`lib/mix/tasks/parapet.gen.ui.ex:84-105`):
```elixir
guidance =
  if File.exists?(template_path) do
    EEx.eval_file(template_path, assigns: assigns)
  else
    """
    # Ensure you place these routes inside an existing authenticated scope,
    # or define a new pipeline with your app's standard authentication plugs.
    # Parapet does not provide its own auth.
    ...
    """
  end

Igniter.add_notice(igniter, guidance)
```

**Integration activation contract to preserve**:
- Use explicit `Parapet.attach(adapters: [...])` wiring from `lib/parapet.ex:21-38`.
- Keep install-generated activation host-owned and deterministic, matching `README.md:136-146`.
- Do not mutate integration modules to invent a second activation path.

---

### `test/mix/tasks/parapet.install_test.exs` (test, batch)

**Primary analog:** `test/mix/tasks/parapet.install_test.exs`

**Secondary analog:** `test/mix/tasks/parapet.gen.ui_test.exs`

**Igniter task harness** (`test/mix/tasks/parapet.install_test.exs:8-16`):
```elixir
igniter =
  test_project(app_name: :test)
  |> Igniter.Project.Module.create_module(TestWeb.Endpoint, """
  use TestWeb, :endpoint

  plug Plug.RequestId
  """)
  |> Install.igniter()
```

**Generated file and rewrite assertions** (`test/mix/tasks/parapet.install_test.exs:18-40`):
```elixir
assert_creates(igniter, "lib/test/parapet_instrumenter.ex", """
defmodule Test.ParapetInstrumenter do
  @moduledoc "Host-owned telemetry instrumentation for Parapet."

  def setup do
    Parapet.Metrics.Probe.setup()
    :ok
  end
end
""")

endpoint_source =
  Rewrite.source!(igniter.rewrite, "lib/test_web/endpoint.ex")
  |> Rewrite.Source.get(:content)

assert endpoint_source =~ "plug(Parapet.Plug.Metrics)"
```

**Idempotency proof** (`test/mix/tasks/parapet.install_test.exs:43-60`):
```elixir
assert [_, _] = String.split(endpoint_source, "plug(Parapet.Plug.Metrics)")
```

**Notice assertion pattern for summary/gated extras** (`test/mix/tasks/parapet.gen.ui_test.exs:54-72`):
```elixir
assert Enum.any?(
  igniter.notices,
  &String.contains?(&1, "Ensure you place these routes inside an existing authenticated scope")
)
```

Use this same notice assertion style for:
- end-of-run summary copy
- skipped extras copy
- UI-offer guidance copy
- follow-up actions such as `mix parapet.doctor`

---

### `lib/mix/tasks/parapet.doctor.ex` (utility, batch)

**Primary analog:** `lib/mix/tasks/parapet.doctor.ex`

**Current CLI and aggregation pattern** (`lib/mix/tasks/parapet.doctor.ex:23-79`):
```elixir
def run(args) do
  {opts, checks, _} = OptionParser.parse(args, switches: [ci: :boolean])
  is_ci = Keyword.get(opts, :ci, false)
  run_all? = checks == []

  Application.load(:parapet)
  Mix.Task.run("app.config")

  results = %{}
  results =
    if run_all? or "runbooks" in checks,
      do: Map.put(results, :runbooks, check_runbooks()),
      else: results
  ...

  if is_ci do
    print_json(results, exit_code)
  else
    print_human(results)
  end

  if exit_code > 0, do: halt(exit_code)
  :ok
end
```

**Check function shape** (`lib/mix/tasks/parapet.doctor.ex:81-95`):
```elixir
defp check_runbooks do
  slos = Parapet.SLO.all()

  invalid_slos =
    Enum.filter(slos, fn slo ->
      is_nil(slo.runbook) or String.trim(slo.runbook) == ""
    end)

  if invalid_slos == [] do
    %{status: :ok, messages: ["All SLOs have runbooks."]}
  else
    %{status: :fatal, messages: messages}
  end
end
```

**AST-based static router analysis** (`lib/mix/tasks/parapet.doctor.ex:97-143`):
```elixir
if File.exists?(router_path) do
  source = File.read!(router_path)

  if Code.ensure_loaded?(Sourceror) do
    ast = Sourceror.parse_string!(source)

    {_, acc} =
      Macro.prewalk(ast, {[], []}, fn
        {:scope, _, args} = node, {scopes, violations} ->
          {node, {[{:scope, extract_plugs(args)} | scopes], violations}}
        ...
      end)
```

**UI-specific scoped analysis** (`lib/mix/tasks/parapet.doctor.ex:145-196`):
```elixir
{:live_session, _, args} = node, {scopes, violations} ->
  {node, {[{:live_session, extract_plugs(args)} | scopes], violations}}

{:live, _, args} = node, {scopes, violations} ->
  text = Macro.to_string(args)

  is_operator_ui =
    String.contains?(text, "OperatorLive") or
      String.contains?(text, "OperatorDetailLive")

  if is_operator_ui and not has_auth_plug?(scopes) do
    {node, {scopes, ["Unsecured operator UI LiveView found" | violations]}}
  else
    {node, {scopes, violations}}
  end
```

**Human and machine output contract** (`lib/mix/tasks/parapet.doctor.ex:224-259`):
```elixir
printer.(
  IO.ANSI.format(color ++ ["==> #{check}: #{result.status}"] ++ [:reset])
  |> IO.iodata_to_binary()
)

output = %{
  exit_code: exit_code,
  checks: results
}
```

**Phase 4 adaptation guidance**:
- Keep the `OptionParser -> results map -> human/json printer -> halt` skeleton.
- Evolve statuses from current `:ok/:warn/:fatal` shape toward the Phase 4 `info/warn/error/skip` contract instead of replacing the whole structure.
- Keep `0/1/2` exit code distinction as an explicit aggregation step, not buried inside individual checks.

---

### `test/mix/tasks/parapet.doctor_test.exs` (test, batch)

**Primary analog:** `test/mix/tasks/parapet.doctor_test.exs`

**Mix shell capture harness** (`test/mix/tasks/parapet.doctor_test.exs:8-31`):
```elixir
setup do
  Mix.shell(Mix.Shell.Process)
  Application.put_env(:parapet, :slos, [])
  File.mkdir_p!(Path.dirname(@router_path))
  ...
end

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

**Exit code assertions** (`test/mix/tasks/parapet.doctor_test.exs:48-61`, `test/mix/tasks/parapet.doctor_test.exs:143-153`, `test/mix/tasks/parapet.doctor_test.exs:178-197`):
```elixir
assert catch_exit(Doctor.run([])) == {:shutdown, 2}
assert catch_exit(Doctor.run(["--ci"])) == {:shutdown, 1}
assert catch_exit(Doctor.run(["cardinality"])) == {:shutdown, 2}
```

**Router fixture pattern** (`test/mix/tasks/parapet.doctor_test.exs:65-127`):
```elixir
router_content = """
defmodule ParapetWeb.Router do
  use Phoenix.Router

  scope "/admin", ParapetWeb do
    pipe_through [:browser, :require_authenticated_user]
    ...
  end
end
"""

File.write!(@router_path, router_content)
```

**JSON contract assertion** (`test/mix/tasks/parapet.doctor_test.exs:130-153`):
```elixir
assert_receive {:mix_shell, :info, output}

json_output = Jason.decode!(output)
assert Map.has_key?(json_output["checks"], "operator_ui")
assert json_output["checks"]["operator_ui"]["status"] == "warn"
```

Extend this same test shape for:
- threshold changes between local and `--ci`
- new `info`/`skip` statuses
- runtime-oriented doctor mode output
- exit code `2` reserved for probe/doctor execution failure

---

### `README.md` (doc, transform)

**Primary analog:** `README.md`

**Secondary analog:** `docs/operator-ui.md`

**Current Day-1 install narrative** (`README.md:21-40`):
```md
## Installation

Add `parapet` to your list of dependencies in `mix.exs`:
...
mix deps.get
mix parapet.install

This will automatically wire Parapet into your Phoenix Endpoint and create a default SLO configuration file.
```

**Current doctor-as-next-step pattern** (`README.md:63-79`):
```md
### 2. Validate your configuration

Run the Parapet Doctor to ensure your configuration is secure and complete.

mix parapet.doctor
```

**Explicit integration opt-in contract** (`README.md:136-146`):
```md
### Optional Async And Delivery Integrations

Parapet's Phase 4 async and delivery contract is host-owned and explicit.
To enable the built-in adapters, opt in through `Parapet.attach/1`:

Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])
```

Copy this structure when tightening the Day-1 story:
- keep `mix parapet.install` as the single paved-road command
- keep `mix parapet.doctor` as the immediate verification step
- keep optional integrations explicitly opt-in, not dependency-detected auto-enable

---

### `docs/operator-ui.md` (doc, transform)

**Primary analog:** `docs/operator-ui.md`

**Secondary analog:** `lib/mix/tasks/parapet.gen.ui.ex`

**Prerequisite and generator gating copy** (`docs/operator-ui.md:9-30`):
```md
## Prerequisites

- Phoenix and LiveView installed in your host app
- Parapet installed and configured (`mix parapet.install`)
- A router with an existing authenticated pipeline or `live_session`

## Installation

Run the generator from the root of your project:

mix parapet.gen.ui
```

**Host-owned auth wording and router snippet** (`docs/operator-ui.md:28-47`):
```md
The generated files belong to your application. Parapet does **not** provide its own authentication system.

scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do
    ...
  end
end
```

**Doctor verification wording** (`docs/operator-ui.md:49-59`):
```md
The Parapet Doctor includes a dedicated check to verify that your operator UI is securely mounted.

mix parapet.doctor

If the doctor detects that `OperatorLive` or `OperatorDetailLive` are mounted outside of an authenticated scope, it will report a warning.
```

Use this doc as the copy pattern for any installer summary or README wording that mentions the UI:
- UI is optional
- UI is only relevant when Phoenix LiveView exists
- auth remains host-owned
- doctor is the verification backstop

## Shared Patterns

### Igniter Task Composition
**Sources:** `lib/mix/tasks/parapet.install.ex:21-95`, `lib/mix/tasks/parapet.gen.spine.ex:13-24`, `lib/mix/tasks/parapet.gen.prometheus.ex:18-33`
**Apply to:** `lib/mix/tasks/parapet.install.ex`
```elixir
igniter
|> Igniter.Project.Config.configure(...)
|> Igniter.Libs.Ecto.gen_migration(...)
|> Igniter.create_new_file(...)
```

Planner guidance: keep `mix parapet.install` as the orchestrator that composes smaller generators in order, rather than re-implementing their internals.

### Host-Owned Optional UI
**Sources:** `lib/mix/tasks/parapet.gen.ui.ex:70-105`, `docs/operator-ui.md:28-59`, `test/mix/tasks/parapet.gen.ui_test.exs:54-72`
**Apply to:** installer summaries, README copy, any UI prompt/flag flow
```elixir
Igniter.add_notice(igniter, guidance)
```

Planner guidance: if install offers `parapet.gen.ui`, gate it on LiveView presence and preserve the existing "Parapet does not provide its own auth" notice boundary.

### Explicit Adapter Activation
**Sources:** `lib/parapet.ex:21-38`, `test/parapet_test.exs:72-129`, `README.md:136-146`
**Apply to:** installer-generated host wiring for Mailglass/Chimeway extras
```elixir
assert {:ok, [:mailglass, :chimeway, :rindle]} ==
         Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])
```

Planner guidance: generated code should opt in through `Parapet.attach(adapters: [...])` plus `config :parapet, providers: [...]`; do not auto-add deps and do not add a second activation mechanism.

### Doctor Output and Threshold Contract
**Sources:** `lib/mix/tasks/parapet.doctor.ex:60-79`, `lib/mix/tasks/parapet.doctor.ex:224-259`, `test/mix/tasks/parapet.doctor_test.exs:130-153`
**Apply to:** new severity threshold logic, `--ci`, runtime-oriented mode
```elixir
output = %{
  exit_code: exit_code,
  checks: results
}
```

Planner guidance: keep stable machine-readable per-check output and test it through `Jason.decode!/1`.

### Compile-Out and Integration Safety
**Sources:** `lib/parapet/integrations/mailglass.ex:22-45`, `lib/parapet/integrations/chimeway.ex:17-40`, `test/parapet/integrations/mailglass_test.exs:45-139`, `test/parapet/integrations/chimeway_test.exs:51-89`
**Apply to:** any install-generated optional integration wiring and related tests
```elixir
def setup do
  :telemetry.detach(@handler_id)
  :telemetry.attach(...)
end

def handle_event(event, measurements, metadata, _config) do
  process_event(event, measurements, metadata)
rescue
  e ->
    Logger.error(...)
    :ok
end
```

Planner guidance: optional integration support assumes adapters remain safe to call repeatedly and safe when absent; tests should keep proving normalized bounded metadata and non-crashing handler behavior.

## No Analog Found

Files the planner may choose to create if Phase 4 extracts helpers out of the two Mix tasks:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/install/*.ex` | utility | batch | No existing dedicated installer-helper namespace exists; current pattern is task-local private helpers in `lib/mix/tasks/parapet.install.ex`. |
| `lib/parapet/doctor/*.ex` | utility | batch | No existing dedicated doctor-helper namespace exists; current pattern is task-local checks in `lib/mix/tasks/parapet.doctor.ex`. |

If helper extraction is chosen, copy naming and small-function shape from existing `lib/parapet/*/*` namespaces, but keep orchestration entrypoints in the Mix task files.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/parapet/`, `test/mix/tasks/`, `test/parapet/`, `docs/`, `README.md`
**Files scanned:** 18
**Pattern extraction date:** 2026-05-20
