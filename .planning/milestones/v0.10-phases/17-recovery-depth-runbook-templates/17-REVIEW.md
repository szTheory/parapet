---
phase: 17-recovery-depth-runbook-templates
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/parapet/runbook.ex
  - lib/parapet/operator/workbench_contract.ex
  - priv/templates/parapet.gen.ui/operator_components.ex.eex
  - lib/mix/tasks/parapet.gen.runbooks.ex
  - priv/templates/parapet.gen.runbooks/dead_letter.ex.eex
  - priv/templates/parapet.gen.runbooks/callback_delay.ex.eex
  - priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex
  - priv/templates/parapet.gen.runbooks/provider_outage.ex.eex
  - priv/templates/parapet.gen.runbooks/retry_storm.ex.eex
  - priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex
  - priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex
  - test/parapet/runbook_test.exs
  - test/parapet/operator/workbench_contract_test.exs
  - test/mix/tasks/parapet.gen.runbooks_test.exs
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-05-24T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

This change set threads a new `:warning` key through the `Parapet.Runbook` DSL macro (`step/2`), the step-projection layer (`WorkbenchContract.derive_runbook_steps/3`), and the operator LiveView EEx component (`runbook_card`). It deepens four existing prebuilt runbook templates (dead_letter, callback_delay, stalled_executor, provider_outage), adds three new ones (retry_storm, suppression_drift, partial_backlog_drain), wires all seven into the `parapet.gen.runbooks` generator with the `on_exists: :skip` host-ownership invariant, and adds regression tests.

The core mechanics are correct and consistent:

- The `warning:` passthrough in `step/2` mirrors the existing `guidance:` field exactly (`unquote(opts)[:warning]`), so a missing key yields `nil` rather than crashing.
- The projection in `derive_runbook_steps/3` adds `warning: Map.get(step, "warning")` after `stringify_keys/1`, so both atom- and string-keyed runbook payloads project correctly.
- The EEx render block (`if step.warning do`) is unconditional on state, matching the documented intent ("any step carrying a precondition or impact warning").
- The capability allowlist is respected: the four capability-backed steps use only `:retry_async_item`, `:requeue_dead_letter`, and `:request_manual_provider_check`, matching `Parapet.Capabilities`.
- The generator uses `on_exists: :skip` on every `copy_template` call, preserving host ownership.

No BLOCKER-severity correctness, security, or data-loss defects were found. The findings below are robustness gaps and coverage/consistency observations.

## Warnings

### WR-01: `warning` block renders on already-executed steps, contradicting the precondition framing of the copy

**File:** `priv/templates/parapet.gen.ui/operator_components.ex.eex:299-303`

**Issue:** The warning block renders whenever `step.warning` is truthy, with no state guard:

```elixir
<%= if step.warning do %>
  <div class="mt-2 p-2 bg-amber-50 border border-amber-100 rounded text-xs text-amber-800">
    <%= step.warning %>
  </div>
<% end %>
```

Compare this with the immediately-preceding `guidance` block (line 293), which is correctly state-gated: `if step.state == :guidance && step.guidance`. Because warnings have no equivalent guard, a step that has already been executed (`step.state == :executed`, rendering the green "Executed" badge on line 287-288) still shows its amber warning. Every capability template's warning is written as a *precondition / pre-execution* caution — e.g. dead_letter's "Do not requeue if the error indicates a persistent structural failure" and stalled_executor's "Retrying without identifying the root cause may reproduce the deadlock." After execution these read as if the operator is being warned about an action they have already taken, which is confusing and undercuts the trust the amber block is meant to convey. This is a behavior/UX correctness gap in the emitted host artifact, not merely styling.

**Fix:** Suppress the warning once the step is no longer actionable (executed steps no longer expose an action button on lines 326-329):

```elixir
<%= if step.warning && step.state != :executed do %>
  <div class="mt-2 p-2 bg-amber-50 border border-amber-100 rounded text-xs text-amber-800">
    <%= step.warning %>
  </div>
<% end %>
```

If post-execution display is intentional, change the copy to be tense-neutral and document the decision; otherwise gate it as above for parity with the `guidance` block.

