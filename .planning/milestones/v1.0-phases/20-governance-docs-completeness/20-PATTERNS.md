# Phase 20: Governance & Docs Completeness - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 13 new/modified files
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `CONTRIBUTING.md` | doc (governance) | static | `docs/integrations/sigra.md` (structured Markdown conventions) | partial |
| `SECURITY.md` | doc (governance) | static | `docs/integrations/sigra.md` (structured Markdown conventions) | partial |
| `CODE_OF_CONDUCT.md` | doc (governance) | static | none (pure community boilerplate) | no-analog |
| `README.md` (edit) | doc (root) | static | `README.md` itself (in-place edit) | exact |
| `mix.exs` (edit) | config | transform | `mix.exs` itself (in-place edit) | exact |
| `docs/integrations/chimeway.md` | doc (integration guide) | static | `docs/integrations/sigra.md` | exact |
| `docs/integrations/mailglass.md` | doc (integration guide) | static | `docs/integrations/sigra.md` | exact |
| `docs/integrations/rindle.md` | doc (integration guide) | static | `docs/integrations/sigra.md` | exact |
| `docs/integrations/scoria.md` | doc (integration guide) | static | `docs/integrations/rulestead.md` (no pre-built SLO, reporter wiring note) | role-match |
| `docs/slo-authoring-guide.md` (edit) | doc (guide) | static | `docs/slo-authoring-guide.md` itself + `docs/slo-reference.md` (bundle registration pattern) | exact |
| `docs/slo-reference.md` (edit) | doc (reference) | static | `docs/slo-reference.md` itself (in-place cross-link addition) | exact |

---

## Pattern Assignments

### `CONTRIBUTING.md` (new, governance doc)

**Analog:** `docs/integrations/sigra.md` (H2 section structure) + `docs/integrations/rulestead.md` (config keys prose pattern)

**Document structure pattern** — four required sections from D-06:

```markdown
## Local proof commands

Run all three before pushing:

```elixir
mix test
mix credo
mix dialyzer
```

## Commit conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`. Run `mix format` before committing — CI fails on unformatted code.

## Pull request flow

1. Fork → branch → commit.
2. Open a PR against `main`. Include a one-sentence summary and link any related issue.
3. All CI checks must be green (test, credo, dialyzer, format).
4. A maintainer will review within [N] days.

## Development setup

This is an Elixir library, not an application. You need Elixir 1.19+ and Postgres 14+. Run `mix deps.get` then `mix test` to confirm everything works.
```

**No interactive setup wizard** — D-06 explicitly excludes one. Keep setup section to "Elixir + Postgres" only.

---

### `SECURITY.md` (new, governance doc)

**Analog:** `docs/integrations/sigra.md` (prose with code URL pattern)

**Disclosure channel pattern** (D-01 locked):

```markdown
## Reporting a Vulnerability

Report security vulnerabilities via **GitHub Private Vulnerability Reporting**:

<https://github.com/szTheory/parapet/security/advisories/new>

Do not open a public GitHub issue for security vulnerabilities.
```

**Triage timeline pattern** (Claude's discretion — standard community language):

```markdown
## Disclosure Timeline

- **Acknowledgement:** within 3 business days of report receipt.
- **Initial assessment:** within 7 business days.
- **Fix or mitigation:** coordinated with reporter; target 90 days for critical issues.
- **Public disclosure:** after a fix is available, coordinated with reporter.
```

**Pre-merge prerequisite:** Maintainer must enable Private Vulnerability Reporting in repo Settings → Code security and analysis before merging (D-01).

---

### `CODE_OF_CONDUCT.md` (new, governance doc)

**Analog:** none — pure community standard text.

**Source:** Contributor Covenant v2.1 verbatim from `https://www.contributor-covenant.org/version/2/1/code_of_conduct/`. D-05 locked. No project-specific adaptation needed beyond filling in the contact method (GitHub PVR URL from D-01, or omit contact email per the same decision).

