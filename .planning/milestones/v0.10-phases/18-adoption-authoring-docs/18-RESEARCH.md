# Phase 18: Adoption & Authoring Docs — Research

**Researched:** 2026-05-24
**Domain:** Documentation authoring (Elixir/ExDoc) with anti-drift verification pass
**Confidence:** HIGH — all claims verified against live source files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** All eight new files MUST be added explicitly to the `extras:` list in `mix.exs`. ExDoc does not glob, so unlisted files ship in the tarball but never render on hexdocs.pm. The existing `groups_for_extras: [Guides: ~r/docs\//]` already matches `docs/integrations/*.md`, so all new files land in the "Guides" group with no group change. The Hex `files:` whitelist already ships the whole `docs` dir — no `files:` change needed.
- **D-02:** New docs cross-link to, do not replace, existing docs.
- **D-03:** Mirror the established doc voice: prose-led second-person, sentence-case `##`/`###` headings, `elixir`/`bash` fenced code blocks, no emojis.
- **D-04:** Document the real cold-start sequence: add `:parapet` dep → `mix parapet.install` → `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` → `mix parapet.gen.prometheus` → `mix parapet.doctor`. Must use `config :parapet, providers: [...]`, NOT the legacy `:slos` env.
- **D-05:** State explicitly that the adopter writes zero raw PromQL.
- **D-06:** Set the login-slice data-prerequisite honestly: login-journey slice needs `parapet_journey_login_count` which Sigra emits; the `min_total_rate` guard prevents flapping but "no data" must not be read as "green."
- **D-07 (AS-FOUND, now SUPERSEDED by D-16):** `Parapet.attach(adapters: [...])` WAS broken for Rulestead — Rulestead exposes only `attach/0`, and `Parapet.attach/1` hard-codes `apply(module, :setup, [])`. **OQ-1 was resolved to option (b)+(d): plan 18-01 adds `def setup, do: attach()` to `rulestead.ex` + a `Parapet.Integration` behaviour, so the uniform `Parapet.attach(adapters: [:rulestead])` line now WORKS and ALL four guides use it. Do NOT have the Rulestead guide show `Parapet.Integrations.Rulestead.attach()`.**
- **D-08:** Threadline: inbound audit ingestion fully wired; outbound guarded by `Code.ensure_loaded?(Threadline)`. No Threadline SLO slice or metrics module.
- **D-09:** Accrue has metrics but no SLO slice module.
- **D-10:** Scope is exactly the four named integrations (Sigra, Accrue, Rulestead, Threadline).
- **D-11:** Each integration guide: Prerequisites → what it unlocks → activation line → config keys → 2-3 troubleshooting answers.
- **D-12:** Low-traffic section MUST describe the exact engine output: guard shape, `min_total_rate: 0.01` default, windows `["5m","30m","1h","2h","6h","3d"]`, multipliers 14.4/page, 6.0/ticket, 1.0/warning.
- **D-13:** Cite `Parapet.Metrics.Probe` as the real synthetic-probe fallback. Name "lower-the-objective" as the wrong anti-pattern.
- **D-14:** Journey-slicing decision tree spine: "does this failure directly prevent a user task? → journey SLO." Anchor to real WebSaaS slices.
- **D-15:** All five troubleshooting seeds map to real surfaces with documented behaviors.

### Claude's Discretion

- Exact prose, examples, and ordering within each doc.
- Whether `getting-started.md` ends with a "next steps" pointer into other docs.
- Whether the slo-authoring decision tree renders as Mermaid or nested bullet tree (default: bullet tree, no new tooling).

### Deferred Ideas (OUT OF SCOPE)

- Runnable demo app (`examples/demo_app/`, DEMO-01) — deferred to v0.10.x.
- `mix parapet.gen.slo` wizard (SLO-W1) and cross-integration SLO bundles (SLO-B1) — deferred to v1.0+.
- Integration guides for Chimeway/Mailglass/Rindle/Scoria — already in `slo-reference.md`.
- A real `setup/0` delegate on Rulestead — NO LONGER DEFERRED: OQ-1 resolved to (b)+(d), implemented in 18-01 (D-16).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-03 | New adopter follows `getting-started.md` from install → first SLO → first generated alert in under 30 min | Verified cold-start sequence: `mix parapet.install` → `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` → `mix parapet.gen.prometheus` (writes 3 files) → `mix parapet.doctor` |
| ADOPT-04 | `troubleshooting.md` seeded with 5-7 predictable Q&A | All five surfaces verified: doctor severity model, Oban compile-out guard, cluster_static uniqueness ERROR, endpoint/router checks, Fly.io deploy hook |
| ADOPT-05 | Per-integration guides under `docs/integrations/` for Sigra, Accrue, Rulestead, Threadline | Integration API verified: Sigra/Accrue/Threadline expose `setup/0`; Rulestead exposes only `attach/0`; metrics modules confirmed; SLO slice presence confirmed (Sigra: backs WebSaaS login; Accrue/Rulestead/Threadline: no SLO slice) |
| SLO-03 | `slo-authoring-guide.md` with journey-slicing examples and decision tree | Real WebSaaS slices verified as anchor examples; decision tree litmus verified |
| SLO-04 | "Low-Traffic and Low-Volume Services" section with denominator guard, synthetic-probe fallback, anti-pattern | Exact engine values verified: `min_total_rate: 0.01` (slice_spec.ex:27), windows (generator.ex:10), multipliers (generator.ex:196-199), guard expression (generator.ex:106), Probe module confirmed |
</phase_requirements>

---

## Summary

