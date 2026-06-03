# Phase 16: SLO Starter Packs & Low-Traffic Guardrails - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the **code surfaces** that let an adopter register a coherent first set of SLOs in
**one line** without hand-writing PromQL, with low-traffic safety baked in. These are the
modules that the Phase 18 docs will later name — this phase builds them, it does not document
them.

**In scope:** `Parapet.SLO.StarterPack.WebSaaS` (HTTP availability + LoginJourney + Oban
job-success) and `Parapet.SLO.StarterPack.DeliverySaaS` (extends WebSaaS, adds Mailglass +
Chimeway delivery slices), both as `@behaviour Parapet.SLO.Provider` modules built on the
existing SliceSpec → Generator engine; documented default objectives with human-terms rationale;
conditional/compile-out registration for the delivery slices; low-traffic denominator guards and
low-cardinality label compliance on every pack slice.

**Out of scope (milestone constraints):** No new runtime deps, Ecto schemas, or Oban queues.
No Generator engine changes (packs ride the existing multi-burn-rate + denominator-guard path).
No auto-generated/silent SLO targets — objectives are opinionated defaults with documented
rationale, not system-proposed guesses (REQUIREMENTS Out of Scope). No docs content (Phase 18),
no `mix parapet.gen.slo` wizard or cross-integration bundles (deferred to v1.0+).
</domain>

<decisions>
## Implementation Decisions

### Pack Structure & One-Line Registration (SLO-01)
- **D-01:** `Parapet.SLO.StarterPack.WebSaaS` is a new `@behaviour Parapet.SLO.Provider` module
  whose `slos/0` returns a list of three `SliceSpec` structs — HTTP availability, login journey,
  Oban job-success. It mirrors the shape of the existing SliceSpec providers
  (`mailglass_delivery.ex:6`, `chimeway_delivery.ex:6`, `rindle_async.ex:6`).
- **D-02:** "One line" means the adopter adds the pack module to `config :parapet, providers: [...]`.
  The engine reads providers from `Application.get_env(:parapet, :providers, [])`
  (`lib/parapet/slo.ex:71`), flat-maps `provider.slos()` (`:72`), and resolves each via
  `Resolvable.to_slo/1` (`:77`). The pack MUST write to `:providers`, NOT the legacy `:slos` env —
  the legacy path falls through to single-warning alerts and skips multi-burn-rate generation.
- **D-03:** The pack defines **fresh SliceSpecs**; it does NOT reuse the legacy
  `Parapet.SLO.HTTP/.LoginJourney/.Oban` modules. Those emit raw `%Parapet.SLO{}` structs with
  hand-written PromQL targeting metric names this codebase **does not actually emit** (no
  `parapet_journey_login_*` or `parapet_oban_job_duration_milliseconds_count` emitter exists in
  `lib/`). The legacy modules may be read for objective/wording reference only.

### HTTP Selector / SliceSpec Format — Research Flag RESOLVED
- **D-04:** **No HTTP selector helper module is needed.** `Parapet.Metrics.AsyncDelivery.selector/2`
  is metric-agnostic: given a binary metric name it renders any label matchers generically
  (`async_delivery.ex:108-130`), and both `Generator.aggregate_rate/4` (`generator.ex:156-159`)
  and `Resolvable.rate_expr/2` (`resolvable.ex:49-51`) call it with no delivery-family coupling.
  The HTTP slice passes the real HTTP metric name + matchers directly.
- **D-05:** The HTTP slice matches on the `status_class` label (values `"2xx"`/`"3xx"`), **NOT**
  `status_code`. The plug emits `status_code` as a high-cardinality *measurement* (not queryable
  as a label) and `status_class` as a tag (`plug/metrics.ex:23,28,39`; registered tags
  `[:route, :method, :status_class]` at `metrics/http.ex:31`). The legacy `slo/http.ex:25`
  `status_code=~"2..|3.."` default is wrong for this codebase — do not copy it.
- **D-06 (planning code-read):** Confirm the exact Prometheus-formatted series name for the HTTP
  duration-count metric via `lib/parapet/metrics/prometheus_formatter.ex`, and the real Oban
  job-success metric name via `lib/parapet/metrics/oban.ex`, before pinning the pack's
  `total_source_metric` / matchers. The research flag does not require a `--research-phase` run —
  this is an internal code-read.

### DeliverySaaS Conditional Registration (SLO-02)
- **D-07:** `Parapet.SLO.StarterPack.DeliverySaaS` composes the WebSaaS three slices PLUS the
  Mailglass + Chimeway delivery slices by delegating to the existing
  `MailglassDelivery.slos()` / `ChimewayDelivery.slos()` catalogs — it does NOT redefine those
  SliceSpecs inline (avoids drift from their tested names/objectives).
