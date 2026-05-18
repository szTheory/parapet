# Phase 4: Async & Delivery Telemetry Contracts - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the normalized async and delivery telemetry contract for `Mailglass`, `Chimeway`, and `Rindle` so downstream phases can build metrics, SLOs, incident enrichment, and runbooks on a stable, low-cardinality public vocabulary.

This phase is about the contract and adapter seam only. It does **not** freeze built-in SLO catalogs, incident enrichment payloads, durable action-item semantics, or recovery UX. Those belong to later phases once the contract has been proven.

</domain>

<decisions>
## Implementation Decisions

### Public contract shape
- **D-01:** Replace the current thin `[:parapet, :journey, ...]` shim approach with a dedicated async/delivery contract. Do not keep Phase 4 on the generic journey namespace as the long-term public API.
- **D-02:** Use a **small bounded event family** rather than one fully generic event and rather than provider-specific public event trees.
- **D-03:** The recommended public event families are:
  - `[:parapet, :delivery, :outbound]`
  - `[:parapet, :delivery, :provider_feedback]`
  - `[:parapet, :delivery, :webhook_ingest]`
  - `[:parapet, :async, :stage]`
  - `[:parapet, :async, :backlog]`
  - `[:parapet, :async, :callback]`
- **D-04:** Use event names to express the lifecycle seam and use metadata to express bounded fault-domain and outcome details. Do not encode every nuance into the event name.
- **D-05:** Keep adapter-specific telemetry shapes internal. Public telemetry must be normalized across sibling integrations.

### Outcome vocabulary
- **D-06:** Use **capability-tiered normalization**, not one universal cross-adapter state machine and not coarse `success` / `failure`.
- **D-07:** Delivery outcomes should use a bounded shared vocabulary:
  - core: `attempted`, `provider_accepted`, `delivered`, `failed`
  - extensions where supported: `bounced`, `complained`, `suppressed`
- **D-08:** Async outcomes should use a bounded shared vocabulary:
  - `started`, `succeeded`, `retryable_failed`, `discarded`, `delayed`
- **D-09:** `provider_accepted` must remain distinct from `delivered`. Do not collapse callback-confirmed delivery into acceptance.
- **D-10:** `retryable_failed` must remain distinct from `discarded` or exhausted work. Normal retries are not user-harming incidents by default.

### Fault-plane separation
- **D-11:** Adopt a **mixed model**: lifecycle in event name, fault plane in metadata.
- **D-12:** Keep the fault-plane taxonomy intentionally small and stable:
  - `provider`
  - `webhook`
  - `suppression`
  - `worker`
  - `backlog`
- **D-13:** Distinguish callback or reconciliation delay from internal backlog. Do not treat webhook silence as generic delivery failure.
- **D-14:** Suppression drift is its own plane. Do not collapse it into provider failure or ordinary bounce/failure handling.
- **D-15:** The contract should make it easy for later phases to classify “what plane is unhealthy?” without forcing the UI to reverse-engineer root cause heuristically.

### Metadata and label policy
- **D-16:** Move from the current denylist-style safety posture to an **allowlisted normalized schema** for Phase 4 public telemetry.
- **D-17:** Public top-level metadata must contain only documented bounded fields. Arbitrary pass-through adapter metadata is not part of the public contract.
- **D-18:** Recommended safe top-level bounded fields are:
  - `integration`
  - `provider`
  - `channel`
  - `queue`
  - `pipeline_stage`
  - `outcome`
  - `failure_class`
  - `delay_bucket`
  - `retry_state`
  - `fault_plane`
- **D-19:** `queue` is only label-safe when queue names are finite and documented. If a host derives queue names from tenant or user data, treat queue identity as a ref instead.
- **D-20:** Keep high-cardinality values under `metadata.refs`, using `_ref` suffixes instead of `_id` to make them visibly non-label-safe.
- **D-21:** Recommended ref-style keys include:
  - `message_ref`
  - `delivery_ref`
  - `job_ref`
  - `attempt_ref`
  - `webhook_ref`
  - `provider_request_ref`
  - `provider_message_ref`
  - `trace_ref`
  - `run_ref`
  - `incident_ref`
  - `tenant_ref`
  - `recipient_ref`
- **D-22:** Exact identifiers belong in wide evidence or later durable follow-up artifacts, not in Prometheus tags or incident summary labels.

### Measurements and telemetry style
- **D-23:** Keep measurements numeric and small. Phase 4 should standardize on `count` and optional timing measurements such as `duration_ms` and `delay_ms`.
- **D-24:** Bucket delay for metrics and alerting. Never use raw `delay_ms` values as label dimensions.
- **D-25:** Where upstream operations have meaningful timing boundaries, prefer idiomatic `:telemetry.span/3` or equivalent start/stop/exception semantics behind the adapter seam.
- **D-26:** Use `:telemetry.attach_many/4` for related integration families rather than many fragmented handlers.
- **D-27:** Treat handler crash safety as part of the contract quality bar. Handler detachment must be considered a real observability failure mode.

### Phase boundary discipline
- **D-28:** Freeze the public async/delivery vocabulary, bounded metadata/tag keys, adapter behavior shape, and attachment/compile-out rules in Phase 4.
- **D-29:** Defer concrete built-in SLO families and generated alert semantics to Phase 5.
- **D-30:** Defer incident enrichment schema, durable follow-up item policy, and operator-facing fault summaries to Phase 6.
- **D-31:** Defer recovery commands, runbook action contracts, and retry/replay UX to Phase 7.
- **D-32:** Phase 4 should optimize for a stable mental model for adopters and downstream agents, not for immediate end-to-end product completeness.

