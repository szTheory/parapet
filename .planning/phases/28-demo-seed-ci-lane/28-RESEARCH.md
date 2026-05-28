# Phase 28: Demo Seed + CI Lane - Research

**Researched:** 2026-05-28
**Domain:** Elixir/Phoenix/Ecto — demo app wiring (capability registration, runbook module, seed, headless ExUnit CI scenarios)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Author two new compiled modules: `DemoApp.Runbooks.StalledExecutor` (`use Parapet.Runbook`) and `DemoApp.Recovery.RetryAsyncItem` (`use Parapet.Recovery`).
- **D-02:** Reuse frozen-allowlist atom `:retry_async_item` — no new capability id.
- **D-03:** Seeded incident `runbook_data` MUST set `"module"` key pointing at `DemoApp.Runbooks.StalledExecutor`.
- **D-04:** `execute/2` mutates demo DB state via `Parapet.Spine.ActionItem` (no new migration).
- **D-05:** Four scenarios as headless ExUnit in `examples/demo_app/test/demo_app/recovery_loop_test.exs`, tagged `:smoke`. No `Phoenix.LiveViewTest`, no Wallaby.
- **D-06:** Expired-preview scenario: age `expires_at` past now, assert `{:short_circuited, :preview_expired}`. Mechanism TBD by plan-phase (research provides concrete recommendation below).
- **D-07:** CI `demo` job continuity satisfied by existing wiring; plan-phase verifies provisioning is sufficient.
- **D-08:** Claim-conflict is sequential (not wall-clock race). Core's `ConcurrencyCase` harness is unavailable to the demo project.
- **D-09:** Start `Parapet.Capabilities` in `DemoApp.Application.start/1` AND call `Parapet.Recovery.attach/1` at boot.
- **D-10:** `mix demo.reset` = `ecto.drop + ecto.create + ecto.migrate + run priv/repo/seeds.exs`.
- **D-11:** Add capability-backed incident as new seed block in `examples/demo_app/priv/repo/seeds.exs`.

### Claude's Discretion

- Exact step ids / labels / descriptions / `target_kind` value, and `preview/2` + `execute/2` bodies.
- Time-injection mechanism for expired-preview scenario.
- Whether boot-time registration is inline after `Supervisor.start_link/2` or a dedicated child.
- Whether four scenarios are in one file or split.
- Whether `execute/2` inserts a fresh `ActionItem` or flips an existing seeded one.

### Deferred Ideas (OUT OF SCOPE)

- Genuinely concurrent two-connection claim race (second non-sandboxed demo Repo).
- `mix parapet.gen.recovery <NAME>` Igniter scaffolder (Phase 29).
- `mix parapet.doctor` recovery-action adoption signal (Phase 29).
- `docs/recovery-actions.md` adopter guide (Phase 29).
- `Parapet.Recovery` Experimental → Stable graduation (Phase 29).
- New runbook templates / template renames.
- Browser/Wallaby E2E.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-05 | Demo app seeded with at least one capability-backed incident exposing Preview-able + Confirm-able action; seed runs as part of `mix setup` on fresh clone | D-01 through D-04, D-09 through D-11 wiring; seed structure confirmed; `setup` alias at `mix.exs:51` already runs seeds |
| DEMO-06 | CI demo lane exercises four scenarios; failures break the build | D-05 through D-08; `:smoke` tag + `mix test --only smoke` at `ci.yml:139` already wired; `release_gate` at `ci.yml:141-142` already requires `demo` |
</phase_requirements>

---

## Summary

Phase 28 wires the Parapet recovery loop end-to-end inside the demo app and contract-tests it in CI. All load-bearing primitives (`Parapet.Operator.preview_runbook_step/3`, `confirm_runbook_step/4`, `Parapet.Capabilities` agent, `Parapet.Recovery.attach/1`, `ClaimService`, the frozen return-tuple contract) already exist from Phases 23–27. This phase adds the missing demo-side pieces: a `use Parapet.Recovery` capability module, a `use Parapet.Runbook` runbook module, a capability-backed seeded incident, boot-time agent registration, four headless `:smoke`-tagged ExUnit scenarios, `mix demo.reset`, and the CI verification that the new tests satisfy the release gate.

The most important discovery from direct code inspection is **how to read the preview token back in tests**: `preview_runbook_step/3` already returns `{:ok, Map.put(result, :preview, preview_data)}` where `preview_data` is the full computed preview map including `"preview_token"`. The test can extract the token directly from the preview call's return value — no secondary DB query, no `WorkbenchContract.derive/3` call needed. `WorkbenchContract.find_active_preview/1` is a private function; it is not a valid test surface.

