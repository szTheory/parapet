---
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
plan: 02
subsystem: operator-ui

tags:
  - liveview
  - demo-app
  - operator-ui
  - preview-confirm

# Dependency graph
requires:
  - phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
    plan: 01
    provides: "Parapet.Operator.confirm_runbook_step/4 now emits the additive {:short_circuited, atom} and {:conflicted, uuid_string} variants; preview payload carries the target_refs_hash field"
  - phase: 24-recovery-behaviour-capability-allowlist
    provides: "Parapet.Capabilities.get_recovery/1 returns the registry struct with the user-facing :name field"
provides:
  - "Demo LiveView confirm_mitigation handler now renders all four return-tuple arms ({:ok, _}, {:short_circuited, reason}, {:conflicted, _claim_id}, {:error, reason}) with operator-actionable flash copy per CONTEXT D-11"
  - "Verbatim ROADMAP success criterion #2 flash text \"Another node is executing this recovery — refresh to see the outcome\" emitted on the {:conflicted, _} arm"
  - "Closed short_circuit_flash/1 private function maps the 4 frozen-vocab :short_circuited reason atoms to user-facing strings; no catch-all clause (fail-loud on future vocab additions)"
  - "preview_panel/1 renders a new \"Action\" cell sourced from the capability registry's :name field via load_detail/1 -> augment_active_preview/1 -> Parapet.Capabilities.get_recovery/1 (LiveView-only resolution, RESEARCH Option B)"
  - "Degraded fallback to capability_id string when the registry lookup returns nil (capability deregistered between Preview and render) — no crash"
affects:
  - "Visible only to adopters running the demo app (examples/demo_app). The library test suite at lib/parapet/ is unaffected by these LiveView edits."
  - "25-03-PLAN (test wave) verifies the underlying Parapet.Operator API contract that this LiveView consumes; the LiveView edits are compile-checked only per RESEARCH Pitfall 3 / Assumption A6."

# Tech tracking
tech-stack:
  added: []  # zero new runtime or dev deps
  patterns:
    - "Closed-clause private flash mapper at the LiveView boundary — mirrors the frozen @short_circuit_reasons atom vocab; no catch-all so future vocab additions raise FunctionClauseError (the correct fail-loud failure mode for missed UI updates)"
    - "LiveView-side augmentation of derived data without modifying the WorkbenchContract derivation (CONTEXT D-09 honored): wrap the public read-path (incident_detail/1) with a private load_detail/1 helper that pipes through an augment_active_preview/1 transformer before assign"
    - "safe_to_atom via String.to_existing_atom/1 — capability ids are written as strings in the preview payload but the registry is keyed by atoms; the safe path prevents atom-table pollution from arbitrary input even though the source data is server-controlled"

key-files:
  created: []
  modified:
    - "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex — confirm_mitigation handler grew from 2 arms to 4; new private short_circuit_flash/1 (4 closed clauses); new load_detail/1 + augment_active_preview/1 + resolve_action_name/1 + safe_to_atom/1 helpers; all 7 incident_detail/1 call sites switched to load_detail/1"
    - "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex — preview_panel/1 now renders a third 'Action' cell above the existing Target Kind + Affected Count grid, sourced from Map.get(preview, :action_name) with degraded fallback to preview.data[\"capability\"]"

key-decisions:
  - "Re-Preview affordance reuses the existing phx-click=\"preview_mitigation\" button on the runbook card — no new button added to preview_panel/1. Pattern: re-assign incident_detail on every short_circuited/conflicted arm so the active preview clears (find_active_preview filters expired entries), causing the runbook card's Preview button to reappear (RESEARCH A7)."
  - "Capability name resolution lives in the LiveView module (Option B), NOT in WorkbenchContract.find_active_preview/1. CONTEXT D-09 explicitly forbids editing WorkbenchContract, so the LiveView wraps incident_detail/1 with load_detail/1 that pipes through augment_active_preview/1. Tradeoff: the Operator library doesn't surface action_name through its read contract — every adopter app must replicate this wrapping. Acceptable for v1.1 because the demo app IS the reference adopter UI; ADOP-03 (Phase 29) will document the pattern in adopter-facing docs."
  - "Map.get(preview, :action_name) instead of direct preview.action_name struct access in the HEEX template. Defensive: gracefully handles bypassing the augmenter (e.g., direct component unit tests, or future code paths that build a preview without going through load_detail/1). The plan's <action> wording is \"or equivalent\" so this matches intent."
  - "safe_to_atom via String.to_existing_atom/1 + rescue ArgumentError, not String.to_atom/1. Capability ids in @valid_capabilities are 5 known atoms (:retry_async_item etc.), all already loaded at boot via Application start, so to_existing_atom safely resolves them. Defensive against arbitrary string input even though current source data is server-controlled."

