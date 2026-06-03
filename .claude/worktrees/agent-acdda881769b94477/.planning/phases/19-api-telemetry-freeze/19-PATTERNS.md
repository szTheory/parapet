# Phase 19: API & Telemetry Freeze — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 7 new/modified files + ~70 moduledoc edits
**Analogs found:** 6 / 7 (one file — `docs/stability.md` — has a structural analog but no identical peer)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/verify.public_api.ex` | Mix task (gate) | request-response (compile-time) | `lib/mix/tasks/verify.public_api.ex` itself | exact (extend in-place) |
| `test/mix/tasks/verify.public_api_test.exs` | test | request-response | `test/mix/tasks/verify.public_api_test.exs` itself | exact (extend in-place) |
| `test/telemetry_contract_test.exs` | test (contract) | event-driven | `test/parapet/telemetry/async_delivery_test.exs` | role-match |
| `docs/stability.md` | policy document | — | `docs/HISTORY.md`, `docs/telemetry.md` | structural (Markdown doc in docs/) |
| `docs/telemetry.md` | documentation | — | `docs/telemetry.md` itself | exact (edit in-place) |
| `mix.exs` | config | — | `mix.exs` itself | exact (edit in-place) |
| ~70 public `@moduledoc`s | module annotation | — | `lib/parapet/telemetry/async_delivery.ex` @moduledoc block | role-match (no existing callout to copy yet) |

---

## Pattern Assignments

### `lib/mix/tasks/verify.public_api.ex` (Mix task, extend in-place)

**Analog:** `lib/mix/tasks/verify.public_api.ex` (the file itself — extend, not rewrite)

**Current structure — full file** (lines 1–62):

```elixir
defmodule Mix.Tasks.Verify.PublicApi do
  @moduledoc """
  Verifies that all public API modules have documentation and generate a manifest.
  """
  use Mix.Task

  @shortdoc "Verifies public API module documentation"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")
    Application.load(:parapet)

    {:ok, modules} = :application.get_key(:parapet, :modules)

    manifest =
      modules
      |> Enum.filter(&public_api_module?/1)
      |> Enum.map(&check_module_docs/1)
      |> Enum.sort_by(& &1.module)

    output =
      if Code.ensure_loaded?(Jason) do
        Jason.encode!(manifest, pretty: true)
      else
        inspect(manifest, pretty: true, limit: :infinity)
      end

    IO.puts(output)

    if Enum.any?(manifest, fn m -> not m.has_docs end) do
      IO.puts(:stderr, "Error: One or more public API modules are missing documentation.")
      System.halt(1)
    end
  end

  defp public_api_module?(module) do
    name = inspect(module)

    (String.starts_with?(name, "Parapet.") or name == "Parapet") and
      not String.starts_with?(name, "Parapet.Internal.") and
      not String.starts_with?(name, "Parapet.TestSupport.") and
      not String.contains?(name, ".Resolvable.")
  end

  defp check_module_docs(module) do
    has_docs =
      case Code.fetch_docs(module) do
        {:docs_v1, _, _, _, :hidden, _, _} -> false
        {:docs_v1, _, _, _, :none, _, _} -> false
        {:docs_v1, _, _, _, %{}, _, _} -> true
        {:error, _} -> false
      end

    %{
      module: inspect(module),
      has_docs: has_docs
    }
  end
end
```

**What to change (D-02, D-03):**

1. Rename `check_module_docs/1` to `check_module/1` and extend it to also return a `:tier` field by extracting the moduledoc text from the same `Code.fetch_docs/1` call.
2. Add a private `detect_tier_from_text/1` function.
3. Add a second `System.halt(1)` guard in `run/1` for `:unclassified` modules (after the existing `has_docs` guard).

**`Code.fetch_docs/1` pattern to copy from** (lines 48–55 of the existing task):
```elixir
case Code.fetch_docs(module) do
  {:docs_v1, _, _, _, :hidden, _, _} -> false
  {:docs_v1, _, _, _, :none, _, _}   -> false
  {:docs_v1, _, _, _, %{}, _, _}     -> true
  {:error, _}                         -> false