Phase 18 is a documentation-only phase delivering eight Markdown files plus one `mix.exs` edit. Every code surface the docs name was independently verified against the live source in this research pass. The findings below identify four places where CONTEXT.md citations have shifted line numbers (minor — behavior correct) and one substantial correction: CONTEXT.md's description of Threadline as having no `setup/0` is wrong — Threadline **does** expose `setup/0` (line 12), which means `Parapet.attach(adapters: [:threadline])` works correctly. This changes D-07's scope: only Rulestead is broken, not "the others work; Rulestead doesn't."

The dominant risk for the authoring team remains documentation drift: describing APIs, metrics names, config keys, or behaviors that don't match the live code. This research provides a complete ground-truth map so every claim in the eight docs can be anchored to a verified fact.

**Primary recommendation:** Write each doc section against the verified facts in this research, not against the CONTEXT.md line-number citations (many have shifted). Use the live source as the source of truth.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cold-start getting-started guide | Documentation | mix.exs (extras: registration) | Pure docs; only code touch is the extras list |
| Troubleshooting Q&A | Documentation | — | Describes existing CLI task behaviors |
| SLO-authoring decision tree | Documentation | — | Guidance; no engine code |
| Integration guides (4x) | Documentation | — | Describes existing integration wiring |
| ExDoc rendering | ExDoc (dev-only) | mix.exs extras list | ExDoc 0.40.2 requires explicit extras listing |

---

## Verification Results: CONTEXT.md Citation Audit

This is the core deliverable of this research pass. Every cited surface was opened and checked.

### V-01: mix.exs registration (D-01)

**Status: CONFIRMED with corrections**

- `extras:` list: lines **58-66** (CONTEXT.md cited 58-66 — CONFIRMED)
- `groups_for_extras: [Guides: ~r/docs\//]`: line **69** (CONFIRMED)
- `package()` `files:` whitelist: line **42** — `~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs)` — ships entire `docs` directory (CONFIRMED)
- Oban `optional: true`: line **84** (CONFIRMED)
- ExDoc version in use: **0.40.2** (resolved from mix.lock), spec `~> 0.31` in mix.exs line **88**

**What the planner must do:** Add all eight new file paths to the `extras:` list at mix.exs:58-66. The `docs/integrations/` directory does not yet exist — it must be created. The regex `~r/docs\//` will match `docs/integrations/sigra.md` etc. without any change to `groups_for_extras`.

