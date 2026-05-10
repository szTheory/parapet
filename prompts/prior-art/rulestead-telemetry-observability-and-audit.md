# Rulestead Telemetry, Observability & Audit

> **Purpose:** Specify the event schemas, measurement/metadata contracts, OpenTelemetry alignment, impression/exposure model, debug surfaces, and append-only audit ledger for rulestead. Distilled from threadline's audit DNA, lattice_stripe's telemetry conventions, and the observability requirements in the master research brief.
>
> **Read alongside:** `rulestead-engineering-dna-from-prior-libs.md` §2.3, `rulestead-domain-language-field-guide.md` §Events, `rulestead-security-privacy-and-threat-model.md` (redaction rules).

---

## 1. Principles

1. **One canonical event tree.** All events live under `[:rulestead, ...]`. Stable contract; versioned in `api_stability.md`.
2. **Span conventions everywhere.** Every meaningful operation emits `:start` / `:stop` / `:exception` triplets with `:telemetry.span/3`.
3. **Measurements are numbers; metadata is context.** No mixing — monotonic `:duration`/`:monotonic_time` go in measurements; everything else in metadata.
4. **Redact at emission.** The context map in events never contains raw PII. `Rulestead.ContextRedactor` runs inline.
5. **Impression sampling is opt-in + bounded.** High-volume evaluation events are sampled by default; admin mutation events are never sampled.
6. **Audit is not telemetry.** Telemetry is ephemeral + lossy; audit is durable + complete. They share nothing except timestamps.
7. **Debug surfaces must not leak secrets.** `/health`, `/diagnostics`, admin explain views redact the same attributes as logs.
8. **Everything is traceable.** Every event carries a `trace_id` + `span_id` when the caller provides one; otherwise generated.

---

## 2. Event schema

### 2.1 Namespace layout

```
[:rulestead, :eval, :decide, :start | :stop | :exception]
[:rulestead, :eval, :cache, :hit | :miss | :invalidate]
[:rulestead, :eval, :stale_used]
[:rulestead, :eval, :fallthrough]         # hit default_value; helps spot misconfig
[:rulestead, :eval, :impression]           # sampled; optional
[:rulestead, :eval, :exposure]             # experimentation hook, always on

[:rulestead, :snapshot, :published]
[:rulestead, :snapshot, :applied]
[:rulestead, :snapshot, :stale]

[:rulestead, :admin, :flag, :created | :updated | :archived | :unarchived]
[:rulestead, :admin, :audience, :created | :updated | :archived]
[:rulestead, :admin, :ruleset, :drafted | :simulated | :published | :reverted]
[:rulestead, :admin, :rollout, :started | :advanced | :held | :rolled_back | :completed]
[:rulestead, :admin, :killswitch, :engaged | :released]
[:rulestead, :admin, :change_request, :submitted | :approved | :rejected | :merged]
[:rulestead, :admin, :ui, :page_view | :action_started | :action_completed | :search]

[:rulestead, :ops, :import, :applied | :failed]
[:rulestead, :ops, :export, :generated]
[:rulestead, :ops, :webhook, :received | :rejected]
[:rulestead, :ops, :dlq, :exhausted]

[:rulestead, :hooks, :before_eval | :after_eval | :before_mutation | :after_mutation,
  :start | :stop | :exception]

[:rulestead, :repo, :query]                # piggybacks on Ecto's events; re-exposes with our namespace for sampling
```

Concrete names are part of the API contract. Once published, they can be extended (add events) but **never renamed** without a deprecation cycle.

### 2.2 Canonical measurements

| Key | Type | Events | Notes |
|---|---|---|---|
| `:duration` | integer (native time) | all `:stop` / `:exception` | `System.monotonic_time() - start` |
| `:monotonic_time` | integer | all `:start` / `:stop` / `:exception` | `System.monotonic_time()` |
| `:system_time` | integer | `:start` only | wall-clock for correlation |
| `:count` | integer | `:invalidate`, `:stale_used`, `:fallthrough` | 1 per event |
| `:cache_age_ms` | integer | `:cache, :hit`, `:stale_used` | how old was the snapshot |

### 2.3 Canonical metadata (all events)

Every event carries these keys when available:

```elixir
%{
  tenant_id: "acme",
  env: :prod,
  snapshot_version: 2741,
  trace_id: "01HXY...",
  span_id: "b7f3...",
  actor_id: "u_123",           # who performed (operator for admin events; evaluation actor for eval events)
  actor_role: :operator | :app,
  node: :"rulestead@host-1",
  instance_id: "rulestead-5f7c-prod"
}
```

`tenant_id`/`actor_id` go through `Rulestead.ContextRedactor` before emission.

### 2.4 Event-specific metadata

#### `[:rulestead, :eval, :decide, :stop]`

```elixir
%{
  flag_key: "checkout_v2",
  variant: "treatment",
  value: %{...},                  # raw value (may be redacted)
  matched_rule_index: 2,
  bucket: 4721,
  reason: :rule_match,            # :rule_match | :default | :killswitch | :forced | :killswitch_forced | :error
  cache_source: :local | :cluster | :store,
  sample: 1.0                     # 0.0..1.0; sub-sampling downstream weights this
}
```

#### `[:rulestead, :eval, :impression]`

Emitted after decide when impression tracking is enabled. Sampled per-flag config.

```elixir
%{
  flag_key: "checkout_v2",
  variant: "treatment",
  ruleset_version: 27,
  snapshot_version: 2741,
  context_digest: "sha256:ab12...",   # hash of sanitized context for dedup
  sample_rate: 0.01
}
```

#### `[:rulestead, :eval, :exposure]`

Always emitted for flags marked `track_exposures: true`. This is the experimentation hook — downstream aggregators turn these into assignment tables.

```elixir
%{
  experiment_key: "checkout_v2",
  variant: "treatment",
  assignment_unit: :user,            # :user | :session | :tenant | custom
  assignment_id: "u_123",            # already-redacted hash if policy requires
  ruleset_version: 27,
  assigned_at_ms: 1_731_000_000_000
}
```

Exposures are the bridge to experimentation tools (GrowthBook, Statsig, your own warehouse). We emit; we don't ship an analytics backend.

#### `[:rulestead, :eval, :cache, :miss]`

```elixir
%{
  flag_key: "checkout_v2",
  source_attempted: :local | :cluster | :store,
  fallback_source: :store,
  snapshot_version_requested: 2741,
  reason: :cold | :evicted | :version_mismatch | :cross_node_fanout
}
```

#### `[:rulestead, :admin, :ruleset, :published]`

```elixir
%{
  flag_key: "checkout_v2",
  ruleset_id: "01HXY...",
  ruleset_version: 27,
  prior_version: 26,
  simulate_delta: %{
    evaluated: 12_500,
    flipped: 430,
    by_variant: %{"treatment" => 320, "control" => 110}
  },
  change_request_id: "cr_9a2f",         # nil if direct-publish allowed
  audit_event_id: "01HXY..."            # cross-reference to audit ledger
}
```

Every admin event carries `:audit_event_id`. Telemetry is disposable; audit is the record of truth.

#### `[:rulestead, :admin, :killswitch, :engaged]`

```elixir
%{
  flag_key: "checkout_v2",
  forced_variant: "control",
  expires_at: ~U[2026-04-25 10:00:00Z],
  reason: "p99 latency regression — rolling back",
  audit_event_id: "01HXY..."
}
```

#### `[:rulestead, :hooks, <phase>, :exception]`

```elixir
%{
  hook_module: MyApp.RulesteadHooks,
  hook_phase: :before_eval,
  flag_key: "checkout_v2",
  kind: :error | :exit | :throw,
  error: formatted_error_binary,
  stacktrace: formatted_stacktrace_binary
}
```

Hook exceptions never crash the evaluator. They're logged, emitted, and the operation proceeds with the original input.

---

## 3. Span conventions

Every span-like operation uses `:telemetry.span/3`:

```elixir
:telemetry.span(
  [:rulestead, :eval, :decide],
  %{flag_key: flag_key, tenant_id: ctx.tenant_id, env: ctx.env, trace_id: ctx.trace_id},
  fn ->
    result = Evaluator.decide(flag_key, ctx)
    stop_metadata = %{
      variant: result.variant,
      matched_rule_index: result.matched_rule_index,
      bucket: result.bucket,
      reason: result.reason,
      cache_source: result.cache_source
    }
    {result, stop_metadata}
  end
)
```

