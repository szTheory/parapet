# Technology Stack

**Project:** Parapet v0.7 Async & Delivery Reliability
**Researched:** 2026-05-17
**Scope:** New stack additions and integration changes for `Chimeway`, `Mailglass`, `Rindle`, and built-in stalled-job runbook support.

## Recommendation

v0.7 should **extend Parapet's existing telemetry-normalization layer**, not add a new async platform. The correct shape is:

1. Keep Parapet as a thin adapter over sibling-library telemetry.
2. Reuse `Oban` for queue truth, retries, and stalled/discarded-job inspection.
3. Reuse `Req` only where Parapet must make host-owned HTTP calls itself.
4. Add richer normalized Parapet event families so the Operator UI can distinguish:
   - provider failure
   - webhook drift
   - suppression drift
   - internal backlog / stalled jobs

The main change is architectural, not infrastructural: **move from single coarse journey events to bounded normalized async/delivery events with queue-aware context**.

## Recommended Stack Additions

### Runtime dependencies to add or tighten

| Technology | Version / Status | Purpose in v0.7 | Why |
|------------|------------------|-----------------|-----|
| `:oban` | Tighten from `>= 0.0.0` to `~> 2.21` or `~> 2.22`; current Hex is `2.22.1` on 2026-05-17 | Queue truth for stalled-job detection, retry state inspection, discarded-job visibility, and runbook context | Parapet already depends on Oban semantics for notifications and metrics. v0.7 now depends on concrete job lifecycle concepts (`available`, `executing`, `retryable`, `completed`, `discarded`) rather than only generic queue throughput. |
| `:telemetry` | Consider widening from `~> 1.2` to `~> 1.4`; current Hex is `1.4.2` on 2026-05-17 | Attach richer handlers, optionally use `:telemetry.persist/0` carefully in adopter docs, and align with current ecosystem contracts | v0.7 is telemetry-heavy. Staying on an old floor adds avoidable friction for sibling integrations already shipping modern telemetry surfaces. |
| `:telemetry_metrics` | Consider widening from `~> 1.0` to `~> 1.1`; current Hex is `1.1.0` | Support additional counters/gauges/distributions for async and delivery views | This is a safe extension of Parapet's existing metrics layer, not a new observability subsystem. |
| `:req` | Keep `~> 0.5.17` optional; current Hex is `0.5.17` | Optional outbound HTTP only for Parapet-owned fetch/reconcile helpers or provider health probes if v0.7 adds them | Req already gives retries and Finch reuse. Do not add a second HTTP client. |

### Internal components to add

| Component | Type | Purpose | Why |
|-----------|------|---------|-----|
| `Parapet.Integrations.DeliveryAdapter` | Internal behaviour/helper | Shared normalization for `Chimeway` and `Mailglass` event translation | The current adapters duplicate thin `handle_event/4` logic and only emit failure events. v0.7 needs one bounded mapping policy for provider, stream/channel, status, and drift fields. |
| `Parapet.Integrations.AsyncAdapter` | Internal behaviour/helper | Shared normalization for `Rindle` and Oban-backed stalled-work signals | Rindle queue symptoms and Rindle domain telemetry should land in a single internal schema, not two unrelated code paths. |
| `Parapet.RunbookTemplates.Async` | Internal module(s), no new dep | Built-in stalled-job, dead-letter, and safe-retry templates | This satisfies the milestone without introducing a separate workflow engine. |
| `Parapet.ObanInspector` | Internal query module | Query `Oban.Job` and queue state for runbook context, incident enrichment, and doctor checks | Stalled-job support requires deterministic queue facts. Query them directly; do not infer them from metrics alone. |

## Existing Dependencies to Reuse

