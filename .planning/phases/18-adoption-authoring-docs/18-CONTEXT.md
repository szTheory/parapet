# Phase 18: Adoption & Authoring Docs - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Write the adoption/authoring docs that let a stranger go from cold start to a running SLO
and a generated alert in under 30 minutes, recover from the first obstacle, and discover the
SLO slices each built-in integration unlocks — **and only docs**. This is the final phase of
v0.10 "Adopter Success" and the only deliverable is Markdown that *accurately names* the code
surfaces already built in Phases 15-17. The dominant risk is documentation drift (docs that
describe APIs/metrics/config that don't exist) and Hex package scope-leak.

**In scope (eight new files):**
- `docs/getting-started.md` — install → first running SLO → first generated alert in <30 min,
  zero raw PromQL, references the WebSaaS starter pack (ADOPT-03).
- `docs/troubleshooting.md` — 5-7 predictable Q&A: blank Prometheus target, doctor
  warn-vs-error, Oban compile-out, multi-node uniqueness, Fly.io config (ADOPT-04).
- `docs/slo-authoring-guide.md` — good-vs-bad journey-slicing, a decision tree, and a named
  "Low-Traffic and Low-Volume Services" section (denominator guard, synthetic-probe fallback,
  extended-window approach, named "lower-the-objective" anti-pattern) (SLO-03, SLO-04).
- `docs/integrations/{sigra,accrue,rulestead,threadline}.md` — one consistent per-integration
  guide each (ADOPT-05).
- `mix.exs` `extras:` registration for all eight (the only non-Markdown edit).

**Out of scope (milestone constraints):** No new runtime code, Ecto schemas, Oban queues, or
deps. No new integration guides beyond the four named (Chimeway/Mailglass/Rindle/Scoria are
already covered in `slo-reference.md`). No runnable demo app (DEMO-01, deferred to v0.10.x).
No `mix parapet.gen.slo` wizard or cross-integration bundles (deferred to v1.0+). No
auto-generated/silent SLO targets. Do not modify the code surfaces being documented — if a doc
can't be written truthfully, the correct fix is honest framing, not silent code drift (one
exception flagged below: see Open Question on the Rulestead activation API).
</domain>

<decisions>
## Implementation Decisions

### Doc Set Structure, Placement & Registration
- **D-01:** All eight new files MUST be added explicitly to the `extras:` list in `mix.exs`
  (`mix.exs:58-66`) — ExDoc does not glob, so unlisted files ship in the tarball but never
  render on hexdocs.pm. The existing `groups_for_extras: [Guides: ~r/docs\//]` (`mix.exs:69`)
  already matches `docs/integrations/*.md`, so all new files land in the "Guides" group with no
  group change. The Hex `files:` whitelist already ships the whole `docs` dir (`mix.exs:42`) —
  no `files:` change needed.
- **D-02:** New docs **cross-link to, do not replace** existing docs. `getting-started.md` is a
  tight copy-paste command sequence that links to `adopter-flows.md` (conceptual mental model)
  for depth; `slo-authoring-guide.md` teaches slicing/low-traffic authoring and links to
  `slo-reference.md` (the provider/slice catalog) rather than duplicating the slice list — so a
  slice rename only touches `slo-reference.md`.
- **D-03:** Mirror the established doc voice: prose-led "jobs-to-be-done" framing, sentence-case
  `##`/`###` headings, fenced `elixir`/`bash` code blocks, no emojis (per `adopter-flows.md` /
  `slo-reference.md`).

### Getting-Started Path Accuracy (ADOPT-03)
- **D-04:** Document the real cold-start sequence: add `:parapet` dep → `mix parapet.install`
  → `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` → `mix parapet.gen.prometheus`
  (writes `priv/parapet/prometheus/alerts.yml`) → `mix parapet.doctor`. The one-line SLO MUST use
  `config :parapet, providers: [...]`, **NOT** the legacy `:slos` env — the legacy path falls
  through to single-warning alerts and skips multi-burn-rate generation
  (`web_saas.ex:7`, `slo-reference.md:14-21`, `parapet.gen.prometheus.ex:21-33`).
