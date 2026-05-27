# Phase 24: Recovery Behaviour + Capability Allowlist - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 4 (2 created, 2 modified)
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/recovery.ex` (CREATED) | new behaviour module + `__using__/1` + `attach/1` | request-response (in-process registry write) | `lib/parapet/integration.ex` (behaviour shape) + `lib/parapet.ex:30-47` (attach activation) | exact (composite — both analogs together cover the full shape) |
| `test/parapet/recovery_test.exs` (CREATED) | new test (sync sweep + 100-async sweep) | request-response (Agent reads/writes) | `test/parapet/capabilities_test.exs` (sync portions only) | role-match — sync baseline only; async sweep is new pattern (no in-repo precedent) |
| `lib/parapet/capabilities.ex` (MODIFIED, lines 14-18) | allowlist widening (atom-list edit) | n/a (module attribute) | self-precedent at `capabilities.ex:14-18` | exact (in-place widening) |
| `docs/stability.md` (MODIFIED, table around lines 45-58) | docs row | n/a (markdown table row) | adjacent rows at `docs/stability.md:48-49` | exact (table-row mirror) |

---

## Pattern Assignments

### `lib/parapet/recovery.ex` (CREATED — new behaviour module + activation)

**Composite analog**: `lib/parapet/integration.ex` (behaviour + `@moduledoc` admonition shape) AND `lib/parapet.ex:30-47` (`attach/1` activation function shape) AND `lib/parapet/capabilities.ex:6-10` (Experimental admonition verbatim).

#### Pattern 1 — Moduledoc + Experimental admonition (verbatim)

**Source:** `lib/parapet/capabilities.ex:2-11`

```elixir
@moduledoc """
Registry for dynamic capabilities provided by activated adapters.
This module serves as the Phase 7 named recovery contract.

> #### Experimental {: .warning}
>
> This module is **experimental** in v1.x. Its API may change in a minor release with a
> single-version notice in CHANGELOG.md. See
> [Stability & Deprecation Policy](stability.html) for details.
"""
```

**Apply this by**: writing `Parapet.Recovery`'s `@moduledoc` with prose tailored to the behaviour's host-facing role (mirror `Parapet.Integration`'s style — short, adopter-oriented, names `Parapet.Recovery.attach/1` as the entry point), followed by the **verbatim 5-line Experimental admonition above**. This admonition matches the regex in `lib/mix/tasks/verify.public_api.ex:7-15` so the module auto-classifies — do NOT alter wording, indentation, or the trailing line referencing `stability.html`. Per D-03 and D-16, no edits to `verify.public_api.ex` are needed.

#### Pattern 2 — Behaviour declaration shape

**Source:** `lib/parapet/integration.ex:1-27` (full file, 27 LOC)

```elixir
defmodule Parapet.Integration do
  @moduledoc """
  Behaviour for Parapet ecosystem integration adapters.
  ...
  > #### Stable {: .info}
  > ...
  """

  @doc since: "1.0.0"
  @doc """
  Sets up the integration adapter, attaching telemetry handlers and performing any
  required initialization. Called by `Parapet.attach/1` when this adapter is activated.
  """
  @callback setup() :: any()
end
```

**Apply this by**: structuring `Parapet.Recovery` with the same shape — single `defmodule`, moduledoc with Experimental (not Stable) admonition, then `@callback` declarations. Per D-01 declare **four** callbacks (not one):

```elixir
@callback id() :: atom()
@callback label() :: String.t()
@callback preview(incident :: any(), step :: any()) :: {:ok, map()} | {:error, term()}
@callback execute(incident :: any(), target_refs :: any()) :: {:ok, map()} | {:error, term()}
```

Each callback gets its own `@doc since: "1.1.0"` and `@doc """..."""` block above the `@callback` line, mirroring `Integration`'s single-callback pattern at `:21-26`. Arity-2 on `preview`/`execute` is **non-negotiable** — locked by `lib/parapet/operator.ex:711,767` consumer call sites (see Shared Patterns below). Concrete `t()` types may use idiomatic Elixir (per D-22 / CONTEXT discretion); the arities are fixed.

#### Pattern 3 — Minimal `__using__/1` macro (RCV-01 ergonomic surface)

**No direct analog exists** — `Parapet.Integration` does not provide `__using__/1`; adapters write `@behaviour Parapet.Integration` directly. `Parapet.Recovery` adds one **only** because RCV-01 spells out `use Parapet.Recovery`.

**Apply this by** (per D-02 — inject **only** `@behaviour`, nothing else):

```elixir
defmacro __using__(_opts) do
  quote do
    @behaviour Parapet.Recovery
  end
