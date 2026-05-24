# Phase 17: Recovery Depth — Runbook Templates - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 13 (4 modified source files, 3 new template files, 3 modified test files, 1 modified generator, 1 modified UI template, 1 modified workbench contract)
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/runbook.ex` | DSL macro | transform | self (surgical addition) | exact |
| `lib/parapet/operator/workbench_contract.ex` | service/projection | transform | self (surgical addition) | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | UI template | request-response | self — guidance block at lines 293–297 | exact |
| `priv/templates/parapet.gen.runbooks/dead_letter.ex.eex` | runbook template | transform | self (deepen existing) | exact |
| `priv/templates/parapet.gen.runbooks/callback_delay.ex.eex` | runbook template | transform | self (deepen existing) | exact |
| `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` | runbook template | transform | self (deepen existing) | exact |
| `priv/templates/parapet.gen.runbooks/provider_outage.ex.eex` | runbook template | transform | self (deepen existing) | exact |
| `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex` | runbook template | transform | `stalled_executor.ex.eex` (guidance-only mitigation variant) | role-match |
| `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex` | runbook template | transform | `callback_delay.ex.eex` (guidance-only, no capability) | role-match |
| `priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex` | runbook template | transform | `stalled_executor.ex.eex` (`:retry_async_item` + `:async_item`) | exact |
| `lib/mix/tasks/parapet.gen.runbooks.ex` | generator / mix task | batch | self (add three `copy_template` calls) | exact |
| `test/parapet/runbook_test.exs` | test | — | self (extend DummyRunbook + schema assertion) | exact |
| `test/parapet/operator/workbench_contract_test.exs` | test | — | self (extend projection fixture) | exact |
| `test/mix/tasks/parapet.gen.runbooks_test.exs` | test | — | self (add file-path + content assertions) | exact |

---

## Pattern Assignments

### `lib/parapet/runbook.ex` — add `warning:` to `step/2` macro + add `@doc`

**Analog:** self — surgical insertion at line 32 and new `@doc` above line 19.

**Current `step/2` macro** (`lib/parapet/runbook.ex` lines 19–35) — this is the exact block to modify:

```elixir
defmacro step(id, opts) do
  quote do
    @steps %{
      id: unquote(id),
      label: unquote(opts)[:label],
      description: unquote(opts)[:description],
      type: unquote(opts)[:type],
      kind: unquote(opts)[:kind],
      capability: unquote(opts)[:capability],
      target_kind: unquote(opts)[:target_kind],
      requires_preview: Keyword.get(unquote(opts), :requires_preview, false),
      preview_only: Keyword.get(unquote(opts), :preview_only, false),
      auto_execute: Keyword.get(unquote(opts), :auto_execute, false),
      guidance: unquote(opts)[:guidance]
    }
  end
end
```

**Action:** Add `warning: unquote(opts)[:warning]` after the `guidance:` line (line 32). The resulting map will have 12 keys.

**`execute_mitigation/2` overridable default** (`lib/parapet/runbook.ex` lines 14–15) — shows the `__using__` block structure for context; no change needed here:

```elixir
def execute_mitigation(_step, _incident), do: {:error, :not_implemented}
defoverridable execute_mitigation: 2
```

**`__before_compile__/1`** (`lib/parapet/runbook.ex` lines 49–64) — no change needed; `Macro.escape(steps)` at line 60 carries the full `@steps` map automatically once the macro map is extended:

```elixir
defmacro __before_compile__(env) do
  steps = Module.get_attribute(env.module, :steps) |> Enum.reverse()
  title = Module.get_attribute(env.module, :title, "Runbook")
  desc = Module.get_attribute(env.module, :description, "")

  quote do
    def __runbook_schema__() do
      %{
        module: to_string(__MODULE__),
        title: unquote(title),
        description: unquote(desc),
        steps: unquote(Macro.escape(steps))
      }
    end
  end
