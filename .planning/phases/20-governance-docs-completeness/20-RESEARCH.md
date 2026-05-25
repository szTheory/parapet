# Phase 20: Governance & Docs Completeness — Research

**Researched:** 2026-05-25
**Domain:** Elixir/Hex OSS governance docs, ExDoc configuration, integration guide authoring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Security disclosure via GitHub Private Vulnerability Reporting. URL: `https://github.com/szTheory/parapet/security/advisories/new`. No email address. Enable in repo Settings → Code security and analysis before merging.
- **D-02:** README version matrix: Elixir 1.19+, OTP 26–28, Postgres 14+. Parenthetical: "CI validates on Elixir 1.19 / OTP 27 / PG 14."
- **D-03:** Four `groups_for_extras` sections — Getting Started (`README.md`, `docs/getting-started.md`), Guides (`docs/adopter-flows.md`, `docs/operator-ui.md`, `docs/slo-authoring-guide.md`, `docs/troubleshooting.md`, `docs/HISTORY.md`, `CHANGELOG.md`), Integration Guides (`docs/integrations/*.md` — all 8), Reference (`docs/stability.md`, `docs/telemetry.md`, `docs/slo-reference.md`).
- **D-04:** Set `main: "getting-started"` in `mix.exs` docs config (replaces `main: "readme"`).
- **D-05:** `CODE_OF_CONDUCT.md` → Contributor Covenant v2.1.
- **D-06:** `CONTRIBUTING.md` scope: `mix test`, `mix credo`, `mix dialyzer`, Conventional Commits + `mix format`, PR flow. No interactive setup wizard.
- **D-07:** All three governance docs at repo root. Add to `mix.exs` `files:` whitelist with globs: `CONTRIBUTING*`, `SECURITY*`, `CODE_OF_CONDUCT*`.
- **D-08:** All four new integration guides (Chimeway, Mailglass, Rindle, Scoria) follow `docs/integrations/sigra.md` template exactly: prerequisites → what it unlocks → activation → config keys → troubleshooting.
- **D-09:** File locations: `docs/integrations/chimeway.md`, `docs/integrations/mailglass.md`, `docs/integrations/rindle.md`, `docs/integrations/scoria.md`. Add all four to `mix.exs` `extras:`.
- **D-10:** Add Provider-as-bundle section to `docs/slo-authoring-guide.md` (not a separate file). Reference `Parapet.SLO.StarterPack.DeliverySaaS`. Cross-link from `docs/slo-reference.md`.

### Claude's Discretion

- Exact wording of the `SECURITY.md` disclosure template (triage timelines, responsible disclosure language).
- Exact wording of the README 1.0 semver commitment paragraph.
- Per-integration config keys and troubleshooting content — derive from integration modules' docstrings and existing test/fixture data.
- Whether `docs/HISTORY.md` and `CHANGELOG.md` appear in Guides or listed separately — default to Guides.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GOV-01 | `CONTRIBUTING.md` covering `mix test`, `mix credo`, `mix dialyzer`, Conventional Commits + formatter, PR flow | D-06 locked; sigra.md template confirms local proof pattern; no external prerequisite |
| GOV-02 | `SECURITY.md` documenting vulnerability-disclosure process | D-01 locked (GitHub PVR URL); standard SECURITY.md template structure confirmed |
| GOV-03 | `CODE_OF_CONDUCT.md` (Contributor Covenant or equivalent) | D-05 locked (CC v2.1); standard text available verbatim |
| GOV-04 | README 1.0 semver commitment + Elixir/OTP/Postgres version matrix | D-02 locked; README location and content shape confirmed by reading README.md |
| GOV-05 | Governance docs in Hex `files:` whitelist | D-07 locked; current `files:` in mix.exs read and confirmed |
| DOCS-01 | Chimeway integration guide | D-08/D-09; chimeway.ex read; template confirmed from sigra.md |
| DOCS-02 | Mailglass integration guide | D-08/D-09; mailglass.ex read; template confirmed |
| DOCS-03 | Rindle integration guide | D-08/D-09; rindle.ex read; template confirmed |
| DOCS-04 | Scoria integration guide | D-08/D-09; scoria.ex + Parapet.Metrics.Scoria read; template confirmed |
| DOCS-05 | Provider-as-bundle pattern in SLO authoring guide | D-10; DeliverySaaS source read; slo-authoring-guide.md current state confirmed |
| DOCS-06 | HexDocs grouped extras + getting-started as landing page | D-03/D-04; current mix.exs docs config read; target shape locked |
</phase_requirements>

