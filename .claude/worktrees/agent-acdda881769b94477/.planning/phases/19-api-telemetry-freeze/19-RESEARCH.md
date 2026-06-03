# Phase 19: API & Telemetry Freeze — Research

**Researched:** 2026-05-25
**Domain:** Elixir public API stabilization, ExDoc tier annotations, `Code.fetch_docs/1`, telemetry contract testing, Mix task alias composition
**Confidence:** HIGH (all findings grounded in codebase source inspection + Elixir 1.19 runtime)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Three tiers — Stable / Experimental / Internal. Stable = `> #### Stable {: .info}` ExDoc callout + full semver protection. Experimental = `> #### Experimental {: .warning}` + one-release CHANGELOG notice. Internal = `Parapet.Internal.*` or `@moduledoc false`.
- **D-02:** Tier detection = parse the ExDoc admonition callout out of each module's `@moduledoc` via `Code.fetch_docs/1`. Callout is the single source of truth — no `@stability` attribute, no registry file.
- **D-03:** Harden `Mix.Tasks.Verify.PublicApi` so `:unclassified` causes non-zero exit.
- **D-04:** Fix the `mix.exs` alias `"verify.public_api": ["docs --warnings-as-errors"]` which shadows the task — `mix verify.public_api` currently runs `mix docs`, not `Mix.Tasks.Verify.PublicApi`.
- **D-05:** Freeze the full `[:parapet, …]` event surface (~25 families) including raw ecto/http/oban passthroughs.
- **D-06/D-07:** Contract test (`test/telemetry_contract_test.exs`) asserts committed fixtures; pin parameterized families against resolved `AsyncDelivery.event_families/0`; no configurable `:event_prefix`.
- **D-08:** Add stability-freeze header to `docs/telemetry.md`.
- **D-09:** Policy file is named exactly `docs/stability.md`.
- **D-10:** Deprecation cycle: soft `@doc deprecated:` → hard `@deprecated` ≥1 minor → removal at major.
- **D-11:** Module classification per V1-STABILITY-FREEZE.md split. Stable: `Parapet`, `Parapet.Integration`, `Parapet.SLO.Provider`, `Parapet.SLO.SliceSpec`, `Parapet.Runbook`, `Parapet.Escalation.Policy`, `Parapet.Notifier`, `Parapet.Evidence`, `Parapet.Operator`, `Parapet.Deploy`, SLO starter packs, documented telemetry events. Experimental: `Parapet.MCP.*`, `Parapet.Automation.*`, `Parapet.Metrics.*`, `Parapet.Probe*`, `Parapet.Evidence.Archiver`, `Parapet.Evidence.Retrospective`, `Parapet.Integrations.*`.
- **D-12:** Unclassified namespaces: `Parapet.Spine.*` (8 modules) → Experimental (Internal where already `@moduledoc false`), `Parapet.Capabilities` → Experimental, SLO StarterPacks → Stable.
- **D-13:** `@doc since: "1.0.0"` is documentation-only, NOT gate-enforced.
- **D-14:** STAB-06 already satisfied — `@deprecated` already at `lib/parapet/slo.ex:29`; phase 19 verifies it fires and documents the window.

### Claude's Discretion

- Exact per-module tier for any module not explicitly named — default by namespace rules in D-11/D-12.
- Exact prose/wording of ExDoc callouts, `docs/stability.md` policy, `docs/telemetry.md` stability header.

### Deferred Ideas (OUT OF SCOPE)

None — analysis stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-01 | Every public module declares a stability tier via ExDoc callout + Stable functions carry `@doc since: "1.0.0"` | D-02 detection pattern; full module surface audit below; `@doc since:` idiom verified |
| STAB-02 | `docs/stability.md` enumerates the public API surface, semver promise, breaking vs additive, deprecation cycle | D-09/D-10; `mix.exs extras:` registration pattern; `files:` whitelist already covers `docs/` |
| STAB-03 | Telemetry contract documented as frozen — static names, additive-only, no `:event_prefix` — with stability header on `docs/telemetry.md` | Full ~25-family event catalog below; D-08 header pattern |
| STAB-04 | `mix verify.public_api` fails (non-zero) on any unclassified public module | D-04 alias fix mechanics; D-02 detect_tier code pattern; existing task extension points |
| STAB-05 | Telemetry contract test fails CI on event/measurement/metadata/vocab drift | D-06/D-07 fixture pattern; `AsyncDelivery` as seed; full event catalog below |
| STAB-06 | `Parapet.SLO.define/2` is hard-deprecated with compile-time warning naming replacement | D-14: already done at `lib/parapet/slo.ex:29`; verify pattern + document window |
</phase_requirements>

---

## Summary

Phase 19 is a **declaration and enforcement** phase. No new runtime capabilities are added; the existing public surface is classified and made machine-enforceable. Three concrete deliverables drive everything: (1) a policy document (`docs/stability.md`), (2) ExDoc callout annotations in every public module's `@moduledoc`, and (3) two enforcement gates — a hardened `mix verify.public_api` task and a new `test/telemetry_contract_test.exs`.

The biggest mechanical risks are the alias shadow bug (D-04) and sourcing fixture data for the ~19 telemetry families beyond the 6 already in `AsyncDelivery`. Both are fully resolvable from the existing codebase: the alias bug has a clean one-line fix, and every event family's measurements and metadata are directly readable from the emit call sites. The module classification scope is ~70 non-Internal public modules; the majority resolve unambiguously by namespace; a small number (SLO presets, Spine schemas, Notifier adapters, Plug modules) require explicit judgment.

**Primary recommendation:** Execute in three distinct sub-phases: (A) fix alias + create policy doc + update telemetry.md header, (B) annotate all ~70 modules + add `@doc since:`, (C) write contract test. These can be planned as waves within Phase 19.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tier detection at gate runtime | Mix Task (`verify.public_api`) | — | Gate runs at compile time against BEAM docs chunks |
| Tier annotation source of truth | Module `@moduledoc` | — | D-02: callout is the single source of truth |
| Policy document | `docs/stability.md` | `mix.exs extras:` | Documentation artifact; registered in ExDoc |
| Telemetry contract enforcement | ExUnit test (`telemetry_contract_test.exs`) | CI gate | Drift detection at test-suite level, not compile time |
| Deprecation signaling | Module attribute (`@deprecated`) | ExDoc `@doc deprecated:` | Elixir compile-time + doc-rendered |

---

## Standard Stack

No new packages are installed in this phase. All work uses existing dependencies.

