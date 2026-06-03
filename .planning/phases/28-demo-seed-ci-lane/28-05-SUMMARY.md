---
phase: 28-demo-seed-ci-lane
plan: "05"
subsystem: demo-app/test
tags: [smoke-tests, recovery-loop, claim-service, operator-api, ci-contract]
dependency_graph:
  requires: ["28-01", "28-03"]
  provides: ["DEMO-06"]
  affects: ["28-demo-seed-ci-lane"]
tech_stack:
  added: []
  patterns:
    - "DemoAppWeb.ConnCase for headless ExUnit smoke scenarios (no LiveViewTest, no Wallaby)"
    - "Token read-back from preview_runbook_step/3 return value (:preview key)"
    - "Expired-preview injection via Repo.update_all jsonb merge on TimelineEntry payload"
    - "Sequential double-confirm for deterministic claim-conflict (no Task.async)"
key_files:
  created:
    - examples/demo_app/test/demo_app/recovery_loop_test.exs
    - examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs
  modified:
    - examples/demo_app/lib/demo_app/recovery/retry_async_item.ex
decisions:
  - "Use atom :retry_item (not string) as step_id to bypass String.to_existing_atom/1 lazy-load race in ExUnit BEAM"
  - "Code.ensure_loaded! in setup ensures function_exported?/3 works for the runbook module check"
  - "select-then-update pattern in execute/2 avoids update_all limit: restriction in Ecto"
  - "Inline parapet_action_claims migration in demo app (single migration with both create + lease_until column)"
metrics:
  duration: "~40 minutes"
  completed: "2026-05-28T19:53:45Z"
  tasks_completed: 2
  files_changed: 3
---

# Phase 28 Plan 05: Recovery Loop CI Scenarios Summary

Four headless `:smoke`-tagged ExUnit scenarios that contract-test the Preview → Confirm recovery loop through `Parapet.Operator` API, using `DemoAppWeb.ConnCase` sandbox with a self-contained setup. All four pass; full smoke suite (6 tests) is green. CI `demo` job wiring confirmed unchanged.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Author recovery_loop_test.exs with happy-path + setup | 48d5d3b | examples/demo_app/test/demo_app/recovery_loop_test.exs (new) |
| 2 | Add three short-circuit/conflict scenarios and confirm CI wiring | 48d5d3b | (same file, same commit) |

Note: Tasks 1 and 2 landed in a single commit because the auto-fixes (migration + execute/2 bug) were discovered and resolved before the first per-task commit.

## Scenarios Implemented

| Scenario | Assertion | Result |
|----------|-----------|--------|
| Happy path | `{:ok, _}` + `recovery_confirmed` TimelineEntry + `tool_name == "operator_confirm_recovery"` ToolAudit | PASS |
| Expired preview | age `payload["expires_at"]` -600s via jsonb merge → `{:short_circuited, :preview_expired}` | PASS |
| Resolved mid-flow | flip incident to `"resolved"` → `{:short_circuited, :incident_resolved}` | PASS |
| Sequential claim-conflict | two confirms same step_id, distinct `idempotency_key` → `{:ok,_}` then `{:conflicted,_}` | PASS |

## CI Wiring Verified (D-07)

`.github/workflows/ci.yml` is **unedited**. The `demo` job runs `mix test --only smoke` (line 139); `release_gate` already `needs: [lint, test, demo]` (line 141-142). The `:smoke` module tag on `DemoApp.RecoveryLoopTest` means the new scenarios are picked up automatically. No workflow changes were needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Missing `parapet_action_claims` migration in demo app**
- **Found during:** Task 1 — `confirm_runbook_step/4` raised `Postgrex.Error: relation "parapet_action_claims" does not exist`
- **Root cause:** The demo app migrations only covered tables from pre-Phase-23 (incidents, timeline entries, tool audits, action items). The `parapet_action_claims` table introduced in Phase 23 was never added to the demo app migration chain.
- **Fix:** Created `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` as a single combined migration (create table + `lease_until` column + indexes). Ran `mix ecto.migrate` in both dev and test envs.
- **Files modified:** `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs`
- **Commit:** 48d5d3b

**2. [Rule 1 - Bug] `update_all` with `limit:` in `RetryAsyncItem.execute/2`**
- **Found during:** Task 1 — happy-path confirm returned `{:error, {:capability_raised, "update_all allows only with_cte, where and join expressions"}}`
- **Root cause:** The `execute/2` body from Plan 28-01/02 used `limit: 1` inside an `update_all` query, which Ecto does not support.
- **Fix:** Changed to a select-then-update pattern: first `Repo.one(from a ..., limit: 1, select: a.id)`, then `Repo.update_all(from a ..., where: a.id == ^item_id, ...)`.
- **Files modified:** `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex`
- **Commit:** 48d5d3b

**3. [Rule 3 - Blocker] `String.to_existing_atom("retry_item")` fails on lazy module load**
- **Found during:** Task 1 — all four scenarios returned `{:error, :invalid_step_id}` from `parse_step_id/1`
- **Root cause:** BEAM loads modules lazily; `:retry_item` atom is only interned when `DemoApp.Runbooks.StalledExecutor` code is executed. In ExUnit startup, the compiled `.beam` files exist but are not yet loaded.
- **Fix 1:** Use atom `:retry_item` directly as `step_id` arg (bypasses `String.to_existing_atom`; `parse_step_id/1` accepts atoms natively).
- **Fix 2:** Add `Code.ensure_loaded!(DemoApp.Runbooks.StalledExecutor)` in the `setup` block to ensure `function_exported?/3` returns true for `__runbook_schema__/0`.
- **Files modified:** `examples/demo_app/test/demo_app/recovery_loop_test.exs`
- **Commit:** 48d5d3b

## Known Stubs

None — all four scenarios exercise real DB state and real operator API paths. The `execute/2` mutates an actual `Parapet.Spine.ActionItem` row in the sandbox.

## Threat Flags

None — no new trust boundaries introduced. The scenarios are in-process ExUnit tests; no HTTP, auth, or external surfaces.

## Self-Check: PASSED

- [x] `examples/demo_app/test/demo_app/recovery_loop_test.exs` exists
- [x] `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` exists
- [x] Commit 48d5d3b exists in git log
- [x] All 6 smoke tests pass (`mix test --only smoke`: 6 tests, 0 failures)
- [x] `ci.yml` is unchanged (`git diff --stat -- .github/workflows/ci.yml` is empty)
- [x] File does NOT reference `find_active_preview` or `WorkbenchContract`