The expired-preview scenario (D-06) is also resolved: the preview expiry check at `operator.ex:767-769` reads `DateTime.compare(preview_entry.expires_at, DateTime.utc_now()) != :gt`. The `preview_entry.expires_at` is parsed directly from the `recovery_preview` timeline entry's `payload["expires_at"]` field (`find_recent_preview/3` at `operator.ex:1053-1094`). The correct injection mechanism is to directly update the `TimelineEntry`'s `payload["expires_at"]` to a past datetime using `DemoApp.Repo.update_all` — no `now:` clock option exists in `confirm_runbook_step/4`.

**Primary recommendation:** Use `DemoAppWeb.ConnCase` for all four scenarios (shared sandbox, single connection, no async). Read the preview token from the `{:ok, result}` map of `preview_runbook_step/3`. Age the preview by updating the `TimelineEntry` payload directly. Drive claim-conflict sequentially: preview once, confirm twice, assert first is `{:ok, _}` and second is `{:conflicted, _}`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Capability registration | Demo app boot (Application) | — | Named singleton must answer before any request or test; boot is the only safe registration point |
| Recovery capability impl | Demo lib (`DemoApp.Recovery.RetryAsyncItem`) | — | Host-owned behaviour; lives in demo lib, not core |
| Runbook module | Demo lib (`DemoApp.Runbooks.StalledExecutor`) | — | Compiled runbook module; `extract_module/1` requires an existing atom |
| Seed (incident + capability reference) | Demo priv/repo/seeds.exs | — | Runs under `mix setup` and `mix demo.reset` |
| Headless CI scenarios | Demo test (`recovery_loop_test.exs`) | CI `demo` job | Four ExUnit scenarios; CI job already provisions DB + runs `mix test --only smoke` |
| `mix demo.reset` | Demo mix.exs aliases | — | Mirrors `setup` alias; adds `ecto.drop` at front |
| Release gate wiring | `.github/workflows/ci.yml` | — | `release_gate` already `needs: [lint, test, demo]`; plan confirms no edits needed |

---

## Standard Stack

No new external packages. All tooling already in the demo's `mix.exs`.

### Core (all already in project)

| Module / API | Location | Purpose |
|---|---|---|
| `Parapet.Recovery` behaviour + `attach/1` | `lib/parapet/recovery.ex` | 4-callback `use Parapet.Recovery`, registration entry point |
| `Parapet.Capabilities` Agent | `lib/parapet/capabilities.ex` | Named singleton registry; `start_link/1` + `register_recovery/2` + `get_recovery/1` |
| `Parapet.Operator.preview_runbook_step/3` | `lib/parapet/operator.ex:670` | Writes `recovery_preview` timeline entry; returns `{:ok, map_with_preview_key}` |
| `Parapet.Operator.confirm_runbook_step/4` | `lib/parapet/operator.ex:749` | Returns `{:ok,_}` \| `{:short_circuited, reason}` \| `{:conflicted, claim_id}` \| `{:error,_}` |
| `Parapet.Operator.ActionPayload` | `lib/parapet/operator/action_payload.ex` | Struct: `actor`, `reason`, `correlation_id`, `action_type`, `idempotency_key` |
| `Parapet.Evidence.create_incident/1` | Parapet core | Creates incident; `correlation_key` partial-unique on open incidents |
| `Parapet.Spine.ActionItem` | Parapet core migrations | Existing table (`parapet_action_items`): `id`, `title`, `integration`, `external_id`, `kind`, `state`, `incident_id` |
| `Parapet.Spine.TimelineEntry` | Parapet core | Existing table; `payload` is jsonb; `type: "recovery_preview"` |
| `DemoAppWeb.ConnCase` | `examples/demo_app/test/support/conn_case.ex` | Sandbox checkout + shared mode; all new tests use this |
| `Ecto.Adapters.SQL.Sandbox` | Ecto | Manual mode in `test_helper.exs`; shared per test via `ConnCase.setup` |

**Installation:** None required — zero new dependencies.

---

## Package Legitimacy Audit

No new packages are installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
Application.start/1
  └─ Supervisor.start_link([DemoApp.Repo, ..., Parapet.Capabilities, ...])
       └─ Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])
            └─ Parapet.Capabilities.register_recovery(:retry_async_item, ...)

mix setup / mix demo.reset
  └─ seeds.exs
       └─ Parapet.Evidence.create_incident(%{runbook_data: %{"module" => "DemoApp.Runbooks.StalledExecutor", ...}})