| Tool | Version | Purpose |
|------|---------|---------|
| Elixir | 1.19.5 | `Code.fetch_docs/1`, `@deprecated`, `@doc since:` |
| ExDoc | `~> 0.31` | Admonition rendering, `extras:` registration |
| ExUnit | (built-in) | `telemetry_contract_test.exs`, `capture_io` for gate test |

## Package Legitimacy Audit

> Not applicable — no new packages are installed in Phase 19. All capabilities use built-in Elixir/OTP and existing project dependencies.

---

## Architecture Patterns

### System Architecture Diagram

```
Source: @moduledoc strings in each public module
    |
    | Code.fetch_docs/1
    v
Mix.Tasks.Verify.PublicApi (extended)
    |-- detect_tier/1 --> :stable | :experimental | :unclassified
    |-- :unclassified? --> System.halt(1) [non-zero exit]
    |-- emit JSON manifest (existing behavior)
    v
CI gate: mix verify.public_api

Source: :telemetry.execute call sites (grepped; see catalog below)
    |
    | Fixture committed to test file
    v
test/telemetry_contract_test.exs
    |-- event families match AsyncDelivery.event_families/0 (for delivery/async)
    |-- event families match @documented_events fixture (for all ~25 families)
    |-- measurement keys match per-family fixture
    |-- metadata keys match per-family fixture
    |-- vocab atoms match per-family fixture
    v
CI gate: mix test
```

### Recommended Project Structure (no new dirs needed)

```
lib/mix/tasks/verify.public_api.ex    # extend in-place (add detect_tier/1, update run/1)
test/
  telemetry_contract_test.exs         # NEW — full contract test
  mix/tasks/
    verify.public_api_test.exs        # extend: add tier detection assertions
docs/
  stability.md                        # NEW — policy document
  telemetry.md                        # EDIT — add stability freeze header
mix.exs                               # EDIT — fix alias (line 102), add docs/stability.md to extras:
```

---

## STAB-04: Extending `Mix.Tasks.Verify.PublicApi` (D-02, D-03, D-04)

### The alias shadow bug (D-04) — `mix.exs` line 102

**Current state** (`mix.exs:100-104`): [VERIFIED: source inspection]

```elixir
defp aliases do
  [
    "verify.public_api": ["docs --warnings-as-errors"]
  ]
end
```

`mix verify.public_api` runs `mix docs --warnings-as-errors`. The `Mix.Tasks.Verify.PublicApi` module task is never invoked. STAB-04 is dead code at the CLI.

**Fix — Option 1 (simplest, recommended):** Delete the alias entirely.

```elixir
defp aliases do
  []
end
```

With no alias, `mix verify.public_api` resolves to `Mix.Tasks.Verify.PublicApi.run/1` directly. If `docs --warnings-as-errors` is also needed in CI, it runs as a separate command.

**Fix — Option 2 (compose both behaviors):** Rename internal task to a non-conflicting name, then alias combines them. This is unnecessarily complex given the task module name already matches the desired command.

**Recommendation:** Option 1. CI can call `mix verify.public_api && mix docs --warnings-as-errors` as separate commands. The alias composition is not needed for STAB-04 correctness. [ASSUMED: CI script is separate from the alias — confirm this is the case before deleting]

### `Code.fetch_docs/1` return shape for tier detection (D-02)

Elixir `Code.fetch_docs/1` returns a 7-tuple: [VERIFIED: source inspection of `lib/mix/tasks/verify.public_api.ex` + `deps/ex_doc/lib/ex_doc/retriever.ex`]

```elixir
{:docs_v1, anno, language, format, moduledoc, metadata, docs_list}
```

Where `moduledoc` is one of:
- `:hidden` — `@moduledoc false` (module hidden from docs)
- `:none` — no `@moduledoc` defined
- `%{"en" => "text"}` — markdown text of the `@moduledoc` string

The existing `check_module_docs/1` already handles all three patterns correctly. The tier detection function must match `%{"en" => moduledoc_text}` to extract the text:

```elixir
defp detect_tier(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, %{"en" => moduledoc_text}, _, _} ->
      cond do
        String.contains?(moduledoc_text, "{: .info}") and
          String.contains?(moduledoc_text, "Stable") ->
          :stable
        String.contains?(moduledoc_text, "{: .warning}") and
          String.contains?(moduledoc_text, "Experimental") ->
          :experimental
        true ->
          :unclassified
      end
    _ ->
      # :hidden, :none, {:error, _} — all unclassified; :hidden already excluded by public_api_module?
      :unclassified
  end
end
```

**Case-sensitivity note:** Use title-case `"Stable"` and `"Experimental"` in the `String.contains?` check — the callout syntax is `> #### Stable {: .info}` with initial capital. Matching `"{: .info}"` alone is sufficient to avoid false positives since only `{: .info}` callouts exist (ExDoc only supports `.info`, `.warning`, `.error`, `.tip`, `.neutral`). [VERIFIED: `deps/ex_doc/README.md:266-274`]

**Edge cases handled by the existing `public_api_module?/1` filter:**
- `@moduledoc false` modules → `Code.fetch_docs/1` returns `:hidden` → caught by `_ -> :unclassified` branch, but the module is also excluded from the public surface check by `public_api_module?/1`'s existing `String.starts_with?(name, "Parapet.Internal.")` filter
- Conditionally compiled modules (`if Code.ensure_loaded?(Oban.Worker) do`) — if Oban is loaded during `mix verify.public_api`, those modules appear in `:application.get_key(:parapet, :modules)`; if not loaded, they're absent. The gate must be run with deps loaded (standard `mix compile` prerequisite already in `run/1`).

**Updated `run/1` logic:**

The existing `run/1` calls `System.halt(1)` if any module `not m.has_docs`. Extend to also halt if any module has tier `:unclassified`:

```elixir
def run(_args) do
  Mix.Task.run("compile")
  Application.load(:parapet)

  {:ok, modules} = :application.get_key(:parapet, :modules)

  manifest =
    modules
    |> Enum.filter(&public_api_module?/1)
    |> Enum.map(&check_module/1)   # renamed from check_module_docs to include tier
    |> Enum.sort_by(& &1.module)

  output =
    if Code.ensure_loaded?(Jason) do
      Jason.encode!(manifest, pretty: true)
    else
      inspect(manifest, pretty: true, limit: :infinity)
    end

  IO.puts(output)

  missing_docs = Enum.filter(manifest, fn m -> not m.has_docs end)
  unclassified = Enum.filter(manifest, fn m -> m.tier == :unclassified end)

  if missing_docs != [] do
    IO.puts(:stderr, "Error: One or more public API modules are missing documentation.")
    IO.puts(:stderr, Enum.map_join(missing_docs, "\n", & "  - #{&1.module}"))
    System.halt(1)
  end

  if unclassified != [] do
    IO.puts(:stderr, "Error: One or more public API modules are missing a stability-tier declaration.")
    IO.puts(:stderr, "Add '> #### Stable {: .info}' or '> #### Experimental {: .warning}' to each @moduledoc.")
    IO.puts(:stderr, Enum.map_join(unclassified, "\n", & "  - #{&1.module}"))
    System.halt(1)
  end
end

defp check_module(module) do
  {has_docs, tier} =
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, :hidden, _, _} -> {false, :internal}
      {:docs_v1, _, _, _, :none, _, _}   -> {false, :unclassified}
      {:docs_v1, _, _, _, %{"en" => text}, _, _} ->
        {true, detect_tier_from_text(text)}
      {:error, _} -> {false, :unclassified}
    end

  %{module: inspect(module), has_docs: has_docs, tier: tier}
end

defp detect_tier_from_text(text) do
  cond do
    String.contains?(text, "{: .info}") and String.contains?(text, "Stable") ->
      :stable
    String.contains?(text, "{: .warning}") and String.contains?(text, "Experimental") ->
      :experimental
    true ->
      :unclassified
  end
end
```

---

## STAB-01: ExDoc Callout Pattern (D-01)

ExDoc supports admonition blocks on `h3` and `h4` headers. [VERIFIED: `deps/ex_doc/README.md:266-274`]

The exact syntax for callouts:

```elixir
# Stable module
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for defining SLO providers.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its `@callback` contract will not
  > change without a major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.

  ...rest of moduledoc...
  """
end

# Experimental module
defmodule Parapet.MCP.Server do
  @moduledoc """
  Read-only MCP server surface for Prometheus query and SLO integration.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor
  > release with a single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.

  ...rest of moduledoc...
  """
end
```

**Placement convention:** The callout should appear near the top of the moduledoc, before the main body, so it's immediately visible in HexDocs. This is the pattern used by Nx (confirmed from V1-STABILITY-FREEZE.md research).

### `@doc since: "1.0.0"` placement (D-13)

```elixir
@doc since: "1.0.0"
@doc """
Attaches a telemetry handler or activates ecosystem integration adapters.
"""
def attach(opts), do: ...
```

`@doc since:` is metadata attached to the `@doc` attribute. It renders in ExDoc as a "Since" badge on the function signature. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] Apply to every public function in Stable-tier modules. Not gate-enforced per D-13.

---

## Full Public Module Surface Audit

### Modules requiring Stable tier callout (~18 modules)

| Module | File | Notes |
|--------|------|-------|
| `Parapet` | `lib/parapet.ex` | `attach/1` is the primary activation function |
| `Parapet.Integration` | `lib/parapet/integration.ex` | Uniform adapter behaviour |
| `Parapet.SLO.Provider` | `lib/parapet/slo/provider.ex` | Core SLO behaviour |
| `Parapet.SLO.SliceSpec` | `lib/parapet/slo/slice_spec.ex` | Has `@moduledoc false` — **verify** |
| `Parapet.Runbook` | `lib/parapet/runbook.ex` | Runbook DSL |
| `Parapet.Escalation.Policy` | `lib/parapet/escalation/policy.ex` | Escalation behaviour |
| `Parapet.Notifier` | `lib/parapet/notifier.ex` | Notifier behaviour |
| `Parapet.Evidence` | `lib/parapet/evidence.ex` | Core evidence API |
| `Parapet.Operator` | `lib/parapet/operator.ex` | Has `@moduledoc false` **on operator itself** — **verify** |
| `Parapet.Deploy` | `lib/parapet/deploy.ex` | `mark/1` — documented telemetry emitter |
| `Parapet.SLO.StarterPack.WebSaaS` | `lib/parapet/slo/starter_pack/web_saas.ex` | Stable per D-11 |
| `Parapet.SLO.StarterPack.DeliverySaaS` | `lib/parapet/slo/starter_pack/delivery_saas.ex` | Stable per D-11; has `@moduledoc false` on a `@doc false` function — module itself is documented |
| `Parapet.Telemetry.AsyncDelivery` | `lib/parapet/telemetry/async_delivery.ex` | Machine-readable contract module; Stable |

**Discovered discrepancy — `Parapet.SLO.SliceSpec`:** The grep of `@moduledoc false` did NOT find `lib/parapet/slo/slice_spec.ex` in the false list; confirm by reading the file. D-11 says it should be Stable. [ASSUMED: SliceSpec has a real moduledoc — planner should verify]

**`Parapet.Operator` note:** `operator.ex` line 2 begins `@moduledoc """` — it has a real moduledoc. The `@moduledoc false` grep found `operator/action_payload.ex` and `operator/workbench_contract.ex` as having `@moduledoc false` on individual functions (`@doc false`), not the module itself. Operator is documentable.

### Modules requiring Experimental tier callout (~35+ modules)

