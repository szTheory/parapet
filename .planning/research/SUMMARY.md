# Project Research Summary

**Project:** Parapet — v0.10 Adopter Success
**Domain:** Phoenix/Elixir OSS SRE library — adopter onboarding, SLO authoring guidance, recovery depth (subsequent milestone on a feature-complete v0.9 system)
**Researched:** 2026-05-23
**Confidence:** HIGH

## Executive Summary

Parapet is a feature-complete Phoenix/Elixir SRE library. v0.9 shipped the full stack: a provider-first SLO engine with multi-burn-rate PromQL generation, an incident/timeline/action spine, preview-first runbook recovery, and a one-command `mix parapet.install` path. v0.10 is **not feature expansion — it is a credibility-gate release**. The job is to move Parapet from "feature-complete but unadoptable by a stranger" to "a stranger can evaluate, install, and succeed at 11 PM." All four research files converge unambiguously on this framing, and they are mutually consistent: the work is almost entirely docs, opinionated defaults wrapping existing capability, and template content — not new subsystems.

The recommended approach is disciplined restraint. Three pillars, each touching exactly one part of the existing architecture: (A) an **adoption funnel** — populated hex.pm metadata, a Release-Please-owned CHANGELOG, a one-page getting-started guide, troubleshooting/FAQ, per-integration guides for the four built-but-invisible adapters (Sigra, Accrue, Rulestead, Threadline), and a git-only Docker Compose demo; (B) **recovery depth** — deepen the four thin runbook templates and add three new ones (retry storm, suppression drift, partial backlog drain), gated by a single surgical DSL addition of a `warning:` step key; (C) **SLO authoring guidance** — two opinionated starter packs (`Parapet.SLO.Pack.WebSaaS`, `Parapet.SLO.Pack.DeliverySaaS`) built as plain `Parapet.SLO.Provider` implementations, plus an authoring guide covering good-vs-bad journey slicing and low-traffic-safe alerting. The ExDoc constraint surface is tiny: bump `ex_doc` to `~> 0.40`, add a `docs:` key, populate `links:`, and add `CHANGELOG*` to the `files:` whitelist. No new runtime deps, no new Ecto schemas, no new Oban queues.

The dominant risk is **drift and scope-leak, not technical difficulty**. The research is emphatic on three things: (1) demo deps and the `demo/` directory must never leak into the published Hex package — the demo is git-only and must pin `{:parapet, path: "../../"}` with a CI compile-and-doctor check that ships in the same PR; (2) docs must not claim DSL behavior that does not exist — the `warning:` key must land in `Parapet.Runbook.step/2` *before* any template uses it, the single most important sequencing constraint in the milestone; (3) starter packs must respect low-cardinality (no per-request labels) and low-traffic safety (non-zero `min_total_rate` per slice) or they will destroy adopter trust the first time they page on noise. Every one of these is preventable with a small CI gate or a sequencing rule, all of which the research specifies concretely.

## Key Findings

### Recommended Stack

The stack delta for v0.10 is minimal and fully verified against official sources and live repo state. There are **no new runtime dependencies**. The only `mix.exs` changes are: bump `{:ex_doc, "~> 0.40"}` (currently `~> 0.31`, locked at 0.40.2), add a `docs:` key to `project/0` with `extras`/`groups_for_extras`/`groups_for_modules`, populate the empty `links: %{}` with canonical `"GitHub"` and `"Changelog"` keys, and add `CHANGELOG*` to the `files:` whitelist. The demo harness is Docker Compose (Prometheus + Grafana + a minimal Phoenix app) living in a top-level `demo/` directory that is automatically excluded from the package because it is not `lib`/`priv`/`docs`. SLO packs and recovery depth require zero new tooling — they reuse the existing Provider behaviour, SliceSpec struct, and Igniter template generators.

**Core technologies:**
- ex_doc `~> 0.40`: hexdocs HTML + sidebar grouping — bump from `~> 0.31` to pick up extras grouping and `.livemd` support; no breaking changes in range.
- Docker Compose v2 (Prometheus `v3.x` + Grafana `11.x`, pinned): single-command full-loop demo — the de facto Elixir observability demo idiom (mirrors prom_ex); requires no Erlang distribution knowledge.
- Release Please (`release-type: elixir`, already configured): owns CHANGELOG.md generation from Conventional Commits — humans must NOT hand-edit the changelog body.
- Phoenix `~> 1.7` (demo app only): exercises the real install surface via `{:parapet, path: "../../"}`; never enters the published package.