**Contact field:** Use the GitHub PVR URL `https://github.com/szTheory/parapet/security/advisories/new` as the enforcement contact point, consistent with D-01.

---

### `README.md` (edit — add semver commitment + version matrix)

**Analog:** `README.md` itself — in-place addition after the existing `## Installation` section or before it.

**Existing Installation section** (`README.md` lines 22–55):

```markdown
## Installation

Add `parapet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parapet, "~> 0.1.0"}
  ]
end
```
```

**New content to add** (GOV-04, D-02 locked — Claude's discretion on exact wording):

```markdown
## Compatibility

| Component | Supported |
|-----------|-----------|
| Elixir | 1.19+ |
| OTP | 26–28 |
| Postgres | 14+ |

CI validates on Elixir 1.19 / OTP 27 / PG 14.

## Stability & Versioning

Parapet follows [Semantic Versioning](https://semver.org/). Starting at `1.0`, the public API (modules, functions, telemetry event names, SLO slice names, and Prometheus metric names documented in hexdocs) will not break without a major-version bump. Pre-1.0 minor releases may include breaking changes noted in [CHANGELOG.md](CHANGELOG.md).
```

**Placement:** Insert the Compatibility table and Stability section between the badge block (lines 1–5) and the existing `## Features` section (line 13), or directly before `## Installation`. Either placement is acceptable — prefer before Features for discoverability.

---

### `mix.exs` (edit — package files, docs main, extras, groups_for_extras)

**Analog:** `mix.exs` itself — in-place edits to `package/0` and `docs/0`.

**Current `package/0` `files:` line** (`mix.exs` line 42):

```elixir
files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs),
```

**Target `files:` after D-07** (add three governance doc globs):

```elixir
files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* CODE_OF_CONDUCT* LICENSE* docs),
```

**Current `docs/0` `main:` line** (`mix.exs` line 55):

```elixir
main: "readme",
```

**Target `main:` per D-04:**

```elixir
main: "getting-started",
```

**Current `extras:` block** (`mix.exs` lines 58–74) — add 4 new integration guide paths (D-09):

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
  "docs/integrations/sigra.md",
  "docs/integrations/accrue.md",
  "docs/integrations/rulestead.md",
  "docs/integrations/threadline.md",
  "docs/integrations/chimeway.md",
  "docs/integrations/mailglass.md",
  "docs/integrations/rindle.md",
  "docs/integrations/scoria.md"
],
```

**Current `groups_for_extras:` block** (`mix.exs` lines 76–78):

```elixir
groups_for_extras: [
  Guides: ~r/docs\//
]
```

**Target `groups_for_extras:` per D-03** (replace entirely):

```elixir
groups_for_extras: [
  "Getting Started": ["README.md", "docs/getting-started.md"],
  Guides: [
    "docs/adopter-flows.md",
    "docs/operator-ui.md",
    "docs/slo-authoring-guide.md",
    "docs/troubleshooting.md",
    "docs/HISTORY.md",
    "CHANGELOG.md"
  ],
  "Integration Guides": ~r|docs/integrations/|,
  Reference: [
    "docs/stability.md",
    "docs/telemetry.md",
    "docs/slo-reference.md"
  ]
]
```

**Critical:** Use explicit file lists for Getting Started, Guides, and Reference groups. Use regex only for Integration Guides. This avoids the regex-overlap pitfall (Pitfall 6 from RESEARCH.md) where a broad `~r/docs\//` would swallow integration guide paths.

---

### `docs/integrations/chimeway.md` (new, integration guide)

**Analog:** `docs/integrations/sigra.md` (exact template) — all seven sections in order.

**Title pattern** (`sigra.md` line 1):

```markdown
# Parapet + Chimeway
```

**Prerequisites section** (`sigra.md` lines 5–8):

```markdown
## Prerequisites

- `chimeway` installed in your host app (optional dep — if it is absent, Chimeway never emits the telemetry events the adapter listens for, so the attached handlers stay dormant and harmless; Parapet does not probe for the `chimeway` library itself)
- Parapet installed and configured (`mix parapet.install`)
```

