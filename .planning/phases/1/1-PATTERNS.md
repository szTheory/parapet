# Phase 1: SRE Telemetry Translation - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/integrations/scoria.ex` | integration | event-driven | `lib/parapet/integrations/accrue.ex` | exact |
| `lib/mix/tasks/parapet.gen.scoria.ex` | generator | file I/O | `lib/mix/tasks/parapet.gen.prometheus.ex` | exact |
| `lib/mix/tasks/parapet.install.ex` | generator | file I/O | `lib/mix/tasks/parapet.install.ex` (self) | exact |

## Pattern Assignments

### `lib/parapet/integrations/scoria.ex` (integration, event-driven)

**Analog:** `lib/parapet/integrations/accrue.ex`

**Imports and Setup pattern** (lines 1-15):
```elixir
defmodule Parapet.Integrations.Accrue do
  @moduledoc """
  Parapet integration for the Accrue billing library.
  Listens to Accrue telemetry events and translates them into standard Parapet billing journey metrics.
  """

  require Logger

  @doc """
  Attaches telemetry handlers for Accrue billing events.
  """
  def setup do
    :telemetry.attach(
      "parapet-accrue-billing-processed",
      [:accrue, :billing, :processed],
      &__MODULE__.handle_event/4,
      nil
    )
```

**Safe Event Handling pattern** (lines 24-32):
```elixir
  @doc """
  Handles Accrue telemetry events safely and emits Parapet billing journey events.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )
  end
```

**Event Translation pattern** (lines 34-45):
```elixir
  defp process_event([:accrue, :billing, state], measurements, metadata)
       when state in [:processed, :failed] do
    outcome = if state == :processed, do: :success, else: :failure

    parapet_metadata = Map.put(metadata, :outcome, outcome)

    :telemetry.execute(
      [:parapet, :journey, :billing],
      measurements,
      parapet_metadata
    )
  end
```

---

### `lib/mix/tasks/parapet.gen.scoria.ex` (generator, file I/O)

**Analog:** `lib/mix/tasks/parapet.gen.prometheus.ex`

**Igniter Mix Task pattern** (lines 1-13):
```elixir
defmodule Mix.Tasks.Parapet.Gen.Prometheus do
  @moduledoc """
  Generates valid Prometheus recording and alerting rules based on the user's defined SLOs.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      defaults: []
    }
  end
```

**Template Evaluation and File Creation pattern** (lines 33-39):
```elixir
    template_path =
      Application.app_dir(:parapet, "priv/templates/parapet.gen.prometheus/rules.yml.eex")

    yaml_content = EEx.eval_file(template_path, slos: slos, windows: windows)

    Igniter.create_new_file(
      igniter,
      "priv/parapet/prometheus/rules.yml",
      yaml_content
    )
```

---

### `lib/mix/tasks/parapet.install.ex` (generator, file I/O)

**Analog:** `lib/mix/tasks/parapet.install.ex` (Existing code)

**Task Info with Flag pattern** (lines 14-17):
```elixir
    %Igniter.Mix.Task.Info{
      schema: [with_sigra: :boolean],
      defaults: [with_sigra: false]
    }
```

**Conditional Code Injection pattern** (lines 27-46):
```elixir
    with_sigra? = igniter.args.options[:with_sigra] || false

    setup_code =
      if with_sigra? do
        """
        def setup do
          if Code.ensure_loaded?(Parapet.Integrations.Sigra) do
            Parapet.Integrations.Sigra.setup()
          end
          :ok
        end
        """
      else
        """
        def setup do
          # Attach handlers here
          :ok
        end
        """
      end
```

## Shared Patterns

### Safe Telemetry Handling
**Source:** `lib/parapet/integrations/accrue.ex`
**Apply to:** All integration modules consuming events to ensure host application stability.
```elixir
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(...)
  end
```

### Igniter File Generators
**Source:** `lib/mix/tasks/parapet.gen.prometheus.ex`
**Apply to:** Code and configuration generators.
- Uses `Igniter.Mix.Task`
- `info/2` provides schema definitions
- `igniter/1` modifies project state and creates files

## Metadata

**Analog search scope:** `lib/parapet/integrations`, `lib/mix/tasks`
**Files scanned:** 4
**Pattern extraction date:** 2024-05-18