### WR-02: New generator test does not assert the `on_exists: :skip` host-ownership invariant

**File:** `test/mix/tasks/parapet.gen.runbooks_test.exs:8-77`

**Issue:** The phase prompt calls out `on_exists: :skip` as a generator invariant, and the generator (`lib/mix/tasks/parapet.gen.runbooks.ex:37,43,...`) sets it on all seven `copy_template` calls. The new test only asserts that files are created on a fresh project and that their content contains the expected `defmodule`/`capability`/`warning` markers. It never runs the generator twice to prove a pre-existing host file is preserved (skipped) rather than overwritten — which is the entire point of the host-ownership invariant. The sibling generator test `test/mix/tasks/parapet.gen.ui_test.exs:77` already establishes the idempotency-test precedent in this codebase, so the omission is a coverage regression, not an unestablished pattern. A future refactor could silently change `:skip` to `:overwrite` (clobbering operator customizations of copy/thresholds — exactly what the generator notice on `parapet.gen.runbooks.ex:75-78` invites users to do) with no failing test.

**Fix:** Add an idempotency/skip test mirroring the UI generator pattern, e.g.:

```elixir
test "skips files that already exist (preserves host customization)" do
  igniter1 = test_project(app_name: :test) |> Runbooks.igniter()

  # Re-run on the result; existing files must be skipped, not overwritten.
  igniter2 = Runbooks.igniter(igniter1)

  source =
    Rewrite.source!(igniter2.rewrite, "lib/test/parapet/runbooks/stalled_executor.ex")
    |> Rewrite.Source.get(:content)

  # Content from the first generation is still present and not duplicated.
  assert source =~ "defmodule Test.Parapet.Runbooks.StalledExecutor do"
end
```

(Adjust to whatever observable the Igniter test harness exposes for a skipped copy.)

### WR-03: `step/2` performs no validation of `:capability` against the allowlist or of `:kind`/`:type` enums

**File:** `lib/parapet/runbook.ex:38-55`

**Issue:** The `step/2` macro accepts `:capability`, `:kind`, and `:type` as free-form values and stores them verbatim into `@steps`. `Parapet.Capabilities.register_recovery/2` raises `ArgumentError` for any capability id outside the three-element allowlist, but `step/2` enforces nothing at runbook compile time. A host author who writes `capability: :retry_aysnc_item` (typo) or `kind: :capabilty` produces a runbook that compiles cleanly and ships, then fails opaquely later — the capability is never wired, so `WorkbenchContract.derive_runbook_steps/3` projects the step as `:executable`/`:previewable` and the operator gets a dead Execute/Preview button with no diagnostic. Phase 17 deepens and multiplies these templates (four capability steps across the catalog) and documents the allowlist in the `@doc` on `runbook.ex:28-29`, so this is the right moment to enforce what the docs already promise. This is a robustness gap that pushes a class of silent misconfiguration to production.

**Fix:** Validate at macro-expansion time so typos fail the host's compile. For example, raise when `:kind` is `:capability` but `:capability` is not in the allowlist, and when `:type`/`:kind` are outside their documented enums:

```elixir
defmacro step(id, opts) do
  capability = opts[:capability]

  if capability && capability not in [:retry_async_item, :requeue_dead_letter, :request_manual_provider_check] do
    raise ArgumentError,
          "step #{inspect(id)}: invalid :capability #{inspect(capability)}. " <>
            "Valid: :retry_async_item, :requeue_dead_letter, :request_manual_provider_check"
  end

  quote do
    @steps %{
      id: unquote(id),
      # ... unchanged ...
    }
  end
end
```

(Validation must run on the literal `opts` at expansion time; it cannot be deferred into the `quote` block if you want compile-time failure.)

## Info

### IN-01: `runbook_test.exs` exercises `warning:` only on a `preview_only`/guidance step, never on a capability step

**File:** `test/parapet/runbook_test.exs:32-40,96-105`