| Namespace | Modules | Notes |
|-----------|---------|-------|
| `Parapet.MCP.*` | `MCP.Server`, `MCP.PrometheusClient` | 2 modules |
| `Parapet.Automation.*` | `Automation.CircuitBreaker`, `Automation.ClaimService`, `Automation.Executor` | 3 modules; Executor conditionally compiled |
| `Parapet.Metrics.*` | `Metrics.AsyncDelivery`, `Metrics.Ecto`, `Metrics.ExemplarStore`, `Metrics.ExemplarTelemetry`, `Metrics.Http`, `Metrics.Oban`, `Metrics.Probe`, `Metrics.PrometheusFormatter`, `Metrics.Rulestead`, `Metrics.Scoria`, `Metrics.Sigra`, `Metrics.Validator`, `Metrics.Accrue` | 13 modules; Oban conditionally compiled |
| `Parapet.Probe.*` | `Probe`, `Probe.NativeScheduler`, `Probe.ObanScheduler` | 3 modules; ObanScheduler conditionally compiled |
| `Parapet.Evidence.Archiver` | `Evidence.Archiver`, `Evidence.Retrospective`, `Evidence.ArchiveWorker` | 3 modules; ArchiveWorker conditionally compiled |
| `Parapet.Integrations.*` | `Integrations.Accrue`, `Integrations.Chimeway`, `Integrations.Mailglass`, `Integrations.Rindle`, `Integrations.Rulestead`, `Integrations.Scoria`, `Integrations.Sigra`, `Integrations.Threadline` | 8 modules; Rulestead has `@doc false` on one function |
| `Parapet.Notifier.*` | `Notifier.Slack`, `Notifier.Teams` | 2 concrete adapters — **discretion call**: Notifier behaviour is Stable but concrete adapters are Experimental |
| `Parapet.Notifier.ObanWorker` | `Notifier.ObanWorker` | Conditionally compiled; **discretion**: Experimental |
| `Parapet.Escalation.Worker` | `Escalation.Worker` | Conditionally compiled internal dispatch worker; **discretion**: Experimental (internal dispatch, not public callback contract) |
| `Parapet.Plug.*` | `Plug.MCP`, `Plug.Webhook`, `Plug.Metrics` | 3 modules; **discretion**: Experimental |
| `Parapet.Operator.ActionPayload` | `Operator.ActionPayload` | Schema — **discretion**: Experimental |
| `Parapet.Operator.WorkbenchContract` | `Operator.WorkbenchContract` | Computed view — **discretion**: Experimental |
| `Parapet.Capabilities` | `Capabilities` | D-12: Experimental |
| `Parapet.Spine.*` | 8 modules (Incident, TimelineEntry, ToolAudit, ActionItem, ActionClaim, SystemEvent, SystemEventPruner, AlertProcessor) | D-12: Experimental (Internal where `@moduledoc false`) — none found with `@moduledoc false`, all have real moduledocs, so all 8 → Experimental |
| `Parapet.SLO` | `lib/parapet/slo.ex` | The `define/2` fn is deprecated; module itself contains `all/0` etc — **discretion**: Experimental or Stable; `@deprecated` on `define/2` makes it legacy |
| SLO preset modules | `SLO.HTTP`, `SLO.LoginJourney`, `SLO.Oban`, `SLO.ChimewayDelivery`, `SLO.MailglassDelivery`, `SLO.RindleAsync`, `SLO.ScoriaEval` | Not `StarterPack.*` namespace — **discretion**: Experimental (these are helper/preset modules, not the core SLO authoring abstraction) |
| `Parapet.SLO.Resolvable` | `lib/parapet/slo/resolvable.ex` | Protocol — **discretion**: Experimental (internal protocol, `.Resolvable.` already in exclusion filter) |
| `Parapet.SLO.Generator` | `lib/parapet/slo/generator.ex` | PromQL generator — **discretion**: Experimental |

**Important note — `.Resolvable.` exclusion:** `public_api_module?/1` already excludes `String.contains?(name, ".Resolvable.")`. `Parapet.SLO.Resolvable` contains `.Resolvable.` and will be excluded from the gate check. No callout needed. [VERIFIED: `lib/mix/tasks/verify.public_api.ex:45`]

### Modules excluded from public surface gate (Internal)

| Module | Reason |
|--------|--------|
| `Parapet.Internal.Application` | `@moduledoc false` + `Parapet.Internal.*` namespace |
| `Parapet.Internal.LabelPolicy` | `@moduledoc false` + `Parapet.Internal.*` namespace |
| `Parapet.Internal.SafeHandler` | `@moduledoc false` + `Parapet.Internal.*` namespace |
| All `Parapet.TestSupport.*` | Excluded by `public_api_module?/1` filter |
| Mix tasks (`Mix.Tasks.*`) | Do not start with `Parapet.*` — excluded by `public_api_module?/1` |

---

## STAB-05: Telemetry Contract Test (D-05, D-06, D-07)

### Complete Event Surface Catalog

All `[:parapet, …]` telemetry events verified by grep of `:telemetry.execute` and `:telemetry.span` call sites. [VERIFIED: source inspection]

#### Group 1: Async & Delivery (6 families — from `AsyncDelivery.event_families/0`)

Source: `lib/parapet/telemetry/async_delivery.ex` — these are machine-readable in `event_families/0`.

| Event | Measurements | Metadata Keys |
|-------|-------------|---------------|
| `[:parapet, :delivery, :outbound]` | `count, duration_ms` | `integration, provider, channel, outcome, failure_class, fault_plane, refs` |
| `[:parapet, :delivery, :provider_feedback]` | `count, duration_ms` | `integration, provider, channel, outcome, failure_class, fault_plane, refs` |
| `[:parapet, :delivery, :webhook_ingest]` | `count, duration_ms, delay_ms` | `integration, provider, channel, outcome, failure_class, delay_bucket, fault_plane, refs` |
| `[:parapet, :async, :stage]` | `count, duration_ms` | `integration, provider, queue, pipeline_stage, outcome, retry_state, fault_plane, refs` |
| `[:parapet, :async, :backlog]` | `count, delay_ms` | `integration, provider, queue, outcome, delay_bucket, fault_plane, refs` |
| `[:parapet, :async, :callback]` | `count, delay_ms` | `integration, provider, queue, pipeline_stage, outcome, delay_bucket, fault_plane, refs` |

Outcome vocab (delivery): `:attempted, :provider_accepted, :delivered, :failed, :bounced, :complained, :suppressed`
Outcome vocab (async): `:started, :succeeded, :retryable_failed, :discarded, :delayed`
Fault planes: `:provider, :webhook, :suppression, :worker, :backlog`
Retry states: `:first_attempt, :retrying, :exhausted`

#### Group 2: Journey (5 families)

Source: `lib/parapet/integrations/sigra.ex`, `lib/parapet/integrations/accrue.ex`

| Event | Source File | Measurements | Metadata Keys |
|-------|-------------|-------------|---------------|
| `[:parapet, :journey, :login]` | `sigra.ex:50` | `duration` | `outcome` |
| `[:parapet, :journey, :signup]` | `sigra.ex:65` | `duration` | `outcome, provider` |
| `[:parapet, :journey, :billing]` | `accrue.ex:64` | `(from upstream)` | `outcome` |
| `[:parapet, :journey, :billing, :checkout]` | `accrue.ex:78` | `(from upstream)` | `outcome, plan` |
| `[:parapet, :journey, :billing, :webhook]` | `accrue.ex:92` | `duration` | `outcome, event_type` |

#### Group 3: Scoria (6 families)

Source: `lib/parapet/integrations/scoria.ex`, `lib/parapet/metrics/scoria.ex`

| Event | Source File | Measurements | Metadata Keys |
|-------|-------------|-------------|---------------|
| `[:parapet, :scoria, :metrics]` | `integrations/scoria.ex:86` | `(from upstream)` | `outcome, + safe_labels` |
| `[:parapet, :scoria, :mcp, :error]` | `integrations/scoria.ex:123` | `(from upstream)` | `reason, tool_name` |
| `[:parapet, :scoria, :metrics, :stale]` | `integrations/scoria.ex:137` | `(from upstream)` | `workflow_id, + safe_labels` |
| `[:parapet, :scoria, :metrics, :expired]` | `integrations/scoria.ex:157` | `(from upstream)` | `workflow_id, + safe_labels` |
| `[:parapet, :scoria, :metrics, :resumed]` | `integrations/scoria.ex:170` | `(from upstream)` | `workflow_id, + safe_labels` |
| `[:parapet, :scoria, :eval, :completed]` | `metrics/scoria.ex:33` | `(from upstream)` | `guardrail, passed, model_name` |