- **D-05:** State explicitly that the adopter writes **zero raw PromQL** — the WebSaaS pack passes
  metric names + matchers and the Generator renders all PromQL (`web_saas.ex:67-108`,
  `generator.ex:138-159`). This is the AC-01 promise.
- **D-06:** Set the data-prerequisite expectation honestly: WebSaaS's **HTTP and Oban** slices
  work from the always-installed plug/Oban telemetry alone, but the **login-journey** slice only
  produces real data if the host emits `[:parapet, :journey, :login]` (via the Sigra integration
  or another emitter) — `web_saas.ex:85` uses `parapet_journey_login_count`, emitted only by
  `Parapet.Metrics.Sigra` (`sigra.ex:14,40-51`). The `min_total_rate` guard keeps it from
  flapping when absent, so "no data" must not be misread as "green."

### Per-Integration Guides + Activation Truth (ADOPT-05, AC-04)
- **D-07 (CORRECTNESS — overrides the requirement's wording):** `Parapet.attach(adapters: [...])`
  is real and works for **Sigra, Accrue, Threadline** (all expose `setup/0`), but is **BROKEN for
  Rulestead** — Rulestead exposes only `attach/0` (`rulestead.ex:12`), and `Parapet.attach/1`
  hard-codes `apply(module, :setup, [])` (`parapet.ex:30-34`), so `Parapet.attach(adapters:
  [:rulestead])` raises `UndefinedFunctionError`. The Rulestead guide MUST show
  `Parapet.Integrations.Rulestead.attach()` directly. Do NOT mirror the requirement's "consistent
  attach line per integration" phrasing — that phrasing is itself the drift source. (See Open
  Question: planning decides doc-only correction vs. a one-line `setup/0` delegate in
  `rulestead.ex`.)
- **D-08:** **Threadline is partially wired, not aspirational** — inbound audit ingestion
  (`[:threadline,:audit,:event]` → `Parapet.Evidence.log_tool_audit`) is fully wired
  (`threadline.ex:59-69`); outbound (`[:parapet,:audit,:created]` → `Threadline.log_audit/1`) is
  guarded by `Code.ensure_loaded?(Threadline)` and only fires if the host has the Threadline lib
  (`threadline.ex:71-79`). There is **no Threadline SLO slice or metrics module**, so the
  Threadline guide MUST NOT have an "unlocks SLO slices out of the box" section — honest framing
  is "audit evidence interoperability (inbound wired; outbound requires the Threadline lib)."
- **D-09:** **Accrue has metrics but no SLO slice module** (no `slo/accrue*.ex`, has
  `metrics/accrue.ex`) — like Threadline, the Accrue guide surfaces journey **metrics**, not
  pre-built SLO slices. Sigra and Rulestead DO emit Prometheus metrics (`metrics/sigra.ex`,
  `metrics/rulestead.ex`); Sigra additionally backs the WebSaaS login slice.
- **D-10:** Scope is exactly the four named integrations (Sigra, Accrue, Rulestead, Threadline).
  Chimeway/Mailglass/Rindle/Scoria are NOT given new guides — their SLO surfaces are already in
  `slo-reference.md:27-42`.
- **D-11:** Each integration guide follows ONE consistent structure: Prerequisites/optional-dep
  → what it unlocks (SLO slices *or* metrics, honestly per D-08/D-09) → activation line
  (uniform per D-16) → config keys → 2-3 troubleshooting answers.