**Issue:** The DSL test asserts `warning` round-trips through `__runbook_schema__()` only for the `:investigate` step (`type: :manual`, `kind: :guidance`, `preview_only: true`). The phase's actual production usage of `warning:` is overwhelmingly on `type: :mitigation`, `kind: :capability` steps (e.g. dead_letter `requeue_item`, stalled_executor `retry_item`). The schema map is identical regardless of step type so the assertion technically covers the field, but the test does not document/lock the more important capability-step path. Consider adding a `warning:` assertion to the existing `:retry` capability step (lines 22-30) for stronger intent coverage.

**Fix:** Add `warning: "..."` to the `:retry` step definition and a corresponding `assert retry_step.warning == "..."` assertion.

### IN-02: Three deepened/new templates pair `type: :mitigation` with `kind: :guidance` and `preview_only: true`, relying on undocumented projection behavior

**File:** `priv/templates/parapet.gen.runbooks/callback_delay.ex.eex:17-25`, `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex:17-25`, `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex:17-25`

**Issue:** Steps such as `mitigate_delay`, `reduce_retry_pressure`, and `clear_stale_suppressions` declare `type: :mitigation` but `kind: :guidance` with `preview_only: true`. `WorkbenchContract.derive_runbook_steps/3` (workbench_contract.ex:126-132) classifies state purely from `preview_only`/`requires_preview`/execution evidence and ignores `kind` entirely, so these correctly resolve to `state: :guidance` (no action button). This works, but it is load-bearing on the fact that the projection ignores `kind` and that `:type` is decorative for non-capability steps. The DSL `@doc` (runbook.ex:26-27) describes `:type` as ":manual or :mitigation" without explaining that a `:mitigation` step can still be guidance-only. A future change that makes the projection key off `type == :mitigation` to render a button would regress these three templates into showing dead Execute buttons.

**Fix:** Either keep `type: :guidance` semantics consistent (these are advisory, so consider `type: :manual` to match the verify steps), or add a short comment in `WorkbenchContract.derive_runbook_steps/3` noting that step state is intentionally derived from `preview_only`/`requires_preview` only and not from `type`/`kind`.

### IN-03: `provider_outage` `request_manual_check` step uses `requires_preview: true` but has no preview semantics described in the warning/guidance

**File:** `priv/templates/parapet.gen.runbooks/provider_outage.ex.eex:17-26`

**Issue:** `request_manual_provider_check` is a "create a team task" side effect with `requires_preview: true`, which means the operator UI routes it through the preview→confirm flow (`runbook_card` `:previewable` branch, operator_components.ex:318-321, and `preview_panel`). The preview panel surfaces `target_kind`, `count`, `warnings`, and `idempotency_caveats` from the preview payload. The template's warning ("Avoid triggering it multiple times ... duplicate flags create noise") describes an idempotency concern that would be most useful as a preview `idempotency_caveats` value, but the runbook DSL has no field to seed it — the caveat lives only in the static `warning:` string. This is a documentation/consistency observation: the warning copy and the runtime preview caveats are sourced separately and can drift. No code fix required for this phase.

**Fix:** None required now. When the preview-payload contract is next touched, consider whether `warning:` should feed the preview's `idempotency_caveats` so the operator sees the same caution at confirm time.

### IN-04: Operator EEx component has no rendering test; the new warning block is verified only by host-side compilation

**File:** `priv/templates/parapet.gen.ui/operator_components.ex.eex:299-303`

**Issue:** There is no test in `test/` that renders `runbook_card` or any `OperatorComponents` function (confirmed: no references to `runbook_card`, `OperatorComponents`, or `render_component` in the test tree). The new amber warning block is therefore validated only indirectly — it must compile inside a host project, and the contract test (`workbench_contract_test.exs:308-359`) only proves the `warning` field is *projected*, not *rendered*. This matches the repo's existing convention (the UI generator template is treated as an emitted text artifact, not unit-rendered), so it is an observation rather than a regression. The contract-level assertion at workbench_contract_test.exs:358 (`assert s1.warning == "test warning text"`) is the meaningful guard here and is correctly present.

**Fix:** None required for this phase given the established convention. If component-level rendering coverage is ever added for the operator UI, include a case asserting the amber warning block appears for a step with a non-nil `warning` and is absent when `warning` is nil.

---

_Reviewed: 2026-05-24T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