end
```

No `alias`, no `import`, no default callback implementations, no helper functions. This is the most conservative surface and is what Phase 29 (STAB-07) will freeze. Do not add even seemingly-harmless conveniences — they become v1.x freeze liabilities.

#### Pattern 4 — `attach/1` activation function

**Source:** `lib/parapet.ex:30-47`

```elixir
def attach(opts) when is_list(opts) do
  adapters = Keyword.get(opts, :adapters, [])

  Enum.each(adapters, fn adapter ->
    module_name =
      adapter
      |> to_string()
      |> Macro.camelize()

    module = Module.concat(Parapet.Integrations, module_name)

    if Code.ensure_loaded?(module) do
      apply(module, :setup, [])
    end
  end)

  {:ok, adapters}
end
```

**Apply this by**: writing `Parapet.Recovery.attach/1` with a **different signature** but the same skeleton. Per D-04, signature is `attach([module()])` — a flat list of host-module atoms (NOT a keyword list — this diverges intentionally from `Parapet.attach/1`'s `[adapters: [...]]` shape, because the locked success-criterion #2 in ROADMAP.md spells out `Parapet.Recovery.attach([SomeMissingModule, RealModule])`).

Per-module flow (D-05):

```elixir
def attach(modules) when is_list(modules) do
  registered =
    modules
    |> Enum.filter(&Code.ensure_loaded?/1)
    |> Enum.map(fn module ->
      id = module.id()
      label = module.label()

      :ok =
        Parapet.Capabilities.register_recovery(id,
          name: label,
          preview: &module.preview/2,
          execute: &module.execute/2
        )

      id
    end)

  {:ok, registered}
end
```

Critical details:
1. **`Code.ensure_loaded?` silently skips unloaded modules** — no log, no warn (per D-05, established at `lib/parapet.ex:41`, `lib/parapet/integrations/scoria.ex:194`, `lib/parapet/integrations/threadline.ex:81`).
2. **`module.id()` and `module.label()` are called once at attach time** — the values are captured into the registry struct (per D-05). Do NOT capture `&module.id/0` or `&module.label/0` — the operator never invokes those.
3. **`&module.preview/2` and `&module.execute/2` MUST be captured as anonymous-function captures** (per D-06). The registry's struct at `capabilities.ex:33-34` stores these as funs, and `lib/parapet/operator.ex:711,767` gates with `is_function(., 2)`. Passing module atoms would fail that guard and cause silent fallback to `base_preview` — invisible to tests.
4. **Return shape is `{:ok, registered_ids}`** (per D-08) — a 2-tuple, NOT `:ok`. `registered_ids` omits silently-skipped modules. Symmetric with `Parapet.attach/1`'s `{:ok, adapters}` return at `lib/parapet.ex:46`. If zero modules loaded, returns `{:ok, []}` — not an error.
5. **Do NOT pass `target_kind` or `preview_only`** (per D-07) — they keep their existing struct defaults (`nil` and `false`). Adding them to v1.1 callbacks would freeze surface that has no current consumer.

#### Pattern 5 — Optional-dep skip via `Code.ensure_loaded?`

**Source:** `lib/parapet/integrations/scoria.ex:193-201` and `lib/parapet/integrations/threadline.ex:80-88`

```elixir
# scoria.ex:193-201
def check_status(workflow_id) do
  if Code.ensure_loaded?(Scoria.Workflow) do
    state = apply(Scoria.Workflow, :get_state, [workflow_id])

    if state != :paused do
      Parapet.Evidence.resolve_action_item(integration: "scoria", external_id: workflow_id)
    end
  end
end
```

```elixir
# threadline.ex:80-88
defp process_event([:parapet, :audit, :created], _measurements, metadata) do
  if Code.ensure_loaded?(Threadline) do
    audit_attrs = Map.get(metadata, :audit_attrs, %{})
    mapped_attrs = to_threadline_shape(audit_attrs)
    apply(Threadline, :log_audit, [mapped_attrs])
  else
    :ok
  end
