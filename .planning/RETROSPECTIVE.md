# Project Retrospective

## Cross-Milestone Trends

| Milestone | Ph / Pl | Days | LOC | Velocity |
|-----------|---------|------|-----|----------|
| v0.1 | 4 / 15 | 2 | 1992 | 15 plans / 2 days |
| v0.2 | 3 / 11 | 1 | 3164 | 11 plans / 1 day |
| v0.3 | 4 / 12 | 1 | 6667 | 12 plans / 1 day |
| v0.4 | 4 / 9 | 3 | 7847 | 9 plans / 3 days |
| v0.7 | 4 / 12 | 1 | 13401 | 12 plans / 1 day |
| v0.8 | 4 / 8 | 1 | ~13900 | 8 plans / 1 day |
| v0.9 | 14 / 36 | 5 | ~20274 | 36 plans / 5 days |
| v0.10 | 4 / 12 | 2 | ~21038 | 12 plans / 2 days (docs-heavy) |

## Milestone: v0.10 — Adopter Success

**Shipped:** 2026-05-24
**Phases:** 4 | **Plans:** 12

### What Was Built
A credibility-gate milestone that made the feature-complete v0.9 system adoptable by a stranger, with no new runtime deps, Ecto schemas, or Oban queues: populated hex.pm metadata + a Release-Please-owned `CHANGELOG.md`/retroactive `docs/HISTORY.md`; one-line `Parapet.SLO.StarterPack.WebSaaS`/`DeliverySaaS` packs (low-cardinality, low-traffic-safe, zero Generator changes); an end-to-end `warning:` runbook surface with four deepened + three new preview-first templates; and seven adoption guides (getting-started <30 min, troubleshooting, slo-authoring, four per-integration) backed by a uniform, crash-proof `Parapet.Integration` activation behaviour.

### What Worked
- **Code before docs, enforced by phase ordering:** Landing the SLO packs (Phase 16) and runbook templates (Phase 17) before the docs that name them (Phase 18) meant no guide ever referenced uncompilable code — the dominant milestone risk (drift) was structurally avoided.
- **Verifying the DSL surface before relying on it:** Treating `warning:` as a research flag and confirming Elixir was silently swallowing the unknown macro keyword arg *before* any template used it turned a latent no-op into a wired DSL→projection→UI surface with regression tests.
- **Advisor-mode gray-area research:** Resolving OQ-1 (Rulestead activation) to a code fix + compile-enforced `Parapet.Integration` behaviour — rather than shipping a doc that demonstrates a crashing call — came from researching the Elixir/OTel idiom up front.

### What Was Inefficient
- **First audit returned `tech_debt`, requiring a same-day closure pass:** Adopter-facing cross-reference drift (slo-reference omitted the new starter packs) and an inaccurate `Code.ensure_loaded?` detection claim in the integration guides slipped through phase verification and had to be reconciled before close.
- **Auto-extracted accomplishments were unusable:** The milestone CLI's SUMMARY-derived accomplishment list pulled raw header fragments ("dead_letter.ex.eex", "Wave 0 prerequisite files…"), requiring a full manual rewrite of the MILESTONES.md entry.

### Patterns Established
- **Behaviour-enforced uniform activation:** A `@behaviour` declared across all eight adapters makes `Parapet.attach(adapters: […])` uniform and crash-proof, so every integration guide can show the identical activation line.
- **Guidance-only runbooks where no safe capability fits:** `retry_storm`/`suppression_drift` stay advisory rather than executing mitigations that would worsen the failure — depth without overreach.
- **Honest cross-references as an audit target:** Doc-to-doc links (guide → reference catalog) are now an explicit audit check, since a broken cross-ref is invisible to compile/test gates.

### Key Lessons
- For a docs/adoption milestone, the real risk is *drift between docs and code*, not technical difficulty — order phases so code lands first, and audit cross-references as first-class, because no test catches a guide that links to a catalog missing its own entries.
- One-time release-mechanics pins (`release-as: "0.10.0"`) have a precise removal trigger (after the release PR merges and tags) — tie the removal to the tag, not to a phase number, or risk a wrong first-version computation.
- A keyword arg silently swallowed by an Elixir macro is invisible until something renders it — verify new DSL surfaces end-to-end before downstream content depends on them.

### Cost Observations
- Opus-driven planning + execution; small source footprint (~764 LOC change) but doc-heavy (~697 lines), so effort concentrated in authoring and cross-artifact coherence rather than implementation.
- Notable: the closure pass was cheap because the audit enumerated the exact gaps — the fixes were targeted doc edits plus one flaky-test repair, not rework.

## Milestone: v0.9 — Performance, Scale & DX

**Shipped:** 2026-05-23
**Phases:** 14 | **Plans:** 36

### What Was Built
Shifted from feature breadth to operational depth: TSDB cardinality protection (doctor sub-command + compile-time label ceiling), database scale (composite indexes + resolved-only archiver + `mix parapet.archive`), responsive Operator UI under 50k+ incidents, a unified `mix parapet.install` Day-1 orchestrator with multi-node doctor checks, and Ecto-backed multi-node safety (action claims + circuit breakers). Phases 6-14 closed verification gaps surfaced by the first audit.