Rules:
- Start metadata is the "what is being attempted."
- Stop metadata extends with results.
- Exception metadata is automatic + adds our `:kind`, `:error`, `:stacktrace`.
- Duration is auto-computed.
- No `try/rescue` around the span — let it raise, `:telemetry.span/3` emits the `:exception` event correctly.

---

## 4. OpenTelemetry alignment

### 4.1 Shipped component

`Rulestead.OTel` is an optional-dep wrapper that attaches handlers to our telemetry events and converts them to OpenTelemetry spans / metrics.

```elixir
# Host adds to deps + calls in application.ex:
Rulestead.OTel.setup()
```

Config:
```elixir
config :rulestead, Rulestead.OTel,
  spans: true,
  metrics: true,
  span_kind_mapping: %{
    [:rulestead, :eval, :decide] => :internal,
    [:rulestead, :ops, :webhook] => :server,
    [:rulestead, :snapshot, :applied] => :consumer
  }
```

### 4.2 Span attribute naming

We follow OTel semantic conventions where they apply; custom attributes use `rulestead.*`:

| Internal metadata | OTel attribute |
|---|---|
| `tenant_id` | `rulestead.tenant_id` |
| `env` | `rulestead.env` (→ also `deployment.environment`) |
| `snapshot_version` | `rulestead.snapshot.version` |
| `flag_key` | `rulestead.flag.key` |
| `variant` | `rulestead.flag.variant` |
| `matched_rule_index` | `rulestead.flag.matched_rule_index` |
| `bucket` | `rulestead.flag.bucket` |
| `reason` | `rulestead.flag.reason` |
| `ruleset_version` | `rulestead.ruleset.version` |
| `audit_event_id` | `rulestead.audit.event_id` |

### 4.3 Metrics exposure

Telemetry-metrics friendly. Example `Telemetry.Metrics` definitions host apps can register:

```elixir
Telemetry.Metrics.counter("rulestead.eval.decide.count",
  event_name: [:rulestead, :eval, :decide, :stop],
  tags: [:tenant_id, :env, :flag_key, :variant])

Telemetry.Metrics.distribution("rulestead.eval.decide.duration",
  event_name: [:rulestead, :eval, :decide, :stop],
  measurement: :duration,
  unit: {:native, :millisecond},
  tags: [:env, :cache_source],
  reporter_options: [buckets: [0.1, 0.5, 1, 5, 10, 50, 100]])

Telemetry.Metrics.counter("rulestead.eval.cache.miss",
  event_name: [:rulestead, :eval, :cache, :miss],
  tags: [:env, :reason])

Telemetry.Metrics.counter("rulestead.admin.ruleset.published",
  event_name: [:rulestead, :admin, :ruleset, :published],
  tags: [:tenant_id, :env, :flag_key])
```

`flag_key` tagging is configurable — for ultra-high-cardinality deployments, hosts disable `flag_key` from metrics tags and get per-flag visibility only from traces/impressions.

---

## 5. Impression + exposure model

### 5.1 Why they're separate from `:decide`

Every flag evaluation emits `:decide`. Not every evaluation needs to be analyzed. Separating impressions lets hosts:
- Sample impressions at 1% or 0.1% for high-volume flags.
- Aggregate impressions in-process before shipping downstream.
- Disable impressions entirely for non-experimentation flags.

Exposures differ: they're the ground truth of "this actor saw this variant" for experimentation analysis. Always emitted for flags with `track_exposures: true`; dedup-hashed to avoid multi-emitting per request.

### 5.2 Impression sampler

Default config:
```elixir
config :rulestead, :impressions,
  default_sample_rate: 0.01,     # 1%
  per_flag_overrides: %{
    "checkout_v2" => 1.0           # always sampled during rollout
  },
  shipper: Rulestead.Impressions.PubSubShipper,
  shipper_opts: [topic: "impressions"]
```

Shipper behaviour:
```elixir
defmodule Rulestead.Impressions.Shipper do
  @callback ship([impression :: map()]) :: :ok | {:error, term()}
end
```

Built-ins: `PubSubShipper` (default), `FileShipper` (JSONL), `OTelLogsShipper`.

### 5.3 Dedup

In-memory LRU (`:ets`) of `{flag_key, context_digest, ruleset_version}` → already-emitted-at. Size and TTL configurable; dedup is per-node.

---

## 6. Append-only audit ledger (threadline DNA)