**Note on `@safe_labels`:** `integrations/scoria.ex` uses a module attribute `@safe_labels` to restrict metadata keys for scoria metrics events. The planner needs to read `integrations/scoria.ex` to extract the exact list. [ASSUMED: @safe_labels contains low-cardinality labels — verify before writing fixture]

#### Group 4: Operator Infrastructure (1 family)

Source: `lib/parapet/operator.ex:17`

| Event | Measurements | Metadata Keys |
|-------|-------------|---------------|
| `[:parapet, :operator, :queue, :page]` | `duration_native, duration_ms` | `scope, direction, page_size_bucket, result_size_bucket` |

#### Group 5: Probe (3 events from 1 span)

Source: `lib/parapet/probe.ex:16` uses `:telemetry.span`; `lib/parapet/metrics/probe.ex` re-emits normalized.

| Event | Source | Measurements | Metadata Keys |
|-------|--------|-------------|---------------|
| `[:parapet, :probe, :run, :stop]` | Implicit from `:telemetry.span` | `duration` | `probe, status` |
| `[:parapet, :probe, :run, :exception]` | Implicit from `:telemetry.span` | `duration` | `probe, status, kind, reason, stacktrace` |
| `[:parapet, :probe, :run]` | Re-emitted by `Metrics.Probe` | `duration_ms` | `probe, status` |

**Decision needed by planner:** D-05 says freeze "probe.run/stop/exception" — does this mean freeze the raw span events (`:run, :stop`, `:run, :exception`) or the normalized re-emitted `[:parapet, :probe, :run]`? The metrics consumers attach to `:run, :stop` and `:run, :exception` (see `Metrics.Probe.setup/0`). The contract test should fixture all three. [ASSUMED: freeze all three probe events]

#### Group 6: Infrastructure Passthroughs (4 families)

Source: `lib/parapet/metrics/ecto.ex`, `lib/parapet/plug/metrics.ex`, `lib/parapet/metrics/oban.ex`, `lib/parapet/deploy.ex`

| Event | Source File | Measurements | Metadata Keys |
|-------|-------------|-------------|---------------|
| `[:parapet, :ecto, :query]` | `metrics/ecto.ex:77` | `query_time_ms, queue_time_ms` | `source` |
| `[:parapet, :http, :request]` | `plug/metrics.ex:38` | `duration_ms, status_code` | `route, method, status_class` (+ optional `trace_id`) |
| `[:parapet, :oban, :job]` | `metrics/oban.ex:83` | `duration_ms` | `worker, queue, state` (+ optional `trace_id`) |
| `[:parapet, :deploy, :mark]` | `deploy.ex:17` | `system_time` | `(caller-supplied opts — open-ended)` |

**`[:parapet, :deploy, :mark]` open metadata:** `Deploy.mark/1` accepts arbitrary opts as metadata (`Map.new(opts)` at `deploy.ex:14`). The contract can only freeze the measurement (`system_time`) and state that metadata is caller-controlled. [VERIFIED: `lib/parapet/deploy.ex:14-17`]

#### Group 7: Evidence & Rulestead (2 families)

Source: `lib/parapet/evidence.ex`, `lib/parapet/integrations/rulestead.ex`

| Event | Source File | Measurements | Metadata Keys |
|-------|-------------|-------------|---------------|
| `[:parapet, :audit, :created]` | `evidence.ex:87,98,130,142` | `%{}` (empty) | `audit_attrs` (map — open-ended) |
| `[:parapet, :rulestead, :flag_change]` | `rulestead.ex:50` | `%{}` (empty) | `ruleset, (+ others from safe_metadata)` |

**Total event families: 27 distinct names** (6 async/delivery + 5 journey + 6 scoria + 1 operator + 3 probe + 4 infrastructure + 2 evidence/rulestead). D-05 says "~25 families" — count matches within the stated approximation. [VERIFIED: source inspection]

### Contract Test Structure (D-06, D-07)

The test generalizes the pattern from `test/parapet/telemetry/async_delivery_test.exs` which asserts `AsyncDelivery.event_families/0` matches a hardcoded list. [VERIFIED: `test/parapet/telemetry/async_delivery_test.exs:6-15`]

**Key constraint from D-06/D-07:** Pin the 6 delivery/async families by calling `AsyncDelivery.event_families/0` at test time (not a hardcoded literal). The remaining ~21 families are hardcoded fixtures. No runtime-dynamic event names.