### What Worked
- **Proactive safety as a gate, not a guideline:** Enforcing the label ceiling at compile-time (not just docs) made TSDB cardinality protection unbypassable for adopters.
- **Resolved-only retention as a hard contract:** Re-deriving the archive predicate around "never touch active work" and regression-testing every archive entry surface caught a real data-loss footgun before ship.
- **Closure-proof chain:** Building a proof that *fails* if the generated UI bypasses `Parapet.Operator.resolve_incident/2` turned a one-time bug fix (Phase 13) into a durable regression guard (Phase 14).

### What Was Inefficient
- **Audit-driven rework dominated the milestone:** 9 of 14 phases (6-14) were closure/reconciliation work triggered by the first audit's `gaps_found` result. The core five deliverables landed early; most calendar time went to making the proof surfaces honest and rerunnable.
- **Uncommitted working tree at close:** The audited implementation (validator, circuit breaker, claim service, concurrency harness — 55+ files) was left uncommitted by per-plan execution, requiring a reconciliation commit at milestone close before the tag could mean anything.
- **Two directory schemes:** v0.9 phases lived under both `.planning/v0.9-phases/` (numbered) and `.planning/phases/` (named), with leftover v0.6/v0.7 dirs contaminating prefixes — confusing `roadmap analyze` and the milestone tooling.

### Patterns Established
- **Closure phases as first-class:** Appending verification/reconciliation phases (6-14) with their own proof artifacts, rather than silently patching, keeps the milestone audit trail honest.
- **Environment-conditional proofs:** Multi-node canaries that skip cleanly (vs. fail hard) when distributed Erlang is absent keep the suite green across environment classes without lying about coverage.
- **Namespace carve-outs for non-shipped code:** Excluding `Parapet.TestSupport.*` from the public-API doc gate (alongside `Parapet.Internal.*`) so test helpers under the project namespace don't trip ship gates.

### Key Lessons
- A passing per-plan execution does not imply a committed working tree — verify `git status` is clean *before* tagging a milestone, or the tag is hollow.
- When an audit returns `gaps_found`, treat the closure phases as the real work: budget for the reconciliation, and make each gap produce a rerunnable proof so the next audit can't regress silently.
- Keep test-support modules either outside the product namespace or explicitly carved out of API gates; an accidental namespace choice can halt the entire suite via `System.halt`.

### Cost Observations
- Mostly Opus-driven planning + execution across closure phases; heavy reliance on goal-backward verification agents.
- Notable: the milestone's effort distribution inverted the usual ratio — implementation was fast, proof reconciliation was slow.

## Milestone: v0.8 — Deterministic Escalation & Bounded Mitigation

**Shipped:** 2026-05-19
**Phases:** 4 | **Plans:** 8

### What Was Built
Built a durable Oban-backed escalation engine, implemented system-identity execution for bounded runbooks, added Ecto-backed circuit breakers to prevent flap-loop mitigations, and extended the Operator UI to visualize escalation chains.

### What Worked
- **System Identity:** Utilizing a strict URN identity (`system:automation:executor`) for auto-mitigations made it trivial to separate human vs. system actions in the Operator UI.
- **Circuit Breakers via Evidence:** Querying the `ToolAudit` log to determine flap-loops was extremely effective and avoided adding new persistence tables for breaker state.

### What Was Inefficient
- N/A - Test-driven development ensured a smooth implementation path.

### Patterns Established
- **Bounded Auto-Execution:** Strictly requiring `auto_execute: true` in the DSL and executing via Oban jobs to avoid blocking alert ingestion.
- **Escalation Short-Circuiting:** Safely cancelling pending escalations when incidents are acknowledged or resolved.

### Key Lessons
- Providing deterministic auto-mitigation using existing primitives (Oban, Ecto) proves that an SRE platform can be self-healing without relying on autonomous AI agents.

## Milestone: v0.7 — Async & Delivery Reliability

**Shipped:** 2026-05-18
**Phases:** 4 | **Plans:** 12

### What Was Built
Implemented out-of-the-box SLIs for async pipeline health and provider delivery states (Chimeway, Mailglass, Rindle), added explicit fault-domain triage enrichment leveraging durable evidence, and introduced safe, host-wired recovery runbook templates for stalled async work.

### What Worked
- **Provider-First SLOs:** Extending the metrics layer to directly model provider states (like MailglassDelivery or RindleAsync) simplified creating actionable SLIs.
- **Evidence-Backed Triage:** Shifting triage classification from UI heuristics down to durable Ecto snapshot evidence ensures accuracy.

### What Was Inefficient
- Integrating across varying third-party service semantics required careful modeling of states to ensure low cardinality without losing fidelity.

### Patterns Established
- **Bounded SliceSpec Seam:** Providing a narrow surface to define provider-specific delivery slices.
- **Host-Owned Modules:** Utilizing generators to copy fixed template runbooks rather than inventing dynamic workflow DSLs.