**What it unlocks section** — content derived from RESEARCH.md Chimeway entry. Chimeway has a pre-built SLO provider (`Parapet.SLO.ChimewayDelivery`), so reference it (unlike Rulestead which has no pre-built SLO):

```markdown
## What it unlocks

Chimeway delivery events become Parapet delivery metrics:

- `parapet_delivery_provider_feedback` — counted per `outcome`, `failure_class`, `fault_plane` tags
- `parapet_delivery_webhook_ingest` — for callback-delayed events, counted per `delay_bucket` tag

The `Parapet.SLO.ChimewayDelivery` provider uses these metrics for three slices:
`chimeway_provider_acceptance`, `chimeway_callback_confirmation`, `chimeway_callback_freshness`.
Register it in `config :parapet, providers: [Parapet.SLO.ChimewayDelivery]` and run
`mix parapet.gen.prometheus`. See [Parapet SLO Reference](docs/slo-reference.md) for the full slice catalog.
```

**Activation section** (`sigra.md` lines 23–30) — list the exact telemetry event handled:

```markdown
## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:chimeway])
```

This attaches a telemetry handler for `[:chimeway, :event, :failed]`.
```

**Config keys section** (`sigra.md` lines 32–34) — Chimeway has no Parapet-level config:

```markdown
## Config keys

The Chimeway integration has no Parapet-level config keys. It reads standard Chimeway telemetry events and re-emits them as Parapet delivery events without additional configuration.
```

**Troubleshooting section** (`sigra.md` lines 36–48) — three Q&As from RESEARCH.md Chimeway troubleshooting list:

```markdown
## Troubleshooting

### Metrics are not appearing in Prometheus

Confirm two things: (1) `Parapet.attach(adapters: [:chimeway])` was called before the first Chimeway event fired, and (2) your `Telemetry.Metrics` reporter includes metrics from the relevant `Parapet.Metrics.*` module. If the reporter is not wired, counters are defined but never scraped.

### Telemetry handler raises a conflict error on startup

A second call to `Parapet.attach(adapters: [:chimeway])` raises a telemetry conflict because the handler name `parapet-chimeway-delivery-events` is already registered. Attach each adapter exactly once at application startup.

### Events appear under provider_feedback instead of webhook_ingest (or vice versa)

Parapet routes Chimeway events based on `callback_delay?/1`. Events where a callback delay is detected are emitted as `[:parapet, :delivery, :webhook_ingest]`; all other failures are emitted as `[:parapet, :delivery, :provider_feedback]`. This routing is intentional — confirm your SLO slices are querying the correct event family.
```

---

### `docs/integrations/mailglass.md` (new, integration guide)

**Analog:** `docs/integrations/sigra.md` (exact template).

**Title:**

```markdown
# Parapet + Mailglass
```

**Prerequisites:** Same boilerplate as sigra.md / chimeway.md, substituting `mailglass`.

**What it unlocks** — three event families (outbound, reconcile, webhook) per RESEARCH.md:

```markdown
## What it unlocks

Mailglass email events become Parapet delivery metrics across three event families:

- `parapet_delivery_outbound` — send-stop events, tagged by `outcome`, `fault_plane`
- `parapet_delivery_provider_feedback` — reconcile-stop events, tagged by `outcome`, `delay_bucket`
- `parapet_delivery_webhook_ingest` — webhook exception events, tagged by `failure_class`

All events carry `integration: :mailglass`, `provider`, `channel: :email` tags. Optional ref tags: `message_id`, `delivery_id`, `provider_message_id`.

The `Parapet.SLO.MailglassDelivery` provider uses these metrics for four slices:
`mailglass_submit_acceptance`, `mailglass_confirmed_delivery`, `mailglass_webhook_freshness`,
`mailglass_suppression_drift`. See [Parapet SLO Reference](docs/slo-reference.md).
```

**Activation** — three events via `:telemetry.attach_many/4`:

```markdown
## Activation