end
```
The extended version matches `%{"en" => text}` instead of the bare `%{}` wildcard so the text can be inspected for callout markers.

**`stderr` error pattern to copy** (lines 33–36):
```elixir
if Enum.any?(manifest, fn m -> not m.has_docs end) do
  IO.puts(:stderr, "Error: One or more public API modules are missing documentation.")
  System.halt(1)
end
```
Duplicate this block immediately after for the `:unclassified` check (same structure, different filter predicate and error message).

---

### `mix.exs` (config, edit in-place)

**Analog:** `mix.exs` itself

**Alias block to delete** (lines 100–104):
```elixir
defp aliases do
  [
    "verify.public_api": ["docs --warnings-as-errors"]
  ]
end
```
Replace with an empty list (D-04):
```elixir
defp aliases do
  []
end
```

**`extras:` list to extend** (lines 58–73) — insert `"docs/stability.md"` after `"docs/HISTORY.md"`:
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "docs/HISTORY.md",
  "docs/stability.md",         # ADD — D-09
  "docs/adopter-flows.md",
  "docs/operator-ui.md",
  "docs/slo-reference.md",
  "docs/telemetry.md",
  "docs/getting-started.md",
  "docs/troubleshooting.md",
  "docs/slo-authoring-guide.md",
  "docs/integrations/sigra.md",
  "docs/integrations/accrue.md",
  "docs/integrations/rulestead.md",
  "docs/integrations/threadline.md"
],
```
Note: `files:` whitelist at line 42 already includes `docs` wholesale — no whitelist change needed.

---

### `test/mix/tasks/verify.public_api_test.exs` (test, extend in-place)

**Analog:** `test/mix/tasks/verify.public_api_test.exs` (the file itself) + `test/parapet/telemetry/async_delivery_test.exs` for assertion style

**Existing test — full file** (lines 1–18):
```elixir
defmodule Mix.Tasks.Verify.PublicApiTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Mix.Tasks.Verify.PublicApi

  test "run/1 prints manifest and succeeds if public API modules have docs" do
    output =
      capture_io(fn ->
        PublicApi.run([])
      end)

    assert output =~ "Parapet"
    assert output =~ "has_docs"
    assert output =~ "Parapet.Telemetry.AsyncDelivery"
  end
end
```

**What to add (D-03):**
- A test asserting the manifest includes a `"tier"` key (reflecting the new `check_module/1` return shape).
- A test asserting that `Parapet.Telemetry.AsyncDelivery` resolves to tier `"stable"` (it has the Stable callout after Phase 19).
- A test asserting that a module without any callout would cause `System.halt(1)`. Since `System.halt/1` exits the process, use `capture_io(:stderr, ...)` and expect the error message in stderr output rather than testing the halt directly. Alternatively, test `detect_tier_from_text/1` directly if it is made accessible (via `@doc false` and a `:test` env export, or by calling the private function through the manifest field).

**`capture_io` pattern to copy** (lines 8–12):
```elixir
output =
  capture_io(fn ->
    PublicApi.run([])
  end)
```
Extend by also capturing `:stderr`:
```elixir
capture_io(:stderr, fn ->
  # test that triggers the unclassified branch
end)
```

---

### `test/telemetry_contract_test.exs` (test, create new)

**Analog:** `test/parapet/telemetry/async_delivery_test.exs`

**Key pattern — module attribute as fixture** (lines 6–14 of the analog):
```elixir
test "exposes the six locked public event families" do
  assert AsyncDelivery.event_families() == [
           [:parapet, :delivery, :outbound],
           [:parapet, :delivery, :provider_feedback],
           [:parapet, :delivery, :webhook_ingest],
           [:parapet, :async, :stage],
           [:parapet, :async, :backlog],
           [:parapet, :async, :callback]
         ]
end
```
The contract test generalizes this: `@async_delivery_families` is seeded from `AsyncDelivery.event_families()` at compile time (a module attribute — same pattern as the analog test calls the function at runtime). All other 21 families are hardcoded module attributes.

**Key pattern — `allowed_public_keys/1` assertion** (lines 32–50 of the analog, `shape_metadata` test):
The analog tests that shaped metadata has only expected keys and no extra keys. The contract test mirrors this by asserting `Parapet.Telemetry.AsyncDelivery.allowed_public_keys(family)` against the fixture for each delivery/async family.