- **D-16 (OQ-1 RESOLVED → option (b)+(d), 2026-05-24):** Make integration activation uniform
  and crash-proof in code so all four guides can honestly show the same
  `Parapet.attach(adapters: [...])` line — this SUPERSEDES D-07's "Rulestead guide shows
  `Parapet.Integrations.Rulestead.attach()` directly" instruction. The code carve-out
  (explicitly permitted by the phase boundary) comprises: (1) add `def setup, do: attach()` to
  `lib/parapet/integrations/rulestead.ex` (Rulestead is the SOLE outlier — research confirmed all
  7 others already expose `setup/0`); (2) introduce a `Parapet.Integration` behaviour with
  `@callback setup() :: any()` (match existing return shapes) and declare `@behaviour
  Parapet.Integration` + `@impl true` on ALL eight integration modules (Sigra, Accrue, Threadline,
  Chimeway, Mailglass, Rindle, Scoria, Rulestead) so a missing/mis-named callback is a COMPILE
  error — mirrors Parapet's own `Parapet.Notifier`/`Parapet.Probe`/`Parapet.SLO.Provider`
  behaviour idiom and the project DNA "prefer adapters and behaviors for integrations" /
  "compile-time validation where possible"; (3) fix the `Parapet.attach/1` `@doc` (it claims it
  "invokes `setup/0`" — now true everywhere); (4) tests: a behaviour-conformance test + a
  `Parapet.attach(adapters: [:rulestead])` activation test in the established
  `test/parapet/integrations/*` style; (5) CHANGELOG `### Fixed` (Rulestead activation crash) +
  `### Added` (`Parapet.Integration` behaviour). Purely additive (safe minor bump); rejected
  alternatives: doc-only (leaves a live crash in the 30-min path) and a `function_exported?/3`
  tolerant dispatcher (the "obscures runtime behavior" footgun the DNA warns against, since
  Parapet owns every integration module).

### SLO-Authoring Low-Traffic Guidance (SLO-03, SLO-04)
- **D-12:** The "Low-Traffic and Low-Volume Services" section MUST describe the EXACT engine
  output, not generic SRE folklore: the rendered guard
  `<ratio_record> > <threshold> and <total_rate_record> > <min_total_rate>`, default
  `min_total_rate: 0.01` (`slice_spec.ex:27`, overridable per-slice), and the multi-burn windows
  `["5m","30m","1h","2h","6h","3d"]` at multipliers 14.4/page, 6.0/ticket, 1.0/warning
  (`generator.ex:10,103-106,196-199`). The extended-window approach maps to the real 6h/3d
  windows the Generator already emits.
- **D-13:** Cite synthetic probes as the real fallback — `Parapet.Metrics.Probe` is implemented
  (`probe.ex:38-70`, emits `parapet.probe.run.total` / `parapet.probe.run.duration.ms`). Name the
  "lower-the-objective to silence noise" anti-pattern explicitly as the wrong alternative to the
  `min_total_rate` guard + extended windows.
- **D-14:** The journey-slicing decision tree's spine is the requirement's litmus: "does this
  failure directly prevent a user task? → journey SLO." Anchor good-vs-bad examples to the real
  WebSaaS slices (HTTP availability, login journey, Oban job-success) from `web_saas.ex`.

### Troubleshooting Seed Accuracy (ADOPT-04)
- **D-15:** All five seeds map to real surfaces with these exact behaviors:
  1. **doctor warn-vs-error** — severity `info=0/warn=1/error=2` (`doctor.ex:23`); `--threshold`
     defaults to `:error` locally but `:warn` under `--ci` (`doctor.ex:54-57`). Do NOT claim warn
     fails CI by default in the wrong direction.
  2. **Oban compile-out** — `Parapet.Metrics.Oban` is wrapped in `if Code.ensure_loaded?(Oban)`
     (`oban.ex:1`); Oban is `optional: true` (`mix.exs:84`).
  3. **multi-node uniqueness** — the `cluster_static` doctor check emits an ERROR if the
     escalation worker lacks `unique:` (`doctor.ex:305-313`).
  4. **blank Prometheus target** — maps to the `endpoint` check (Plug.Metrics presence,
     `doctor.ex:226-230`) + the `/metrics` router check (`doctor.ex:137-142`) + the
     `mix parapet.gen.prometheus` output path; NOT a generic Prometheus tip.
  5. **Fly.io config** — the generated deploy hook `rel/hooks/post_start.sh` using
     `$RELEASE_VERSION` (`install.ex:282-295`). Scope the answer to what Parapet emits; link out
     for Fly's own scrape/firewall config (the one external boundary — see Open Question).