```elixir
Parapet.attach(adapters: [:mailglass])
```

This attaches handlers for `[:mailglass, :outbound, :send, :stop]`,
`[:mailglass, :reconcile, :stop]`, and `[:mailglass, :webhook, :ingest, :exception]`.
```

**Config keys:** No Parapet-level config (same as Chimeway).

**Troubleshooting:** Duplicate attach conflict + reporter wiring + `latency_ms` field note per RESEARCH.md.

---

### `docs/integrations/rindle.md` (new, integration guide)

**Analog:** `docs/integrations/sigra.md` (exact template).

**Title:**

```markdown
# Parapet + Rindle
```

**Prerequisites:** Same boilerplate, substituting `rindle`.

**What it unlocks** — three async event families, seven source events per RESEARCH.md:

```markdown
## What it unlocks

Rindle media-processing events become Parapet async metrics across three families:

- `parapet_async_stage` — from `started`, `processed`, `failed`, `discarded` events; tagged by `pipeline_stage`, `outcome`, `retry_state`, `fault_plane`
- `parapet_async_backlog` — from `backlog` events; tagged by `queue`
- `parapet_async_callback` — from `callback_delayed` and `reconciliation_delayed` events; tagged by `delay_bucket`

All events carry `integration: :rindle`, `provider`, `queue` tags. Optional refs: `job_id`, `webhook_id`.

The `Parapet.SLO.RindleAsync` provider uses these metrics for five slices:
`rindle_terminal_success`, `rindle_queue_freshness`, `rindle_callback_freshness`,
`rindle_long_running_stage`, `rindle_funnel_regression`. See [Parapet SLO Reference](docs/slo-reference.md).
```

**Activation** — all seven events must be listed (Pitfall 5 from RESEARCH.md):

```markdown
## Activation

```elixir
Parapet.attach(adapters: [:rindle])
```

This attaches handlers for all seven Rindle events:
`[:rindle, :media, :started]`, `[:rindle, :media, :processed]`, `[:rindle, :media, :failed]`,
`[:rindle, :media, :discarded]`, `[:rindle, :media, :backlog]`,
`[:rindle, :media, :callback_delayed]`, and `[:rindle, :media, :reconciliation_delayed]`.
```

**Config keys:** No Parapet-level config.

**Troubleshooting:** Duplicate attach + `pipeline_stage` normalization (string → atom) + `retry_state` inference from `attempt`/`attempt_number` per RESEARCH.md.

---

### `docs/integrations/scoria.md` (new, integration guide)

**Analog:** `docs/integrations/rulestead.md` — specifically the "no pre-built SLO provider" + reporter wiring note pattern. Also reference `docs/stability.md` / `docs/telemetry.md` cross-link pattern.

**Title:**

```markdown
# Parapet + Scoria
```

**Prerequisites:** Same boilerplate, substituting `scoria`.

**What it unlocks** — two distinct value propositions (Pitfall 4 from RESEARCH.md: must cover both metrics AND evidence spine):

```markdown
## What it unlocks

Scoria AI/LLM events feed Parapet in two ways:

**Prometheus metrics** (via `Parapet.Metrics.Scoria`):
- `scoria_evaluation_total` — eval completion counter, tagged by `guardrail`, `passed`, `model_name`
- `scoria_mcp_errors_total` — MCP tool error counter, tagged by `reason`, `tool_name`

**Evidence spine integration** (unique to Scoria):
- Config-deployed events create `Parapet.Evidence` incident records with runbook data
- Stale workflow events create action items; resumed workflows resolve them automatically

**Reporter wiring required:** The integration attaches telemetry handlers automatically, but the Prometheus metric definitions must be registered separately:

```elixir
metrics: Parapet.Metrics.Scoria.metrics() ++ your_other_metrics()
```

