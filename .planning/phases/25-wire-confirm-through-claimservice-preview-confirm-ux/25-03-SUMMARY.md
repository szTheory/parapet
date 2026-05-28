---
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
plan: 03
subsystem: operator-tests

tags:
  - tests
  - concurrency
  - preview-lifecycle
  - claim-service
  - dummy-repo

# Dependency graph
requires:
  - phase: 25-wire-confirm-through-claimservice-preview-confirm-ux/plan-01
    provides: "Parapet.Operator.confirm_runbook_step/4 routed through ClaimService.claim_action/1 with action_kind: \"operator\"; new return variants {:short_circuited, :preview_expired | :target_refs_drift | :incident_resolved | :breaker_open} and {:conflicted, uuid_string}; target_refs_hash field surfaced by find_recent_preview/3"
  - phase: 23-foundations-telemetry-contract-lease-until-migration
    provides: "parapet_action_claims schema + (incident_id, action_kind, action_key) unique constraint + lease_until self-heal; @short_circuit_reasons + @action_kinds frozen vocabs"
  - phase: 24-recovery-behaviour-capability-allowlist
    provides: "Parapet.Capabilities Agent with register_recovery + get_recovery; 5-atom allowlist"
provides:
  - "Unit test coverage for the new {:short_circuited, :preview_expired} branch (kept as a regression marker in test/parapet/operator_test.exs:524 and a canonical home in test/parapet/operator/preview_lifecycle_test.exs)"
  - "Unit test coverage for the new {:short_circuited, :target_refs_drift} branch via post-write target_refs tamper + recorded-hash mismatch"
  - "Backward-compatibility test for pre-Phase-25 stored previews (no target_refs_hash field) — the drift gate's nil-safe guard must let confirm proceed"
  - "Pitfall 5 regression guard: target_refs canonicalization stable across atom-vs-string round-trip (the jsonb storage roundtrip coerces atoms to strings; target_refs_hash/1's `Enum.map(&to_string/1) |> Enum.sort` must yield the same hash either way)"
  - "Multi-node concurrency proof for the operator-confirm path: two simulated operators racing Confirm against the same (incident_id, action_kind: \"operator\", action_key) claim row yield exactly one {:ok, _} winner and one {:conflicted, claim_id} loser, with the claim_id matching a parapet_action_claims row with status=\"executed\", action_kind=\"operator\""
  - "Extended DummyRepo in test/parapet/operator_test.exs that handles ClaimService.claim_action/1's raw 0-arity function transaction protocol (transaction(fun), insert_all/3 with on_conflict, aggregate/3, one!/1, update!/1) — closes the Wave 1 known red"
affects:
  - "26-* phases (audit propagation + RecoveryAction emit-site wiring) inherit the now-fully-tested operator path"
  - "27-* phases (prebuilt playbooks) can rely on the proven claim-protected confirm semantics"

# Tech tracking
tech-stack:
  added: []  # zero new runtime or dev deps
  patterns:
    - "BareRepo-style DummyRepo extension: synchronous unit-test repo that handles both Ecto.Multi-driven transactions AND raw-function transactions (the latter for ClaimService.claim_action/1). Stubs insert_all/3 to deliver the first-caller-wins claim path so the synchronous unit happy-path test can flow through ClaimService and reach capability.execute."
    - "ConcurrencyCase + unboxed_run + Task.async rendezvous (verbatim pattern from executor_concurrency_test.exs / claim_service_test.exs) — now the third operator-side caller of the pattern. Adds explicit Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end) inside unboxed_run (Pitfall 4 mitigation — ConcurrencyCase only resets DB tables, not the Capabilities Agent)."
    - "Post-write payload-tamper pattern for hash-drift testing: write a Preview via Operator.preview_runbook_step/3 (which records target_refs_hash), then Map.put(preview, \"target_refs\", [\"tampered\"]) BEFORE injecting via Process.put(:mock_entries, [entry]) — the stored target_refs are tampered but the stored target_refs_hash still encodes the original list."
    - "Atom-vs-string canonicalization regression guard: a capability whose preview/2 returns atom target_refs, then a 'rehydrated' confirm-side payload with stringified target_refs, verifying target_refs_hash/1 produces identical hashes for both."