| Existing dependency | Reuse in v0.7 | Notes |
|---------------------|---------------|-------|
| `Ecto` / `Ecto.SQL` | Incident enrichment, queue snapshots, runbook context, dead-letter counts | Use for low-volume facts only. Do not mirror raw job events into Parapet tables. |
| `Oban` | Retry/discarded/stalled job inspection, queue-level SLIs, Rindle queue classification | Reuse the existing optional compile-out pattern already used by `Parapet.Metrics.Oban` and notification dispatch. |
| `Req` | Optional provider-health fetches or host-owned reconciliation endpoints | Reuse Finch-backed transport. Avoid Tesla, HTTPoison, Hackney, or custom Finch plumbing. |
| `:telemetry` | Primary integration seam for `Chimeway`, `Mailglass`, `Rindle`, and Oban | This remains the public integration boundary. |
| `telemetry_metrics` | Prometheus-facing metrics definitions for new normalized events | Extend current metric registration, do not add PromEx. |
| `opentelemetry_api` | Trace exemplars / correlation only | Keep trace linkage optional. v0.7 is not an OTel-first milestone. |
| Existing Operator UI / Incident timeline / Runbook DSL | Context display and action surface | v0.7 should enrich these surfaces, not replace them. |

## Integration Changes By Capability

### `Mailglass`

**Recommendation:** upgrade the integration from a single failure hook to a **multi-event delivery adapter** over Mailglass's documented telemetry surface.

Use these Mailglass event families:

- `[:mailglass, :outbound, :send, :stop | :exception]`
- `[:mailglass, :outbound, :dispatch, :stop | :exception]`
- `[:mailglass, :webhook, :ingest, :stop | :exception]`
- `[:mailglass, :webhook, :signature, :verify, :stop | :exception]`
- `[:mailglass, :webhook, :normalize, :stop]`
- `[:mailglass, :webhook, :orphan, :stop]`
- `[:mailglass, :webhook, :duplicate, :stop]`
- `[:mailglass, :webhook, :reconcile, :stop | :exception]`

Emit normalized Parapet events such as:

- `[:parapet, :delivery, :outbound]`
- `[:parapet, :delivery, :provider_feedback]`
- `[:parapet, :delivery, :webhook_ingest]`
- `[:parapet, :delivery, :suppression_drift]`

Bounded metadata to preserve:

- `provider`
- `status`
- `tenant_id` if already whitelisted by Mailglass
- `event_type`
- `duplicate`
- `delivery_id_matched`
- `remaining_orphan_count`

Do **not** pass through recipient addresses, subjects, bodies, raw payloads, or delivery IDs as metric labels. Delivery IDs may be timeline refs, not labels.

### `Chimeway`

**Recommendation:** treat `Chimeway` as a sibling delivery adapter with the same normalized Parapet delivery schema as `Mailglass`.

Current repo evidence only shows `[:chimeway, :event, :failed]`. I could not verify a broader public Chimeway telemetry contract from official docs, so confidence here is **medium**. The implementation guidance is:

- keep the adapter dependency-free
- attach only to documented/public Chimeway events
- map them into the same normalized internal event families as Mailglass
- require explicit allowlists for metadata keys before promoting anything to metrics

If Chimeway lacks the telemetry needed for backlog drift or provider feedback distinction, add a **small adapter options contract** in Parapet for host-supplied mapping functions rather than pulling in a provider SDK.

### `Rindle`

**Recommendation:** stop treating Rindle as one coarse `:media` journey and instead combine:

1. Rindle domain telemetry
2. Oban queue telemetry
3. direct `Oban.Job` inspection for stalled/discarded state

Use Rindle's documented background-processing contract:

- queues: `rindle_promote`, `rindle_process`, `rindle_purge`, `rindle_maintenance`
- job lifecycle is backed by the default `Oban` instance
- queue ownership stays with the adopter

Use Rindle telemetry families where available:

- upload/session lifecycle
- asset state changes
- variant state changes
- cleanup runs

Then join that with existing Parapet Oban metrics and inspector queries to distinguish:

- media processor regression
- queue backlog
- webhook or external delivery lag
- maintenance-worker drift

This is the key v0.7 integration point: **Rindle symptoms should not be inferred from Rindle telemetry alone**.

### Built-in stalled-job runbook support

**Recommendation:** build this on top of `Oban.Job` state and queue inspection, not on new workers or new storage.

Needed pieces:

- `Parapet.ObanInspector` querying queue counts by `state`
- queue age / oldest-job calculations for `available`, `executing`, and `retryable`
- discarded/dead-letter summaries
- runbook template modules for:
  - retry exhausted jobs
  - backlog growth
  - stuck executing jobs
  - Rindle maintenance drift

Use the existing `Parapet.Runbook` DSL and Operator UI. Do not add a separate runbook engine, scheduler, or remediation daemon.

## Transport and Adapter Considerations

