# Architecture Research

**Domain:** Elixir/Phoenix OSS SRE Library — v0.10 Adopter Success (3-pillar integration)
**Researched:** 2026-05-23
**Confidence:** HIGH (all components read directly from source; integration patterns verified against live code)

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                    EXISTING BIFURCATED CORE (unchanged)              │
├───────────────────────────────┬──────────────────────────────────────┤
│   TELEMETRY / METRICS / SLOs  │   INCIDENTS / TIMELINES / ACTIONS    │
│                               │                                      │
│  Telemetry events             │  Alertmanager webhook                │
│       ↓                       │       ↓                              │
│  Parapet.Metrics.*            │  Parapet.Spine.Incident (Ecto)       │
│       ↓                       │  Parapet.Spine.TimelineEntry (Ecto)  │
│  SLO.Provider behaviour       │  Parapet.Spine.ToolAudit (Ecto)      │
│  (config :parapet,            │  Parapet.Spine.ActionClaim (Ecto)    │
│   providers: [...])           │       ↓                              │
│       ↓                       │  Parapet.Operator                    │
│  SLO.Generator → PromQL YAML  │  (LiveView Operator UI)              │
│                               │       ↓                              │
│  *** NO ECTO HERE ***         │  Parapet.Automation.Executor (Oban)  │
│  *** NO ECTO HERE ***         │  + ClaimService + CircuitBreaker     │
└───────────────────────────────┴──────────────────────────────────────┘
         ↑ v0.10 adds SLO Pack providers here (left side only)
         ↑ v0.10 enriches runbook templates here (right side only)
```

**v0.10 integration rule:** Each pillar touches exactly one side of the bifurcation. SLO packs and authoring guidance live entirely on the telemetry/metrics side. Runbook template enrichment lives entirely on the incident/action side. The demo and docs cross neither — they sit outside the library boundary. This preserves the architecture's foundational invariant.

---

## Pillar A: SLO Starter Packs — Integration Architecture

### The Two Registration Paths (Existing)

Reading `lib/parapet/slo.ex` reveals two registration systems:

**Legacy path** (deprecated): `Parapet.SLO.HTTP.register/1`, `Parapet.SLO.Oban.register/1`, `Parapet.SLO.LoginJourney.register/1` — these store `%Parapet.SLO{}` structs in `Application.put_env(:parapet, :slos, ...)` at runtime. Marked `@deprecated "Use a Parapet.SLO.Provider module instead"` in `Parapet.SLO.define/2`.

**Provider path** (current): `config :parapet, providers: [Parapet.SLO.MailglassDelivery, ...]` — modules implementing `@behaviour Parapet.SLO.Provider` (single callback `slos/0 :: [struct()]`). Read at compile-time by `Parapet.SLO.provider_catalog/0`. `Parapet.SLO.Generator.provider_artifacts/0` feeds these into multi-burn-rate PromQL generation.

### Architectural Fit: Pack Modules as Provider Behaviour Implementations

SLO starter packs must use the **provider path**, not the legacy path. The evidence:

1. `Parapet.SLO.MailglassDelivery` and `Parapet.SLO.ChimewayDelivery` implement `@behaviour Parapet.SLO.Provider` and return `[%SliceSpec{}]` structs — this is the correct shape.
2. `Parapet.SLO.Generator.provider_artifacts/0` calls `SLO.provider_catalog/0` which calls `provider.slos()` on each registered provider — packs participate automatically with no changes to Generator.
3. `SliceSpec` already has `min_total_rate: 0.01` as a default field — this is the denominator guard for low-traffic protection, already built in.
4. Multi-burn-rate windows are hard-coded in `Generator` as `@windows ["5m", "30m", "1h", "2h", "6h", "3d"]` — pack providers get multi-burn-rate PromQL automatically.

**New modules: `lib/parapet/slo/pack/`**

```
lib/parapet/slo/pack/
  web_saas.ex         # Parapet.SLO.Pack.WebSaaS
  delivery_saas.ex    # Parapet.SLO.Pack.DeliverySaaS
