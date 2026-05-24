# Phase 16: SLO Starter Packs & Low-Traffic Guardrails - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 4 (2 lib, 2 test)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/slo/starter_pack/web_saas.ex` | provider (behaviour impl) | CRUD / data-construction | `lib/parapet/slo/mailglass_delivery.ex` | exact |
| `lib/parapet/slo/starter_pack/delivery_saas.ex` | provider (composite + conditional) | CRUD / data-construction + conditional | `lib/parapet/slo/mailglass_delivery.ex` (shape) + `lib/parapet/integrations/threadline.ex` (guard idiom) | exact composite |
| `test/parapet/slo/starter_pack/web_saas_test.exs` | test | — | `test/parapet/slo/mailglass_delivery_test.exs` | exact |
| `test/parapet/slo/starter_pack/delivery_saas_test.exs` | test | — | `test/parapet/slo/generator_test.exs` (provider registration) + `test/parapet/slo/mailglass_delivery_test.exs` | exact composite |

---

## Pattern Assignments

### `lib/parapet/slo/starter_pack/web_saas.ex` (provider, data-construction)

**Primary analog:** `lib/parapet/slo/mailglass_delivery.ex`
**Secondary analog:** `lib/parapet/slo/rindle_async.ex`

**Imports pattern** (`mailglass_delivery.ex` lines 1–9):
```elixir
defmodule Parapet.SLO.MailglassDelivery do
  @moduledoc """
  Built-in Phase 5 delivery slices for Mailglass.
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.Metrics.AsyncDelivery
  alias Parapet.SLO.SliceSpec
```

For WebSaaS, `AsyncDelivery` is NOT needed as an alias (metric names are passed as binary strings
directly — D-04). Only `SliceSpec` is aliased:

```elixir
defmodule Parapet.SLO.StarterPack.WebSaaS do
  @moduledoc """
  ...
  """

  @behaviour Parapet.SLO.Provider
  alias Parapet.SLO.SliceSpec
```

**Core `@impl true` / `slos/0` scaffold** (`mailglass_delivery.ex` lines 11–13):
```elixir
  @impl true
  def slos do
    [
```

**`kind: :ratio` SliceSpec with binary `good_source_metric`** — adapted from `mailglass_delivery.ex`
lines 14–33 (but using binary metric names instead of `AsyncDelivery.metric_name/2`):

```elixir
      SliceSpec.new(
        name: :mailglass_submit_acceptance,
        integration: :mailglass,
        kind: :ratio,
        good_source_metric: AsyncDelivery.metric_name(:provider_feedback, :total),
        good_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :provider_accepted,
          fault_plane: :provider
        ],
        total_source_metric: AsyncDelivery.metric_name(:outbound, :total),
        total_matchers: [integration: :mailglass, channel: :email, outcome: :attempted, fault_plane: :provider],
        objective: 99.0,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/mailglass-submit-acceptance",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :provider},
        summary: "Mailglass provider acceptance is slipping"
      ),
```

**CRITICAL DIFFERENCE for WebSaaS:** Use binary strings for `*_source_metric` and include
non-empty `total_matchers` (the `SliceSpec` validator at `slice_spec.ex` lines 127–129 rejects
`total_matchers: []`):

```elixir
      SliceSpec.new(
        name: :web_saas_http_availability,
        integration: :http,
        kind: :ratio,
        good_source_metric: "parapet_http_request_count",
        good_matchers: [status_class: ["2xx", "3xx"]],
        total_source_metric: "parapet_http_request_count",
        total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]],
        objective: 99.5,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/http-availability",
        group_labels: [:integration, :method],
        summary: "HTTP availability is below 99.5%"
      ),
```

**`min_total_rate` low-volume override pattern** (`mailglass_delivery.ex` line 71,
`rindle_async.ex` line 44): default is `0.01` (from `slice_spec.ex` line 27 / `new/1` line 43);
low-volume override is `0.001`:

```elixir
        min_total_rate: 0.001,   # override only when explicit low-volume justification exists
```

All three WebSaaS slices use the default (`0.01`) — no override needed.

