# Feature Research

**Domain:** Adopter-facing onboarding, SLO authoring guidance, and common recovery depth for a mature Phoenix/Elixir OSS SRE library (Parapet v0.10)
**Researched:** 2026-05-23
**Confidence:** HIGH (ecosystem observations), MEDIUM (low-traffic alerting patterns), HIGH (runbook template gaps from direct codebase audit)

---

## Context: What Already Exists (Do Not Rebuild)

Before the feature landscape, the key constraint: Parapet v0.9 shipped a complete SRE stack. The v0.10 work is adoption-gap closure, not feature expansion. The existing built surfaces to build ON TOP OF:

- `mix parapet.install` / `mix parapet.gen.*` / `mix parapet.doctor` generators
- Provider-first SLO engine with multi-burn-rate PromQL alert generation
- Existing SLO providers: `Parapet.SLO.HTTP`, `Parapet.SLO.Oban`, `Parapet.SLO.LoginJourney`, `Parapet.SLO.MailglassDelivery`, `Parapet.SLO.ChimewayDelivery`, `Parapet.SLO.RindleAsync`, `Parapet.SLO.ScoriaEval`
- Four v0.7 runbook templates: `dead_letter.ex.eex`, `callback_delay.ex.eex`, `stalled_executor.ex.eex`, `provider_outage.ex.eex` — all currently thin stubs (1-2 steps each, minimal preconditions, no warnings)
- Eight integration adapters: Accrue, Chimeway, Mailglass, Rindle, Rulestead, Scoria, Sigra, Threadline — built but undocumented as adoption-facing guides
- `docs/adopter-flows.md`, `docs/slo-reference.md`, `docs/operator-ui.md`, `docs/telemetry.md` — internal docs with no structured getting-started path
- `mix.exs` package metadata: currently `links: %{}` (empty), no description field, no keywords

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features a stranger evaluating Parapet at 11 PM expects to find. Missing these = "this library isn't ready."

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Populated hex.pm metadata (`links:`, description, source_url) | Every credible Hex package links to its repo, docs, and issues. An empty `links: %{}` signals an abandoned or unpublished library. AppSignal, ErrorTracker, Oban all have full metadata. | LOW | Mix.exs change only. `links: %{"GitHub" => ..., "HexDocs" => ..., "Issues" => ...}`, add `:description` sentence. |
| `CHANGELOG.md` at repo root | Adopters check changelog before adding a dependency. Absence reads as "this project doesn't track what it ships." ErrorTracker, Oban, PromEx all have changelogs. | LOW | Conventional Commits are already in use; Release Please should auto-generate this. Needs a retroactive summary of v0.1–v0.9 at minimum. |
| One-page end-to-end getting-started guide | Distinct from reference docs. The single page an adopter reads before deciding whether to invest more time. AppSignal's guide has a forked demo app + 3 steps. ErrorTracker's guide is 8 focused sections. The current README is 208 lines split across features vs flows. | MEDIUM | Create `docs/getting-started.md` or restructure README. Must answer: "Install → first running SLO → first alert" in under 30 min. |
| Troubleshooting / FAQ doc | Every library of this complexity accumulates "why isn't my alert firing?" and "how do I configure with Fly.io?" questions. No FAQ = support burden on the maintainer. Sentry, AppSignal, ErrorTracker all have FAQ sections. | LOW-MEDIUM | `docs/troubleshooting.md`. Seed with the 5-7 most predictable questions based on install path (blank Prometheus target, doctor warn vs error, Oban compile-out, multi-node uniqueness). |
| Per-integration setup guides (Accrue, Rulestead, Threadline, Sigra) | Accrue/Rulestead/Threadline/Sigra adapters are fully built but invisible to adopters — no docs surface them. A stranger who uses Sigra for auth has no idea Parapet can automatically produce login journey SLOs. | MEDIUM | `docs/integrations/` directory with one file per integration. Each file: what events it hooks, what metrics/SLOs it produces, how to enable, what `Parapet.attach(adapters: [...])` line to add. |
| Runnable demo / example app | AppSignal links to a fork-and-run Phoenix app. PromEx ships `example_applications/`. ErrorTracker has no demo (notably, it is the weakest onboarding among peers). A runnable demo is the fastest way to reduce "does this actually work?" friction. | MEDIUM-HIGH | `examples/demo_app/` — minimal Phoenix app with Parapet wired up, a few SLOs defined, and instructions to `docker-compose up && mix parapet.install`. Must be kept green in CI. |