There is no pre-built SLO provider for Scoria. The evaluation and MCP error counters are raw ingredients for custom slices — see [SLO authoring guide](docs/slo-authoring-guide.md).

The `[:parapet, :scoria, …]` events follow the same additive-only stability rules as all other Parapet telemetry events — see [telemetry contract](docs/telemetry.md).
```

**Activation** — multiple handler IDs via `Parapet.Metrics.Scoria.setup()`:

```markdown
## Activation

```elixir
Parapet.attach(adapters: [:scoria])
```

This attaches handlers for: `[:scoria, :sre, :telemetry]`, `[:scoria, :config, :deployed]`,
`[:scoria, :mcp, :tool, :exception]`, `[:scoria, :workflow, :stale]`,
`[:scoria, :workflow, :expired]`, `[:scoria, :workflow, :resumed]`, and `[:scoria, :eval, :completed]`.

Handler IDs: `parapet-scoria-telemetry`, `parapet-scoria-config-telemetry`,
`parapet-scoria-mcp-telemetry`, `parapet-scoria-workflow-telemetry`, `parapet-scoria-eval-handler`.
```

**Config keys:** No Parapet-level config (uses `Code.ensure_loaded?/1` at runtime for `Scoria.Workflow`).

**Troubleshooting:** Reporter wiring, duplicate attach conflict (for each of the 5 handler IDs), high-cardinality metadata (the module strips non-safe labels; only `[:model, :provider, :tool_name]` are kept).

---

### `docs/slo-authoring-guide.md` (edit — add Provider-as-bundle section)

**Analog:** `docs/slo-authoring-guide.md` itself — append a new `##` section following the existing "Writing a custom slice" section pattern.

**Existing section heading style** (`slo-authoring-guide.md` lines 39, 57 — H2 with prose + code block):

```markdown
## Writing a custom slice

When the built-in packs do not cover your journey, you define a custom provider module ...

```elixir
config :parapet,
  providers: [
    Parapet.SLO.StarterPack.WebSaaS,
    MyApp.SLO.CheckoutJourney
  ]
```
```

**New section to append** (D-10 — Provider-as-bundle pattern):

```markdown
## Provider-as-bundle pattern

A `Parapet.SLO.Provider` that returns slices from multiple sub-providers is the bundle abstraction. No separate macro or base module is required — the `slos/0` callback returns a flat list, and list concatenation is the composition primitive.

The canonical example is `Parapet.SLO.StarterPack.DeliverySaaS`, which composes three providers into one registration:

```elixir
defmodule MyApp.SLO.FullStack do
  @behaviour Parapet.SLO.Provider

  @impl true
  def slos do
    Parapet.SLO.StarterPack.WebSaaS.slos() ++
      if Code.ensure_loaded?(Mailglass), do: Parapet.SLO.MailglassDelivery.slos(), else: [] ++
      my_custom_slices()
  end

  defp my_custom_slices, do: [...]
end
```

Register the bundle provider the same way as any single provider:

```elixir
config :parapet, providers: [MyApp.SLO.FullStack]
```

**Conditional registration:** Use `Code.ensure_loaded?/1` to guard slices for optional host libraries. The bundle module itself is always loadable (passes `mix verify.public_api`) regardless of whether the guarded library is present. This is the pattern used by `Parapet.SLO.StarterPack.DeliverySaaS` — see its moduledoc for the reference implementation.

For the full built-in provider catalog and starter packs, see [Parapet SLO Reference](docs/slo-reference.md#starter-packs).
```

---

### `docs/slo-reference.md` (edit — add cross-link to Provider-as-bundle section)

**Analog:** `docs/slo-reference.md` itself — append a link to the new slo-authoring-guide section within the existing Starter Packs section.

**Current Starter Packs entry** (`slo-reference.md` lines 47–55) — add one sentence at the end of the `DeliverySaaS` bullet:

```markdown
- `Parapet.SLO.StarterPack.DeliverySaaS` — ... Delivery slices register **only when the corresponding host library is loaded** ... See the [Provider-as-bundle pattern](docs/slo-authoring-guide.md#provider-as-bundle-pattern) in the SLO authoring guide for how to build your own bundle provider.
```

