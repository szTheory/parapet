# Parapet Recovery Actions Guide

Parapet is built around a simple conviction: knowing that a user journey is failing is only half the job. The other half is doing something about it safely — without guessing at blast radius, without running blind, and without bypassing the audit trail.

A recovery capability is how you wire that second half. It gives the operator a bounded, preview-first action that the workbench can surface during an incident — one that shows exactly what will change before committing, executes only after the operator confirms, and records the outcome in the immutable timeline regardless of success or failure.

This guide walks through how to decide when a recovery capability adds value, how to author and register one using `mix parapet.gen.recovery`, and what the error semantics look like when something goes wrong.

For the Operator UI's Preview → Confirm interaction flow, see [Preview-First Recovery](operator-ui.html#phase-7-preview-first-recovery) in the Operator UI guide.

## When to wire a recovery capability

Not every runbook step benefits from automation. Two of the six prebuilt playbooks Parapet ships are intentionally guidance-only: the retry storm and suppression drift playbooks name specific automated mitigations that would worsen the incident rather than resolve it. Retrying into a storm increases queue pressure. Bulk-clearing suppressions risks mass-escalation of already-handled alerts.

Use this decision frame to decide whether a step warrants a capability:

- **Is there a bounded, reversible mutation that stops the failure?**
  - Yes → a capability is appropriate. Continue.
    - **Is the blast radius small enough to preview concisely?** (e.g., "This will retry 3 jobs" vs. "This will affect all 12 000 users in the flag cohort")
      - Concise → wire the capability. Preview will surface the count and target refs.
      - Unclear → author the preview step to expose the scope explicitly before asking for confirm.
    - **Is the operation safe to retry if the operator confirms twice by mistake?**
      - Yes → standard capability.
      - No → add idempotency guards in `execute/2`.
  - No (investigation-only, or automation makes it worse) → guidance-only step, no capability needed.

**Guidance-only is the correct choice when:**

- The right action is "look at your APM and decide" — no programmatic action fits.
- Automating the mitigation would compound the failure (retry storm, suppression drift).
- The affected scope cannot be bounded at preview time.

**Capability-backed is the correct choice when:**

- There is exactly one safe mutation that resolves the failure mode.
- You can compute the preview cheaply and display it meaningfully to the operator.
- The operation can be scoped to specific `target_refs` (job IDs, flag names, label keys).

## Authoring a recovery capability

### Generate the scaffold

Run the generator with the module name you want:

```bash
mix parapet.gen.recovery RetryAsyncItem
```

This creates two files:

- `lib/<your_app>/parapet/recovery/retry_async_item.ex` — the capability module
- `test/<your_app>/parapet/recovery/retry_async_item_test.exs` — the test stub

The generator uses `on_exists: :skip` — running it twice on the same name is safe and will not overwrite edits you have already made.

### The four frozen callbacks

A recovery capability module implements the `Parapet.Recovery` behaviour. The four callbacks are part of the Stable contract and are frozen for the 1.x line:

```elixir
defmodule MyApp.Parapet.Recovery.RetryAsyncItem do
  use Parapet.Recovery

  @impl true
  def id, do: :retry_async_item

  @impl true
  def label, do: "Retry Async Item"

  @impl true
  def preview(incident, step) do
    target_refs = step["target_refs"] || []
    count = length(target_refs)

    {:ok, %{
      summary: "Will retry #{count} stalled item(s) linked to this incident.",
      count: count,
      target_refs: target_refs,
      preconditions: ["Item must be in :executing or :scheduled state"],
      warnings: ["Retrying without root-cause confirmation may reproduce the deadlock"]
    }}
  end

  @impl true
  def execute(incident, target_refs) do
    # Perform the mutation. Return {:ok, result} on success, {:error, reason} on failure.
    results = Enum.map(target_refs, &MyApp.Jobs.retry_item/1)
    {:ok, %{retried: length(results), refs: target_refs}}
  end
end
```

**`id/0`** — returns the capability atom. Must be one of the five allowlisted atoms declared in `Parapet.Capabilities`:

- `:retry_async_item`
- `:requeue_dead_letter`
- `:request_manual_provider_check`
- `:revert_feature_flag`
- `:disable_metric_label`

Returning an atom outside this list raises `ArgumentError` at `Parapet.Capabilities.register_recovery/2` when `attach/1` runs at boot. This is intentional — the allowlist enforces that only explicitly bounded operations can be wired as operator-executable mitigations.

