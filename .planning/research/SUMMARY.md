# Project Research Summary

**Project:** Parapet — Phoenix reliability layer (Elixir OSS library)
**Domain:** SRE substrate / opinionated telemetry + SLO library for Phoenix SaaS
**Researched:** 2026-05-09
**Confidence:** HIGH

## Executive Summary

Parapet is an opinionated SRE substrate for Phoenix SaaS teams — a library, not an application. It sits above the existing `:telemetry` ecosystem (Phoenix, Ecto, Oban all emit telemetry natively) and provides what's missing: a journey-based SLO DSL that compiles to correct Prometheus recording and alerting rules, enforced low-cardinality metric labels, generated Grafana dashboards, and a `mix parapet.doctor` CI gate that catches the footguns no one else catches. The primary differentiator over "just use PromEx" is the SLO layer — journey framing ("checkout completion SLO is burning") is actionable where raw metric rates are not, and auto-generated multi-window burn-rate PromQL removes the most error-prone toil in SRE work.

The recommended approach follows a telemetry-first, host-owned model: a generated `lib/my_app/parapet.ex` module is the single point of truth for what Parapet does in a host app; all artifacts (Grafana JSON, Prometheus rule YAML) land in `priv/parapet/` as host-owned files visible in `git status`. Optional dependencies (Oban, Sigra, OTel) compile out cleanly when absent. The PromEx adapter ships first as the default metrics reporter since it dominates the Phoenix ecosystem; the adapter seam means teams can swap to Peep or `telemetry_metrics_prometheus_core` without library changes. OTel is supported for traces only — OTel Metrics and Logs remain "Development" in the Erlang/Elixir SDK as of 2026.

The key risks are all well-understood and addressable in Phase 1: high-cardinality metric labels that explode Prometheus TSDB, telemetry handlers that block the request hot path, handlers that silently detach on crash with no observable signal, and a public `/metrics` endpoint in production. Every one of these must be solved at the foundation layer — they cannot be retrofitted without breaking the semver contract. A `mix parapet.doctor` that hard-fails (exit 2) on these violations, combined with compile-time cardinality linting, creates the paved road that differentiates Parapet from any DIY telemetry assembly.

---

## Key Findings

### Recommended Stack

Parapet's core runtime stack is stable and well-constrained: Elixir 1.16–1.18 × OTP 26–27 (matching sibling lib CI matrix), with `:telemetry`, `telemetry_metrics`, and `telemetry_poller` as the only always-required library deps. Everything else is optional. PromEx `~> 1.11` ships as the default metrics reporter adapter, with `telemetry_metrics_prometheus_core` as the minimal path and Peep `~> 5.0` documented as a high-performance swap for high-throughput apps. OpenTelemetry `~> 1.5` is supported for traces only — mark it `:temporary` in releases to prevent OTel termination cascading to the host. Grafana Alloy replaces Promtail (EOL March 2026) and Grafana Agent (EOL November 2025) as the recommended collector.

**Core technologies:**
- **Elixir 1.16–1.18 / OTP 26–27:** Hard matrix constraint from sibling libs; test against full matrix in CI
- **`:telemetry` + `telemetry_metrics` + `telemetry_poller`:** Substrate Parapet attaches to; always-required deps; Phoenix/Ecto/Oban all emit natively
- **PromEx `~> 1.11`:** Default reporter adapter; most Phoenix teams already have it; ships Grafana dashboards alongside metrics
- **`peep ~> 5.0`:** High-performance alternative reporter; document the swap path, don't block on it
- **OpenTelemetry `~> 1.5` (traces only):** Optional; OTel Metrics/Logs are "Development" status — do not build on them
- **Grafana Alloy:** Collector layer for adopters; generates templated Alloy config as a Parapet artifact
- **`promtool`:** Validate generated Prometheus rule YAML in CI — hard gate, not optional
- **`credo` + `dialyxir` + `mix format`:** Hard CI gates; inherited from sibling lib DNA

### Expected Features

Parapet's v0.1 MVP is the "trustworthy spine" — everything needed to deliver one end-to-end reliability signal with correct SLO math and no footguns.