end
```

**Apply this by**: using the same predicate idiom. `Parapet.Recovery.attach/1` filters with `Enum.filter(&Code.ensure_loaded?/1)` before invoking `module.id()`/`module.label()`. The two precedents above both branch with `if Code.ensure_loaded?(M) do ... end` and silently no-op (or `:ok`) when the dep is missing. That is the contract — no warn, no log, no error. The `Parapet.attach/1` form at `lib/parapet.ex:41` is the closest match (uses `if Code.ensure_loaded?(module) do apply(...) end` inside `Enum.each`).

---

### `test/parapet/recovery_test.exs` (CREATED — sync sweep + 100-async sweep)

**Analog (sync portions only):** `test/parapet/capabilities_test.exs:1-53` (full file)

The async sweep has **no in-repo precedent** — Phase 24 introduces the pattern. Plan-phase must document the read-only-on-just-written-key rule (D-13) inline in the test file.

#### Pattern 6 — Sync-test baseline (setup + `assert_raise`)

**Source:** `test/parapet/capabilities_test.exs:1-53`

```elixir
defmodule Parapet.CapabilitiesTest do
  use ExUnit.Case, async: false

  alias Parapet.Capabilities

  setup do
    case start_supervised(Capabilities) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        Agent.update(Capabilities, fn _ -> %{recovery: %{}} end)
        :ok
    end

    :ok
  end

  describe "register_recovery/2" do
    test "raises on invalid capability id" do
      assert_raise ArgumentError, ~r/Invalid recovery capability id/, fn ->
        Capabilities.register_recovery(:invalid_capability, name: "Invalid")
      end
    end
  end
end
```

**Apply this by**: for the sync portion of `recovery_test.exs` (success-criterion #1, #2, #3 — Dialyzer-surface check via a fixture host module, `attach/1` filters unloaded modules, `ArgumentError` on out-of-allowlist id), use the exact same skeleton:

- `use ExUnit.Case, async: false` for tests that reset the Agent state via `Agent.update(Capabilities, fn _ -> %{recovery: %{}} end)`.
- Reuse the existing `setup` block verbatim — `start_supervised(Capabilities)` + the `:already_started` reset branch.
- `assert_raise ArgumentError, ~r/Invalid recovery capability id/` for the allowlist-rejection test. The existing regex still matches after widening per D-10 (`capabilities.ex:42-45` interpolates `inspect(@valid_capabilities)`, so the message naming the new 5 valid ids is automatic).
- Use `assert_raise` for an attach call with a host module whose `id/0` returns an atom NOT in the widened 5-atom allowlist.

Test cases the sync sweep MUST cover (mapping to success criteria):

| Test | Maps To | Pattern |
|------|---------|---------|
| `attach/1` registers a real fixture host module | SC #1, SC #2 (positive side) | call `Parapet.Recovery.attach([Fixture])`, then `assert {:ok, [:retry_async_item]} = result`, then `assert %{} = Capabilities.get_recovery(:retry_async_item)` |
| `attach/1` silently skips an unloaded module | SC #2 (skip side) | `assert {:ok, []} = Parapet.Recovery.attach([NonExistent.Module])` |
| `attach/1` skip + register mix returns only the registered id | SC #2 (mixed) | `assert {:ok, [:retry_async_item]} = Parapet.Recovery.attach([NonExistent.Module, Fixture])` |
| Registering an out-of-allowlist id raises | SC #3 | host fixture returns a bogus atom from `id/0` → `assert_raise ArgumentError, ~r/Invalid recovery capability id/` |
| New atoms `:revert_feature_flag` and `:disable_metric_label` are accepted | SC #3 (widening side) | register a fixture for each of the two new atoms; assert no raise + `get_recovery(id)` returns the struct |

Fixture host modules live inside the test file via `defmodule Parapet.RecoveryTest.FixtureRetry do use Parapet.Recovery; def id, do: :retry_async_item; def label, do: "Test"; def preview(_, _), do: {:ok, %{}}; def execute(_, _), do: {:ok, %{}} end` — one fixture per allowlisted id, all inside the test file.

#### Pattern 7 — 100-async sweep (NEW — no precedent)

**No analog.** Per D-12/D-13/D-14, this is a new pattern. Apply this by writing a separate test module (or a separate `describe` block in a second test module file) with `use ExUnit.Case, async: true` and the following rules embedded as comments:

```elixir
defmodule Parapet.RecoveryAsyncSweepTest do
  use ExUnit.Case, async: true

  alias Parapet.Capabilities

  # 100-test async sweep — see Phase 24 D-12/D-13/D-14.
  #
  # Why this is safe with a shared supervised Agent:
  #   - Parapet.Capabilities is a single named Agent supervised at boot
  #     (lib/parapet/internal/application.ex:11). It is NOT reset per test.
  #   - Agent.update serializes all writes through the Agent's mailbox.
  #   - The :recovery map is keyed by capability id; per-key put_in means
  #     concurrent writers on DISTINCT keys do not corrupt each other, and
  #     concurrent writers on the SAME key get last-writer-wins.
  #   - Each test reads ONLY the row it just wrote (via get_recovery/1).
  #     Never assert on capabilities(:recovery) list cardinality — that races.
  #   - This is NOT the v0.10 SLO Application.put_env mistake (Pitfall 13);
  #     that mistake mutated shared atomic flags. Per-key map cells with
  #     last-writer-wins-per-cell are race-free for the assertion we make.

  for n <- 1..100 do
    test "async write #{n} is isolated per key" do
      # parameterize over the 5 allowlisted atoms cyclically (D-13 option b)
      ids = [:retry_async_item, :requeue_dead_letter, :request_manual_provider_check,
             :revert_feature_flag, :disable_metric_label]
      id = Enum.at(ids, rem(unquote(n), 5))
      name = "async-fixture-#{unquote(n)}"

      :ok = Capabilities.register_recovery(id,
        name: name,
        preview: fn _, _ -> {:ok, %{}} end,
        execute: fn _, _ -> {:ok, %{}} end
      )

      cap = Capabilities.get_recovery(id)
      assert cap != nil
      # Read-only-on-just-written-key: do NOT assert cap.name == name,
      # because another async test cycling the same id may have written
      # after us. The contract is just: the row exists post-write.
      assert cap.id == id
    end
  end