**`label/0`** — returns the display name shown in the Operator UI action panel. Keep it short and action-oriented: `"Retry Async Item"`, not `"Handles retry logic for async work items"`.

**`preview/2`** — receives the incident and the runbook step map. Should return `{:ok, preview_map}` where the map contains enough information for the operator to assess scope and decide whether to confirm. Recommended keys: `count`, `target_refs`, `summary`, `preconditions`, `warnings`. Return `{:error, reason}` if the preview cannot be computed (e.g., no target refs attached to the incident). Preview is called before any mutation — it must be read-only.

**`execute/2`** — receives the incident and the target refs array confirmed in the preview step. Performs the mutation. Return `{:ok, result_map}` on success or `{:error, reason}` on failure. Parapet records the outcome either way: `{:ok, _}` writes a `recovery_confirmed` timeline entry, `{:error, _}` writes a `recovery_failed` timeline entry and releases the claim without a lockout window.

### Registering at boot

Call `Parapet.Recovery.attach/1` in your application's `start/2` callback (after `Parapet.attach/1`):

```elixir
def start(_type, _args) do
  Parapet.attach(adapters: [MyApp.Parapet.Integrations.Sigra])

  {:ok, _} =
    Parapet.Recovery.attach([
      MyApp.Parapet.Recovery.RetryAsyncItem,
      MyApp.Parapet.Recovery.RequeueDeadLetter
    ])

  # ... rest of supervision tree
end
```

`attach/1` silently skips any module where `Code.ensure_loaded?/1` returns false — the same optional-dependency pattern used by `Parapet.attach/1`. Passing a module that has not been compiled (e.g., an integration module absent from your deps) is safe.

### Verifying adoption with mix parapet.doctor

Run the recovery check after wiring your capabilities:

```bash
mix parapet.doctor recovery
```

The check reports three signals:

1. **Zero capabilities registered** → `:skip` (not a warning; a fresh install with no capabilities is expected and does not fail `--ci`).
2. **Runbook step references an unregistered capability atom** → `:warn`. This means a runbook step has `capability: :retry_async_item` but no module has been attached for that atom.
3. **Registered capability module missing a callback** → `:warn`. This means the module was attached but does not implement all four frozen callbacks.

For CI integration:

```bash
mix parapet.doctor --ci recovery
```

With `--ci`, the doctor exits `1` for `:warn` findings — catching misconfigured capabilities before they reach production.

## Preview/Confirm UX

The Operator UI implements a three-state flow for capability-backed runbook steps: Guidance → Preview → Confirm. The UI renders the preview map returned by your `preview/2` callback, including the summary, count, target refs, preconditions, and warnings. The operator reviews and then clicks Confirm to execute.