**Test file structure to copy:**
```elixir
defmodule Parapet.TelemetryContractTest do
  use ExUnit.Case, async: true

  # Group 1: Derived from AsyncDelivery at compile time (D-07 — do NOT hardcode here)
  @async_delivery_families Parapet.Telemetry.AsyncDelivery.event_families()

  # Groups 2-7: Hardcoded fixtures — adding a new emit call that is not listed here
  # causes the length assertion to fail, triggering CI failure.
  @other_documented_families [...]

  @all_documented_families @async_delivery_families ++ @other_documented_families

  @documented_measurements %{...}
  @documented_metadata_keys %{...}

  describe "event family contract" do
    test "..." do ... end
  end

  describe "measurement key contract" do
    for {family, keys} <- @documented_measurements do
      test "..." do ... end
    end
  end

  describe "metadata key contract (delivery/async)" do
    for family <- Parapet.Telemetry.AsyncDelivery.event_families() do
      test "..." do ... end
    end
  end
end
```

See RESEARCH.md lines 497–606 for the full concrete fixture data (all 27 families, all measurement/metadata maps). Planner should copy that block directly as the starting point — it is already derived from grepped call sites.

**One open fixture item:** `@safe_labels` in `lib/parapet/integrations/scoria.ex` must be read by the implementer to finalize the scoria metrics family metadata keys before committing the fixture.

---

### `docs/stability.md` (policy document, create new)

**Analog:** `docs/telemetry.md` (existing extra in `extras:` list; same role — a structured Markdown guide in `docs/`)

**`docs/telemetry.md` opening structure** (lines 1–7):
```markdown
# Telemetry Event Schema

Parapet emits telemetry as a public contract. Event names define the lifecycle seam,
while metadata stays bounded and safe for downstream metrics, SLOs, and incident logic.

## Versioning Contract
...
```
Copy this H1 + intro paragraph + H2-section skeleton pattern for `docs/stability.md`. Replace content with the seven sections from RESEARCH.md lines 629–641:

1. Stability Tiers (table: Tier / Signal / Semver Guarantee)
2. Public API Surface Enumeration (per-module tier table by namespace, per D-11/D-12)
3. Semver Promise
4. What Counts as Breaking vs Additive
5. Deprecation Cycle (soft `@doc deprecated:` → hard `@deprecated` ≥1 minor → removal at major)
6. Telemetry Contract (frozen names, additive-only metadata, no `:event_prefix`)
7. Deprecation Register (current: `Parapet.SLO.define/2` → replacement: `Parapet.SLO.Provider`)

**Cross-links required:** `docs/stability.md` must link to `docs/telemetry.md` (and vice versa). Use ExDoc relative HTML links: `[Telemetry Reference](telemetry.html)` and `[Stability Policy](stability.html)`.

---

### `docs/telemetry.md` (documentation, edit in-place)

**Analog:** `docs/telemetry.md` itself

**Current opening** (lines 1–3):
```markdown
# Telemetry Event Schema

Parapet emits telemetry as a public contract.
```

**Insert immediately after line 1** (the H1 heading), before line 3 (D-08):
```markdown
> #### Stable Contract {: .info}
>
> This telemetry reference is **stable** as of v1.0.0. Event names under
> `[:parapet, …]` are frozen — renaming or removing them is a semver-major change.
> Measurement and documented metadata keys may be extended in minor releases but
> will not be removed or renamed without a deprecation cycle. Parapet will never
> add a configurable `:event_prefix` option; all event names are static.
> See [Stability & Deprecation Policy](stability.html) for details.
```

ExDoc admonition syntax verified in `deps/ex_doc/README.md` lines 266–274: `> #### Title {: .class}` on a blockquote is rendered as a styled callout. The `.info` class produces a blue/info box.

---

### ~70 public module `@moduledoc`s (annotation, bulk edit)

**Analog:** `lib/parapet/telemetry/async_delivery.ex` @moduledoc (current, no callout yet — the pattern is the RESEARCH.md ExDoc callout syntax, not an existing codebase example)

