---
phase: 26-audit-propagation
plan: "01"
subsystem: operator-audit
tags: [audit, timeline, tool-audit, retrospective, evidence-trail]
dependency_graph:
  requires: [25-03]
  provides: [AUD-01, AUD-02, AUD-03, criterion-4]
  affects: [lib/parapet/operator.ex, lib/parapet/evidence/retrospective.ex]
tech_stack:
  added: []
  patterns:
    - "inspect/1 for opaque-result normalization in audit payloads"
    - "Best-effort failure-path audit write (discard result, preserve return contract)"
    - "DummyRepo Process-dict capture for testing best-effort writes"
key_files:
  created: []
  modified:
    - lib/parapet/operator.ex
    - lib/parapet/evidence/retrospective.ex
    - test/parapet/operator_test.exs
    - test/parapet/operator/preview_lifecycle_test.exs
    - test/parapet/evidence/retrospective_test.exs
decisions:
  - "Inline Map.put/:Map.update! pipeline (Option B) for audit_attrs enrichment — avoids a new build_audit/4 arity while keeping failure arm independently buildable (Pitfall 4)"
  - "Failure-arm audit write uses _ = Evidence.run_operator_command/1 to discard result — best-effort, DB outage does not change {:error, reason} return (D-06/Pitfall 2)"
  - "Captured writes in DummyRepo via Process.put(:captured_writes) — minimal additive extension, no side effects on existing tests"
metrics:
  duration: "5m"
  completed: "2026-05-28T14:37:27Z"
  tasks: 3
  files_modified: 5
---

# Phase 26 Plan 01: Audit Propagation — Enrich Confirm Writes + Retrospective Rendering

Complete, durable evidence trail for every operator Confirm: enriched success write (AUD-01/02), new failure write (AUD-03), and human-readable retrospective rendering (criterion 4).

## What Was Built

### Task 1: Enrich success and failure audit writes (`lib/parapet/operator.ex`)

The `{:ok, exec_result}` arm of `confirm_runbook_step/4` now writes a fully enriched `recovery_confirmed` TimelineEntry + ToolAudit:

- **TimelineEntry payload** gains `actor` (= `payload.actor`), `capability` (= `to_string(capability_id)`), `target_refs` (= `preview_entry.target_refs || []`), and a nested `outcome` map `%{"status" => "succeeded", "result" => inspect(exec_result)}`. The `step_id` key is retained.
- **ToolAudit** gains `output: %{"status" => "succeeded", "result" => ...}` and the input map gains `action_name` + `target_refs` via an inline `Map.put/Map.update!` pipeline on the existing `build_audit/2` result.

The `{:error, reason}` arm (post-won capability failure) now writes a **new `recovery_failed` TimelineEntry + ToolAudit** (`success: false`) before calling `ClaimService.mark_failed/2`. The audit write result is discarded (`_ = ...`) so a DB outage cannot change the `{:error, reason}` return shape. The rescued `{:capability_raised, msg}` path flows through the same arm and is normalized by `inspect(reason)`.

Short-circuit and conflict arms are unchanged.

### Task 2: Add retrospective render clauses (`lib/parapet/evidence/retrospective.ex`)

Two new `format_payload/1` clauses inserted immediately before the `inspect(payload)` catch-all:

- **Success clause** matches `%{"capability", "actor", "outcome" => %{"status" => "succeeded"}}` and renders: `"{cap} confirmed by {actor} on {inspect(target_refs)}"`.
- **Failure clause** matches `%{"capability", "actor", "outcome" => %{"status" => "failed", "reason"}}` and renders: `"Recovery failed: {cap} by {actor} — {reason}"`.

No filtering or whitelist changes to `generate_markdown/1`. `format_type/1` already humanizes the type label; these clauses provide the supplementary detail line.

### Task 3: Extend tests (`test/` — 3 files, no new files)

**`test/parapet/operator_test.exs`:** AUD-01 assertions on `result.timeline_entry.payload` (actor, capability, target_refs list, outcome.status) and AUD-02 assertions on `result.tool_audit` (success, input.action_name, input.target_refs, input.actor, output map, output.status).

**`test/parapet/operator/preview_lifecycle_test.exs`:**
- Extended `DummyRepo.transaction/1` to capture completed multi results into `:captured_writes` process key; reset in setup and on_exit.
- CR-02 (execute → `{:error, :provider_unavailable}`): asserts `recovery_failed` TimelineEntry + `success: false` ToolAudit captured.
- CR-03 (execute raises): asserts `recovery_failed` captured and outcome reason contains `"capability_raised"`.
- `preview_expired` short-circuit: asserts NO `recovery_confirmed` or `recovery_failed` entry captured (AUD-03 negative).

**`test/parapet/evidence/retrospective_test.exs`:** New test with `recovery_confirmed` + `recovery_failed` entries; asserts `"confirmed by"` copy, `"Recovery failed:"` prefix, `refute markdown =~ "%{"` (no raw inspect fallback), and chronological ordering of the two entries.

## Acceptance Criteria Verification

- `result.timeline_entry.type == "recovery_confirmed"` (string, unchanged) — PASS
- Timeline payload carries `actor`, `capability`, `target_refs` (list), `outcome.status == "succeeded"` — PASS
- ToolAudit `success == true`, `input["action_name"] == "retry_async_item"`, `is_list(input["target_refs"])`, `input["actor"] == payload.actor`, `is_map(output)`, `output["status"] == "succeeded"` — PASS
- CR-02 still returns `{:error, :provider_unavailable}` — PASS
- CR-03 still returns `{:error, {:capability_raised, message}}` with `message =~ "boom from host"` — PASS
- `grep -v '^#' lib/parapet/operator.ex | grep -c 'recovery_failed'` returns 1 — PASS
- No `mix.exs`/`mix.lock` diff; no new migration file — PASS
- `mix compile --warnings-as-errors` passes — PASS
- `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs test/parapet/evidence/retrospective_test.exs` — 24 tests, 0 failures

## Deviations from Plan

None. Plan executed exactly as written. All three tasks implemented per the action spec, RESEARCH patterns, and CONTEXT decisions.

## Pre-existing Issues (Out of Scope)

`Mix.Tasks.Parapet.InstallTest` (1 failure in `mix test`) was failing before Phase 26 work on the base commit. It is caused by an Igniter/Rewrite issue unrelated to audit propagation. Not introduced by this plan.

## Self-Check: PASSED

- `lib/parapet/operator.ex` exists and contains `recovery_failed` — FOUND
- `lib/parapet/evidence/retrospective.ex` exists and contains `Recovery failed:` — FOUND
- Commit `0f00b1e` (Task 1) — FOUND in git log
- Commit `638c8bc` (Task 2) — FOUND in git log
- Commit `acf24e5` (Task 3) — FOUND in git log
- `mix test` (targeted): 24/24 PASSED
- `mix compile --warnings-as-errors`: PASSED
