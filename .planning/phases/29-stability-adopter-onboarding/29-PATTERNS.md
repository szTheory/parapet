# Phase 29: Stability + Adopter Onboarding — Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 9 (4 new, 5 modified)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/parapet.gen.recovery.ex` | Mix task / generator | request-response (scaffold) | `lib/mix/tasks/parapet.gen.runbooks.ex` | exact |
| `priv/templates/parapet.gen.recovery/recovery.ex.eex` | EEx template | transform | `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` | exact |
| `test/mix/tasks/parapet.gen.recovery_test.exs` | test | request-response | `test/mix/tasks/parapet.gen.runbooks_test.exs` | exact |
| `lib/mix/tasks/parapet.doctor.ex` (mod: `check_recovery`) | Mix task / introspection | CRUD (read-only) | `lib/mix/tasks/parapet.doctor.ex` (existing checks) + `lib/parapet/spine/alert_processor.ex` | exact + role-match |
| `lib/parapet/recovery.ex` (mod: moduledoc admonition) | behaviour module | N/A (doc-only edit) | `docs/stability.md:10-13` (tier-callout strings) | exact |
| `docs/stability.md` (mod: row move + compat note) | reference doc | N/A | self (existing table structure) | exact |
| `docs/recovery-actions.md` | adopter guide doc | N/A | `docs/slo-authoring-guide.md` | role-match |
| `mix.exs` (mod: extras + groups_for_extras) | config | N/A | self (existing extras/groups structure) | exact |
| `docs/getting-started.md` + `docs/operator-ui.md` (mod: cross-links) | doc | N/A | self (existing bullet lists / section prose) | exact |

---

## Pattern Assignments

### `lib/mix/tasks/parapet.gen.recovery.ex` (Mix task / generator, new)

**Analog:** `lib/mix/tasks/parapet.gen.runbooks.ex`

**Igniter task skeleton** (lines 1–15):
```elixir
defmodule Mix.Tasks.Parapet.Gen.Runbooks do
  @moduledoc """
  Generates a fixed host-owned runbook catalog for Parapet.
  """
  use Igniter.Mix.Task

  @example "mix parapet.gen.runbooks"
  @shortdoc "Generates host-owned runbook modules"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :parapet,
      example: @example
    }
  end
```

**Net-new vs analog — positional arg:** The `gen.recovery` task adds `positional: [:name]` to the `%Igniter.Mix.Task.Info{}` struct. Bare atom = required; Igniter raises `ArgumentError` automatically if omitted (verified at `deps/igniter/lib/mix/task.ex:360-362`). The analog has no positional args.

```elixir
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :parapet,
      example: @example,
      positional: [:name]          # <-- net-new vs analog
    }
  end
```

**base_name / module_prefix / lib_dir derivation** (lines 17–24):
```elixir
  def igniter(igniter) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    app_name = Igniter.Project.Application.app_name(igniter)

    base_name = web_module |> inspect() |> String.trim_trailing("Web")
    runbook_module_prefix = Module.concat([base_name, "Parapet", "Runbooks"])

    lib_dir = Path.join(["lib", "#{app_name}", "parapet", "runbooks"])
```

Substitute `"Recovery"` for `"Runbooks"`, append the camelized `name` segment, and derive `lib_dir` as `"lib/<app_name>/parapet/recovery"`. Read the NAME value as `igniter.args.positional.name` (map access, not keyword list).

**`Igniter.copy_template/5` idiom** (lines 32–43):
```elixir
    igniter
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "stalled_executor.ex.eex"
      ]),
      Path.join([lib_dir, "stalled_executor.ex"]),
      assigns,
      on_exists: :skip
    )
```

For `gen.recovery`: the source template path becomes `"parapet.gen.recovery/recovery.ex.eex"`; the destination is `Path.join([lib_dir, "#{name_underscored}.ex"])`. Use `on_exists: :skip`.

**Test stub creation:** Use `Igniter.create_new_file/4` (4-arg form — the 3-arg form is `@deprecated` per `deps/igniter/lib/igniter.ex:812`) with `on_exists: :skip`, writing to `"test/<app_name>/parapet/recovery/<name_underscored>_test.exs"`. Alternatively, use a second `copy_template/5` call if the test stub itself is an EEx template.

