---
phase: 25
slug: wire-confirm-through-claimservice-preview-confirm-ux
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-29
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18) |
| **Config file** | `test/test_helper.exs`, `test/support/concurrency_bootstrap.ex` |
| **Quick run command** | `mix test test/parapet/operator_test.exs test/parapet/operator/` |
| **Full suite command** | `mix test` |
| **Concurrency-inclusive command** | `mix test --include unboxed` |
| **Demo-app compile-check** | `cd examples/demo_app && mix compile --warnings-as-errors` |
| **Estimated runtime** | ~25 seconds (quick), ~90 seconds (full incl. concurrency) |

---

## Sampling Rate

- **After every task commit:** Run quick command for the file(s) being modified
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green, including `mix test --include unboxed` AND `cd examples/demo_app && mix compile --warnings-as-errors`
- **Max feedback latency:** ~25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-T1 | 25-01 | 1 | UI-03 | T-25-02 | target_refs_hash computed AFTER host_data merge; canonicalized via Enum.map(&to_string/1) (Pitfalls 2 + 5) | source assertion + compile | `mix compile --warnings-as-errors` + grep gates | lib/parapet/operator.ex (modify) | green |
| 25-01-T2 | 25-01 | 1 | UI-02, UI-04 | T-25-01, T-25-03, T-25-04 | 4-arm ClaimService.claim_action dispatch with action_kind: "operator"; string→atom mapper closes adopter-leak surface | source assertion + compile + dialyzer | `mix compile --warnings-as-errors` + `mix dialyzer` + grep gates | lib/parapet/operator.ex (modify) | green |
| 25-02-T1 | 25-02 | 2 | UI-04 | T-25-LV-01 | 4-arm LiveView handler; closed short_circuit_flash/1 (no catch-all clause) | source assertion + compile | `cd examples/demo_app && mix compile --warnings-as-errors` + grep gates for verbatim flash strings | examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex (modify) | green (compile); visual → Manual-Only |
| 25-02-T2 | 25-02 | 2 | UI-01 | T-25-LV-02, T-25-LV-04 | Action Name resolved server-side via Parapet.Capabilities.get_recovery; no phx-value-* hash round-trip | source assertion + compile | `cd examples/demo_app && mix compile --warnings-as-errors` + grep gates | examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex (modify) | green (compile); visual → Manual-Only |
| 25-03-T1 | 25-03 | 2 | UI-03 | T-25-01 | Updated assertion proves :stale_preview replaced with :short_circuited :preview_expired | test command | `mix test test/parapet/operator_test.exs` | test/parapet/operator_test.exs (modify) | green |
| 25-03-T2 | 25-03 | 2 | UI-03 | T-25-01, T-25-02 | :preview_expired and :target_refs_drift branch coverage + nil-hash legacy compat | test command | `mix test test/parapet/operator/preview_lifecycle_test.exs` | test/parapet/operator/preview_lifecycle_test.exs (new) | green |
| 25-03-T3 | 25-03 | 2 | UI-02, UI-04 | T-25-04, T-25-T-01, T-25-T-02 | Multi-node race produces 1 {:ok, _} + 1 {:conflicted, _claim_id}; claim row action_kind == "operator" | test command (3x for flake check) | `mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed` | test/parapet/operator/confirm_concurrency_test.exs (new) | green |
| 25-CR-01 | review | post | UI-02 | T-25-01 | incident_state_gate is allow-list driven; operator passes ["open","investigating"] so Acknowledge-then-Confirm succeeds; resolved still honestly short-circuits | test command | `mix test test/parapet/operator/preview_lifecycle_test.exs` | lib/parapet/automation/claim_service.ex + lib/parapet/operator.ex (commits 65e5ee5, 790541b) | green |
| 25-CR-02 | review | post | UI-02 | T-25-04 | ClaimService.mark_failed/2 (status failed_retryable + last_error_*); steal_expired_claim re-grants; operator error arm releases claim → no 5-min lockout | test command | `mix test test/parapet/automation/claim_service_test.exs --include unboxed` | lib/parapet/automation/claim_service.ex + lib/parapet/spine/action_claim.ex | green |
| 25-CR-03 | review | post | UI-04 | T-25-03 | capability.execute wrapped in try/rescue → {:error, {:capability_raised, msg}}; claim released via mark_failed; no raw string leak to adopters | test command | `mix test test/parapet/operator/preview_lifecycle_test.exs` | lib/parapet/operator.ex | green |

