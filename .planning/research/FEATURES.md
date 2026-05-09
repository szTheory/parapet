# Feature Research

**Domain:** Phoenix SaaS reliability layer / opinionated SRE substrate
**Researched:** 2026-05-09
**Confidence:** HIGH — grounded in extensive prior domain research, prior art analysis, Elixir ecosystem survey, and explicit product decisions in PROJECT.md

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features a Phoenix SaaS team assumes exist in any SRE library. Missing any of these means the product feels incomplete before they've read the docs.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Phoenix route metrics (request rate, error rate, latency) | Every Prometheus/Grafana setup starts here; PromEx already ships this | LOW | Must use Phoenix route pattern labels, not raw paths — raw paths are the #1 cardinality footgun |
| Low-cardinality metric label enforcement | Prometheus orthodoxy; teams already know this rule but can't easily enforce it | MEDIUM | Not a config option — violations are bugs. Lint at compile time and doctor-check at runtime |
| Oban job/queue health metrics | Any Phoenix SaaS with background jobs expects queue health monitoring | MEDIUM | Retry-aware semantics are non-negotiable — a single job exception ≠ a page |
| Ecto DB pool saturation metrics | Standard Phoenix operational concern; `queue_time` vs `query_time` separation is essential | LOW | Distinguish "DB is slow" from "pool is saturated" — different mitigations |
| Prometheus recording and alerting rule generation | Teams expect not to hand-write PromQL for SLOs | HIGH | The Sloth/Pyrra lesson: SLO rule generation is table stakes for any SLO product |
| Grafana dashboard artifacts | Operators live in Grafana; generating dashboards is the obvious deliverable | MEDIUM | Provision as JSON + provisioning YAML, not manual import instructions |
| Install generator (mix task) | Phoenix ecosystem convention; teams expect generators for non-trivial setup | MEDIUM | Generated files stay host-owned and modifiable — not hidden behind library config |
| `mix parapet.doctor` health check | Teams need install confidence before going to production | MEDIUM | Must catch the critical footguns: public `/metrics`, public LiveDashboard, high-cardinality labels |
| Day-1 install guide through first alert | A README that stops at "add to mix.exs" is unusable | LOW | Cover the path: install → configure → first SLO → first alert → first Grafana panel |
| Telemetry contract as documented public API | Teams that build on Parapet telemetry events need semver guarantees | MEDIUM | Treat breakage the same as a function signature change; publish event schema in docs |

### Differentiators (Competitive Advantage)

Features that separate Parapet from "just use PromEx" or "hand-assemble with telemetry_metrics_prometheus."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Journey-based SLO modeling | "Checkout completion SLO is burning" is actionable; "5xx rate elevated" is not — journey framing changes what operators do | HIGH | The core product idea: instrument user journeys, not just system signals |
| SLO DSL that compiles to Prometheus rules | Developers should never hand-write multi-window burn-rate PromQL | HIGH | Steal from Sloth: simple spec → recording rules + alerting rules; steal from Pyrra: show error budget |
| Deploy/change correlation markers | The most common incident question is "what changed?" — Parapet answers it automatically | MEDIUM | Correlate SLO degradation windows with deploy SHA, migration, flag change |
| Cardinality safety as a hard constraint | Most libraries treat cardinality as user responsibility; Parapet enforces it | MEDIUM | Label linting at compile time, runtime cardinality warnings in doctor; not a setting |
| Sigra auth journey as first business SLO | Login failure is the most universal customer-harm signal; first-class integration validates the whole pattern | MEDIUM | Login SLO via Sigra events is the reference integration that proves the model |
| Wide events schema separated from metrics | Teaches the correct split: low-cardinality metrics for alerting, high-cardinality events for investigation | MEDIUM | user_id/account_id/request_id belong in structured events, never in metric labels |
| Volume gates on low-traffic SLOs | Prevents paging on statistically meaningless blips in low-traffic routes | LOW | A 100% error rate on 1 request is not a SEV-1; volume gates make this correct |
| `mix parapet.doctor` as CI gate | Doctor checks that block CI on hard safety violations create a paved road for the whole team | LOW | Exit codes: 0 = ok, 1 = warnings over threshold, 2 = hard safety failure |
| Host-owned generated scaffolding | Adopters read and modify what Parapet generates — no hidden magic | MEDIUM | Generator model means teams trust what's in their repo; they own the reliability config |
| OpenSLO-compatible export | Interoperable with the broader SLO ecosystem (Sloth, Pyrra, vendor tools) | LOW | YAML export as an output format; makes Parapet's SLO model vendor-neutral |
| AGENTS.md context generation | AI coding assistants get structured, cited operational context without hallucinating | LOW | Deferred to v0.2+, but design the evidence model now to avoid breaking changes |