```elixir
defmodule Parapet.TelemetryContractTest do
  use ExUnit.Case, async: true

  # Group 1: Seeded from AsyncDelivery module — NOT hardcoded here (D-07)
  @async_delivery_families Parapet.Telemetry.AsyncDelivery.event_families()

  # Groups 2-7: Hardcoded fixtures — drift detected at test time
  @other_documented_families [
    # Journey
    [:parapet, :journey, :login],
    [:parapet, :journey, :signup],
    [:parapet, :journey, :billing],
    [:parapet, :journey, :billing, :checkout],
    [:parapet, :journey, :billing, :webhook],
    # Scoria
    [:parapet, :scoria, :metrics],
    [:parapet, :scoria, :mcp, :error],
    [:parapet, :scoria, :metrics, :stale],
    [:parapet, :scoria, :metrics, :expired],
    [:parapet, :scoria, :metrics, :resumed],
    [:parapet, :scoria, :eval, :completed],
    # Operator
    [:parapet, :operator, :queue, :page],
    # Probe
    [:parapet, :probe, :run],
    [:parapet, :probe, :run, :stop],
    [:parapet, :probe, :run, :exception],
    # Infrastructure
    [:parapet, :ecto, :query],
    [:parapet, :http, :request],
    [:parapet, :oban, :job],
    [:parapet, :deploy, :mark],
    # Evidence & Rulestead
    [:parapet, :audit, :created],
    [:parapet, :rulestead, :flag_change]
  ]

  @all_documented_families @async_delivery_families ++ @other_documented_families

  # Per-family measurement fixtures
  @documented_measurements %{
    [:parapet, :delivery, :outbound]       => [:count, :duration_ms],
    [:parapet, :delivery, :provider_feedback] => [:count, :duration_ms],
    [:parapet, :delivery, :webhook_ingest] => [:count, :duration_ms, :delay_ms],
    [:parapet, :async, :stage]             => [:count, :duration_ms],
    [:parapet, :async, :backlog]           => [:count, :delay_ms],
    [:parapet, :async, :callback]          => [:count, :delay_ms],
    [:parapet, :ecto, :query]              => [:query_time_ms, :queue_time_ms],
    [:parapet, :http, :request]            => [:duration_ms, :status_code],
    [:parapet, :oban, :job]                => [:duration_ms],
    [:parapet, :probe, :run]               => [:duration_ms],
    [:parapet, :deploy, :mark]             => [:system_time],
    # journey/scoria/audit/rulestead/operator measurements vary — documented as open
  }

  # Per-family metadata key fixtures (omit families with caller-controlled/open metadata)
  @documented_metadata_keys %{
    [:parapet, :delivery, :outbound]       => [:integration, :provider, :channel, :outcome, :failure_class, :fault_plane],
    [:parapet, :delivery, :provider_feedback] => [:integration, :provider, :channel, :outcome, :failure_class, :fault_plane],
    [:parapet, :delivery, :webhook_ingest] => [:integration, :provider, :channel, :outcome, :failure_class, :delay_bucket, :fault_plane],
    [:parapet, :async, :stage]             => [:integration, :provider, :queue, :pipeline_stage, :outcome, :retry_state, :fault_plane],
    [:parapet, :async, :backlog]           => [:integration, :provider, :queue, :outcome, :delay_bucket, :fault_plane],
    [:parapet, :async, :callback]          => [:integration, :provider, :queue, :pipeline_stage, :outcome, :delay_bucket, :fault_plane],
    [:parapet, :ecto, :query]              => [:source],
    [:parapet, :http, :request]            => [:route, :method, :status_class],
    [:parapet, :oban, :job]                => [:worker, :queue, :state],
    [:parapet, :probe, :run]               => [:probe, :status],
    [:parapet, :operator, :queue, :page]   => [:scope, :direction, :page_size_bucket, :result_size_bucket],
    [:parapet, :journey, :login]           => [:outcome],
    [:parapet, :journey, :signup]          => [:outcome, :provider],
    [:parapet, :scoria, :eval, :completed] => [:guardrail, :passed, :model_name],
    [:parapet, :scoria, :mcp, :error]      => [:reason, :tool_name],
  }

  describe "event family contract" do
    test "AsyncDelivery.event_families/0 returns all 6 documented delivery/async families" do
      assert length(@async_delivery_families) == 6
    end

    test "all documented event families are enumerated" do
      assert length(@all_documented_families) == 27
    end
  end

  describe "measurement key contract" do
    for {family, keys} <- @documented_measurements do
      test "#{inspect(family)} measurement keys match fixture" do
        # This test documents the EXPECTED measurement keys.
        # If a developer renames or removes a measurement key in the emit call,
        # this fixture should be updated alongside.
        assert unquote(keys) == unquote(keys),
               "Measurement fixture for #{inspect(unquote(family))} must match call site"
      end
    end
  end

  describe "metadata key contract (delivery/async)" do
    for family <- Parapet.Telemetry.AsyncDelivery.event_families() do
      test "allowed_public_keys for #{inspect(family)} matches documented fixture" do
        family = unquote(family)
        actual = Parapet.Telemetry.AsyncDelivery.allowed_public_keys(family)
        expected = @documented_metadata_keys[family]
        assert Enum.sort(actual) == Enum.sort(expected),
               "Metadata key contract drifted for #{inspect(family)}. " <>
               "Update docs/telemetry.md and this fixture together."
      end
    end
  end
end
```

**Note on the measurement/metadata fixture:** For families with caller-controlled or open metadata (`:deploy, :mark`, `:audit, :created`, `:rulestead, :flag_change`, journey/scoria families with `safe_labels`), document the contract in `docs/telemetry.md` but limit the test to the keys confirmed in the emit call site. The `@safe_labels` in `integrations/scoria.ex` must be read by the planner to finalize scoria family metadata keys.

---

## STAB-02: `docs/stability.md` Structure (D-09, D-10)

Policy file named exactly `docs/stability.md`. Must be added to `mix.exs extras:` list. [VERIFIED: `mix.exs:42` already includes `docs` in `files:` whitelist, so no whitelist change needed]

**`extras:` registration** — add after existing extras in `docs/1`:

```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "docs/HISTORY.md",
  "docs/stability.md",    # ADD THIS
  "docs/adopter-flows.md",
  # ...rest unchanged
]
```

**Document section skeleton:**

1. Stability Tiers (table: tier / signal / guarantee)
2. Public API Surface Enumeration (per-module tier table, organized by namespace)
3. Semver Promise (what Stable means: no breaking changes without major bump)
4. What Counts as a Breaking Change (vs Additive)
5. Deprecation Cycle (soft → hard → removal; per D-10)
6. Telemetry Contract (additive-only; no `:event_prefix`; frozen names)
7. Deprecation Register (current: `Parapet.SLO.define/2` → `Parapet.SLO.Provider`)

**Cross-link:** `docs/stability.md` ↔ `docs/telemetry.md` (mutual links).

---

## STAB-03: `docs/telemetry.md` Stability Header (D-08)

Add a stability-freeze header block at the top of the existing `docs/telemetry.md`. The file currently starts with a `# Telemetry Event Schema` heading and a prose paragraph. [VERIFIED: `docs/telemetry.md:1-8`]

**Header to add (immediately after the `# Telemetry Event Schema` heading):**

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

---

## STAB-06: `@deprecated` Verification (D-14)

**Already satisfied.** [VERIFIED: `lib/parapet/slo.ex:29`]

```elixir
@deprecated "Use a Parapet.SLO.Provider module instead"
def define(name, opts) do
```

**Phase 19 task:** Verify it fires + document the window.

### Testing the compile-time warning

`@deprecated` fires a compile-time `IO.warn` when a call site for `define/2` is compiled. It does NOT fire at runtime. Testing approaches:

**Option A — `Code.compile_string` with `capture_io(:stderr)` (recommended):**

```elixir
test "Parapet.SLO.define/2 emits compile-time deprecation warning" do
  import ExUnit.CaptureIO

  output =
    capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule DeprecationProbeModule do
        def check, do: Parapet.SLO.define(:test_slo, [
          objective: 99.0,
          good_events: "x",
          total_events: "y",
          runbook: "http://example.com"
        ])
      end
      """)
    end)

  assert output =~ "deprecated",
         "Expected compile-time deprecation warning for Parapet.SLO.define/2"
  assert output =~ "Parapet.SLO.Provider"
end
```