**Current extras list (baseline):**
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "docs/HISTORY.md",
  "docs/adopter-flows.md",
  "docs/operator-ui.md",
  "docs/slo-reference.md",
  "docs/telemetry.md"
],
```

**Eight new entries to append:**
```
"docs/getting-started.md",
"docs/troubleshooting.md",
"docs/slo-authoring-guide.md",
"docs/integrations/sigra.md",
"docs/integrations/accrue.md",
"docs/integrations/rulestead.md",
"docs/integrations/threadline.md"
```

Note: That is seven new Markdown files, not eight — the CONTEXT.md scope section says "eight new files" but lists: `getting-started.md`, `troubleshooting.md`, `slo-authoring-guide.md`, and four integration guides = **7 files**. The "eight" likely counts the `mix.exs` edit itself. The planner should add all seven Markdown files to `extras:`.

---

### V-02: Getting-started cold-start sequence (D-04/D-05/D-06)

**Status: CONFIRMED with one important addition**

**`lib/parapet/slo/starter_pack/web_saas.ex`:**
- One-line activation: `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` — confirmed in module `@moduledoc` at lines 6-7 [VERIFIED]
- Three slices confirmed: `web_saas_http_availability` (line 68), `web_saas_login_journey` (line 81), `web_saas_oban_job_success` (line 95) [VERIFIED]
- Login slice uses `parapet_journey_login_count` at lines **85 and 87** (CONTEXT.md cited 85 — CONFIRMED; actual metric is `good_source_metric: "parapet_journey_login_count"` at line 85, `total_source_metric` at 87)

**`lib/parapet/metrics/sigra.ex`:**
- Counter `"parapet.journey.login.count"` at line **14** (CONTEXT.md cited 14 — CONFIRMED)
- Emits on `[:parapet, :journey, :login]` with `outcome` tag [VERIFIED]
- `Parapet.Metrics.Sigra.setup/0` exists at line 8 but just returns `:ok` — the Sigra _integration_ (not metrics module) does the telemetry attachment

**`lib/parapet/slo/generator.ex`:**
- Generator renders all PromQL via `ratio_expr/2`, `total_rate_expr/2`, `aggregate_rate/4` (lines 138-159 in CONTEXT.md, actual lines 138-159 — CONFIRMED) [VERIFIED]
- Zero raw PromQL claim is correct: adopter only specifies metric names + matchers

**`lib/mix/tasks/parapet.gen.prometheus.ex`:**
- Writes **three** output files (not one as colloquially described): [VERIFIED]
  - `priv/parapet/prometheus/recording_rules.yml`
  - `priv/parapet/prometheus/alerts.yml`
  - `priv/parapet/prometheus/rules.yml`
- CONTEXT.md (D-04) says "writes `priv/parapet/prometheus/alerts.yml`" — technically correct but incomplete. The getting-started doc should mention all three files so adopters know what was generated. The `alerts.yml` is the most actionable for a first adopter.

**`lib/parapet/slo.ex` — legacy `:slos` path:**
- `Parapet.SLO.define/2` is marked `@deprecated "Use a Parapet.SLO.Provider module instead"` (line 29) [VERIFIED]
- The legacy path stores SLOs in Application env `:slos`. The generator's `alert_group/1` for legacy `%SLO{}` structs generates a single `SLOBurnRateWarning` alert at the `6h` window only (generator.ex line 123-135), confirming D-04's "falls through to single-warning alerts and skips multi-burn-rate generation" [VERIFIED]

**Additional insight not in CONTEXT.md:** `mix parapet.install` does NOT automatically configure the WebSaaS starter pack. It writes the instrumenter module, configures `:instrumenter`, wires the endpoint plug, and generates Prometheus artifacts — but the `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` line must be added by the adopter manually (or via `--with-mailglass`/`--with-chimeway` flags for delivery providers). The getting-started doc must make this explicit.

---

### V-03: Rulestead attach defect (D-07 — CORRECTNESS)

**Status: CONFIRMED for Rulestead defect; CORRECTION for Threadline claim**

**`lib/parapet.ex`:**
- `attach/1` with adapters list calls `apply(module, :setup, [])` at line **33** (CONTEXT.md cited 30-34 — CONFIRMED; the `apply` call is at line 33) [VERIFIED]
- Logic: resolves `Parapet.Integrations.<CamelizedName>`, checks `Code.ensure_loaded?`, then calls `setup/0`

**`lib/parapet/integrations/rulestead.ex`:**
- Exposes `def attach do` at line **12** — NO `setup/0` function exists [VERIFIED]
- Therefore `Parapet.attach(adapters: [:rulestead])` calls `apply(Parapet.Integrations.Rulestead, :setup, [])` which raises `UndefinedFunctionError` [VERIFIED]
- The Rulestead integration does NOT call `Parapet.Metrics.Rulestead.setup()` — it only wires the telemetry handler via `attach/0`

**`lib/parapet/integrations/sigra.ex`:**
- Exposes `def setup do` at line **12** — `Parapet.attach(adapters: [:sigra])` works [VERIFIED]

**`lib/parapet/integrations/accrue.ex`:**
- Exposes `def setup do` at line **12** — `Parapet.attach(adapters: [:accrue])` works [VERIFIED]

**`lib/parapet/integrations/threadline.ex`:**
- Exposes `def setup do` at line **12** — `Parapet.attach(adapters: [:threadline])` WORKS [VERIFIED]
- **CORRECTION TO CONTEXT.md D-07:** The context says Threadline is one of the three that "expose `setup/0`" — this is correct. But note the CONTEXT.md code_context "watch-outs" section (which mentions only Rulestead as the crash) is consistent with this. The broader claim in D-07 ("works for Sigra, Accrue, Threadline") is CONFIRMED.

**OQ-1 option (b) assessment — one-line `setup/0` delegate:**
Adding `def setup, do: attach()` to `rulestead.ex` is surgically clean and low-risk:
- The `attach/0` function has no return value contract beyond the telemetry attach call
- Adding `setup/0` makes the API consistent with all other integration modules
- No test changes needed beyond updating the Rulestead integration test setup to call `Parapet.attach(adapters: [:rulestead])` instead of `Parapet.Integrations.Rulestead.attach()` directly
- Risk: LOW — one-line addition to a small, tested module

The planner should decide between (a) doc-only correction and (b) this one-line fix. Both are valid; (b) prevents future adopter confusion if they read other integration guides and expect uniformity.

---

### V-04: Per-integration truth (D-08/D-09/D-10/D-11)

**Status: CONFIRMED with one refinement on Rulestead metrics**

**Integration modules summary (all verified against live source):**

| Integration | `setup/0` | `attach/0` | Metrics module | SLO slice module |
|-------------|-----------|------------|----------------|-----------------|
| Sigra | ✓ line 12 | — | `metrics/sigra.ex` — `parapet.journey.login.count`, `parapet.journey.signup.count` | — (but backs `web_saas_login_journey` slice) |
| Accrue | ✓ line 12 | — | `metrics/accrue.ex` — billing checkout count, webhook duration | — |
| Rulestead | — | ✓ line 12 | `metrics/rulestead.ex` — `parapet_rulestead_flag_change_total` | — |
| Threadline | ✓ line 12 | — | — (no metrics module) | — |

**Key observations:**

1. **Sigra** (`integrations/sigra.ex`): `setup/0` wires `telemetry.attach_many` for 4 Sigra events AND calls `Parapet.Metrics.Sigra.setup()` (though that function just returns `:ok`). The real metric emission happens when Sigra fires `[:sigra, :auth, :login, :stop]` → Parapet re-emits `[:parapet, :journey, :login]` → `parapet_journey_login_count` counter. This backs the WebSaaS login slice.

2. **Accrue** (`integrations/accrue.ex`): `setup/0` wires 4 telemetry handlers AND calls `Parapet.Metrics.Accrue.setup()` (returns `:ok`). Emits `parapet.journey.billing.checkout.count` and `parapet.journey.billing.webhook.duration`. No SLO slice — the guide surfaces these metrics, not pre-built SLO slices.

3. **Rulestead** (`integrations/rulestead.ex`): Only has `attach/0`. Wires `[:rulestead, :admin, :ruleset, :published]` → re-emits `[:parapet, :rulestead, :flag_change]`. **Important refinement:** The Rulestead metrics module (`metrics/rulestead.ex`) defines `parapet_rulestead_flag_change_total` but has no `setup/0` — it is NOT called by the integration module. The metrics module is a `Telemetry.Metrics` definition, not a telemetry handler. The adopter guide should clarify what wiring is needed to report these metrics to Prometheus (requires the host's `Telemetry.Metrics` reporter to include `Parapet.Metrics.Rulestead.metrics()`).

4. **Threadline** (`integrations/threadline.ex`): `setup/0` wires two telemetry handlers:
   - Inbound: `[:threadline, :audit, :event]` → `Parapet.Evidence.log_tool_audit(attrs)` (line 59-68) — always fires [VERIFIED]
   - Outbound: `[:parapet, :audit, :created]` → `apply(Threadline, :log_audit, [mapped_attrs])` guarded by `Code.ensure_loaded?(Threadline)` (line 72-76) — only fires if host has Threadline lib [VERIFIED]
   - No metrics module, no SLO slice module [VERIFIED]

---

### V-05: Low-traffic guard shape (D-12/D-13)

**Status: CONFIRMED — all values match exactly**

**`lib/parapet/slo/slice_spec.ex`:**
- `min_total_rate: 0.01` default at lines **27** (struct default) and **43** (`Keyword.put_new`) [VERIFIED]
- CONTEXT.md cited line 27 — CONFIRMED

**`lib/parapet/slo/generator.ex`:**
- `@windows ["5m", "30m", "1h", "2h", "6h", "3d"]` at line **10** (CONTEXT.md cited line 10 — CONFIRMED) [VERIFIED]
- Alert multipliers at lines **196-199** (CONTEXT.md cited 196-199 — CONFIRMED):
  - `:page` → window `"5m"`, multiplier `14.4` [VERIFIED]
  - `:ticket` → window `"30m"`, multiplier `6.0` [VERIFIED]
  - `:warning` → window `"6h"`, multiplier `1.0` [VERIFIED]
  - `:diagnostic` → window `"30m"`, multiplier `1.0` [VERIFIED]
- Alert guard expression at line **106** (CONTEXT.md cited 103-106 — CONFIRMED):
  ```
  "#{ratio_record_name(spec.name, window)} > #{threshold} and #{total_rate_record_name(spec.name, window)} > #{spec.min_total_rate}"
  ```
  Which expands to the form: `parapet:<name>:error_ratio:<window> > <threshold> and parapet:<name>:total_rate:<window> > 0.01` [VERIFIED]

**`lib/parapet/metrics/probe.ex`:**
- Confirmed as a real, implemented feature — emits `parapet.probe.run.total` (counter) and `parapet.probe.run.duration.ms` (distribution) [VERIFIED]
- `setup/0` exists at line 13, attaches handlers for `[:parapet, :probe, :run, :stop]` and `[:parapet, :probe, :run, :exception]` [VERIFIED]
- CONTEXT.md cited `probe.ex:38-70` for the implementation — actual implementation starts earlier (setup at line 13, handle_event at line 56, telemetry.execute at line 64) but the metrics definitions and handler logic are real [VERIFIED]

---

### V-06: Troubleshooting seed accuracy (D-15)

**Status: CONFIRMED — all five seeds verified**

**Seed 1 — doctor warn-vs-error:**
- `@severity_order %{skip: 0, info: 0, warn: 1, error: 2}` at line **23** (CONTEXT.md cited line 23 — CONFIRMED) [VERIFIED]
- `parse_threshold(nil, true)` → `:warn` at line **54**; `parse_threshold(nil, false)` → `:error` at line **55** (CONTEXT.md cited 54-57 — CONFIRMED, actual is 54-57) [VERIFIED]
- Behavior: `mix parapet.doctor` alone → threshold `:error`; `mix parapet.doctor --ci` → threshold `:warn` [VERIFIED]
- Exit code 1 when any finding at or above threshold (line 414-415); exit code 0 when clean

**Seed 2 — Oban compile-out:**
- `if Code.ensure_loaded?(Oban) do` — first line of `lib/parapet/metrics/oban.ex` [VERIFIED]
- Oban `optional: true` at mix.exs line **84** [VERIFIED]
- The entire `Parapet.Metrics.Oban` module is conditionally compiled

**Seed 3 — multi-node uniqueness:**
- `check_cluster_static/0` at doctor.ex line **289** (CONTEXT.md cited 305-313 — line numbers shifted; actual `unique:` check logic starts at line **306**) [VERIFIED]
- Check: `String.contains?(worker_source, "unique:")` at line 306 — emits ERROR message "Escalation worker is missing Oban uniqueness; concurrent nodes could execute the same escalation twice." (lines 310-313) [VERIFIED]
- Status `:error` when errors list non-empty (line 345) [VERIFIED]

**Seed 4 — blank Prometheus target:**
- `check_endpoint/0` at line **218** (CONTEXT.md cited 226-230 — actual `check_endpoint` starts at 218, the Parapet.Plug.Metrics check is at lines 226-230 — CONFIRMED) [VERIFIED]
- Checks for `"Parapet.Plug.Metrics"` in endpoint file — emits `:warn` if missing (line 230) [VERIFIED]
- `check_router/0` at line **117** (CONTEXT.md cited 137-142 — the `/metrics` unsecured check is at lines 138-139) [VERIFIED]
- The three output files from `mix parapet.gen.prometheus`: `recording_rules.yml`, `alerts.yml`, `rules.yml` (all in `priv/parapet/prometheus/`) [VERIFIED]

**Seed 5 — Fly.io config:**
- `update_deploy_hook/1` in install.ex at line **276** (CONTEXT.md cited 282-295 — the actual content starts at 279, `$RELEASE_VERSION` at line 283/294) [VERIFIED]
- Writes `rel/hooks/post_start.sh` with:
  ```sh
  bin/<app_name> rpc "Parapet.Deploy.mark(version: \"$RELEASE_VERSION\")"
  ```
  [VERIFIED]
- OQ-2 boundary confirmed: the hook covers Parapet's deploy marker; Fly.io scrape config and firewall are external

---

### V-07: Existing doc voice (D-02/D-03)

**Status: CONFIRMED**

Voice patterns verified across `adopter-flows.md`, `slo-reference.md`, `operator-ui.md`, `README.md`:

- **Prose-led second-person:** "You should be able to install Parapet..." — confirmed in `adopter-flows.md`
- **Sentence-case `##`/`###` headings:** "## Phase 5 Provider Registration", "## Who This Is For" — confirmed (no title-case heading found)
- **`elixir`/`bash` fences:** confirmed throughout (```elixir, ```bash)
- **No emojis:** confirmed — none found in any existing doc
- **Jobs-to-be-done framing:** "Trigger:", "What you are trying to do:", "Parapet path:", "What 'done' looks like:" pattern in `adopter-flows.md`