*Status: pending · green · red · flaky*

> **Audit note (2026-05-29):** Statuses promoted pending → green after empirically re-running the suites: `operator_test.exs` + `preview_lifecycle_test.exs` (26 tests, 0 failures incl. `--include unboxed`) and `confirm_concurrency_test.exs` (1 unboxed test, 0 failures). Full library suite was green at 483 tests, 0 failures at verification (2026-05-28T07:25Z); no lib/test drift since (commits 65e5ee5 + 790541b unchanged). Rows 25-CR-01..03 added to record the code-review fix coverage that landed after the original 7 tasks. Demo-app LiveView tasks (25-02-T1/T2) are compile-verified green; their visual rendering remains Manual-Only (demo app is outside the library `mix test` path — RESEARCH Pitfall 3; CI demo lane is explicit Phase 28 scope).

---

## Wave 0 Requirements

> The standard Wave 0 pattern (failing tests scaffolded BEFORE implementation) is not strictly applied in this phase because the operator-API rewire (plan 25-01) is the centralized edit that all tests depend on. Instead, plan 25-01 lands in Wave 1; plans 25-02 (LiveView) and 25-03 (tests) run in parallel in Wave 2.
>
> The post-plan-01 test coverage explicitly addresses every Wave 0 gap from RESEARCH.md "Wave 0 Gaps" (:739-748):

- [x] test/parapet/operator/confirm_concurrency_test.exs (UI-02, UI-04) — owned by plan 25-03 task 3
- [x] test/parapet/operator/preview_lifecycle_test.exs (UI-03, UI-04 short-circuit shape) — owned by plan 25-03 task 2
- [x] Update existing test/parapet/operator_test.exs:524 (:stale_preview → :preview_expired) — owned by plan 25-03 task 1
- [x] Demo-app compile-check (LiveView edits) — owned by plan 25-02 tasks 1 + 2 verification commands
- [ ] (Out of scope per D-16 default) Telemetry-emit assertions — deferred to Phase 26 where emit-site coverage will be locked in

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Demo LiveView renders the 4 confirm-arm flash strings + Action Name cell + Re-Preview affordance (existing Preview button reappears) | UI-01, UI-04 | Demo app is not in default `mix test` path; LiveView visual states need browser confirmation | Boot the demo app: `cd examples/demo_app && mix setup && mix phx.server`. Navigate to a seeded incident. Click Preview → verify Action Name appears in panel. Force each branch: (a) expire token via SQL `UPDATE parapet_timeline_entries SET payload = jsonb_set(payload, '{expires_at}', to_jsonb('2020-01-01T00:00:00Z'::text)) WHERE type = 'recovery_preview' AND incident_id = '...'` then click Confirm → flash: "Preview expired — please re-Preview before confirming"; (b) race two browser sessions clicking Confirm simultaneously → one sees the success flash, the other sees verbatim "Another node is executing this recovery — refresh to see the outcome"; (c) tamper with `target_refs` via SQL UPDATE without updating the hash, then Confirm → flash: "Target state changed since Preview — please re-Preview". |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 25s for quick command (operator_test.exs + preview_lifecycle_test.exs)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved

---

## Validation Audit 2026-05-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Verdict:** NYQUIST-COMPLIANT. Every Phase-25 requirement (UI-01..UI-04) has automated verification at the library-contract level, confirmed green by re-running the suites (operator + preview-lifecycle: 26 tests; confirm-concurrency: 1 unboxed test; all 0 failures). The three code-review fixes (CR-01/02/03) each carry green regression tests. The only un-automated items are demo-app LiveView visual renders, which are correctly recorded under Manual-Only Verifications and whose CI automation is an explicit Phase 28 deliverable (not a gap). No test files generated — nothing was missing.
