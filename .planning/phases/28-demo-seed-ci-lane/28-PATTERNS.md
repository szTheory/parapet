# Phase 28: Demo Seed + CI Lane - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 7 (3 new, 4 modified)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` | config/declaration | transform | `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` | exact (rendered form of the template) |
| `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` | service/capability | request-response + CRUD | `test/parapet/recovery_test.exs` fixture modules (lines 5–43) | role-match (same 4-callback contract, minimal bodies replaced with real ones) |
| `examples/demo_app/test/demo_app/recovery_loop_test.exs` | test | request-response | `examples/demo_app/test/demo_app/operator_smoke_test.exs` | exact (same `@moduletag :smoke`, `use DemoAppWeb.ConnCase`, self-contained DB setup) |
| `examples/demo_app/lib/demo_app/application.ex` | config | request-response | self (current file, lines 7–17) | self-modification |
| `examples/demo_app/priv/repo/seeds.exs` | config/migration | CRUD | self (current file, incident blocks at lines 8–46, 63–81, 86–104) | self-modification |
| `examples/demo_app/mix.exs` | config | — | self (current file, `aliases/0` at lines 49–55) | self-modification |
| `.github/workflows/ci.yml` | config | — | self (lines 94–142, read-only verify) | self-read-only |

---

## Pattern Assignments

### `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` (config/declaration, transform)

**Analog:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex`

**Full rendered module** (all 36 lines — resolve `.eex` EEx bindings to the demo prefix):

```elixir
# priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex — rendered for DemoApp
defmodule DemoApp.Runbooks.StalledExecutor do
  use Parapet.Runbook

  title("Stalled Executor Recovery")
  description("Guidance and recovery actions for background jobs stuck in an executing state.")

  step(:investigate_logs,
    label: "Check Worker Logs",
    description: "Verify if the worker process crashed without reporting, or if it is currently deadlocked.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Search your APM for the worker executing this item. Look for crash reports, timeout events, or lock-acquisition failures around the item's last-attempt timestamp.",
    warning: "If logs show the item is still actively executing, do not retry — a concurrent retry will cause a duplicate execution race. Wait for the current attempt to complete or time out first."
  )

  step(:retry_item,
    label: "Retry Item",
    description: "Force the async item to be retried.",
    type: :mitigation,
    kind: :capability,
    capability: :retry_async_item,
    target_kind: :async_item,
    requires_preview: true,
    warning: "Retrying without identifying the root cause may reproduce the deadlock. Confirm the underlying resource or lock contention is resolved before proceeding."
  )

  step(:verify_recovery,
    label: "Verify Recovery",
    description: "Confirm the item completed successfully after the retry.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Check the item's status in the job backend — it should transition from executing or scheduled to completed. Verify in your APM that no new stall events have occurred for this item."
  )
end
```

**Notes for planner:**
- Replace `<%= inspect(@module_prefix) %>` with `DemoApp.Runbooks` — that is the only EEx substitution.
- The step id used in headless tests is `:retry_item` (the atom passed as the second argument to `preview_runbook_step/3` and `confirm_runbook_step/4`). Do NOT change the step id from the template; all four CI scenarios use `"retry_item"` as the `step_id` string.
- The `capability: :retry_async_item` field on the mitigation step is load-bearing — it must match the allowlisted atom exactly (`capabilities.ex:14-20`).

---

### `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` (service/capability, request-response + CRUD)

**Analog:** `test/parapet/recovery_test.exs` lines 5–11 (fixture shell) + `lib/parapet/recovery.ex` lines 30–56 (callback specs)

**Callback contract from analog** (`lib/parapet/recovery.ex:30-56`):

```elixir
@callback id() :: atom()
@callback label() :: String.t()
@callback preview(incident :: any(), step :: any()) :: {:ok, map()} | {:error, term()}
@callback execute(incident :: any(), target_refs :: any()) :: {:ok, map()} | {:error, term()}
```

**Minimal fixture shape from analog** (`test/parapet/recovery_test.exs:5-11`):

```elixir
defmodule Parapet.RecoveryTest.FixtureRetryAsync do
  use Parapet.Recovery
  def id, do: :retry_async_item
  def label, do: "Retry Async (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end
