# Phase 4: Async & Delivery Telemetry Contracts - Pattern Map

**Mapped:** 2026-05-17
**Phase context:** `.planning/v0.7-phases/4/4-CONTEXT.md`
**Primary goal:** freeze a bounded async/delivery event contract for `Mailglass`, `Chimeway`, and `Rindle` without leaking provider payload shape or high-cardinality labels.

## Files analyzed

- `lib/parapet/integrations/mailglass.ex`
- `lib/parapet/integrations/chimeway.ex`
- `lib/parapet/integrations/rindle.ex`
- `lib/parapet/internal/label_policy.ex`
- `lib/parapet/metrics/scoria.ex`
- `test/parapet/integrations/mailglass_test.exs`
- `test/parapet/integrations/chimeway_test.exs`
- `test/parapet/integrations/rindle_test.exs`
- `test/parapet/internal/label_policy_test.exs`

## Stronger in-repo analogs to mirror

These are more relevant than the current thin Phase 3 adapters when planning Phase 4:

| Target area | Best analog | Why it matters |
|---|---|---|
| Multi-event adapter contract | `lib/parapet/integrations/sigra.ex` | Uses `:telemetry.attach_many/4`, maps multiple upstream states into one bounded downstream vocabulary. |
| Mixed event-family translation | `lib/parapet/integrations/accrue.ex` | Shows separate event families (`billing`, `checkout`, `webhook`) with normalized metadata per family. |
| Allowlisted metadata translation | `lib/parapet/integrations/scoria.ex` | Uses `Map.take/2` and computed normalized fields instead of pass-through metadata. |
| Crash-safe handler attachment | `lib/parapet/internal/safe_handler.ex` and `lib/parapet.ex` | Centralized rescue wrapper exists already; Phase 4 should prefer it over per-module rescue duplication. |
| Metrics/tag discipline | `lib/parapet/metrics/scoria.ex`, `lib/parapet/metrics/oban.ex`, `lib/parapet/metrics/exemplar_telemetry.ex` | Existing repo pattern is bounded tags plus explicit tag extraction. |

## File classification and likely touch points

| File | Role | Data flow | Closest analog | Match quality | Planning note |
|---|---|---|---|---|---|
| `lib/parapet/integrations/mailglass.ex` | integration adapter | event-driven | `lib/parapet/integrations/accrue.ex` | role+flow | Expand from one upstream failure event into normalized delivery and possibly async families. |
| `lib/parapet/integrations/chimeway.ex` | integration adapter | event-driven | `lib/parapet/integrations/accrue.ex` | role+flow | Same seam as Mailglass, but likely biased toward webhook/provider feedback events. |
| `lib/parapet/integrations/rindle.ex` | integration adapter | event-driven | `lib/parapet/integrations/sigra.ex` | role+flow | Already maps multiple states; Phase 4 should normalize to bounded async outcomes. |
| `lib/parapet/internal/label_policy.ex` | utility/policy | transform | `lib/parapet/metrics/scoria.ex` + `lib/parapet/metrics/exemplar_telemetry.ex` | partial | Current denylist should shift toward explicit allowlists per normalized event family. |
| `lib/parapet.ex` | public API / activation seam | request-response to event attachment | itself + `lib/parapet/internal/safe_handler.ex` | exact | Keep host-owned adapter activation model intact. |
| `lib/parapet/internal/safe_handler.ex` | utility | event-driven | itself | exact | Likely reusable if Phase 4 moves integrations to `Parapet.attach/1` map form. |
| `test/parapet/integrations/mailglass_test.exs` | test | event-driven | `test/parapet/integrations/scoria_test.exs` | role+flow | Add multi-event assertions, sanitized metadata assertions, and attachment assertions. |
| `test/parapet/integrations/chimeway_test.exs` | test | event-driven | `test/parapet/integrations/scoria_test.exs` | role+flow | Mirror normalized public event families, not old `:journey` names. |
| `test/parapet/integrations/rindle_test.exs` | test | event-driven | `test/parapet/integrations/scoria_test.exs` | role+flow | Assert outcome normalization and dropped refs/unsafe labels. |
| `test/parapet/internal/label_policy_test.exs` | test | transform | itself + `test/parapet/metrics/scoria_test.exs` | partial | Replace regex-only rejection tests with contract allowlist tests per family. |

## Concrete reusable patterns

### 1. Adapter activation stays explicit and optional