**SliceSpec validator constraints** (`slice_spec.ex` lines 93–130) — both conditions must be met
for `kind: :ratio` slices:
- `good_matchers` must be non-empty (line 123)
- `total_matchers` must be non-empty (line 127)
- `group_labels` must be a non-empty list (line 105)
- Either `objective` or `threshold` required (line 132–146)

**Module close** (`mailglass_delivery.ex` lines 94–95):
```elixir
    ]
  end
end
```

---

### `lib/parapet/slo/starter_pack/delivery_saas.ex` (provider, composite + conditional)

**Primary analog (module shape):** `lib/parapet/slo/mailglass_delivery.ex`
**Primary analog (conditional guard):** `lib/parapet/integrations/threadline.ex` lines 71–79
**Primary analog (conditional guard alternative):** `lib/parapet/integrations/scoria.ex` lines 184–192

**`Code.ensure_loaded?` + `apply/3` idiom** (`threadline.ex` lines 71–79):
```elixir
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

**`Code.ensure_loaded?` + `apply/3` with conditional list** (`scoria.ex` lines 184–192):
```elixir
  def check_status(workflow_id) do
    if Code.ensure_loaded?(Scoria.Workflow) do
      state = apply(Scoria.Workflow, :get_state, [workflow_id])

      if state != :paused do
        Parapet.Evidence.resolve_action_item(integration: "scoria", external_id: workflow_id)
      end
    end
  end