### 6.1 Schema

```elixir
schema "rulestead_audit_events" do
  field :event_id,            Ecto.UUID   # UUIDv7 — time-ordered primary key
  field :occurred_at,         :utc_datetime_usec
  field :tenant_id,           :string
  field :env,                 :string
  field :snapshot_version,    :integer
  field :actor_id,            :string
  field :actor_role,          :string
  field :actor_display,       :string     # rendered at emit, snapshot for UI replay
  field :resource_type,       :string     # "flag" | "ruleset" | "rollout" | "audience" | "killswitch" | "change_request"
  field :resource_key,        :string
  field :resource_id,         Ecto.UUID
  field :verb,                :string     # "created" | "updated" | "archived" | "published" | etc.
  field :idempotency_key,     :string
  field :trace_id,            :string
  field :correlation_id,      :string     # for chaining across related events (e.g., CR → publish → rollout start)
  field :reason,              :string     # operator-provided mutation reason
  field :prior_state,         :map
  field :next_state,          :map
  field :diff,                :map        # jsondiff between prior + next
  field :signature,           :binary     # HMAC over canonical payload (optional, tenant-configurable)
end
```

Indexes:
- Primary key: `event_id` (UUIDv7 gives temporal ordering).
- `(tenant_id, env, occurred_at DESC)` — timeline queries.
- `(resource_type, resource_key, occurred_at DESC)` — per-resource timeline.
- `(correlation_id)` — chain follow.
- `(actor_id, occurred_at DESC)` — per-operator audit.
- Partial unique on `(idempotency_key)` where not null.

### 6.2 Immutability enforcement

- **App-level:** no `update_*` / `delete_*` function; `AuditStore` behaviour has only `put_event/2` + read functions.
- **DB-level (Postgres trigger):**

```sql
CREATE OR REPLACE FUNCTION rulestead_audit_immutable()
  RETURNS TRIGGER AS $$
  BEGIN
    IF TG_OP = 'UPDATE' THEN
      RAISE EXCEPTION 'rulestead_audit_events is append-only (UPDATE forbidden)'
        USING ERRCODE = '45A01';
    ELSIF TG_OP = 'DELETE' THEN
      RAISE EXCEPTION 'rulestead_audit_events is append-only (DELETE forbidden)'
        USING ERRCODE = '45A01';
    END IF;
    RETURN NULL;
  END;
  $$ LANGUAGE plpgsql;

CREATE TRIGGER rulestead_audit_immutable_trig
  BEFORE UPDATE OR DELETE ON rulestead_audit_events
  FOR EACH ROW EXECUTE FUNCTION rulestead_audit_immutable();
```

Migration emits this trigger. Tests assert `Postgrex.Error{postgres: %{code: "45A01"}}` on attempted update/delete.

### 6.3 Atomic write + audit

Every admin mutation uses `Ecto.Multi` with both the mutation and the audit insertion in the same transaction. If the audit insert fails, the mutation rolls back.

```elixir
def publish_ruleset(%{flag_key: _} = attrs, %Rulestead.Context{} = ctx) do
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:ruleset, Ruleset.changeset(%Ruleset{}, attrs))
  |> Ecto.Multi.run(:simulate_delta, fn _, %{ruleset: r} ->
    Simulator.simulate(r, sample: :last_hour)
  end)
  |> Ecto.Multi.insert(:audit, fn %{ruleset: r, simulate_delta: delta} ->
    AuditEvent.changeset(%AuditEvent{}, %{
      resource_type: "ruleset",
      resource_key: r.flag_key,
      resource_id: r.id,
      verb: "published",
      prior_state: %{ruleset_version: r.version - 1},
      next_state: %{ruleset_version: r.version, simulate_delta: delta},
      diff: AuditDiff.between(r.prior_version, r),
      idempotency_key: attrs[:idempotency_key],
      tenant_id: ctx.tenant_id,
      env: to_string(ctx.env),
      snapshot_version: ctx.snapshot_version,
      actor_id: ctx.actor.id,
      actor_role: ctx.actor.role,
      actor_display: ctx.actor.display_name,
      reason: attrs[:reason],
      trace_id: ctx.trace_id,
      correlation_id: attrs[:correlation_id] || Ecto.UUID.generate()
    })
  end)
  |> Repo.transaction()
end
```