ExUnit test (recovery_loop_test.exs, :smoke tag)
  ├─ [setup] DemoAppWeb.ConnCase → Ecto.Sandbox.checkout + shared mode
  │    └─ create_incident (runbook_data["module"] = StalledExecutor)
  │    └─ Parapet.Evidence.insert_action_item (for execute/2 to flip)
  │
  ├─ Scenario 1 (happy path)
  │    preview_runbook_step → {:ok, %{preview: %{"preview_token" => token, ...}}}
  │    confirm_runbook_step(incident, :retry_item, token, confirm_payload)
  │    → {:ok, _}
  │    assert TimelineEntry type="recovery_confirmed" exists
  │    assert ToolAudit row exists
  │
  ├─ Scenario 2 (expired preview)
  │    preview_runbook_step → {:ok, %{preview: %{"preview_token" => token, ...}}}
  │    Repo.update_all(TimelineEntry payload["expires_at"] = past datetime)
  │    confirm_runbook_step → {:short_circuited, :preview_expired}
  │
  ├─ Scenario 3 (resolved mid-flow)
  │    preview_runbook_step → {:ok, %{preview: %{"preview_token" => token, ...}}}
  │    Repo.update_all(Incident, set: [state: "resolved"])
  │    confirm_runbook_step → {:short_circuited, :incident_resolved}
  │
  └─ Scenario 4 (claim conflict)
       preview_runbook_step → {:ok, %{preview: %{"preview_token" => token, ...}}}
       confirm_runbook_step #1 → {:ok, _}   (wins the claim)
       confirm_runbook_step #2 (same token, new idempotency_key) → {:conflicted, claim_id}

CI demo job (ci.yml:94-139)
  └─ ecto.create && ecto.migrate → mix run seeds.exs → mix test --only smoke
       └─ release_gate needs: [lint, test, demo]
```

### Recommended Project Structure

```
examples/demo_app/
├── lib/demo_app/
│   ├── application.ex          # ADD: Parapet.Capabilities child + attach call
│   ├── recovery/
│   │   └── retry_async_item.ex # NEW: use Parapet.Recovery — 4 callbacks
│   └── runbooks/
│       └── stalled_executor.ex # NEW: use Parapet.Runbook — 3-step shape
├── priv/repo/seeds.exs         # ADD: 4th incident block with runbook_data["module"]
├── mix.exs                     # ADD: demo.reset alias
└── test/demo_app/
    └── recovery_loop_test.exs  # NEW: @moduletag :smoke, 4 scenarios
```

### Pattern 1: Token Extraction from `preview_runbook_step/3` Return

**What:** The preview call returns the preview map — including `"preview_token"` — directly in its return value. No secondary DB query needed.

**When to use:** Always. This is the only public surface. `WorkbenchContract.find_active_preview/1` is a private helper.

```elixir
# Source: lib/parapet/operator.ex:706 (verified by direct read)
preview_payload = %ActionPayload{
  actor: "ci_operator",
  reason: "CI scenario preview",
  correlation_id: Ecto.UUID.generate(),
  action_type: :preview_mitigation
}

{:ok, result} = Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)
token = result.preview["preview_token"]
# result.preview is the full compute_preview/3 map with all documented fields
```

### Pattern 2: Expired-Preview Time Injection

**What:** Age the `recovery_preview` timeline entry's `payload["expires_at"]` to a past value using `Repo.update_all` with a jsonb set. `confirm_runbook_step/4` reads `expires_at` from the timeline payload via `find_recent_preview/3` — there is no `now:` clock override option.

**When to use:** Expired-preview scenario only (Scenario 2).

```elixir
# Source: lib/parapet/operator.ex:1053-1094 (find_recent_preview/3 confirmed by direct read)
# The expiry gate reads payload["expires_at"] from the TimelineEntry row.
# Direct mutation is the correct injection mechanism.
import Ecto.Query

past_dt = DateTime.utc_now() |> DateTime.add(-600, :second) |> DateTime.to_iso8601()

from(t in Parapet.Spine.TimelineEntry,
  where: t.incident_id == ^incident.id and t.type == "recovery_preview"
)
|> DemoApp.Repo.update_all(set: [payload: fragment("payload || ?::jsonb", ^%{"expires_at" => past_dt})])
```

**Note:** `find_recent_preview/3` parses `payload["expires_at"]` from either a `%DateTime{}` struct or an ISO 8601 binary (confirmed `operator.ex:1073-1083`). Writing an ISO 8601 string is safe.

### Pattern 3: Sequential Claim-Conflict

**What:** Call `confirm_runbook_step/4` twice against the same `(incident_id, action_kind, action_key)` after a valid preview. The first call wins; the second hits the `on_conflict: :nothing` unique constraint deterministically.

**When to use:** Claim-conflict scenario (Scenario 4).

```elixir
# Source: lib/parapet/automation/claim_service.ex:107-110,126-133 (cited in CONTEXT.md D-08)
confirm_payload_1 = %ActionPayload{
  actor: "operator_a",
  reason: "First confirm",
  correlation_id: Ecto.UUID.generate(),
  action_type: :execute_mitigation,
  idempotency_key: Ecto.UUID.generate()
}
confirm_payload_2 = %ActionPayload{
  actor: "operator_b",
  reason: "Second confirm",
  correlation_id: Ecto.UUID.generate(),
  action_type: :execute_mitigation,
  idempotency_key: Ecto.UUID.generate()  # MUST be different from payload_1
}