- **D-08:** Delivery slices are gated at **runtime inside `slos/0`** via
  `Code.ensure_loaded?(Mailglass)` / `Code.ensure_loaded?(Chimeway)` — the established
  optional-integration pattern (`integrations/threadline.ex:72`, `integrations/scoria.ex:185`,
  `parapet.ex:32`), and the explicit purpose of the `test/support/mailglass.ex` /
  `test/support/chimeway.ex` "compiler guard" stubs. Mailglass/Chimeway are host-supplied
  libraries detected by module presence — they are NOT `mix.exs` deps, so config/dep-list gating
  would never trip. (If planning finds a config-presence signal is cleaner, that is acceptable as
  long as absent libs cleanly drop the slices.)
- **D-09:** The `DeliverySaaS` module itself is **always loadable and fully documented** — the
  guard lives inside `slos/0`, never a module-level `if Code.ensure_loaded? do defmodule` wrapper.
  A vanished module would crash `provider_catalog/0` at `provider.slos()` (`slo.ex:72`) and break
  `verify.public_api` (`mix docs --warnings-as-errors`).

### Low-Traffic Guard & Low-Cardinality Compliance
- **D-10:** The low-traffic denominator guard **already exists** — every pack slice keeps a
  non-zero `SliceSpec.min_total_rate` (default `0.01`), which the Generator renders as
  `... and <total_rate_record> > <min_total_rate>` (`slice_spec.ex:27`, `generator.ex:103-107`;
  asserted at `generator_test.exs:37`). Slices expected to run at low volume may override lower
  (e.g. `0.001`, as `mailglass_delivery.ex:71` does). **Zero Generator changes** — satisfies
  criterion 4.
- **D-11:** Low-cardinality compliance is **convention-only** in the SliceSpec/selector path
  (LabelPolicy is enforced at metric-definition time via `Metrics.Validator.__after_compile__`
  and `AsyncDelivery.build_*_metric`, NOT on slice matchers). Pack slices therefore restrict HTTP
  matchers to `status_class` + `method`, omit `route` from `group_labels` (keep the default
  `group_labels: [:integration]`, `slice_spec.ex:22`), and use no `id`/`trace`/`path`/`user` keys.
  **Planning should add a small test asserting every pack slice's keys pass
  `LabelPolicy.assert_safe!`** so criterion 3 is enforced rather than convention-only.

### Default Objectives
- **D-12:** Each pack slice ships an **opinionated default objective with documented rationale**
  in human terms (e.g. "99.9% login success = ~43 min/month of user-impacting auth failures"),
  per SLO-01 and AC-02. These are explicit, inspectable defaults the adopter can override — NOT
  auto-generated/silent targets (REQUIREMENTS Out of Scope forbids system-proposed targets).
  Draw default values from the existing delivery slices' conventions and SRE norms; planning
  pins the exact numbers.

### Claude's Discretion
- Exact default objective values per slice (D-12) and the human-terms rationale wording — pin
  during planning, anchored to existing slice defaults + SRE convention.
- Whether DeliverySaaS gating uses `Code.ensure_loaded?` (preferred, per test stubs) or a
  config-presence signal (D-08) — either is acceptable if absent libs drop the slices cleanly.