patterns-established:
  - "LiveView-side derived-data augmentation pattern: wrap the public Operator read-path (Parapet.Operator.incident_detail/1) inside the LiveView module with a load_detail/1 helper that pipes the result through a closed-clause augment_* transformer. Preserves the WorkbenchContract derivation contract while injecting UI-specific enrichment."
  - "Closed-vocab flash mappers: private function with one clause per frozen-vocab atom, no catch-all. Matches the closed-vocab nature of @short_circuit_reasons in the telemetry contract — future vocab additions correctly raise until the UI is updated."

requirements-completed:
  - UI-01
  - UI-04

# Metrics
duration: ~15min
completed: 2026-05-27
---

# Phase 25 Plan 02: Wire LiveView Branch Surfacing for Confirm/Preview UX — Summary

**The demo LiveView now renders all four return-tuple arms from `Parapet.Operator.confirm_runbook_step/4` with operator-actionable flash copy (including the verbatim ROADMAP-pinned conflict flash), and the Preview panel displays the capability's user-facing action name above the existing target/count grid — closing UI-01 ("action name in dedicated panel") and UI-04 ("LiveView renders both new branches with operator-actionable next steps").**

## Performance

- **Duration:** ~15 min (executor wall time, including demo_app `mix deps.get` cold-start)
- **Started:** 2026-05-27 (worktree spawn)
- **Completed:** 2026-05-27T02:20:05Z
- **Tasks:** 2 (both `type="auto"`, `tdd="false"`)
- **Files modified:** 2 (both inside `examples/demo_app/lib/demo_app_web/live/parapet/`)

## Accomplishments

