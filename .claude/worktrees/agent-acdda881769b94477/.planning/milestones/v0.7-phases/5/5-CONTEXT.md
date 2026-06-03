# Phase 5: Built-In Async & Delivery SLOs - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the Phase 4 async and delivery telemetry contract into built-in reliability slices, low-cardinality metrics, provider-backed SLO modules, and generated Prometheus alert artifacts for `Mailglass`, `Chimeway`, and `Rindle`.

This phase is about productized detection defaults and alert semantics. It does **not** finalize incident enrichment payloads, operator UI classification, durable action-item policies, or recovery actions. Those remain Phase 6 and Phase 7 work.

</domain>

<decisions>
## Implementation Decisions

### Product shape
- **D-01:** Phase 5 should be moderately opinionated: ship strong built-ins, explicit opt-in seams, and host-owned generated artifacts.
- **D-02:** Do **not** ship Phase 5 as thin primitives only. The library should provide a paved road, not just ingredients.
- **D-03:** Do **not** auto-discover or auto-enable async/delivery SLOs or alerts. Explicit host registration remains the default.
- **D-04:** Preserve the existing host-owned activation model:
  - adapters are attached explicitly;
  - providers are registered explicitly;
  - generated artifacts stay inspectable and editable in the host app.

### Built-in slice catalog
- **D-05:** Ship one explicit provider module per integration, not one broad generic delivery provider and not a maximal state-by-state matrix.
- **D-06:** The built-in provider modules for Phase 5 should be:
  - `Parapet.SLO.MailglassDelivery`
  - `Parapet.SLO.ChimewayDelivery`
  - `Parapet.SLO.RindleAsync`
- **D-07:** Each provider should expose a **small catalog** of built-in slices so the surface feels complete without becoming a provider-console clone.

### Mailglass slices
- **D-08:** `Mailglass` should ship these default slices:
  - `mailglass_submit_acceptance` — `provider_accepted / attempted`
  - `mailglass_confirmed_delivery` — `delivered / provider_accepted` when provider feedback exists
  - `mailglass_webhook_freshness` — webhook/callback delay slice
  - `mailglass_suppression_drift` — diagnostic alert slice, not a paging-budget SLO
- **D-09:** `provider_accepted` must remain distinct from `delivered`. Delivery confirmation is not the same as upstream acceptance.

### Chimeway slices
- **D-10:** `Chimeway` should ship these default slices:
  - `chimeway_provider_acceptance` — `provider_accepted / attempted`
  - `chimeway_callback_confirmation` — confirmed delivered vs confirmed failed
  - `chimeway_callback_freshness` — callback delay slice
- **D-11:** Chimeway should stay aligned with the currently proven upstream surface in this repo. Do not invent unsupported richer public semantics only to make the catalog look symmetric.

### Rindle slices
- **D-12:** `Rindle` should ship these default slices:
  - `rindle_terminal_success` — `succeeded / (succeeded + discarded)`
  - `rindle_queue_freshness` — queue age/latency slice
  - `rindle_callback_freshness` — external callback or reconciliation delay slice
  - `rindle_long_running_stage` — diagnostic alert slice by `pipeline_stage`, not a default paging SLO
  - `rindle_funnel_regression` — diagnostic recording or alert slice using stage counts, not a default page
- **D-13:** `retryable_failed` is not a paging symptom by default. Treat it as noise unless paired with sustained backlog or callback burn.
- **D-14:** `discarded` is the terminal, user-harming async failure state for default alerting purposes.
- **D-15:** Queue freshness should be based on delay or age, not raw depth alone. Raw depth may be recorded, but it is not the primary operator signal.

### Alert semantics
- **D-16:** Use a plane-specific, terminality-aware alert taxonomy rather than a generic burn-rate-only model.
- **D-17:** Page on user-harming or terminal symptoms:
  - `discarded` async work burn
  - sustained delivery failure that impacts the user-facing slice
  - sustained callback/webhook delay beyond tolerated freshness
  - sustained queue freshness burn that indicates real backlog harm
- **D-18:** Ticket on sustained but not yet urgent degradation:
  - suppression drift
  - provider acceptance shortfall
  - callback delay that is degrading but not yet clearly user-harming
  - backlog growth that is notable but not yet page-worthy
- **D-19:** Keep normal retries and single transient provider failures at warning or muted-by-default severity. They should not page humans by default.
- **D-20:** Generated alerts should group on bounded operator labels such as:
  - `alertname`
  - `integration`
  - `fault_plane`
  - coarse `queue`, `channel`, or `pipeline_stage` when relevant