**Copy from:** `lib/parapet.ex:21-37`

```elixir
def attach(opts) when is_list(opts) do
  adapters = Keyword.get(opts, :adapters, [])

  Enum.each(adapters, fn adapter ->
    module_name =
      adapter
      |> to_string()
      |> Macro.camelize()

    module = Module.concat(Parapet.Integrations, module_name)

    if Code.ensure_loaded?(module) do
      apply(module, :setup, [])
    end
  end)

  {:ok, adapters}
end
```

**Use in Phase 4**

- Keep `setup/0` as the adapter entrypoint.
- Do not introduce hidden auto-discovery.
- New contract modules can exist internally, but host activation should still flow through `Parapet.attach(adapters: [...])`.

### 2. Prefer one handler id per related event family via `attach_many/4`

**Copy from:** `lib/parapet/integrations/sigra.ex:12-23`

```elixir
:telemetry.attach_many(
  "parapet-sigra-auth",
  [
    [:sigra, :auth, :login, :stop],
    [:sigra, :auth, :login, :exception],
    [:sigra, :auth, :signup, :stop],
    [:sigra, :auth, :signup, :exception]
  ],
  &__MODULE__.handle_event/4,
  nil
)
```

**And from:** `lib/parapet/integrations/accrue.ex:27-35`

```elixir
:telemetry.attach_many(
  "parapet-accrue-billing-checkout-webhook",
  [
    [:accrue, :billing, :checkout, :stop],
    [:accrue, :billing, :checkout, :exception],
    [:accrue, :billing, :webhook, :stop],
    [:accrue, :billing, :webhook, :exception]
  ],
  &__MODULE__.handle_event/4,
  nil
)
```

**Use in Phase 4**

- Mailglass and Chimeway should likely attach related delivery/provider-feedback/webhook event sets with `attach_many/4`.
- Rindle may need grouped async lifecycle events rather than one handler per terminal state.
- This matches `D-26` in the phase context and keeps the public namespace narrow.

### 3. Translation should happen through explicit event-pattern clauses

**Copy from:** `lib/parapet/integrations/accrue.ex:67-90`

```elixir
defp process_event([:accrue, :billing, :checkout, state], measurements, metadata)
     when state in [:stop, :exception] do
  outcome = if state == :stop, do: :success, else: :failure
  plan = Map.get(metadata, :plan, "unknown")

  parapet_metadata = %{outcome: outcome, plan: plan}

  :telemetry.execute(
    [:parapet, :journey, :billing, :checkout],
    measurements,
    parapet_metadata
  )
end
```

**And from:** `lib/parapet/integrations/sigra.ex:40-67`

```elixir
defp process_event([:sigra, :auth, :login, state], measurements, _metadata)
     when state in [:stop, :exception] do
  outcome = if state == :stop, do: :success, else: :failure

  parapet_metadata = %{outcome: outcome}

  :telemetry.execute(
    [:parapet, :journey, :login],
    %{duration: measurements.duration},
    parapet_metadata
  )
end
```

**Use in Phase 4**

- Model the new public contract with multiple `process_event/3` clauses keyed by upstream event shape.
- Compute normalized `outcome`, `fault_plane`, `retry_state`, `delay_bucket`, or `pipeline_stage` in those clauses.
- Keep a catch-all clause returning `:ok`.
- Avoid generic pass-through adapters; current Mailglass and Chimeway are too thin to copy directly.

### 4. Use allowlisted metadata extraction, not pass-through maps

**Copy from:** `lib/parapet/integrations/scoria.ex:71-84`

```elixir
safe_metadata = Map.take(metadata, @safe_labels)

has_error? = Map.has_key?(metadata, :error) and not is_nil(metadata.error)
outcome = if has_error?, do: :failure, else: :success

parapet_metadata = Map.put(safe_metadata, :outcome, outcome)

:telemetry.execute(
  [:parapet, :scoria, :metrics],
  measurements,
  parapet_metadata
)
```

**And from:** `lib/parapet/metrics/scoria.ex:27-34`

```elixir
sanitized_metadata = Map.take(metadata, [:guardrail, :passed, :model_name])

:telemetry.execute(
  [:parapet, :scoria, :eval, :completed],
  measurements,
  sanitized_metadata
)
```

**Use in Phase 4**