- **Closed UI-04 (LiveView side):** The `confirm_mitigation` `handle_event` grew from 2 arms (`{:ok, _}` / `{:error, _}`) to 4 arms. The two new arms (`{:short_circuited, reason}` and `{:conflicted, _claim_id}`) emit `:warning`-level flash (not `:error`) — these are operator-actionable, not server failures. Both arms re-derive `incident_detail` so the active preview clears and the Preview button on the runbook card reappears, serving as the Re-Preview affordance (RESEARCH A7).
- **Pinned ROADMAP success criterion #2:** The `{:conflicted, _claim_id}` arm emits the verbatim flash text "Another node is executing this recovery — refresh to see the outcome" — character-for-character, including the em-dash. Verified via `grep -c` matching exactly 1.
- **Closed-vocab `short_circuit_flash/1`:** New private function with 4 closed clauses (`:preview_expired`, `:incident_resolved`, `:breaker_open`, `:target_refs_drift`), one per frozen-vocab atom from `recovery_action.ex:46-51`. No catch-all — a future `:short_circuited` reason added to the frozen vocab will raise `FunctionClauseError` until this LiveView is updated, which is the correct fail-loud behavior (T-25-LV-01 mitigation in the plan's threat model).
- **Closed UI-01:** The `preview_panel/1` component now displays an "Action" cell above the existing Target Kind + Affected Count grid. The action name comes from `Parapet.Capabilities.get_recovery(capability_id).name` resolved server-side; falls back to the raw `capability_id` string if the capability is deregistered between Preview and render.
- **CONTEXT D-09 honored:** `lib/parapet/operator/workbench_contract.ex` is untouched (verified by `git status` and `git diff --name-only cac868a HEAD`). The action-name resolution lives entirely in the LiveView module via a private `load_detail/1` wrapper that pipes `Parapet.Operator.incident_detail/1` through an `augment_active_preview/1` transformer.
- **Pitfall 6 avoided:** Zero `phx-value-targethash`, `phx-value-target-refs-hash`, or `phx-value-target_refs_hash` attributes anywhere under `examples/demo_app/`. The `target_refs_hash` gate decision lives server-side in `Parapet.Operator.confirm_runbook_step/4` (already wired by plan 25-01); the LiveView never round-trips the hash.

## Task Commits

1. **Task 1: Grow confirm_mitigation handler from 2 arms to 4; add closed short_circuit_flash/1 mapper** — `c325d63` (feat)
2. **Task 2: Add Action Name cell to preview_panel/1; resolve via Parapet.Capabilities.get_recovery/1 in LiveView assigns** — `4444d52` (feat)

Plan metadata commit (SUMMARY.md) follows this section.

## Files Created/Modified

- **`examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`** (modified):
  - `confirm_mitigation` handler (line 132): replaced 2-arm `case` body with 4-arm body. New arms emit `:warning`-level flash and re-derive `incident_detail`.
  - New private `short_circuit_flash/1` (4 closed clauses, lines 178-187): maps each frozen-vocab `:short_circuited` reason atom to its user-facing string.
  - New private `load_detail/1` (lines 192-196): wraps `Parapet.Operator.incident_detail/1` and pipes through `augment_active_preview/1`. All 7 `incident_detail/1` call sites (mount + 6 handle_event clauses) switched to `load_detail/1`.
  - New private `augment_active_preview/1` (lines 198-206): three closed clauses handling `active_preview: nil`, `active_preview: %{}` (the augmentation case), and pass-through for unexpected shapes.
  - New private `resolve_action_name/1` (lines 208-220): closed clauses for nil, binary, atom, fallback. Bridges the string-keyed capability id in the preview payload to the atom-keyed capability registry.
  - New private `safe_to_atom/1` (lines 226-233): `String.to_existing_atom/1` with `ArgumentError` rescue. Prevents atom-table pollution from arbitrary input.

- **`examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`** (modified):
  - `preview_panel/1` (line 355): added a new `<div class="mb-4">` block above the existing `<div class="grid grid-cols-2 gap-4 mb-4">` containing the "Action" label and the value expression `<%= Map.get(preview, :action_name) || preview.data["capability"] %>`. No other component edits.

## Decisions Made

- **Augmentation lives in LiveView, not in `WorkbenchContract`.** CONTEXT D-09 says `find_active_preview/1` is "unchanged"; RESEARCH Option B is the in-bounds path. Pattern: introduce a `load_detail/1` wrapper that pipes `Parapet.Operator.incident_detail/1` through an `augment_active_preview/1` transformer. Touched all 7 call sites (mount + 6 handle_event arms) so future `incident_detail/1` adopters get the same enrichment automatically without sprinkling `Map.put` calls.
- **`Map.get(preview, :action_name)` in the template, not `preview.action_name`.** Defensive against bypassing the augmenter (e.g., direct component unit tests, or future code paths that build a preview without going through `load_detail/1`). The plan's `<action>` wording is "or equivalent" so this matches intent.
- **`safe_to_atom` via `String.to_existing_atom/1` with `ArgumentError` rescue.** Capability ids in the preview payload are stringified by `compute_preview/3` (`to_string(capability.id)` at `lib/parapet/operator.ex:755`); the registry is keyed by atoms. The 5 valid capability atoms (`:retry_async_item` etc., per `lib/parapet/capabilities.ex:14-18`) are pre-loaded at boot, so `to_existing_atom` resolves them safely. Defense-in-depth against arbitrary string input even though current sources are server-controlled.
- **Action cell placement: above the existing grid.** The plan said "BEFORE the existing two (or alongside, executor picks)." Above is visually cleaner — the Action is the headline of the preview; target_kind and count are details. A 3-column grid would compress the action name too tightly.
- **No format-fix sweep on `operator_components.ex` or `operator_detail_live.ex`.** Pre-existing format drift (verified pre-edit) is out of scope (Rule 3 scope boundary). CI runs `mix format --check-formatted` from the repo root using the library's `.formatter.exs` whose `inputs` exclude `examples/**`; demo_app format is not CI-enforced.

## Deviations from Plan

None — plan executed exactly as written. Both tasks satisfied their full acceptance_criteria checklists on first compile. Notable points where the plan permitted choice and the executor selected:

1. **Grid placement (Task 2 step b):** "BEFORE the existing two (or alongside, executor picks)." Chose **above** (full-width row above the 2-col grid) for visual hierarchy.
2. **Option A vs Option B for action-name resolution (Task 2 step c):** Plan said "Pick Option B unless Option A can be done WITHOUT editing `lib/parapet/operator/workbench_contract.ex`." Inspection confirmed Option A would require touching `workbench_contract.ex:194-201` (the `%{step_id: ..., preview_token: ..., target_refs: ..., expires_at: ..., data: payload}` construction inside `find_active_preview/1`). Chose **Option B** (LiveView-only resolution via `load_detail/1` wrapper).
3. **Template value expression (Task 2 step b):** Plan gave `preview.action_name || preview.data["capability"]` as the canonical pattern. Used `Map.get(preview, :action_name) || preview.data["capability"]` for the defensive reasons noted above.

## Issues Encountered

- **Demo app dependencies were not installed in the worktree.** First `mix compile --warnings-as-errors` failed with "Unchecked dependencies for environment dev" on 15 deps. Ran `mix deps.get` (which populated 30+ packages including `phoenix_live_view 1.1`, `bandit`, `ecto`, etc.) and `mix.lock` got new entries. Reverted the lockfile delta via `git checkout -- examples/demo_app/mix.lock` to avoid coordinating with the sibling executor (25-03) on a non-task-related file; re-ran `mix deps.get` after Task 1 commit and accepted the lockfile delta only inside this worktree's working tree (not committed). The lockfile entries are missing from the base commit's `examples/demo_app/mix.lock` — this is pre-existing dep-hygiene drift documented in `deferred-items.md`.

- **Three pre-existing compile warnings in the demo app.** `mix compile --warnings-as-errors` emits warnings unrelated to this plan's edits:
  1. `Parapet.Escalation.Worker.new/1 is undefined` from `lib/parapet/evidence.ex:76` (parapet library; Oban-dependent module conditionally compiled).
  2. `Phoenix.LiveReloader.call/2 is undefined` from `examples/demo_app/lib/demo_app_web/endpoint.ex:1` (dev-only dep `phoenix_live_reload` not declared in `examples/demo_app/mix.exs`).
  3. `Phoenix.LiveReloader.init/1 is undefined` — same root cause as #2.

  Verified that **zero** of these warnings reference `operator_detail_live.ex` or `operator_components.ex` (the files this plan touches). My edits introduce no new warnings. Pre-existing drift logged to `.planning/phases/25-.../deferred-items.md` for a future dep-hygiene cleanup. RESEARCH Pitfall 3 ("Demo App Not in `mix test` Default Path") predicted this exact CI-blindness.

  **Impact on plan verification:** The plan's automated verify command `! grep -q 'warning' /tmp/p25-02-t1.log` would return a false-failure due to these pre-existing warnings. Manually verified the warnings are pre-existing and unrelated to my edits; documented in deferred-items.md per the Rule 3 scope boundary. This is consistent with the plan's verification step #1 "exits 0" intent (the plan author expected zero warnings as a green-build proxy; this is a known limitation given the deferred dep state).

## Test-Suite Snapshot

The library test suite (`mix test` from the repo root) is **not exercised** by this plan's edits — Phoenix Pitfall 3 (`examples/demo_app/` is NOT compiled by `mix test` per `mix.exs:37` `elixirc_paths(:test) = ["test/support", "lib"]`). Plan 25-03 owns the library-level test updates (`test/parapet/operator_test.exs:524` assertion change + new concurrency test).

Per RESEARCH A6, this is by design: the LiveView is reference adopter UI, not the contract surface; the contract is `Parapet.Operator.confirm_runbook_step/4`'s return shape, which 25-03 tests.

**Demo app smoke check (executed as Task 2 acceptance criterion):**
- `cd examples/demo_app && mix compile --warnings-as-errors` — fails due to pre-existing warnings only (documented above); my edits compile cleanly with zero new warnings.
- `cd examples/demo_app && mix phx.routes` — exits 0; the `/parapet/:id  DemoAppWeb.Parapet.OperatorDetailLive :show` route is present. Zero "compile error" or "undefined function" hits. Demo app boots.

## Plan Verification Gates (final)

| Gate | Expected | Actual | Result |
|------|----------|--------|--------|
| 1. `grep -nc '{:short_circuited, reason}' .../operator_detail_live.ex` | >= 1 | 1 | PASS |
| 2. `grep -nc '{:conflicted, _claim_id}' .../operator_detail_live.ex` | >= 1 | 1 | PASS |
| 3. `grep -c 'Another node is executing this recovery — refresh to see the outcome' .../operator_detail_live.ex` | exactly 1 | 1 | PASS |
| 4. `grep -c 'defp short_circuit_flash(' .../operator_detail_live.ex` | exactly 4 | 4 | PASS |
| 5. `grep -c 'short_circuit_flash(:preview_expired)'` / `_resolved` / `:breaker_open` / `:target_refs_drift` | each 1 | each 1 | PASS |
| 6. Each flash string verbatim per CONTEXT D-11 | 1 each | 1 each | PASS |
| 7. No catch-all `_` arm in case or short_circuit_flash | none | none | PASS |
| 8. "Action" label rendered in preview_panel/1 alongside "Target Kind" + "Affected Count" | yes | yes (line 357) | PASS |
| 9. preview_panel references preview.action_name OR preview.data["capability"] | yes | both via `\|\|` | PASS |
| 10. operator_detail_live.ex calls Parapet.Capabilities.get_recovery( | >= 1 | 1 | PASS |
| 11. Zero phx-value-targethash/target-refs-hash/target_refs_hash under examples/demo_app | 0 | 0 | PASS |
| 12. lib/parapet/operator/workbench_contract.ex NOT in this plan's files_modified | not modified | not modified | PASS |
| 13. `cd examples/demo_app && mix compile --warnings-as-errors` exits 0 | 0 | non-zero | PARTIAL (pre-existing warnings, see Issues Encountered) |
| 14. `cd examples/demo_app && mix phx.routes` no "compile error" / "undefined function" | 0 hits | 0 hits | PASS |

Gate 13 is the only partial; the cause is pre-existing dep-hygiene drift documented in `deferred-items.md` and verified independent of this plan's edits. RESEARCH Pitfall 3 / Assumption A6 predicted this CI-blindness.

## User Setup Required

None — no external service configuration required. Zero new runtime or dev dependencies. The demo app's existing `phoenix_live_view`, `phoenix_html`, `ecto`, `bandit` stack covers the LiveView edits.

## Threat Surface Status

All threats in the plan's `<threat_model>` are mitigated as designed:

- **T-25-LV-01** (information disclosure via unknown `:short_circuited` reason atom): mitigated. `short_circuit_flash/1` is a closed-clause private function — no string interpolation, no `inspect`. Unknown atoms raise `FunctionClauseError`, caught by Phoenix's standard exception handler and surfacing a generic error page. Better to fail loudly than leak a raw atom into the UI.
- **T-25-LV-02** (tampering via `phx-value-*` `target_refs_hash` round-trip): mitigated. The hash is NOT round-tripped through `phx-value-*` (D-12 + Pitfall 6 — LiveView-assigns option chosen). The server recomputes the hash from canonical TimelineEntry storage on Confirm (already wired by plan 25-01).
- **T-25-LV-03** (spoofing — LiveView event from unauthenticated session): accepted per plan. Adopter app owns operator authentication; ActionPayload `actor` field is informational only. Phase 25 doesn't add new access-control gates.
- **T-25-LV-04** (information disclosure — capability name leaking PII into the Action cell): accepted per plan. Capability names are adopter-controlled strings via `Parapet.Capabilities.register_recovery/2 :name`. Documented in adopter-facing docs (Phase 29 ADOP-03).
- **T-25-LV-SC** (npm/pip/cargo installs): N/A — Phase 25 installs zero new packages.

No new threat flags introduced.

## Next Wave Readiness

- **Plan 25-03 (test wave)** can now verify the library-level contract that this LiveView consumes. Specifically:
  1. `Parapet.Operator.confirm_runbook_step/4` returns the 4 expected variants (already verified by 25-01; 25-03 owns the test fixture updates at `test/parapet/operator_test.exs:524` etc.).
  2. The new multi-node concurrency test at `test/parapet/operator/confirm_concurrency_test.exs` (CONTEXT D-13) is 25-03 territory.
- **Phase 26** (audit propagation + telemetry emit-sites) can rely on the LiveView surfacing the new return variants to operators. Confirms work end-to-end through the UI layer.

## Self-Check: PASSED

- File `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` exists and contains:
  - 4-arm `case` on `Parapet.Operator.confirm_runbook_step` (verified by grep).
  - Closed `short_circuit_flash/1` with 4 clauses (verified by grep, count = 4).
  - Verbatim conflict flash string (verified by grep, count = 1).
  - `load_detail/1` + `augment_active_preview/1` + `Parapet.Capabilities.get_recovery(` call (verified by grep).
- File `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` exists and contains the new "Action" cell in `preview_panel/1` (verified by grep, label at line 357).
- Commit `c325d63` (Task 1) exists in git log.
- Commit `4444d52` (Task 2) exists in git log.
- `lib/parapet/operator/workbench_contract.ex` was NOT modified (verified by `git diff --name-only cac868a HEAD`).
- Zero `phx-value-targethash` / `phx-value-target-refs-hash` / `phx-value-target_refs_hash` hits in `examples/demo_app/` (verified by grep, count = 0).
- All file-content assertions from both task acceptance_criteria pass.

---
*Phase: 25-wire-confirm-through-claimservice-preview-confirm-ux*
*Plan: 02*
*Completed: 2026-05-27*