```

Each is a thin coordination module that implements `@behaviour Parapet.SLO.Provider` and returns `SliceSpec` structs by delegating to existing providers.

### Critical Design Decision: Pack Modules Delegate, Not Duplicate

The existing `Parapet.SLO.HTTP`, `Parapet.SLO.Oban`, `Parapet.SLO.LoginJourney` modules use the **legacy** `register/1` pattern (Application.put_env), not the Provider behaviour. This is the key tension for pack design.

**Option A — Pack calls legacy `register/1` functions (DO NOT USE):** Mixes the two registration systems. Legacy path is deprecated. Creates a two-registry situation where `SLO.all()` must merge both sources. STACK research correctly ruled this out.

**Option B — Pack defines its own `SliceSpec` structs using the same metric names (RECOMMENDED):** Pack modules build `SliceSpec` structs pointing at the same Prometheus metric names that the existing legacy providers consume (`parapet_http_server_duration_milliseconds_count`, `parapet_oban_job_duration_milliseconds_count`, `parapet_journey_login_duration_milliseconds_count`). This is exactly the pattern used by `MailglassDelivery` and `ChimewayDelivery` — those modules define SliceSpecs from AsyncDelivery metric names directly, no delegation to a `register/1` call.

**Structural shape of `Parapet.SLO.Pack.WebSaaS`:**

```elixir
defmodule Parapet.SLO.Pack.WebSaaS do
  @moduledoc """
  Opinionated SLO starter pack for Phoenix SaaS apps with HTTP, auth, and background jobs.

  Registers three slices:
  - HTTP request availability (99.9%) — error rate across 2xx/3xx vs all requests
  - Login journey success rate (99.9%) — auth outcome via parapet_journey_login_*
  - Oban job success rate (99.5%) — lower because retries are expected

  Add to config/config.exs:

      config :parapet, providers: [Parapet.SLO.Pack.WebSaaS]

  Or via mix parapet.install --with-web-saas-pack (adds provider to config automatically).
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.SLO.SliceSpec

  @impl true
  def slos do
    [http_slice(), login_slice(), oban_slice()]
  end

  defp http_slice do
    SliceSpec.new(
      name: :pack_http_availability,
      integration: :http,
      kind: :ratio,
      good_source_metric: "parapet_http_server_duration_milliseconds_count",
      good_matchers: [status_code: ~r/2..|3../],   # expressed as label matchers
      total_source_metric: "parapet_http_server_duration_milliseconds_count",
      total_matchers: [],
      objective: 99.9,
      alert_class: :page,
      runbook: "https://example.com/runbooks/http-availability",
      group_labels: [:integration],
      summary: "HTTP request availability is burning error budget"
    )
  end
  # ... login_slice/0, oban_slice/0
end
```

**Note on metric matchers:** The existing `SliceSpec` uses `good_matchers: [key: value]` keyword list format and the `AsyncDelivery.selector/2` helper for building PromQL selectors. HTTP metrics may need to verify which helper applies or use raw PromQL-compatible label specs. This is the one place to check against `Parapet.Metrics.AsyncDelivery.selector/2` to confirm it handles HTTP label format, or write a pack-specific selector helper. This is not a blocker — it is a one-line clarification.

### Registration: `mix parapet.install --with-<pack>` Flags

`mix parapet.install` already uses `maybe_configure_providers/2` which calls `Igniter.Project.Config.configure/5` with a merge updater. Adding `--with-web-saas-pack` and `--with-delivery-saas-pack` flags to the `info/2` schema follows the same pattern as existing `--with-mailglass`/`--with-chimeway` flags. The updater merges into the providers list idempotently.

**Modified file:** `lib/mix/tasks/parapet.install.ex`
- Add two entries to the `schema:` list: `with_web_saas_pack: :boolean`, `with_delivery_saas_pack: :boolean`
- Add two entries to `defaults:`
- Add pack provider modules to `providers` list in `igniter/1` via `maybe_add`
- Add pack references to `install_summary_notice`

No new Mix task is needed. A `mix parapet.gen.slo` task would duplicate the config surface already covered by install flags.

### Low-Traffic Alerting: Where Guidance Attaches

The generator already emits `alerts.yml.eex` with a fixed template. The `min_total_rate` field on `SliceSpec` is the denominator guard — it becomes the `and parapet:name:total_rate:5m > 0.01` clause in generated alert expr (line 107 of `generator.ex`):

```
"#{ratio_record_name(spec.name, window)} > #{threshold} and #{total_rate_record_name(spec.name, window)} > #{spec.min_total_rate}"
```

**v0.10 change: add commented guidance to the alerts.yml.eex template.** The template is EEx so it can include a YAML comment block above each alert group explaining the `min_total_rate` guard and when to raise it. This is a template content change only — no Elixir code change:

```yaml
# LOW TRAFFIC NOTE: This alert includes a minimum traffic guard (total_rate > <%= spec.min_total_rate %>).
# If your service receives < 100 req/hr, consider raising this threshold or enabling a Parapet.Probe.
# See: https://hexdocs.pm/parapet/slo-authoring-guide.html#low-traffic
```

**Modified file:** `priv/templates/parapet.gen.prometheus/alerts.yml.eex`

The substantive guidance (denominator guard pattern, synthetic probe fallback, extended window approach) lives in `docs/slo-authoring-guide.md` — docs content, not code.

---

## Pillar B: Richer Recovery Templates — Integration Architecture

### What the Runbook DSL Already Supports

Reading `lib/parapet/runbook.ex` directly, the `step/2` macro accepts these keys in opts:

- `label:` — display string
- `description:` — operator-facing description
- `type:` — `:manual` or `:mitigation`
- `kind:` — `:guidance` or `:capability`
- `capability:` — atom naming the host capability
- `target_kind:` — `:async_item`, `:queue`, `:provider`, etc.
- `requires_preview: true/false` — preview gate before execution
- `preview_only: true/false` — never executes, display only
- `auto_execute: true/false` — opt-in for Executor automation
- `guidance:` — string shown to operator for manual steps

**The DSL already has all the vocabulary needed for deep templates.** There is no `warning:` key — that is a gap. Adding `warning:` would be a one-line addition to the `step/2` macro and the `__runbook_schema__` output. This is the only DSL gap exposed.

### DSL Gap: `warning:` annotation

The FEATURES.md correctly identifies that richer templates need warning annotations like `"Retrying without fixing root cause re-populates the DLQ."` The DSL step macro does not currently accumulate a `warning:` key. The fix is surgical:

**Modified file:** `lib/parapet/runbook.ex`

```elixir
defmacro step(id, opts) do
  quote do
    @steps %{
      id: unquote(id),
      label: unquote(opts)[:label],
      description: unquote(opts)[:description],
      type: unquote(opts)[:type],
      kind: unquote(opts)[:kind],
      capability: unquote(opts)[:capability],
      target_kind: unquote(opts)[:target_kind],
      requires_preview: Keyword.get(unquote(opts), :requires_preview, false),
      preview_only: Keyword.get(unquote(opts), :preview_only, false),
      auto_execute: Keyword.get(unquote(opts), :auto_execute, false),
      guidance: unquote(opts)[:guidance],
      warning: unquote(opts)[:warning]   # ADD THIS
    }
  end
end
```

The `warning:` value is a string shown in the Operator UI alongside the step. The LiveView operator templates must render it if non-nil — this is a template content change in `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`, not a behaviour change.

**No other DSL gaps are exposed.** Preconditions are expressed as `kind: :guidance, preview_only: true` steps. Post-checks are expressed as `kind: :guidance, preview_only: true` steps at the end. Bounded mitigation is expressed via `requires_preview: true` + `target_kind:`. Scope-check previews use `preview_only: true`.

### Automation.Executor + ClaimService + CircuitBreaker: No Changes Needed

The existing `Executor` → `ClaimService` → `CircuitBreaker` → `ToolAudit` chain is complete and correct for all deeper template content. The gates in `ClaimService`:

1. `incident_state_gate` — only executes for `"open"` incidents
2. `breaker_gate` — delegates to `CircuitBreaker.gate/4` which counts `ToolAudit` records within the configured window
3. `suppression_gate` — host-injectable suppression check
4. `custom_gate` — host-injectable additional gate

None of these need modification for richer templates. The new runbook templates (retry storm, suppression drift, partial backlog drain) use the same step shape as existing templates. They do not require new capabilities, new Oban queue configuration, or new Ecto schemas.

### Template Generator: Add Three New Templates

`lib/mix/tasks/parapet.gen.runbooks.ex` uses `Igniter.copy_template/5` with `on_exists: :skip`. Adding three new templates requires:

1. Create three new template files in `priv/templates/parapet.gen.runbooks/`
2. Add three `Igniter.copy_template/5` calls in `parapet.gen.runbooks` task

**New template files:**
```
priv/templates/parapet.gen.runbooks/retry_storm.ex.eex
priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex
priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex
```

**Modified file:** `lib/mix/tasks/parapet.gen.runbooks.ex` — three additional `Igniter.copy_template` calls

**`on_exists: :skip` is correct and must be preserved.** This is host-owned scaffolding. If an adopter has already run `mix parapet.gen.runbooks` and customized their templates, re-running must not overwrite them. The skip behavior is the host-ownership contract.

### Data Flow: Richer Template Execution Path

```
Alert fires → Alertmanager webhook
    ↓
Parapet.Spine.Incident created (Ecto)
    ↓
Parapet.Automation.Executor (Oban Worker) enqueued via auto_execute_on
    ↓
ClaimService.claim_action/1
  ├── incident_state_gate (open?)
  ├── breaker_gate → CircuitBreaker.gate/4 → counts ToolAudit rows
  ├── suppression_gate (host-injected)
  └── custom_gate (host-injected)
    ↓ {:won, claim}
Parapet.Operator.execute_runbook_step/3
    ↓
Host's execute_mitigation/2 callback (generated runbook module)
    ↓
ClaimService.mark_executed/2
    ↓
ToolAudit record written (Evidence.append_timeline)
    ↓
TimelineEntry record written
    ↓
Operator UI shows "System-Executed" badge + warning text (if warning: key present)
```

The richer template steps are content in this flow. The `warning:` key surfaces in the UI but does not gate execution — it is a display annotation for the operator, not an execution constraint.

---

## Pillar C: Adoption Funnel — Integration Architecture

### Demo: Isolation from Published Package

The demo sits entirely outside the library boundary:

```
parapet/                       (repo root)
  lib/                         (in files: whitelist — published)
  priv/                        (in files: whitelist — published)
  docs/                        (in files: whitelist — published)
  demo/                        (NOT in files: whitelist — git-only)
    app/
      mix.exs                  (declares {:parapet, path: "../../"})
      lib/
        demo_app/
          parapet_instrumenter.ex
          runbooks/             (generated by mix parapet.gen.runbooks)
      config/
        config.exs              (config :parapet, providers: [Parapet.SLO.Pack.WebSaaS])
    docker-compose.yml
    prometheus/
      prometheus.yml
    grafana/
      provisioning/
```

The path-dep `{:parapet, path: "../../"}` means the demo exercises the real library code from the repo, not a stale Hex snapshot. Changes to `lib/` are reflected in the demo app immediately.

**Anti-drift mechanism:** The demo app's config exercises `mix parapet.install` via committed outputs (the instrumenter, the generated Prometheus YAML). A CI check that runs `mix compile` and `mix parapet.doctor` inside `demo/app/` catches drift between the install path and the demo before it reaches adopters. This is not a full E2E browser test — just compilation + doctor health check.

### Getting-Started Guide + Troubleshooting: ExDoc Extras Integration

New docs files fit the existing ExDoc extras pattern in `mix.exs`. The current `docs:` key is absent — it needs to be added as part of v0.10 (STACK research confirms). Once added, new files in `docs/` are included via glob or explicit listing.

**New docs files:**
```
docs/
  getting-started.md           (new — the "first 30 minutes" path)
  troubleshooting.md           (new — FAQ, seeded with predictable questions)
  slo-authoring-guide.md       (new — good-vs-bad slicing + low-traffic guidance)
  integrations/
    sigra.md                   (new — login journey SLO, Parapet.attach call)
    accrue.md                  (new — billing/checkout journey)
    rulestead.md               (new — flag-change correlation)
    threadline.md              (new — audit compliance)
```

**Modified file:** `mix.exs` — add `docs:` key to `project/0` with `extras:`, `groups_for_extras:`, and `groups_for_modules:`

The `docs/` directory is already in the `files:` whitelist. New files in `docs/` and `docs/integrations/` are automatically included in the published package and rendered on hexdocs.pm. No whitelist change needed for docs files.

### Anti-Drift: How the Demo Stays Honest

The most dangerous pattern for an adoption-funnel library is a demo or getting-started guide that diverges from the real install path. Three mechanisms prevent this:

1. **Path dependency in demo:** `{:parapet, path: "../../"}` means the demo must compile against the real lib. If `mix parapet.install` changes output, the demo's committed instrumenter will fail `mix compile`, making drift visible.

2. **Getting-started guide references only public APIs:** The guide uses only the commands a real adopter runs (`mix parapet.install`, `mix parapet.doctor`, `mix parapet.gen.prometheus`). It does not reference internal modules. Public API gate (`mix verify.public_api`) catches if guide-referenced modules are removed.

3. **SLO pack config in getting-started guide matches install flag output:** The guide shows `config :parapet, providers: [Parapet.SLO.Pack.WebSaaS]`. The `--with-web-saas-pack` install flag writes exactly this line via Igniter. These are not two separate code paths — the guide documents the output that the flag produces.

---

## Component Inventory: New vs. Modified

### New Components

| Component | Type | Location | Notes |
|-----------|------|----------|-------|
| `Parapet.SLO.Pack.WebSaaS` | New module | `lib/parapet/slo/pack/web_saas.ex` | `@behaviour Parapet.SLO.Provider`; returns SliceSpecs for HTTP, login, Oban |
| `Parapet.SLO.Pack.DeliverySaaS` | New module | `lib/parapet/slo/pack/delivery_saas.ex` | `@behaviour Parapet.SLO.Provider`; extends WebSaaS with Mailglass/Chimeway; conditional on those deps |
| `retry_storm.ex.eex` | New template | `priv/templates/parapet.gen.runbooks/` | 6-step template; uses existing DSL including new `warning:` key |
| `suppression_drift.ex.eex` | New template | `priv/templates/parapet.gen.runbooks/` | 6-step template; diagnosis-heavy, mitigation bounded to soft-bounce cohort |
| `partial_backlog_drain.ex.eex` | New template | `priv/templates/parapet.gen.runbooks/` | 6-step template; bounded concurrency ceiling mitigation |
| `docs/getting-started.md` | New doc | `docs/` | Zero-to-30-minutes path; ends at "first alert rule generated" |
| `docs/troubleshooting.md` | New doc | `docs/` | FAQ seeded with 5-7 predictable questions from install path |
| `docs/slo-authoring-guide.md` | New doc | `docs/` | Good-vs-bad slicing + low-traffic guidance (denominator guard, probe fallback, extended window) |
| `docs/integrations/sigra.md` | New doc | `docs/integrations/` | Login journey SLO surface; what Parapet.attach enables |
| `docs/integrations/accrue.md` | New doc | `docs/integrations/` | Billing/checkout journey SLO surface |
| `docs/integrations/rulestead.md` | New doc | `docs/integrations/` | Flag-change correlation; what it unlocks in incident UI |
| `docs/integrations/threadline.md` | New doc | `docs/integrations/` | Audit compliance SLO surface |
| `demo/` (entire dir) | New repo artifact | `demo/` (git-only) | Docker Compose + minimal Phoenix app; NOT in files: whitelist |

### Modified Components

| Component | File | Change | Why |
|-----------|------|--------|-----|
| `Parapet.Runbook` step macro | `lib/parapet/runbook.ex` | Add `warning:` key to step accumulator and `__runbook_schema__` output | Enables warning annotations in richer templates; no existing steps break (nil is safe default) |
| `mix parapet.install` | `lib/mix/tasks/parapet.install.ex` | Add `--with-web-saas-pack` and `--with-delivery-saas-pack` flags; wire into provider config | Registration entry point for packs |
| `mix parapet.gen.runbooks` | `lib/mix/tasks/parapet.gen.runbooks.ex` | Add three `Igniter.copy_template` calls for new templates | Expose new templates to adopters |
| Existing four runbook templates | `priv/templates/parapet.gen.runbooks/*.ex.eex` | Deepen with precondition steps, warning annotations, scope checks, post-verify steps | Content only; no template generator logic changes |
| `alerts.yml.eex` | `priv/templates/parapet.gen.prometheus/alerts.yml.eex` | Add YAML comment block explaining `min_total_rate` guard and low-traffic guidance link | Content only; EEx template; no generator logic changes |
| `mix.exs` | `mix.exs` | Add `docs:` key with extras/groups; add `CHANGELOG*` to files: whitelist; populate `links:`; bump ex_doc to `~> 0.40` | Adoption funnel packaging gate |
| Operator UI detail template | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Render `step.warning` if non-nil (alert callout in UI) | Surfaces warning: key visually to operator |

### No New Components Required

| What was considered | Why not needed |
|--------------------|---------------|
| `Parapet.SLO.Catalog` GenServer | `Parapet.SLO.provider_catalog/0` is a compile-time read of Application env; a runtime catalog would be a second unsynchronized registry |
| `mix parapet.gen.slo` interactive task | Install flags already cover provider registration; no evidence of adopter need for interactive prompting |
| New Oban queue or worker | All recovery template steps route through existing `Parapet.Automation.Executor` queue |
| New Ecto schemas | No new durable state needed; runbook enrichment is template content |
| New EEx evaluation engine | `priv/templates/` already uses `EEx.eval_file` via `Igniter.copy_template`; no change |
| `Parapet.SLO.Pack` meta-behaviour | Packs are plain `Provider` behaviour implementations; a meta-behaviour adds ceremony without capability |

---

## Architectural Patterns

### Pattern 1: Provider Behaviour as the Only SLO Extension Point

**What:** All SLO definitions flow through `@behaviour Parapet.SLO.Provider` → `config :parapet, providers: [...]` → `Parapet.SLO.provider_catalog/0` → `Generator.provider_artifacts/0`. The legacy `register/1` path (Application.put_env at call time) is deprecated and must not be used for new pack modules.

**When to use:** Any time a new bundle of SLO slices needs to be shipped as a library module (built-in provider) or registered by an adopter (host provider).

**Trade-offs:** Compile-time registration means provider list is set at config load, not at runtime. This is correct for GitOps auditability. The cost is that adding a provider requires a config change + restart, not a live update — acceptable for SRE infra.

**Key invariant:** `Parapet.SLO.provider_catalog/0` must remain the single authoritative source. Any pack that writes to `Application.put_env(:parapet, :slos, ...)` instead of implementing the Provider behaviour creates a split-registry bug.

### Pattern 2: Template Content as the Recovery Depth Mechanism

**What:** Runbook template EEx files in `priv/templates/parapet.gen.runbooks/` are the correct extension point for recovery depth. The DSL is expressive enough; the templates are thin. Adding steps, warnings, and scope checks is template content work.

**When to use:** Any time a recovery scenario needs new steps, richer preconditions, or warning annotations.

**Trade-offs:** Templates use `on_exists: :skip` — once generated into the host app, they are host-owned and will not be updated by future Parapet upgrades. Adopters must re-run the generator or manually apply improvements. This is correct for the host-ownership model but means template improvements do not retroactively benefit existing adopters.

**Key invariant:** `on_exists: :skip` must never change to `:overwrite`. The host-owned scaffolding contract is what makes Parapet safe to run in production.

### Pattern 3: Docs as the Guidance Layer (Not Code)

**What:** SLO authoring guidance, low-traffic alerting patterns, good-vs-bad slicing examples, and integration setup guides all live in `docs/`. They are not executable code, not new behaviours, not generated files. They are authored Markdown rendered by ExDoc.

**When to use:** Any time the gap is "adopters don't know what to do" rather than "adopters can't do it technically."

**Trade-offs:** Docs can drift from code. Mitigation: docs reference only public-facing commands and configs, not internal module names. The `mix verify.public_api` gate catches broken module references in doc strings.

**Key invariant:** A new docs file does not require a new module, a new Mix task, or a new generator. Docs in `docs/` that are listed in `mix.exs` extras are automatically included in the published package and rendered on hexdocs.pm.

---

## Data Flow: How the Three Pillars Connect at Install Time

```
New adopter runs: mix parapet.install --with-web-saas-pack

    Igniter orchestrator
        ↓
    parapet.gen.spine (Ecto migrations, schemas)
        ↓
    write_instrumenter (host-owned module with Parapet.attach)
        ↓
    Config.configure(:parapet, [:providers], [Parapet.SLO.Pack.WebSaaS])   ← NEW
        ↓
    parapet.gen.prometheus
        → SLO.provider_catalog() reads [Parapet.SLO.Pack.WebSaaS]
        → Pack.WebSaaS.slos() returns [SliceSpec for HTTP, login, Oban]
        → Generator.provider_artifacts() emits multi-burn-rate PromQL
        → priv/parapet/prometheus/alerts.yml written with min_total_rate guard + comment
        ↓
    Operator UI branch (optional, --with-ui)
        ↓
    install_summary_notice (lists "WebSaaS SLO pack enabled")

Adopter reads docs/getting-started.md
    → points to: mix parapet.doctor (verify)
    → points to: docs/slo-authoring-guide.md (tune objectives)
    → points to: docs/integrations/sigra.md (if using Sigra for auth)

Adopter runs: mix parapet.gen.runbooks
    → generates 7 template files into lib/<app>/parapet/runbooks/
       (4 existing deepened + 3 new)
    → host owns and customizes from there
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Pack Modules Using the Legacy `register/1` Path

**What people do:** Call `Parapet.SLO.HTTP.register()` inside `Pack.WebSaaS.slos/0` or `start_link`.

**Why it's wrong:** `register/1` writes to `Application.put_env(:parapet, :slos, ...)`. The Generator reads from `provider_catalog/0` which reads `config :parapet, providers: [...]`. A pack that registers via the legacy path would not appear in `provider_catalog/0`-based generation, would only appear in `SLO.legacy()`, and would use deprecated single-burn-rate YAML generation instead of multi-burn-rate.

**Do this instead:** Implement `@behaviour Parapet.SLO.Provider` and return `[%SliceSpec{}]` structs. The Generator handles everything else.

### Anti-Pattern 2: A Parallel SLO Registry or Catalog Module

**What people do:** Create `Parapet.SLO.Catalog` as a GenServer or ETS table to hold pack definitions at runtime.

**Why it's wrong:** Creates a second authoritative source that can drift from the compile-time `providers:` config. Adds a supervised process that must start before any generator runs. Breaks the compile-time GitOps auditability of the provider behaviour.

**Do this instead:** Add pack modules to `config :parapet, providers: [...]`. The compile-time path is already correct.

### Anti-Pattern 3: `on_exists: :overwrite` on Runbook Templates

**What people do:** Change `Igniter.copy_template` to `:overwrite` so improved templates are applied to existing adopters on `mix parapet.gen.runbooks` re-runs.

**Why it's wrong:** Destroys host customizations. The entire point of host-owned scaffolding is that adopters own the generated files. Overwriting silently discards their work.

**Do this instead:** Keep `:skip`. Document template improvements in CHANGELOG.md. Adopters who want improvements apply them manually or re-generate into a new path and diff.

### Anti-Pattern 4: Adding `demo/` to the `files:` Whitelist

**What people do:** Add `demo` to `files: ~w(lib priv .formatter.exs mix.exs README* docs CHANGELOG* demo)` to "make it easy to find."

**Why it's wrong:** Publishes the demo Phoenix app — including its `mix.exs`, deps list, and config — as part of the `parapet` Hex package. This pollutes the published package with Phoenix, Ecto, Postgrex, Faker, and whatever else the demo app needs. It also increases package download size significantly.

**Do this instead:** Keep `demo/` git-only. Reference the demo from the README with a link to the GitHub repo path.

### Anti-Pattern 5: A New Mix Task for SLO Pack Registration (`mix parapet.gen.slo`)

**What people do:** Create a `mix parapet.gen.slo` interactive task with prompts ("Which app type? WebSaaS or DeliverySaaS?") that writes the provider config.

**Why it's wrong:** `mix parapet.install --with-web-saas-pack` already does this in one flag. A second task creates two code paths that must stay in sync. Neither path is better than a single flag on the existing installer. Interactive prompts are harder to test and harder to script in CI.

**Do this instead:** Add flags to `mix parapet.install`. Document the manual `config.exs` line for adopters who already installed and want to add a pack.

---

## Build Order (Dependency-Aware)

This ordering ensures each piece is usable when the next piece references it.

### Phase 1: Foundation (Unblocked)
**Deliverables:**
- `mix.exs` — add `docs:` key, `links:`, `CHANGELOG*` to whitelist, bump ex_doc
- `CHANGELOG.md` stub (Release Please will own it; stub for hexdocs rendering)
- `lib/parapet/runbook.ex` — add `warning:` key to step macro
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — render `warning:` if non-nil

**Rationale:** These have no dependencies on pillar work. The `warning:` DSL addition must land before any enriched template references it. hex.pm metadata is a credibility gate that benefits all other work.

### Phase 2: SLO Packs (Depends on: existing SLO engine — already shipped)
**Deliverables:**
- `lib/parapet/slo/pack/web_saas.ex` — `Parapet.SLO.Pack.WebSaaS` module
- `lib/parapet/slo/pack/delivery_saas.ex` — `Parapet.SLO.Pack.DeliverySaaS` module
- `lib/mix/tasks/parapet.install.ex` — add `--with-web-saas-pack` and `--with-delivery-saas-pack` flags
- `priv/templates/parapet.gen.prometheus/alerts.yml.eex` — add low-traffic comment block

**Rationale:** Pack modules must exist before docs reference them. Install flags must exist before the getting-started guide instructs adopters to use them.

### Phase 3: Runbook Templates (Depends on: Phase 1 `warning:` DSL addition)
**Deliverables:**
- Deepen existing four templates (`dead_letter`, `callback_delay`, `stalled_executor`, `provider_outage`)
- New templates: `retry_storm`, `suppression_drift`, `partial_backlog_drain`
- `lib/mix/tasks/parapet.gen.runbooks.ex` — add three new `copy_template` calls

**Rationale:** Template content must come after the DSL supports `warning:`. Template generator change must come after new template files exist.

### Phase 4: Core Docs (Depends on: Phase 2 packs + Phase 3 templates — can reference them accurately)
**Deliverables:**
- `docs/getting-started.md` — references install flags from Phase 2
- `docs/troubleshooting.md` — seeds with install-path FAQ
- `docs/slo-authoring-guide.md` — references pack modules from Phase 2 + alerts.yml comment from Phase 2

**Rationale:** The getting-started guide must accurately reflect the install flags and pack names that exist. Writing it before Phase 2 would produce a guide that references things that don't compile yet.

### Phase 5: Integration Guides (Depends on: Phase 4 getting-started guide for cross-reference)
**Deliverables:**
- `docs/integrations/sigra.md`
- `docs/integrations/accrue.md`
- `docs/integrations/rulestead.md`
- `docs/integrations/threadline.md`

**Rationale:** Integration guides can reference the getting-started guide for the base install path. Each guide stands alone but benefits from the getting-started guide existing as a canonical cross-link target.

### Phase 6: Demo (Depends on: Phase 4 docs — demo README links to getting-started)
**Deliverables:**
- `demo/` directory
- `demo/docker-compose.yml`
- `demo/app/` minimal Phoenix app
- CI check: `mix compile` + `mix parapet.doctor` inside `demo/app/`

**Rationale:** Demo is the highest-effort, highest-maintenance deliverable. It should come last so docs improvements (Phase 4-5) reduce the onboarding friction the demo is meant to solve. If doc improvements alone close the adoption gap significantly, the demo cost-benefit can be reassessed.

---

## Parallel Subsystem Temptations and How to Avoid Them

| Temptation | Why It Feels Right | Why It's a Parallel Subsystem | How to Avoid |
|------------|-------------------|-------------------------------|--------------|
| `Parapet.SLO.Catalog` GenServer | "Packs need a place to register at runtime" | Second SLO registry that drifts from `providers:` config | Use `Parapet.SLO.provider_catalog/0` — already the authoritative source |
| `mix parapet.gen.slo` | "Interactive SLO scaffolding is better DX" | Second registration entry point duplicating install flags | Add flags to existing `mix parapet.install` |
| `Parapet.SLO.Pack` meta-behaviour | "Packs are different from providers" | A third registration abstraction above Provider | Packs ARE providers; `@behaviour Parapet.SLO.Provider` is sufficient |
| Grafana provisioning in demo | "Demo should show the full loop with dashboards" | Real adopters' Grafana configs differ; provisioning becomes wrong for everyone | Link to `mix parapet.gen.grafana` instructions; don't bundle live Grafana config |
| Pack-specific alert tuning engine | "Low-traffic packs need smart threshold adjustment" | New PromQL generation layer parallel to Generator | Emit guidance comments in existing alerts.yml.eex template; let operators adjust `min_total_rate` |
| Host-side "pack registry" | "Host wants to know which packs are active" | Application env inspection duplicated into a new module | `Parapet.SLO.provider_catalog/0` already returns all registered provider slices |

---

## Sources

- `lib/parapet/slo/provider.ex` — Provider behaviour definition (HIGH confidence, read directly)
- `lib/parapet/slo/slice_spec.ex` — SliceSpec struct and validation; `min_total_rate` field confirmed (HIGH confidence, read directly)
- `lib/parapet/slo.ex` — `provider_catalog/0`, legacy/provider split, `@deprecated` on `define/2` (HIGH confidence, read directly)
- `lib/parapet/slo/generator.ex` — `provider_artifacts/0`, alert expr with `min_total_rate` guard, `@windows` (HIGH confidence, read directly)
- `lib/parapet/slo/mailglass_delivery.ex`, `chimeway_delivery.ex`, `rindle_async.ex` — canonical examples of Provider behaviour with SliceSpecs (HIGH confidence, read directly)
- `lib/parapet/runbook.ex` — full step macro, confirmed `warning:` key absent (HIGH confidence, read directly)
- `lib/parapet/automation/executor.ex`, `claim_service.ex`, `circuit_breaker.ex` — full execution chain; no changes needed for richer templates (HIGH confidence, read directly)
- `lib/mix/tasks/parapet.install.ex` — Igniter orchestrator, `maybe_configure_providers/2`, provider merge pattern (HIGH confidence, read directly)
- `lib/mix/tasks/parapet.gen.runbooks.ex` — `Igniter.copy_template` with `on_exists: :skip` confirmed (HIGH confidence, read directly)
- `priv/templates/parapet.gen.runbooks/*.ex.eex` — all four existing templates read; confirmed 1-2 steps each with no `warning:` key (HIGH confidence, read directly)
- `priv/templates/parapet.gen.prometheus/alerts.yml.eex` — EEx template structure confirmed; comment injection point identified (HIGH confidence, read directly)
- `mix.exs` — `files:` whitelist, `links: %{}`, `ex_doc` version constraint confirmed (HIGH confidence, read directly)

---

*Architecture research for: Parapet v0.10 Adopter Success — 3-pillar integration into existing Phoenix/Elixir SRE library*
*Researched: 2026-05-23*