**ExDoc callout syntax (D-01) — Stable:**
```elixir
@moduledoc """
One-line description of the module.

> #### Stable {: .info}
>
> This module is **stable** as of v1.0.0. Its public API will not change
> without a major-version bump and a full deprecation cycle. See
> [Stability & Deprecation Policy](stability.html) for details.

...rest of existing moduledoc...
"""
```

**ExDoc callout syntax (D-01) — Experimental:**
```elixir
@moduledoc """
One-line description of the module.

> #### Experimental {: .warning}
>
> This module is **experimental** in v1.x. Its API may change in a minor
> release with a single-version notice in CHANGELOG.md. See
> [Stability & Deprecation Policy](stability.html) for details.

...rest of existing moduledoc...
"""
```

**Placement rule:** Callout block goes immediately after the first sentence/paragraph, before any `## Options` or `## Examples` sections — so it is the first thing visible in HexDocs after the summary line.

**Stable modules (D-11, D-12):** `Parapet`, `Parapet.Integration`, `Parapet.SLO.Provider`, `Parapet.SLO.SliceSpec` (verify not `@moduledoc false`), `Parapet.Runbook`, `Parapet.Escalation.Policy`, `Parapet.Notifier`, `Parapet.Evidence`, `Parapet.Operator`, `Parapet.Deploy`, `Parapet.SLO.StarterPack.WebSaaS`, `Parapet.SLO.StarterPack.DeliverySaaS`, `Parapet.Telemetry.AsyncDelivery`.

**Experimental modules (D-11, D-12):** `Parapet.MCP.Server`, `Parapet.MCP.PrometheusClient`, `Parapet.Automation.CircuitBreaker`, `Parapet.Automation.ClaimService`, `Parapet.Automation.Executor`, all `Parapet.Metrics.*`, `Parapet.Probe`, `Parapet.Probe.NativeScheduler`, `Parapet.Probe.ObanScheduler`, `Parapet.Evidence.Archiver`, `Parapet.Evidence.Retrospective`, `Parapet.Evidence.ArchiveWorker`, all `Parapet.Integrations.*`, `Parapet.Notifier.Slack`, `Parapet.Notifier.Teams`, `Parapet.Notifier.ObanWorker`, `Parapet.Escalation.Worker`, `Parapet.Plug.MCP`, `Parapet.Plug.Webhook`, `Parapet.Plug.Metrics`, `Parapet.Operator.ActionPayload`, `Parapet.Operator.WorkbenchContract`, `Parapet.Capabilities`, all 8 `Parapet.Spine.*` modules, `Parapet.SLO`, SLO preset modules (`SLO.HTTP`, `SLO.LoginJourney`, `SLO.Oban`, `SLO.ChimewayDelivery`, `SLO.MailglassDelivery`, `SLO.RindleAsync`, `SLO.ScoriaEval`), `Parapet.SLO.Generator`.

**Skip (excluded from gate):** `Parapet.SLO.Resolvable` (`.Resolvable.` in name — already excluded by `public_api_module?/1`), `Parapet.Internal.*`, `Parapet.TestSupport.*`, all Mix tasks.

**`@doc since: "1.0.0"` pattern (D-13):**
```elixir
@doc since: "1.0.0"
@doc """
Attaches an exception-safe telemetry handler or activates ecosystem integration adapters.
"""
def attach(opts), do: ...
```
Apply to every public function in Stable-tier modules. Not gate-enforced — documentation-only.

**Example — `lib/parapet.ex` (Stable, lines 1–8 currently):**
```elixir
defmodule Parapet do
  @moduledoc """
  Parapet provides telemetry foundations and safety rails for Phoenix SaaS teams.

  This top-level API provides boundary constraints ensuring that metric collection
  bugs never crash the host process and high cardinality labels are explicitly rejected.
  """
```
Insert Stable callout after the first paragraph (after line 6, before the closing `"""`).

**Example — `lib/parapet/slo/provider.ex` (Stable, lines 1–7 currently):**
```elixir
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for providing SLOs to the Parapet system.
  """

  @callback slos() :: [struct()]
end
```
Insert Stable callout between the first sentence and the closing `"""`.

---

### `lib/parapet/slo.ex` (verify only — STAB-06)

**No changes to the `@deprecated` itself** — it is already in place (line 29):
```elixir
@deprecated "Use a Parapet.SLO.Provider module instead"
def define(name, opts) do
```