### Adapter shape

Use `:telemetry.attach_many/4` for sibling integrations with multiple event families. The current one-handler-per-event shape is too narrow for `Mailglass` and likely too narrow for `Chimeway`.

Each adapter should:

1. translate sibling events into one bounded Parapet internal schema
2. strip or demote high-cardinality identifiers
3. emit low-cardinality metrics events
4. optionally append richer refs to timeline evidence only

### HTTP transport

If v0.7 introduces Parapet-owned fetches:

- use `Req`
- reuse the default Finch pool unless adopters pass `:finch`
- keep retries bounded
- treat HTTP fetch failure as evidence, not source-of-truth replacement

Do not add:

- `Tesla`
- `HTTPoison`
- custom Finch wrappers

### Optional dependency and compile-out rules

Keep `Chimeway`, `Mailglass`, and `Rindle` out of Parapet's required dependency graph. Prefer:

- telemetry-only integration modules
- `Code.ensure_loaded?` guards where module references are unavoidable
- contract tests or example apps for sibling-library verification

Do **not** add those sibling libraries as hard runtime deps just to make the adapter code "feel integrated". That would violate a core project constraint.

## What Not To Add

| Do not add | Why not |
|------------|---------|
| `Broadway`, `GenStage`, RabbitMQ/Kafka clients, or another queue substrate | v0.7 is observability over existing async systems, not a new async platform. |
| PromEx | Parapet already owns a telemetry-to-metrics path. Adding PromEx would duplicate responsibility and increase dependency surface. |
| A second HTTP client (`Tesla`, `HTTPoison`, raw `Mint` wrapper) | `Req` already covers the needed transport with retries and Finch integration. |
| Provider-specific SDK ownership inside Parapet | Parapet should observe sibling libs and host-owned flows, not become the vendor-integration layer itself. |
| A new persistent store for async job facts | `Oban.Job` plus existing Parapet incidents/timeline is enough. Adding storage creates sync problems. |
| Polling daemons for data already available via telemetry or Oban queries | Prefer event-driven translation first. Poll only when the sibling library's contract requires it. |
| Autonomous remediation workers | The milestone explicitly stops short of production mutation without operator intent. |

## Milestone-Specific Package Guidance

### `mix.exs`

Recommended changes:

```elixir
defp deps do
  [
    {:ecto, "~> 3.10"},
    {:ecto_sql, "~> 3.10"},
    {:igniter, "~> 0.7.9"},
    {:opentelemetry_api, "~> 1.3", optional: true},
    {:telemetry, "~> 1.4"},
    {:telemetry_metrics, "~> 1.1"},
    {:oban, "~> 2.21", optional: true},
    {:req, "~> 0.5.17", optional: true},
    {:sigra, ">= 0.0.0", optional: true}
  ]
end
```

Notes:

- `:telemetry` and `:telemetry_metrics` widening is recommended but should be validated in CI before release.
- `:oban` should be tightened because v0.7 now depends on concrete lifecycle semantics, not just "some Oban present".
- No new sibling-library deps are recommended in the core package.

## Confidence

| Area | Confidence | Notes |
|------|------------|-------|
| Oban / stalled-job stack | HIGH | Verified against current Oban docs and Rindle docs. |
| Mailglass integration surface | HIGH | Verified against current Mailglass telemetry docs. |
| Req reuse | HIGH | Verified against current Req docs. |
| Chimeway integration surface | MEDIUM | Repo evidence exists, but I could not verify a broader official public telemetry contract. |

## Sources

- Project context: `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `README.md`
- Local implementation: `mix.exs`, `lib/parapet/integrations/*.ex`, `lib/parapet/metrics/oban.ex`
- Mailglass telemetry docs: https://hexdocs.pm/mailglass/telemetry.html
- Rindle background processing docs: https://hexdocs.pm/rindle/background_processing.html
- Oban job lifecycle docs: https://hexdocs.pm/oban/job_lifecycle.html
- Req docs: https://hexdocs.pm/req/Req.html
- Hex package status:
  - Oban: https://hex.pm/packages/oban/versions
  - Telemetry: https://hex.pm/packages/telemetry/versions
  - Req: https://hex.pm/packages/req/versions
  - Telemetry Metrics: https://hex.pm/packages/telemetry_metrics/versions