- **D-21:** Phase 5 generated alerts should assume Alertmanager-style inhibition and grouping:
  - symptom pages suppress lower-level cause alerts
  - warning does not route like page
- **D-22:** Add `for` durations and minimum-volume guards to generated alerts so transient spikes and low-volume noise do not create false pages.

### API and artifact shape
- **D-23:** Keep `Parapet.attach(adapters: [...])` as the integration activation seam. Do not overload attachment with silent SLO activation.
- **D-24:** Register built-in SLO providers explicitly through configuration, for example:
  - `config :parapet, providers: [...]`
- **D-25:** Prefer provider modules and behaviour callbacks over legacy `register/1` mutation APIs as the long-term Phase 5 direction.
- **D-26:** Split responsibilities clearly:
  - integration adapters normalize bounded telemetry events;
  - metrics modules define Telemetry metrics and selectors;
  - provider modules declare built-in slices and alert metadata;
  - generators render host-owned Prometheus artifacts.
- **D-27:** `mix parapet.gen.prometheus` should generate artifacts from active providers only.
- **D-28:** Prefer separate host-owned artifact files for recording rules and alerts over one opaque mixed output if the implementation cost is reasonable.
- **D-29:** Built-ins may use an internal bounded slice spec rather than raw arbitrary PromQL everywhere. The generator should own most of the PromQL shape for shipped defaults.
- **D-30:** Keep one escape hatch for advanced custom providers, but do not optimize the default API around arbitrary raw PromQL strings.

### Metrics and label policy
- **D-31:** Continue treating metrics safety as a non-negotiable. New Phase 5 metrics must preserve the low-cardinality contract from Phase 4.
- **D-32:** Do not emit `message_id`, `job_id`, `recipient`, `webhook_id`, provider request IDs, or similar exact identifiers into labels.
- **D-33:** Prefer Prometheus-native naming and units for new metrics:
  - counters end in `_total`
  - durations should move toward base-unit `_seconds`
  - ratios should stay interpretable as `0..1`
- **D-34:** Shared label shapes across provider modules matter for coherent generated artifacts and least-surprise DX.

### GSD decision policy
- **D-35:** Shift routine implementation decisions left within GSD for this phase and later related work. Downstream agents should make coherent recommendations by default instead of escalating every gray area.
- **D-36:** Only escalate decisions that have real product, operator, or API blast radius:
  - public API naming that is hard to change
  - materially different operator alert semantics
  - changes that threaten low-cardinality or host-owned design constraints
  - anything that meaningfully broadens or narrows scope
- **D-37:** For ordinary implementation details, the preferred default is:
  - follow repo patterns;
  - preserve least surprise;
  - prefer explicit over magical;
  - optimize for operator-grade DX.

### the agent's Discretion
- **D-38:** Exact internal module names for metrics helpers, slice structs, template helpers, and provider plumbing.
- **D-39:** Exact `for` durations, burn windows, and traffic gates, as long as they follow the symptom-first and retry-aware rules above.
- **D-40:** Whether Phase 5 keeps short-term compatibility with legacy registration helpers while moving the blessed path to provider modules.
- **D-41:** Exact Prometheus file split and template layout, as long as generated artifacts stay host-owned and inspectable.

</decisions>

<specifics>
## Specific Ideas

- “Page on user harm” is the governing principle for this phase, not generic async noise.
- Keep the mental model clean:
  - provider acceptance is not confirmed delivery;
  - callback delay is not queue backlog;
  - retryable failure is not discarded work;
  - suppression drift is not the same as provider outage.
- Parapet should learn from queue systems that separate retries from dead work and from observability systems that distinguish symptom alerts from cause signals.
- The desired adopter experience is:
  - explicit enablement;
  - useful defaults on day 1;
  - generated files they can inspect and edit;
  - no hidden alert policy magic.
- The desired GSD experience is:
  - default to coherent recommendations;
  - only ask the user when the decision has high leverage or long-term surface-area consequences.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked upstream decisions
- `.planning/ROADMAP.md` — active v0.7 roadmap and Phase 5 scope boundary
- `.planning/REQUIREMENTS.md` — `DELV-02`, `DELV-03`, `ASYNC-01`, `ASYNC-02`, `ASYNC-03`
- `.planning/PROJECT.md` — product thesis, host-owned stance, low-cardinality doctrine
- `.planning/STATE.md` — current project position
- `.planning/v0.7-phases/4/4-CONTEXT.md` — locked Phase 4 async/delivery contract and taxonomy