### Anti-Features (Commonly Requested, Often Problematic)

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Custom metrics backend / storage | Teams want "one tool" | Rebuilding Prometheus/VictoriaMetrics/Mimir is enormous scope; Parapet's value is on top of these, not replacing them | Generate Prometheus metrics; let teams choose their backend |
| Hosted SaaS / phone-home mode | Managed service is easier | Violates host-owned principle; creates vendor relationship; changes security boundary | Open-source, host-owned only; no telemetry sent to third parties |
| Autonomous incident remediation (AI autopilot) | "Fix it automatically" is appealing | Unbounded production mutations without approval gates cause outages; AI hallucinations are dangerous at prod | Evidence bundles + approval-gated tools; AI investigates, human decides |
| Per-user metrics and dashboards | Customer-specific visibility sounds valuable | Puts user_id in metric labels → cardinality explosion → Prometheus OOM | High-cardinality fields in structured events/traces only; aggregate metrics by route/status |
| Custom notification/paging system | "All-in-one" alerts from the library | Different teams use PagerDuty, Opsgenie, Slack, email — owning notification delivery creates N integrations to maintain | Generate Prometheus alert rules with routing metadata; Alertmanager/Grafana Alerting handles delivery |
| In-app operator/admin UI (v0.1) | Embedded visibility is convenient | Grafana already exists in most stacks; a competing UI in v0.1 costs more than it adds before the evidence model is proven | Grafana dashboard artifacts in v0.1; in-app UI only when it materially beats the alternative |
| Email deliverability monitoring (v0.1) | Email is SaaS infrastructure | Scope creep before the spine is proven; adds provider webhook handling complexity before core is validated | Design the event model to accommodate email; ship after HTTP + Oban + login are working |
| DB-backed durable evidence spine (v0.1) | Persistence makes incidents queryable | Commits to a DB schema before the telemetry contract is stable; locking adopters into a schema prematurely is a breaking-change risk | Telemetry-first in v0.1; durable spine in v0.2 after the event contract is stable |
| Real-time LiveView incident dashboard (v0.1) | Looks impressive in demos | Significant frontend investment before the data model is proven; Grafana already serves the operator audience | Grafana artifacts for v0.1 operator surface |

---

## Feature Dependencies

```
Telemetry Contract (documented, semver)
    └──required by──> HTTP Metrics Slice
    └──required by──> Oban Metrics Slice
    └──required by──> Login Journey SLO (Sigra)
    └──required by──> Wide Events Schema

HTTP Metrics Slice (route classification, label contracts)
    └──required by──> SLO DSL (needs correct total/good event sources)

SLO DSL (good/total counts, objective, window)
    └──required by──> Prometheus Rule Generation (recording + alerting rules)
    └──required by──> Grafana SLO Panels
    └──required by──> Volume Gates

Prometheus Rule Generation
    └──required by──> Grafana Dashboard Artifacts (panels reference recording rules)

Deploy Markers
    └──enhances──> SLO Windows (correlate degradation with deploys)
    └──enhances──> Grafana Dashboards (deploy overlays)

Wide Events Schema
    └──enhances──> Investigation Workflow (separate from metrics path)

mix parapet.doctor
    └──validates──> All of the above (cardinality, label contracts, endpoint security)

[v0.2+] Durable Evidence Spine
    └──requires──> Telemetry Contract (stable event schema from v0.1)
    └──enhances──> Incident Management

[v0.2+] Email Deliverability Monitoring
    └──requires──> HTTP Metrics Slice (same instrumentation pattern)
    └──requires──> Telemetry Contract (provider event normalization)

[v0.2+] AI Evidence Bundles / AGENTS.md
    └──requires──> Wide Events Schema
    └──requires──> Durable Evidence Spine (for cited, stable evidence)
```

### Dependency Notes