result_1 = Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload_1)
result_2 = Parapet.Operator.confirm_runbook_step(incident, "retry_item", token, confirm_payload_2)

assert {:ok, _} = result_1
assert {:conflicted, _claim_id} = result_2
```

**Important:** The `action_key` is derived from `step_id_atom` (`to_string(step_id_atom)`) inside `confirm_runbook_step/4` — the conflict uniqueness is `(incident_id, action_kind="operator", action_key="retry_item")`. Both callers use the same `step_id` so the constraint fires on the second insert.

### Pattern 4: `DemoApp.Recovery.RetryAsyncItem` Module Shape

**What:** Near-copy of the `Parapet.Recovery` 4-callback contract. `preview/2` returns the 5-field documented map. `execute/2` mutates a `Parapet.Spine.ActionItem` row.

```elixir
# Source: lib/parapet/recovery.ex (all 4 @callback specs, verified by direct read)
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
    # Flip an ActionItem linked to this incident from "open" to "retrying"
    import Ecto.Query
    Application.get_env(:parapet, :repo)
    |> then(fn repo ->
      from(a in Parapet.Spine.ActionItem,
        where: a.incident_id == ^incident.id and a.state == "open",
        limit: 1
      )
      |> repo.update_all(set: [state: "retrying"])
    end)
    |> case do
      {n, _} when n > 0 -> {:ok, %{retried_count: n}}
      {0, _} -> {:ok, %{retried_count: 0, note: "no open items found"}}
    end
  end
end
```

**Note on repo access in execute/2:** `Application.get_env(:parapet, :repo)` mirrors how `seeds.exs:3` and `config/config.exs:3-5` configure `DemoApp.Repo` as the Parapet repo. Both the dev/test env and CI have this set. Alternatively, call `DemoApp.Repo` directly since `execute/2` is demo-only code.

### Pattern 5: `DemoApp.Application` Boot Wiring

**What:** Add `Parapet.Capabilities` as a supervision child before `attach/1` is called.

```elixir
# Source: lib/parapet/capabilities.ex:22-24 (start_link/1 verified by direct read)
# Source: lib/parapet/recovery.ex:87-106 (attach/1 verified by direct read)
def start(_type, _args) do
  children = [
    DemoApp.Repo,
    DemoAppWeb.Telemetry,
    {Phoenix.PubSub, name: DemoApp.PubSub},
    Parapet.Capabilities,          # ADD: named singleton agent
    DemoAppWeb.Endpoint
  ]

  opts = [strategy: :one_for_one, name: DemoApp.Supervisor]
  {:ok, sup} = Supervisor.start_link(children, opts)
  # inline registration — simpler than a dedicated child
  {:ok, _} = Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])
  {:ok, sup}
end
```

**Important:** `Parapet.Capabilities` must be in `children` before `attach/1` is called — `attach/1` calls `register_recovery/2` which calls `Agent.update(__MODULE__, ...)` synchronously. If the agent is not started, this crashes.

### Pattern 6: Test Case Setup for `recovery_loop_test.exs`

**What:** Use `DemoAppWeb.ConnCase` (not `ExUnit.Case` directly) to get the Ecto sandbox in shared mode for each test. Create a fresh capability-backed incident in each test — do NOT rely on seeded data (seeds run in the dev/non-sandbox DB; test sandbox is isolated, matching the pattern at `operator_smoke_test.exs:11-21`).

```elixir
# Source: examples/demo_app/test/demo_app/operator_smoke_test.exs:1-23 (verified by direct read)
# Source: examples/demo_app/test/support/conn_case.ex:1-29 (verified by direct read)
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

    # Insert an ActionItem for execute/2 to operate on
    {:ok, action_item} =
      DemoApp.Repo.insert(%Parapet.Spine.ActionItem{
        id: Ecto.UUID.generate(),
        title: "async_job_#{System.unique_integer([:positive])}",
        integration: "demo",
        external_id: "ext-#{System.unique_integer([:positive])}",
        kind: "async_item",
        state: "open",
        incident_id: incident.id
      })

    %{incident: incident, action_item: action_item}
  end
  # ...