- This is the key pattern for `D-16` through `D-22`.
- Public metadata should be built from an allowlisted set of bounded keys.
- Put high-cardinality values under `metadata.refs` or drop them from emitted public telemetry entirely.
- Do not repeat the current `Rindle` pattern of `Map.put(metadata, :outcome, outcome)` for public delivery/async events.

### 5. Crash-safe handler attachment already has a reusable home

**Copy from:** `lib/parapet/internal/safe_handler.ex:5-19`

```elixir
def attach(handler_id, event_name, handler_module, function_name, config \\ %{}) do
  :telemetry.attach(
    handler_id,
    event_name,
    fn event, measurements, metadata, conf ->
      try do
        apply(handler_module, function_name, [event, measurements, metadata, conf])
      rescue
        e ->
          Logger.error(
            "Parapet telemetry handler exception in #{inspect(handler_module)}.#{function_name}/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
          )
      end
    end,
    config
  )
end
```

**And activation path from:** `lib/parapet.ex:40-67`

```elixir
case SafeHandler.attach(
       handler_id,
       event_name,
       handler_module,
       function_name,
       config
     ) do
  :ok ->
    Logger.debug("Parapet attached telemetry handler #{handler_id}")
    {:ok, [handler_id]}

  {:error, _} = error ->
    error
end
```

**Use in Phase 4**

- Existing integrations duplicate `rescue` logic inside `handle_event/4`.
- Planner should consider consolidating attachment through `Parapet.attach/1` map form or a similar shared helper.
- Even if modules keep `handle_event/4`, crash-safety must remain explicit and tested.

### 6. Metrics and exemplars use explicit tag extraction

**Copy from:** `lib/parapet/metrics/oban.ex:38-59`

```elixir
LabelPolicy.assert_safe!([:worker, :queue, :state])

[
  counter("parapet.oban.jobs.total",
    event_name: [:parapet, :oban, :job],
    tags: [:worker, :queue, :state],
    description: "Total number of Oban jobs processed"
  ),
  distribution("parapet.oban.job.duration_ms",
    event_name: [:parapet, :oban, :job],
    measurement: :duration_ms,
    tags: [:worker, :queue, :state],
    description: "Duration of Oban jobs in milliseconds",
    reporter_options: [
      buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000, 10_000]
    ]
  )
]
```

**And from:** `lib/parapet/metrics/exemplar_telemetry.ex:22-35`

```elixir
case Map.get(metadata, :trace_id) do
  nil -> :ok
  trace_id when is_binary(trace_id) ->
    tags = Map.take(metadata, [:worker, :queue, :state])
    ExemplarStore.record_trace("parapet_oban_job_duration_ms", tags, trace_id)
end
```

**Use in Phase 4**

- Public contract labels should be a fixed list consumed by later metrics modules.
- Explicit `Map.take/2` on the emitted metadata is the repo’s safest pattern.
- Delay/raw duration may exist as measurements, but not as tags.

## Current code to reuse carefully

### `Mailglass` and `Chimeway`

**Source:** `lib/parapet/integrations/mailglass.ex:12-44`, `lib/parapet/integrations/chimeway.ex:12-44`

Reusable:

- `setup/0` and `handle_event/4` as the integration seam.
- one-direction upstream-to-Parapet translation model.

Do not copy forward unchanged:

- single-event-only attachment.
- public event name `[:parapet, :journey, :mail_delivery]`.
- hardcoded `%{outcome: :failure}` with no bounded provider/fault-plane metadata.

### `Rindle`

**Source:** `lib/parapet/integrations/rindle.ex:40-52`

Reusable:

- translating multiple upstream terminal states from one clause.

Do not copy forward unchanged:

- `Map.put(metadata, :outcome, outcome)` leaks unsanitized metadata into public telemetry.
- `:success` / `:failure` is too coarse for the Phase 4 async vocabulary.

## Likely implementation touch points

### 1. Integration adapters

- `lib/parapet/integrations/mailglass.ex`
- `lib/parapet/integrations/chimeway.ex`
- `lib/parapet/integrations/rindle.ex`

Expected changes:

- switch from journey event emission to new `[:parapet, :delivery, ...]` and `[:parapet, :async, ...]` families.
- normalize upstream states into bounded public outcomes.
- emit bounded top-level metadata plus ref-shaped evidence fields where needed.

### 2. Shared safety/translation support

- `lib/parapet/internal/label_policy.ex`
- `lib/parapet/internal/safe_handler.ex`
- `lib/parapet.ex`