### 6.4 PgBouncer-safe actor context propagation

Sibling libs running through PgBouncer transaction-mode can lose `SET LOCAL app.actor_id` across connections. Rulestead's audit flow avoids that entirely by:
1. Actor identity flows through the `%Rulestead.Context{}` struct explicitly.
2. `Ecto.Multi` runs within a single checked-out connection; audit insertion is in the same transaction as the mutation.
3. Row-level audit data is set via Ecto inserts, not via Postgres session GUCs.

This sidesteps the PgBouncer class of bugs entirely (threadline learned this at cost).

### 6.5 Signing (optional)

Tenants with compliance needs can enable per-event HMAC signing:

```elixir
config :rulestead, :audit,
  signing: %{
    enabled: true,
    secret_provider: {MyApp.Secrets, :audit_hmac_key, []},
    canonicalizer: Rulestead.AuditSignature.CanonicalJSON
  }
```

Signature covers: `event_id, occurred_at, tenant_id, env, resource_type, resource_key, verb, prior_state, next_state, diff, reason, actor_id, correlation_id`.

Verification: `Rulestead.Audit.verify_signature/1` returns `:ok | {:error, reason}`.

### 6.6 Export + import

- `Rulestead.Audit.export/2` streams events to `IO.Stream` as JSONL with optional signed manifest.
- `Rulestead.Audit.verify_export/1` re-checks signatures on a bundle.
- Export is CSV-escapable for regulated industries.

---

## 7. Debug surfaces

### 7.1 `/health` (plug)

```
GET /rulestead/health
→ 200 {
    "status": "ok",
    "snapshot_version": 2741,
    "snapshot_age_ms": 1250,
    "store_reachable": true,
    "cache_hit_rate_5m": 0.993,
    "fail_closed_events_5m": 0
  }
```

Returns 503 when snapshot age > threshold AND store is unreachable AND cache is cold. Never leaks PII. Tenants can gate visibility to internal networks only.

### 7.2 `/diagnostics` (admin UI)

Already covered in `rulestead-admin-ux-and-operator-ia.md` §3.12. It surfaces:
- fallthroughs (`:decide` with `reason: :default` high-volume = misconfig signal)
- stale snapshots per node
- fail-closed events
- hook health

### 7.3 `iex` helpers

```elixir
Rulestead.Debug.snapshot_info()
# => %{version: 2741, published_at: ~U[...], flag_count: 142}

Rulestead.Debug.cache_stats()
# => %{hit: 99_412, miss: 312, invalidate: 14, age_ms_p99: 4200}

Rulestead.Debug.explain("checkout_v2", %{actor_id: "u_123", env: :prod})
# => %{variant: "treatment", bucket: 4721, reason: :rule_match, matched_rule_index: 2, trace: [...]}

Rulestead.Debug.last_audit_events(limit: 20)
# reads the ledger with redaction applied
```

All debug functions apply redaction. None bypass policy checks for tenant scoping.

---

## 8. Default logging integration

Rulestead does **not** own logging. It emits telemetry; hosts forward to their logger.

We ship a default handler as opt-in:

```elixir
# In host Application.start/2:
Rulestead.Logger.attach_default(level: :info)
```

Default handler:
- Logs `:admin, *, :published|engaged|rolled_back` at `:info`.
- Logs `:exception` events at `:error` with formatted stacktrace.
- Logs `:stale_used`, `:fail_closed` at `:warning`.
- Never logs `:eval, :decide, :stop` (too noisy).
- Passes `trace_id`, `tenant_id`, `flag_key` as `Logger.metadata/1`.

Hosts can disable and wire custom logger handlers instead.

---

## 9. Correlation across events

The audit event `correlation_id` chains related mutations: a change-request submission → approval → publish → rollout-advance all share a `correlation_id`. Timeline UI groups by correlation.

Telemetry `trace_id` flows from `%Rulestead.Context{}` or is generated at the top of each public entrypoint.

```
HTTP request → Plug assigns trace_id → Ctx carries it →
  decide() emits [:eval, :decide, :*] with trace_id →
    if cache miss: emits [:eval, :cache, :miss] with same trace_id →
      Store.get emits [:repo, :query] with same trace_id
```

---

## 10. Sampling strategy (hot-path events)

`[:rulestead, :eval, :decide, :stop]` fires on every evaluation — hot path.