- Module/file naming under `lib/parapet/slo/starter_pack/` vs flat `lib/parapet/slo/` — follow
  the existing slice layout.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/parapet/slo.ex` — the Provider registration engine (`providers` config → `provider.slos()`
  → `Resolvable.to_slo/1`); lines 71-77 define one-line activation.
- `lib/parapet/slo/provider.ex` — the `@behaviour` the packs implement.
- `lib/parapet/slo/slice_spec.ex` — SliceSpec struct, `min_total_rate` default (`:27`),
  `group_labels` default (`:22`), `new/1` validation (`:93-110`).
- `lib/parapet/slo/mailglass_delivery.ex`, `lib/parapet/slo/chimeway_delivery.ex` — existing
  SliceSpec providers to compose (DeliverySaaS) and mirror (shape, objective conventions,
  `min_total_rate` overrides).
- `lib/parapet/slo/rindle_async.ex` — third reference SliceSpec provider.
- `lib/parapet/slo/generator.ex` — multi-burn-rate + denominator-guard rendering (`:103-107`,
  `:156-159`); the engine packs ride unchanged.
- `lib/parapet/slo/resolvable.ex` — slice → selector resolution (`rate_expr/2`, `:49-51`).
- `lib/parapet/metrics/async_delivery.ex` — `selector/2`, the research-flag function
  (generic renderer, `:108-130`).
- `lib/parapet/internal/label_policy.ex` — low-cardinality policy (`assert_safe!`,
  `allowed_public_keys/1`) for the D-11 enforcement test.
- `lib/parapet/metrics/http.ex` + `lib/parapet/plug/metrics.ex` — the REAL emitted HTTP series
  and labels (`status_class` tag, `status_code` measurement); source of truth for D-05/D-06.
- `lib/parapet/metrics/oban.ex` — the REAL emitted Oban metric name for the job-success slice
  (D-06 code-read).
- `lib/parapet/metrics/prometheus_formatter.ex` — dots→underscores / `_count` series-name
  translation; pins the exact `total_source_metric` strings.
- `lib/parapet/slo/http.ex`, `login_journey.ex`, `oban.ex` — legacy modules; READ for objective
  wording only, do NOT reuse their default PromQL (wrong metric names for this codebase).
- `test/parapet/slo/mailglass_delivery_test.exs` (+ sibling slice/generator tests) — registration
  and verification conventions to follow.
- `.planning/REQUIREMENTS.md` — SLO-01/SLO-02 + Out of Scope (no auto-generated targets, no
  bundles/wizard) + AC-02 (human-terms objectives).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Provider engine is complete** — `Parapet.SLO.Provider` + `Parapet.SLO` registration flow
  (`slo.ex:71-77`) already turn a list of providers into resolved SLOs. Packs are just new
  providers; no engine work.
- **SliceSpec → multi-burn-rate Generator** already emits low-traffic-safe alerts with the
  `min_total_rate` denominator guard baked in (`generator.ex:103-107`). Criterion 4's "zero
  Generator changes" is achievable because the machinery exists.
- **`AsyncDelivery.selector/2` is a generic metric+matcher renderer** (`:108-130`) — the WebSaaS
  HTTP slice reuses it directly; no HTTP-specific selector helper required (research flag closed).
- **Existing SliceSpec providers** (`mailglass_delivery.ex`, `chimeway_delivery.ex`,
  `rindle_async.ex`) are working, tested templates for shape, objectives, and `min_total_rate`
  overrides.
- **Optional-integration compile-out pattern** (`Code.ensure_loaded?` + `apply/3`) is established
  across `integrations/threadline.ex`, `integrations/scoria.ex`, `parapet.ex`; `test/support`
  stubs exist specifically to exercise it.

### Established Patterns
- One-line activation = appending a provider module to `config :parapet, providers: [...]`
  (mirrors how the install task wires providers, `parapet.install.ex:71-74,147-164`).
- Optional deps are detected by **module presence** (`Code.ensure_loaded?`), not `mix.exs` deps —
  Mailglass/Chimeway are host-supplied and absent from `deps/0`.
- `verify.public_api` = `mix docs --warnings-as-errors` (`mix.exs:95`) — new public pack modules
  must be fully documented or CI breaks.
- LabelPolicy enforces low cardinality at **metric-definition time** only — slice matchers are
  not auto-checked, so packs enforce by discipline (+ the D-11 test).

### Integration Points
- `config :parapet, providers: [...]` — where packs activate.
- `Parapet.SLO.provider_catalog/0` / `slos/0` — runtime call site for delivery-slice gating.
- The generated Prometheus rule artifacts (`generator.ex`) — packs participate unchanged.

### Watch-outs
- **Dead-alert trap:** legacy `slo/http.ex`/`slo/oban.ex` default PromQL references series names
  (`parapet_journey_login_*`, `parapet_oban_job_duration_milliseconds_count`) that this codebase
  does NOT emit. Copying them produces rules that pass tests but never fire. Pin metric names from
  the real emitters (D-06).
- **`status_code` is not a label** — it is a measurement. Match `status_class` (D-05).
- **Module-level compile guard would break `verify.public_api`** — gate delivery slices inside
  `slos/0`, keep the module always loadable (D-09).
- **`min_total_rate: 0` would reintroduce flapping** — keep it non-zero on every pack slice (D-10).
</code_context>

<specifics>
## Specific Ideas

- Compose `DeliverySaaS` from `MailglassDelivery.slos()` / `ChimewayDelivery.slos()` rather than
  re-authoring the delivery SliceSpecs — single source of truth, no objective drift.
- Add a `LabelPolicy.assert_safe!` test over every pack slice's keys to upgrade criterion 3 from
  convention to enforced guarantee.
- Document each default objective in human terms (e.g. error-budget minutes/month), matching the
  AC-02 example phrasing.
</specifics>

<deferred>
## Deferred Ideas

- **`mix parapet.gen.slo` interactive wizard** (SLO-W1) — deferred to v1.0+.
- **Cross-integration SLO slice bundles** (SLO-B1, e.g. "e-commerce reliability suite") —
  deferred to v1.0+; per-integration docs (Phase 18) must first prove which bundles adopters want.
- **SLO authoring guide + low-traffic guidance docs** (SLO-03/SLO-04) — Phase 18; this phase
  builds the code those docs will name.
- **Auto-generated / system-proposed SLO targets** — permanently out of scope (false safety
  guarantees); packs ship explicit opinionated defaults instead.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 16.
</deferred>