end
```

Plan-phase chooses between D-13 option (a) (single allowlisted atom + varied `name`) and option (b) (parameterize over all 5 cyclically — shown above). Both satisfy SC #4. The cyclical-over-5 form is preferred because it also implicitly exercises that the two new allowlist atoms accept registrations under contention.

**Critical**: do NOT migrate the existing `test/parapet/capabilities_test.exs` to `async: true` (per D-14 — out of scope). The existing sync tests stay as-is; the new file lives alongside.

---

### `lib/parapet/capabilities.ex` (MODIFIED — lines 14-18 only)

**Self-analog**: the current `@valid_capabilities` declaration is its own template.

#### Pattern 8 — Allowlist widening (in-place)

**Source — current state:** `lib/parapet/capabilities.ex:14-18`

```elixir
@valid_capabilities [
  :retry_async_item,
  :requeue_dead_letter,
  :request_manual_provider_check
]
```

**Apply this by**: replacing the 3-atom list with the 5-atom list per D-09. Order matters — it is the order the error message renders the valid ids (since `:42-45` interpolates `inspect(@valid_capabilities)`), and the order is locked by ROADMAP.md SC #3 enumeration:

```elixir
@valid_capabilities [
  :retry_async_item,
  :requeue_dead_letter,
  :request_manual_provider_check,
  :revert_feature_flag,
  :disable_metric_label
]
```

**Do NOT touch (per D-10/D-11):**

- `register_recovery/2` raise branch at `capabilities.ex:42-45` — already interpolates `inspect(@valid_capabilities)`; the widened list flows through automatically.
- `lib/parapet/telemetry/recovery_action.ex` — vocab agreement enforced solely by `@valid_capabilities`; telemetry module only enumerates metadata KEYS at `:85-92`, not value vocabularies.
- Any other line in `capabilities.ex` — no edits to `start_link/1`, `register_recovery/2` happy branch, `capabilities/1`, or `get_recovery/1`. The per-key Agent state pattern is the architectural foundation for the 100-async test; touching it would invalidate D-12.

---

### `docs/stability.md` (MODIFIED — single table-row insertion around lines 45-58)

**Analog**: adjacent rows in the same Experimental Modules table.

#### Pattern 9 — Experimental Modules table row

**Source — adjacent rows for shape:** `docs/stability.md:48-49`

```markdown
| `Parapet.MCP.PrometheusClient` | Prometheus query client for MCP |
| `Parapet.Telemetry.RecoveryAction` | Machine-readable recovery action telemetry contract |
```

**Apply this by**: inserting ONE new row alphabetically between `Parapet.MCP.PrometheusClient` (`:48`) and `Parapet.Telemetry.RecoveryAction` (`:49`). The new row goes BEFORE `Parapet.Telemetry.RecoveryAction` because `Parapet.Recovery` sorts before `Parapet.Telemetry.*` alphabetically. Shape matches adjacent rows exactly — pipe, backtick-wrapped module name, pipe, short tier description, pipe:

```markdown
| `Parapet.Recovery` | Host-app-facing recovery action behaviour + activation function |
```

Tier description wording is Claude's discretion (per CONTEXT.md discretion bullet 2) provided it matches the **format** of adjacent rows (single short noun phrase, no trailing period, sentence-case). Suggested alternatives that also fit: "Host-registered recovery action behaviour" / "Recovery action capability behaviour".

**No other edits to `docs/stability.md`** — no edits to the Stable Modules table, no edits to the policy prose, no edits to the outcome-atom freeze rule at `:141`.

---

## Shared Patterns

### Experimental Admonition (verbatim regex-matched contract)

**Source:** `lib/parapet/capabilities.ex:6-10` (also at `lib/parapet/integrations/sigra.ex:6-10` and many other Experimental modules).

```
> #### Experimental {: .warning}
>
> This module is **experimental** in v1.x. Its API may change in a minor release with a
> single-version notice in CHANGELOG.md. See
> [Stability & Deprecation Policy](stability.html) for details.
```

**Apply to:** the new `lib/parapet/recovery.ex` `@moduledoc`. Must be verbatim — the regex classifier in `lib/mix/tasks/verify.public_api.ex:7-15` halts the build (at `:64-79`) on any deviation. Phase 29 STAB-07 will graduate this to the Stable admonition; until then, Experimental is the contract.

### Function-Capture Bridge (operator-consumer contract)

**Source:** `lib/parapet/capabilities.ex:33-34` (struct storage) + `lib/parapet/operator.ex:711,767` (consumer guards — NOT read here per CONTEXT.md "do NOT touch" directive, but the contract is documented in D-06).

```elixir
# capabilities.ex:33-34 — preview/execute stored as anonymous funs
preview: Keyword.get(attrs, :preview),
execute: Keyword.get(attrs, :execute),
```

**Apply to:** `Parapet.Recovery.attach/1` — when delegating to `register_recovery/2`, pass `preview: &module.preview/2` and `execute: &module.execute/2` (NOT `preview: module` or `preview: &module.preview/2 |> some_wrap`). Capturing as MFA-style anonymous funs is what the operator's `is_function(., 2)` guard accepts. The arity-2 is locked at both ends.

### Supervised Agent for Per-Key State (Pitfall 13 avoidance)

**Source:** `lib/parapet/capabilities.ex:20-22` (Agent start) + `lib/parapet/internal/application.ex:11` (supervision — not re-read, per CONTEXT.md).

```elixir
def start_link(_opts) do
  Agent.start_link(fn -> %{recovery: %{}} end, name: __MODULE__)