For the complete interaction flow — including the action panel layout, warning rendering, and how the UI handles the short-circuit and conflict cases — see [Preview-First Recovery](operator-ui.html#phase-7-preview-first-recovery) in the Operator UI guide.

The preview step is time-bounded (5 minutes). If the operator does not confirm within the window, the next Confirm attempt returns `{:short_circuited, :preview_expired}`.

## Error semantics

Three outcome variants extend the base `{:ok, result}` path of `confirm_runbook_step/4`. All three are additive and are part of the Stable contract for the 1.x line. If you pattern-match on the return value of `Parapet.Operator.confirm_runbook_step/4`, you must handle all three:

### `{:short_circuited, reason}`

The action was not executed. Possible reasons:

- `:breaker_open` — the Ecto-backed circuit breaker for this capability has tripped (too many recent failures on the action type). The operator should investigate and reset the breaker before retrying.
- `:incident_state_changed` — the incident moved to a terminal state (e.g., `:resolved`) between the operator clicking Preview and clicking Confirm. No mutation occurred; safe to ignore.
- `:preview_expired` — the 5-minute preview window elapsed before the operator confirmed. The operator should request a fresh preview and confirm again.

No timeline entry is written for short-circuits — nothing was executed.

### `{:conflicted, claim_id}`

Another node in the cluster already holds the action claim for this capability + incident combination. This is the multi-node safety guard: Parapet uses an Ecto-backed lease to ensure only one node executes a given recovery action on a given incident at a time. The operator should wait for the concurrent action to complete (or for the lease to expire) before retrying.

No timeline entry is written for conflicts — nothing was executed.

### `:recovery_failed` timeline entry type

When `execute/2` returns `{:error, reason}`, Parapet writes a `recovery_failed` `TimelineEntry` (type `:recovery_failed`) with the failure reason and the operator identity. The claim is released immediately — no lockout window. The operator can attempt a fresh confirm after investigating the failure reason.

The `recovery_failed` entry appears in the retrospective generator's chronology alongside `recovery_confirmed` entries. Both entry types are documented in [Stability & Deprecation Policy](stability.html) as part of the additive 1.x Stable contract.

## Worked examples

### Stalled Async — `:retry_async_item`

**Scenario:** Background jobs are stuck in the `:executing` state after a worker crash. The SLO error budget is burning and the queue backlog is growing.

The `StalledExecutor` runbook template ships with a `:retry_item` step using `capability: :retry_async_item`. Wire the capability to your job backend:

```elixir
defmodule MyApp.Parapet.Recovery.RetryAsyncItem do
  use Parapet.Recovery

  def id, do: :retry_async_item
  def label, do: "Retry Async Item"

  def preview(_incident, step) do
    target_refs = step["target_refs"] || []
    count = length(target_refs)

    {:ok, %{
      summary: "Will reschedule #{count} stalled item(s) for immediate retry.",
      count: count,
      target_refs: target_refs,
      preconditions: ["Items must be in :executing or :scheduled state"],
      warnings: [
        "Do not retry if the worker is still executing — this will cause a duplicate. " <>
          "Confirm the worker process has terminated before proceeding."
      ]
    }}
  end

  def execute(_incident, target_refs) do
    Enum.each(target_refs, fn job_id ->
      Oban.retry_job(String.to_integer(job_id))
    end)

    {:ok, %{retried: length(target_refs)}}
  end
end
```

**Preview map guidance:** Include the specific job IDs as `target_refs` so the operator can see exactly which jobs will be retried. The `warnings` key surfaces the duplicate-execution risk.

---

### Dead-Letter Drain — `:requeue_dead_letter`

**Scenario:** Items have permanently failed processing and accumulated in the dead-letter queue. The root cause (e.g., schema mismatch) has been resolved and the items need to be reprocessed.

The `DeadLetter` runbook template ships with a `:requeue_item` step using `capability: :requeue_dead_letter`.

```elixir
defmodule MyApp.Parapet.Recovery.RequeueDeadLetter do
  use Parapet.Recovery

  def id, do: :requeue_dead_letter
  def label, do: "Requeue Dead Letter"

  def preview(_incident, step) do
    target_refs = step["target_refs"] || []
    items = Enum.map(target_refs, &MyApp.Jobs.fetch_dead_letter/1)
    count = length(items)

    {:ok, %{
      summary: "Will move #{count} dead-lettered item(s) back to the processing queue.",
      count: count,
      target_refs: target_refs,
      preconditions: [
        "Root cause of the original failure must be resolved before requeuing"
      ],
      warnings: [
        "Requeued items will be re-processed from the start. " <>
          "Confirm the operation is idempotent or that any partial side effects have been reversed."
      ]
    }}
  end

  def execute(_incident, target_refs) do
    Enum.each(target_refs, fn item_id ->
      Oban.retry_job(String.to_integer(item_id))
    end)

    {:ok, %{requeued: length(target_refs)}}
  end
end
```

**Preview map guidance:** Name the specific items being requeued. Call out the idempotency requirement explicitly in `warnings` — dead-letter requeue is the most common source of accidental duplicate side effects.

---

### Deploy-Tied Incident — `:revert_feature_flag`

**Scenario:** Error rates spiked immediately after a feature-flag activation. The `DeployTiedIncident` runbook template has correlated the incident with the flag change. The operator wants to roll back the flag.

The `DeployTiedIncident` runbook ships with a `:revert_flag` step using `capability: :revert_feature_flag`. This capability is typically provided by your Rulestead integration (Parapet's feature-flag change-correlation adapter):

```elixir
defmodule MyApp.Parapet.Recovery.RevertFeatureFlag do
  use Parapet.Recovery

  def id, do: :revert_feature_flag
  def label, do: "Revert Feature Flag"

  def preview(_incident, step) do
    flag_key = step["flag_key"] || step["target_refs"] |> List.first()
    current_state = Rulestead.flag_state(flag_key)
    affected_cohort = Rulestead.flag_cohort_size(flag_key)

    {:ok, %{
      summary: "Will revert '#{flag_key}' from '#{current_state}' to disabled.",
      target_refs: [flag_key],
      preconditions: ["Flag must be currently enabled"],
      warnings: [
        "This will affect #{affected_cohort} users in the current rollout cohort.",
        "If the flag controls a database migration path, coordinate a migration rollback before reverting."
      ]
    }}
  end

  def execute(_incident, target_refs) do
    flag_key = List.first(target_refs)
    :ok = Rulestead.disable_flag(flag_key)
    {:ok, %{reverted: flag_key}}
  end
end
```

**Preview map guidance:** Surface the blast radius (cohort size) in `warnings`. The operator needs to know how many users will be affected by the flag revert before confirming. Include the specific flag key in `target_refs` so the timeline entry records exactly what was reverted.

---

### Cardinality Blowout — `:disable_metric_label`

**Scenario:** A metric label is emitting unbounded values (user IDs, trace IDs, request IDs) and the TSDB series count is exploding. `mix parapet.doctor cardinality` has identified the offending label.

The `CardinalityBlowout` runbook template ships with a `:disable_label` step using `capability: :disable_metric_label`.

```elixir
defmodule MyApp.Parapet.Recovery.DisableMetricLabel do
  use Parapet.Recovery

  def id, do: :disable_metric_label
  def label, do: "Disable Metric Label"

  def preview(_incident, step) do
    label_key = step["target_refs"] |> List.first()
    affected_metrics = MyApp.Metrics.metrics_with_label(label_key)
    alert_rules = MyApp.Metrics.alert_rules_referencing_label(label_key)

    {:ok, %{
      summary: "Will disable label '#{label_key}' across #{length(affected_metrics)} metric(s).",
      target_refs: [label_key],
      count: length(affected_metrics),
      preconditions: ["Label source must be corrected to emit bounded values after disabling"],
      warnings: [
        "Disabling this label will break #{length(alert_rules)} Prometheus alert rule(s) that filter on '#{label_key}'.",
        "Coordinate with your observability team before confirming.",
        "After disabling, trigger a scrape cycle and verify TSDB series count is declining."
      ]
    }}
  end

  def execute(_incident, target_refs) do
    label_key = List.first(target_refs)
    :ok = MyApp.Metrics.disable_label(label_key)
    {:ok, %{disabled_label: label_key}}
  end
end
```

**Preview map guidance:** Enumerate the downstream impact (affected alert rules, dashboard panels) so the operator can coordinate before confirming. Cardinality disable is the highest-blast-radius capability — the preview is the primary safety gate.

---

## What not to do

These are the failure modes that turn a recovery capability into a liability.

- **Swallow errors silently in `execute/2`.** If your execute returns `{:ok, %{}}` on failure, Parapet writes a success audit entry and the operator sees a green confirm. The incident stays open, the root cause is unresolved, and the timeline shows a false success. Always return `{:error, reason}` when the mutation did not succeed — Parapet will write a `recovery_failed` entry and release the claim for retry.

- **Use a capability as a generic admin escape hatch.** Recovery capabilities are scoped to the specific failure modes in the allowlist. They are not an arbitrary command runner. If you find yourself wanting a capability that accepts freeform input or executes unrelated operations, it belongs in a custom admin UI, not in a Parapet runbook step.

- **Return an atom outside the five-atom allowlist from `id/0`.** The allowlist is not a soft convention — it is a compile-time-enforced contract. `Parapet.Capabilities.register_recovery/2` raises `ArgumentError` for any non-allowlisted atom. If your use case genuinely requires a new capability type, open a GitHub issue to discuss extending the allowlist in a future minor version.

- **Make `preview/2` perform mutations.** Preview is called before the operator confirms — it is explicitly read-only. Any mutation in `preview/2` (writes, state changes, external API calls with side effects) will execute before the operator has reviewed the scope. Preview must be safe to call multiple times.

- **Skip the `target_refs` contract.** The `target_refs` list is what connects the operator's confirm to the specific objects being acted on. An empty `target_refs` list makes the preview look like a no-op and causes the execute to act on zero items. Always populate `target_refs` in `preview/2` so the operator can see exactly what will change, and always iterate `target_refs` in `execute/2` rather than re-querying the scope.