**`Igniter.add_notice/2` tail** (lines 132–135):
```elixir
    |> Igniter.add_notice("""
    Parapet runbooks generated at `#{lib_dir}`.
    You can customize the copy and thresholds to fit your domain.
    """)
```

Mirror this for `gen.recovery` with an appropriate notice message.

---

### `priv/templates/parapet.gen.recovery/recovery.ex.eex` (EEx template, new)

**Analog:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex`

**Template header convention** (line 1):
```elixir
defmodule <%= inspect(@module_prefix) %>.StalledExecutor do
  use Parapet.Runbook
```

For `recovery.ex.eex` the header becomes:
```elixir
defmodule <%= inspect(@module_prefix) %>.<%= @name_camelized %> do
  use Parapet.Recovery
```

**Required content — 4-callback fixture shape** (from `test/parapet/recovery_test.exs:5-11`):
```elixir
defmodule Parapet.RecoveryTest.FixtureRetryAsync do
  use Parapet.Recovery
  def id, do: :retry_async_item
  def label, do: "Retry Async (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end
```

The EEx template must emit `use Parapet.Recovery` + all four callbacks with user-facing docstring placeholders. The 4-callback signatures are FROZEN (D-02):
- `def id, do: :your_capability_atom`
- `def label, do: "Human-readable label"`
- `def preview(_incident, _step), do: {:ok, %{}}`
- `def execute(_incident, _target_refs), do: {:ok, %{}}`

Assigns available in the template: `@module_prefix` (module alias), `@app_name` (atom), `@name_camelized` (PascalCase string), `@name_underscored` (snake_case string for the default capability atom placeholder).

---

### `test/mix/tasks/parapet.gen.recovery_test.exs` (test, new)

**Analog:** `test/mix/tasks/parapet.gen.runbooks_test.exs`

**Module + import block** (lines 1–5):
```elixir
defmodule Mix.Tasks.Parapet.Gen.RunbooksTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Runbooks
```

**`Igniter.Test` setup + `Rewrite.sources` path assertion pattern** (lines 8–18):
```elixir
  describe "mix parapet.gen.runbooks" do
    test "creates fixed runbook files under lib/<host>/parapet/runbooks/" do
      igniter =
        test_project(app_name: :test)
        |> Runbooks.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

      assert Enum.any?(
               files,
               &String.contains?(&1, "lib/test/parapet/runbooks/stalled_executor.ex")
             )
```

**Content assertion pattern** (lines 54–61):
```elixir
      stalled_executor_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/stalled_executor.ex")
        |> Rewrite.Source.get(:content)

      assert stalled_executor_source =~ "defmodule Test.Parapet.Runbooks.StalledExecutor do"
      assert stalled_executor_source =~ "use Parapet.Runbook"
      assert stalled_executor_source =~ "capability: :retry_async_item"
      assert stalled_executor_source =~ "warning:"
```

**For `gen.recovery` test:** Pass the positional name through `igniter/1` directly on the test project. Assert:
- `Rewrite.sources` contains path `"lib/test/parapet/recovery/<name_underscored>.ex"`
- Source content `=~ "use Parapet.Recovery"`, `=~ "def id"`, `=~ "def label"`, `=~ "def preview"`, `=~ "def execute"`
- Test stub path `"test/test/parapet/recovery/<name_underscored>_test.exs"` present in sources
- `on_exists: :skip` behavior: running the task twice on the same test project does not overwrite

---

### `lib/mix/tasks/parapet.doctor.ex` (modified — add `check_recovery`)

**Analog:** self (`lib/mix/tasks/parapet.doctor.ex`) — existing check contract + `lib/parapet/spine/alert_processor.ex:116-128`

**`@static_checks` registration** (line 22):
```elixir
@static_checks ~w(runbooks router operator_ui endpoint cardinality cluster_static)
```
Add `"recovery"` to this list. The `parse_requested_checks/1` guard at line 67 uses `@static_checks` as-is — no separate guard edit needed.

**Dispatch clause pattern** (lines 89–94):
```elixir
  defp run_static_check("runbooks"), do: check_runbooks()
  defp run_static_check("router"), do: check_router()
  defp run_static_check("operator_ui"), do: check_operator_ui()
  defp run_static_check("endpoint"), do: check_endpoint()
  defp run_static_check("cardinality"), do: check_cardinality()
  defp run_static_check("cluster_static"), do: check_cluster_static()
```
Add after line 94:
```elixir
  defp run_static_check("recovery"), do: check_recovery()
```

**`:skip` no-adoption idiom** (lines 96–115 — `check_runbooks` as the contract template):
```elixir
  defp check_runbooks do
    slos = Parapet.SLO.all()

    invalid_slos =
      Enum.filter(slos, fn slo ->
        is_nil(slo.runbook) or String.trim(slo.runbook) == ""
      end)

    cond do
      slos == [] ->
        %{status: :skip, messages: ["No SLOs defined, so runbook validation was skipped."]}

      invalid_slos == [] ->
        %{status: :info, messages: ["All SLOs have runbooks."]}

      true ->
        messages = Enum.map(invalid_slos, &"SLO #{inspect(&1.name)} is missing a valid runbook")
        %{status: :error, messages: messages}
    end
  end
```

**`check_recovery` return contract:** Same `%{status: atom(), messages: [String.t()]}` shape. Per RESEARCH.md Pitfall 5 and CONTEXT.md specifics: zero-capability-count must map to `:skip` or `:info` (NOT `:warn`) to avoid `mix parapet.doctor --ci` exiting 1 on a fresh install (the `--ci` threshold is `:warn` per `doctor.ex:54`). `:warn` fires only when capabilities ARE registered but something is wrong.

Three signals for `check_recovery`:
1. `Parapet.Capabilities.capabilities(:recovery)` (line 52): zero count → `:skip`
2. Iterate `Parapet.SLO.all()` → resolve runbook module → call `__runbook_schema__/0` → cross-check each step's `:capability` atom against `Parapet.Capabilities.get_recovery/1` (returns `nil` if unregistered) → `:warn` if unregistered
3. For each registered capability, `Code.ensure_loaded?/1` + `function_exported?/2` on the 4 callbacks → `:warn` if any fail

**SLO-string → runbook-module discovery pattern** (`lib/parapet/spine/alert_processor.ex:116-128`):
```elixir
  defp build_runbook_data(alertname, triage_summary) when is_binary(alertname) do
    slo = Enum.find(Parapet.SLO.all(), fn s -> to_string(s.name) == alertname end)

    case slo do
      %{runbook: runbook} when not is_nil(runbook) ->
        module = get_runbook_module(runbook)

        if module && Code.ensure_loaded?(module) &&
             function_exported?(module, :__runbook_schema__, 0) do
          apply(module, :__runbook_schema__, [])
          |> Incident.put_triage_summary(triage_summary)
        else
          Incident.put_triage_summary(%{}, triage_summary)
        end

      _ ->
        Incident.put_triage_summary(%{}, triage_summary)
    end
  end
```

`check_recovery` iterates ALL SLOs (not filtered by alertname). URL strings that fail `get_runbook_module/1` parse return `nil` and fall through safely — they produce a SKIP, never `:warn` or `:error`.

**`Parapet.Capabilities` read primitives** (`lib/parapet/capabilities.ex:52-66`):
```elixir
  def capabilities(:recovery) do
    Agent.get(__MODULE__, fn state ->
      state.recovery |> Map.values()
    end)
  end

  def get_recovery(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.recovery, id)
    end)
  end
```

---

### `lib/parapet/recovery.ex` (modified — moduledoc admonition flip, lines 16–20)

**Analog:** `docs/stability.md:10-13` (verbatim tier-callout strings)

**Current text to replace** (lines 16–20):
```elixir
  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
```

**Target text — verbatim Stable callout** (from `docs/stability.md:10-13`):
```
> #### Stable {: .info}
```

The full replacement block must say `Stable {: .info}` (not `info` without the curly-brace syntax) so `verify.public_api`'s `detect_tier_from_text/1` regex matches:
```elixir
Regex.match?(~r/####\s+Stable\s*\{:\s*\.info\}/, text) -> :stable
```

Also per D-03: add callback-freeze prose to the moduledoc — as prose, NOT as new code. Prose tone can mirror `Parapet.Integration` (also Stable). No new module attributes, no `@deprecated`, no runtime guards.

---

### `docs/stability.md` (modified — row move + compat note)

**Analog:** self (existing table structure)

**Source row to REMOVE** (line 49, Experimental table):
```
| `Parapet.Recovery` | Host-app-facing recovery action behaviour + activation function |
```

**Destination — Stable Modules table** (lines 24–38): Insert the Recovery row in the existing alphabetical/logical ordering. The Stable table currently ends at line 38 with `Parapet.Telemetry.AsyncDelivery`. Insert the `Parapet.Recovery` row within this block.

**Deprecation/Compatibility Register to EXTEND** (lines 195–197):
```
| Module / Function | Kind | Replacement | Deprecation Stage | Removal Target |
|-------------------|------|-------------|-------------------|---------------|
| `Parapet.SLO.define/2` | Hard `@deprecated` | `Parapet.SLO.Provider` — implement the behaviour and pass the module to `Parapet.attach/1` | Hard deprecation (compile-time warning active) | Next major version |
```

Add a second row below the existing `Parapet.SLO.define/2` row. Content per D-06: adopters who pattern-match `Parapet.Operator.confirm_runbook_step/4` must handle the additive `{:short_circuited, reason}` and `{:conflicted, claim_id}` variants; these are additive and will NOT be removed in 1.x.

---

### `docs/recovery-actions.md` (new adopter guide)

**Analog:** `docs/slo-authoring-guide.md`

**Top-level section structure** (headings at lines 1, 9, 39, 57, 137):
```
# Parapet SLO Authoring Guide           ← line 1: title / decision-frame intro
## How to decide what to slice          ← line 9: decision-frame
## Writing a custom slice               ← line 39: authoring
## Provider-as-bundle pattern           ← line 57: patterns
## What not to do                       ← line 137: what-not-to-do
```

**Map to `recovery-actions.md`:**
```
# Parapet Recovery Actions Guide        ← title / decision-frame intro
## When to wire a recovery capability   ← decision-frame (mirrors "How to decide what to slice")
## Authoring a recovery capability      ← authoring (mix parapet.gen.recovery + 4 callbacks)
## Preview/Confirm UX                   ← patterns (references operator-ui.md:179-208)
## Worked examples                      ← 4 capability-backed playbooks (D-15)
## What not to do                       ← what-not-to-do (mirrors last section of slo guide)
```

**Tone and depth anchor** (from `slo-authoring-guide.md:1-8`):
```
Parapet is built around a simple conviction: an SLO should track whether users can do
the things they came to your app to do, not whether the servers are breathing...

This guide walks through how to decide what deserves a slice...
```

The adopter guide opens with a conviction statement, explains the decision frame first, then shows authoring mechanics — same left-to-right ordering.

**"What not to do" section structure** (lines 137–145):
```markdown
## What not to do

These are the failure modes that produce noise instead of signal.

- **Lower the objective to silence noise.** ...
- **Alert on infrastructure metrics as if they were journey SLOs.** ...
```

Mirror this pattern for recovery anti-patterns (e.g., "Do not make your capability swallow errors silently," "Do not use a capability as a generic admin escape hatch").

**Four worked examples** (D-15): `:retry_async_item`, `:requeue_dead_letter`, `:revert_feature_flag`, `:disable_metric_label`. Each maps to a capability-backed playbook shipped in Phase 27. Guidance-only playbooks (retry storm, suppression drift) are excluded.

---

### `mix.exs` (modified — extras + groups_for_extras)

**Analog:** self (existing extras / groups structure)

**`extras` list** (lines 59–80):
```elixir
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/HISTORY.md",
        "docs/stability.md",
        "docs/adopter-flows.md",
        "docs/operator-ui.md",
        "docs/slo-reference.md",
        "docs/telemetry.md",
        "docs/getting-started.md",
        "docs/troubleshooting.md",
        "docs/slo-authoring-guide.md",
        "docs/release-policy.md",
        "docs/integrations/sigra.md",
        ...
      ],
```

Add `"docs/recovery-actions.md"` to this list (position: alongside other `docs/*.md` Guides entries, e.g., after `"docs/slo-authoring-guide.md"`).

**`groups_for_extras: Guides`** (lines 84–92):
```elixir
      groups_for_extras: [
        "Getting Started": ["README.md", "docs/getting-started.md"],
        Guides: [
          "docs/adopter-flows.md",
          "docs/operator-ui.md",
          "docs/slo-authoring-guide.md",
          "docs/troubleshooting.md",
          "docs/release-policy.md",
          "docs/HISTORY.md",
          "CHANGELOG.md"
        ],
```

Add `"docs/recovery-actions.md"` to the `Guides:` list alongside the other guide entries. **Both `extras` AND `groups_for_extras` must be updated in the same commit** — omitting either causes silent failure (file ships to Hex but renders nothing in HexDocs, per RESEARCH.md Pitfall 1).

---

### `docs/getting-started.md` (modified — Next steps cross-link, lines 94–99)

**Analog:** self (existing "## Next steps" bullet list)

**Current block** (lines 94–99):
```markdown
## Next steps

- [Parapet Adopter Flows](docs/adopter-flows.md) — understand the reliability operating loop and when each surface matters
- [SLO Authoring Guide](docs/slo-authoring-guide.md) — learn to author custom SLO slices for your specific journeys
- [Parapet Sigra Integration](docs/integrations/sigra.md) — wire the login journey slice with real authentication event data
- [Runnable Demo App](https://github.com/szTheory/parapet/tree/main/examples/demo_app) — explore a live, seeded Parapet setup end-to-end: incidents, timeline entries, runbook steps, and the Operator UI populated and ready to browse
```

Add a 5th bullet linking to `docs/recovery-actions.md`. Pattern: `- [Recovery Actions Guide](docs/recovery-actions.md) — author host recovery capabilities and wire them to runbook steps`.

---

### `docs/operator-ui.md` (modified — Preview-First Recovery cross-link, lines 179–208)

**Analog:** self (existing "## Phase 7 Preview-First Recovery" prose section)

**Section end** (line 208):
```
By naming and bounding these capabilities, the host application maintains control over what
the operator can do, ensuring the workbench remains a safe environment for high-stakes
incident response.
```

Add a forward-reference sentence after line 208 (or within the "Named Capabilities" subsection): `See the [Recovery Actions Guide](recovery-actions.html) for step-by-step authoring instructions, worked examples, and the error semantics for each capability outcome.`

---

## Shared Patterns

### Igniter task `info/2` + `igniter/1` skeleton
**Source:** `lib/mix/tasks/parapet.gen.runbooks.ex:5-15`
**Apply to:** `lib/mix/tasks/parapet.gen.recovery.ex`

```elixir
use Igniter.Mix.Task

@example "mix parapet.gen.recovery <NAME>"
@shortdoc "Generates a host-owned recovery action module"

def info(_argv, _composing_task) do
  %Igniter.Mix.Task.Info{
    group: :parapet,
    example: @example,
    positional: [:name]
  }
end

def igniter(igniter) do
  # Use igniter/1 — igniter/2 is @deprecated (deps/igniter/lib/mix/task.ex:35)
```

### `Igniter.copy_template/5` with `on_exists: :skip`
**Source:** `lib/mix/tasks/parapet.gen.runbooks.ex:33-43` / `lib/mix/tasks/parapet.gen.ui.ex:33-44`
**Apply to:** `lib/mix/tasks/parapet.gen.recovery.ex`

```elixir
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.recovery", "recovery.ex.eex"]),
  Path.join([lib_dir, "#{name_underscored}.ex"]),
  assigns,
  on_exists: :skip
)
```

### Doctor check `%{status:, messages:}` contract
**Source:** `lib/mix/tasks/parapet.doctor.ex:96-115` (`check_runbooks`)
**Apply to:** `check_recovery` in `lib/mix/tasks/parapet.doctor.ex`

Pattern: `cond` on primary condition (empty list = `:skip`, healthy = `:ok` or `:info`, problem = `:warn`). Return `%{status: atom(), messages: [String.t()]}`. Adoption absence = `:skip`; partial problems = `:warn`; never `:error` for adoption signals.

### Tier-callout verbatim strings
**Source:** `docs/stability.md:10-13`
**Apply to:** `lib/parapet/recovery.ex:16-20` (flip target) + `docs/stability.md` Stable table row description

```
> #### Stable {: .info}
```
```
> #### Experimental {: .warning}
```

### EEx template `@module_prefix` header convention
**Source:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex:1`
**Apply to:** `priv/templates/parapet.gen.recovery/recovery.ex.eex`

```elixir
defmodule <%= inspect(@module_prefix) %>.<%= @name_camelized %> do
```

---

## No Analog Found

All files have close analogs in the codebase. No entries here.

---

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/parapet/`, `priv/templates/`, `test/mix/tasks/`, `test/parapet/`, `docs/`, `mix.exs`, `lib/parapet/spine/`
**Files scanned:** 14 (via direct Read at cited lines)
**Pattern extraction date:** 2026-05-28