end
```

**D-12 doc requirement:** Add a `@doc` immediately before `defmacro step(id, opts)` at line 19. No `@doc` currently exists on this macro. The doc must list all accepted options including the new `warning:`. Mirror the `@moduledoc` style at lines 2–6.

---

### `lib/parapet/operator/workbench_contract.ex` — add `warning:` to projection map

**Analog:** self — surgical insertion at line 152 (after `guidance:`, before `state:`).

**Current projection map** (`lib/parapet/operator/workbench_contract.ex` lines 144–156) — the exact block to modify:

```elixir
%{
  id: step_id,
  label: Map.get(step, "label"),
  description: Map.get(step, "description"),
  type: Map.get(step, "type"),
  kind: Map.get(step, "kind"),
  capability: Map.get(step, "capability"),
  target_kind: target_kind,
  guidance: Map.get(step, "guidance"),
  state: state,
  executed_at: if(executed_entry, do: executed_entry.inserted_at),
  targeting_hints: targeting_hints
}
```

**Action:** Add `warning: Map.get(step, "warning"),` after `guidance: Map.get(step, "guidance"),` (line 152) and before `state: state,` (line 153). The string key `"warning"` matches the `stringify_keys/1` output (lines 226–228 convert atom keys to strings).

**`stringify_keys/1`** context (lines 226–228) — shows why `"warning"` (string) is the correct key to pass to `Map.get/2` in the projection:

```elixir
# stringify_keys/1 normalises atom keys → string keys before projection
# So Map.get(step, "warning") is correct whether data comes from
# __runbook_schema__() (atom key :warning) or DB round-trip (string key "warning").
```

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` — add warning render block in `runbook_card`

**Analog:** self — the guidance block at lines 293–297 is the direct model to mirror with amber styling.