---

## Summary

Phase 20 is a documentation and configuration phase — no new runtime code. It closes eleven requirements across two categories: OSS governance trust artifacts (GOV-01 through GOV-05) and documentation completeness (DOCS-01 through DOCS-06). All decisions were locked in CONTEXT.md; research confirms feasibility and surfaces the exact content to write for each artifact.

The three governance docs (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`) are new files at repo root, each with well-established community templates that are directly adaptable to this project's toolchain. The four integration guides (Chimeway, Mailglass, Rindle, Scoria) copy the `docs/integrations/sigra.md` template structure, with content derived entirely from the existing integration module source code already read in this research. The `mix.exs` changes are a single file: switch `main:`, restructure `groups_for_extras:`, extend `extras:`, and extend `files:`.

All content sources exist in the codebase. No external packages are installed. No runtime code changes are required.

**Primary recommendation:** Work in artifact order — governance docs first (simplest, most boilerplate), then integration guides (content from existing source), then mix.exs wiring (single file, high dependency), then in-place doc additions (slo-authoring-guide.md, README.md, slo-reference.md cross-link).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OSS governance docs | Repository root (static files) | Hex package `files:` whitelist | Governance docs live at root by convention; whitelist ensures they ship with the package |
| Integration guide authoring | `docs/integrations/` (static Markdown) | `mix.exs` `extras:` list | ExDoc picks up guides via `extras:`; content derives from lib source |
| HexDocs navigation | `mix.exs` docs config | ExDoc build | `groups_for_extras:` and `main:` are the only levers; no code changes |
| README version commitment | `README.md` (static Markdown) | — | Plain README edit; no tooling involved |
| Provider-as-bundle pattern doc | `docs/slo-authoring-guide.md` (static Markdown) | `docs/slo-reference.md` cross-link | In-place addition to existing guide; reference module already exists |

---

## Standard Stack

### Core (no new packages — documentation-only phase)

This phase installs zero external packages. All tooling is already present in the project.

| Tool | Version | Purpose |
|------|---------|---------|
| ExDoc | `~> 0.31` (already in mix.exs) | Renders `extras:` into hexdocs; `groups_for_extras:` drives navigation |
| mix.exs `package/0` | N/A | `files:` whitelist controls what ships in the Hex package |

[VERIFIED: codebase grep — mix.exs line 97]

### ExDoc Configuration Keys (relevant to this phase)

[VERIFIED: codebase grep — mix.exs lines 53–79]

Current `docs/0` in mix.exs:
- `main: "readme"` → change to `"getting-started"` (D-04)
- `extras:` list (11 entries currently) → add 4 integration guides + governance docs if needed
- `groups_for_extras:` currently `[Guides: ~r/docs\//]` → replace with 4-group structure (D-03)
- `files:` in `package/0` currently `~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs)` → add `CONTRIBUTING* SECURITY* CODE_OF_CONDUCT*` (D-07)

---

## Package Legitimacy Audit

> This phase installs no external packages. No audit required.

**Packages removed due to slopcheck:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Repo Root
├── CONTRIBUTING.md  (new — GOV-01)        → Hex package (via files: whitelist)
├── SECURITY.md      (new — GOV-02)        → Hex package (via files: whitelist)
├── CODE_OF_CONDUCT.md (new — GOV-03)      → Hex package (via files: whitelist)
├── README.md        (edit — GOV-04)       → hexdocs "Getting Started" group
└── mix.exs          (edit — GOV-05, DOCS-06)
      ├── package.files → adds CONTRIBUTING* SECURITY* CODE_OF_CONDUCT*
      └── docs
            ├── main: "getting-started"
            ├── extras: adds 4 new integration guides
            └── groups_for_extras: 4-group structure

docs/
├── integrations/
│   ├── sigra.md     (existing template)
│   ├── chimeway.md  (new — DOCS-01) ← content from lib/parapet/integrations/chimeway.ex
│   ├── mailglass.md (new — DOCS-02) ← content from lib/parapet/integrations/mailglass.ex
│   ├── rindle.md    (new — DOCS-03) ← content from lib/parapet/integrations/rindle.ex
│   └── scoria.md    (new — DOCS-04) ← content from lib/parapet/integrations/scoria.ex
├── slo-authoring-guide.md  (edit — DOCS-05) + Provider-as-bundle section
└── slo-reference.md        (edit — DOCS-05 cross-link)
```

### Recommended File Creation Order

1. `CODE_OF_CONDUCT.md` — pure boilerplate, no research needed at write time
2. `SECURITY.md` — fixed URL from D-01, standard triage language
3. `CONTRIBUTING.md` — project-specific but short (4 sections from D-06)
4. `docs/integrations/chimeway.md` — derive from chimeway.ex
5. `docs/integrations/mailglass.md` — derive from mailglass.ex
6. `docs/integrations/rindle.md` — derive from rindle.ex
7. `docs/integrations/scoria.md` — derive from scoria.ex (most complex)
8. Edit `docs/slo-authoring-guide.md` — append Provider-as-bundle section
9. Edit `docs/slo-reference.md` — add cross-link
10. Edit `README.md` — add semver commitment + version matrix
11. Edit `mix.exs` — single edit touching `package/0` and `docs/0`

### mix.exs Target State

**`package/0` `files:` list (D-07):**
```elixir
files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* CODE_OF_CONDUCT* LICENSE* docs)
```

**`docs/0` `main:` (D-04):**
```elixir
main: "getting-started"
```

**`docs/0` `extras:` additions (D-09):**
Add to the existing extras list:
```elixir
"docs/integrations/chimeway.md",
"docs/integrations/mailglass.md",
"docs/integrations/rindle.md",
"docs/integrations/scoria.md"
```

**`docs/0` `groups_for_extras:` replacement (D-03):**
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

Note: using `~r|docs/integrations/|` regex for Integration Guides ensures all 8 guides (4 existing + 4 new) are captured without enumerating each path. This matches the pattern used in the existing `groups_for_extras: [Guides: ~r/docs\//]`. [VERIFIED: codebase grep — mix.exs line 77]

### Integration Guide Template (from sigra.md)

[VERIFIED: codebase read — docs/integrations/sigra.md]

Shape to replicate exactly:
1. **Title:** `# Parapet + [Integration Name]`
2. **Intro paragraph:** One sentence describing the library, one sentence on what Parapet does when attached.
3. **`## Prerequisites`** — library as optional dep caveat (handlers dormant if absent), `mix parapet.install` as prerequisite.
4. **`## What it unlocks`** — bullet list of emitted metrics with tag annotations, plus any pre-built SLO provider note or "no pre-built SLO" note with link to authoring guide.
5. **`## Activation`** — `Parapet.attach(adapters: [:name])` code block listing the exact telemetry event atoms handled.
6. **`## Config keys`** — table or prose describing Parapet-level config (or "no config keys" if none).
7. **`## Troubleshooting`** — `###` subheadings for each known failure mode.

### Anti-Patterns to Avoid

- **Inventing new template sections:** Every guide must match sigra.md exactly. No adding sections not in the template.
- **Using `main: "readme"` keyword for getting-started:** ExDoc `main:` takes the filename stem without extension and without path prefix. `"getting-started"` resolves to `docs/getting-started.md` because ExDoc strips the path. [ASSUMED — based on ExDoc convention; verify by checking ExDoc docs if uncertain]
- **Listing integration guide files individually in `groups_for_extras:`:** Use the `~r|docs/integrations/|` regex so new guides added later are automatically grouped.
- **Forgetting that `files:` in `package/0` is separate from `extras:` in `docs/0`:** `extras:` controls what ExDoc includes; `files:` controls what Hex publishes. Governance docs at root need both: they are already reachable to ExDoc via their `extras:` entry if added, but they need `files:` globs to ship in the Hex package.
- **Adding governance docs to `extras:`:** The locked decisions (D-03) do NOT include `CONTRIBUTING.md`, `SECURITY.md`, or `CODE_OF_CONDUCT.md` in any ExDoc group — they go in `files:` only. Only `README.md` and `CHANGELOG.md` appear in hexdocs extras (already present).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Code of Conduct text | Custom policy | Contributor Covenant v2.1 verbatim | De facto OSS standard; verbatim text from contributorcovenant.org |
| Integration guide structure | Novel format | sigra.md template exactly | Consistency across 8 guides; adopters scan by pattern |
| PromQL or telemetry event names in guides | Derive from memory | Read from integration module source directly | Source of truth is the `@events` module attributes and `process_event/3` clauses |
| ExDoc navigation regex | Custom glob logic | `~r|docs/integrations/|` | ExDoc accepts Elixir regex in `groups_for_extras`; simpler and future-proof |

---

## Integration Guide Content — Derived from Source

### Chimeway (`docs/integrations/chimeway.ex`)

[VERIFIED: codebase read]

- **Library:** email/notification library
- **Handler ID:** `"parapet-chimeway-delivery-events"`
- **Telemetry events listened:** `[:chimeway, :event, :failed]` (single event via `:telemetry.attach/4`)
- **What Parapet emits:** re-emits to `[:parapet, :delivery, :provider_feedback]` or `[:parapet, :delivery, :webhook_ingest]` depending on `callback_delay?/1` check
- **Metadata shape:** `integration: :chimeway`, `provider`, `channel: :notification`, `outcome: :failed`, `failure_class`, `fault_plane`, `delay_bucket`
- **Config keys:** none at Parapet level (no `Application.get_env` calls in module)
- **Pre-built SLO provider:** `Parapet.SLO.ChimewayDelivery` (referenced in slo-reference.md — slices: `chimeway_provider_acceptance`, `chimeway_callback_confirmation`, `chimeway_callback_freshness`)
- **Troubleshooting to cover:** duplicate attach conflict (same `@handler_id`), metrics not appearing (reporter wiring), callback_delay vs provider_feedback routing distinction

### Mailglass (`lib/parapet/integrations/mailglass.ex`)

[VERIFIED: codebase read]

- **Library:** email library
- **Handler ID:** `"parapet-mailglass-delivery"`
- **Telemetry events listened:** `[:mailglass, :outbound, :send, :stop]`, `[:mailglass, :reconcile, :stop]`, `[:mailglass, :webhook, :ingest, :exception]` (via `:telemetry.attach_many/4`)
- **What Parapet emits:**
  - `[:parapet, :delivery, :outbound]` for send stop
  - `[:parapet, :delivery, :provider_feedback]` for reconcile stop
  - `[:parapet, :delivery, :webhook_ingest]` for webhook exception
- **Metadata shape:** `integration: :mailglass`, `provider`, `channel: :email`, `outcome`, `fault_plane`, optional `failure_class`, `delay_bucket`; refs: `message_id`, `delivery_id`, `provider_message_id`
- **Config keys:** none at Parapet level
- **Pre-built SLO provider:** `Parapet.SLO.MailglassDelivery` (slices: `mailglass_submit_acceptance`, `mailglass_confirmed_delivery`, `mailglass_webhook_freshness`, `mailglass_suppression_drift`)
- **Troubleshooting:** duplicate attach, reporter wiring, latency_ms field in webhook events

### Rindle (`lib/parapet/integrations/rindle.ex`)

[VERIFIED: codebase read]

- **Library:** media processing library
- **Handler ID:** `"parapet-rindle-async"`
- **Telemetry events listened:** `[:rindle, :media, :started]`, `[:rindle, :media, :processed]`, `[:rindle, :media, :failed]`, `[:rindle, :media, :discarded]`, `[:rindle, :media, :backlog]`, `[:rindle, :media, :callback_delayed]`, `[:rindle, :media, :reconciliation_delayed]`
- **What Parapet emits:**
  - `[:parapet, :async, :stage]` for started/processed/failed/discarded
  - `[:parapet, :async, :backlog]` for backlog
  - `[:parapet, :async, :callback]` for callback_delayed and reconciliation_delayed
- **Metadata shape:** `integration: :rindle`, `provider`, `queue`, `pipeline_stage` (normalized), `outcome`, `retry_state`, `fault_plane`, `delay_bucket`; refs: `job_id`, `webhook_id`
- **Config keys:** none at Parapet level
- **Pre-built SLO provider:** `Parapet.SLO.RindleAsync` (slices: `rindle_terminal_success`, `rindle_queue_freshness`, `rindle_callback_freshness`, `rindle_long_running_stage`, `rindle_funnel_regression`)
- **Troubleshooting:** duplicate attach, `pipeline_stage` normalization (string → atom), retry_state inference from `attempt`/`attempt_number` metadata

### Scoria (`lib/parapet/integrations/scoria.ex` + `lib/parapet/metrics/scoria.ex`)

[VERIFIED: codebase read]

- **Library:** AI/LLM library (tools, workflows, config, MCP)
- **Handler IDs:** `"parapet-scoria-telemetry"`, `"parapet-scoria-config-telemetry"`, `"parapet-scoria-mcp-telemetry"`, `"parapet-scoria-workflow-telemetry"`, `"parapet-scoria-eval-handler"` (via Parapet.Metrics.Scoria.setup())
- **Telemetry events listened:**
  - `[:scoria, :sre, :telemetry]` → emits `[:parapet, :scoria, :metrics]` + creates incident on error
  - `[:scoria, :config, :deployed]` → creates incident with runbook_data
  - `[:scoria, :mcp, :tool, :exception]` → emits `[:parapet, :scoria, :mcp, :error]`
  - `[:scoria, :workflow, :stale]` → emits `[:parapet, :scoria, :metrics, :stale]` + creates action item
  - `[:scoria, :workflow, :expired]` → emits `[:parapet, :scoria, :metrics, :expired]`
  - `[:scoria, :workflow, :resumed]` → emits `[:parapet, :scoria, :metrics, :resumed]` + resolves action item if not paused
  - `[:scoria, :eval, :completed]` → emits `[:parapet, :scoria, :eval, :completed]` (via Metrics.Scoria)
- **Safe labels (low-cardinality):** `[:model, :provider, :tool_name]` — the module explicitly strips high-cardinality metadata
- **Prometheus metrics** (from Metrics.Scoria):
  - `scoria_evaluation_total` — counter, tags: `guardrail`, `passed`, `model_name`
  - `scoria_mcp_errors_total` — counter, tags: `reason`, `tool_name`
- **Config keys:** none at Parapet level (reads Scoria.Workflow via `Code.ensure_loaded?` at runtime)
- **Pre-built SLO provider:** none (unlike Chimeway/Mailglass/Rindle — the Scoria integration is about evidence/incidents + eval metrics, not delivery SLOs)
- **Notable:** Scoria is the only integration that creates incidents (`Parapet.Evidence.create_incident/1`) and action items (`Parapet.Evidence.create_action_item/1`) directly — relevant for "what it unlocks" section
- **Cross-link to telemetry.md:** relevant since telemetry.md is the frozen contract and the Scoria guide should note that the `[:parapet, :scoria, …]` events follow the same additive-only rules

### Provider-as-Bundle Pattern (DOCS-05)

[VERIFIED: codebase read — lib/parapet/slo/starter_pack/delivery_saas.ex]

Content for the new section in `docs/slo-authoring-guide.md`:

**What:** A `Parapet.SLO.Provider` that implements `slos/0` returning a list combining multiple sub-providers' slices is the bundle abstraction. No separate macro or abstraction is needed.

**Canonical example:** `Parapet.SLO.StarterPack.DeliverySaaS` — its `slos/0` calls `WebSaaS.slos() ++ delivery_slices(Mailglass, Chimeway)`, composing 10 slices from 3 providers with conditional registration guards (`Code.ensure_loaded?/1`).

**Key points to document:**
- Register one provider in `config :parapet, providers: [...]` to activate multiple slice sets
- Conditional registration pattern: `if Code.ensure_loaded?(SomeLib), do: SomeProvider.slos(), else: []`
- The provider itself is always loadable (passes `mix verify.public_api`) regardless of host lib presence
- Cross-link target: `Parapet.SLO.StarterPack.DeliverySaaS` moduledoc

---

## Common Pitfalls

### Pitfall 1: ExDoc `main:` value format
**What goes wrong:** Setting `main: "docs/getting-started"` or `main: "getting-started.md"` instead of `main: "getting-started"`.
**Why it happens:** ExDoc resolves the extras page identifier by stripping path prefix and `.md` extension. The value is the bare stem, not a path.
**How to avoid:** Use `"getting-started"` exactly (no path, no extension). [ASSUMED — based on ExDoc convention]
**Warning signs:** HexDocs landing page still shows README or 404.

### Pitfall 2: `files:` glob ordering matters
**What goes wrong:** Placing new governance doc globs after `docs` causes Hex to include them (docs is a directory glob), but they would have been missed without explicit globs since they are at root.
**Why it happens:** `docs` in the `files:` list captures the whole `docs/` directory. Root-level `.md` files not matching existing globs (`README*`, `CHANGELOG*`, `LICENSE*`) are silently excluded from the package.
**How to avoid:** Add explicit globs `CONTRIBUTING*`, `SECURITY*`, `CODE_OF_CONDUCT*` to `files:`. The locked decision D-07 specifies this exactly.
**Warning signs:** `mix hex.build --dry-run` output does not list the governance files.

### Pitfall 3: Governance docs accidentally added to `extras:`
**What goes wrong:** Adding `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` to `extras:` causes them to appear in hexdocs navigation, which looks wrong (they belong on GitHub, not hexdocs).
**Why it happens:** Confusion between "ship in package" (files:) and "appear in hexdocs" (extras:).
**How to avoid:** Only add governance docs to `files:` whitelist, not to `extras:`. Cross-link from README to GitHub URLs instead.

### Pitfall 4: Scoria guide omitting the incident/action-item behavior
**What goes wrong:** Guide only covers the telemetry metrics path, missing the evidence spine integration (incidents, action items).
**Why it happens:** The metrics path is the most visible but Scoria uniquely also calls `Parapet.Evidence.create_incident/1` and `create_action_item/1`.
**How to avoid:** "What it unlocks" section must mention both the Prometheus metrics AND the incident/action-item creation. This is the Scoria integration's distinct value proposition.

### Pitfall 5: Rindle guide failing to list all 7 telemetry events
**What goes wrong:** Guide lists only a subset of the 7 Rindle events.
**Why it happens:** Rindle has the most complex event mapping (7 events → 3 async families).
**How to avoid:** Read the `@events` module attribute directly: all 7 are listed. The guide activation section should list all 7.

### Pitfall 6: `groups_for_extras` regex match overlap
**What goes wrong:** The `Guides: ~r/docs\//` pattern (current) matches ALL `docs/` files including `docs/integrations/*`, causing integration guides to appear in the general Guides group instead of Integration Guides.
**Why it happens:** The replacement must be done carefully — `Integration Guides` regex must be evaluated before a broader `docs/` catch-all.
**How to avoid:** Replace the entire `groups_for_extras:` block rather than appending. ExDoc evaluates groups in order; list Integration Guides before any broad `docs/` pattern. Using explicit file lists for Guides (rather than a regex) avoids the ordering issue entirely. D-03 specifies explicit file lists for Getting Started, Guides, and Reference — only Integration Guides uses a regex.

---

## Code Examples

### Verified mix.exs `groups_for_extras` Pattern

```elixir
# Source: mix.exs line 76-78 (current), to be replaced per D-03
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

[VERIFIED: codebase read — mix.exs; target shape from D-03]

### Verified `files:` Whitelist Target

```elixir
# Source: mix.exs line 42-43 (current), extended per D-07
files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* CODE_OF_CONDUCT* LICENSE* docs)
```

[VERIFIED: codebase read — mix.exs line 42]

### Verified Integration Activation Pattern (from sigra.md)

```elixir
# For Chimeway — adapter atom is :chimeway
Parapet.attach(adapters: [:chimeway])

# For Mailglass — adapter atom is :mailglass
Parapet.attach(adapters: [:mailglass])

# For Rindle — adapter atom is :rindle
Parapet.attach(adapters: [:rindle])

# For Scoria — adapter atom is :scoria
Parapet.attach(adapters: [:scoria])
```

[VERIFIED: codebase read — sigra.md activation pattern; handler_id names in each .ex confirm atom conventions]

### Verified SLO Provider Registration Pattern

```elixir
# For Chimeway + Mailglass built-in SLO providers
config :parapet,
  providers: [
    Parapet.SLO.ChimewayDelivery,
    Parapet.SLO.MailglassDelivery,
    Parapet.SLO.RindleAsync
  ]

# Or via the DeliverySaaS bundle
config :parapet, providers: [Parapet.SLO.StarterPack.DeliverySaaS]
```

[VERIFIED: codebase read — slo-reference.md, delivery_saas.ex]

### Scoria Metrics Reporter Wiring (analogous to Rulestead pattern)

```elixir
# In your Telemetry reporter setup
metrics: Parapet.Metrics.Scoria.metrics() ++ your_other_metrics()
```

[VERIFIED: codebase read — Parapet.Metrics.Scoria.metrics/0 exists; pattern from rulestead.md troubleshooting]

### Provider-as-Bundle Pattern Example

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

[VERIFIED: codebase read — delivery_saas.ex lines 57-78; this pattern is the exact reference]

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `groups_for_extras: [Guides: ~r/docs\//]` (single group) | 4-group structure: Getting Started / Guides / Integration Guides / Reference | Better hexdocs discoverability |
| `main: "readme"` | `main: "getting-started"` | Getting-started is the hexdocs landing page (DOCS-06) |
| No governance docs | CONTRIBUTING.md + SECURITY.md + CODE_OF_CONDUCT.md at root | OSS trust signal for `~> 1.0` adopters |
| 4 integration modules with no guides | 4 new guides in `docs/integrations/` | Adopters can activate Chimeway, Mailglass, Rindle, Scoria from docs |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExDoc `main:` takes bare filename stem `"getting-started"` (no path, no extension) | Architecture Patterns / Common Pitfalls | Wrong value causes hexdocs 404 landing; trivially fixed but would break D-04 |
| A2 | ExDoc evaluates `groups_for_extras` entries in order, so explicit file lists evaluated before regex avoids capture overlap | Common Pitfalls #6 | Integration guides could appear under Guides group; fix is to use explicit lists (already preferred by D-03) |

**All other claims are VERIFIED via codebase reads of mix.exs, sigra.md, chimeway.ex, mailglass.ex, rindle.ex, scoria.ex, delivery_saas.ex, slo-reference.md, slo-authoring-guide.md.**

---

## Open Questions

1. **Should governance docs appear in hexdocs extras?**
   - What we know: D-03 does not include them in any extras group. D-07 adds them to `files:` only.
   - What's unclear: Whether community convention is to include them in hexdocs or only on GitHub.
   - Recommendation: Follow D-03 and D-07 exactly — `files:` only, no `extras:` entry. GitHub links from README are sufficient.

2. **Scoria: does the guide need `Parapet.Metrics.Scoria.metrics()` reporter wiring instruction?**
   - What we know: `Parapet.Metrics.Scoria.setup()` is called from `Parapet.Integrations.Scoria.setup()`, so the handler is attached automatically. But the `metrics/0` function returning `Telemetry.Metrics` definitions for the reporter is a separate concern (as seen in the Rulestead guide troubleshooting).
   - What's unclear: Whether Scoria metrics auto-wire into the reporter or require manual wiring like Rulestead.
   - Recommendation: Include a reporter wiring note in the Scoria guide's troubleshooting section analogous to the Rulestead guide. Claude's discretion covers exact wording.

---

## Environment Availability

> Step 2.6: SKIPPED — this phase is purely Markdown file authoring and mix.exs edits. No external tools, services, runtimes, or CLIs beyond the project's existing Elixir toolchain are required.

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from `.planning/config.json` — treating as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `mix.exs` test config |
| Quick run command | `mix test` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GOV-01 | `CONTRIBUTING.md` exists at repo root | smoke (file check) | `test -f CONTRIBUTING.md` | ❌ — new file |
| GOV-02 | `SECURITY.md` exists at repo root | smoke (file check) | `test -f SECURITY.md` | ❌ — new file |
| GOV-03 | `CODE_OF_CONDUCT.md` exists at repo root | smoke (file check) | `test -f CODE_OF_CONDUCT.md` | ❌ — new file |
| GOV-04 | README contains semver commitment + matrix | manual review | `grep -i "1\.0\|OTP\|Postgres" README.md` | ✅ (README exists) |
| GOV-05 | `mix hex.build --dry-run` includes governance files | manual smoke | `mix hex.build --dry-run 2>&1 \| grep -E "CONTRIBUTING\|SECURITY\|CODE_OF_CONDUCT"` | ✅ (mix.exs exists) |
| DOCS-01 | `docs/integrations/chimeway.md` exists with correct shape | smoke (file check) | `test -f docs/integrations/chimeway.md` | ❌ — new file |
| DOCS-02 | `docs/integrations/mailglass.md` exists with correct shape | smoke (file check) | `test -f docs/integrations/mailglass.md` | ❌ — new file |
| DOCS-03 | `docs/integrations/rindle.md` exists with correct shape | smoke (file check) | `test -f docs/integrations/rindle.md` | ❌ — new file |
| DOCS-04 | `docs/integrations/scoria.md` exists with correct shape | smoke (file check) | `test -f docs/integrations/scoria.md` | ❌ — new file |
| DOCS-05 | `slo-authoring-guide.md` contains Provider-as-bundle section | smoke | `grep -i "provider-as-bundle\|bundle" docs/slo-authoring-guide.md` | ✅ (file exists; section absent) |
| DOCS-06 | `mix docs` builds without warnings; `main:` and `groups_for_extras:` correct in mix.exs | build smoke | `mix docs --warnings-as-errors` | ✅ (mix.exs exists) |

### Sampling Rate

- **Per task commit:** `mix test`
- **Per wave merge:** `mix test --warnings-as-errors && mix docs --warnings-as-errors`
- **Phase gate:** Full suite green + `mix hex.build --dry-run` governance file check before `/gsd:verify-work`

### Wave 0 Gaps

None — no new test files are required for this phase. All validation is file-existence checks, content grep, and build smoke. The `mix docs --warnings-as-errors` gate is the primary automated validation for ExDoc config correctness.

---

## Security Domain

> `security_enforcement` not set in `.planning/config.json` (key absent) — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | — (documentation phase; no user input) |
| V6 Cryptography | no | — |

No ASVS categories apply. This phase creates static Markdown files and edits `mix.exs`. There is no user input, no authentication surface, no data storage, and no network communication introduced by this phase.

### Security Note: SECURITY.md Disclosure Channel

The `SECURITY.md` file itself is a security governance artifact. The locked decision (D-01) uses GitHub Private Vulnerability Reporting rather than a maintainer email address, which is the more secure option: no email exposure, no inbox to monitor, and GitHub manages the CVE lifecycle through their CNA status. The maintainer must enable Private Vulnerability Reporting in repo Settings before merging the SECURITY.md (D-01 specifies this as a pre-merge action).

---

## Sources

### Primary (HIGH confidence — codebase reads)

- `mix.exs` — current `extras:`, `groups_for_extras:`, `files:`, `main:` (lines 42, 53–79)
- `docs/integrations/sigra.md` — golden template structure (all 5 sections)
- `lib/parapet/integrations/chimeway.ex` — handler ID, events, metadata shape
- `lib/parapet/integrations/mailglass.ex` — handler ID, events, metadata shape
- `lib/parapet/integrations/rindle.ex` — handler ID, events, metadata shape
- `lib/parapet/integrations/scoria.ex` — handler IDs, events, incident/action-item behavior
- `lib/parapet/metrics/scoria.ex` — Prometheus metric definitions and tags
- `lib/parapet/slo/starter_pack/delivery_saas.ex` — Provider-as-bundle canonical example
- `docs/slo-reference.md` — built-in provider catalog (slice names)
- `docs/slo-authoring-guide.md` — current state (no bundle section yet)
- `.planning/phases/20-governance-docs-completeness/20-CONTEXT.md` — all locked decisions
- `.planning/REQUIREMENTS.md` — GOV-01…DOCS-06 acceptance criteria

### Secondary (MEDIUM confidence — authoritative community standards)

- Contributor Covenant v2.1 — widely adopted OSS Code of Conduct; text at contributorcovenant.org
- GitHub Private Vulnerability Reporting — GitHub CNA program, GitHub Advisory Database integration

---

## Metadata

**Confidence breakdown:**
- Governance doc content: HIGH — locked decisions specify exact structure; community templates are stable
- Integration guide content: HIGH — derived directly from module source code read in this session
- ExDoc configuration: HIGH — current state read from mix.exs; target from locked D-03/D-04
- Provider-as-bundle pattern: HIGH — canonical example read from delivery_saas.ex source
- ExDoc `main:` value format (A1): MEDIUM/ASSUMED — convention-based; trivially verified by running `mix docs`

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (30 days; this is stable territory — ExDoc config, OSS governance conventions, and codebase structure are not moving)