key-files:
  created:
    - "test/parapet/operator/preview_lifecycle_test.exs — 4 tests covering :preview_expired (isolated copy), :target_refs_drift (post-write tamper), nil-hash legacy-preview backward-compat, and atom-vs-string canonicalization (Pitfall 5)"
    - "test/parapet/operator/confirm_concurrency_test.exs — 1 @tag :unboxed test proving multi-node Confirm race: exactly one {:ok, _} + one {:conflicted, claim_id}, claim_id matches winner's parapet_action_claims row (action_kind=\"operator\", action_key=\"op_step\", status=\"executed\")"
  modified:
    - "test/parapet/operator_test.exs — DummyRepo extended for ClaimService's raw-fun transaction protocol (transaction(fun), insert_all/3, aggregate/3, one!/1, update!/1); legacy :stale_preview assertion at the recovery-execution describe block updated to {:short_circuited, :preview_expired}; setup block now Process.put(:mock_incident, incident) so DummyRepo.one!/1 returns the test incident for ClaimService.lock_incident/3"

key-decisions:
  - "Extended the existing inline DummyRepo in operator_test.exs rather than creating a new top-level BareRepo module. The synchronous unit-test harness only needs the 'first caller wins' code path; a full new module would have duplicated everything. Kept the changes contained to the file that needed them, with extensive @moduledoc-level comments explaining the dual transaction protocol."
  - "Cloned a private DummyRepo into preview_lifecycle_test.exs rather than extracting a shared helper. Two reasons: (a) the existing DummyRepo lives inside the OperatorTest module and isn't accessible from other test files, (b) extracting now would touch test/support and risk a broader-scope refactor than this plan's charter allows. Kept duplication local; future refactor can extract if a third file needs it."
  - "Test 4 (atom-vs-string Pitfall 5 guard) implemented as a full test, not skipped. The implementation re-registers the capability with atom target_refs in the test body itself (overriding the setup's string-based capability), so it's surgical and doesn't leak into the other tests."
  - "Did NOT add a separate synchronous unit test for {:conflicted, claim_id} return shape. The multi-node concurrency test exercises the wrap-to-2-tuple translation in the real (unboxed_run + ConcurrencyRepo) harness, which is stronger evidence than mocking the conflict. The PATTERNS map called this out as plan-phase discretion; the concurrency proof is sufficient."

patterns-established:
  - "DummyRepo + Process.put + ClaimService: the synchronous unit-test pattern for operator-API tests now flows the full preview->confirm->ClaimService->execute->mark_executed chain via process-dictionary-backed mocks. Future operator-API tests can clone this shape."
  - "Multi-node Confirm race proof: the third instance of the Task.async rendezvous + :go broadcast pattern (after Executor and ClaimService). Operators racing on the same idempotency_key are the contention scope; different keys would not collide."
  - "Pitfall 4 mitigation as a contract: every concurrency test that touches Capabilities MUST reset the Agent inside unboxed_run before register_recovery. ConcurrencyCase does NOT do this for us."

requirements-completed:
  - UI-02
  - UI-03
  - UI-04

# Metrics
duration: ~6min
completed: 2026-05-28
---

# Phase 25 Plan 03: Verification Scaffolding for Operator Confirm Path — Summary

**Provides unit coverage for the two new short-circuit branches (`:preview_expired`, `:target_refs_drift`) and a multi-node concurrency proof for the operator-confirm path. Closes the Wave 1 known red (operator_test.exs:495 happy-path) by extending the inline `DummyRepo` to handle `ClaimService.claim_action/1`'s raw-function transaction protocol.**

## Performance

- **Duration:** ~6 min (executor wall time)
- **Started:** 2026-05-28T02:17:56Z
- **Completed:** 2026-05-28T02:23:50Z
- **Tasks:** 3 (all `type="auto"`, `tdd="false"`)
- **Files created:** 2
- **Files modified:** 1

## Accomplishments