end
```

**Why `correlation_key` must be unique per test:** `Parapet.Evidence.create_incident/1` enforces a partial unique index on `correlation_key` where `state != 'resolved'` (confirmed `concurrency_bootstrap.ex:46-48`). Re-using a fixed key across concurrent tests would collide. Use `System.unique_integer/1` or omit `correlation_key` entirely.

### Anti-Patterns to Avoid

- **Reading the token via `WorkbenchContract.find_active_preview/1`:** That is a private function. It filters out expired tokens, so it cannot be used for the expired-preview scenario anyway. Extract the token from the `preview_runbook_step/3` return value.
- **Registering the capability only in `seeds.exs`:** Seeds run in the dev DB context; the test process starts the application (which runs `Application.start/2`), but if `Parapet.Capabilities` is not in the supervision tree, `attach/1` will crash. Register in `Application.start/2`.
- **Reusing a fixed `idempotency_key` across Confirm calls in the conflict scenario:** The `idempotency_key` must differ between the two confirm calls (different "operators"). The `action_key` is the `step_id` string, not the `idempotency_key` — the conflict uniqueness is `(incident_id, action_kind, action_key)`.
- **Using `Task.async` for the conflict scenario:** The sandbox is shared on the test PID; spawned tasks do not share the sandbox connection, causing `DBConnection.OwnershipError`. Drive conflict sequentially.
- **Using `String.to_atom/1` for module resolution:** `extract_module/1` uses `String.to_existing_atom/1`. The runbook module atom must already exist (i.e., the module must be compiled and loaded). In a running test process the module is loaded because it's in `elixirc_paths`. `seeds.exs` also works because `mix run` loads the full app.
- **Inline `"steps"` seed for the Preview/Confirm incident:** The operator API resolves steps from the compiled runbook module, not from inline `"steps"` in `runbook_data`. Only the `"module"` key enables Preview/Confirm.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token read-back after preview | DB query for `recovery_preview` timeline entry | Return value of `preview_runbook_step/3` (`:preview` key) | Already in return value; DB query is fragile to sandbox state |
| Clock injection for expiry | `now:` opt patch to core | Direct `Repo.update_all` on `TimelineEntry.payload["expires_at"]` | Core has no clock option; direct mutation is 3 lines in the sandbox |
| Concurrent claim race | Second non-sandboxed repo in demo test env | Sequential double-confirm | Same contract path; sandbox is single-connection; no concurrency harness in demo |
| Capability registration | Custom Agent, `Application.put_env` | `Parapet.Capabilities` + `Parapet.Recovery.attach/1` | Already ships; putting capabilities in `Application.put_env` repeats the v0.10 mistake |

**Key insight:** All four scenarios map cleanly to pure `Parapet.Operator` API calls with direct Ecto sandbox mutations for state setup — no browser driver, no PubSub watcher, no second repo needed.

---

## Common Pitfalls

### Pitfall 1: Seeded Incident Uses Inline `"steps"` Instead of `"module"` Key

**What goes wrong:** `extract_module/1` returns `{:error, :missing_runbook}`; `preview_runbook_step/3` and `confirm_runbook_step/4` both fail with `{:error, :missing_runbook}`. All four CI scenarios fail immediately.

**Why it happens:** The existing three seed incidents use inline `"steps"` lists, which is a display-only path. Preview/Confirm requires a compiled module reference.

**How to avoid:** The 4th seed incident's `runbook_data` must be `%{"module" => "Elixir.DemoApp.Runbooks.StalledExecutor"}` (or `to_string(DemoApp.Runbooks.StalledExecutor)` which produces the same string).

**Warning signs:** `{:error, :missing_runbook}` from any `preview_runbook_step/3` call.

### Pitfall 2: `Parapet.Capabilities` Agent Not Started Before `attach/1`

**What goes wrong:** `attach/1` calls `register_recovery/2` which calls `Agent.update(Parapet.Capabilities, ...)`. If the agent process doesn't exist, this raises `(exit) no process: the process is not alive or there's no process currently associated with the given name`.

**Why it happens:** `Parapet.Capabilities` must be a supervision child before `attach/1` is called.

**How to avoid:** List `Parapet.Capabilities` in the `children` list in `Application.start/2` before calling `attach/1`.

**Warning signs:** Boot crash in either `mix phx.server` or `mix test --only smoke`.

### Pitfall 3: Tests Rely on Seed Data (Wrong DB)

**What goes wrong:** Seeded incidents exist in the dev/test DB at the process level, but ExUnit sandbox starts each test with a clean transaction. `DemoApp.Repo.get!` or `Parapet.Evidence` queries against the seeded data return `nil` or raise.

**Why it happens:** `operator_smoke_test.exs` comment at line 13-14 explicitly documents this: sandbox is isolated from the seeds DB.

**How to avoid:** Create incidents and `ActionItem` rows inside the `setup` block of each test using the sandboxed Repo. CONTEXT.md's D-05 says "Each scenario builds a `%ActionPayload{}`" — each scenario must also create its own incident.