**Cross-link targets available (docs to link FROM getting-started and others):**
- `adopter-flows.md` — conceptual mental model ("eight adopter jobs")
- `slo-reference.md` — provider/slice catalog, registered providers, generated artifacts
- `operator-ui.md` — UI setup, mounting, auth
- `telemetry.md` — telemetry event schema versioning

**`docs/integrations/` directory does not yet exist** — the planner must create it (along with its four Markdown files).

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExDoc | 0.40.2 (spec `~> 0.31`) | Documentation generation and hexdocs.pm rendering | Already installed; `verify.public_api` alias wraps `mix docs --warnings-as-errors` |
| Markdown (CommonMark) | — | All eight new files | ExDoc renders Markdown `extras` natively |

### No new dependencies

This phase installs zero new packages. All tooling is already present.

---

## Package Legitimacy Audit

No packages are installed in this phase. Section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Adopter reads docs/getting-started.md
        │
        ▼
mix parapet.install ──────────────────────────► rel/hooks/post_start.sh
        │                                        (deploy marker)
        ▼
config :parapet, providers: [WebSaaS]  ◄─── docs/integrations/sigra.md (if adding Sigra)
        │
        ▼
mix parapet.gen.prometheus
        │
        ├──► priv/parapet/prometheus/recording_rules.yml
        ├──► priv/parapet/prometheus/alerts.yml
        └──► priv/parapet/prometheus/rules.yml
        │
        ▼