- **Closed the Wave 1 known red.** Plan 25-01 routed `confirm_runbook_step/4` through `ClaimService.claim_action/1`, which passes a raw 0-arity function to `repo.transaction/1`. The existing inline `DummyRepo.transaction/1` only accepted `Ecto.Multi`, causing the happy-path test at `test/parapet/operator_test.exs:495` to crash with `Ecto.Multi.to_list/1` `no function clause matching`. Extended `DummyRepo` with `transaction(fun)`, `insert_all/3` (stubbed to deliver "first-caller-wins"), `one!/1`, `aggregate/3` (returns 0 so the breaker stays open), and `update!/1`. `mix test test/parapet/operator_test.exs` is now 14/14 green.
- **Updated the legacy `:stale_preview` assertion** at the renamed `confirm_runbook_step executes and short-circuits expired previews with :preview_expired` test in `operator_test.exs`. The only test-side reference to `:stale_preview` is gone (`grep -rn ':stale_preview' test/` returns zero).
- **Created `test/parapet/operator/preview_lifecycle_test.exs`** with 4 tests covering:
  1. `{:short_circuited, :preview_expired}` for expired tokens (isolated canonical copy).
  2. `{:short_circuited, :target_refs_drift}` via post-write target_refs tamper that leaves the recorded hash intact.
  3. Backward compatibility: a stored preview without a `target_refs_hash` field (simulating a pre-Phase-25 write) must NOT short-circuit on drift — the gate's nil-safe guard at `operator.ex:712` lets confirm proceed.
  4. Pitfall 5 regression guard: target_refs canonicalization is stable across atom-vs-string round-trip. A capability returning `[:item_a, :item_b]` (atoms) and a rehydrated stored payload with `["item_a", "item_b"]` (strings) yield identical hashes.
- **Created `test/parapet/operator/confirm_concurrency_test.exs`** with one `@tag :unboxed` test proving:
  - Two operators race `Operator.confirm_runbook_step/4` against the same `(incident_id, action_kind: "operator", action_key: "op_step")` after each takes the same preview.
  - Exactly one task gets `{:ok, _}` (the winner); exactly one gets `{:conflicted, claim_id}` (the loser).
  - Exactly one `:executed` side-effect fires (assert_receive + refute_receive — the winner's `capability.execute` callback ran, the loser's never did).
  - The conflict's `claim_id` is a UUID string that resolves to a `parapet_action_claims` row with `status="executed"`, `action_kind="operator"`, `action_key="op_step"`.
  - Sanity: the unique constraint at `parapet_action_claims (incident_id, action_kind, action_key)` keeps exactly one row.
  - Includes the Pitfall 4 mitigation: `Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)` inside `unboxed_run` before `register_recovery`.

## Task Commits

1. **Task 1: Update DummyRepo for ClaimService raw-fun txn + `:preview_expired` assertion** — `88ea82a` (test)
2. **Task 2: Add `preview_lifecycle_test.exs` for new short-circuit branches** — `a7558f3` (test)
3. **Task 3: Add `confirm_concurrency_test.exs` proving multi-node Confirm race** — `5712754` (test)

## Files Created/Modified

### `test/parapet/operator_test.exs` (modified)

Three changes:

1. **`DummyRepo` extension** (lines ~8-130 in the new shape): added `transaction(fun)` clause for the raw 0-arity function protocol, `insert_all/3` for `ActionClaim` that always grants the claim, `aggregate/3` returning 0 (breaker stays open), `one!/1` for `lock_incident`, and `update!/1` for the `mark_executed` changeset path. Extensive `@moduledoc` comments explain why each function is needed and what `ClaimService` calls into.
2. **Recovery-execution setup block** (around line 547): added `Process.put(:mock_incident, incident)` so `DummyRepo.one!/1` returns the same struct that `ClaimService.lock_incident/3` queries for — keeps the open-state gate green during the happy-path confirm flow.
3. **Renamed and updated** the existing `confirm_runbook_step executes and rejects stale previews` test to `confirm_runbook_step executes and short-circuits expired previews with :preview_expired`. The assertion changed from `{:error, :stale_preview}` to `{:short_circuited, :preview_expired}`.

### `test/parapet/operator/preview_lifecycle_test.exs` (created)