**Warning signs:** `Ecto.NoResultsError` or `nil` incident in `confirm_runbook_step/4`.

### Pitfall 4: `correlation_key` Collision Across Tests

**What goes wrong:** If two test cases share the same `correlation_key` on an open incident, `Parapet.Evidence.create_incident/1` raises a unique-constraint error because of the partial index on `(correlation_key)` where `state != 'resolved'`.

**Why it happens:** The partial unique index prevents duplicate open incidents (confirmed `concurrency_bootstrap.ex:46-48`).

**How to avoid:** Either omit `correlation_key` from test incidents or use `"stalled-executor-#{System.unique_integer([:positive])}"`.

### Pitfall 5: `idempotency_key` Same for Both Confirm Calls in Conflict Scenario

**What goes wrong:** If both confirm calls share the same `idempotency_key`, the second may be deduplicated rather than conflicted, returning `{:ok, _}` instead of `{:conflicted, _}`.

**Why it happens:** The `idempotency_key` is stored on the claim and may trigger early-return deduplication.

**How to avoid:** Use `Ecto.UUID.generate()` for each confirm payload independently.

### Pitfall 6: `find_active_preview/1` Filters Expired Tokens

**What goes wrong:** If the test tries to use `WorkbenchContract.derive/3` to read the active preview after aging it, the result will have `active_preview: nil` — the private `find_active_preview/1` filters expired entries (`workbench_contract.ex:197`). The test cannot use this surface to verify the token was properly expired.

**Why it happens:** `find_active_preview/1` is designed to only show non-expired previews to the UI.

**How to avoid:** Read the token from `preview_runbook_step/3` return value before aging, then age the row. The expired-preview scenario only needs the token to be stale when `confirm_runbook_step/4` is called.

---

## Code Examples

### Full Happy-Path Scenario Shape

```elixir
# Source: lib/parapet/operator.ex:706, :857-885 (verified by direct read)
test "happy-path: Confirm writes TimelineEntry + ToolAudit", %{incident: incident} do
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

  # TimelineEntry assertion
  import Ecto.Query
  assert DemoApp.Repo.exists?(
    from t in Parapet.Spine.TimelineEntry,
    where: t.incident_id == ^incident.id and t.type == "recovery_confirmed"
  )

  # ToolAudit assertion
  assert DemoApp.Repo.exists?(
    from a in Parapet.Spine.ToolAudit,
    where: a.tool_name == "operator_confirm_recovery"
  )
end
```

### Expired-Preview Scenario Shape

```elixir
# Source: lib/parapet/operator.ex:767-769, 1053-1083 (verified by direct read)
test "expired preview: confirm returns {:short_circuited, :preview_expired}", %{incident: incident} do
  preview_payload = %Parapet.Operator.ActionPayload{
    actor: "ci_operator",
    reason: "CI expiry preview",
    correlation_id: Ecto.UUID.generate(),
    action_type: :preview_mitigation
  }

  {:ok, preview_result} =
    Parapet.Operator.preview_runbook_step(incident, "retry_item", preview_payload)

  token = preview_result.preview["preview_token"]

  # Age the preview — write ISO 8601 string (find_recent_preview parses both DateTime and binary)
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
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-----------------|--------------|--------|
| Inline `"steps"` seed (display-only) | `"module"` key pointing at compiled runbook | Phase 25/28 | Seeds must use module reference for Preview/Confirm |
| Manual concurrency harness (core `ConcurrencyCase`) | Sequential double-confirm for conflict testing | Phase 28 design | Demo project does not ship core test support; sequential is correct for SQL sandbox |
| Seeds-only capability registration | Boot-time `Application.start/2` `attach/1` | Phase 28 design | Single registration serves both server + all test processes |

**Deprecated/outdated:**
- Inline `"steps"` in `runbook_data` for capability-backed incidents: only works for display; does not support `preview_runbook_step/3` or `confirm_runbook_step/4`.

---

## CI Provisioning Verification (D-07)

The existing CI `demo` job at `.github/workflows/ci.yml:94-139` runs:

1. `mix ecto.create && mix ecto.migrate` (line 135) — creates `demo_app_test` DB with full schema
2. `mix run priv/repo/seeds.exs` (line 137) — runs seeds in dev context
3. `mix test --only smoke` (line 139) — runs sandboxed tests

**Gap identified:** Step 2 (seeds) runs against the non-sandboxed DB. The new `recovery_loop_test.exs` follows `operator_smoke_test.exs` pattern of creating its own incidents in the sandbox — it does NOT depend on seeded data. This means the `mix run priv/repo/seeds.exs` step in CI is not required for the four new scenarios to pass, but it is required to verify that the seed itself works (success criterion #4 about `mix demo.reset`).

**Conclusion:** No CI job edits are needed. The four scenarios self-provision inside the sandbox. The seed step already verifies DEMO-05 seed correctness. `release_gate` already wires `demo` as a required check.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Parapet.Spine.ToolAudit` table name is `parapet_tool_audits` and is queryable via `DemoApp.Repo` in tests | Code Examples, Validation Architecture | Happy-path assertion fails; adjust the query alias |
| A2 | `fragment("payload || ?::jsonb", ^map)` is valid PostgreSQL jsonb merge syntax for Ecto in the demo test env (PostgreSQL 16, as per ci.yml) | Code Examples (expired-preview shape) | Expiry injection query fails; alternative is to insert a new TimelineEntry row with the expired token instead |
| A3 | `execute/2` calling `DemoApp.Repo` directly (or via `Application.get_env(:parapet, :repo)`) works inside the ExUnit sandbox because the sandbox shared mode propagates to any process started by the test PID | Pattern 4 (execute/2 body) | `execute/2` uses a different repo connection that is not in the sandbox; flip to no-op test-only approach |