```

**Full module pattern for DeliverySaaS** — adapts the conditional guard to list accumulation
(no `apply/3` needed because the calls go to internal Parapet modules, not host-supplied ones):

```elixir
defmodule Parapet.SLO.StarterPack.DeliverySaaS do
  @moduledoc """
  ...
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.SLO.ChimewayDelivery
  alias Parapet.SLO.MailglassDelivery
  alias Parapet.SLO.StarterPack.WebSaaS

  @impl true
  def slos do
    websaas_slices = WebSaaS.slos()

    mailglass_slices =
      if Code.ensure_loaded?(Mailglass) do
        MailglassDelivery.slos()
      else
        []
      end

    chimeway_slices =
      if Code.ensure_loaded?(Chimeway) do
        ChimewayDelivery.slos()
      else
        []
      end

    websaas_slices ++ mailglass_slices ++ chimeway_slices
  end
end
```

**D-09 critical:** The module-level `if Code.ensure_loaded? do defmodule` pattern used in
`lib/parapet/metrics/oban.ex` MUST NOT be used here. That pattern hides the module from docs when
the optional dep is absent, breaking `mix verify.public_api` (`mix.exs` line 95:
`"verify.public_api": ["docs --warnings-as-errors"]`). The guard lives inside `slos/0` only.

**Test stub anatomy confirming the design** (`test/support/mailglass.ex` lines 1–4,
`test/support/chimeway.ex` lines 1–4):
```elixir
defmodule Mailglass do
  @moduledoc false
  # Dummy module for testing Mailglass integration compiler guards
end
```
In `:test` env these stubs are compiled (via `elixirc_paths/1` in `mix.exs`), so
`Code.ensure_loaded?(Mailglass)` returns `true` → delivery slices included. In production without
real Mailglass installed, returns `false` → delivery slices silently omitted.

---

### `test/parapet/slo/starter_pack/web_saas_test.exs` (test)

**Primary analog:** `test/parapet/slo/mailglass_delivery_test.exs`
**Secondary analog:** `test/parapet/slo/generator_test.exs` (provider registration + denominator guard)

**Module scaffold** (`mailglass_delivery_test.exs` lines 1–6):
```elixir
defmodule Parapet.SLO.MailglassDeliveryTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO.MailglassDelivery
  alias Parapet.SLO.SliceSpec
```

**Catalog order assertion + named slice pattern** (`mailglass_delivery_test.exs` lines 7–25):
```elixir
  test "exposes the locked mailglass slice catalog with provider acceptance distinct from delivery" do
    slices = MailglassDelivery.slos()

    assert Enum.map(slices, & &1.name) == [
             :mailglass_submit_acceptance,
             :mailglass_confirmed_delivery,
             :mailglass_webhook_freshness,
             :mailglass_suppression_drift
           ]

    acceptance = Enum.find(slices, &(&1.name == :mailglass_submit_acceptance))
    delivered = Enum.find(slices, &(&1.name == :mailglass_confirmed_delivery))

    assert %SliceSpec{} = acceptance
    assert acceptance.good_matchers[:outcome] == :provider_accepted
    assert delivered.good_matchers[:outcome] == :delivered
    assert acceptance.alert_class == :ticket
    assert delivered.alert_class == :page
  end
```

**Diagnostic / secondary kind assertion** (`mailglass_delivery_test.exs` lines 27–33):
```elixir
  test "suppression drift is diagnostic and not a default paging slo" do
    suppression = Enum.find(MailglassDelivery.slos(), &(&1.name == :mailglass_suppression_drift))
    assert suppression.kind == :diagnostic
    assert suppression.alert_class == :diagnostic
    assert suppression.labels[:fault_plane] == :suppression
  end
```

**Provider registration + denominator guard test** (`generator_test.exs` lines 40–62):
```elixir
  test "provider artifacts use active providers only" do
    Application.put_env(:parapet, :providers, [MailglassDelivery])

    on_exit(fn ->
      Application.put_env(:parapet, :slos, [])
      Application.put_env(:parapet, :providers, [])
    end)

    artifacts = Generator.provider_artifacts()

    assert artifacts.recording_rules =~ "mailglass_submit_acceptance"
    refute artifacts.recording_rules =~ "legacy_only"
  end
```

**Denominator guard assertion** (`generator_test.exs` line 37):
```elixir
    assert artifacts.alerts =~ "> 0.01"
```

**Additional test assertions required for WebSaaS** (D-11 LabelPolicy + D-06 metric name):

The `LabelPolicy.assert_safe!/1` test from RESEARCH.md:
```elixir
  test "all WebSaaS pack slice matcher keys pass LabelPolicy.assert_safe!" do
    slices = Parapet.SLO.StarterPack.WebSaaS.slos()

    Enum.each(slices, fn slice ->
      matcher_keys = Keyword.keys(slice.good_matchers ++ slice.total_matchers)
      assert :ok = Parapet.Internal.LabelPolicy.assert_safe!(matcher_keys)
      assert :ok = Parapet.Internal.LabelPolicy.assert_safe!(slice.group_labels)
    end)
  end
```

Note: `use ExUnit.Case, async: true` — all provider tests use `async: true` (they are pure data
construction with no shared state). The provider registration tests that call
`Application.put_env` must NOT be `async: true` (process dictionary is shared).

---

### `test/parapet/slo/starter_pack/delivery_saas_test.exs` (test)

**Primary analog:** `test/parapet/slo/generator_test.exs` (provider registration, `Application.put_env`, `on_exit`)
**Secondary analog:** `test/parapet/slo/chimeway_delivery_test.exs` (slice catalog assertion)

**Module scaffold** (`chimeway_delivery_test.exs` lines 1–5):
```elixir
defmodule Parapet.SLO.ChimewayDeliveryTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO.ChimewayDelivery
```

**For DeliverySaaS**, must NOT use `async: true` if any test modifies `Application.put_env`.
Tests that only call `DeliverySaaS.slos()` and read from the stubs (which are always loaded in
`:test` env) are safe with `async: true`.

**Slice count assertion pattern** — adapts catalog order assertion from `chimeway_delivery_test.exs`
lines 6–23:
```elixir
  test "exposes the locked chimeway slice catalog aligned to the proven surface" do
    slices = ChimewayDelivery.slos()

    assert Enum.map(slices, & &1.name) == [
             :chimeway_provider_acceptance,
             :chimeway_callback_confirmation,
             :chimeway_callback_freshness
           ]
```

**In-test env (stubs loaded), DeliverySaaS count check:**
```elixir
  test "returns WebSaaS slices plus Mailglass and Chimeway slices when both stubs are loaded" do
    slices = Parapet.SLO.StarterPack.DeliverySaaS.slos()
    # 3 WebSaaS + 4 MailglassDelivery + 3 ChimewayDelivery = 10
    assert length(slices) == 10
  end
```

**No-duplication assertion (delegated, not redefined):**
```elixir
  test "delivery slice names match MailglassDelivery and ChimewayDelivery catalogs exactly" do
    delivery_slices = Parapet.SLO.StarterPack.DeliverySaaS.slos()
    mailglass_names = Enum.map(Parapet.SLO.MailglassDelivery.slos(), & &1.name)
    chimeway_names = Enum.map(Parapet.SLO.ChimewayDelivery.slos(), & &1.name)

    all_expected = Enum.map(Parapet.SLO.StarterPack.WebSaaS.slos(), & &1.name) ++
                   mailglass_names ++ chimeway_names

    assert Enum.map(delivery_slices, & &1.name) == all_expected
  end
```

---

## Shared Patterns

### Behaviour Declaration
**Source:** `lib/parapet/slo/mailglass_delivery.ex` lines 6, 11
**Apply to:** Both lib files

```elixir
@behaviour Parapet.SLO.Provider

@impl true
def slos do
```

Provider behaviour contract (`lib/parapet/slo/provider.ex` lines 1–7):
```elixir
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for providing SLOs to the Parapet system.
  """

  @callback slos() :: [struct()]