end
```

**Apply to:** the 100-async test in `test/parapet/recovery_test.exs`. Do NOT introduce a per-test sandbox process, per-test ETS table, or `Application.put_env` indirection (per D-12). The `:recovery` map is keyed by capability id; per-key `put_in` makes concurrent distinct-key writes non-racing, and same-key writes are last-writer-wins. The test asserts only on the row it just wrote (via `get_recovery/1`), never on list cardinality.

---

## No Analog Found

| File / Sub-pattern | Role | Data Flow | Reason |
|------|------|-----------|--------|
| 100-async sweep test pattern | test | concurrent in-process writes | First async test against the supervised `Parapet.Capabilities` Agent in the repo. The existing `capabilities_test.exs` is `async: false` with full-state reset (`:12`) — a pattern that cannot scale. Plan-phase should embed D-12/D-13/D-14 rationale as comments in the new test file so future readers understand why the pattern diverges. |
| `__using__/1` macro on a Parapet behaviour | macro | compile-time injection | `Parapet.Integration` does NOT provide `__using__/1`; adapters declare `@behaviour Parapet.Integration` directly. `Parapet.Recovery.__using__/1` is the first such macro in the codebase. The minimal injection (only `@behaviour Parapet.Recovery`) is the conservative posture chosen specifically to keep the v1.x freeze surface narrow (D-02). |

---

## Metadata

**Analog search scope:** `lib/parapet/*.ex`, `lib/parapet/integrations/*.ex`, `lib/parapet/telemetry/*.ex`, `test/parapet/*.exs`, `docs/stability.md`, `lib/mix/tasks/verify.public_api.ex`.

**Files scanned (Read):** 8 — `lib/parapet/integration.ex`, `lib/parapet.ex`, `lib/parapet/capabilities.ex`, `test/parapet/capabilities_test.exs`, `lib/parapet/integrations/scoria.ex` (lines 185-207), `lib/parapet/integrations/threadline.ex` (lines 70-91), `lib/parapet/integrations/sigra.ex` (lines 1-25), `docs/stability.md` (lines 30-69).

**Files NOT read (per CONTEXT.md "do NOT touch" directive):** `lib/parapet/operator.ex`, `lib/parapet/telemetry/recovery_action.ex`, `lib/mix/tasks/verify.public_api.ex`, `lib/parapet/internal/application.ex`. Their line references in CONTEXT.md are sufficient — Phase 24 does not edit them; quoting their exact text would risk encouraging unintended edits.

**Pattern extraction date:** 2026-05-27