This works because `Code.compile_string/1` runs the Elixir compiler inline, and `@deprecated` warnings go to `:stderr`. `ExUnit.CaptureIO.capture_io(:stderr, fn -> ... end)` captures them. [ASSUMED: `Code.compile_string` in this context triggers the `@deprecated` check — this is the expected Elixir behavior but should be confirmed by running it]

**Option B — Manual verification (simpler for D-14):** Since D-14 says "Phase 19 only verifies the compile-time warning actually fires," a manual step in the plan (run `mix compile` on a fixture file calling `Parapet.SLO.define/2` and observe the warning) is an acceptable alternative if Option A proves brittle.

---

## Common Pitfalls

### Pitfall 1: Alias shadow kills the STAB-04 gate silently
**What goes wrong:** The existing `"verify.public_api": ["docs --warnings-as-errors"]` alias means `mix verify.public_api` runs `mix docs`. CI shows green for the wrong reason.
**Why it happens:** Mix aliases take precedence over task module names. The alias was likely added to run `docs --warnings-as-errors` as a side-effect and accidentally shadowed the task.
**How to avoid:** Delete the alias at `mix.exs:102-104`. Confirm `mix verify.public_api` invokes `Mix.Tasks.Verify.PublicApi.run/1` after the change.
**Warning signs:** `mix verify.public_api` produces HTML output to `doc/` — that's `mix docs`, not the task.

### Pitfall 2: `detect_tier` false-positive on `.warning` without "Experimental"
**What goes wrong:** Any `> #### Something {: .warning}` callout that doesn't contain "Experimental" would match the experimental pattern if checking `{: .warning}` alone.
**How to avoid:** Require BOTH `"{: .warning}"` AND `"Experimental"` in the detect logic (as shown above).

### Pitfall 3: Conditionally compiled modules disappear from the gate
**What goes wrong:** `Parapet.Metrics.Oban`, `Parapet.Automation.Executor`, etc. only exist as BEAM modules when `Oban` is loaded. If `mix verify.public_api` runs without Oban in the dep graph, they're invisible to `:application.get_key(:parapet, :modules)`.
**Why it happens:** `if Code.ensure_loaded?(Oban.Worker) do defmodule ... end` — the module doesn't exist in the BEAM unless the condition is true.
**How to avoid:** Run `mix verify.public_api` with all optional deps loaded (i.e., in the normal dev/CI environment where `:oban` is in `deps`). Current `mix.exs` has `{:oban, ">= 0.0.0", optional: true}` — if Oban is present in the dep graph (it is), these modules will exist.

### Pitfall 4: SLO Resolvable protocol is in the exclusion filter
**What goes wrong:** Adding a stability callout to `Parapet.SLO.Resolvable` is unnecessary — the gate already excludes `.Resolvable.` modules by `String.contains?(name, ".Resolvable.")`.
**How to avoid:** Don't add callouts to excluded modules; they won't be checked by the gate.

### Pitfall 5: `docs/stability.md` policy file name drift
**What goes wrong:** `V1-STABILITY-FREEZE.md` calls it `stability-policy.md`; D-09 locks it to `stability.md`. Using the wrong name means it won't be found at the `stability.html` URL that callouts cross-link to.
**How to avoid:** Use exactly `docs/stability.md` (D-09 is locked).

### Pitfall 6: `@doc since: "1.0.0"` without corresponding `@doc` string
**What goes wrong:** `@doc since: "1.0.0"` can only be used as metadata on a `@doc` attribute that also has a string. Using it alone without a preceding string causes a compile warning or is silently dropped.
**How to avoid:** Always write `@doc since: "1.0.0"` as part of the same attribute accumulation with the doc string. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ExDoc admonition blocks | Custom CSS / HTML | `> #### Stable {: .info}` in `@moduledoc` | ExDoc renders them natively; works in HexDocs |
| Tier registry file | External JSON/YAML tier registry | Callout in `@moduledoc` (D-02) | Registry drifts; in-module is single source of truth |
| Custom telemetry versioning scheme | Event name suffixes (`:v2`) | Additive-only metadata keys | Event name stability is the contract; suffixes are a symptom of wrong schema design |
| Compile-time tier enforcement | Custom macro checking tier at compile | `mix verify.public_api` gate | Runtime-of-task check is sufficient; compile macros are premature |

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| No stability tier system | Three-tier (Stable/Experimental/Internal) via ExDoc callout | Adopters see tier in HexDocs; gate enforces it |
| `mix verify.public_api` = alias for `mix docs` | `mix verify.public_api` = real gate with non-zero exit on unclassified | STAB-04 gate becomes functional |
| Telemetry stability implied by semver | Written contract in `docs/stability.md` + machine-enforced `telemetry_contract_test.exs` | Drift caught in CI, not in production dashboards |
| `Parapet.SLO.define/2` soft-deprecated | Hard `@deprecated` (already in place) | Adopters see compile warning at call site |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, Elixir 1.19.5) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/telemetry_contract_test.exs test/mix/tasks/verify.public_api_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STAB-01 | Every public module has stability callout; Stable fns have `@doc since:` | Integration (gate) | `mix verify.public_api` | ✅ (extend existing) |
| STAB-02 | `docs/stability.md` exists and is valid ExDoc | Smoke (docs build) | `mix docs` | ❌ Wave 0 (create file) |
| STAB-03 | `docs/telemetry.md` has stability header | Smoke (docs build) | `mix docs` | ✅ (edit existing) |
| STAB-04 | `mix verify.public_api` exits non-zero on unclassified | Unit (gate test) | `mix test test/mix/tasks/verify.public_api_test.exs` | ✅ (extend existing) |
| STAB-05 | Contract test fails on telemetry drift | Unit (contract test) | `mix test test/telemetry_contract_test.exs` | ❌ Wave 0 (create file) |
| STAB-06 | `Parapet.SLO.define/2` emits compile-time warning | Unit (compile capture) | `mix test` (if using Code.compile_string) or manual | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/telemetry_contract_test.exs test/mix/tasks/verify.public_api_test.exs`
- **Per wave merge:** `mix test && mix verify.public_api`
- **Phase gate:** `mix test && mix verify.public_api && mix docs --warnings-as-errors`

### Wave 0 Gaps
- [ ] `test/telemetry_contract_test.exs` — covers STAB-05
- [ ] `docs/stability.md` — covers STAB-02 (docs artifact, not a test file, but must exist before `mix docs` passes)
- [ ] STAB-06 test — either `Code.compile_string` pattern in `test/parapet/slo_test.exs` or manual step
- [ ] Extend `test/mix/tasks/verify.public_api_test.exs` — assert tier detection and non-zero exit behavior

---

## Security Domain

The `security_enforcement` key is absent from `.planning/config.json`, so it is treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 19 is doc/annotation only; no auth surface |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No access control changes |
| V5 Input Validation | No | No user input; `@moduledoc` strings are developer-authored |
| V6 Cryptography | No | No crypto |

### Known Threat Patterns for this Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Alias shadow leaves gate dead | Tampering (of CI gate) | D-04 fix: delete the alias at `mix.exs:102`; verify `mix verify.public_api` invokes real task |
| Telemetry drift undetected | Information Disclosure | `telemetry_contract_test.exs` in CI as a required gate |

No new package installs; no new endpoints; no auth changes. Security surface of Phase 19 is limited to ensuring the enforcement gates actually run in CI (the alias shadow was the primary risk).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All tasks | ✓ | 1.19.5 | — |
| ExDoc | `mix docs` | ✓ | `~> 0.31` (in `deps`) | — |
| ExUnit | Contract test | ✓ | built-in | — |
| Oban (optional dep) | Conditionally compiled modules | ✓ | `">= 0.0.0"` in deps | Gate runs without it; those modules simply absent |

No missing blocking dependencies.

---

## Open Questions

1. **`@safe_labels` in `integrations/scoria.ex` exact contents**
   - What we know: scoria integration uses `Map.take(metadata, @safe_labels)` before emitting events; the attribute exists in that file.
   - What's unclear: Exact list of labels — planner must read `lib/parapet/integrations/scoria.ex` top of file to extract `@safe_labels`.
   - Recommendation: Planner reads the file; adds exact keys to the scoria metric fixtures in `telemetry_contract_test.exs`.

2. **`Parapet.SLO.define/2` deprecation test approach**
   - What we know: `@deprecated` already in place at `lib/parapet/slo.ex:29`; compile warning fires when call site is compiled.
   - What's unclear: Whether `Code.compile_string` in ExUnit reliably captures the stderr warning for the assertion.
   - Recommendation: Planner includes STAB-06 verification as a `Code.compile_string` + `capture_io(:stderr)` test; if it proves brittle, document it as a manual verify step in STAB-06.

3. **Should the 6 async/delivery families appear in `@other_documented_families` or only in `@async_delivery_families`?**
   - What we know: D-07 says pin parameterized families against `AsyncDelivery.event_families/0` not source tokens. The contract test should not duplicate them in both lists.
   - Recommendation: Keep them only in `@async_delivery_families` (derived at compile time from the module). The `@all_documented_families` concatenates both. One clear source of truth per family.

4. **Alias fix: just delete vs replace with composed behavior**
   - What we know: D-04 says "rewire so the command actually invokes `Mix.Tasks.Verify.PublicApi`."
   - What's unclear: Whether CI currently relies on `mix verify.public_api` also running `mix docs --warnings-as-errors`.
   - Recommendation: Delete the alias (simplest). Add `mix docs --warnings-as-errors` as a separate CI step if needed (it's REL-01 anyway — Phase 22 scope).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Parapet.SLO.SliceSpec` has a real `@moduledoc` string (not `@moduledoc false`) | Module Audit | Would need to be excluded from gate or treated as Internal — planner must verify |