- **Telemetry contract requires everything:** The telemetry event schema is the foundation. Getting it right in v0.1 prevents breaking changes when durable surfaces are added in v0.2.
- **HTTP metrics slice requires route classification first:** Without Phoenix route pattern labels (not raw paths), any SLO built on HTTP metrics has unbounded cardinality. Route classification is a hard prerequisite.
- **SLO DSL requires correct metric sources:** The DSL compiles to Prometheus recording rules that aggregate good/total counts. If the underlying metrics have bad labels, SLO math is wrong.
- **Volume gates depend on the SLO DSL being correct:** Can't gate on volume if the good/total counts aren't trustworthy.
- **Durable spine conflicts with v0.1 scope:** Shipping DB-backed evidence before the telemetry contract is stable risks a breaking migration when the event schema changes.

---

## MVP Definition

### Launch With (v0.1 "Trustworthy spine")

Minimum viable product — what establishes the contract and delivers the first end-to-end reliability signal.

- [ ] **Telemetry contract** — documented event schema treated as public API with semver guarantees; establishes the foundation before durable surfaces are added
- [ ] **HTTP/API health slice** — Phoenix route metrics (request rate, error rate, latency) with low-cardinality labels; route classification using Phoenix route patterns not raw paths
- [ ] **Oban/job health slice** — failure rate, throughput, latency per queue and worker; retry-aware semantics (single exception ≠ page)
- [ ] **Login journey SLO (via Sigra)** — auth success rate as the first business-critical SLO; validates the full SLI → SLO → burn-rate alert pipeline
- [ ] **Deploy/change markers** — correlated with SLO windows and error spikes; answers "what changed?" during incidents
- [ ] **Grafana dashboard artifacts** — generated JSON dashboards and Prometheus provisioning YAML for the v0.1 slices; not manual import instructions
- [ ] **Prometheus alerting rules** — generated recording + alerting rules for HTTP availability, HTTP latency, Oban queue health, login SLO
- [ ] **`mix parapet.doctor`** — catches the critical footguns: public `/metrics`, public LiveDashboard, high-cardinality labels, missing SLO runbooks; CI gate with exit codes
- [ ] **Install generator** — `mix parapet.install` generates host-owned, inspectable scaffolding; library config for runtime behavior
- [ ] **Day-1 install guide** — covers install → configure → first SLO → first alert → first Grafana panel

### Add After Validation (v0.2)

Features to add once the spine is proven and the telemetry contract is stable.

- [ ] **DB-backed durable evidence spine** — telemetry contract is stable, safe to commit to a persistence schema; enables querying incident history
- [ ] **Email deliverability monitoring** — provider event normalization (Postmark, SendGrid, SES), transactional email SLOs, bounce/complaint dashboards; deferred because it adds provider webhook surface before core is validated
- [ ] **Chimeway notification delivery health** — delivery latency, queue backlog, provider degradation markers; follows same pattern as email slice
- [ ] **Accrue billing/checkout journey SLOs** — revenue-critical journeys as a named slice; high-value but depends on the spine being trusted

### Future Consideration (v0.3+)

Features to defer until product-market fit is established and the evidence model is proven.

- [ ] **In-app operator/admin UI** — LiveDashboard SRE pages (SLOs, error budgets, incidents, runbooks); build only when it materially beats Grafana for the operator use case
- [ ] **AI evidence bundles / AGENTS.md generation** — structured investigation context for AI coding assistants; needs stable durable evidence spine to produce cited, trustworthy evidence
- [ ] **Approval-gated MCP tools** — read-only investigation tools first; production-mutation tools with approval gates; deferred because it requires proven evidence model and audit infrastructure
- [ ] **Incident management layer** — state model, timeline entries, postmortem drafts, action item tracking; full incident workflow after the evidence model is operational
- [ ] **Synthetic checks** — scheduled probes for critical journeys; useful but adds active-probe infrastructure complexity
- [ ] **Additional sibling library integrations** — Mailglass, Threadline, Rulestead, Rindle; each follows the Sigra pattern after it's validated

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Telemetry contract (event schema) | HIGH | LOW | P1 |
| HTTP/API health slice | HIGH | MEDIUM | P1 |
| Oban/job health slice | HIGH | MEDIUM | P1 |
| Login journey SLO (Sigra) | HIGH | MEDIUM | P1 |
| Prometheus rule generation | HIGH | HIGH | P1 |
| Grafana dashboard artifacts | HIGH | MEDIUM | P1 |
| `mix parapet.doctor` | HIGH | MEDIUM | P1 |
| Install generator | HIGH | MEDIUM | P1 |
| Day-1 install guide | HIGH | LOW | P1 |
| Deploy/change markers | HIGH | LOW | P1 |
| Wide events schema | MEDIUM | MEDIUM | P2 |
| Volume gates on SLOs | MEDIUM | LOW | P2 |
| Cardinality linting (compile-time) | HIGH | MEDIUM | P2 |
| OpenSLO export | LOW | LOW | P2 |
| DB-backed evidence spine | MEDIUM | HIGH | P2 (v0.2) |
| Email deliverability monitoring | MEDIUM | HIGH | P2 (v0.2) |
| In-app operator UI | MEDIUM | HIGH | P3 |
| AI evidence bundles / AGENTS.md | MEDIUM | MEDIUM | P3 |
| Approval-gated MCP tools | LOW | HIGH | P3 |
| Incident management layer | MEDIUM | HIGH | P3 |
| Synthetic checks | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for v0.1 launch — the "trustworthy spine"
- P2: Should have; build after v0.1 spine is validated
- P3: Nice to have; defer until the evidence model is proven and PMF is established