**Current guidance block** (`priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 293–297):

```heex
<%%= if step.state == :guidance && step.guidance do %>
  <div class="mt-2 p-2 bg-blue-50 border border-blue-100 rounded text-xs text-blue-800 italic">
    <%%= step.guidance %>
  </div>
<%% end %>
```

**Action:** Insert the new warning block immediately after line 297 (after the guidance `end`) and before line 299 (the `targeting_hints` block). The warning block renders regardless of `step.state` (it applies to any step kind). Use amber styling to distinguish from the blue guidance block and the red runtime preview-panel warnings:

```heex
<%%= if step.warning do %>
  <div class="mt-2 p-2 bg-amber-50 border border-amber-100 rounded text-xs text-amber-800">
    <%%= step.warning %>
  </div>
<%% end %>
```

**Do NOT** use or mirror the `preview_panel` warnings block (lines 361–370) — that reads `preview.data["warnings"]`, a runtime capability-preview field, not the step-level `warning:` DSL field.

**Full `runbook_card` step loop context** (`lib/../operator_components.ex.eex` lines 280–330) — shows the slot order: label/badge (286–289), description (291), guidance block (293–297), [NEW: warning block here], targeting_hints (299–307), action button (310–326).

---

### `priv/templates/parapet.gen.runbooks/dead_letter.ex.eex` — deepen existing template

**Analog:** self — the current 2-step file is the base; mirror `stalled_executor.ex.eex` step shape for the verification step.

**Current full file** (`priv/templates/parapet.gen.runbooks/dead_letter.ex.eex` lines 1–25):

```elixir
defmodule <%= inspect(@module_prefix) %>.DeadLetter do
  use Parapet.Runbook

  title("Dead Letter Queue Recovery")
  description("Guidance and recovery actions for items that have permanently failed processing.")

  step(:investigate_error,
    label: "Analyze Error Reason",
    description: "Check the last error message for why the item was dead lettered.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Review the attached exception and stacktrace."
  )

  step(:requeue_item,
    label: "Requeue Item",
    description: "Move the item out of the dead letter queue to be processed again.",
    type: :mitigation,
    kind: :capability,
    capability: :requeue_dead_letter,
    target_kind: :async_item,
    requires_preview: true
  )
end
```

**Gaps to fill:**
1. Add `warning:` to `:investigate_error` (precondition step) — warn about irreversible nature or conditions that should abort.
2. Add `warning:` to `:requeue_item` (mitigation step) — warn about re-processing already-failed items.
3. Add a new `:verify_recovery` step (`type: :manual, kind: :guidance, preview_only: true`) after the mitigation step.

**Step shape for new verification step** — mirror the `:investigate_logs` precondition pattern from `stalled_executor.ex.eex` lines 7–14:

```elixir
step(:verify_recovery,
  label: "Verify Recovery",
  description: "Confirm the item processed successfully after requeue.",
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "Check the job's status; it should transition out of the dead letter queue."
)
```

---

### `priv/templates/parapet.gen.runbooks/callback_delay.ex.eex` — deepen existing template (most work)

**Analog:** self — current 1-step stub; mirror `provider_outage.ex.eex` lines 16–24 for the guidance-only mitigation step shape (no capability).

**Current full file** (`priv/templates/parapet.gen.runbooks/callback_delay.ex.eex` lines 1–15):

```elixir
defmodule <%= inspect(@module_prefix) %>.CallbackDelay do
  use Parapet.Runbook

  title("Callback Delay Investigation")
  description("Guidance for investigating delayed webhooks or asynchronous callbacks.")

  step(:verify_receipt,
    label: "Verify Webhook Receipt",
    description: "Check if the callback was ever received by the system.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Search HTTP logs for incoming requests matching the expected path and payload."
  )
end
```

**Gaps to fill:**
1. Add `warning:` to `:verify_receipt`.
2. Add a guidance-only mitigation step (no capability — none of the three fits callback delay).
3. Add a verification step.

**Guidance-only mitigation pattern** — mirror `callback_delay` step 1 shape but with `type: :mitigation`:

```elixir
step(:mitigate_delay,
  label: "Investigate and Remediate Delay Source",
  description: "Identify the root cause of the callback delay and take corrective action.",
  type: :mitigation,
  kind: :guidance,
  preview_only: true,
  guidance: "Check provider retry policy, network timeouts, and queue depth. Extend deadline or re-trigger callback via provider dashboard if the window has not expired.",
  warning: "Do not re-trigger if the original callback is still in flight — duplicate delivery may cause double-processing."
)
```

---

### `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — deepen existing template

**Analog:** self — current 2-step file; add `warning:` to existing steps + new verification step.

**Current full file** (`priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` lines 1–25):

```elixir
defmodule <%= inspect(@module_prefix) %>.StalledExecutor do
  use Parapet.Runbook

  title("Stalled Executor Recovery")
  description("Guidance and recovery actions for background jobs stuck in an executing state.")

  step(:investigate_logs,
    label: "Check Worker Logs",
    description: "Verify if the worker process crashed without reporting, or if it is currently deadlocked.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Search your APM for the worker executing this item."
  )

  step(:retry_item,
    label: "Retry Item",
    description: "Force the async item to be retried.",
    type: :mitigation,
    kind: :capability,
    capability: :retry_async_item,
    target_kind: :async_item,
    requires_preview: true
  )
end
```

**Gaps to fill:**
1. Add `warning:` to `:investigate_logs` — warn if logs show the item is still actively executing.
2. Add `warning:` to `:retry_item` — warn that retrying a truly deadlocked item without root cause analysis may reproduce the deadlock.
3. Add a `:verify_recovery` step after `:retry_item`.

---

### `priv/templates/parapet.gen.runbooks/provider_outage.ex.eex` — deepen existing template

**Analog:** self — current 2-step file; add `warning:` to existing steps + new verification step.

**Current full file** (`priv/templates/parapet.gen.runbooks/provider_outage.ex.eex` lines 1–25):

```elixir
defmodule <%= inspect(@module_prefix) %>.ProviderOutage do
  use Parapet.Runbook

  title("Provider Outage Handling")
  description("Guidance and actions during an external API or service provider outage.")

  step(:check_status,
    label: "Check Provider Status Page",
    description: "Verify if the provider is currently experiencing an outage.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Check the official provider status page."
  )

  step(:request_manual_check,
    label: "Request Manual Follow-up",
    description: "Flag this provider incident for manual investigation by the team.",
    type: :mitigation,
    kind: :capability,
    capability: :request_manual_provider_check,
    target_kind: :provider,
    requires_preview: true
  )
end
```

**Gaps to fill:**
1. Add `warning:` to `:check_status` — warn if the provider status page itself is unreachable (common during full outages).
2. Add `warning:` to `:request_manual_check` — warn that this creates a team task; avoid duplicate flags.
3. Add a `:verify_recovery` step after `:request_manual_check`.

---

### `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex` — NEW template (guidance-only)

**Analog:** `priv/templates/parapet.gen.runbooks/callback_delay.ex.eex` — guidance-only mitigation, no capability. Also see the RESEARCH.md full-depth pattern for 3-step structure.

**Mirror this** — copy the EEx header, `use Parapet.Runbook`, `title/description` macros, then three steps matching the depth checklist. Mitigation is `type: :mitigation, kind: :guidance, preview_only: true` (guidance-only — `:retry_async_item` is semantically wrong for a storm: retrying items worsens the storm; see RESEARCH.md D-07 correction).

**Step skeleton to produce:**

```elixir
defmodule <%= inspect(@module_prefix) %>.RetryStorm do
  use Parapet.Runbook

  title("Retry Storm Recovery")
  description("Guidance for recovering from a queue saturated with rapid retry attempts after a transient failure.")

  step(:assess_storm,
    label: "Assess Retry Storm Scope",
    description: "Confirm the queue is experiencing abnormal retry volume, not normal processing.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Check queue depth, retry rate, and worker utilization in your APM. A storm typically shows retry counts growing faster than success counts.",
    warning: "Do not apply retry-accelerating mitigations during a storm — they will worsen worker exhaustion."
  )

  step(:reduce_retry_pressure,
    label: "Reduce Retry Pressure",
    description: "Adjust backoff configuration or temporarily throttle the affected queue.",
    type: :mitigation,
    kind: :guidance,
    preview_only: true,
    guidance: "Increase retry backoff interval, reduce queue concurrency, or temporarily pause the queue via your job backend's admin interface. Resume once the transient failure has resolved.",
    warning: "Pausing the queue will delay legitimate work — communicate to stakeholders and set a resume reminder."
  )

  step(:verify_storm_cleared,
    label: "Verify Storm Has Cleared",
    description: "Confirm retry volume has returned to normal after adjustments.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Re-check queue metrics. Retry rate should be declining and worker utilization should be normalizing."
  )
end
```

---

### `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex` — NEW template (guidance-only)

**Analog:** `priv/templates/parapet.gen.runbooks/callback_delay.ex.eex` — guidance-only throughout, no capability (none of the three allowlisted capabilities address escalation suppression state).

**Mirror this** — same structure as `callback_delay.ex.eex` + the three-step depth pattern.

**Step skeleton to produce:**

```elixir
defmodule <%= inspect(@module_prefix) %>.SuppressionDrift do
  use Parapet.Runbook

  title("Suppression Drift Investigation")
  description("Guidance for identifying and correcting escalation suppression windows that have drifted or accumulated beyond intended periods.")

  step(:identify_drifted_suppressions,
    label: "Identify Drifted Suppression Windows",
    description: "Find suppressions that are still active but have exceeded their expected duration.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Query the suppression records for open windows older than your policy maximum. Compare current time against each window's intended expiry.",
    warning: "Suppressions older than expected may be silently blocking incident escalations — do not dismiss this runbook without reviewing the full suppression list."
  )

  step(:clear_stale_suppressions,
    label: "Clear Stale Suppression Windows",
    description: "Remove or expire suppression windows that have drifted beyond policy.",
    type: :mitigation,
    kind: :guidance,
    preview_only: true,
    guidance: "For each stale suppression, expire or delete the record using your host application's admin tooling or a manual database update. Document each change.",
    warning: "Clearing a suppression may immediately trigger escalation for the affected incident — ensure on-call is aware before proceeding."
  )

  step(:verify_escalation_restored,
    label: "Verify Escalation Restored",
    description: "Confirm that affected incidents now escalate correctly after suppression removal.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Check the incident timeline for any newly triggered escalation entries. Review alert routing to confirm the escalation path is functioning."
  )
end
```

---

### `priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex` — NEW template (`:retry_async_item`)

**Analog:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — same capability (`:retry_async_item`), same `target_kind: :async_item`, same `requires_preview: true` pattern.

**Mirror this** exactly — copy `stalled_executor.ex.eex` and adapt the labels/descriptions/guidance. The mitigation step uses `capability: :retry_async_item` with `requires_preview: true` (operator scopes the preview to the stuck subset before retrying).

**Step skeleton to produce:**

```elixir
defmodule <%= inspect(@module_prefix) %>.PartialBacklogDrain do
  use Parapet.Runbook

  title("Partial Backlog Drain")
  description("Guidance and recovery actions for a queue where a subset of items is stuck while others process normally.")

  step(:identify_stuck_items,
    label: "Identify Stuck Items",
    description: "Determine which items in the backlog are not draining and confirm they are a bounded subset.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Filter queue items by status and age. Stuck items will have a last-attempt timestamp older than normal processing SLA with no recent progress.",
    warning: "Verify the items are genuinely stuck and not simply lower-priority. Retrying healthy items unnecessarily may trigger duplicate side effects."
  )

  step(:retry_stuck_items,
    label: "Retry Stuck Items",
    description: "Preview the bounded set of stuck items and retry them.",
    type: :mitigation,
    kind: :capability,
    capability: :retry_async_item,
    target_kind: :async_item,
    requires_preview: true,
    warning: "Review the preview count before confirming — if the affected set is unexpectedly large, investigate the root cause before retrying."
  )

  step(:verify_drain,
    label: "Verify Backlog Is Draining",
    description: "Confirm the previously stuck items are now processing.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Monitor queue depth and item status. Previously stuck items should show progress within one processing cycle."
  )
end
```

---

### `lib/mix/tasks/parapet.gen.runbooks.ex` — add three `copy_template` calls

**Analog:** self — the four existing `Igniter.copy_template` calls at lines 33–56 are the exact pattern to repeat.

**Current pattern** (`lib/mix/tasks/parapet.gen.runbooks.ex` lines 32–56):

```elixir
igniter
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "stalled_executor.ex.eex"]),
  Path.join([lib_dir, "stalled_executor.ex"]),
  assigns,
  on_exists: :skip
)
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "dead_letter.ex.eex"]),
  Path.join([lib_dir, "dead_letter.ex"]),
  assigns,
  on_exists: :skip
)
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "provider_outage.ex.eex"]),
  Path.join([lib_dir, "provider_outage.ex"]),
  assigns,
  on_exists: :skip
)
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "callback_delay.ex.eex"]),
  Path.join([lib_dir, "callback_delay.ex"]),
  assigns,
  on_exists: :skip
)
```

**Action:** Pipe three more identical-structure `|> Igniter.copy_template(...)` calls after line 56 (before `|> Igniter.add_notice`), using the new template filenames:
- `"retry_storm.ex.eex"` → `"retry_storm.ex"`
- `"suppression_drift.ex.eex"` → `"suppression_drift.ex"`
- `"partial_backlog_drain.ex.eex"` → `"partial_backlog_drain.ex"`

The `assigns` variable (line 26–30) already contains `module_prefix:`, `app_name:`, and `base_name:` — no change to assigns needed.

---

### `test/parapet/runbook_test.exs` — extend DummyRunbook + schema assertion (D-11 Layer 1)

**Analog:** self — the `DummyRunbook` definition at lines 4–55 and the schema assertion at lines 57–112.

**DummyRunbook `step(:investigate, ...)` pattern** (lines 32–39) — shows the existing step with `guidance:` that is the closest structural analog for adding `warning:`:

```elixir
step(:investigate,
  label: "Investigate Manually",
  description: "Look at the logs.",
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "Go to Grafana..."
)
```

**Action 1:** Add `warning: "Check logs before proceeding."` to this step (or add a new dedicated step). The value must be a literal string so the schema assertion can check equality.

**Schema assertion pattern** (lines 95–103) — shows how to assert a step field:

```elixir
assert investigate_step.id == :investigate
assert investigate_step.label == "Investigate Manually"
assert investigate_step.description == "Look at the logs."
assert investigate_step.type == :manual
assert investigate_step.kind == :guidance
assert investigate_step.requires_preview == false
assert investigate_step.preview_only == true
assert investigate_step.auto_execute == false
assert investigate_step.guidance == "Go to Grafana..."
```

**Action 2:** Add `assert investigate_step.warning == "Check logs before proceeding."` after line 103. This assertion fails before the DSL fix (step map has no `warning` key → field access returns nil) and passes after.

---

### `test/parapet/operator/workbench_contract_test.exs` — extend projection fixture + assertion (D-11 Layer 2)

**Analog:** self — the projection test at lines 308–369.

**Projection test fixture** (lines 308–326) — shows the `runbook_data` step map structure:

```elixir
test "derives runbook steps with previewable and guidance distinctions" do
  incident = %Incident{
    id: "inc-1",
    runbook_data: %{
      "title" => "Mailglass Recovery",
      "description" => "Recovery steps for Mailglass",
      "steps" => [
        %{id: "step-1", label: "Check status", preview_only: true},
        %{
          id: "step-2",
          label: "Retry delivery",
          requires_preview: true,
          target_kind: "suppressed_delivery"
        },
        %{id: "step-3", label: "Direct mitigation", requires_preview: false}
      ]
    }
  }
```

**Action 1:** Add `warning: "test warning text"` to the `step-1` map in the fixture (step-1 uses atom keys like the others — the projection's `stringify_keys/1` at line 115 handles normalisation).

**Step assertion pattern** (lines 354–357):

```elixir
[s1, s2, s3] = derived.runbook_steps
assert s1.id == "step-1"
assert s1.state == :guidance
assert s1.targeting_hints == []
```

**Action 2:** Add `assert s1.warning == "test warning text"` after the existing `s1` assertions. This is the most critical layer because the projection-drop failure at `workbench_contract.ex:144-156` is invisible to all other test layers.

---

### `test/mix/tasks/parapet.gen.runbooks_test.exs` — extend file-path + content assertions (D-11 Layer 3)

**Analog:** self — the four existing file-path and content assertion blocks at lines 8–48.

**File-path assertion pattern** (lines 15–18):

```elixir
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/stalled_executor.ex"))
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/dead_letter.ex"))
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/provider_outage.ex"))
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/callback_delay.ex"))
```

**Content assertion pattern** (lines 20–26):

```elixir
stalled_executor_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/stalled_executor.ex")
  |> Rewrite.Source.get(:content)

assert stalled_executor_source =~ "defmodule Test.Parapet.Runbooks.StalledExecutor do"
assert stalled_executor_source =~ "use Parapet.Runbook"
assert stalled_executor_source =~ "capability: :retry_async_item"
```

**Action:** After line 18, add three new file-path assertions:

```elixir
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/retry_storm.ex"))
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/suppression_drift.ex"))
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/partial_backlog_drain.ex"))
```

Then add three content assertion blocks (after line 48, before `end`) mirroring the pattern above:
- `retry_storm_source` — assert `=~ "defmodule Test.Parapet.Runbooks.RetryStorm do"` and `=~ "warning:"`
- `suppression_drift_source` — assert `=~ "defmodule Test.Parapet.Runbooks.SuppressionDrift do"` and `=~ "warning:"`
- `partial_backlog_drain_source` — assert `=~ "defmodule Test.Parapet.Runbooks.PartialBacklogDrain do"` and `=~ "capability: :retry_async_item"` and `=~ "warning:"`

Also extend the four existing templates' content assertions to verify `=~ "warning:"` after the DSL+template changes land.

---

## Shared Patterns

### EEx Template Header
**Source:** Any of the four existing templates, e.g. `priv/templates/parapet.gen.runbooks/dead_letter.ex.eex` line 1
**Apply to:** All three new `.ex.eex` template files

```elixir
defmodule <%= inspect(@module_prefix) %>.<ModuleName> do
  use Parapet.Runbook
```

`@module_prefix` is the `module_prefix` assign passed by the generator (line 29 of `parapet.gen.runbooks.ex`). The `inspect/1` call produces the correct dotted module name.

### Guidance Step Pattern (precondition / verification)
**Source:** All four existing templates, step 1 in each
**Apply to:** All precondition and verification steps across all 7 templates

```elixir
step(:step_id,
  label: "Human Label",
  description: "One sentence.",
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "Operator instruction text.",
  warning: "Optional amber-block advisory text."   # add where needed
)
```

`preview_only: true` causes `WorkbenchContract.derive_runbook_steps/3` line 129 to set `state: :guidance`, which renders the guidance block in `runbook_card` and suppresses the action button.

### Capability-Backed Mitigation Pattern (`:retry_async_item`)
**Source:** `stalled_executor.ex.eex` lines 16–24
**Apply to:** `partial_backlog_drain.ex.eex` mitigation step

```elixir
step(:step_id,
  label: "Human Label",
  description: "One sentence.",
  type: :mitigation,
  kind: :capability,
  capability: :retry_async_item,
  target_kind: :async_item,
  requires_preview: true,
  warning: "Review the preview count before confirming."
)
```

### Guidance-Only Mitigation Pattern (no capability)
**Source:** `callback_delay.ex.eex` step 1 structure adapted to `type: :mitigation`
**Apply to:** `retry_storm.ex.eex` and `suppression_drift.ex.eex` mitigation steps; `callback_delay.ex.eex` new mitigation step

```elixir
step(:step_id,
  label: "Human Label",
  description: "One sentence.",
  type: :mitigation,
  kind: :guidance,
  preview_only: true,
  guidance: "Step-by-step operator instructions.",
  warning: "Impact advisory text."
)
```

### Capabilities Allowlist Constraint
**Source:** `lib/parapet/capabilities.ex` lines 8–12
**Apply to:** Every template mitigation step that references a `capability:` option

```elixir
@valid_capabilities [
  :retry_async_item,
  :requeue_dead_letter,
  :request_manual_provider_check
]
```

Only these three values are safe. Any other atom compiles silently but raises `ArgumentError` via `register_recovery/2` (line 35–37) and returns `{:error, :capability_unwired}` at runtime.

---

## No Analog Found

None — every file either has an exact self-analog (surgical addition to existing file) or a strong role-match analog in the same template family.

---

## Metadata

**Analog search scope:** `lib/parapet/`, `lib/mix/tasks/`, `priv/templates/parapet.gen.runbooks/`, `priv/templates/parapet.gen.ui/`, `test/parapet/`, `test/mix/tasks/`
**Files scanned:** 14 source files read directly (all line numbers confirmed against live source by RESEARCH.md)
**Pattern extraction date:** 2026-05-24
**Line number authority:** RESEARCH.md Drift Report — all CONTEXT.md citations confirmed exact except `step/2` macro def starts line 19 (not 21) and `alert_processor.ex` lives at `lib/parapet/spine/alert_processor.ex` (not `lib/parapet/alert_processor.ex`). Both corrections noted above where relevant.
**`retry_storm` capability correction:** RESEARCH.md D-07 corrects the CONTEXT.md claim — `retry_storm` must be guidance-only (`:retry_async_item` is semantically wrong for a storm scenario). `partial_backlog_drain` uses `:retry_async_item`. See RESEARCH.md lines 243–245 for rationale.