### Expected Features

This is a "credibility gate" feature set, not a greenfield MVP. The bar is set by peers: AppSignal (best onboarding DX), ErrorTracker (clean single-command install but weakest demo), PromEx (strong example apps), Oban Web (the direct peer for recovery UI — but theirs is direct bulk action with no preview, which is exactly Parapet's differentiator). The competitive insight: Parapet already surpasses Sloth/Pyrra and PromEx on capability; the entire gap is the guidance and onboarding layer.

**Must have (table stakes):**
- Populated hex.pm metadata (`links:`, description, source_url) — empty `links: %{}` signals an abandoned library; 30-minute fix that gates everything.
- `CHANGELOG.md` — adopters check it before adding a dep; absence reads as "doesn't track what it ships."
- One-page end-to-end getting-started guide — the single doc that converts interest to installation; ends when the adopter sees something work.
- Troubleshooting / FAQ — reduces abandonment at the first obstacle; seeded with predictable install-path questions.
- Per-integration setup guides (Sigra, Accrue, Rulestead, Threadline) — unlocks discovery of built-but-invisible adapters.

**Should have (competitive differentiators):**
- Opinionated SLO starter packs by app type (`Pack.WebSaaS`, `Pack.DeliverySaaS`) — the "what SLO do I add first?" answer that no peer provides.
- SLO authoring guide with good-vs-bad journey slicing + low-traffic-safe alerting guidance — closes the explicit JTBD gap #3.
- Richer preview-first, bounded runbook templates (deepen 4, add 3) — closes JTBD gap #1; Parapet's preview-before-execute is a genuine edge over Oban Web's direct bulk actions.

**Defer (v0.10.x / v1.0+):**
- Runnable demo app + its CI check — high value but highest maintenance cost; validate that doc improvements close the gap first (P2). Note: research treats the demo as deferrable, but if built it must ship its CI check in the same PR.
- `mix parapet.gen.slo` interactive wizard — install flags already cover registration; no evidence of need (P3).
- Cross-integration SLO bundles (e-commerce suite wiring Sigra + Accrue + Chimeway) — defer until per-integration docs reveal which bundles adopters actually want (P3).

### Architecture Approach

The existing system is a **bifurcated core**: a telemetry/metrics/SLO side (no Ecto) and an incident/timeline/action side (Ecto-backed). The v0.10 integration rule is clean and load-bearing: each pillar touches exactly one side. SLO packs and authoring guidance live entirely on the telemetry/SLO side via the Provider behaviour; runbook enrichment lives entirely on the incident/action side via template content; demo and docs sit outside the library boundary entirely. This preserves the architecture's foundational invariant. The only code-level extension points are well-defined and small.

**Major components:**
1. SLO Pack modules (`lib/parapet/slo/pack/*.ex`) — new `@behaviour Parapet.SLO.Provider` modules returning `SliceSpec` structs against existing metric names; participate in multi-burn-rate generation automatically with zero Generator changes. Must NOT use the deprecated legacy `register/1` path.
2. `Parapet.Runbook` step macro — add a single `warning:` key (surgical, nil-safe default); render it in the Operator UI detail template. This is the only DSL gap exposed by the entire milestone.
3. Runbook templates (`priv/templates/parapet.gen.runbooks/*.ex.eex`) — deepen 4 + add 3, all content-only using existing DSL vocabulary (`requires_preview`, `kind: :guidance`, `target_kind:`) plus the new `warning:`; generator keeps `on_exists: :skip` (host-ownership contract).
4. Docs (`docs/`, `docs/integrations/`) — authored Markdown rendered by ExDoc; the guidance layer, not code; reference only public commands/configs so `verify.public_api` catches drift.
5. `mix parapet.install` — add `--with-web-saas-pack` / `--with-delivery-saas-pack` flags following the existing provider-merge pattern; no new Mix task.

### Critical Pitfalls

1. **Docs claiming DSL behavior that doesn't exist (`warning:`)** — the `warning:` step key must be added to `Parapet.Runbook.step/2` BEFORE any template or guide uses it; Elixir silently swallows unknown macro keyword args, so misuse compiles cleanly but the warning never renders. This is the milestone's single most important sequencing constraint.
2. **Demo deps / `demo/` directory leaking into the published package** — keep `demo/` git-only with its own isolated `mix.exs`; never add it to the `files:` whitelist; gate with `mix hex.build --dry-run | grep demo` returning zero matches.
3. **Demo drifting to a stale Hex snapshot + having no CI check** — lock `{:parapet, path: "../../"}` and ship a `demo` CI job (`mix compile --warnings-as-errors && mix parapet.doctor`) in the same PR that creates the demo, never retrofitted.
4. **Starter packs baking in high-cardinality labels** — pack `SliceSpec.new/1` calls must use only low-cardinality labels (`:integration`, `:queue`, `:provider`); add an ExUnit assertion that no label key contains `id`/`trace`/`path`/`user`.
5. **Starter packs flapping on low-traffic apps** — every slice must set a non-zero `min_total_rate`; the authoring guide must have a dedicated low-traffic section (denominator guard, synthetic probe fallback, extended window) and explicitly name the lower-the-objective anti-pattern. Packs and guide must ship together.
6. **Runbook steps bypassing ClaimService / non-idempotent under retry** — every auto-execute-capable template needs a commented `ClaimService.claim_action/1` reference impl, an "Auto-Execution Setup" `@moduledoc` section (the `auto_execute_on:` mapping is separate config), and a state-verification guidance step before every mutating step.
7. **CHANGELOG.md hand-edited, conflicting with Release Please** — commit at most a header-only stub; put any retroactive v0.1–v0.9 history in `docs/history.md`, not in the changelog body.
8. **Per-integration guides hiding optional-dep behavior** — every guide must lead with a "Prerequisites" section naming the exact optional dep and stating that Parapet compiles cleanly but the integration won't activate without it; back it with a compile-out test.

## Implications for Roadmap

Based on research, the suggested phase structure follows the architecture's dependency-aware build order: foundation first (the `warning:` DSL and packaging gate everything), then code surfaces (packs, templates), then docs that accurately reference them, then the optional demo last.

### Phase 1: Packaging & DSL Foundation
**Rationale:** These deliverables have no dependencies and unblock everything else. The `warning:` DSL addition MUST land before any enriched template references it (Pitfall #1, the milestone's key sequencing constraint). hex.pm metadata is a credibility gate that all other adoption work depends on.
**Delivers:** `mix.exs` `docs:` key + `links:` + `CHANGELOG*` whitelist + ex_doc `~> 0.40`; header-only `CHANGELOG.md` stub (Release Please owns the body); `warning:` key in `Parapet.Runbook.step/2`; Operator UI detail template renders `warning:` when non-nil.
**Addresses:** hex.pm metadata + CHANGELOG (table stakes).
**Avoids:** Pitfall #1 (nonexistent DSL options), Pitfall #7 (CHANGELOG hand-edit conflict).

### Phase 2: SLO Starter Packs & Low-Traffic Guardrails
**Rationale:** Pack modules must exist before any doc or demo references them. Built on the already-shipped SLO engine — packs are thin Provider implementations.
**Delivers:** `Parapet.SLO.Pack.WebSaaS` (HTTP 99.9% / login 99.9% / Oban 99.5%); `Parapet.SLO.Pack.DeliverySaaS` (adds Mailglass/Chimeway delivery slices, conditional on those deps); `--with-web-saas-pack` / `--with-delivery-saas-pack` install flags; low-traffic comment block in `alerts.yml.eex`.
**Uses:** Provider behaviour, SliceSpec (`min_total_rate`), Generator multi-burn-rate windows — all existing.
**Implements:** SLO Pack modules (component 1) + install flags (component 5).
**Avoids:** Pitfall #4 (high-cardinality labels), Pitfall #5 (low-traffic flapping), Pitfall #13 (verify.public_api on new modules).

### Phase 3: Recovery Depth — Runbook Templates
**Rationale:** Template content must come after the `warning:` DSL exists (Phase 1). Generator change must come after the new template files exist.
**Delivers:** Deepen the four existing templates (dead_letter, callback_delay, stalled_executor, provider_outage) with precondition/scope/warning/verify steps; add `retry_storm`, `suppression_drift`, `partial_backlog_drain`; three new `Igniter.copy_template` calls (keep `on_exists: :skip`).
**Addresses:** richer preview-first runbook templates (differentiator, JTBD gap #1).
**Avoids:** Pitfall #6 (ClaimService bypass), Pitfall #7-runbook (non-idempotent steps), Pitfall #8 (`auto_execute` without `auto_execute_on:`).

### Phase 4: Core Docs — Getting Started, Troubleshooting, SLO Authoring
**Rationale:** These docs must accurately reflect the pack names (Phase 2) and template behavior (Phase 3) that now exist; writing them earlier would document things that don't compile.
**Delivers:** `docs/getting-started.md` (zero-to-30-min, ends at "first alert rule generated", zero raw PromQL); `docs/troubleshooting.md` (FAQ from install path); `docs/slo-authoring-guide.md` (good-vs-bad slicing + low-traffic section).
**Addresses:** getting-started, troubleshooting, SLO authoring guide (table stakes + differentiator).
**Avoids:** Pitfall #3 (assumes PromQL expertise), Pitfall #5-guide (low-traffic section), Pitfall #1 (no nonexistent options in examples).

### Phase 5: Per-Integration Guides
**Rationale:** Can reference the getting-started guide (Phase 4) as the canonical cross-link base. No new code — adapters already exist.
**Delivers:** `docs/integrations/{sigra,accrue,rulestead,threadline}.md`, each with a leading "Prerequisites" section naming the optional dep, the exact `Parapet.attach` line, and what SLO slices it unlocks. Author in adoption-frequency order: Sigra, Accrue, Rulestead, Threadline.
**Addresses:** per-integration guides + per-integration SLO slice surfacing (table stakes + differentiator).
**Avoids:** Pitfall #11 (hiding optional-dep / compile-out behavior).

### Phase 6: Runnable Demo (optional / deferrable)
**Rationale:** Highest effort, highest maintenance. Should come last so Phase 4-5 docs reduce the friction the demo is meant to solve; reassess cost-benefit after docs land. If built, the CI check is non-negotiable and ships in the same PR.
**Delivers:** git-only `demo/` (Docker Compose with pinned Prometheus `v3.x`/Grafana `11.x` + minimal Phoenix app pinned via `path: "../../"`); a `demo` CI job running `mix compile --warnings-as-errors && mix parapet.doctor`.
**Addresses:** runnable demo (P2 table stakes, deferred).
**Avoids:** Pitfall #2 (deps leak), Pitfall #12 (no CI check), Pitfall #2-drift (stale Hex snapshot).

### Phase Ordering Rationale

- **Dependency-driven:** The `warning:` DSL addition (Phase 1) is a hard prerequisite for enriched templates (Phase 3) — using it before it exists compiles silently and breaks at the UI. Pack modules (Phase 2) must exist before docs (Phase 4) can name them without referencing uncompilable code.
- **Architecture-aligned:** Code surfaces that touch the bifurcated core (Phases 2-3) precede the docs that describe them (Phases 4-5), which precede the out-of-boundary demo (Phase 6). Each pillar stays on its own side of the bifurcation.
- **Risk-front-loaded:** The credibility gate (metadata + CHANGELOG) and the single DSL sequencing constraint land in Phase 1. The highest-maintenance, most-droppable deliverable (demo) lands last so it can be reassessed against actual onboarding friction.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (SLO Packs):** One concrete open question — whether `Parapet.Metrics.AsyncDelivery.selector/2` handles HTTP label format, or whether the pack needs a small selector helper for HTTP `status_code` matchers. ARCHITECTURE.md flags this as a "one-line clarification, not a blocker," but it warrants a quick code check during planning. Run `--research-phase` only if the selector check reveals a gap.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Fully specified — verified `mix.exs` deltas, surgical macro change, header-only CHANGELOG stub. No research needed.
- **Phase 3 (Runbook Templates):** DSL and execution chain read directly; every step shape and gate is documented. Content work against a known DSL.
- **Phase 4 / Phase 5 (Docs):** Pure authoring against existing public APIs; structure and section content fully enumerated in FEATURES.md.
- **Phase 6 (Demo):** Pattern is the prom_ex Docker Compose idiom; isolation and CI requirements are fully specified.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All decisions verified against official ExDoc/Hex docs and canonical OSS mix.exs (ecto, req, ex_doc) plus direct repo read; live version numbers confirmed. |
| Features | HIGH | Ecosystem peer analysis well-sourced (Google SRE Workbook, AppSignal, ErrorTracker, PromEx, Oban Web); runbook gaps from direct codebase audit. Low-traffic alerting patterns are MEDIUM (community/SRE-doc consensus, not a single canonical impl). |
| Architecture | HIGH | Every component, behaviour, and gate read directly from source; integration points and the single DSL gap verified against live code. |
| Pitfalls | HIGH | All grounded in direct codebase audit + verified ecosystem patterns; each maps to a concrete CI check or sequencing rule. |

**Overall confidence:** HIGH

### Gaps to Address

- **HTTP SliceSpec selector format (Phase 2):** Confirm `AsyncDelivery.selector/2` handles HTTP `status_code` label matchers, or write a pack-specific selector helper. Resolve with a quick code read during Phase 2 planning; not a blocker per ARCHITECTURE.md.
- **Threadline integration honesty (Phase 5):** PITFALLS flags Threadline as "conceptual interoperability" — the guide must be honest about what is actually wired vs aspirational. Validate the real wiring state before writing the guide so it doesn't overclaim.
- **Demo go/no-go decision (Phase 6):** FEATURES defers the demo to P2 pending measurement that docs alone close the adoption gap. The roadmap should treat Phase 6 as conditional and revisit after Phases 4-5 land.
- **Low-traffic guidance is consensus, not canonical:** The denominator-guard / synthetic-probe / extended-window patterns are MEDIUM-confidence SRE community guidance. Validate the specific thresholds (e.g., 6h window, 50× burn rate) against Parapet's actual generated rule shapes during Phase 4 authoring.

## Sources

### Primary (HIGH confidence)
- Parapet codebase direct read — `lib/parapet/slo/{provider,slice_spec,generator}.ex`, `lib/parapet/slo.ex`, `lib/parapet/runbook.ex`, `lib/parapet/automation/{executor,claim_service,circuit_breaker}.ex`, `lib/mix/tasks/parapet.{install,gen.runbooks}.ex`, `priv/templates/parapet.gen.runbooks/*.ex.eex`, `priv/templates/parapet.gen.prometheus/alerts.yml.eex`, `mix.exs`, `mix.lock`, `.github/workflows/{ci,release-please}.yml` — source of truth for current state, extension points, and the `warning:` DSL gap.
- ExDoc configuration — https://hexdocs.pm/ex_doc/ExDoc.html (official); canonical mix.exs references: elixir-ecto/ecto, wojtekmach/req, elixir-lang/ex_doc (links/extras/groups patterns).
- Google SRE Workbook, "Alerting on SLOs" — https://sre.google/workbook/alerting-on-slos/ (multi-burn-rate math + low-traffic denominator problem).
- Release Please for Elixir — https://elixirschool.com/blog/managing-releases-with-release-please (CHANGELOG ownership model).
- Hex.pm publish docs — https://hex.pm/docs/publish (files: whitelist + metadata fields); current ex_doc version verified live at https://hex.pm/packages/ex_doc (0.40.3).
- ErrorTracker getting-started — https://hexdocs.pm/error_tracker/getting-started.html (Elixir-native onboarding peer).

### Secondary (MEDIUM confidence)
- PromEx — https://github.com/akoutmos/prom_ex (example_applications/ Docker Compose demo idiom + path-dep pattern).
- AppSignal Phoenix monitoring guide — https://blog.appsignal.com/2024/09/17/... ("guide ends when data appears" onboarding principle).
- Grafana SLO best practices — https://grafana.com/docs/grafana-cloud/alerting-and-irm/slo/best-practices/ (synthetic supplements for low traffic).
- Oban Web overview — https://oban.pro/docs/web/overview.html (recovery UI peer; direct bulk action vs Parapet preview-first).

### Tertiary (LOW confidence)
- Sloth — https://github.com/slok/sloth and Pyrra — https://github.com/pyrra-dev/pyrra (K8s-native SLO authoring peers; not Phoenix-native — used for contrast, not direct guidance).

---
*Research completed: 2026-05-23*
*Ready for roadmap: yes*