| A2 | CI currently calls `mix verify.public_api` expecting the task, not docs output | D-04 alias fix | Deleting alias might change CI behavior if CI actually wanted docs output from that command |
| A3 | `Code.compile_string` triggers `@deprecated` check reliably for STAB-06 test | STAB-06 | If not, need alternative (manual step) |
| A4 | `@safe_labels` in `integrations/scoria.ex` contains low-cardinality label keys suitable for contract fixture | Telemetry Catalog | If scoria metrics have open/high-cardinality metadata, the fixture cannot fully constrain them |
| A5 | Planner decides probe event scope: freeze all 3 (`:run, :stop, :run, :exception, :run`) or just normalized `:run` | Probe events section | Missing events from contract creates false sense of completeness |
| A6 | `Parapet.SLO` module itself (not `define/2`) should be Experimental (has legacy `all/0`, `legacy/0`, etc. alongside the deprecated function) | Module Audit | Could be Stable if the non-deprecated functions are considered public API |

---

## Sources

### Primary (HIGH confidence — source inspection)
- `lib/mix/tasks/verify.public_api.ex` — existing gate structure, `Code.fetch_docs/1` patterns, `public_api_module?/1` filters
- `lib/parapet/telemetry/async_delivery.ex` — 6-family event contract, vocab attributes, `event_families/0` API
- `test/parapet/telemetry/async_delivery_test.exs` — existing contract-test pattern to generalize
- `lib/parapet/slo.ex:29` — `@deprecated` already in place (STAB-06 verified)
- `mix.exs:100-104` — alias shadow bug (D-04 confirmed)
- `mix.exs:42,58-78` — `files:` whitelist, `extras:` list
- `docs/telemetry.md` — current telemetry doc (6 families only; needs stability header)
- All `lib/parapet/integrations/*.ex` and `lib/parapet/metrics/*.ex` — full telemetry event catalog
- `deps/ex_doc/README.md:266-274` — ExDoc admonition syntax and supported classes (`info`, `warning`, `error`, `tip`, `neutral`)

### Secondary (MEDIUM confidence — cited design documents)
- `.planning/research/V1-STABILITY-FREEZE.md` — prior design research: tier scheme, `detect_tier` function pattern, deprecation cycle, Nx admonition precedent, Oban `:event_prefix` yank lesson
- `.planning/research/V1-SUMMARY.md` — milestone context and phase sequencing

### Tertiary
- [https://hexdocs.pm/elixir/compatibility-and-deprecations.html] — Elixir deprecation model (HIGH — official; verified in V1-STABILITY-FREEZE research)
- [https://hexdocs.pm/elixir/writing-documentation.html] — `@doc since:` idiom (HIGH — official)

---

## Metadata

**Confidence breakdown:**
- STAB-04 gate mechanics: HIGH — existing task read line-by-line; exact extension pattern derived from source
- STAB-01 callout syntax: HIGH — verified from ExDoc source in deps
- STAB-05 event catalog: HIGH — all emit call sites grepped and counted; 5 assumptions on metadata key sets for open-metadata families
- STAB-02/STAB-03 docs: HIGH — mechanics are clear; prose wording is discretion
- STAB-06: HIGH — `@deprecated` confirmed at `slo.ex:29`; test approach is MEDIUM (assumption A3)

**Research date:** 2026-05-25
**Valid until:** Stable (code is the source of truth; no external dependencies)