### Differentiators (Competitive Advantage)

Features that separate Parapet from "just PromEx + some Prometheus YAML."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Opinionated SLO starter packs by app type | PromEx, Sloth, and Pyrra all give you primitives; none give an opinionated "if you're a Phoenix SaaS shipping checkout + auth + email, start with these 4 SLOs." Parapet already has the engine and existing providers. The gap is the guidance layer. | MEDIUM | Concretely: ship `Parapet.SLO.StarterPack.WebSaaS` (HTTP + LoginJourney + ObanJobs) and `Parapet.SLO.StarterPack.DeliverySaaS` (adds MailglassDelivery + ChimewayDelivery). One `use Parapet.SLO.StarterPack.WebSaaS` line registers a coherent set of first SLOs. Depends on existing SLO providers. |
| Good-vs-bad journey slicing examples | SLO adoption fails most often at slicing, not at PromQL syntax. The JTBD gap map (#3) is explicit: adopters "struggle to choose the right slices." Grafana's best practice guide says "start with availability and latency, collaborate on what matters to customers." Parapet can be more opinionated than that. | LOW-MEDIUM | A `docs/slo-authoring-guide.md` with concrete before/after examples: "Don't: one SLO for all HTTP traffic. Do: separate login journey from checkout from background jobs." Include a decision tree: "Does this failure directly prevent a user from completing a task? → journey SLO. Is it infrastructure noise? → don't SLO it." |
| Low-traffic-safe alerting guidance | The Google SRE Workbook explicitly warns that multi-window multi-burn-rate alerts fail for low-traffic services: a single failure in a 10-req/hr service = 1000x burn rate. Parapet already generates multi-burn-rate PromQL. The gap is guidance about when that's not enough and what to do instead. | MEDIUM | In `docs/slo-authoring-guide.md`: named section "Low-Traffic and Low-Volume Services." Document the denominator guard pattern (`and sum(rate(total[1h])) > N`), the synthetic probe fallback, the raise-objective-temporarily approach. Reference Parapet's existing probe infrastructure. This does NOT require new engine code — it's guidance + generated rule commentary. |
| Richer prebuilt runbook templates with preconditions, warnings, and preview steps | The four existing templates are 1-2 step stubs. Dead letter has two steps; callback delay has one step; stalled executor has two steps; provider outage has two steps. By contrast, a credible SRE runbook for "dead letter recovery" should cover: precondition verification (is the root cause known?), scope check (how many items?), preview (show affected items before acting), warning (bounded retry, not bulk), confirm, and post-action verification. Oban Web's UI provides this for job management; Parapet needs to provide it for recovery. | MEDIUM | Deepen the four existing templates + add three new ones (retry storm, suppression drift, partial backlog drain). Each template needs: precondition steps (manual, `kind: :guidance`), a scoped preview step (`requires_preview: true`), at least one warning annotation (`warning: "..."`), the mitigation step with bounded capability, and a verification step. No new DSL needed — uses existing `Parapet.Runbook` step macro options. |
| Per-integration SLO slice surfacing | Sigra (auth login journey SLO), Accrue (billing/checkout journey SLO), Rulestead (flag-change correlation), Threadline (audit compliance SLO) — all built, none documented as "this integration gives you THIS SLO out of the box." | LOW-MEDIUM | Each integration guide should include: "When you enable this integration, you get [named SLO slices] automatically. Here is what they measure and why." Depends on per-integration guides. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-generated SLO targets (system proposes 99.9%) | Seems like DX. "Just tell me what objective to use." | A suggested 99.9% that doesn't reflect real user expectations or architecture constraints becomes a false safety guarantee. Teams accept it without understanding it, then page on noise. Google SRE Workbook explicitly warns against aspirational targets. | Opinionated starter packs with documented rationale ("99.9% for login: this means 43 min/month of user-impacting auth failures — is that acceptable?"). Make adopters confirm the target, not accept a default silently. |
| Bundled Grafana provisioning as part of demo setup | A demo with `docker-compose up grafana prometheus parapet_app` seems like great DX. | Grafana provisioning diverges fast from real adopter setups (datasource names, org IDs, auth). Maintaining a demo Grafana config that's always wrong for real users adds ongoing noise and false expectation. AppSignal's demo app deliberately sidesteps this. | The demo app should show the Parapet install path + doctor + generated Prometheus YAML. Link out to the existing `mix parapet.gen.grafana` instructions. Don't bundle a "live" Grafana. |
| Bundled SLO "score" or reliability rating | Adopters want a quick health grade. | A summary score (e.g., "Reliability: 87%") aggregates across SLOs with different weights, windows, and user-impact levels. It creates false confidence and is the first thing that gets put on an executive dashboard, divorced from context. | Show error budget burn rates per SLO slice in the operator UI. Let operators form their own judgment from context-rich signals, not a synthetic aggregate. |
| Auto-discovery of "important journeys" from telemetry | Sounds like a great zero-config path. | Parapet's core insight (from `adopter-flows.md`) is that the right SLOs require human intent — you have to decide checkout matters more than `/healthz`. Auto-discovery produces SLOs for things that don't need SLOs and misses the ones that do. | Opinionated starter packs + decision guide. Humans pick the journeys; Parapet provides the slice definitions and alert math. |
| Hosted CHANGELOG / release subscription | Adopters ask for "email me when there's a new version." | Third-party release subscription services add a vendor dependency to the OSS project and create privacy surface. The Elixir community already has `mix hex.outdated` and GitHub watch functionality. | Link to GitHub releases + ship CHANGELOG.md. Conventional Commits + Release Please already does the generation work. |

---

## Feature Dependencies

```
Runnable Demo App
    └──requires──> Getting-Started Guide (the demo needs narrative framing)
    └──requires──> hex.pm metadata + CHANGELOG (demo README links to them)

Per-Integration Guides (Accrue, Rulestead, Threadline, Sigra)
    └──requires──> No new code — existing adapters already built
    └──enables──> Per-Integration SLO Slice Surfacing (docs unlock discovery)

SLO Starter Packs (StarterPack.WebSaaS, StarterPack.DeliverySaaS)
    └──requires──> Existing SLO providers (HTTP, Oban, LoginJourney, MailglassDelivery, etc.)
    └──requires──> SLO Authoring Guide (starter packs without guidance create confusion)

SLO Authoring Guide
    └──requires──> Low-Traffic Guidance section (inseparable from SLO slicing guidance)
    └──enhances──> Runnable Demo (demo can reference the guide for "next steps")

Richer Runbook Templates (deepen existing 4 + add 3 new)
    └──requires──> Existing Parapet.Runbook DSL (already built)
    └──requires──> Existing runbook template generator (mix parapet.gen.runbooks)
    └──enhances──> Per-Integration Guides (guides can reference specific runbooks)

Troubleshooting / FAQ
    └──requires──> Getting-Started Guide (FAQ answers questions the guide raises)
    └──enhances──> Per-Integration Guides (integration-specific FAQ entries)

hex.pm metadata + CHANGELOG
    └──requires──> Nothing new (mix.exs change + generated file)
    └──enables──> All other adoption funnel items (credibility gate)
```

### Dependency Notes

- **hex.pm metadata blocks everything**: An empty `links: %{}` signals an unpublished or unmaintained library before any other content is read. This is a 30-minute fix that must land first.
- **Getting-started guide and demo are co-dependent**: A demo without a guide is a repo. A guide without a demo is theory. Both should ship together.
- **Runbook templates don't require engine changes**: The Parapet.Runbook DSL already supports `warning:`, `requires_preview: true`, `kind: :guidance`, and `preconditions:`. Deepening templates is template content work, not API work.
- **SLO starter packs require existing providers**: StarterPack modules are thin wrappers that call `register/1` on existing SLO providers with opinionated defaults. No new SLO math needed.

---

## MVP Definition

### Launch With (v0.10)

This is not a greenfield MVP — it is a "credibility gate" release for a library that is already feature-complete. The minimum set to move from "feature-complete but unadoptable by a stranger" to "stranger can evaluate, install, and succeed."

- [ ] **hex.pm metadata** (`links:`, description, source_url) — credibility gate, 30-minute fix
- [ ] **CHANGELOG.md** — credibility gate, blocks hex.pm discoverability trust
- [ ] **One-page getting-started guide** (`docs/getting-started.md`) — the single doc that converts interest to installation
- [ ] **Troubleshooting / FAQ doc** (`docs/troubleshooting.md`) — reduces abandonment at the first obstacle
- [ ] **Per-integration setup guides** (Accrue, Rulestead, Threadline, Sigra minimum) — unlocks discovery of built-but-invisible capabilities
- [ ] **SLO authoring guide with good-vs-bad examples and low-traffic guidance** (`docs/slo-authoring-guide.md`) — closes JTBD gap #3
- [ ] **SLO starter packs** (`Parapet.SLO.StarterPack.WebSaaS`, `Parapet.SLO.StarterPack.DeliverySaaS`) — the "what SLO do I add first?" answer
- [ ] **Richer runbook templates** (deepen existing 4 stubs; add `retry_storm`, `suppression_drift`, `partial_backlog_drain`) — closes JTBD gap #1

### Add After Validation (v0.10.x)

- [ ] **Runnable demo app** (`examples/demo_app/`) — high value but high maintenance cost; validate doc improvements reduce onboarding friction before investing in a live demo
- [ ] **CI-kept demo green check** — once demo app exists, must be in CI

### Future Consideration (v1.0+)

- [ ] **Interactive SLO wizard via `mix parapet.gen.slo`** — guided prompts ("What journey? What's acceptable failure rate?") that generate a starter SLO definition. Deferred: guide + starter packs are faster to ship and carry less maintenance risk.
- [ ] **Cross-integration SLO slice bundles** — a pack that wires Sigra (login) + Accrue (checkout) + Chimeway (notification) into a single "e-commerce SaaS reliability suite." Deferred until per-integration docs prove which bundles adopters actually want.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| hex.pm metadata + links | HIGH | LOW | P1 |
| CHANGELOG.md | HIGH | LOW | P1 |
| Getting-started guide | HIGH | MEDIUM | P1 |
| Troubleshooting / FAQ | HIGH | LOW-MEDIUM | P1 |
| Per-integration guides (4 integrations) | HIGH | MEDIUM | P1 |
| SLO authoring guide + low-traffic guidance | HIGH | MEDIUM | P1 |
| SLO starter packs (WebSaaS + DeliverySaaS) | HIGH | MEDIUM | P1 |
| Richer runbook templates (deepen 4 + add 3) | HIGH | MEDIUM | P1 |
| Runnable demo app | MEDIUM-HIGH | HIGH | P2 |
| `mix parapet.gen.slo` interactive wizard | MEDIUM | HIGH | P3 |
| Cross-integration SLO bundles | MEDIUM | MEDIUM | P3 |

**Priority key:**
- P1: Must have for v0.10 launch
- P2: Add after core v0.10 docs land and adoption friction is measured
- P3: Future consideration, v1.0+

---

## Competitor Feature Analysis

| Feature | PromEx | ErrorTracker | AppSignal | Oban Web | Sloth/Pyrra | Parapet v0.10 Plan |
|---------|--------|-------------|-----------|----------|-------------|-------------------|
| Onboarding flow | 4-step generator + example apps | Igniter single-command + 8-section guide | mix task guided install + demo fork | Docs-only (Pro tier) | CLI + YAML examples | Getting-started guide + per-integration guides + optional demo app |
| SLO support | None (metrics only) | None (error tracking only) | Throughput/error alerts, no user-journey SLOs | Queue health only | Full SLO YAML + recording rules + multi-burn alerts | Existing engine + starter packs + authoring guide |
| Low-traffic alerting guidance | None | N/A | Not documented | N/A | Not documented | Named guidance section in SLO authoring guide (denominator guard, synthetic probe fallback) |
| Journey slicing guidance | None | None | Generic "performance monitoring" | Queue-scoped | Define your own SLIs | Good-vs-bad slicing examples + decision guidance in authoring guide |
| Recovery runbooks | None | None | None | Cancel/retry/pause jobs in UI | None | Deepen 4 existing + add 3 new (retry storm, suppression drift, partial backlog drain) |
| Preview-before-execute recovery | None | None | None | No preview (direct bulk action) | None | Already in DSL; deepen templates to consistently use requires_preview |
| hex.pm metadata quality | Full (links, description, keywords) | Full | Full | Full | N/A (CLI tool) | Fix empty links: %{}, add description and source_url |
| CHANGELOG | Yes | Yes | Yes | Yes | Yes | Missing — P1 to add |
| Per-integration guides | Plugin docs (built-in plugins only) | Phoenix/LiveView/Oban auto-tracked | Ecto instrumentation guide | N/A | N/A | docs/integrations/ for each of 4 undocumented adapters |
| Runnable demo | example_applications/ in repo | None (weakest onboarding peer) | Fork-and-run demo app | N/A | getting-started.yml example | Deferred to P2; guide + starter packs come first |

### Key Competitive Observations

**PromEx** (closest Phoenix metrics peer): Metrics-only, no SLO authoring, no runbooks, no journey concept. Parapet's differentiator is exactly the SLO-to-incident loop that PromEx stops short of. PromEx's onboarding is strong (example apps, clean generator) — this is the bar to match for DX.

**ErrorTracker**: Weakest onboarding of all peers (no demo, guide only). Yet it has a clean `mix igniter.install error_tracker` single-command path that Parapet already matches with `mix parapet.install`. The gap is ErrorTracker's guide is more focused (error tracking is a simpler JTBD).

**AppSignal**: Best onboarding DX in the peer set. The `mix appsignal.install API_KEY` interactive terminal flow + forked demo app sets the bar. Parapet cannot offer the SaaS-side (no hosted account), but it can offer a comparable "zero to first working thing" guide quality.

**Oban Web**: The direct peer for "recovery UI." Oban Web's bulk retry/cancel/pause is direct (no preview). Parapet's preview-first recovery is a genuine differentiator — but it needs templates deep enough that operators believe the preconditions are real, not boilerplate.

**Sloth/Pyrra**: SLO generation tools for Kubernetes-native stacks. Neither addresses Phoenix-native telemetry, journey-level SLIs, or async/delivery fault planes. Parapet already surpasses both for the Phoenix adopter, but has weaker authoring guidance.

---

## Specific Deliverables: SLO Starter Packs

### `Parapet.SLO.StarterPack.WebSaaS`

Target: A Phoenix SaaS with request handling, auth, and background jobs. Registers:

1. `Parapet.SLO.HTTP` — overall request availability (99.9% default)
2. `Parapet.SLO.LoginJourney` — auth success rate via Sigra or direct instrumentation (99.9% default)
3. `Parapet.SLO.Oban` — job success rate across all queues (99.5% default — lower because job retries are expected)

Opinionated defaults with documented rationale. One `use` or `apply/1` call registers all three.

### `Parapet.SLO.StarterPack.DeliverySaaS`

Target: A Phoenix SaaS that also sends emails and/or notifications. Extends WebSaaS with:

4. `Parapet.SLO.MailglassDelivery` — `mailglass_confirmed_delivery` slice (provider confirmation, not just submit)
5. `Parapet.SLO.ChimewayDelivery` — `chimeway_callback_confirmation` slice

Only registers Mailglass/Chimeway slices if those providers are configured — compile-out-cleanly constraint applies.

### What a Starter Pack Guidance Doc Must Address

- Why these four/five and not others (what user harms they cover)
- What the objective numbers mean in human terms (43 min/month downtime at 99.9%)
- What to do when you want to add a checkout SLO (point to authoring guide for custom slices)
- When NOT to use a starter pack (brownfield apps with existing PromQL — follow migration guide instead)

---

## Specific Deliverables: Runbook Templates

### Deepen Existing Four Templates

**`dead_letter.ex.eex`** — Currently: 2 steps (investigate error, requeue item). Needs:
- Step 0: Precondition — verify root cause is understood before any retry (manual guidance, not mitigation)
- Step 0b: Scope check — count affected items in DLQ before acting (manual guidance)
- New warning annotation on requeue step: "Retrying without fixing root cause re-populates the DLQ. Confirm the error class is resolved."
- Step 3: Post-action verification — confirm items are processing, not re-failing (manual guidance)

**`callback_delay.ex.eex`** — Currently: 1 step (verify webhook receipt). Needs:
- Step 1b: Provider status check (was the callback sent from provider side? manual guidance)
- Step 2: Distinguish lag categories — network delay vs never-sent vs suppressed (guidance)
- Step 3 (conditional): Force-fetch callback if provider supports it (mitigation, requires_preview, bounded to single item)
- Step 4: Escalate to provider if delay exceeds SLA (manual escalation step)

**`stalled_executor.ex.eex`** — Currently: 2 steps (investigate logs, retry item). Needs:
- Step 0: Precondition — confirm job is genuinely stalled, not in a slow-but-expected state (guidance with time boundary: "stalled means executing for > N × expected duration")
- Step 1b: Check for concurrency locks or resource contention (guidance)
- Warning on retry: "Retrying a stuck job without clearing the lock will produce a duplicate. Confirm no zombie lock exists."
- Step 3: Post-retry verification (guidance)

**`provider_outage.ex.eex`** — Currently: 2 steps (check status page, request manual check). Needs:
- Step 1b: Check Parapet's own delivery SLO burn rate to distinguish partial vs full outage (guidance with link)
- Step 2: Decide on fallback strategy — hold queue or switch provider (guidance with decision tree)
- Step 3: Mitigation (bounded) — pause queue if provider is confirmed down, requires_preview
- Step 4: Re-enable queue + verify when provider recovers (manual guidance)

### New Templates to Add

**`retry_storm.ex.eex`**:
- Precondition: Confirm exponential backoff is configured (Oban default: yes, but verify)
- Scope: Count jobs currently scheduled for retry in the next N minutes
- Warning: "Bulk clearing retry schedules without fixing root cause defers, not resolves, the storm."
- Mitigation: Pause affected queues temporarily (bounded, requires_preview, `target_kind: :queue`)
- Mitigation: Drain or reschedule retry cohort with jitter (bounded, requires_preview)
- Verification: Confirm retry rate is declining

**`suppression_drift.ex.eex`**:
- Precondition: Confirm Mailglass suppression list has grown in the monitoring window (link to suppression SLI)
- Scope: How many addresses suppressed? How recently? What suppression reason?
- Warning: "Bulk un-suppressing addresses that bounced hard will damage sender reputation."
- Mitigation: Review suppression reason categories — only soft bounces and user-request suppression are safe candidates for review (guidance)
- Mitigation: Initiate bounded suppression review workflow (requires_preview, scoped to soft-bounce cohort)
- Verification: Confirm delivery rate recovers, re-suppression rate stays low

**`partial_backlog_drain.ex.eex`**:
- Precondition: Confirm backlog age distribution (oldest item age, not just queue depth)
- Scope: Is the backlog growing, stable, or shrinking? What's the processing rate vs insertion rate?
- Warning: "Draining an oversized backlog at full speed can overwhelm downstream providers. Use bounded concurrency."
- Mitigation: Set temporary queue concurrency ceiling (requires_preview, bounded to queue)
- Mitigation: Drain N items (bounded batch, preview shows items before execution)
- Verification: Confirm drain rate is sustainable, downstream error rate is stable

---

## Specific Deliverables: Getting-Started Guide Structure

The canonical zero-to-30-minutes path. One doc, one job.

**What it covers** (distinct from reference docs):
1. What Parapet is in two sentences (user-journey reliability, not generic metrics)
2. Add dependency + run `mix parapet.install` — expected output
3. Run `mix parapet.doctor` — what green vs warn vs error means
4. "Your first SLO" — copy-paste a WebSaaS starter pack activation
5. Generate Prometheus artifacts — `mix parapet.gen.prometheus` expected output
6. What fires your first alert — what to simulate, what to look for in Prometheus
7. Where to go next — links to reference docs (adopter-flows, slo-reference, operator-ui, integrations/)

**What it does NOT cover** (saved for reference docs):
- Full SLO DSL API
- All generator flags
- Custom provider module authoring
- Escalation policy configuration

**Structural principle (learned from AppSignal and ErrorTracker comparison)**: The getting-started guide ends when the adopter has seen something work, not when all features are explained. AppSignal's guide ends with "you should now see data in the AppSignal dashboard." This guide ends with "you should now see a Prometheus alert rule generated for your checkout SLO."

---

## Specific Deliverables: Per-Integration Guides

Location: `docs/integrations/` directory. One file per integration.

**Each guide structure** (consistent across all four):
1. What this integration does (1 paragraph)
2. Prerequisites (what the sibling library must be installed and configured for)
3. Enable in Parapet (the exact `Parapet.attach(adapters: [...])` line)
4. What you get out of the box (which metrics and SLO slices this unlocks)
5. Configuration options (any provider-specific config keys)
6. What to add to `mix parapet.gen.prometheus` output (any SLO provider config)
7. Troubleshooting (the 2-3 most common "why isn't this working?" answers)

**Priority order for authoring** (by expected adoption frequency):
1. Sigra — login journey SLO is the first SLO most Phoenix SaaS teams want
2. Accrue — billing/checkout journey is second most common
3. Rulestead — flag-change correlation is useful for any team doing feature flags
4. Threadline — audit compliance is more niche, documents last

---

## Low-Traffic Alerting: Specific Guidance Content

The Google SRE Workbook defines the problem precisely: a 10-req/hr service with one failure = 1000× burn rate = immediate page on a 99.9% SLO. Parapet's generated PromQL must be accompanied by guidance explaining when it needs adjustment.

**Three recommended patterns to document** (in the SLO authoring guide):

1. **Denominator guard**: Add `and sum(rate(total_metric[1h])) > MINIMUM_RATE` to alert rules to prevent firing when traffic is statistically insufficient. Parapet's generator should emit a commented example in the generated alert YAML.

2. **Synthetic probe fallback**: For very-low-traffic journeys (e.g., a B2B SaaS with 50 logins/day), supplement with Parapet's existing `Parapet.Probe` infrastructure. Synthetic probes maintain signal quality when real traffic is too sparse for burn-rate math to be meaningful.

3. **Extended window / lower sensitivity target**: For low-traffic services, replace a 1-hour fast window with a 6-hour fast window, and raise the burn-rate threshold at the short window from 14.4× to significantly higher (e.g., 50×). Document when this is appropriate vs when to prefer the synthetic probe approach.

**Anti-pattern to name explicitly**: Lowering the SLO objective just to silence noisy alerts (e.g., 90% instead of 99.9% for login, because login is low-traffic in staging). Name it, explain why it's harmful (you lose production signal), and recommend the denominator guard instead.

---

## Sources

- Google SRE Workbook, Alerting on SLOs: https://sre.google/workbook/alerting-on-slos/ (HIGH confidence — primary reference for burn-rate math and low-traffic guidance)
- Grafana SLO best practices: https://grafana.com/docs/grafana-cloud/alerting-and-irm/slo/best-practices/ (HIGH confidence — recommends synthetic supplements for low traffic)
- AppSignal Phoenix monitoring guide: https://blog.appsignal.com/2024/09/17/a-complete-guide-to-phoenix-for-elixir-monitoring-with-appsignal.html (MEDIUM confidence — onboarding flow benchmark)
- ErrorTracker getting-started guide: https://hexdocs.pm/error_tracker/getting-started.html (HIGH confidence — Elixir-native onboarding pattern peer)
- Hex.pm publish documentation: https://hex.pm/docs/publish (HIGH confidence — metadata field reference)
- PromEx GitHub: https://github.com/akoutmos/prom_ex (HIGH confidence — Phoenix metrics peer, example_applications benchmark)
- Oban Web overview: https://oban.pro/docs/web/overview.html (MEDIUM confidence — recovery UI peer)
- Sloth GitHub: https://github.com/slok/sloth (MEDIUM confidence — SLO authoring peer)
- Pyrra GitHub + article: https://github.com/pyrra-dev/pyrra, https://0xdc.me/blog/service-level-objectives-made-easy-with-sloth-and-pyrra/ (MEDIUM confidence — SLO authoring peer)
- Parapet codebase audit: direct read of mix.exs, lib/parapet/slo/*, priv/templates/parapet.gen.runbooks/*, docs/* (HIGH confidence — source of truth for current state)

---

*Feature research for: Parapet v0.10 Adopter Success — Phoenix/Elixir OSS SRE library adoption gap closure*
*Researched: 2026-05-23*
