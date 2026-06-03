# Phase 30: Registry Decoupling - Pattern Map

**Mapped:** 2026-06-03
**Files analyzed:** 5
**Analogs found:** 1 / 1

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/slo/registry.ex` | registry | CRUD | `lib/parapet/capabilities.ex` / Untracked `Registry` | exact |
| `lib/parapet/slo.ex` | interface | request-response | `lib/parapet/capabilities.ex` | role-match |
| `lib/parapet/slo/http.ex` | registration | request-response | `lib/parapet/capabilities.ex` | partial |
| `lib/parapet/slo/oban.ex` | registration | request-response | `lib/parapet/capabilities.ex` | partial |
| `test/parapet/slo_test.exs` | test | request-response | `test/parapet/capabilities_test.exs` | partial |

## Pattern Assignments

### `lib/parapet/slo/registry.ex` (registry, CRUD)

**Analog:** Untracked implementation of `lib/parapet/slo/registry.ex` and `lib/parapet/capabilities.ex`

The existing `.planning/threads/slo-state-off-application-env.md` recommends an ETS-backed GenServer for test isolation. A partial implementation already exists as an untracked file (`lib/parapet/slo/registry.ex`). It should be expanded to handle `providers` in addition to `slos`.

**State Management Pattern** (lines 3-7, 36-39 from `lib/parapet/slo/registry.ex`):
```elixir
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(__MODULE__, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end
```

**Test Isolation Pattern** (lines 46-54 from `lib/parapet/slo/registry.ex`):
```elixir
  def checkout do
    GenServer.call(__MODULE__, {:checkout, self()})
  end

  defp find_checkout_pid do
    pids = [self() | Process.get(:"$callers", [])]
    Enum.find(pids, fn pid ->
      case :ets.lookup(__MODULE__, {:checkout, pid}) do
        [{_, true}] -> true
        _ -> false
      end
    end)
  end
```

**Store/Provider Registration Pattern** (combining isolation with write access):
```elixir
  def store(slo) do
    pid = find_checkout_pid()
    key = if pid, do: {:test, pid, slo.name}, else: {:global, slo.name}
    :ets.insert(__MODULE__, {key, slo})
    :ok
  end
  
  def register_providers(providers) do
    pid = find_checkout_pid()
    key = if pid, do: {:test, pid, :providers}, else: {:global, :providers}
    :ets.insert(__MODULE__, {key, providers})
    :ok
  end
```

---

### `lib/parapet/slo.ex` (interface, request-response)

**Analog:** `lib/parapet/capabilities.ex`

**Lookup/Retrieval Pattern**:
```elixir
  def provider_catalog do
    Parapet.SLO.Registry.providers()
    |> Enum.flat_map(fn provider -> provider.slos() end)
  end
```

## Shared Patterns

### Test Isolation
**Source:** `lib/parapet/slo/registry.ex`
**Apply to:** `test/parapet/slo_test.exs` and `test/mix/tasks/parapet.gen.grafana_test.exs`
Instead of using `Application.put_env(:parapet, :providers, ...)`, tests should use `Parapet.SLO.Registry.checkout()` and `Parapet.SLO.Registry.register_providers([...])`. The `async: false` flags can be removed since state is partitioned per test PID.

```elixir
  setup do
    Parapet.SLO.Registry.checkout()
    :ok
  end
```

## Metadata

**Analog search scope:** `lib/parapet/capabilities.ex`, `lib/parapet/slo/registry.ex` (untracked)
**Files scanned:** 5
**Pattern extraction date:** 2026-06-03