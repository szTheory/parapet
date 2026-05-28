---
phase: 27-prebuilt-playbooks
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex
  - priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex
  - priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex
  - lib/mix/tasks/parapet.gen.runbooks.ex
  - test/mix/tasks/parapet.gen.runbooks_test.exs
  - lib/parapet/runbook.ex
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 27: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The phase delivers two new EEx runbook templates (`deploy_tied_incident`, `cardinality_blowout`),
a hardened `suppression_drift`, wiring in the Igniter generator, extended tests, and a `@doc`
atom-list update in `runbook.ex`. EEx interpolation is correct (only `@module_prefix` is
referenced; all three templates render with a single assign). Step structure is internally
consistent: capability steps carry `kind: :capability` + `capability:` atom + `requires_preview:
true` but no `preview_only:`; guidance steps carry `kind: :guidance` + `preview_only: true` but
no `capability:` key. The new capability atoms (`:revert_feature_flag`, `:disable_metric_label`)
are registered in `Parapet.Capabilities.@valid_capabilities` and the `@doc` list in
`runbook.ex` is correctly extended. The `@doc since:` / `@doc """` two-attribute pattern is the
established project convention (69 usages) and works correctly in Elixir.

Two test-coverage gaps are the primary findings; one is a clear regression surface
(guidance-only contract not asserted), the other a minor omission. No data-loss, security, or
behavioral defects were found.

## Warnings

### WR-01: Guidance-only contract for `suppression_drift` is not machine-checked

**File:** `test/mix/tasks/parapet.gen.runbooks_test.exs:94-99`

**Issue:** The `suppression_drift` template is the canonical guidance-only runbook — the phase
context explicitly states "guidance-only templates carry no `capability:` key." The test only
asserts the module name and `warning:` substring are present. It does not assert the absence of
`capability:` on any step, nor the presence of `kind: :guidance` on the mitigation step
(`:clear_stale_suppressions`). If a future contributor accidentally promoted the clear step to a
capability step the test would pass silently, violating the contract and potentially wiring an
unsafe bulk-clear automation path.

**Fix:**

```elixir
# Add to the suppression_drift_source block:
assert suppression_drift_source =~ "kind: :guidance"
refute suppression_drift_source =~ "capability:"
```

The `refute` is load-bearing: it is the only way to machine-verify the "guidance-only" invariant
for this template class.

---

### WR-02: New capability templates lack `use Parapet.Runbook` assertion

**File:** `test/mix/tasks/parapet.gen.runbooks_test.exs:111-129`

**Issue:** The `stalled_executor` block asserts `"use Parapet.Runbook"` (line 59), establishing a
pattern that every generated module compiles with the DSL. The two new template blocks
(`deploy_tied_incident`, `cardinality_blowout`) do not include this assertion. If an EEx
rendering bug dropped the `use` line the module would compile as a plain module, silently
skipping `__runbook_schema__/0` injection and causing a runtime `UndefinedFunctionError` when the
operator UI attempts to load the runbook.

**Fix:**

```elixir
# In the deploy_tied_incident_source block:
assert deploy_tied_incident_source =~ "use Parapet.Runbook"

# In the cardinality_blowout_source block:
assert cardinality_blowout_source =~ "use Parapet.Runbook"
```

## Info

### IN-01: All 35 assertions are in one monolithic test function

**File:** `test/mix/tasks/parapet.gen.runbooks_test.exs:8-131`

**Issue:** The single `"creates fixed runbook files..."` test contains 35 assertions across nine
runbooks. A failure anywhere in the test body produces a single failure with a line-number
pointer that requires manual scrolling to correlate to a specific runbook. This is not a
correctness defect, but each new runbook widens the blast radius of a single assertion failure
and makes failure attribution harder.

**Fix:** Consider grouping per-runbook content assertions into individual named sub-tests or at
minimum naming them with an explicit failure message:

```elixir
assert deploy_tied_incident_source =~ "use Parapet.Runbook",
       "deploy_tied_incident template is missing 'use Parapet.Runbook'"
```

Inline assertion messages are low-effort and immediately improve failure attribution without
restructuring the test.

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