mix parapet.doctor ──────► exit 0 (clean) or exit 1 (findings at/above threshold)
        │
        ▼
Adopter reads docs/troubleshooting.md (if blocked)
Adopter reads docs/slo-authoring-guide.md (to customize SLOs)
```

### Recommended project structure (new files only)

```
mix.exs                              # EDIT: add 7 new extras entries
docs/
├── getting-started.md               # NEW (ADOPT-03)
├── troubleshooting.md               # NEW (ADOPT-04)
├── slo-authoring-guide.md           # NEW (SLO-03, SLO-04)
└── integrations/                    # NEW directory
    ├── sigra.md                     # NEW (ADOPT-05)
    ├── accrue.md                    # NEW (ADOPT-05)
    ├── rulestead.md                 # NEW (ADOPT-05)
    └── threadline.md                # NEW (ADOPT-05)
```

### Pattern 1: Integration guide consistent structure (D-11)

Every integration guide follows this exact shape:

```markdown
# <Integration name>

<One-sentence description of what it is and what Parapet unlocks with it.>

## Prerequisites

- `<integration lib>` installed in your host app (optional dep — Parapet detects via `Code.ensure_loaded?`)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

<For Sigra: "Sigra login and signup events become Parapet journey metrics (parapet_journey_login_count, parapet_journey_signup_count) and the WebSaaS login slice becomes meaningful.">
<For Accrue: billing journey metrics — NOT SLO slices>
<For Rulestead: flag-change evidence (rulestead_flag_change_total counter) — NOT SLO slices>
<For Threadline: audit evidence interoperability — NOT SLO slices>

## Activation

```elixir
# All four — uniform Parapet.attach works (Rulestead included, after 18-01's setup/0 delegate, D-16):
Parapet.attach(adapters: [:sigra])
Parapet.attach(adapters: [:accrue])
Parapet.attach(adapters: [:rulestead])
Parapet.attach(adapters: [:threadline])
```

## Config keys

...

## Troubleshooting