### Key Lessons
- Providing exact recovery guidance requires distinguishing webhook/callback drift from internal queue backlogs or provider outages.

## Milestone: v0.4 — Scoria AI Integration

**Shipped:** 2026-05-15
**Phases:** 4 | **Plans:** 9

### What Was Built
Implemented AI telemetry translation, eval-driven SLOs, deploy correlation for AI configs, and workflow approval pauses as durable HITL states.

### What Worked
- **Strict Cardinality Control:** The `Parapet.Metrics.Scoria` translation layer successfully protected the TSDB from high-cardinality AI refs.
- **Data-First Providers:** Moving the SLO registry to a `Provider` behaviour enabled compile-time validation.

### What Was Inefficient
- Minimal friction encountered; test-driven approach ensured smooth implementation.

### Patterns Established
- **Dual-Track Telemetry:** Using Prometheus for systemic alerting and Ecto for 100% reliable deep links for workflow pauses.
- **Telemetry for UX, Adapter for Truth:** Using adapter polling as a cache-invalidation hint to prevent state drift.

### Key Lessons
- Alerting on low-volume AI endpoints requires multi-burn-rate PromQL to avoid false positives.
- Decoupling UI URLs from the routing layer via configurable MFA keeps the library pure.

## Milestone: v0.3 — Runbooks & Alert Routing

**Shipped:** 2026-05-12
**Phases:** 4 | **Plans:** 12

### What Was Built
Implemented webhook receiver for Prometheus Alertmanager, structured Runbook DSL, and modular Notifier system for Slack/Teams.

### What Worked
- Leveraging existing Ecto `Incident` schema for Alertmanager correlation simplified the state machine.

### What Was Inefficient
- Parsing external JSON payloads reliably required strict schema validation.

### Patterns Established
- One-click mitigations securely audited via the `ToolAudit` Ecto schema.

### Key Lessons
- Operator UI requires interactive state to display attached runbooks efficiently.

## Milestone: v0.2 — Durable Spine and Operator UI

**Shipped:** 2026-05-11
**Phases:** 3 | **Plans:** 11

### What Was Built
Established the durable Ecto spine (Incidents, Timeline, Tool Audits), generated an isolated Phoenix LiveView Operator SRE workbench, and integrated sibling libraries like Sigra, Rulestead, and Mailglass via optional capability adapters.

### What Worked
- **Decoupled Persistence:** Using `Application.get_env` for dynamic repo lookup enabled seamless host integration without coupling Parapet to a specific DB.
- **Static UI Verification:** Moving UI layout checks from manual human tasks to automated static Tailwind class assertions drastically improved cycle time.
- **Compile-time Adapters:** Utilizing `Code.ensure_loaded?` allowed us to add 6 sibling integrations without adding a single runtime dependency.

### What Was Inefficient
- **Test Context Leaks:** Had to manually intervene during telemetry testing because of leftover global state/crashes in `ThreadlineTest`.

### Patterns Established
- Generating LiveView templates into the host application rather than shipping them as pre-compiled modules to maintain host ownership.
- Validating visual contracts (like 3-pane layouts) via string matching in tests to avoid the weight of E2E browser automation.

### Key Lessons
- Ecto schemas can be successfully tested purely on their changesets without needing a Repo, which is crucial for library distribution.
- Automated structural testing of templates is a powerful "shift-left" technique that completely eliminated manual UI verification bottlenecks.

## Milestone: v0.1 — Trustworthy Spine

**Shipped:** 2026-05-10
**Phases:** 4 | **Plans:** 15

### What Was Built
Successfully implemented the core telemetry framework, metric collectors, SLO generators, and developer experience tools (doctor checks and dashboard generation) to enable the "Zero to First Alert" workflow.

### What Worked
- **Strict safety rails out of the box:** Forcing a hardcoded label policy regex and telemetry-first approach allowed us to guarantee safety.
- **Generator vs Runtime balance:** Distributing the integration scaffolding (`Parapet.Instrumenter`) vs runtime metrics plugins provided the flexibility expected by Phoenix teams.
- **Test Driven & Clear Phasing:** Breaking the work down vertically (Foundation → Metrics → SLO → DX) made progress verifiable and predictable at every step.

### What Was Inefficient
- **Verification Setup:** Setting up manual verification for Grafana/Prometheus was complex and required human intervention. 
- **Tooling Friction:** Encountered parsing limits with AST manipulation during DX phases (specifically handling function pipes in `mix parapet.doctor`), which required fallback static analysis.

### Patterns Established
- Telemetry-first contract definition before database persistence schemas.
- Using `Igniter` for deterministic codebase modifications inside Mix tasks.
- Abstracting complex configuration (like PromQL rules) into Elixir structs evaluated into EEx templates.

### Key Lessons
- Providing explicit configuration options early isn't always the best path; rigid safety boundaries (like hardcoded label regex) build more trust in a new SRE tool.
- Verifying artifacts that live outside the runtime (e.g. Grafana dashboards and YAML rules) requires robust programmatic checks (`promtool`) but ultimately still needs human eyes.