```

**Full production module shape** (from RESEARCH.md Pattern 4, sourced from `lib/parapet/recovery.ex` and `lib/parapet/operator.ex:820`):

```elixir
defmodule DemoApp.Recovery.RetryAsyncItem do
  use Parapet.Recovery

  @impl Parapet.Recovery
  def id, do: :retry_async_item

  @impl Parapet.Recovery
  def label, do: "Retry Async Item"

  @impl Parapet.Recovery
  def preview(incident, _step) do
    {:ok, %{
      count: 1,
      target_refs: [incident.id],
      preconditions: ["Item must be in 'executing' state"],
      warnings: ["Retrying without root cause analysis may reproduce the stall"],
      summary: "Force-retry the stalled async item linked to this incident"
    }}
  end

  @impl Parapet.Recovery
  def execute(incident, _target_refs) do
    import Ecto.Query
    {n, _} =
      DemoApp.Repo.update_all(
        from(a in Parapet.Spine.ActionItem,
          where: a.incident_id == ^incident.id and a.state == "open",
          limit: 1
        ),
        set: [state: "retrying"]
      )
    case n do
      n when n > 0 -> {:ok, %{retried_count: n}}
      0 -> {:ok, %{retried_count: 0, note: "no open items found"}}
    end
  end
end
```

**Notes for planner:**
- `preview/2` MUST return the documented 5-field map (`count`, `target_refs`, `preconditions`, `warnings`, `summary`) — these keys are consumed by `compute_preview/3` (`operator.ex:1003-1051`).
- `execute/2` contract is `{:ok, map()} | {:error, term()}` (`recovery.ex:56`); it is invoked as `capability.execute.(incident, preview_entry.target_refs)` (`operator.ex:820`).
- `DemoApp.Repo` is used directly (not via `Application.get_env(:parapet, :repo)`) — simpler for demo-only code, and the ExUnit sandbox shared mode propagates to callers of `DemoApp.Repo` within the test process span (RESEARCH.md Open Question #2).
- The `@impl Parapet.Recovery` annotations are the idiomatic Elixir behaviour pattern; the fixture analogs omit them for brevity but production code should include them.

---

### `examples/demo_app/test/demo_app/recovery_loop_test.exs` (test, request-response)

**Analog:** `examples/demo_app/test/demo_app/operator_smoke_test.exs` (all 23 lines)

**Module header + tag pattern from analog** (`operator_smoke_test.exs:1-4`):

```elixir
defmodule DemoApp.OperatorSmokeTest do
  use DemoAppWeb.ConnCase

  @moduletag :smoke
```

**Self-contained incident creation pattern from analog** (`operator_smoke_test.exs:11-21`):

```elixir
  test "at least one seeded incident exists" do
    # Insert an incident within the sandboxed connection so this test is
    # self-contained and does not depend on `mix run priv/repo/seeds.exs`
    # having populated the (separate, non-sandbox) dev DB (RESEARCH.md Pitfall 3).
    {:ok, _} =
      Parapet.Evidence.create_incident(%{
        title: "smoke test incident",
        state: "open"
      })

    assert DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count) > 0
  end
```

**Sandbox setup from ConnCase analog** (`test/support/conn_case.ex:20-28`):

```elixir
  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DemoApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DemoApp.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
```

**ActionPayload shape from LiveView analog** (`operator_detail_live.ex:103-131`):

```elixir
# Preview payload shape:
payload = %Parapet.Operator.ActionPayload{
  actor: "operator_ui",
  reason: "Previewed mitigation from UI",
  correlation_id: Ecto.UUID.generate(),
  action_type: :preview_mitigation
}