...
```

### Pattern 2: Low-traffic guard description (D-12)

The exact engine output for an alert expression:

```
parapet:<slice_name>:error_ratio:<window> > <threshold> and parapet:<slice_name>:total_rate:<window> > 0.01
```

Example for `web_saas_login_journey` at `:page` class (14.4x multiplier, 5m window, 99.9% objective → threshold = 0.001 × 14.4 = 0.0144):

```
parapet:web_saas_login_journey:error_ratio:5m > 0.0144 and parapet:web_saas_login_journey:total_rate:5m > 0.01
```

### Anti-Patterns to Avoid

- **Showing `Parapet.Integrations.Rulestead.attach()` or framing the uniform line as a crash (D-16):** After 18-01 the uniform `Parapet.attach(adapters: [:rulestead])` is the CORRECT line for all four guides. Do NOT special-case Rulestead's activation or document it as crashing.
- **Claiming Accrue or Rulestead "unlock SLO slices":** Neither has an SLO slice module. They emit metrics; adopters build their own slices from those metrics if desired.
- **Showing `config :parapet, :slos, [...]` (legacy path):** This results in single-warning-only alerts, not multi-burn-rate. The getting-started doc must use `config :parapet, providers: [...]`.
- **Claiming `mix parapet.install` automatically adds the WebSaaS provider:** It does not. The adopter adds `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` manually after install.
- **Claiming `mix parapet.gen.prometheus` writes only `alerts.yml`:** It writes three files. All three should be mentioned.
- **Stating doctor `--ci` makes CI stricter:** It makes CI more permissive (threshold drops from `:error` to `:warn`). The troubleshooting doc must get this direction right.
- **Documenting Threadline as having no `setup/0`:** Threadline does expose `setup/0`. The integration is partially wired (no SLO slices or metrics module), but the activation API is uniform with Sigra/Accrue.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PromQL guard expressions | Custom Prometheus YAML | `mix parapet.gen.prometheus` + `SliceSpec.min_total_rate` | Generator renders all PromQL; manual YAML drifts from the engine |
| Docs build validation | Custom CI script | `mix docs --warnings-as-errors` (already aliased as `mix verify.public_api`) | ExDoc surfaces broken cross-references and undefined module links |
| Decision tree diagram tooling | Mermaid (new dep) | Nested bullet tree | Existing docs use bullets; no new tooling needed |

**Key insight:** For a docs phase, the "don't hand-roll" principle applies to validation: don't write a custom cross-reference checker when `mix docs --warnings-as-errors` already catches broken module/function links.

---

## Runtime State Inventory

Not applicable — this is a greenfield docs phase with no rename/refactor/migration scope.

---

## Common Pitfalls

### Pitfall 1: Rulestead activation crash — RESOLVED by D-16 (kept for history)

> **SUPERSEDED:** OQ-1 was resolved to option (b)+(d). Plan 18-01 fixes the code FIRST (Rulestead `setup/0` delegate + `Parapet.Integration` behaviour), so the pitfall below no longer applies — the uniform line is now the CORRECT activation line for Rulestead. Do NOT treat `Parapet.attach(adapters: [:rulestead])` in the Rulestead guide as drift; it is the intended uniform line. The remaining drift risk inverts: showing `Parapet.Integrations.Rulestead.attach()` or framing the uniform line as a crash IS the drift.

**What WAS wrong (pre-fix):** `Parapet.attach(adapters: [:rulestead])` raised `UndefinedFunctionError: Parapet.Integrations.Rulestead.setup/0 is undefined` because Rulestead exposed `attach/0`, not `setup/0`, and `Parapet.attach/1` hard-codes `apply(module, :setup, [])`.

**The fix (18-01):** `def setup, do: attach()` on Rulestead + a compile-enforced `Parapet.Integration` behaviour. After 18-01, the uniform API works for all eight integrations.

---

### Pitfall 2: Accrue/Rulestead/Threadline "unlocks SLO slices"

**What goes wrong:** Author claims these integrations produce ready-to-use SLO slices, analogous to how Sigra backs the WebSaaS login slice.

**Why it happens:** The mental model from Sigra bleeds over. The docs try to be symmetric.

**How to avoid:** Only Sigra backs a pre-built SLO slice (the WebSaaS login journey). Accrue and Rulestead emit Prometheus metrics (journey metrics and flag-change counter respectively). Threadline provides audit evidence interoperability. No SLO slice modules exist for any of them. The guides must describe what actually exists.

---

### Pitfall 3: Legacy `:slos` path in getting-started

**What goes wrong:** Author uses the `Parapet.SLO.define(:name, ...)` / `config :parapet, :slos, [...]` path in the getting-started example (because the README's "### 1. Define your SLOs" section shows this pattern).

**Why it happens:** The README's "Operator Loop" section shows the legacy path (which still compiles and runs). The cold-start adopter copies it.

**How to avoid:** `getting-started.md` must use `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]`. The `slo-reference.md` doc already notes the legacy path is a compatibility surface. Getting-started should not mention it at all — just link to `slo-reference.md` for the full provider/legacy explanation.

---

### Pitfall 4: `mix parapet.doctor --ci` direction

**What goes wrong:** Doc says "`mix parapet.doctor --ci` fails on warnings" — which is backwards. `--ci` drops the threshold to `:warn`, which means it catches more things than the default `:error` threshold... but the _default_ `:error` threshold already means `warn`-level findings don't fail CI without `--ci`.

**Why it happens:** The threshold/exit-code model is slightly counterintuitive: `:warn` threshold is _more_ sensitive (fails on warn+), `:error` threshold is less sensitive (fails only on error).

**How to avoid:** State it precisely: "By default, `mix parapet.doctor` exits 1 only when a finding is `:error`. With `--ci`, it exits 1 for any `:warn` or `:error` finding — a stricter gate suitable for CI pipelines." The `--ci` flag actually makes the check _stricter_ (catches more), not looser.

**Correction to initial reading:** `--ci` sets threshold to `:warn`, meaning _more_ findings fail. This is the correct understanding. CONTEXT.md's D-15.1 says "threshold defaults to `:error` locally flipping to `:warn` under `--ci`" — that is correct, and `:warn` is the stricter threshold.

---

### Pitfall 5: Claiming `mix parapet.install` adds the WebSaaS provider

**What goes wrong:** Getting-started doc implies that after `mix parapet.install` the WebSaaS SLO pack is active.

**Why it happens:** The install task is presented as "one step" and the adopter expects it to wire everything.

**How to avoid:** Install scaffolds the instrumenter, endpoint plug, and deploy hook. The `providers` config is separate and must be added by the adopter. The cold-start sequence in `getting-started.md` must show step 2 explicitly: "After install, add the WebSaaS starter pack to your config..."

---

### Pitfall 6: ExDoc unlisted extras

**What goes wrong:** A new doc file is committed but not added to `mix.exs` extras list, so it ships in the package tarball but never renders on hexdocs.pm.

**Why it happens:** Authors expect ExDoc to glob the `docs/` directory.

**How to avoid:** ExDoc 0.40.2 requires explicit listing. Every new file must be added to `extras:`. The `mix verify.public_api` alias runs `mix docs --warnings-as-errors` — however, an unlisted file does not cause a docs build warning; it simply does not appear. The validation step (see below) must explicitly check that all eight new files are listed.

---

## Code Examples

Verified patterns from live source:

### WebSaaS one-line activation
```elixir
# Source: lib/parapet/slo/starter_pack/web_saas.ex, @moduledoc lines 5-7
config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]
```

### Actual alert expression shape (from generator.ex:106)
```
# Pattern: parapet:<name>:error_ratio:<window> > <threshold> and parapet:<name>:total_rate:<window> > <min_total_rate>
# Example for web_saas_login_journey (page class, 5m window):
parapet:web_saas_login_journey:error_ratio:5m > 0.0144 and parapet:web_saas_login_journey:total_rate:5m > 0.01
```

### Rulestead activation (uniform form, after 18-01's setup/0 delegate — D-16)
```elixir
# Source: lib/parapet/integrations/rulestead.ex (def setup, do: attach() added by 18-01)
Parapet.attach(adapters: [:rulestead])
```

### Sigra/Accrue/Threadline activation (uniform form works)
```elixir
# Source: lib/parapet.ex:21-37
# Works because Sigra/Accrue/Threadline all expose setup/0
Parapet.attach(adapters: [:sigra])
Parapet.attach(adapters: [:accrue])
Parapet.attach(adapters: [:threadline])
```

### Doctor exit-code model
```bash
# Source: lib/mix/tasks/parapet.doctor.ex:23, 54-57
# Default: exits 1 only on :error findings
mix parapet.doctor

