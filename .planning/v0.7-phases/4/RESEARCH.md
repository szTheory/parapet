# Phase 4: Async & Delivery Telemetry Contracts - Research

**Researched:** 2026-05-17
**Domain:** Elixir telemetry contract normalization for optional async and delivery adapters
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Publishing concrete built-in SLO module names or alert rule families in Phase 4.
- Freezing durable incident enrichment payload structure before Phase 6.
- Defining recovery action payloads, retry/replay APIs, or runbook command contracts before Phase 7.
- Broad autonomous or semi-autonomous remediation behavior.
- Provider-console-style message forensics or high-cardinality per-message observability.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DELV-01 | System distinguishes `attempted`, `provider_accepted`, `delivered`, `failed`, `bounced`, `complained`, and `suppressed` delivery outcomes where the sibling integration exposes those states. | `## Summary`, `## Standard Stack`, `## Architecture Patterns`, `## Common Pitfalls` |
| TRIAGE-01 | System normalizes async and delivery telemetry into bounded fault-domain metadata such as `provider`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, and coarse delay buckets without leaking high-cardinality identifiers into metrics labels. | `## Summary`, `## Architecture Patterns`, `## Don't Hand-Roll`, `## Security Domain` |
</phase_requirements>

## Summary

Phase 4 should change the existing adapter seam, not the broader product architecture, because the repo already centralizes optional integration activation in [`lib/parapet.ex`](/Users/jon/projects/parapet/lib/parapet.ex), already treats telemetry as the public integration boundary, and already keeps label safety in one place with [`lib/parapet/internal/label_policy.ex`](/Users/jon/projects/parapet/lib/parapet/internal/label_policy.ex). [VERIFIED: codebase grep]

The actual baseline is still thin: `Mailglass` maps one failure event into `[:parapet, :journey, :mail_delivery]`, `Chimeway` does the same for one failed event, and `Rindle` maps two media events into `[:parapet, :journey, :media]`; none of those adapters currently expose bounded async or delivery fault-plane metadata, and the label policy is still regex-denylist based rather than schema-allowlist based. [VERIFIED: codebase grep]