### Claude's Discretion
- Exact prose, examples, and ordering within each doc — anchored to the existing docs' voice
  (D-03) and the real surfaces cited above.
- Whether `getting-started.md` ends with a "next steps" pointer into `adopter-flows.md` /
  `slo-authoring-guide.md` / the integration guides (recommended for funnel cohesion).
- Whether the slo-authoring decision tree renders as a Mermaid diagram or a nested bullet tree —
  follow whatever the existing docs already use (default: bullet tree, no new tooling).

### Open Questions for Planning
- **OQ-1 (Rulestead activation) — RESOLVED 2026-05-24 → option (b)+(d). See D-16.** Decision:
  fix activation in code (Rulestead `setup/0` delegate + a compile-enforced `Parapet.Integration`
  behaviour across all 8 integrations) so every guide shows the uniform
  `Parapet.attach(adapters: [...])` line. Backed by deep research (Elixir/OTel idiom = `setup/0`
  + `@behaviour`; Parapet's own behaviour pattern; "explicit over magic" DNA). No doc ships the
  crashing call; the doc-only and tolerant-dispatcher alternatives were rejected.
- **OQ-2 (Fly.io boundary, D-15.5):** The Fly.io troubleshooting answer authoritatively covers
  the Parapet side (deploy hook, `/metrics` exposure) but must link out for Fly-internal scrape
  config rather than assert platform specifics.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — ADOPT-03/04/05, SLO-03/04, and AC-01/02/04 (the exact doc
  contracts + the "no auto-generated targets" Out of Scope).
- `mix.exs` — `docs()` extras list (`:53-72`, D-01 registration target), `package()` files
  whitelist (`:40-51`), Oban `optional: true` (`:84`).
- `docs/adopter-flows.md`, `docs/slo-reference.md`, `docs/operator-ui.md`, `docs/telemetry.md`,
  `README.md` — existing docs to cross-link, mirror in voice, and NOT duplicate (D-02/D-03).
- `lib/parapet/slo/starter_pack/web_saas.ex` — WebSaaS one-line activation + the three slices +
  `parapet_journey_login_count` login dependency (D-04/D-05/D-06/D-14).
- `lib/parapet/slo/starter_pack/delivery_saas.ex` — DeliverySaaS composition (referenced for the
  getting-started "next step" and delivery integration context).
- `lib/mix/tasks/parapet.install.ex` — the real install sequence + Fly.io deploy hook
  (`:76-95`, `:121-122`, `:282-295`) (D-04/D-15.5).
- `lib/mix/tasks/parapet.gen.prometheus.ex` — generated alert/recording rule output paths
  (`:21-33`) (D-04).
- `lib/mix/tasks/parapet.doctor.ex` — severity model + thresholds + `--ci` flip + cluster/endpoint
  checks (`:23,54-57,137-142,226-230,305-313`) (D-15).
- `lib/parapet.ex` — `attach/1` hard-coded `apply(module, :setup, [])` (`:21-38`) — the root of
  the Rulestead-attach defect (D-07).
- `lib/parapet/integrations/{sigra,accrue,rulestead,threadline}.ex` — per-integration wiring
  truth: `setup/0` vs `attach/0`, optional-dep guards, what each unlocks (D-07/D-08/D-09/D-11).
- `lib/parapet/metrics/{sigra,accrue,rulestead}.ex` — which integrations emit Prometheus metrics
  (Threadline has none — D-08/D-09).
- `lib/parapet/slo/slice_spec.ex` (`:27` default `min_total_rate`), `lib/parapet/slo/generator.ex`
  (`:10` windows, `:103-106` guard expr, `:196-199` multipliers) — the EXACT low-traffic rule
  shape (D-12).
- `lib/parapet/metrics/probe.ex` — synthetic-probe feature for the low-traffic fallback (D-13).

No external specs — requirements fully captured in decisions above. (One external boundary:
Fly.io's own scrape config, OQ-2 — link out, don't assert.)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **A full docs scaffold already exists** — `docs/{adopter-flows,slo-reference,operator-ui,
  telemetry,HISTORY}.md` + `README.md` + `CHANGELOG.md`, all registered in `mix.exs` extras with
  a `Guides` group (`mix.exs:53-72`). New docs slot into the same structure with one extras edit.
- **Every code surface the docs name is already built and tested** — WebSaaS/DeliverySaaS packs
  (Phase 16), seven runbook templates (Phase 17), the install/gen/doctor tasks, and the
  multi-burn-rate Generator. The phase only describes them.
- **The Generator renders all PromQL** — adopters never hand-write queries; the docs' "zero raw
  PromQL" claim is backed by `generator.ex:138-159`.
- **Synthetic probes are a real, implemented feature** (`probe.ex`) — citable as the low-traffic
  fallback, not aspirational.

### Established Patterns
- Docs are ExDoc `extras` Markdown grouped by `~r/docs\//`; voice is prose-led second-person, no
  emojis, `elixir`/`bash` fences.
- One-line SLO activation = appending a provider module to `config :parapet, providers: [...]`
  (the blessed path; `:slos` is legacy/degraded).
- Optional integrations are detected by module presence (`Code.ensure_loaded?`), not deps —
  Mailglass/Chimeway/Threadline are host-supplied.

### Integration Points
- `mix.exs` `extras:` (`:58-66`) — the single registration edit for all eight files.
- `Parapet.attach/1` (`parapet.ex:21-38`) — the activation entry point the integration guides
  document (with the Rulestead exception, D-07).
- The generated `priv/parapet/prometheus/{alerts,recording_rules,rules}.yml` — the "first
  generated alert" getting-started milestone.

### Watch-outs
- **Rulestead-attach crash (D-07):** `Parapet.attach(adapters: [:rulestead])` raises
  `UndefinedFunctionError` — Rulestead has `attach/0`, not `setup/0`. Highest-impact drift risk.
- **Threadline/Accrue have no SLO slice modules (D-08/D-09):** documenting "unlocks SLO slices"
  for them would describe metrics that don't exist — the exact drift STATE.md flagged.
- **Legacy `:slos` env (D-04):** showing it in getting-started silently degrades the adopter to
  single-warning alerts with no multi-burn-rate generation.
- **Login slice needs Sigra (D-06):** a cold-start adopter without Sigra has a login SLO with no
  data, not a healthy one.
- **doctor `--ci` flips the threshold to `:warn` (D-15.1):** getting the exit-code model backward
  breaks adopter CI pipelines.
</code_context>

<specifics>
## Specific Ideas

- Lead every integration guide with a Prerequisites/optional-dep section, then "what it unlocks,"
  then the (corrected) activation line, then config keys, then 2-3 troubleshooting answers —
  one consistent shape across all four (D-11).
- Anchor the slo-authoring decision tree to the literal "does this failure directly prevent a
  user task? → journey SLO" litmus, with good-vs-bad examples drawn from the real WebSaaS slices.
- Express the low-traffic section against the engine's ACTUAL rendered guard and windows, not
  generic thresholds — quote the `... and <total_rate> > <min_total_rate>` shape and the
  `["5m","30m","1h","2h","6h","3d"]` window set.
- Name the "lower-the-objective to silence noise" anti-pattern explicitly as the wrong move.
</specifics>

<deferred>
## Deferred Ideas

- **Runnable demo app** (`examples/demo_app/`, DEMO-01) — deferred to v0.10.x; validate that docs
  alone reduce onboarding friction first.
- **`mix parapet.gen.slo` wizard** (SLO-W1) and **cross-integration SLO bundles** (SLO-B1) —
  deferred to v1.0+.
- **Integration guides for Chimeway/Mailglass/Rindle/Scoria** — not in this phase; already
  covered by `slo-reference.md`. Revisit if adopters ask for standalone guides.
- **A real `setup/0` delegate on Rulestead** to make the uniform attach line work everywhere —
  only if planning chooses OQ-1 option (b); otherwise the doc-only correction stands.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 18.
</deferred>