# CI mode: exits 1 on :warn OR :error findings (stricter)
mix parapet.doctor --ci

# Explicit threshold override
mix parapet.doctor --threshold warn
```

### Fly.io deploy hook (from install.ex)
```sh
# Source: lib/mix/tasks/parapet.install.ex, update_deploy_hook/1
# Written to rel/hooks/post_start.sh
bin/<app_name> rpc "Parapet.Deploy.mark(version: \"$RELEASE_VERSION\")"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Parapet.SLO.define/2` with raw PromQL | `config :parapet, providers: [ProviderModule]` with SliceSpec | Phase 16 (v0.10) | Adopters get zero-PromQL multi-burn-rate alerts; legacy still works but generates single-warning only |
| Manual YAML alert files | `mix parapet.gen.prometheus` generates 3 files | Phase 16 | Recording rules, alerts, and combined rules all generated from Elixir definitions |
| Custom SLO definitions | `Parapet.SLO.StarterPack.WebSaaS` one-line pack | Phase 16 | Cold start possible in one config line |

**Deprecated/outdated:**
- `Parapet.SLO.define/2`: tagged `@deprecated` in `lib/parapet/slo.ex:29`. Works but generates single-warning alerts only. Do not show in getting-started.
- `config :parapet, :slos, [...]`: the runtime Application env path. Functional but compatibility-only; generates degraded alert set.

---

## Open Questions (RESOLVED)

1. **OQ-1: Rulestead one-line delegate (D-07)**
   - What we know: `Parapet.attach(adapters: [:rulestead])` crashes. The fix is `def setup, do: attach()` in `rulestead.ex` — one line, low risk.
   - What's unclear: Planning's preference between (a) doc-only inconsistency and (b) surgical code fix.
   - Recommendation: Choose (b). The one-line fix is lower risk than documenting a broken API and hoping future adopters notice the footnote. The planner should add a code task for rulestead.ex before the doc tasks.

2. **OQ-2: Fly.io boundary (D-15.5)**
   - What we know: The troubleshooting answer covers `rel/hooks/post_start.sh` and the `/metrics` exposure. Fly.io scrape config and firewall rules are external.
   - What's unclear: Whether to link to a specific Fly.io docs page.
   - Recommendation: Link to `https://fly.io/docs/` generally (or the metrics/Prometheus section if available) rather than asserting Fly-specific steps. The OQ-2 boundary is correct.

3. **OQ-3: Rulestead metrics wiring gap (not in CONTEXT.md)**
   - What we know: `Parapet.Metrics.Rulestead` defines `parapet_rulestead_flag_change_total` but has no `setup/0` and is not called by the integration module.
   - What's unclear: Does the adopter need to include `Parapet.Metrics.Rulestead.metrics()` in their `Telemetry.Metrics` reporter config? If so, the Rulestead guide must document this.
   - Recommendation: The Rulestead guide should include a note explaining that the metrics definition module exists but the host must wire it into their Telemetry.Metrics reporter. This is a real gap that will block adopters trying to get `parapet_rulestead_flag_change_total` into Prometheus.

---

## Environment Availability

This phase has no external tool dependencies beyond the existing Elixir/Mix toolchain. The `docs/integrations/` directory does not exist and must be created — this is a filesystem operation, not a missing dependency.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All tasks | ✓ | 1.19+ | — |
| ExDoc | `mix docs` validation | ✓ | 0.40.2 | — |
| `mix verify.public_api` | Doc build validation | ✓ | alias exists in mix.exs | — |

---

## Validation Architecture

> `nyquist_validation` not set in `.planning/config.json` — treated as enabled.

Since this phase produces no runtime code, unit tests do not apply. The validation strategy uses three complementary mechanisms:

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (for scripted checks) + Mix tasks |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix docs --warnings-as-errors` |
| Full suite command | `mix test && mix verify.public_api && mix docs --warnings-as-errors` |

### Phase Requirements → Validation Map

| Req ID | Behavior | Validation Type | Automated Command | Mechanism |
|--------|----------|----------------|-------------------|-----------|
| ADOPT-03 | `getting-started.md` renders on hexdocs, cross-links resolve | docs build | `mix docs --warnings-as-errors` | ExDoc catches broken `[text](path)` links to other extras |
| ADOPT-04 | `troubleshooting.md` renders, Q&A sections present | docs build + grep | `mix docs --warnings-as-errors` | Structure check: grep for each of 5 seed headings |
| ADOPT-05 | All 4 integration guides render under Guides group | docs build | `mix docs --warnings-as-errors` | ExDoc renders all extras in the correct group |
| SLO-03 | `slo-authoring-guide.md` decision tree present | docs build + grep | `mix docs --warnings-as-errors` | Headings check |
| SLO-04 | Low-traffic section names `min_total_rate`, correct windows | grep | `grep -r "min_total_rate" docs/slo-authoring-guide.md` | Anti-drift grep checks |

### Anti-Drift Verification Checks

The dominant risk for this phase is documentation drift. The following checks should run as a post-authoring verification gate (can be scripted in a Wave 0 test file or run manually):

```bash
# 1. All 7 new docs are listed in mix.exs extras:
grep -c "docs/getting-started\|docs/troubleshooting\|docs/slo-authoring-guide\|docs/integrations" mix.exs
# Expected: 7