### Existing milestone research
- `.planning/research/SUMMARY.md` — milestone arc and build-order guidance
- `.planning/research/ARCHITECTURE.md` — normalized event layer and evidence split guidance
- `.planning/research/PHASE-3-INTEGRATIONS.md` — explicit activation and host-owned integration posture

### Product and engineering doctrine
- `prompts/PARAPET-GSD-IDEA.md` — product principles, especially page-on-user-harm and host ownership
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — explicit seams, telemetry-as-API, doctor/diagnostics posture
- `prompts/parapet-integration-opportunities.md` — integration-specific operator goals for Mailglass, Chimeway, and Rindle
- `prompts/elixir-telemetry-space-deep-research.md` — ecosystem gaps, SLO generation guidance, cardinality discipline
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — observability-stack and DX guidance
- `prompts/sre-best-practices-solo-founder-deep-research.md` — solo-operator alerting and human-noise constraints

### Existing code and artifact baseline
- `docs/telemetry.md` — public async/delivery event families and semantics
- `docs/slo-reference.md` — current SLO and generated alert posture
- `lib/parapet/telemetry/async_delivery.ex` — normalized event families and bounded metadata
- `lib/parapet/integrations/mailglass.ex` — current Mailglass normalization seam
- `lib/parapet/integrations/chimeway.ex` — current Chimeway normalization seam
- `lib/parapet/integrations/rindle.ex` — current Rindle normalization seam
- `lib/parapet.ex` — explicit adapter activation contract
- `lib/parapet/slo.ex` — current SLO registry and provider aggregation seam
- `lib/parapet/slo/provider.ex` — provider behaviour
- `lib/parapet/slo/http.ex` — legacy built-in registration baseline
- `lib/parapet/slo/login_journey.ex` — legacy built-in registration baseline
- `lib/parapet/slo/oban.ex` — legacy built-in registration baseline
- `lib/mix/tasks/parapet.gen.prometheus.ex` — current generated Prometheus artifact task
- `lib/parapet/slo/generator.ex` — current low-level YAML generation baseline
- `priv/templates/parapet.gen.prometheus/rules.yml.eex` — current alert/rule template

### Phase 5 implementation and verification baseline
- `test/parapet/integrations/mailglass_test.exs` — current Mailglass contract tests
- `test/parapet/integrations/chimeway_test.exs` — current Chimeway contract tests
- `test/parapet/integrations/rindle_test.exs` — current Rindle contract tests
- `test/mix/tasks/parapet.gen.prometheus_test.exs` — current generator expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.attach/1` already provides the explicit, least-surprise activation seam and should remain the top-level integration switch.
- `Parapet.SLO.Provider` already gives a better long-term registration model than mutating app env through legacy `register/1` helpers.
- `Parapet.Telemetry.AsyncDelivery` already codifies the distinctions Phase 5 needs:
  - `provider_accepted` vs `delivered`
  - `retryable_failed` vs `discarded`
  - `backlog` vs `callback`
  - `provider` vs `suppression` vs `webhook`
- The existing Prometheus generator and templates provide a host-owned artifact path that Phase 5 should extend rather than replace.

### Established Patterns
- Optional integrations remain explicit and compile out cleanly.
- Telemetry is treated as public API and labels are aggressively bounded.
- The project consistently prefers generated or inspectable host-owned assets over hidden runtime magic.
- Prior phases already favor productized defaults over raw vendor primitives when the paved road is honest.

### Integration Points
- New metrics modules should consume the normalized Phase 4 async/delivery events rather than sibling-library raw telemetry directly.
- New provider modules should aggregate through the existing `:providers` seam in `Parapet.SLO.all/0`.
- Generated alerting artifacts should evolve from today’s generic ratio-only output into slice-aware symptom and diagnostic rule sets.
- Phase 6 should consume the same slice taxonomy and alert labels rather than reverse-engineering classification in the UI.

</code_context>

<deferred>
## Deferred Ideas

- Auto-discovered provider registration or hidden auto-enabled alerts.
- Provider-console-style exhaustive state matrices and forensic dashboards.
- Exact-item alerting as a primary Phase 5 model rather than a later durable evidence or action-item concern.
- Final incident enrichment schema and operator workbench classification details — Phase 6.
- Recovery actions, retries, replay UX, and runbook command contracts — Phase 7.
- Broad autonomous remediation or opaque operational magic.

</deferred>

---

*Phase: 5-built-in-async-and-delivery-slos*
*Context gathered: 2026-05-17*
