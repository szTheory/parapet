---
phase: 28-demo-seed-ci-lane
verified: 2026-05-28T21:00:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
re_verification:
  prior_outcome: human-gated (browser click-through, now automated)
  previous_score: 10/10
  gaps_closed:
    - "Browser Preview -> Confirm click-through automated into CI via Phoenix.LiveViewTest (Scenario 5)"
  gaps_remaining: []
  regressions: []
---

# Phase 28: Demo Seed + CI Lane Verification Report

**Phase Goal:** The demo app (`examples/demo_app/`) is seeded with at least one capability-backed incident demonstrating Preview -> Confirm end-to-end on a fresh clone. CI exercises four scenarios so the loop is contract-tested.
**Verified:** 2026-05-28T21:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (commit cdfc213 added LiveView Scenario 5 + root-cause fix)

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Seeded open incident exists with `runbook_data["module"]` pointing at `DemoApp.Runbooks.StalledExecutor` | VERIFIED | `priv/repo/seeds.exs` line 156: `"module" => to_string(DemoApp.Runbooks.StalledExecutor)`; incident state `"open"`, correlation_key `"stalled-async-executor"` |
| 2  | Seed creates an open `ActionItem` linked to the capability-backed incident | VERIFIED | `seeds.exs` lines 161+: `%Parapet.Spine.ActionItem{}` with `state: "open"`, `incident_id: incident_stalled.id` |
| 3  | `mix demo.reset` exits 0 and prints seed-complete line | VERIFIED | Previously confirmed: `Seeds complete: 4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 action item, 1 tool audit` |
| 4  | `DemoApp.Runbooks.StalledExecutor` exists as a compiled `use Parapet.Runbook` module with `:retry_item` step declaring `capability: :retry_async_item` | VERIFIED | `lib/demo_app/runbooks/stalled_executor.ex`: step `:retry_item` has `capability: :retry_async_item, requires_preview: true` |
| 5  | `DemoApp.Recovery.RetryAsyncItem` implements all 4 `Parapet.Recovery` callbacks with the correct 5-field preview map and a real DB mutation in `execute/2` | VERIFIED | `lib/demo_app/recovery/retry_async_item.ex`: all 4 `@impl` callbacks; select-then-update via `DemoApp.Repo.update_all` on `Parapet.Spine.ActionItem` |
| 6  | Boot-time `Parapet.Recovery.attach/1` registers `:retry_async_item` for both server and test processes | VERIFIED | `lib/demo_app/application.ex` line 19: `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` after `Supervisor.start_link/2` |
| 7  | `mix demo.reset` alias chains `ecto.drop -> ecto.create -> ecto.migrate -> run priv/repo/seeds.exs` | VERIFIED | `mix.exs` line 52 exactly matches spec |
| 8  | Four `:smoke`-tagged CI scenarios pass: happy-path Confirm, expired preview, resolved mid-flow, sequential claim-conflict | VERIFIED | All 4 API scenarios pass in `recovery_loop_test.exs` |
| 9  | CI `demo` job runs `mix test --only smoke`; `release_gate` requires `[lint, test, demo]` | VERIFIED | `.github/workflows/ci.yml` line 139: `cd examples/demo_app && mix test --only smoke`; line 142: `needs: [lint, test, demo]`; `ci.yml` unmodified in this phase |
| 10 | No core `lib/parapet/**` files were modified by this phase | VERIFIED | All modifications confined to `examples/demo_app/`; confirmed across all phase 28 commits |
| 11 | Operator Preview -> Confirm click-through is contract-tested headlessly in CI via `Phoenix.LiveViewTest` (Scenario 5) | VERIFIED | `recovery_loop_test.exs` lines 215-256: `live(conn, "/parapet/#{incident.id}")`, `render_click()` on `preview_mitigation` button, `render_click()` on `confirm_mitigation` button; asserts rendered DOM (`"Recovery Preview"`, `"Retrying without root cause analysis"`, `"Recovery confirmed"`) AND DB side effects (TimelineEntry `recovery_confirmed`, ToolAudit `operator_confirm_recovery`, ActionItem state `"resolved"`); `mix test --only smoke` produces **7 tests, 0 failures** |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` | `use Parapet.Runbook` 3-step runbook with `:retry_item` capability step | VERIFIED | Exists; steps `:investigate_logs`, `:retry_item`, `:verify_recovery`; `capability: :retry_async_item` |
| `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` | `use Parapet.Recovery` with 4 callbacks; `execute/2` mutates ActionItem | VERIFIED | Exists; all 4 `@impl Parapet.Recovery` callbacks; select-then-update in `execute/2` |
| `examples/demo_app/lib/demo_app/application.ex` | Boot-time `Parapet.Recovery.attach/1` after `Supervisor.start_link/2` | VERIFIED | Line 19: `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` |
| `examples/demo_app/priv/repo/seeds.exs` | Incident 4 with BOTH `"module"` AND `"steps"` keys + open `ActionItem` | VERIFIED | Lines 156-157: both keys present; `ActionItem` linked to `incident_stalled.id`; root-cause fix confirmed |
| `examples/demo_app/mix.exs` | `"demo.reset"` alias + `lazy_html` test dep | VERIFIED | Line 52: alias matches spec; line 37: `{:lazy_html, ">= 0.1.0", only: :test}` |
| `examples/demo_app/test/demo_app/recovery_loop_test.exs` | `@moduletag :smoke`; 5 scenarios (4 API + 1 LiveView click-through) | VERIFIED | Exists; 257 lines; Scenario 5 at lines 215-256 uses `Phoenix.LiveViewTest` (`live/2`, `render_click/1`, `has_element?/2`) |
| `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` | `parapet_action_claims` table + `lease_until` column + indexes | VERIFIED | Exists; creates table with all required columns; unique index on `(incident_id, action_kind, action_key)` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `stalled_executor.ex` | `:retry_async_item` | `capability:` field on `:retry_item` step | VERIFIED | `capability: :retry_async_item` |
| `retry_async_item.ex` | `Parapet.Spine.ActionItem` | `DemoApp.Repo.update_all` in `execute/2` | VERIFIED | Real DB mutation confirmed |
| `application.ex` | `DemoApp.Recovery.RetryAsyncItem` | `Parapet.Recovery.attach/1` at boot | VERIFIED | Line 19 |
| `seeds.exs` | `DemoApp.Runbooks.StalledExecutor` | `"module"` + `"steps"` both keys present | VERIFIED | Lines 156-157; root-cause fix: both keys required for UI render AND execution |
| `recovery_loop_test.exs` Scenario 5 | LiveView `/parapet/:id` | `Phoenix.LiveViewTest.live/2` + `render_click/1` | VERIFIED | LiveView mounted; Preview button clicked; preview panel rendered; Confirm button clicked; DB side effects asserted |
| `recovery_loop_test.exs` | `Parapet.Operator.confirm_runbook_step/4` | All 4 API scenarios call this API directly | VERIFIED | Sequential confirm for conflict scenario; token read via `preview_result.preview["preview_token"]` |
| `.github/workflows/ci.yml` | `recovery_loop_test.exs` | `mix test --only smoke` picks up `@moduletag :smoke` | VERIFIED | Line 139; `ci.yml` unmodified in this phase |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `recovery_loop_test.exs` Scenario 5 | `confirm_html`, ActionItem state | `Phoenix.LiveViewTest` drives real LiveView `handle_event/3`; `RetryAsyncItem.execute/2` runs against sandbox DB; `DemoApp.Repo.update_all` on real ActionItem row | Yes — `"resolved"` state asserted via `DemoApp.Repo.get_by`; TimelineEntry + ToolAudit asserted via `DemoApp.Repo.exists?` | FLOWING |
| `recovery_loop_test.exs` Scenarios 1-4 | `confirm_result` | `Parapet.Operator.confirm_runbook_step/4` -> `RetryAsyncItem.execute/2` -> real sandbox DB mutation | Yes — TimelineEntry + ToolAudit written by core | FLOWING |
| `seeds.exs` incident 4 | `incident_stalled`, `_action_item` | `Parapet.Evidence.create_incident/1` + `DemoApp.Repo.insert/1` against demo DB | Yes — confirmed via `mix demo.reset` output | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 7 smoke tests pass (4 API + 1 LiveView + 2 pre-existing) | `cd examples/demo_app && mix test --only smoke` | `7 tests, 0 failures` (0.2s) | PASS |
| `mix.exs` demo.reset alias recognized | `grep "demo.reset" examples/demo_app/mix.exs` | Line 52: alias matches spec | PASS |
| `lazy_html` dep present | `grep "lazy_html" examples/demo_app/mix.exs` | Line 37: `{:lazy_html, ">= 0.1.0", only: :test}` | PASS |
| Seeds carry both `"module"` and `"steps"` keys for incident 4 | `grep '"steps"\\|"module"' priv/repo/seeds.exs` | Lines 156-157: both keys confirmed | PASS |
| `ci.yml` smoke wiring intact | `grep "mix test --only smoke" .github/workflows/ci.yml` | Line 139 matches | PASS |
| `release_gate` gates on demo | `grep "needs.*lint.*test.*demo" .github/workflows/ci.yml` | Line 142: `needs: [lint, test, demo]` | PASS |

### Probe Execution

No `probe-*.sh` files declared or present for this phase. Behavioral spot-checks above cover the equivalent functional verification.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEMO-05 | Plans 01-04 | Demo app seeded with capability-backed incident; Preview-able + Confirm-able step; seed runs as part of `mix setup`; replayable via `mix demo.reset` | SATISFIED | Seeds incident 4 with both `"module"` + `"steps"` keys + open ActionItem; `setup` alias confirmed; `demo.reset` confirmed; all 7 smoke tests pass |
| DEMO-06 | Plan 05 | CI demo lane exercises 4 scenarios; failures break build | SATISFIED | `recovery_loop_test.exs` has all 4 API `:smoke`-tagged scenarios + 1 LiveView scenario; `ci.yml` demo job runs `mix test --only smoke`; `release_gate needs: [lint, test, demo]` |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` markers found in any file delivered by this phase. No placeholder returns, hardcoded empty arrays in render paths, or orphaned stubs detected.

**Notes on root-cause fix (commit cdfc213):**

The prior verification flagged a browser-only click-through as unautomatable. The root cause was that the seeded incident lacked the `"steps"` key in `runbook_data`, so `WorkbenchContract.derive/3` found no inline steps and the Preview button never rendered in the UI. The fix adds `"steps"` alongside `"module"` to both `seeds.exs` and the test `setup` block. `Phoenix.LiveViewTest` (headless, in-process) now mounts the real LiveView, drives the same `phx-click` events as a browser operator would, and verifies DOM output + DB side effects. No browser is required.

### Human Verification Required

None. All previously-human items have been automated into CI via `Phoenix.LiveViewTest` Scenario 5.

### Gaps Summary

No gaps. All 11 observable truths verified. The previously-human browser click-through is now fully contract-tested headlessly in CI — `Phoenix.LiveViewTest` drives the identical `phx-click` events, asserts rendered panel content, and verifies all DB side effects. `mix test --only smoke` produces 7 tests, 0 failures. Both DEMO-05 and DEMO-06 requirements are satisfied. The `release_gate` CI gate remains wired with `needs: [lint, test, demo]`.

---

_Verified: 2026-05-28T21:00:00Z_
_Verifier: Claude (gsd-verifier)_