end
```

### SliceSpec.new/1 — Required Field Minimums
**Source:** `lib/parapet/slo/slice_spec.ex` lines 9–30, 93–130
**Apply to:** All SliceSpec definitions in both lib files

Struct enforce_keys: `[:name, :integration, :kind, :alert_class, :runbook]`

Validator rules (lines 93–130):
- `good_matchers: []` raises `ArgumentError` for non-diagnostic slices (line 123)
- `total_matchers: []` raises `ArgumentError` for ALL slice kinds (line 117 for diagnostic, line 127 for others)
- `group_labels: []` raises `ArgumentError` (line 105)
- Either `objective` OR `threshold` required (lines 132–146)

Default values applied by `new/1` (lines 36–46): `min_total_rate: 0.01`, `group_labels: [:integration]`, all matcher lists `[]`, `labels: %{}`

### `@moduledoc` Required (verify.public_api)
**Source:** `mix.exs` line 95: `"verify.public_api": ["docs --warnings-as-errors"]`
**Apply to:** Both lib files

Every public module needs `@moduledoc` with non-empty content. Every public function needs `@doc`
with non-empty content or `@doc false`. Both `WebSaaS` and `DeliverySaaS` must include `@moduledoc`
explaining one-line registration and what slices ship.

### Provider Registration Test Pattern
**Source:** `test/parapet/slo/generator_test.exs` lines 40–62
**Apply to:** `web_saas_test.exs` integration tests

```elixir
Application.put_env(:parapet, :providers, [MailglassDelivery])

on_exit(fn ->
  Application.put_env(:parapet, :slos, [])
  Application.put_env(:parapet, :providers, [])
end)

artifacts = Generator.provider_artifacts()
assert artifacts.recording_rules =~ "mailglass_submit_acceptance"
```

Provider registration tests must NOT use `async: true` because `Application.put_env` modifies
shared process dictionary.

### `Code.ensure_loaded?` Guard (Conditional Slice Loading)
**Source:** `lib/parapet/integrations/threadline.ex` lines 71–79
**Apply to:** `lib/parapet/slo/starter_pack/delivery_saas.ex` inside `slos/0`

```elixir
if Code.ensure_loaded?(Threadline) do
  apply(Threadline, :log_audit, [mapped_attrs])
else
  :ok
end
```

For DeliverySaaS, the guard adapts to list accumulation instead of `apply/3` side effects, because
`MailglassDelivery` / `ChimewayDelivery` are internal Parapet modules (always loadable); the guard
is on the host-supplied `Mailglass` / `Chimeway` modules:

```elixir
if Code.ensure_loaded?(Mailglass) do
  MailglassDelivery.slos()
else
  []
end
```

---

## No Analog Found

All four files have close analogs. No table entry needed.

---

## Metadata

**Analog search scope:** `lib/parapet/slo/`, `lib/parapet/integrations/`, `test/parapet/slo/`, `test/support/`
**Files read:** 12 (6 lib analogs, 4 test analogs, 2 support stubs)
**Pattern extraction date:** 2026-05-24