---

## Shared Patterns

### Integration Guide Template Structure
**Source:** `docs/integrations/sigra.md` (lines 1–48) — golden template, all four new guides copy this structure verbatim.

Seven-section order (non-negotiable per D-08):
1. `# Parapet + [Name]` + two-sentence intro
2. `## Prerequisites` — optional dep caveat + `mix parapet.install`
3. `## What it unlocks` — bullet metrics + SLO provider note (or no pre-built SLO + link to authoring guide)
4. `## Activation` — `Parapet.attach(adapters: [:name])` + event list
5. `## Config keys` — table/prose or "no config keys" statement
6. `## Troubleshooting` — `###` Q&A subheadings

No additional sections. No reordering.

### Integration Guide "No Pre-Built SLO" Pattern
**Source:** `docs/integrations/rulestead.md` lines 23–24:

```markdown
There is no pre-built SLO provider for Rulestead flag changes. The counter is the raw ingredient for a custom slice you can author via the [SLO authoring guide](docs/slo-authoring-guide.md).
```

Apply this pattern verbatim (substituting integration name) for Scoria, which has no pre-built SLO provider.

### Integration Guide "Reporter Wiring Required" Pattern
**Source:** `docs/integrations/rulestead.md` lines 14–19:

```markdown
**Reporter wiring required (OQ-3):** The integration wires the telemetry event handler, but it does not register the metric definition with your `Telemetry.Metrics` reporter. To get `parapet_rulestead_flag_change_total` into Prometheus, you must include `Parapet.Metrics.Rulestead.metrics()` in your host app's reporter config:

```elixir
metrics: Parapet.Metrics.Rulestead.metrics() ++ your_other_metrics()
```
```

Apply this pattern to Scoria's "What it unlocks" section (with `Parapet.Metrics.Scoria.metrics()`).

### Integration Guide "Duplicate Attach Conflict" Troubleshooting Pattern
**Source:** `docs/integrations/sigra.md` lines 44–46:

```markdown
### Telemetry handler raises a conflict error on startup

If a previous call to `Parapet.attach(adapters: [:sigra])` already attached the handler with the same name (`parapet-sigra-auth`), a second call raises a telemetry conflict. Attach each adapter exactly once, typically at application startup rather than inside a request handler.
```

All four new integration guides include this troubleshooting entry, substituting the integration name and handler ID(s).

### mix.exs Config Structure
**Source:** `mix.exs` lines 40–79 — `package/0` and `docs/0` functions. The entire docs config is produced by the private `docs/0` function. Edit in-place; do not restructure the function.

### Markdown Cross-Link Convention
**Source:** `docs/integrations/sigra.md` line 19, `docs/slo-authoring-guide.md` lines 7, 36:

```markdown
[Getting started](docs/getting-started.md)
[Parapet SLO Reference](docs/slo-reference.md)
[SLO authoring guide](docs/slo-authoring-guide.md)
```

All cross-links use the bare relative path from repo root (`docs/...`), not absolute URLs. Anchor links use lowercase-hyphenated section headings (`#provider-as-bundle-pattern`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `CODE_OF_CONDUCT.md` | doc (governance) | static | No existing code-of-conduct or comparable community policy file in the codebase. Content is Contributor Covenant v2.1 verbatim — use the canonical text from contributorcovenant.org. |

---

## Metadata

**Analog search scope:** `/Users/jon/projects/parapet/docs/`, `/Users/jon/projects/parapet/docs/integrations/`, `/Users/jon/projects/parapet/mix.exs`, `/Users/jon/projects/parapet/README.md`
**Files scanned:** 8 (sigra.md, rulestead.md, mix.exs, README.md, slo-authoring-guide.md, slo-reference.md, CONTEXT.md, RESEARCH.md)
**Pattern extraction date:** 2026-05-25
