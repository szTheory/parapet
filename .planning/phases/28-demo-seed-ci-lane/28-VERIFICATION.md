---
phase: 28-demo-seed-ci-lane
verified: 2026-05-28T20:15:00Z
status: human_needed
score: 10/10 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Browser click-through: cd examples/demo_app && mix setup && mix phx.server, open /parapet, find the 'Stalled async executor' open incident, click through Preview then Confirm on the 'Retry Item' step"
    expected: "Preview panel displays count=1, target_refs, preconditions, warnings, summary; Confirm button executes the capability and the incident's ActionItem transitions state from 'open' to 'resolved'; a recovery_confirmed TimelineEntry appears in the incident timeline"
    why_human: "LiveView click-through requires a browser; the DB row mutation and timeline update are contract-tested in CI but the rendered UI panels (blast-radius indicator, expected diff, operator-actionable next steps) require visual inspection; automated tests cover the API layer, not the LiveView render"
---

# Phase 28: Demo Seed + CI Lane Verification Report

**Phase Goal:** The demo app (`examples/demo_app/`) is seeded with at least one capability-backed incident demonstrating Preview → Confirm end-to-end on a fresh clone. CI exercises four scenarios (happy-path Confirm, preview-token-expired retry, short-circuit on resolved incident, claim-conflict between two simulated operators) so the loop is contract-tested.
**Verified:** 2026-05-28T20:15:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Seeded open incident exists with `runbook_data["module"]` pointing at `DemoApp.Runbooks.StalledExecutor` | VERIFIED | `priv/repo/seeds.exs` line 116: `"module" => to_string(DemoApp.Runbooks.StalledExecutor)`; incident state `"open"`, correlation_key `"stalled-async-executor"` |
| 2  | Seed creates an open `ActionItem` linked to the capability-backed incident | VERIFIED | `seeds.exs` lines 129–139: `%Parapet.Spine.ActionItem{}` with `state: "open"`, `incident_id: incident_stalled.id`; confirmed present in `mix demo.reset` output |
| 3  | `mix demo.reset` exits 0 and prints seed-complete line including "1 action item" | VERIFIED | Ran `MIX_ENV=dev mix demo.reset`; output: `Seeds complete: 4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 action item, 1 tool audit` |
| 4  | `DemoApp.Runbooks.StalledExecutor` exists as a compiled `use Parapet.Runbook` module with `:retry_item` step declaring `capability: :retry_async_item` | VERIFIED | `lib/demo_app/runbooks/stalled_executor.ex` contains `use Parapet.Runbook`; step `:retry_item` has `capability: :retry_async_item, target_kind: :async_item, requires_preview: true` |
| 5  | `DemoApp.Recovery.RetryAsyncItem` implements all 4 `Parapet.Recovery` callbacks with the correct 5-field preview map and a real DB mutation in `execute/2` | VERIFIED | `lib/demo_app/recovery/retry_async_item.ex`: `id/0` returns `:retry_async_item`; `preview/2` returns `{:ok, %{count:, target_refs:, preconditions:, warnings:, summary:}}`; `execute/2` uses select-then-update via `DemoApp.Repo.update_all` on `Parapet.Spine.ActionItem` |
| 6  | Boot-time `Parapet.Recovery.attach/1` registers `:retry_async_item` for both server and test processes | VERIFIED | `lib/demo_app/application.ex` line 19: `{:ok, _} = Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` called after `Supervisor.start_link/2`; `Parapet.Capabilities` is started by the `:parapet` OTP application (`lib/parapet/internal/application.ex` line 11), so it is running before `attach/1` is called |
| 7  | `mix demo.reset` alias exists and chains `ecto.drop -> ecto.create -> ecto.migrate -> run priv/repo/seeds.exs` | VERIFIED | `mix.exs` line 52: `"demo.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]` |
| 8  | Four `:smoke`-tagged CI scenarios pass: happy-path Confirm, expired preview, resolved mid-flow, sequential claim-conflict | VERIFIED | Ran `mix test --only smoke`: `6 tests, 0 failures`; all four scenarios in `recovery_loop_test.exs` pass via `Parapet.Operator` API |
| 9  | CI `demo` job runs `mix test --only smoke`; `release_gate` requires `[lint, test, demo]` | VERIFIED | `.github/workflows/ci.yml` line 139: `run: cd examples/demo_app && mix test --only smoke`; line 142: `needs: [lint, test, demo]`; `ci.yml` was NOT modified in any phase 28 commit |
| 10 | No core `lib/parapet/**` files were modified by this phase | VERIFIED | `git show --stat` across all phase 28 commits (21c5f9f, 471b0b6, 7a374ec, fbcd31e, 00695cd, 48d5d3b, ca32395) shows zero changes to `lib/parapet/`; all modifications confined to `examples/demo_app/` |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` | `use Parapet.Runbook` 3-step runbook with `:retry_item` capability step | VERIFIED | Exists; 36 lines; steps `:investigate_logs`, `:retry_item`, `:verify_recovery`; `capability: :retry_async_item` |
| `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` | `use Parapet.Recovery` with 4 callbacks; `id/0 => :retry_async_item`; `execute/2` mutates ActionItem | VERIFIED | Exists; 48 lines; all 4 `@impl Parapet.Recovery` callbacks; select-then-update pattern in `execute/2` |
| `examples/demo_app/lib/demo_app/application.ex` | Boot-time `Parapet.Recovery.attach/1` after `Supervisor.start_link/2` | VERIFIED | Modified; `{:ok, _} = Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` at line 19; `{:ok, sup}` captured and returned |
| `examples/demo_app/priv/repo/seeds.exs` | 4th incident block: `state: "open"`, `runbook_data["module"]`, plus open `ActionItem` | VERIFIED | Exists; incident 4 at line 109; `ActionItem` at line 129; no inline `"steps"` on new block; existing 3 incidents intact |
| `examples/demo_app/mix.exs` | `"demo.reset"` alias with `ecto.drop -> ecto.create -> ecto.migrate -> run priv/repo/seeds.exs` | VERIFIED | Line 52 exactly matches spec; `setup` alias unchanged |
| `examples/demo_app/test/demo_app/recovery_loop_test.exs` | `@moduletag :smoke`; 4 scenario tests; no `find_active_preview`; no `Task.async` | VERIFIED | Exists; 183 lines; `@moduletag :smoke`; 4 tests; token read via `preview_result.preview["preview_token"]`; sequential confirm for conflict scenario |
| `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` | Combined migration: `parapet_action_claims` table + `lease_until` column + indexes | VERIFIED | Exists; 34 lines; creates table with all required columns including `lease_until`; creates `(incident_id, action_kind, action_key)` unique index |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `stalled_executor.ex` | `:retry_async_item` | `capability:` field on `:retry_item` step | VERIFIED | Line 22: `capability: :retry_async_item` |
| `retry_async_item.ex` | `Parapet.Spine.ActionItem` | `DemoApp.Repo.update_all` in `execute/2` | VERIFIED | Line 41: `DemoApp.Repo.update_all(from(a in Parapet.Spine.ActionItem, where: a.id == ^item_id), ...)` |
| `application.ex` | `DemoApp.Recovery.RetryAsyncItem` | `Parapet.Recovery.attach/1` after `Supervisor.start_link/2` | VERIFIED | Line 19: `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` |
| `application.ex` | `Parapet.Capabilities` | Started by `:parapet` OTP application; `attach/1` uses the running agent | VERIFIED | `Parapet.Internal.Application` line 11 starts `{Parapet.Capabilities, []}`; demo app dependency ordering guarantees agent is running before `attach/1` |
| `seeds.exs` | `DemoApp.Runbooks.StalledExecutor` | `runbook_data["module"] => to_string(DemoApp.Runbooks.StalledExecutor)` | VERIFIED | Line 116: `"module" => to_string(DemoApp.Runbooks.StalledExecutor)` |
| `recovery_loop_test.exs` | `Parapet.Operator.confirm_runbook_step/4` | All 4 scenarios call this API directly | VERIFIED | Lines 58, 111, 143, 177–178: confirm calls using `:retry_item` atom as step_id |
| `.github/workflows/ci.yml` | `recovery_loop_test.exs` | `mix test --only smoke` picks up `@moduletag :smoke` | VERIFIED | Line 139; `ci.yml` unmodified in this phase |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `recovery_loop_test.exs` scenario 1 | `confirm_result` | `Parapet.Operator.confirm_runbook_step/4` → `RetryAsyncItem.execute/2` → `DemoApp.Repo.update_all` on real sandbox ActionItem | Yes — ActionItem row mutated; TimelineEntry + ToolAudit written by core | FLOWING |
| `seeds.exs` incident 4 | `incident_stalled`, `_action_item` | `Parapet.Evidence.create_incident/1` + `DemoApp.Repo.insert/1` against demo DB | Yes — confirmed via `mix demo.reset` DB output showing INSERT statements | FLOWING |
| `retry_async_item.ex` `execute/2` | `item_id`, `{n, _}` | `DemoApp.Repo.one` query then `DemoApp.Repo.update_all` on `Parapet.Spine.ActionItem` | Yes — real DB query; returns `{:ok, %{retried_count: n}}` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 6 smoke tests pass | `cd examples/demo_app && mix test --only smoke` | `6 tests, 0 failures` (0.1s) | PASS |
| `demo.reset` seeds DB and exits 0 | `MIX_ENV=dev mix demo.reset` | Exits 0; prints "Seeds complete: 4 incidents...1 action item..." | PASS |
| `mix.exs` demo.reset alias recognized | `grep "demo.reset" examples/demo_app/mix.exs` | Line 52: `"demo.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]` | PASS |
| `ci.yml` smoke wiring intact | `grep "mix test --only smoke" .github/workflows/ci.yml` | Line 139 matches | PASS |
| `release_gate` gates on demo | `grep "release_gate\|needs.*lint.*test.*demo" .github/workflows/ci.yml` | Line 141-142: `needs: [lint, test, demo]` | PASS |