### Developer ergonomics and least surprise
- **D-33:** Keep the public namespace narrow and explicit. Prefer a small set of clearly documented event families over hidden magic or adapter auto-discovery.
- **D-34:** Preserve the existing host-owned activation model: integrations remain explicit, optional, and compile out cleanly.
- **D-35:** Document one blessed adoption path first: enable adapter, emit normalized events, run doctor/verification, then move into SLO and incident features in later phases.
- **D-36:** Default future GSD work to make coherent recommendations and only escalate genuinely high-impact ambiguities. Routine contract details should be resolved agent-side where the repo doctrine already points clearly.

### the agent's Discretion
- **D-37:** Exact module names for internal translator helpers and behaviours, as long as the public contract above stays stable and narrow.
- **D-38:** Whether to provide a short compatibility bridge from current `:journey` events during migration, as long as the new Phase 4 contract is the documented forward path.
- **D-39:** Exact delay bucket cut points and exact `failure_class` enum members, as long as they remain small, bounded, and consistent with the above taxonomy.

</decisions>

<specifics>
## Specific Ideas

- Favor a contract that reads like a good Elixir telemetry library, not a vendor event dump.
- Separate:
  - lifecycle stage
  - terminal outcome
  - fault plane
  - exact identifiers
- Borrow the best parts of Oban’s operational vocabulary: `retryable` and `discarded` are materially different.
- Borrow the best parts of email/provider systems like SES/SendGrid/Twilio: acceptance is not delivery, and webhook/callback state matters.
- Keep “wide evidence elsewhere” as the answer to fidelity pressure instead of stuffing identifiers into metric labels.
- The ideal adopter experience is: “I understand what happened from the event names and bounded fields without reading vendor-specific payload lore.”

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — active v0.7 roadmap and Phase 4 scope boundary
- `.planning/REQUIREMENTS.md` — `DELV-01` and `TRIAGE-01`, plus adjacent async/delivery requirements that constrain the contract
- `.planning/PROJECT.md` — product thesis, low-cardinality discipline, compile-out constraints, and milestone intent
- `.planning/STATE.md` — current project status and recent locked decisions

### Existing research for v0.7
- `.planning/research/SUMMARY.md` — recommended milestone arc and contract-first sequencing
- `.planning/research/ARCHITECTURE.md` — normalized async/delivery event-layer guidance
- `.planning/research/FEATURES.md` — operator expectations and async/delivery feature framing
- `.planning/research/PITFALLS.md` — failure modes and anti-patterns for this milestone
- `.planning/research/STACK.md` — dependency and internal component guidance for v0.7
- `.planning/research/PHASE-1-SRE-TELEMETRY.md` — prior signal-vs-evidence architecture decision that should carry forward
- `.planning/research/PHASE-3-INTEGRATIONS.md` — explicit adapter activation and compile-out posture

### Existing code and current baseline
- `lib/parapet/integrations/mailglass.ex` — current overly-thin Mailglass adapter baseline
- `lib/parapet/integrations/chimeway.ex` — current overly-thin Chimeway adapter baseline
- `lib/parapet/integrations/rindle.ex` — current overly-thin Rindle adapter baseline
- `lib/parapet/internal/label_policy.ex` — existing denylist-based label safety baseline to tighten
- `lib/parapet/spine/alert_processor.ex` — downstream incident seam that later phases will consume
- `lib/parapet/metrics/scoria.ex` — existing example of bounded telemetry translation discipline
- `test/parapet/integrations/mailglass_test.exs` — current adapter test expectations
- `test/parapet/integrations/chimeway_test.exs` — current adapter test expectations
- `test/parapet/integrations/rindle_test.exs` — current adapter test expectations
- `test/parapet/internal/label_policy_test.exs` — current label-safety test posture

### Product doctrine and prior art
- `prompts/PARAPET-GSD-IDEA.md` — product thesis and operator-grade reliability stance
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — inherited OSS and DX defaults
- `prompts/parapet-integration-opportunities.md` — sibling-library seam framing for Mailglass, Chimeway, and Rindle
- `prompts/elixir-telemetry-space-deep-research.md` — telemetry and metrics ecosystem guidance
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — SRE and observability product guidance
- `prompts/prior-art/SOURCE-CANONICAL.md` — prior-art index
- `prompts/prior-art/chimeway-host-app-integration-seam.md` — host-owned integration boundary
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — telemetry-as-API and redaction discipline
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` — capture vs semantics vs evidence separation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.attach/1` already establishes the explicit adapter activation model and should remain the top-level opt-in seam.
- `Parapet.Metrics.Scoria` already demonstrates the right posture for bounded translation from rich upstream telemetry into safe metrics signals.
- `Parapet.Spine.AlertProcessor` is the correct downstream incident entry point later phases should reuse rather than bypass.

### Established Patterns
- The repo already treats telemetry as API and protects against cardinality blowups.
- Optional integrations already follow compile-out discipline and explicit host activation.
- The project already distinguishes telemetry from durable evidence and wants to keep that split intact.

### Integration Points
- `Mailglass`, `Chimeway`, and `Rindle` adapters should normalize upstream events into the new bounded Phase 4 contract.
- Metrics, SLO, alert, and incident work in later phases should consume the normalized contract rather than each sibling library directly.
- Label policy and metrics registration code will need to evolve from generic denylist checks toward event-family allowlists.

</code_context>

<deferred>
## Deferred Ideas

- Publishing concrete built-in SLO module names or alert rule families in Phase 4.
- Freezing durable incident enrichment payload structure before Phase 6.
- Defining recovery action payloads, retry/replay APIs, or runbook command contracts before Phase 7.
- Broad autonomous or semi-autonomous remediation behavior.
- Provider-console-style message forensics or high-cardinality per-message observability.

</deferred>

---

*Phase: 4-async-and-delivery-telemetry-contracts*
*Context gathered: 2026-05-17*