**If this table were empty:** All claims verified by direct code read. A1-A3 involve schema/DB details not fully traced to a schema file in this session.

---

## Open Questions

1. **`Parapet.Spine.ToolAudit` alias for direct Repo query in tests**
   - What we know: `ToolAudit` rows are written by `Evidence.run_operator_command/1` on the happy path (`operator.ex:881-885`). The table exists (referenced from test support files implicitly).
   - What's unclear: The exact module alias and whether it's directly Repo-queryable without going through `Evidence`.
   - Recommendation: Query `Parapet.Spine.ToolAudit` directly via `DemoApp.Repo` in the assertion — if the alias doesn't exist, query `Evidence.repo().all(from t in "parapet_tool_audits", ...)` as a fallback. Planner should verify with `grep -r "ToolAudit" lib/parapet/spine/` before writing the assertion.

2. **`execute/2` repo access pattern**
   - What we know: `DemoApp.Repo` is registered as `:parapet` repo via `config.exs:3-5`. `execute/2` runs inside the confirmed LiveView handler context.
   - What's unclear: In the ExUnit sandbox with `shared` mode, whether `execute/2` code that calls `DemoApp.Repo` directly (not the test process) gets the sandbox connection properly.
   - Recommendation: Reference `DemoApp.Repo` directly in `execute/2` — this is the same module the test sandbox is checked out against, and shared mode propagates to processes that call into the same Repo within the test process's span.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| PostgreSQL | All four ExUnit scenarios, seeds | CI: postgres:16-alpine service; local: assumed | 16 (CI) | — |
| Elixir 1.19 / OTP 27.2 | Demo app (`mix.exs: elixir "~> 1.19"`) | CI: setup-beam configured | 1.19.0 / 27.2 (CI) | — |
| Parapet core (path dep) | `examples/demo_app/deps: {:parapet, path: "../.."}` | Always | local path | — |