**Must have (table stakes — teams won't adopt without these):**
- Phoenix route metrics with route-pattern labels (not raw paths) — cardinality correctness prerequisite
- Ecto DB pool metrics separating `queue_time` from `query_time` — "pool saturated" vs "DB slow" have different mitigations
- Oban job/queue health with retry-aware semantics — `:discard` not `:failure` for alerting
- Prometheus recording + alerting rule generation — teams must not hand-write multi-window burn-rate PromQL
- Grafana dashboard artifacts as JSON + provisioning YAML — operators live in Grafana
- `mix parapet.install` generator — Phoenix ecosystem convention; host-owned scaffolding
- `mix parapet.doctor` with CI exit codes — the critical safety gate no other library ships
- Documented telemetry event contract treated as public API — breaking events = breaking change
- Day-1 install guide through first alert — README that stops at `mix.exs` is unusable

**Should have (differentiators — what makes Parapet vs "just use PromEx"):**
- Journey-based SLO DSL that compiles to Prometheus recording + alert rules — core product idea
- Login journey SLO via Sigra — first business-critical SLO; validates the sibling-lib integration pattern
- Deploy/change markers correlated with SLO windows — answers "what changed?" during incidents
- Volume gates on SLOs — prevents paging on 1 error out of 2 requests on low-traffic routes
- Wide events schema separated from metric labels — teaches the correct high/low-cardinality split
- Compile-time cardinality linting — enforced, not advisory

**Defer (v0.2+):**
- DB-backed durable evidence spine — wait for telemetry contract to stabilize before committing to a schema
- Email deliverability monitoring — adds provider webhook surface before core is validated
- In-app operator UI — Grafana already serves the operator audience in v0.1
- AI evidence bundles / AGENTS.md — requires stable durable spine; design the evidence model now, ship later

### Architecture Approach

Parapet is structured as a layered library: a host-generated config module sits atop surface integrations (Phoenix, Oban, Ecto), which feed a core telemetry handler layer that enforces label policy and redaction at emission, which feeds into metric definitions consumed by a pluggable reporter adapter, with the SLO engine and dashboard generators operating on compile-time-validated SLO definitions. The `Parapet.Doctor` Mix task cuts across all layers for CI validation. The five architectural patterns that must hold throughout: (1) telemetry handlers are fast/non-blocking/non-I/O, (2) SLO definitions are validated at compile time with runtime event counting, (3) generator for scaffolding / library for runtime behavior, (4) optional dependency seams via `Code.ensure_loaded?/1`, (5) low-cardinality labels at emission with high-cardinality values in wide events only.

**Major components:**
1. `Parapet.Supervisor` — OTP supervision tree; owns telemetry handler lifecycle with re-attach on crash
2. `Parapet.Telemetry` — handler attach/detach; event normalization; label policy enforcement; redaction at emission
3. `Parapet.Surfaces.*` (Phoenix, Oban, Ecto) — surface-specific SLI calculations; each owns its event names and label contracts
4. `Parapet.SLO` — SLO struct, burn-rate math, Prometheus rule generation; pure functions validated at compile time
5. `Parapet.Dashboards` — Grafana JSON and Prometheus rule file output to `priv/parapet/`
6. `Parapet.Doctor` — Mix task for cardinality lint, security checks, config validation; CI gate with structured exit codes
7. `Parapet.Integrations.*` — optional sibling-lib integrations (Sigra first); each compiles to no-op when dep absent

### Critical Pitfalls

1. **High-cardinality metric labels** — `user_id`, `request_id`, raw `:path` in Prometheus labels causes TSDB explosion; must be a compile-time error, not a warning; enforce via label allowlist in `Parapet.Telemetry` and hard-fail in doctor
2. **Blocking inside telemetry handlers** — handlers run synchronously on the emitting process; any I/O blocks Phoenix requests; every Parapet handler must classify + normalize + enqueue, never do I/O; benchmark overhead < 1ms p99
3. **Silent handler detach on crash** — `:telemetry` drops crashing handlers silently; metrics stop flowing with no visible error; solve in supervisor design: re-attach on crash, emit `parapet_handler_attach_total` / `parapet_handler_detach_total` metrics
4. **Plug.Telemetry stop event treated as complete span** — stop event not guaranteed in all error cases; use `[:phoenix, :router_dispatch, :stop]` not Plug.Telemetry as the SLO signal source
5. **SLO math via averaging ratios** — `avg(error_rate)` is statistically wrong; always store `good_total` and `total` as separate counters; compute `sum(rate(good[w])) / sum(rate(total[w]))`; validate generated PromQL with `promtool`

---

## Implications for Roadmap

Based on the research dependency graph and pitfall-to-phase mapping, a 5-phase structure fits the project:

### Phase 1: Telemetry Foundation & Safety Rails

**Rationale:** Every other phase depends on this being correct. Cardinality decisions, handler lifecycle, label policy, and security defaults made here become the semver contract. Cannot be retrofitted. The 8 Phase-1 pitfalls (cardinality, blocking handlers, silent detach, Plug.Telemetry gap, telemetry as public API, /metrics auth, duplicate handlers, optional dep compilation) must all be solved here — they share a root cause (wrong telemetry architecture) and a shared prevention mechanism (correct supervisor design + label policy + doctor).

**Delivers:**
- `Parapet.Supervisor` with handler lifecycle and re-attach on crash
- `Parapet.Telemetry` core: attach/detach, label allowlist, redaction at emission
- `Parapet.LabelPolicy` with compile-time enforcement
- Optional dep seams (`Code.ensure_loaded?/1` pattern, CI matrix without optional deps)
- `mix parapet.install` generator producing host-owned scaffolding
- `mix parapet.doctor` with hard-fail checks (cardinality, /metrics exposure, LiveDashboard auth)
- CI pipeline: credo, dialyxir, format, warnings-as-errors, promtool, hex.audit
- Telemetry event contract documented as public API (snapshot test)
- Base package structure (`priv/parapet/` layout, `files:` whitelist)

**Addresses:** Install generator, doctor, telemetry contract, cardinality enforcement, optional dep seams
**Avoids:** All Phase-1 pitfalls; establishes the foundation every downstream phase requires

---

### Phase 2: HTTP + Ecto Instrumentation

**Rationale:** HTTP metrics are the first thing every adopter wants and the prerequisite for any HTTP-based SLO. Must be built on the Phase-1 foundation so label policy is enforced from day one. Ecto follows naturally — pool saturation is inseparable from HTTP latency analysis. Together these deliver a complete "is my Phoenix app healthy?" signal.

**Delivers:**
- `Parapet.Surfaces.Phoenix` — route classification using compiled route table; `[:phoenix, :router_dispatch, :stop]` as SLO signal source (not Plug.Telemetry)
- `Parapet.Surfaces.Ecto` — `queue_time` vs `query_time` separation; DB pool saturation SLI
- `Parapet.Metrics` — Telemetry.Metrics spec generation with enforced label contracts
- Prometheus recording rules for HTTP availability, HTTP latency (p50/p95/p99), Ecto pool saturation
- Grafana HTTP + Ecto dashboard (JSON + provisioning YAML) in `priv/parapet/`
- PromEx adapter integration; `telemetry_metrics_prometheus_core` as minimal path

**Uses:** `:telemetry_metrics`, `:telemetry_poller`, PromEx adapter from STACK.md
**Implements:** `Parapet.Surfaces.*` and `Parapet.Metrics` architecture components
**Research flag:** Skip — Phoenix and Ecto telemetry event shapes are well-documented and stable

---

### Phase 3: SLO DSL + Rule Generation

**Rationale:** The SLO DSL is the core product differentiator. It requires correct HTTP metrics (Phase 2) as its event source. SLO math correctness (ratio not average) and PromQL validation via promtool are the critical correctness requirements. This phase makes Parapet fundamentally different from "just use PromEx."

**Delivers:**
- `Parapet.SLO` — SLO struct, burn-rate math, compile-time validation
- SLO DSL (`slo :name do surface/objective/window/good_event/total_event/alert end`)
- `Parapet.SLO.RuleGenerator` — generates correct PromQL: `sum(rate(good[w])) / sum(rate(total[w]))`; multi-window burn-rate alert rules (fast burn 5m+1h, slow burn 1h+6h)
- Volume gates — SLOs self-silence below minimum traffic threshold
- `promtool check rules` validation in CI as a hard gate
- OpenSLO YAML export
- Snapshot tests for generated PromQL correctness

**Avoids:** SLO math errors (averaging ratios), promtool validation gap
**Research flag:** Needs research — Sloth and Pyrra rule formats, multi-window burn-rate PromQL patterns are nuanced; validate generated rules against known-correct examples before shipping

---

### Phase 4: Oban Slice + Sigra Login SLO + Deploy Markers

**Rationale:** Oban job health is the second v0.1 SLO slice and requires the SLO DSL (Phase 3) to be correct before retry-aware semantics can be expressed. The Sigra login SLO is the first business-critical journey and validates the sibling-lib integration pattern that all future integrations will follow — it must ship in v0.1 as the proof of concept. Deploy markers complete the "what changed?" answer and tie together the full incident investigation workflow.

**Delivers:**
- `Parapet.Surfaces.Oban` — `:discard`-based alerting (not `:failure`), queue latency SLI, retry-aware semantics
- Oban SLO definitions in the DSL; separate objectives per critical vs noncritical queue
- `Parapet.Integrations.Sigra` — attaches to Sigra telemetry events for login success/failure SLO; compiles to no-op when `:sigra` absent
- Login journey SLO: SLI → SLO → burn-rate alert → runbook annotation
- Deploy/change markers: `RELEASE_SHA` read at runtime from env, attached to wide events and SLO window annotations
- Wide events schema: structured event shape emitting high-cardinality context (user_id, request_id, trace_id) to logger, never to Prometheus labels
- Complete Grafana dashboard artifacts: Oban queues, login SLO, error budget, deploy overlays
- `mix parapet.doctor` additions: Oban integration detected but not configured warning; missing `deployment_id` warning

**Research flag:** Medium — Sigra telemetry event shapes must be confirmed stable before integration; Oban `:discard` vs `:failure` semantics are well-documented but retry-aware SLO math needs validation

---

### Phase 5: DX Polish + Launch Readiness

**Rationale:** The library is functionally complete after Phase 4 but not shippable without the adopter experience being tight. A README that stops at `mix.exs` will lose adopters before they see the first dashboard. The day-1 guide, doctor refinements, and contract documentation are what make the difference between a library people evaluate and one they trust in production.

**Delivers:**
- Day-1 install guide: install → configure → first SLO → first alert → Grafana panel (end-to-end narrative)
- Grafana Alloy templated config artifact (so adopters don't hand-author it)
- `mix parapet.doctor` final refinements: < 5 hard failures, clear distinction exit 0/1/2
- Cardinality compile-time linting as hard CI gate (not only runtime doctor check)
- Telemetry contract published to HexDocs with ExDoc; changelog section for contract changes
- CI matrix: full Elixir 1.16–1.18 × OTP 26–27; optional deps absent; promtool
- Release Please changelog automation (Conventional Commits)
- Final package: `files:` whitelist enforced, no `.planning/` or `prompts/` shipped

**Research flag:** Skip — DX patterns and HexDocs publication are standard Elixir OSS; Release Please is inherited from sibling lib DNA

---

### Phase Ordering Rationale

- **Phase 1 before everything:** The label policy, handler lifecycle, and optional dep seams are load-bearing constraints that every other component inherits. Building surfaces before the foundation would mean retrofitting cardinality enforcement into live metric names — a breaking change.
- **Phase 2 before Phase 3:** The SLO DSL consumes `good_event` and `total_event` definitions from HTTP metrics. Wrong labels in Phase 2 mean wrong SLO math in Phase 3 — correctness depends on the source being correct first.
- **Phase 3 before Phase 4:** Both Oban SLO and Sigra login SLO require the DSL to express retry-aware semantics and journey objectives. The SLO infrastructure must exist before the slices can use it.
- **Phase 4 before Phase 5:** Can't write a day-1 guide that covers the first alert until the full pipeline (HTTP + Oban + login SLO + deploy markers + alerts) is working end-to-end.
- **Durable evidence spine deferred to v0.2:** Committing to a DB schema before the Phase 1–4 telemetry contract is stable risks a breaking migration. The spine needs a stable event contract to build on.

### Research Flags

**Phases likely needing `/gsd-research-phase` during planning:**
- **Phase 3 (SLO DSL + Rule Generation):** Multi-window burn-rate PromQL is subtle; Sloth and Pyrra rule formats should be studied directly; snapshot tests need known-correct PromQL to validate against
- **Phase 4 (Sigra integration):** Sigra's telemetry event schema and key names must be confirmed current before the integration is built — the optional dep seam only works if the event names are right

**Phases with standard patterns (skip research):**
- **Phase 1 (Telemetry foundation):** Handler lifecycle, supervisor design, and optional dep patterns are all established in sibling lib DNA and Phoenix official docs — follow the documented patterns
- **Phase 2 (HTTP + Ecto):** Phoenix `[:phoenix, :router_dispatch, :stop]` and Ecto repo telemetry event shapes are authoritative and stable — no ambiguity
- **Phase 5 (DX + launch):** HexDocs, Release Please, and CI tooling are standard Elixir OSS practices; sibling libs are the reference

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Live Hex version checks; EOL dates verified (Promtail, Grafana Agent); OTel SDK status confirmed from official docs; sibling lib matrix is authoritative |
| Features | HIGH | Grounded in explicit product decisions in PROJECT.md + PARAPET-GSD-IDEA.md; competitive landscape is well-mapped; anti-features are explicitly reasoned |
| Architecture | HIGH | Drawn from Phoenix Telemetry guide, Telemetry.Metrics, Oban.Telemetry, Ecto official docs; patterns validated against sibling lib DNA; no inference-only claims |
| Pitfalls | HIGH | 10 critical pitfalls, all with documented root causes and verified prevention strategies; recovery costs are realistic; phase mapping is explicit |

**Overall confidence:** HIGH

### Gaps to Address

- **Sigra telemetry event schema:** Integration depends on Sigra's emitted event names and metadata shapes being stable. Verify against current Sigra source before Phase 4 starts. If Sigra events aren't documented as a public API, flag that as a prerequisite for the integration.
- **SLO DSL macro design:** The compile-time SLO validation approach requires careful macro design to produce readable compile errors. The `slo/do` DSL syntax needs prototyping before Phase 3 planning to confirm the approach works with the Elixir macro system and generates clean error messages.
- **PromEx adapter seam:** The adapter interface between `Parapet.Metrics` and a pluggable reporter needs to be defined before Phase 2 so it doesn't need to change shape when Peep support is added. Define the adapter protocol in Phase 1, implement PromEx adapter in Phase 2.
- **Grafana datasource parameterization:** Dashboard JSON must use Grafana template variables for datasource UID to work across installations. Verify the correct Grafana JSON format for this during Phase 2 before generating dashboards.

---

## Sources

### Primary (HIGH confidence)
- `prompts/elixir-telemetry-space-deep-research.md` — 2026 ecosystem survey; Hex version verification; PromEx plug ordering; Peep performance; Plug.Telemetry caveat
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — persona analysis; competitive landscape; SLO design; footgun catalog; module breakdown
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — authoritative constraints: optional deps, telemetry-as-API, host-owned generated code, `files:` whitelist
- `prompts/PARAPET-GSD-IDEA.md` — product thesis, non-goals, first milestone definition
- `.planning/PROJECT.md` — active requirements, out-of-scope decisions, key architectural decisions
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — production-grade telemetry/audit patterns from sibling lib
- Phoenix Telemetry guide (hexdocs.pm/phoenix/telemetry.html) — event names, supervisor pattern
- Oban.Telemetry docs (hexdocs.pm/oban/Oban.Telemetry.html) — `:exception` vs `:discard` semantics
- Ecto Repo telemetry (hexdocs.pm/ecto/Ecto.Repo.html) — `queue_time` vs `query_time` vs `decode_time`
- Google SRE Workbook (sre.google/workbook/alerting-on-slos/) — multi-window burn rate formula
- Prometheus docs (prometheus.io/docs/practices/naming/) — cardinality guidance, ratio recording rules
- Grafana Alloy docs — Promtail EOL March 2, 2026; Grafana Agent EOL November 1, 2025 (verified)
- OpenTelemetry Erlang/Elixir docs — Traces: Stable; Metrics: Development; Logs: Development (verified)
- Hex package page for `peep` — v5.0.1, April 2026 (verified current)

### Secondary (MEDIUM confidence)
- `prompts/sre-best-practices-solo-founder-deep-research.md` — SLO alerting, burn rate math, alert fatigue patterns
- `prompts/parapet-integration-opportunities.md` — integration tiering (Sigra Tier 1, others Tier 2–3)
- Sloth (sloth.dev) — SLO rule generator positioning; rule format reference
- Pyrra (github.com/pyrra-dev/pyrra) — SLO UI + rule generation pipeline pattern
- PromEx (hexdocs.pm/prom_ex/PromEx.html) — plugin architecture reference for interop model
- Honeycomb docs — high-cardinality in events vs metrics split

---
*Research completed: 2026-05-09*
*Ready for roadmap: yes*