Official Telemetry docs confirm three design constraints the planner should treat as hard requirements: `attach_many/4` is the intended API for related event families, `span/3` is the idiomatic way to model start/stop/exception timing boundaries, and handlers that fail are detached from the event manager. [CITED: https://hexdocs.pm/telemetry/telemetry.html] Official Oban lifecycle docs also preserve the distinction between retryable work and discarded work, which matches the locked Phase 4 outcome vocabulary. [CITED: https://hexdocs.pm/oban/job_lifecycle.html]

**Primary recommendation:** keep Phase 4 dependency-neutral and implement it as a bounded public contract layer across the three existing adapters, a new allowlisted metadata policy, and a safer multi-event attachment path that preserves compile-out behavior. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/telemetry/telemetry.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public async/delivery event vocabulary | API / Backend | — | Adapter modules under `lib/parapet/integrations/` emit Telemetry from library code, so the contract belongs in the backend/library layer rather than UI or storage. [VERIFIED: codebase grep] |
| Adapter-specific upstream event translation | API / Backend | — | `Mailglass`, `Chimeway`, and `Rindle` are integration modules that already consume sibling Telemetry and re-emit Parapet events. [VERIFIED: codebase grep] |
| Metadata allowlisting and ref demotion | API / Backend | Database / Storage | Top-level metadata safety must be enforced at emission time, while exact refs belong in evidence later rather than in metric tags. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html] |
| Retry/discarded semantic normalization | API / Backend | Database / Storage | Oban is the repo’s existing async lifecycle reference point, and its lifecycle vocabulary is a backend concern before any alert or UI layer consumes it. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Compile-out adapter activation | API / Backend | — | `Parapet.attach(adapters: ...)` already uses explicit module loading with `Code.ensure_loaded?/1`, so optionality is owned by library boot code. [VERIFIED: codebase grep] |
| Incident enrichment and runbook actions | API / Backend | Frontend Server (SSR) | Later phases consume the contract through `AlertProcessor` and operator surfaces, but Phase 4 only needs to leave them a stable API. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | `1.4.1` in repo; `1.4.2` current on Hex as of 2026-05-17. [VERIFIED: mix.lock][CITED: https://hex.pm/packages/telemetry/versions] | Event attachment, `attach_many/4`, and `span/3` semantics. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | Phase 4 is fundamentally a Telemetry contract change, and the repo already uses Telemetry as the integration boundary. [VERIFIED: codebase grep] |
| `:telemetry_metrics` | `1.1.0` in repo and current on Hex as of 2026-05-17. [VERIFIED: mix.lock][CITED: https://hex.pm/packages/telemetry_metrics/versions] | Defines safe tag extraction rules that later phases will consume. [CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html] | The repo already defines metrics through `Telemetry.Metrics` modules, so Phase 4 should preserve that path rather than introducing another metrics abstraction. [VERIFIED: codebase grep] |
| `:oban` | `2.22.1` in repo and current on Hex as of 2026-05-17. [VERIFIED: mix.lock][CITED: https://hex.pm/packages/oban/versions] | Canonical async lifecycle semantics for `retryable`, `discarded`, `completed`, and queue-backed work. [CITED: https://hexdocs.pm/oban/job_lifecycle.html] | `Parapet.Metrics.Oban` is already present and the phase’s async vocabulary intentionally matches Oban lifecycle concepts. [VERIFIED: codebase grep] |
| Elixir / Mix | `1.19.5` / `1.19.5` locally. [VERIFIED: local command] | Local test and compilation environment for the phase. [VERIFIED: local command] | The planner can assume current local execution uses Elixir 1.19 on OTP 28. [VERIFIED: local command] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Parapet.Internal.SafeHandler` | In-repo helper. [VERIFIED: codebase grep] | Existing crash-catching wrapper around `:telemetry.attach/4`. [VERIFIED: codebase grep] | Reuse or extend it when Phase 4 centralizes multi-event attachment safety; do not duplicate rescue blocks across more handlers without a reason. [VERIFIED: codebase grep] |
| `Parapet.Internal.LabelPolicy` | In-repo helper. [VERIFIED: codebase grep] | Existing label guardrail, currently regex-denylist based. [VERIFIED: codebase grep] | Replace or extend it into event-family-aware allowlists for the new public contract. [VERIFIED: codebase grep] |
| `Parapet.attach/1` | In-repo helper. [VERIFIED: codebase grep] | Optional adapter activation with compile-out behavior. [VERIFIED: codebase grep] | Keep this as the host-owned activation seam for `Mailglass`, `Chimeway`, and `Rindle`. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated bounded `[:parapet, :delivery | :async, ...]` contract | Keep emitting coarse `[:parapet, :journey, ...]` events | Rejected by locked decision D-01 and by the current repo’s inability to express provider acceptance, callback delay, or retry/discard distinction through the journey shim. [VERIFIED: 4-CONTEXT.md][VERIFIED: codebase grep] |
| Shared public event families | Provider-specific public trees | Rejected by locked decisions D-02 through D-05 because downstream phases need one normalized vocabulary. [VERIFIED: 4-CONTEXT.md] |
| Top-level metadata allowlist plus `refs` bucket | Regex denylist only | The current denylist cannot express event-family-specific safe keys and will silently allow bounded-unknown fields as the contract grows. [VERIFIED: codebase grep] |

**Installation:**

```bash
mix deps.get
```

No new Hex dependency is required by the real codebase to plan Phase 4. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Sibling library event
  -> Mailglass / Chimeway / Rindle adapter
  -> internal normalization step
  -> public bounded event family
     -> [:parapet, :delivery, :outbound]
     -> [:parapet, :delivery, :provider_feedback]
     -> [:parapet, :delivery, :webhook_ingest]
     -> [:parapet, :async, :stage]
     -> [:parapet, :async, :backlog]
     -> [:parapet, :async, :callback]
  -> metadata allowlist
     -> safe bounded top-level fields
     -> high-cardinality refs under metadata.refs
  -> Telemetry consumers
     -> Phase 5 metrics/SLO modules
     -> Phase 6 alert and incident enrichment
     -> Phase 7 runbook and recovery surfaces
```

### Current Code Touch Points

| File | Why it matters |
|------|----------------|
| [`lib/parapet/integrations/mailglass.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/mailglass.ex) | Current one-event delivery shim that must expand into multiple bounded delivery families. [VERIFIED: codebase grep] |
| [`lib/parapet/integrations/chimeway.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/chimeway.ex) | Same thin shim problem, with the added uncertainty that broader upstream public event docs were not verified in this session. [VERIFIED: codebase grep][VERIFIED: web search] |
| [`lib/parapet/integrations/rindle.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/rindle.ex) | Current coarse media success/failure mapper that must split async stage, backlog, and callback concerns. [VERIFIED: codebase grep] |
| [`lib/parapet/internal/label_policy.ex`](/Users/jon/projects/parapet/lib/parapet/internal/label_policy.ex) | Current denylist guardrail that should become an allowlisted public contract validator. [VERIFIED: codebase grep] |
| [`lib/parapet/internal/safe_handler.ex`](/Users/jon/projects/parapet/lib/parapet/internal/safe_handler.ex) | Existing attach wrapper is single-event only and uses an anonymous wrapper function. [VERIFIED: codebase grep] |
| [`lib/parapet.ex`](/Users/jon/projects/parapet/lib/parapet.ex) | Existing compile-out activation seam that Phase 4 must preserve. [VERIFIED: codebase grep] |
| [`lib/parapet/metrics/scoria.ex`](/Users/jon/projects/parapet/lib/parapet/metrics/scoria.ex) | Best local example of bounded metadata translation with `Map.take/2`. [VERIFIED: codebase grep] |
| [`lib/parapet/metrics/oban.ex`](/Users/jon/projects/parapet/lib/parapet/metrics/oban.ex) | Existing async vocabulary precedent and the repo’s clearest current use of `queue` and `state` tags. [VERIFIED: codebase grep] |

### Recommended Project Structure

```text
lib/parapet/
├── integrations/      # Expand Mailglass, Chimeway, and Rindle translators
├── internal/          # Contract normalization, allowlists, and safe attachment helpers
├── metrics/           # Existing downstream metrics consumers; Phase 4 should only touch if the contract needs a translation seam
└── parapet.ex         # Keep adapter activation explicit and compile-out safe

test/parapet/
├── integrations/      # Contract tests per adapter
├── internal/          # Label allowlist and safe attachment tests
└── metrics/           # Oban-aligned semantic tests where async vocabulary overlaps
```

### Pattern 1: Normalize Many Upstream Events Into Few Public Families

**What:** each adapter should attach to related sibling events with one handler path, translate them into one of the six locked public event families, and keep provider-specific details out of the public event name. [VERIFIED: 4-CONTEXT.md][CITED: https://hexdocs.pm/telemetry/telemetry.html]

**When to use:** any `Mailglass`, `Chimeway`, or `Rindle` event that currently emits only a coarse success/failure journey story. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.attach_many(
  "parapet-mailglass-delivery",
  [
    [:mailglass, :outbound, :send, :stop],
    [:mailglass, :outbound, :send, :exception],
    [:mailglass, :webhook, :ingest, :stop],
    [:mailglass, :webhook, :ingest, :exception]
  ],
  &__MODULE__.handle_event/4,
  nil
)
```

### Pattern 2: Make Top-Level Metadata an Explicit Schema

**What:** public adapter output should emit only documented bounded keys at the top level and place exact identifiers inside `metadata.refs`. [VERIFIED: 4-CONTEXT.md]

**When to use:** every public `[:parapet, :delivery, ...]` or `[:parapet, :async, ...]` emission path. [VERIFIED: 4-CONTEXT.md]

**Example:**

```elixir
# Source: local bounded-translation pattern in lib/parapet/metrics/scoria.ex
public_metadata = %{
  integration: "mailglass",
  provider: "ses",
  channel: "email",
  outcome: "provider_accepted",
  fault_plane: "provider",
  refs: %{message_ref: metadata[:message_id]}
}
```

### Pattern 3: Preserve Host-Owned Compile-Out Activation

**What:** keep all adapter activation behind explicit `Parapet.attach(adapters: [...])` calls and guard optional modules with `Code.ensure_loaded?/1`. [VERIFIED: codebase grep]

**When to use:** any new helper or adapter setup path introduced in Phase 4. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: local activation pattern in lib/parapet.ex
Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])
```

### Anti-Patterns to Avoid

- **Public provider-specific event trees:** this conflicts with locked decisions D-02 through D-05 and would force later phases to special-case every adapter. [VERIFIED: 4-CONTEXT.md]
- **Passing raw IDs through top-level metadata:** the current project doctrine explicitly rejects high-cardinality metric labels and wants exact identifiers in evidence, not tags. [VERIFIED: 4-CONTEXT.md][VERIFIED: REQUIREMENTS.md]
- **Treating retries as failures equivalent to discard:** Oban’s lifecycle and the phase context both distinguish retryable work from exhausted work. [CITED: https://hexdocs.pm/oban/job_lifecycle.html][VERIFIED: 4-CONTEXT.md]
- **Implementing Phase 5 metrics or Phase 6 incident semantics inside the contract layer:** roadmap boundaries defer those concerns. [VERIFIED: ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-event telemetry attachment | One `:telemetry.attach/4` call per upstream event plus duplicated rescue blocks | `:telemetry.attach_many/4` plus a shared safe attachment path | Telemetry already provides the multi-event API, and the current duplication will get worse across the six locked families. [CITED: https://hexdocs.pm/telemetry/telemetry.html][VERIFIED: codebase grep] |
| Async retry/discard lifecycle semantics | A custom async state machine | Oban lifecycle vocabulary | Oban already defines `retryable` and `discarded`, and the repo already consumes Oban telemetry. [CITED: https://hexdocs.pm/oban/job_lifecycle.html][VERIFIED: codebase grep] |
| Label safety for Phase 4 | More regex rules in `LabelPolicy` | An explicit event-family allowlist schema | The new public contract has a known finite vocabulary, so allowlisting is simpler and safer than growing the denylist. [VERIFIED: 4-CONTEXT.md][VERIFIED: codebase grep] |
| Provider evidence storage | A new event ledger table | Existing telemetry plus later evidence/action-item phases | Requirements explicitly reject mirroring raw high-volume event streams into Ecto. [VERIFIED: REQUIREMENTS.md][VERIFIED: ROADMAP.md] |

**Key insight:** Phase 4 is about narrowing and documenting the public seam, not about inventing new infrastructure. [VERIFIED: ROADMAP.md][VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Keeping the journey shim and just adding more metadata

**What goes wrong:** the repo keeps emitting `[:parapet, :journey, :mail_delivery]` or `[:parapet, :journey, :media]` and tries to represent provider acceptance, callback lag, and retry/discard semantics only through metadata. [VERIFIED: codebase grep]

**Why it happens:** that is the current local pattern in all three relevant adapters. [VERIFIED: codebase grep]

**How to avoid:** create the bounded public event families first and let metadata carry only bounded detail within those families. [VERIFIED: 4-CONTEXT.md]

**Warning signs:** tests still assert only `[:parapet, :journey, ...]` emissions after the phase is complete. [VERIFIED: codebase grep]

### Pitfall 2: Leaving label safety as a generic denylist

**What goes wrong:** Phase 4 adds fields like `provider_message_ref` or tenant-derived queue names and the regex denylist either misses them or makes safe/unsafe meaning ambiguous. [VERIFIED: codebase grep][VERIFIED: 4-CONTEXT.md]

**Why it happens:** the current policy rejects names matching `id`, `raw_`, `token`, or `path`, but it does not define event-family-specific safe keys. [VERIFIED: codebase grep]

**How to avoid:** validate top-level metadata against a fixed allowlist per public event family and treat everything else as refs or internal-only. [VERIFIED: 4-CONTEXT.md]

**Warning signs:** new tests need to inspect raw vendor IDs or ad hoc top-level metadata to pass. [VERIFIED: codebase grep]

### Pitfall 3: Multiplying unsafe handler attachment patterns

**What goes wrong:** the phase introduces many more handlers, one crashes on shape drift, and Telemetry detaches it, creating a blind spot. [CITED: https://hexdocs.pm/telemetry/telemetry.html]

**Why it happens:** handler failures are a documented Telemetry failure mode, and the repo currently splits crash safety between repeated rescue blocks in adapter modules and an anonymous wrapper in `SafeHandler`. [CITED: https://hexdocs.pm/telemetry/telemetry.html][VERIFIED: codebase grep]

**How to avoid:** centralize safe multi-event attachment, add shape-drift tests, and verify repeated setup/attach behavior in tests. [VERIFIED: codebase grep]

**Warning signs:** tests or boot logs show repeated Telemetry warnings or attach collisions, or one integration suddenly goes silent while application behavior has not improved. [VERIFIED: local command][CITED: https://hexdocs.pm/telemetry/telemetry.html]

### Pitfall 4: Breaking compile-out guarantees while expanding adapters

**What goes wrong:** adding direct references or new runtime deps causes `parapet` installs without sibling libraries to fail or behave differently. [VERIFIED: codebase grep][VERIFIED: PITFALLS.md]

**Why it happens:** the real repo uses empty support modules in tests and `Code.ensure_loaded?/1` guards to preserve optional integration posture. [VERIFIED: codebase grep]

**How to avoid:** keep adapter setup explicit, avoid hard deps on `Mailglass`, `Chimeway`, or `Rindle`, and add compile-out regression tests around `Parapet.attach(adapters: ...)`. [VERIFIED: codebase grep]

**Warning signs:** new tests require real sibling packages just to compile the adapter modules. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and the local repo:

### Attach Related Event Families Safely

```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.attach_many(
  "parapet-rindle-async",
  [
    [:rindle, :media, :processed],
    [:rindle, :media, :failed]
  ],
  &__MODULE__.handle_event/4,
  nil
)
```

### Use `span/3`-Style Duration Boundaries

```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.span([:parapet, :probe, :run], %{probe: "health"}, fn ->
  {:ok, %{status: "success"}}
end)
```

### Strip to Bounded Metadata

```elixir
# Source: local pattern in lib/parapet/metrics/scoria.ex
safe_metadata = Map.take(metadata, [:provider, :channel, :outcome, :fault_plane])
:telemetry.execute([:parapet, :delivery, :provider_feedback], %{count: 1}, safe_metadata)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Thin generic `[:parapet, :journey, ...]` shims for async and delivery integrations. [VERIFIED: codebase grep] | A dedicated bounded async/delivery public contract with six event families and bounded metadata. [VERIFIED: 4-CONTEXT.md] | Locked in Phase 4 context on 2026-05-17. [VERIFIED: 4-CONTEXT.md] | Downstream SLO, alert, and incident work can depend on stable semantics instead of reverse-engineering adapter-specific payloads. [VERIFIED: ROADMAP.md] |
| Regex denylist label safety. [VERIFIED: codebase grep] | Event-family-aware allowlisted top-level metadata plus refs for high-cardinality values. [VERIFIED: 4-CONTEXT.md] | Locked in Phase 4 context on 2026-05-17. [VERIFIED: 4-CONTEXT.md] | Makes DELV-01 and TRIAGE-01 enforceable in tests. [VERIFIED: REQUIREMENTS.md] |
| Single-event attachment helpers and duplicated rescue blocks. [VERIFIED: codebase grep] | `attach_many/4` for related families plus explicit crash-safety handling. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | Needed for Phase 4’s multi-family contract. [VERIFIED: 4-CONTEXT.md] | Reduces adapter duplication and keeps handler detachment risk visible. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/telemetry/telemetry.html] |

**Deprecated/outdated:**

- Generic `:journey` as the long-term public API for these integrations is no longer the planned forward path. [VERIFIED: 4-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 4 will only normalize the `Chimeway` states and metadata that are proven by characterization during execution; unsupported provider semantics will remain out of scope for this phase instead of being guessed. [RESOLVED] | `## Current Code Touch Points`, `## Resolved Research Decisions` | If execution discovers less Chimeway surface than hoped, the Chimeway slice stays narrower but the phase remains valid. |
| A2 | Phase 4 can keep concrete metric-definition work mostly deferred to Phase 5 and still leave enough public contract coverage for downstream implementation. [ASSUMED] | `## Recommended Project Structure`, `## Validation Architecture` | Planner may under-scope contract tests if some metric-facing translation code is actually required now. |
| A3 | A temporary `:journey` bridge is not a required Phase 4 deliverable; execution should default to no bridge unless code search during implementation finds an in-repo consumer that would otherwise break. [RESOLVED] | `## Resolved Research Decisions` | If a consumer is found, the bridge becomes a local migration aid and not part of the long-term public contract. |

## Resolved Research Decisions

1. **Chimeway breadth is narrowed to proven upstream behavior.**
   - What we know: the repo only proves `[:chimeway, :event, :failed]`, and broader public Chimeway telemetry docs were not verified in this session. [VERIFIED: codebase grep][VERIFIED: web search]
   - Resolution: Phase 4 planning does not assume richer `Chimeway` semantics than execution can characterize. The first `Chimeway` task in the plan is therefore an explicit characterization/proof step, and the implementation only normalizes the states that step proves real.
   - Effect on scope: the delivery contract stays stable, but `Chimeway` may expose a smaller subset of the delivery vocabulary than `Mailglass` if the upstream surface is narrower.

2. **A temporary `:journey` bridge is optional, not a planning prerequisite.**
   - What we know: D-38 explicitly leaves bridge behavior to agent discretion, and current in-repo evidence only proves test coverage around the journey events. [VERIFIED: 4-CONTEXT.md][VERIFIED: codebase grep]
   - Resolution: the plan defaults to no bridge. Execution should search for in-repo consumers of `[:parapet, :journey, :mail_delivery]` and `[:parapet, :journey, :media]`; if none exist, remove the old shim cleanly. If a consumer is found, a short-lived compatibility bridge is acceptable as an implementation detail, but it is not part of the long-term public contract.
   - Effect on scope: the public forward path remains the new async/delivery families regardless of whether a temporary internal bridge is needed during migration.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and test Phase 4 changes | ✓ | `1.19.5` | — |
| Mix | Run tests and static verification | ✓ | `1.19.5` | — |
| `:telemetry` | Public contract implementation | ✓ | `1.4.1` in repo | — |
| `:telemetry_metrics_prometheus_core` | Some scrape-path tests and formatter behavior | ✗ at runtime in local test run | — | Phase 4 contract tests can avoid the scrape path unless planner intentionally expands metrics formatter coverage. |

**Missing dependencies with no fallback:**

- None. [VERIFIED: local command]

**Missing dependencies with fallback:**

- `:telemetry_metrics_prometheus_core` is not available in the observed test run, but the Phase 4 contract work can still be planned and tested without depending on the scrape formatter path. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: codebase grep][VERIFIED: local command] |
| Config file | `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs test/parapet/internal/label_policy_test.exs test/parapet/internal/safe_handler_test.exs test/parapet/metrics/oban_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DELV-01 | Each delivery adapter emits bounded outcomes that distinguish attempted, provider acceptance, confirmed delivery, failure, bounce, complaint, and suppression when upstream data exists. [VERIFIED: REQUIREMENTS.md] | integration | `mix test test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs` | ✅ |
| TRIAGE-01 | Public event metadata is allowlisted, low-cardinality, and demotes exact identifiers into refs. [VERIFIED: REQUIREMENTS.md] | unit + integration | `mix test test/parapet/internal/label_policy_test.exs test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs` | ✅ |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs test/parapet/internal/label_policy_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/parapet/integrations/public_delivery_contract_test.exs` — cross-adapter contract assertions do not exist yet. [VERIFIED: codebase grep]
- [ ] `test/parapet/integrations/public_async_contract_test.exs` — there is no contract-level async vocabulary test that checks `retryable_failed` vs `discarded` semantics. [VERIFIED: codebase grep]
- [ ] `test/parapet/internal/public_label_schema_test.exs` — current label tests only cover regex rejection, not event-family allowlists or `refs` demotion. [VERIFIED: codebase grep]
- [ ] Extend `test/parapet/internal/safe_handler_test.exs` or add a companion multi-attach test — current tests cover only single-event `attach/5`, not the `attach_many` path Phase 4 will likely need. [VERIFIED: codebase grep]
- [ ] Extend `test/parapet/integrations/*_test.exs` for repeated `setup/0` and compile-out expectations — current tests only prove one happy-path translation each. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 4 is a library telemetry contract change, not an auth flow. [VERIFIED: ROADMAP.md] |
| V3 Session Management | no | No session semantics are introduced by the phase boundary. [VERIFIED: ROADMAP.md] |
| V4 Access Control | no | Adapter normalization does not add an authorization surface in this phase. [VERIFIED: ROADMAP.md] |
| V5 Input Validation | yes | Validate public metadata against explicit allowlists and demote exact identifiers into `refs`. [VERIFIED: 4-CONTEXT.md] |
| V6 Cryptography | no | Webhook signature verification may be observed later as metadata or fault-plane output, but Phase 4 does not define new crypto behavior itself. [VERIFIED: ROADMAP.md][VERIFIED: 4-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| High-cardinality or PII leakage into public telemetry | Information Disclosure | Allowlisted bounded top-level metadata plus `refs` for exact identifiers. [VERIFIED: 4-CONTEXT.md] |
| Handler crash causing silent observability loss | Denial of Service | Safe attachment wrappers, defensive parsing, and explicit tests for shape drift and repeated setup. [CITED: https://hexdocs.pm/telemetry/telemetry.html][VERIFIED: codebase grep] |
| Adapter-specific metadata spoofing or drift changing alert semantics | Tampering | Normalize into a small bounded outcome and fault-plane vocabulary before public emission. [VERIFIED: 4-CONTEXT.md] |
| Queue-name explosion from tenant-derived async lanes | Denial of Service | Treat only documented finite queue names as label-safe; otherwise move queue identity into refs. [VERIFIED: 4-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- [Telemetry docs](https://hexdocs.pm/telemetry/telemetry.html) - verified `attach_many/4`, `span/3`, and handler failure behavior.
- [Oban job lifecycle docs](https://hexdocs.pm/oban/job_lifecycle.html) - verified retryable vs discarded lifecycle semantics.
- [`lib/parapet.ex`](/Users/jon/projects/parapet/lib/parapet.ex) - verified explicit adapter activation and compile-out posture.
- [`lib/parapet/internal/safe_handler.ex`](/Users/jon/projects/parapet/lib/parapet/internal/safe_handler.ex) - verified current single-event safe attach shape.
- [`lib/parapet/internal/label_policy.ex`](/Users/jon/projects/parapet/lib/parapet/internal/label_policy.ex) - verified current denylist label policy.
- [`lib/parapet/integrations/mailglass.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/mailglass.ex), [`lib/parapet/integrations/chimeway.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/chimeway.ex), [`lib/parapet/integrations/rindle.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/rindle.ex) - verified thin current adapter baseline.
- [`lib/parapet/metrics/scoria.ex`](/Users/jon/projects/parapet/lib/parapet/metrics/scoria.ex) - verified local bounded metadata translation precedent.
- [`lib/parapet/metrics/oban.ex`](/Users/jon/projects/parapet/lib/parapet/metrics/oban.ex) - verified local async vocabulary precedent.
- [`test/parapet/integrations/mailglass_test.exs`](/Users/jon/projects/parapet/test/parapet/integrations/mailglass_test.exs), [`test/parapet/integrations/chimeway_test.exs`](/Users/jon/projects/parapet/test/parapet/integrations/chimeway_test.exs), [`test/parapet/integrations/rindle_test.exs`](/Users/jon/projects/parapet/test/parapet/integrations/rindle_test.exs), [`test/parapet/internal/label_policy_test.exs`](/Users/jon/projects/parapet/test/parapet/internal/label_policy_test.exs), [`test/parapet/internal/safe_handler_test.exs`](/Users/jon/projects/parapet/test/parapet/internal/safe_handler_test.exs) - verified current test posture.
- [Telemetry Metrics docs](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html) - verified tag extraction model for bounded metadata.
- [Telemetry Hex versions](https://hex.pm/packages/telemetry/versions), [Telemetry Metrics Hex versions](https://hex.pm/packages/telemetry_metrics/versions), [Oban Hex versions](https://hex.pm/packages/oban/versions) - verified current package versions.

### Secondary (MEDIUM confidence)

- [`4-CONTEXT.md`](/Users/jon/projects/parapet/.planning/v0.7-phases/4/4-CONTEXT.md) - locked Phase 4 decisions and deferred scope.
- [`ROADMAP.md`](/Users/jon/projects/parapet/.planning/ROADMAP.md) - phase boundary and success criteria.
- [`REQUIREMENTS.md`](/Users/jon/projects/parapet/.planning/REQUIREMENTS.md) - DELV-01 and TRIAGE-01 requirements.
- [`.planning/research/ARCHITECTURE.md`](/Users/jon/projects/parapet/.planning/research/ARCHITECTURE.md) - prior milestone architecture framing used to cross-check local recommendations.
- [`.planning/research/STACK.md`](/Users/jon/projects/parapet/.planning/research/STACK.md) - prior stack research, especially for upstream Mailglass and Rindle references.

### Tertiary (LOW confidence)

- No broader official `Chimeway` telemetry documentation was verified in this session; all richer Chimeway guidance remains assumption-backed until that surface is checked. [VERIFIED: web search]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the phase can rely on in-repo Telemetry, Telemetry.Metrics, and Oban usage plus official docs and version pages. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/telemetry/telemetry.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html]
- Architecture: MEDIUM - the repo seams are clear, but the exact upstream `Chimeway` event contract was not verified. [VERIFIED: codebase grep][VERIFIED: web search]
- Pitfalls: HIGH - handler detachment, denylist drift, compile-out regressions, and journey-shim limitations are all visible in either official Telemetry docs or current code. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/telemetry/telemetry.html]

**Research date:** 2026-05-17
**Valid until:** 2026-06-16