Expected changes:

- replace denylist-only safety with public-contract allowlists or event-family-specific validation.
- possibly centralize safe attachment instead of repeating rescue blocks.

### 3. Metrics follow-through

- `lib/parapet/metrics/scoria.ex` as the best translation/sanitization analog.
- likely new metrics modules later, but Phase 4 should at least leave a stable contract they can consume.

Expected changes:

- planner should preserve the repo rule that metrics definitions validate tags explicitly before registration.

## Tests the planner should mirror

### 1. Subscribe to downstream public events and assert translation end-to-end

**Pattern from:** `test/parapet/integrations/mailglass_test.exs:4-18`, `test/parapet/integrations/chimeway_test.exs:4-18`, `test/parapet/integrations/rindle_test.exs:4-22`

```elixir
:telemetry.attach(
  handler_id,
  [:parapet, ...],
  fn name, measurements, metadata, _config ->
    send(test_pid, {:telemetry_event, name, measurements, metadata})
  end,
  nil
)
```

Mirror in Phase 4:

- attach to each new public family under `[:parapet, :delivery, ...]` and `[:parapet, :async, ...]`.
- assert exact event name, measurements, and normalized metadata.
- detach in `on_exit/1`.

### 2. Assert unsafe metadata is removed, not merely ignored

**Pattern from:** `test/parapet/integrations/mailglass_test.exs:36-44`, `test/parapet/integrations/chimeway_test.exs:36-41`, `test/parapet/metrics/scoria_test.exs:46-59`, `test/parapet/integrations/scoria_test.exs:92-105`

Mirror in Phase 4:

- `refute Map.has_key?(metadata, :email)`
- `refute Map.has_key?(metadata, :trace_id)`
- assert only contract-approved keys survive.
- add tests for `_ref` placement if Phase 4 emits `metadata.refs`.

### 3. Assert handler registration exists for the intended upstream events

**Pattern from:** `test/parapet/integrations/scoria_test.exs:77-78`

```elixir
handlers = :telemetry.list_handlers([:scoria, :sre, :telemetry])
assert Enum.any?(handlers, fn h -> h.id == "parapet-scoria-telemetry" end)
```

Mirror in Phase 4:

- verify Mailglass, Chimeway, and Rindle setup attaches the expected grouped handlers.
- especially important if planner moves to `attach_many/4`.

### 4. Assert crash-safety as contract behavior

**Pattern from:** `test/parapet/internal/safe_handler_test.exs:31-57`

Mirror in Phase 4:

- execute a telemetry event that causes translation code to raise.
- assert host execution does not crash.
- capture log and assert the rescue path logs the failure.

### 5. Replace label-policy regex tests with event-contract allowlist tests

**Current baseline:** `test/parapet/internal/label_policy_test.exs:6-69`

Mirror in Phase 4:

- positive tests for the exact allowed top-level fields:
  `integration`, `provider`, `channel`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, `delay_bucket`, `retry_state`, `fault_plane`
- negative tests for unsafe keys like `message_id`, `recipient_email`, raw provider payload fields, and unapproved queue variants.
- if `refs` are part of the public schema, test that `_ref` keys are permitted there but rejected as label tags.

### 6. Assert outcome vocabulary, not just success/failure

New test coverage Phase 4 should add:

- delivery outcomes:
  `attempted`, `provider_accepted`, `delivered`, `failed`, plus supported extensions like `bounced`, `complained`, `suppressed`
- async outcomes:
  `started`, `succeeded`, `retryable_failed`, `discarded`, `delayed`
- distinction tests:
  `provider_accepted != delivered`
  `retryable_failed != discarded`
  webhook delay/backlog planes do not collapse into generic provider failure

## Shared rules the planner should preserve

- Telemetry is treated as API, so public event names and top-level metadata need to be narrow and explicit.
- Measurements stay numeric and compact; labels stay bounded and allowlisted.
- Adapter-specific rich payloads are not public contract.
- Compile-out and explicit host activation are existing repo doctrine and should not change.
- Catch-all event clauses should return `:ok`.

## No local project-specific override files found

- No `CLAUDE.md` present at repo root.
- No `.claude/skills/` or `.agents/skills/` directories present in this repo.

## Completion

`PATTERN MAPPING COMPLETE`  
Phase 4 pattern map is ready for the planner.