---

## Competitor Feature Analysis

| Feature | PromEx | Hand-assembled (telemetry_metrics_prometheus + Grafana) | Datadog/AppSignal (hosted) | Parapet approach |
|---------|--------|--------------------------------------------------------|---------------------------|-----------------|
| Prometheus metrics for Phoenix/Ecto/Oban | Yes — plugin-based | Yes — DIY | Yes — SDK | Compose/interoperate; not duplicate PromEx |
| Grafana dashboard generation | Yes — plugin dashboards auto-uploaded | No — manual | Vendor UI | Generate JSON + provisioning YAML; host-owned |
| SLO DSL | No | No | Vendor-specific | First-class; compiles to recording + alerting rules |
| Journey-based SLO modeling | No | No | Partial (APM transactions) | Core product differentiator |
| Burn-rate alerting rule generation | No | No | Vendor-specific | Auto-generated from SLO DSL; no hand-written PromQL |
| Deploy correlation | No | No | Yes (hosted) | Deploy markers correlated with SLO windows |
| Cardinality enforcement | No (user responsibility) | No | Vendor-side | Hard constraint enforced by linting and doctor checks |
| Runbooks | No | No | No | Generated templates linked from SLO and alert definitions |
| `doctor` checks | No | No | No | mix parapet.doctor with CI gate |
| Host-owned infrastructure | Yes | Yes | No — vendor-hosted | Core principle: no phone-home, no vendor lock-in |
| Auth/login journey SLO | No | No | Partial | First-class Sigra integration |
| Evidence bundles for AI | No | No | Partial (Datadog MCP) | v0.2+ with approval-gated read-only tools |
| Wide events schema | No | No | Yes (Datadog events) | v0.1 schema design; emitted alongside metrics |

---

## Sources

- `prompts/sre-observability-elixir-lib-deep-reseach.md` — comprehensive Elixir ecosystem survey, persona analysis, competitive landscape, SLO design, footgun catalog
- `prompts/PARAPET-GSD-IDEA.md` — authoritative product thesis, non-goals, first milestone definition
- `prompts/parapet-integration-opportunities.md` — integration tiering (Sigra Tier 1, others Tier 2-3)
- `.planning/PROJECT.md` — active requirements, out-of-scope decisions, key architectural decisions
- Google SRE Book / SRE Workbook — burn-rate alerting, symptom-based alerting, postmortem culture (cited in sre-observability research)
- Sloth (sloth.dev) — SLO rule generator positioning: "generating Prometheus SLO rules is hard, error-prone, toil"
- Pyrra (github.com/pyrra-dev/pyrra) — SLO UI + rule generation pipeline pattern
- PromEx (hexdocs.pm/prom_ex) — strongest existing Elixir metrics/Grafana library; Parapet composes above it, not replaces it
- Prometheus docs (prometheus.io) — cardinality warnings, recording rule correctness (ratio aggregation)
- Honeycomb docs (docs.honeycomb.io) — high-cardinality in events vs metrics split

---
*Feature research for: Phoenix SaaS reliability layer (Parapet)*
*Researched: 2026-05-09*