# Confirm payload shape (adds idempotency_key):
payload = %Parapet.Operator.ActionPayload{
  actor: "operator_ui",
  reason: "Confirmed mitigation from UI",
  correlation_id: Ecto.UUID.generate(),
  action_type: :execute_mitigation,
  idempotency_key: Ecto.UUID.generate()
}
```

**Full test module skeleton** (synthesized from analogs + RESEARCH.md Patterns 1–3 and 6):

```elixir
defmodule DemoApp.RecoveryLoopTest do
  use DemoAppWeb.ConnCase

  @moduletag :smoke

  setup do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "Stalled executor demo",
        state: "open",
        correlation_key: "stalled-executor-ci-#{System.unique_integer([:positive])}",
        runbook_data: %{
          "module" => to_string(DemoApp.Runbooks.StalledExecutor)
        }
      })

    {:ok, _action_item} =
      DemoApp.Repo.insert(%Parapet.Spine.ActionItem{
        id: Ecto.UUID.generate(),
        title: "async_job_#{System.unique_integer([:positive])}",
        integration: "demo",
        external_id: "ext-#{System.unique_integer([:positive])}",
        kind: "async_item",
        state: "open",
        incident_id: incident.id
      })

    %{incident: incident}
  end

  # --- Scenario 1: Happy path ---
  test "confirm executes capability and writes TimelineEntry + ToolAudit", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI happy-path preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)

    token = preview_result.preview["preview_token"]

    confirm_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI happy-path confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    assert {:ok, _} =
             Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload)

    import Ecto.Query

    assert DemoApp.Repo.exists?(
             from t in Parapet.Spine.TimelineEntry,
               where: t.incident_id == ^incident.id and t.type == "recovery_confirmed"
           )

    assert DemoApp.Repo.exists?(
             from a in Parapet.Spine.ToolAudit,
               where: a.tool_name == "operator_confirm_recovery"
           )
  end

  # --- Scenario 2: Expired preview ---
  test "expired preview returns {:short_circuited, :preview_expired}", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI expiry preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)

    token = preview_result.preview["preview_token"]

    # Age the preview entry's expires_at to 10 minutes in the past
    past_dt = DateTime.utc_now() |> DateTime.add(-600, :second) |> DateTime.to_iso8601()
    import Ecto.Query

    {1, _} =
      DemoApp.Repo.update_all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident.id and t.type == "recovery_preview"
        ),
        set: [payload: fragment("payload || ?::jsonb", ^%{"expires_at" => past_dt})]
      )

    confirm_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI expiry confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    assert {:short_circuited, :preview_expired} =
             Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload)
  end

  # --- Scenario 3: Resolved mid-flow ---
  test "resolved incident returns {:short_circuited, :incident_resolved}", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI resolved preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)

    token = preview_result.preview["preview_token"]

    import Ecto.Query

    DemoApp.Repo.update_all(
      from(i in Parapet.Spine.Incident, where: i.id == ^incident.id),
      set: [state: "resolved"]
    )

    confirm_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI resolved confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    assert {:short_circuited, :incident_resolved} =
             Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload)
  end

  # --- Scenario 4: Claim conflict (sequential) ---
  test "sequential second confirm returns {:conflicted, _}", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI conflict preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)

    token = preview_result.preview["preview_token"]

    confirm_payload_1 = %Parapet.Operator.ActionPayload{
      actor: "operator_a",
      reason: "First confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    confirm_payload_2 = %Parapet.Operator.ActionPayload{
      actor: "operator_b",
      reason: "Second confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()   # MUST differ from payload_1
    }

    result_1 = Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload_1)
    result_2 = Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload_2)

    assert {:ok, _} = result_1
    assert {:conflicted, _claim_id} = result_2
  end