**Missing dependencies with no fallback:** None identified.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir standard, no version pin needed) |
| Config file | `examples/demo_app/test/test_helper.exs` (sets sandbox manual mode) |
| Quick run command | `cd examples/demo_app && mix test --only smoke` |
| Full suite command | `cd examples/demo_app && mix test --only smoke` (demo tests are all `:smoke`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEMO-05 | Seeded capability-backed incident navigable via operator UI on fresh clone | smoke (seed verification in CI step + manual browser UAT) | `cd examples/demo_app && mix run priv/repo/seeds.exs` (CI step; exits 0 iff seed succeeds) | ❌ Wave 0: new seed block in `seeds.exs` |
| DEMO-05 | `mix demo.reset` replays seed without error | smoke | `cd examples/demo_app && mix demo.reset` (manual / post-phase verification) | ❌ Wave 0: new alias in `mix.exs` |
| DEMO-06 | Happy-path Confirm produces `{:ok,_}` + `recovery_confirmed` TimelineEntry + ToolAudit | unit/smoke | `cd examples/demo_app && mix test --only smoke` | ❌ Wave 0: `test/demo_app/recovery_loop_test.exs` |
| DEMO-06 | Expired preview returns `{:short_circuited, :preview_expired}` | unit/smoke | `cd examples/demo_app && mix test --only smoke` | ❌ Wave 0: `test/demo_app/recovery_loop_test.exs` |
| DEMO-06 | Resolved mid-flow returns `{:short_circuited, :incident_resolved}` | unit/smoke | `cd examples/demo_app && mix test --only smoke` | ❌ Wave 0: `test/demo_app/recovery_loop_test.exs` |
| DEMO-06 | Claim-conflict: first `{:ok,_}`, second `{:conflicted,_}` | unit/smoke | `cd examples/demo_app && mix test --only smoke` | ❌ Wave 0: `test/demo_app/recovery_loop_test.exs` |
| DEMO-06 | `demo` CI job failure breaks the build | CI gate | GitHub Actions: `release_gate needs: [lint, test, demo]` | Existing — no edits needed |

### Sampling Rate

- **Per task commit:** `cd examples/demo_app && mix test --only smoke`
- **Per wave merge:** `cd examples/demo_app && mix test --only smoke`
- **Phase gate:** Full `:smoke` suite green + `mix run priv/repo/seeds.exs` exits 0 before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `examples/demo_app/test/demo_app/recovery_loop_test.exs` — covers DEMO-06 all four scenarios
- [ ] `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` — required for `attach/1` to not crash (boot prereq for all tests)
- [ ] `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` — required for `extract_module/1` to resolve (DEMO-05/06 prereq)
- [ ] `examples/demo_app/priv/repo/seeds.exs` (4th incident block) — DEMO-05 seed
- [ ] `examples/demo_app/mix.exs` (`demo.reset` alias) — DEMO-05 replayability
- [ ] `examples/demo_app/lib/demo_app/application.ex` (`Parapet.Capabilities` child + `attach/1`) — boot prereq for all tests

*(Existing test infrastructure: `DemoAppWeb.ConnCase` and `test_helper.exs` are already present and correct — no changes needed.)*

---

## Security Domain

This phase adds no new HTTP endpoints, authentication surfaces, or external service calls. The four ExUnit scenarios and seed additions do not introduce new trust boundaries. No ASVS categories apply.

---

## Sources

### Primary (HIGH confidence — verified by direct code read in this session)

- `lib/parapet/operator.ex:670-728` — `preview_runbook_step/3` return shape (`:preview` key contains full preview map)
- `lib/parapet/operator.ex:749-958` — `confirm_runbook_step/4` full logic, expiry gate, resolved gate, conflict arm
- `lib/parapet/operator.ex:1003-1051` — `compute_preview/3` — documented 5-field preview map keys
- `lib/parapet/operator.ex:1053-1094` — `find_recent_preview/3` — parses `expires_at` from ISO 8601 string or `%DateTime{}`; confirms direct mutation is the correct injection mechanism
- `lib/parapet/operator.ex:1097-1113` — `extract_module/1` — requires `"module"` string key
- `lib/parapet/operator/workbench_contract.ex:170-209` — `find_active_preview/1` is PRIVATE; filters expired tokens; NOT a valid test surface
- `lib/parapet/capabilities.ex` — `start_link/1` named singleton; `register_recovery/2`; 5-atom allowlist
- `lib/parapet/recovery.ex` — 4 `@callback` specs; `attach/1` calls `Code.ensure_loaded?` then delegates to `register_recovery/2`
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — `@moduletag :smoke` pattern; self-contained incident creation
- `examples/demo_app/test/support/conn_case.ex` — sandbox checkout + shared mode; confirmed single-connection model
- `examples/demo_app/test/test_helper.exs` — manual sandbox mode set globally
- `examples/demo_app/lib/demo_app/application.ex` — current `children` list (4 items, no Capabilities)
- `examples/demo_app/priv/repo/seeds.exs` — current 3-incident structure; trailing `IO.puts` count
- `examples/demo_app/mix.exs:49-55` — `setup` alias chain
- `.github/workflows/ci.yml:94-142` — `demo` job full steps; `release_gate` wiring
- `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — 3-step shape, `:retry_async_item` step confirmed

### Secondary (MEDIUM confidence — cited from CONTEXT.md with line references)

- `lib/parapet/automation/claim_service.ex:107-110,126-133` — `on_conflict: :nothing, conflict_target: [:incident_id, :action_kind, :action_key]` (cited, not re-read)
- `test/support/concurrency_bootstrap.ex:46-48` — partial unique index on `correlation_key` (cited, verified structure at lines 61-72)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex:103-166` — `ActionPayload` shape for preview/confirm (read lines 100-166, verified)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all modules verified by direct read; zero new packages
- Architecture: HIGH — all integration points traced to actual code line numbers
- Pitfalls: HIGH — all pitfalls sourced from direct code inspection
- Time-injection mechanism: HIGH — `find_recent_preview/3` code confirms direct `payload["expires_at"]` mutation is the only path
- Token read-back: HIGH — `preview_runbook_step/3` return shape confirmed at `operator.ex:706`
- CI provisioning: HIGH — `ci.yml` read; no gaps identified

**Research date:** 2026-05-28
**Valid until:** 2026-07-01 (stable Elixir codebase; no fast-moving dependencies)