307 lines. Four tests, all `async: false` (Process-dictionary-based mocks leak across parallel tests). Ships its own inline `DummyRepo` clone of the one in `operator_test.exs` (kept private to this module — see "Key Decisions"). Inline `LifecycleRunbook` declares the `:retry` step. Setup registers `:retry_async_item` with a preview callback that returns a non-empty `target_refs` list and an execute callback that returns `{:ok, :executed}`. Tests are described above.

### `test/parapet/operator/confirm_concurrency_test.exs` (created)

196 lines. `use Parapet.TestSupport.ConcurrencyCase, async: false`. Inline `ConcurrencyRunbook` declares the `:op_step` step with `capability: :retry_async_item, target_kind: "async_item"`. Inside `unboxed_run`: bootstrap reset → Agent reset (Pitfall 4) → register recovery → insert incident → preview → return `{incident, preview_token}`. Two `Task.async` contenders use the SAME `idempotency_key: "operator_confirm_#{incident.id}_op_step"` (that's what makes them race for the same row). After `assert_receive {:ready, _} x2`, `:go` is broadcast. Result assertions + DB-state assertions follow.

## Decisions Made

- **Extended the existing inline DummyRepo** rather than building a new shared TestSupport repo. The synchronous unit harness only needs the "first caller wins" code path through `ClaimService`; a new shared module would have been a much bigger surface change than this plan's charter allows.
- **Cloned a private DummyRepo into preview_lifecycle_test.exs** rather than extracting a shared helper. The existing DummyRepo lives inside `Parapet.OperatorTest` and isn't accessible across test modules without extraction — keeping it local respects scope boundary.
- **Test 4 (atom-vs-string canonicalization) implemented as a full test, not deferred.** The plan said Test 4 was "recommended but may be deferred" — the implementation cost was low (re-register the capability with atom target_refs inside the test body) and the Pitfall 5 footgun is real enough to warrant the regression guard.
- **No standalone synchronous `{:conflicted, claim_id}` unit test.** The plan called this "plan-phase discretion." The multi-node concurrency test exercises the same wrap-to-2-tuple translation in the real-DB harness, which is stronger evidence than mocking the conflict path.

## Deviations from Plan

- **Rule 3 (auto-fix blocking issue):** The plan's Task 1 spec only requested updating the assertion at `:524`. In practice, the happy-path `mix test test/parapet/operator_test.exs` was already red because plan 25-01 routed Confirm through `ClaimService.claim_action/1` (raw-fun transaction), and the existing `DummyRepo.transaction/1` only accepted `Ecto.Multi`. The orchestrator's parallel-executor briefing explicitly authorized "modify the existing test DummyRepo in `test/parapet/operator_test.exs` to handle ClaimService.claim_action/1's raw-function transaction protocol — this is on your charter (closes the Wave 1 known red)." Extended DummyRepo as part of Task 1's commit accordingly. Tracked here as a deviation for traceability.

## Issues Encountered

- **None.** All three tasks completed on first compile + test run. The concurrency test ran deterministically across 3 consecutive runs with seeds 1, 2, 3.

## Test-Suite Snapshot

After all three task commits (`88ea82a`, `a7558f3`, `5712754`):

- **`mix test test/parapet/operator_test.exs`** — 14 tests, 0 failures (Wave 1 known red closed).
- **`mix test test/parapet/operator/preview_lifecycle_test.exs`** — 4 tests, 0 failures.
- **`mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed`** — 1 test, 0 failures. Deterministic across seeds 1, 2, 3.
- **`mix test --include unboxed`** (full suite) — 478 tests, 1 failure. The failure is `test/mix/tasks/parapet.install_test.exs:84` — a PRE-EXISTING failure that predates Phase 25 and is documented in 25-01-SUMMARY.md as "PRE-EXISTING, unrelated to Phase 25." See "Deferred Issues" below.

## Plan Verification Gates (final)

| Gate | Expected | Actual | Result |
|------|----------|--------|--------|
| 1. `mix test test/parapet/operator_test.exs` exits 0 | exit 0 | exit 0 (14/14) | PASS |
| 2. `mix test test/parapet/operator/preview_lifecycle_test.exs` exits 0 | exit 0 | exit 0 (4/4) | PASS |
| 3. `mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed` exits 0 | exit 0 | exit 0 (1/1) | PASS |
| 4. Full suite `mix test --include unboxed` exits 0 | exit 0 | exit 1 (1 pre-existing unrelated failure) | PARTIAL — see Deferred Issues |
| 5. 3 consecutive concurrency runs with varying seeds all pass | 3/3 | 3/3 (seeds 1, 2, 3) | PASS |
| 6. `grep -rn ':stale_preview' test/` returns 0 | 0 | 0 | PASS |

Gate 4 is the only partial — the failing test is pre-existing (`test/mix/tasks/parapet.install_test.exs:84`, Igniter's `Rewrite.source!` on "mix.exs"), unrelated to Phase 25, and acknowledged in plan 25-01's summary.

## Deferred Issues

- **`test/mix/tasks/parapet.install_test.exs:84` — pre-existing failure** with `(Rewrite.Error) no source found for "mix.exs"`. This test predates Phase 25 (its file was last touched in commit `9423a3b feat(01-05): add mix task tests and fix installer test AST issue`, before the v1.1 branch existed). Plan 25-01's summary explicitly documents it as "PRE-EXISTING, unrelated to Phase 25." Out of scope for plan 25-03 per the executor scope-boundary rule (only auto-fix issues directly caused by current task changes). Tracked here so future audit work has the full picture.

## User Setup Required

None. Zero new runtime or dev dependencies. Tests run against the existing Postgres concurrency DB (already configured for `executor_concurrency_test.exs` and `claim_service_test.exs`).

## Threat Surface Status

All threats in the plan's `<threat_model>` are mitigated as designed:

- **T-25-T-01** (Capabilities Agent state leak across tests): mitigated by the explicit `Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)` inside `unboxed_run` in Task 3, and inside the setup block of Task 2. Both happen BEFORE `register_recovery/2`.
- **T-25-T-02** (flaky concurrency test): mitigated by deterministic Postgres unique-constraint arbitration. Verified by 3 consecutive seed-varied runs (seeds 1, 2, 3) all passing.
- **T-25-T-03** (PII in test fixtures): accepted — fixtures are synthetic ("item-1", "item-a", "tampered-ref", etc.).
- **T-25-T-SC** (package-install supply chain): N/A — zero new packages.

No new threat flags introduced.

## Next Phase Readiness

- **Phase 26 (audit propagation + telemetry emit-sites)** can rely on the now-fully-tested operator-confirm path. The contract is locked by tests at three levels:
  - **Synchronous unit:** `preview_lifecycle_test.exs` + `operator_test.exs` cover the four return variants on the DummyRepo synchronous harness.
  - **Multi-node concurrency:** `confirm_concurrency_test.exs` proves the claim-protected race semantics against a real Postgres backend.
  - **Backward compat:** the nil-hash test ensures pre-Phase-25 stored previews don't break.
- **Plan 25-02 (LiveView wiring) — sibling worktree.** No coordination needed at this point; the sibling owns LiveView surfaces under `examples/demo_app/lib/demo_app_web/**` and our charters don't overlap.

## Self-Check: PASSED

- File `test/parapet/operator/preview_lifecycle_test.exs` exists (307 lines).
- File `test/parapet/operator/confirm_concurrency_test.exs` exists (196 lines).
- File `test/parapet/operator_test.exs` exists and contains the renamed test + updated assertion + extended DummyRepo.
- Commit `88ea82a` (Task 1) exists in git log.
- Commit `a7558f3` (Task 2) exists in git log.
- Commit `5712754` (Task 3) exists in git log.
- `mix test test/parapet/operator_test.exs` exits 0 (14/14).
- `mix test test/parapet/operator/preview_lifecycle_test.exs` exits 0 (4/4).
- `mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed` exits 0 (1/1).
- 3 consecutive concurrency runs (seeds 1, 2, 3) all pass.
- `grep -rn ':stale_preview' test/ lib/` returns 0.
- All acceptance criteria for Tasks 1, 2, 3 verified via grep counts (see Test-Suite Snapshot and Plan Verification Gates).

---
*Phase: 25-wire-confirm-through-claimservice-preview-confirm-ux*
*Plan: 03*
*Completed: 2026-05-28*