**Actions for this file in Phase 19:**
1. Add an Experimental callout to the `@moduledoc` (the module contains legacy functions alongside the deprecated one — discretion: Experimental per RESEARCH.md assumption A6).
2. The STAB-06 verification test goes in `test/mix/tasks/verify.public_api_test.exs` or a new `test/parapet/slo_test.exs` — it uses `Code.compile_string` + `capture_io(:stderr)` to assert the compile-time warning fires (RESEARCH.md lines 681–701 has the full test pattern).

---

## Shared Patterns

### ExDoc Admonition Callout Syntax
**Source:** `deps/ex_doc/README.md` lines 266–274 (verified)
**Apply to:** All ~70 public module `@moduledoc` edits AND `docs/telemetry.md` stability header
```
> #### Title {: .class}
>
> Body text in the callout block.
```
Supported classes: `.info` (blue), `.warning` (yellow/orange), `.error` (red), `.tip` (green), `.neutral` (gray). Phase 19 uses only `.info` (Stable) and `.warning` (Experimental).

### `Code.fetch_docs/1` Return Shape
**Source:** `lib/mix/tasks/verify.public_api.ex` lines 48–55
**Apply to:** The extended `check_module/1` function in the same task file
```elixir
case Code.fetch_docs(module) do
  {:docs_v1, _, _, _, :hidden, _, _} -> ...
  {:docs_v1, _, _, _, :none, _, _}   -> ...
  {:docs_v1, _, _, _, %{"en" => text}, _, _} -> ...  # extended form
  {:error, _}                         -> ...
end
```
The existing task uses `%{}` wildcard; the extended form destructures `%{"en" => text}` to read the moduledoc string for tier detection.

### `System.halt(1)` on Validation Failure
**Source:** `lib/mix/tasks/verify.public_api.ex` lines 33–36
**Apply to:** The new `:unclassified` guard in `run/1`
```elixir
if Enum.any?(manifest, fn m -> not m.has_docs end) do
  IO.puts(:stderr, "Error: ...")
  System.halt(1)
end
```

### `ExUnit.CaptureIO` for Gate Testing
**Source:** `test/mix/tasks/verify.public_api_test.exs` lines 3, 8–12
**Apply to:** New tier-gate assertions in the same test file and STAB-06 deprecation warning test
```elixir
import ExUnit.CaptureIO

output = capture_io(fn ->
  PublicApi.run([])
end)
# or for stderr:
output = capture_io(:stderr, fn -> ... end)
```

### ExUnit Module Attribute as Compile-Time Fixture
**Source:** `test/parapet/telemetry/async_delivery_test.exs` lines 6–14 (calls `event_families()` inline in test body)
**Apply to:** `test/telemetry_contract_test.exs` — use module attributes populated from `AsyncDelivery.event_families()` and hardcoded lists, evaluated at compile time, so fixture drift is caught at test compile time not only at runtime.
```elixir
@async_delivery_families Parapet.Telemetry.AsyncDelivery.event_families()
```

### `mix.exs` `extras:` Registration
**Source:** `mix.exs` lines 58–73
**Apply to:** Adding `"docs/stability.md"` to the `extras:` list in `defp docs do`
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "docs/HISTORY.md",
  # insert "docs/stability.md" here
  ...
]
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `docs/stability.md` (content) | policy document | — | No existing per-module tier enumeration document in the repo; `docs/telemetry.md` is a structural analog for the Markdown format and `extras:` registration, but the tier-table content has no codebase precedent |

---

## Metadata

**Analog search scope:** `lib/`, `test/`, `docs/`, `mix.exs`, `deps/ex_doc/`
**Files read:** `lib/mix/tasks/verify.public_api.ex`, `test/mix/tasks/verify.public_api_test.exs`, `test/parapet/telemetry/async_delivery_test.exs`, `lib/parapet/telemetry/async_delivery.ex`, `mix.exs`, `docs/telemetry.md`, `docs/HISTORY.md`, `lib/parapet/slo.ex`, `lib/parapet.ex`, `lib/parapet/slo/provider.ex`, `lib/parapet/deploy.ex`
**Pattern extraction date:** 2026-05-25
