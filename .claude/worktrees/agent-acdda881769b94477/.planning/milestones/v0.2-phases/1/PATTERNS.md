# Phase 1: Durable Evidence Spine (Ecto) - Pattern Map

**Mapped:** 2024-05-11
**Files analyzed:** 4
**Analogs found:** 1 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/parapet.gen.spine.ex` | generator | file I/O | `lib/mix/tasks/parapet.install.ex` | exact |
| `lib/parapet/spine/incident.ex` | model | CRUD | None | no-match |
| `lib/parapet/spine/timeline_entry.ex` | model | CRUD | None | no-match |
| `lib/parapet/spine/tool_audit.ex` | model | CRUD | None | no-match |

## Pattern Assignments

### `lib/mix/tasks/parapet.gen.spine.ex` (generator, file I/O)

**Analog:** `lib/mix/tasks/parapet.install.ex`

**Imports pattern** (lines 6-11):
```elixir
  use Igniter.Mix.Task

  alias Igniter.Code.Common
  alias Igniter.Code.Module, as: CodeModule
  alias Igniter.Project.Config
  alias Igniter.Project.Module, as: ProjectModule
```

**Task Info pattern** (lines 13-19):
```elixir
  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [with_sigra: :boolean],
      defaults: [with_sigra: false]
    }
  end
```

**Core Generator pattern** (lines 21-44):
```elixir
  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = ProjectModule.module_name_prefix(igniter)
    instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
    web_module = Module.concat([inspect(app_module) <> "Web"])
    endpoint_module = Module.concat([web_module, Endpoint])

    with_sigra? = igniter.args.options[:with_sigra] || false

    # ... (setup code omitted for brevity) ...

    igniter
    |> ProjectModule.create_module(
      instrumenter_module,
      """
      @moduledoc "Host-owned telemetry instrumentation for Parapet."

      #{setup_code}
      """
    )
    |> Config.configure(
      "config.exs",
      :parapet,
      [:instrumenter],
      instrumenter_module
    )
```

---

## No Analog Found

Files with no close match in the codebase (planner should use standard Ecto patterns):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/spine/incident.ex` | model | CRUD | No Ecto schemas exist in the project yet |
| `lib/parapet/spine/timeline_entry.ex` | model | CRUD | No Ecto schemas exist in the project yet |
| `lib/parapet/spine/tool_audit.ex` | model | CRUD | No Ecto schemas exist in the project yet |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`, `lib/mix/tasks/**/*.ex`
**Files scanned:** ~20
**Pattern extraction date:** 2024-05-11