### Probe Execution

No `probe-*.sh` files declared or present for this phase. Behavioral spot-checks above cover the equivalent functional verification.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEMO-05 | Plans 01, 02, 03, 04 | Demo app seeded with capability-backed incident; Preview-able + Confirm-able step; seed runs as part of `mix setup`; replayable via `mix demo.reset` | SATISFIED | Seeds incident 4 with `runbook_data["module"]` + open ActionItem; `setup` alias includes `run priv/repo/seeds.exs`; `demo.reset` alias confirmed; all smoke tests pass against seeded data |
| DEMO-06 | Plan 05 | CI demo lane exercises 4 scenarios; failures break build | SATISFIED | `recovery_loop_test.exs` has all 4 `:smoke`-tagged scenarios; `ci.yml` demo job runs `mix test --only smoke`; `release_gate needs: [lint, test, demo]` wires failures as blockers |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` markers found in any file delivered by this phase. No placeholder returns, hardcoded empty arrays in render paths, or orphaned stubs detected.

**Note on accepted deviations (per verification guidance):**

1. `execute/2` select-then-update pattern — the plan originally specified `update_all` with `limit: 1` (which Ecto does not support). The executor auto-fixed this to a `Repo.one` select followed by `Repo.update_all` by `id`. This is correct behavior; the select-then-update is safe because confirms are serialized upstream by `ClaimService`'s `(incident_id, action_kind, action_key)` unique constraint. Not a blocker.

2. `Parapet.Capabilities` not added as a child in `DemoApp.Application` — the plan specified adding it to the demo's `children` list, but this would cause `{:already_started, PID}` because `Parapet.Internal.Application` (the `:parapet` OTP application) already supervises it. The executor correctly omitted the duplicate entry. The capability agent IS in a supervision tree (`:parapet`'s), satisfying the must-have's intent. Not a blocker.

### Human Verification Required

#### 1. Browser Preview → Confirm Click-Through

**Test:** Run `cd examples/demo_app && mix setup && mix phx.server`. Open the Parapet operator UI in a browser. Find the "Stalled async executor" open incident. Click the "Retry Item" runbook step's Preview button, review the preview panel (action name, target args, blast-radius indicator, expected diff), then click Confirm.

**Expected:** Preview panel renders with the 5-field capability preview (count=1, target refs, preconditions, warnings, summary). Confirm executes successfully — the incident's linked ActionItem transitions state from "open" to "resolved", and a `recovery_confirmed` TimelineEntry appears in the incident timeline in the UI.

**Why human:** LiveView rendering of the preview panel (blast-radius indicator, expected diff display, operator-actionable next steps for error branches) requires visual inspection. The underlying DB mutation and audit trail are already contract-tested by the 4 smoke scenarios; what remains is confirming the UI renders those paths correctly for an operator.

---

### Gaps Summary

No gaps. All 10 observable truths verified. All 7 artifacts exist and are substantive, wired, and data-flowing. Both DEMO-05 and DEMO-06 requirements are satisfied. The `release_gate` CI gate is confirmed wired with `needs: [lint, test, demo]` and `ci.yml` was not modified by this phase. No core `lib/parapet/` files were modified.

One human verification item remains: the browser click-through of Preview → Confirm in the LiveView UI (the DB side of this is fully contract-tested; only the rendered panel requires human eyes).

---

_Verified: 2026-05-28T20:15:00Z_
_Verifier: Claude (gsd-verifier)_