end
```

**Notes for planner:**
- `use DemoAppWeb.ConnCase` gives sandbox checkout + shared mode automatically — do not add a separate `setup` for sandbox; the ConnCase `setup` runs first.
- All four scenarios create their own incident in `setup` via `Parapet.Evidence.create_incident/1` with `runbook_data["module"]`. Do NOT query seeded data — the test sandbox is isolated from the seeds DB (RESEARCH.md Pitfall 3).
- The `correlation_key` must be unique per test — use `System.unique_integer([:positive])` suffix to avoid the partial unique index collision (RESEARCH.md Pitfall 4).
- For the conflict scenario, `idempotency_key` MUST differ between the two confirm payloads (RESEARCH.md Pitfall 5). The conflict uniqueness is `(incident_id, action_kind="operator", action_key="retry_item")` — the `step_id` string, not `idempotency_key`.
- Do NOT use `Task.async` for the conflict scenario — spawned tasks do not share the sandbox connection (`DBConnection.OwnershipError`).
- Read the preview token from `preview_result.preview["preview_token"]` (the return value of `preview_runbook_step/3`). Do NOT call `WorkbenchContract.find_active_preview/1` — it is private and filters expired tokens.

---

### `examples/demo_app/lib/demo_app/application.ex` (config, request-response)

**Analog:** Self — current file `examples/demo_app/lib/demo_app/application.ex`

**Current `start/2` body** (lines 7–17 — the section being modified):

```elixir
  @impl true
  def start(_type, _args) do
    children = [
      DemoApp.Repo,
      DemoAppWeb.Telemetry,
      {Phoenix.PubSub, name: DemoApp.PubSub},
      DemoAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: DemoApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

**Target state after modification** (from RESEARCH.md Pattern 5, sourced from `lib/parapet/capabilities.ex:22-24` + `lib/parapet/recovery.ex:87-106`):

```elixir
  @impl true
  def start(_type, _args) do
    children = [
      DemoApp.Repo,
      DemoAppWeb.Telemetry,
      {Phoenix.PubSub, name: DemoApp.PubSub},
      Parapet.Capabilities,               # named singleton agent — must precede attach/1
      DemoAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: DemoApp.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)
    # Inline registration — simpler than a dedicated child; runs once at boot
    {:ok, _} = Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])
    {:ok, sup}
  end
```

**Notes for planner:**
- `Parapet.Capabilities` must appear in `children` BEFORE `Supervisor.start_link/2` is called, and `attach/1` must be called AFTER `start_link/2` returns. If the agent is not started before `attach/1`, `Agent.update(Parapet.Capabilities, ...)` raises `(exit) no process` (RESEARCH.md Pitfall 2).
- The `Supervisor.start_link/2` return must be captured in `{:ok, sup}` so it can be returned from `start/2`. The original one-liner `Supervisor.start_link(children, opts)` becomes two lines.
- `Parapet.Capabilities.start_link/1` signature (`capabilities.ex:22`): `def start_link(_opts)` — it registers itself as `__MODULE__` (the named singleton). Pass it bare (not as a tuple) in `children`.

---

### `examples/demo_app/priv/repo/seeds.exs` (config/migration, CRUD)

**Analog:** Self — current file `examples/demo_app/priv/repo/seeds.exs`

**Existing incident block pattern to mirror** (lines 8–46 — Incident 1, the most complete example with `runbook_data`):

```elixir
{:ok, incident_open} =
  Parapet.Evidence.create_incident(%{
    title: "Login service elevated error rate",
    description: "Auth endpoint returning 5xx > 2% for 10 consecutive minutes",
    state: "open",
    correlation_key: "login-error-rate-spike",
    runbook_data: %{
      "title" => "Login Failure Runbook",
      "description" => "Steps to diagnose and mitigate login service failures",
      "steps" => [...]
    }
  })
```

**Trailing count line to update** (line 118):

```elixir
IO.puts("Seeds complete: 3 incidents (open/investigating/resolved), 6 timeline entries, 1 tool audit")
```

**4th incident block to add** (capability-backed, with `runbook_data["module"]`):

```elixir
# ---------------------------------------------------------------------------
# Incident 4: OPEN — stalled async executor (capability-backed, Preview/Confirm)
# ---------------------------------------------------------------------------
{:ok, incident_stalled} =
  Parapet.Evidence.create_incident(%{
    title: "Stalled async executor",
    description: "Background job stuck in executing state for > 10 minutes",
    state: "open",
    correlation_key: "stalled-async-executor",
    runbook_data: %{
      "module" => to_string(DemoApp.Runbooks.StalledExecutor)
    }
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_stalled.id, %{
    type: "note",
    payload: %{"text" => "Job ID 8821 last heartbeat at 09:14 UTC — executor did not report completion"}
  })
```

**Updated trailing count line:**

```elixir
IO.puts("Seeds complete: 4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 tool audit")
```

**Notes for planner:**
- The `"module"` key value MUST be `to_string(DemoApp.Runbooks.StalledExecutor)` which produces `"Elixir.DemoApp.Runbooks.StalledExecutor"`. `extract_module/1` calls `String.to_existing_atom/1` on this value (`operator.ex:1097-1113`) — the module atom must exist at runtime (it will, because `mix run` loads the full app).
- Do NOT use inline `"steps"` list for this incident — that is a display-only path and breaks `preview_runbook_step/3` + `confirm_runbook_step/4` with `{:error, :missing_runbook}` (CONTEXT.md D-03, RESEARCH.md Pitfall 1).
- The `Application.put_env(:parapet, :repo, DemoApp.Repo)` at line 3 already handles repo config for standalone `mix run` — do not add a second call.

---

### `examples/demo_app/mix.exs` (config)

**Analog:** Self — current file `examples/demo_app/mix.exs`

**Existing `aliases/0` body** (lines 49–55):

```elixir
  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "assets.build": ["tailwind default", "esbuild demo_app"],
      "assets.deploy": ["tailwind default --minify", "esbuild demo_app --minify", "phx.digest"]
    ]
  end
```

**Target state after adding `demo.reset`** (CONTEXT.md D-10):

```elixir
  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "demo.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "assets.build": ["tailwind default", "esbuild demo_app"],
      "assets.deploy": ["tailwind default --minify", "esbuild demo_app --minify", "phx.digest"]
    ]
  end
```

**Notes for planner:**
- `demo.reset` intentionally starts with `ecto.drop` (unlike `setup` which starts with `deps.get`). Drop+recreate makes seed replayability free — seeds stay always-insert, relying on the drop to clear stale state (CONTEXT.md D-10).
- The `"run priv/repo/seeds.exs"` string is identical in both aliases — exact copy.

---

### `.github/workflows/ci.yml` (config — read-only verification)

**No edit needed.** Verified at lines 94–142.

**`demo` job** (lines 94–139 — confirm these steps already provision correctly for the four new scenarios):

```yaml
  demo:
    runs-on: ubuntu-latest
    needs: [lint, test]
    env:
      MIX_ENV: test
    services:
      postgres:
        image: postgres:16-alpine
        ...
    steps:
      - uses: actions/checkout@v4
      - name: Setup Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.19.0'
          otp-version: '27.2'
      - name: Install demo dependencies
        run: cd examples/demo_app && mix deps.get
      - name: Create and migrate demo database
        run: cd examples/demo_app && mix ecto.create && mix ecto.migrate
      - name: Seed demo database
        run: cd examples/demo_app && mix run priv/repo/seeds.exs
      - name: Run smoke test
        run: cd examples/demo_app && mix test --only smoke
```

**`release_gate` wiring** (lines 141–142 — confirms `demo` is a required gate):

```yaml
  release_gate:
    needs: [lint, test, demo]
```

**Planner confirmation:** The new `recovery_loop_test.exs` tests are tagged `@moduletag :smoke`, so `mix test --only smoke` (line 139) picks them up automatically. The seed step (line 137) verifies the 4th incident seed runs without error. `release_gate` already requires `demo`. No workflow edits are needed.

---

## Shared Patterns

### `use Parapet.Recovery` behaviour declaration
**Source:** `lib/parapet/recovery.ex:58-63`
**Apply to:** `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex`

```elixir
defmacro __using__(_opts) do
  quote do
    @behaviour Parapet.Recovery
  end
end
```

The `use Parapet.Recovery` macro injects `@behaviour Parapet.Recovery`. Add `@impl Parapet.Recovery` annotations on each callback for compile-time checking.

### Sandbox setup (shared mode, no async)
**Source:** `examples/demo_app/test/support/conn_case.ex:20-28`
**Apply to:** `examples/demo_app/test/demo_app/recovery_loop_test.exs`

```elixir
setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(DemoApp.Repo)

  unless tags[:async] do
    Ecto.Adapters.SQL.Sandbox.mode(DemoApp.Repo, {:shared, self()})
  end

  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

All new tests use `use DemoAppWeb.ConnCase` — this setup runs automatically per test.

### Token extraction from `preview_runbook_step/3` return
**Source:** `lib/parapet/operator.ex:706` (verified in RESEARCH.md Pattern 1)
**Apply to:** All four scenarios in `recovery_loop_test.exs`

```elixir
{:ok, preview_result} =
  Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)
token = preview_result.preview["preview_token"]
```

The `:preview` key in the return value holds the full computed preview map. Do NOT query the DB for the token — `WorkbenchContract.find_active_preview/1` is private and filters expired entries.

### `Parapet.Evidence.create_incident/1` in test setup
**Source:** `examples/demo_app/test/demo_app/operator_smoke_test.exs:14-20`
**Apply to:** `examples/demo_app/test/demo_app/recovery_loop_test.exs` setup block

```elixir
{:ok, _} =
  Parapet.Evidence.create_incident(%{
    title: "smoke test incident",
    state: "open"
  })
```

Each test creates its own incident in the sandbox. Never rely on seeded data (seeds populate a separate non-sandbox DB context).

---

## No Analog Found

None — all seven files have close analogs in the codebase.

---

## Metadata

**Analog search scope:** `lib/parapet/`, `examples/demo_app/`, `test/parapet/`, `priv/templates/`, `.github/workflows/`
**Files scanned:** 10
**Pattern extraction date:** 2026-05-28