- **Per-event sampling:** default 100% (flip to <100% via config for massive-scale tenants).
- **Tagged metrics:** hosts choose which tags go into `Telemetry.Metrics` (drop `flag_key` at high-cardinality).
- **Impression sampling:** separate dial (default 1%).
- **Cache events:** always 100%.
- **Admin + audit events:** always 100%, never sampled.

```elixir
config :rulestead, :telemetry,
  sample_rate: %{
    [:rulestead, :eval, :decide, :stop] => 1.0,
    [:rulestead, :eval, :impression] => 0.01
  }
```

---

## 11. Privacy + redaction at emission

Before every event is emitted:

1. `context.traits` runs through `Rulestead.ContextRedactor`.
2. Redactor is behaviour-based; default impl drops known PII keys (`email`, `phone`, `ip`, etc.) + host-configured keys + any key matching a configured regex.
3. `actor_id` can be hashed per tenant config (useful for GDPR-style "pseudonymous analytics").
4. `value` in `:decide, :stop` is passed through redactor — strings containing emails or tokens are scrubbed.
5. Redaction is applied even to `:exception` events (stacktraces + error strings scanned for PII patterns).

Audit ledger events apply the same redaction to `prior_state` / `next_state` / `diff`.

---

## 12. Test hooks

`Rulestead.TestHelpers.telemetry/0`:

```elixir
test "publish emits ruleset.published with audit_event_id" do
  ref = attach_event_handlers([[:rulestead, :admin, :ruleset, :published]])

  {:ok, _ruleset} = Rulestead.Rulesets.publish(flag_key, attrs, ctx)

  assert_received {:telemetry, [:rulestead, :admin, :ruleset, :published], _meas, metadata, ^ref}
  assert metadata.flag_key == flag_key
  assert is_binary(metadata.audit_event_id)
end
```

`attach_event_handlers/1` hides the `:telemetry.attach_many/4` + `on_exit` detach boilerplate.

---

## 13. Backwards compatibility contract

Published in `api_stability.md`:

- **Event names:** stable. Renaming requires a deprecation period where the old name continues to emit alongside the new one for ≥2 minor versions.
- **Measurements:** additions allowed; removal/rename requires deprecation.
- **Metadata keys:** additions allowed; removal/rename requires deprecation. Renames in metadata are specifically called-out as breaking.
- **Event ordering:** `:start` before `:stop` before `:exception` (mutually exclusive with `:stop`).
- **Span metadata inheritance:** `:stop` metadata extends `:start` metadata (never contradicts).

Host-facing test suite `test/telemetry_contract_test.exs` asserts the event names, measurement keys, and metadata keys haven't drifted vs a fixture file.

---

## 14. Do / Don't

**Do:**
- Use `:telemetry.span/3` for everything spanning a public operation.
- Redact before emit — never rely on downstream consumers to redact.
- Cross-reference `audit_event_id` from telemetry metadata.
- Emit `:exception` events for hook failures without crashing the caller.
- Surface cardinality hazards in docs (e.g., `flag_key` tag on high-volume metrics).
- Version the event schema + enforce with a contract test.

**Don't:**
- Don't log on every evaluation by default.
- Don't bypass audit in admin mutations "for performance" — it's transactional for a reason.
- Don't ship event names that might need renaming — think twice before publishing.
- Don't mix telemetry with audit: telemetry is lossy, audit is complete.
- Don't emit raw PII in debug surfaces or explain views.
- Don't read from the audit ledger in evaluation hot paths.

---

## 15. TL;DR

- **Canonical event tree** rooted at `[:rulestead, ...]`, versioned as public API.
- **Span conventions** (`:start`/`:stop`/`:exception`) everywhere meaningful, via `:telemetry.span/3`.
- **Measurements vs metadata** discipline — no mixing.
- **OTel is an opt-in adapter**, not a hard dep; shipped as `Rulestead.OTel.setup/0`.
- **Impressions are separate, sampled, dedup-hashed**; exposures are the experimentation ground truth.
- **Append-only audit ledger** with Postgres trigger enforcement + optional HMAC signing — the durable record of truth distinct from ephemeral telemetry.
- **Debug surfaces** (`/health`, `/diagnostics`, `iex` helpers) always redact.
- **Correlation IDs + trace IDs** chain related events across admin + evaluation paths.