# 2. Rulestead activation is the uniform line, never framed as a crash (D-16 supersedes D-07):
grep -q "Parapet.attach(adapters: \[:rulestead\])" docs/integrations/rulestead.md  # present (valid uniform line, works after 18-01)
grep -r "Parapet.Integrations.Rulestead.attach()" docs/  # Expected: 0 (no special-case form)

# 3. Getting-started uses providers: not :slos
grep -r "config :parapet, :slos" docs/getting-started.md
# Expected: 0 results

# 4. Low-traffic guide names the actual min_total_rate default
grep "min_total_rate" docs/slo-authoring-guide.md
# Expected: at least 1 match with "0.01"

# 5. Low-traffic guide names the actual windows
grep -E '"5m".*"30m".*"1h".*"6h".*"3d"' docs/slo-authoring-guide.md
# Expected: 1 match

# 6. Accrue/Rulestead/Threadline guides do NOT claim "SLO slices"
# (checking for the dangerous false claim)
for f in docs/integrations/accrue.md docs/integrations/rulestead.md docs/integrations/threadline.md; do
  grep -l "SLO slice" "$f" && echo "DRIFT RISK in $f"
done
# Expected: 0 matches

# 7. mix docs builds without warnings
mix docs --warnings-as-errors
# Expected: exit 0

# 8. Docs build actually renders all 7 new files
ls doc/
# Expected: getting-started.html, troubleshooting.html, slo-authoring-guide.html,
#           integrations/sigra.html, integrations/accrue.html,
#           integrations/rulestead.html, integrations/threadline.html
```

### Sampling Rate

- **Per doc committed:** Run `mix docs --warnings-as-errors` to catch broken cross-links immediately
- **Per wave merge:** Run full anti-drift grep suite (8 checks above)
- **Phase gate:** `mix test && mix verify.public_api && mix docs --warnings-as-errors` green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `docs/integrations/` directory — must be created (no content yet)
- [ ] Anti-drift grep script — can be a shell script or documented in VALIDATION.md for manual execution
- [ ] No new test files needed — existing test suite covers code surfaces; docs are validated via `mix docs`

---

## Security Domain

This phase touches only Markdown documentation and `mix.exs` `extras:` list. No authentication, session management, input validation, cryptography, or access control surfaces are introduced or modified. Security domain section is not applicable for a documentation-only phase.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExDoc 0.40.2 requires explicit `extras:` listing (no glob) | V-01 | If ExDoc gains glob support in a future version, unlisted files might render unexpectedly — but for authoring, explicit listing is safer regardless | 
| A2 | The `docs/integrations/` directory can be created as part of the same plan wave as the integration guides | V-01 | If the OS/git requires the directory to exist before files are created, it must be created first — but standard filesystem operations handle this |

**All code-surface claims in this research were directly verified against the live source. No code behavior is assumed.**

---

## Sources

### Primary (HIGH confidence — verified against live source)

- `mix.exs` — extras list (lines 58-66), groups_for_extras (line 69), package files (line 42), Oban optional (line 84), ExDoc spec (line 88)
- `lib/parapet.ex` — attach/1 adapter dispatch, apply(module, :setup, []) at line 33
- `lib/parapet/slo/starter_pack/web_saas.ex` — three slices, one-line activation, login metric name
- `lib/parapet/integrations/{sigra,accrue,rulestead,threadline}.ex` — setup/0 vs attach/0 per integration, wiring logic
- `lib/parapet/metrics/{sigra,accrue,rulestead,probe}.ex` — metric definitions, metric names, tags
- `lib/parapet/slo/slice_spec.ex` — min_total_rate default (line 27, 43)
- `lib/parapet/slo/generator.ex` — @windows (line 10), alert expression shape (line 106), multipliers (lines 196-199)
- `lib/mix/tasks/parapet.doctor.ex` — @severity_order (line 23), parse_threshold (lines 54-57), check_cluster_static (line 289, unique: check line 306), check_endpoint (line 218-230), check_router (line 117, /metrics line 138)
- `lib/mix/tasks/parapet.install.ex` — deploy hook (update_deploy_hook/1, lines 276-305), cold-start sequence
- `lib/mix/tasks/parapet.gen.prometheus.ex` — three output paths (lines 21-31)
- `lib/parapet/slo.ex` — legacy @deprecated path (line 29), provider_catalog (line 70-72)
- `lib/parapet/metrics/oban.ex` — compile-out guard (line 1: `if Code.ensure_loaded?(Oban) do`)
- `docs/{adopter-flows,slo-reference,operator-ui,telemetry}.md` — voice, headings, cross-link targets
- `mix.lock` — ExDoc resolved version 0.40.2

### Secondary (MEDIUM confidence)

- ExDoc extras behavior (explicit listing required) — inferred from existing `extras:` list pattern in mix.exs and confirmed by verifying no glob-based extras exist

---

## Metadata

**Confidence breakdown:**
- Code surface verification: HIGH — every cited file opened and confirmed
- ExDoc behavior: HIGH — existing mix.exs pattern plus resolved version confirm behavior
- Voice/style: HIGH — directly read from four existing docs
- OQ-1 risk assessment (one-line delegate): HIGH — simple function addition with clear contract

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 (stable — docs-only phase, no external APIs involved)
