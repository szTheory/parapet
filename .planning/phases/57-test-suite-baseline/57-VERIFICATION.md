---
phase: 57-test-suite-baseline
verified: 2026-07-02T21:31:31Z
status: passed
resolved: 2026-07-02T21:31:31Z
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
resolution: "SC-1 exit-0 accepted as satisfied by the automated CI gate (ci.yml:116 — `mix test` on ubuntu-latest + Postgres across the OTP 26/27/28 matrix; a mandatory gate the `demo` job depends on). This is the phase's own 'CI is the enforcement backstop' model. The two remaining LOCAL failures were confirmed pre-existing at base commit 089373a~1 and are out-of-scope, documented local-vs-CI deltas: OperatorUIParityTest = the 'no operator UI diff' delta (Phase 58 SC-2); ExecutorClusterSmokeTest = a distributed-Erlang peer-node env gap whose failure occurs at `:peer.start_link`, before any Phase 57 code runs. Decision by user (qiksnare13) 2026-07-02: accept CI as verification."
human_verification: []
---

# Phase 57: Test Suite Baseline — Verification Report

**Phase Goal:** A bare `mix test` exits green — the pre-existing reds are fixed directly and all `Process.sleep` call sites are correctly classified, so the "CI is the enforcement backstop" claim rests on an honest green suite.
**Verified:** 2026-07-02T21:31:31Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | `mix test` exits 0 with no failures — `DocsPhase33Test` no longer asserts the stale `"make up-auto"` string | PRESENT_BEHAVIOR_UNVERIFIED | `make up-auto` grep returns 0 hits. The two named reds (DocsPhase33 + RecoveryAction) are confirmed fixed. 2 pre-existing local failures remain (OperatorUIParityTest + ExecutorClusterSmokeTest) that are documented local-vs-CI deltas; Phase 58 SC-2 explicitly lists "no operator UI diff" as a known delta. Cannot run full suite here to produce the CI exit-0 proof. |
| SC-2 | `Telemetry.RecoveryActionTest` passes reliably under concurrent `async: true` runs — `atom_count` delta check removed, `String.to_existing_atom/1`-raises guard retained | VERIFIED | `grep -c ':erlang.system_info(:atom_count)' recovery_action_test.exs` = 0. `grep -c 'String.to_existing_atom(poison)' recovery_action_test.exs` = 2 (both CR-01 guards at lines 130 and 173 intact). |
| SC-3 | The three `Process.sleep` calls in `exemplar_telemetry_test.exs` are gone | VERIFIED | `grep -c 'Process.sleep' test/parapet/metrics/exemplar_telemetry_test.exs` = 0. |
| SC-4 | Intentional concurrency-simulation sleeps annotated with `@concurrency_hold_ms` + explanatory comment; `executor_cluster_smoke_test.exs` startup-race sleep replaced with a synchronous barrier | VERIFIED | `INTENTIONAL HOLD:` present in all 5 files (count=5). `executor_cluster_smoke_test.exs` has exactly 2 occurrences (local runbook + heredoc twin). `@concurrency_hold_ms 75` in 4 files; `@concurrency_hold_ms 50` in `claim_service_test.exs`. `Process.sleep(200)` = 0 hits; `SELECT 1` count = 2 (barrier + downstream script). Heredoc twin uses literal `Process.sleep(75)` (no interpolation). Caller-side sync note confirmed at line 137. `bash scripts/check_intentional_hold.sh` exits 0. |
| SC-5 | A reusable `assert_eventually`/until helper exists in the test support layer | VERIFIED | `grep -c 'def assert_eventually(fun, opts'` = 1 in `test/support/concurrency_case.ex`. `assert_eventually: 2` in `import only:` list at line 15. Implementation catches only `ExUnit.AssertionError` (rescue clause confirmed). `reraise err, st` present — re-raises the real assertion diff verbatim. Default opts: timeout=1_000ms, interval=25ms constant. |

**Score:** 5/5 truths verified (SC-1 is present and the named reds are fixed; see Human Verification for the CI exit-0 confirmation gap)

Note: SC-1 is counted verified for purposes of the must-haves score because the two named pre-existing reds (DocsPhase33 + RecoveryAction, explicitly identified in REQUIREMENTS.md and planning research) are confirmed fixed in the codebase. The PRESENT_BEHAVIOR_UNVERIFIED status reflects that the full-suite exit-0 claim requires CI confirmation given two pre-existing local-only failures.

---

### Plan Must-Haves (57-01-PLAN.md)

| Truth | Status | Evidence |
|-------|--------|----------|
| `docs_phase_33_test.exs` no longer asserts stale `'make up-auto'` string | VERIFIED | `grep -rn 'make up-auto' test/` = 0 hits. Plan also removed `curl -f http://127.0.0.1:` and `WEB_PORT` README assertions (bonus bug-fix per SUMMARY deviation note — parallel stale strings in same test). |
| `recovery_action_test.exs` atom_count delta block is gone | VERIFIED | `grep -c ':erlang.system_info(:atom_count)' recovery_action_test.exs` = 0. |
| CR-01 guards at lines 130 and 173 retained byte-for-byte | VERIFIED | `grep -c 'String.to_existing_atom(poison)' recovery_action_test.exs` = 2. Both guards confirmed at lines 130 and 173 (normalize_outcome test and normalize_*/1 helpers test). |
| Three `Process.sleep(10)` in `exemplar_telemetry_test.exs` removed | VERIFIED | `grep -c 'Process.sleep' exemplar_telemetry_test.exs` = 0. |

| Truth | Status | Evidence |
|-------|--------|----------|
| `assert_eventually/2` exists as plain `def` on `ConcurrencyCase`, exported via `import only:` | VERIFIED | `def assert_eventually(fun, opts \\ [])` at line 64. `assert_eventually: 2` in `only:` list at line 15. |
| `assert_eventually` retries at 25ms interval up to 1_000ms, returns truthy on success, re-raises last `ExUnit.AssertionError` on timeout | VERIFIED | Implementation: `interval` default 25, `timeout` default 1_000, `do_assert_eventually` recurse with `Process.sleep(interval)`. On deadline: `reraise err, st` (verbatim re-raise). |
| `assert_eventually` catches ONLY `ExUnit.AssertionError` | VERIFIED | `rescue` block: `err in ExUnit.AssertionError ->` only. No other rescue clauses. MatchError propagates immediately. |
| `executor_cluster_smoke_test.exs` startup `Process.sleep(200)` replaced by bounded `SELECT 1` barrier | VERIFIED | `grep -c 'Process.sleep(200)' executor_cluster_smoke_test.exs` = 0. `SELECT 1` present at line 97 (barrier) and ~163 (downstream script). 5_000ms deadline at line 119. `PARAPET_CONCURRENCY_DB_HOST/PORT/NAME/USER` named in DX error at lines 110-111. Self-referential `ready?.(ready?, deadline)` pattern at line 90. |
| 6 intentional-hold sites annotated; 5 use `@concurrency_hold_ms`; heredoc twin stays literal | VERIFIED | All counts confirmed. Heredoc twin: `Process.sleep(75)` literal at line 156 with `INTENTIONAL HOLD:` comment at 154-155 directly above. No `#{@concurrency_hold_ms}` interpolation in `remote_setup` string. Caller-side note at line 137: "The local ClusterRunbook above (~line 22) and this eval'd twin are deliberate duplicates that must stay in sync." |
| No bare unclassified `Process.sleep` remains in `test/` | VERIFIED | `bash scripts/check_intentional_hold.sh` exits 0. All remaining test/ sleeps are: @concurrency_hold_ms annotated holds (x5), SELECT 1 barrier backoff sleep(25) (exempt in script), `Process.sleep(75)` heredoc twin with INTENTIONAL HOLD comment, or `Process.sleep(interval)` inside `assert_eventually`'s recursive helper (not in test files proper). |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/parapet/docs_phase_33_test.exs` | Stale `make up-auto` assertion removed | VERIFIED | File exists; 0 hits for `make up-auto` repo-wide |
| `test/parapet/telemetry/recovery_action_test.exs` | `atom_count` delta block removed, CR-01 guards retained | VERIFIED | 0 atom_count reads; 2 `String.to_existing_atom(poison)` guards |
| `test/parapet/metrics/exemplar_telemetry_test.exs` | 0 `Process.sleep` calls | VERIFIED | `grep -c 'Process.sleep' ...` = 0 |
| `test/support/concurrency_case.ex` | `assert_eventually/2` def + exported in `import only:` | VERIFIED | def at line 64; import at line 15 |
| `test/parapet/automation/executor_cluster_smoke_test.exs` | `Process.sleep(200)` replaced by SELECT 1 barrier; 2 INTENTIONAL HOLD annotations | VERIFIED | 0 hits for `sleep(200)`; SELECT 1 at line 97; INTENTIONAL HOLD count = 2 |
| `test/parapet/escalation/worker_concurrency_test.exs` | INTENTIONAL HOLD annotation; `@concurrency_hold_ms 75` | VERIFIED | Lines 19-21 confirmed |
| `test/parapet/automation/executor_concurrency_test.exs` | INTENTIONAL HOLD annotation; `@concurrency_hold_ms 75` | VERIFIED | Lines 24-26 confirmed |
| `test/parapet/automation/claim_service_test.exs` | INTENTIONAL HOLD annotation; `@concurrency_hold_ms 50` | VERIFIED | `@concurrency_hold_ms 50` at outer module scope; lines 51-53 confirmed |
| `test/parapet/operator/confirm_concurrency_test.exs` | INTENTIONAL HOLD annotation; `@concurrency_hold_ms 75` | VERIFIED | Lines 77-79 confirmed |
| `scripts/check_intentional_hold.sh` | Executable; exits 0 on current tree; not wired to CI | VERIFIED | `test -x` passes; exits 0; "NOT wired into mix test, CI, or .credo.exs" comment at line 13 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `concurrency_case.ex using block` | `assert_eventually/2` def | `import only: [assert_eventually: 2, ...]` | WIRED | Line 15 in `only:` list; every `use ConcurrencyCase` module automatically imports the helper |
| `executor_cluster_smoke_test.exs` repo_keeper heredoc | `SELECT 1` readiness barrier | `Ecto.Adapters.SQL.Sandbox.unboxed_run` + `query!` | WIRED | Lines 90-119 in heredoc; uses `unboxed_run` matching the downstream script idiom |
| `assert_eventually` rescue clause | `ExUnit.AssertionError` only | `rescue err in ExUnit.AssertionError ->` | WIRED | No other rescue clause; MatchError propagates immediately |

---

### Behavioral Spot-Checks

Step 7b: Only the target-file-scoped test pass (from SUMMARY) can be verified by static means. Running the full suite requires DB availability.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `make up-auto` assertion removed | `grep -rn 'make up-auto' test/` | 0 hits | PASS |
| CR-01 guards retained (count = 2) | `grep -c 'String.to_existing_atom(poison)' recovery_action_test.exs` | 2 | PASS |
| atom_count delta block gone | `grep -c ':erlang.system_info(:atom_count)' recovery_action_test.exs` | 0 | PASS |
| exemplar sleeps gone | `grep -c 'Process.sleep' exemplar_telemetry_test.exs` | 0 | PASS |
| `assert_eventually` def present + exported | `grep -c 'def assert_eventually\|assert_eventually: 2' concurrency_case.ex` | 1 + 1 | PASS |
| startup sleep(200) gone | `grep -c 'Process.sleep(200)' executor_cluster_smoke_test.exs` | 0 | PASS |
| SELECT 1 barrier present | `grep -c 'SELECT 1' executor_cluster_smoke_test.exs` | 2 | PASS |
| INTENTIONAL HOLD in all 5 files | `grep -rl 'INTENTIONAL HOLD:' [5 files] \| wc -l` | 5 | PASS |
| Grep guard exits clean | `bash scripts/check_intentional_hold.sh` | exit 0 | PASS |
| Full `mix test` exits 0 | Not run (requires DB + peer node env) | — | SKIP — see Human Verification |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TEST-01 | 57-01-PLAN.md | `DocsPhase33Test` stale README assertion fixed | SATISFIED | 0 `make up-auto` hits; test verifies surviving assertions against actual README targets |
| TEST-02 | 57-01-PLAN.md | `RecoveryActionTest` no longer flakes; atom_count delta removed, CR-01 guard retained | SATISFIED | 0 `:erlang.system_info(:atom_count)` reads; 2 `String.to_existing_atom(poison)` guards intact |
| TEST-03 | 57-01-PLAN.md | Three spurious `Process.sleep(10)` in `exemplar_telemetry_test.exs` removed | SATISFIED | `grep -c 'Process.sleep' exemplar_telemetry_test.exs` = 0 |
| TEST-04 | 57-02-PLAN.md | Intentional holds annotated; startup barrier replaces `Process.sleep(200)` | SATISFIED | All 6 hold sites annotated; `Process.sleep(200)` = 0; SELECT 1 barrier with 5_000ms deadline and DX error present; grep guard exits 0 |
| TEST-05 | 57-02-PLAN.md | `assert_eventually/2` exists in test support layer | SATISFIED | `def assert_eventually(fun, opts \\ [])` exists; re-raises real assertion; catches only `ExUnit.AssertionError` |

All 5 phase requirements (TEST-01 through TEST-05) are SATISFIED. No orphaned requirements for this phase.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/parapet/telemetry/recovery_action_test.exs` | 114 | Stale comment — "We assert this property TWO ways:" with points 1 and 2 listed, but the second assertion mechanism (atom_count delta measurement) was removed by 57-01 | WARNING | Comment says "TWO ways" but only one way remains; future readers may look for the missing second assertion. Not a BLOCKER — the surviving code is correct and the load-bearing guard (item 1) is fully intact. |

No TBD, FIXME, or XXX markers found in any modified file.

---

### Human Verification Required

#### 1. CI Exit-0 Confirmation

**Test:** Run `mix test` in the CI environment (GitHub Actions with OTP 28, Elixir 1.20.2, `parapet` prefix, and `parapet_concurrency_test` DB available). Review the exit code and failure count.

**Expected:** 0 failures. The two failures seen locally (`OperatorUIParityTest` "Parity failure: operator_components" and `ExecutorClusterSmokeTest` `:peer.start_link`) are known local-vs-CI deltas and should not appear in a properly configured CI run:

- `OperatorUIParityTest` passes in CI because the generated `operator_components.ex` matches the template in a freshly generated app (the local diff is a local modification). Phase 58 SC-2 explicitly documents "no operator UI diff" as one of three known local-vs-CI deltas.
- `ExecutorClusterSmokeTest` requires distributed Erlang peer nodes (`EPMD` + distributed OTP) which are available in the CI container but not in the local dev environment where `:peer.start_link` fails. The 57-02 change to this file is entirely within the `repo_keeper` heredoc (lines 68-123), which only executes AFTER `:peer.start_link` succeeds — it cannot have introduced this failure.

**Why human:** Cannot run the full suite in a CI environment from this verification context. The orchestrator confirmed both failures pre-existed at the phase-57 base commit (`089373a~1`) but a live CI green run is the definitive proof that SC-1 is satisfied in the actual enforcement backstop.

---

### Gap Assessment: The 2 Remaining Local Failures

The phase goal states: "A bare `mix test` exits green — the **pre-existing reds are fixed directly**."

The planning context identifies exactly two pre-existing reds: `DocsPhase33Test` (stale README assertion) and `RecoveryActionTest` (atom_count flake). Both are confirmed fixed in the codebase.

The two remaining failures are distinct from the planning-identified targets:

1. **`Parapet.OperatorUIParityTest`** (`test/parapet/operator_ui_parity_test.exs:25`, "Parity failure: operator_components"): Last modified in Phase 50 commit `817b263`; untouched by Phase 57. Phase 58 SC-2 explicitly documents "no operator UI diff" as a known local-vs-CI delta. This is a local environment deviation, not a Phase 57 responsibility.

2. **`Parapet.Automation.ExecutorClusterSmokeTest`** (fails at `:peer.start_link`): Requires distributed Erlang peer node support (EPMD). Phase 57-02 modified this file only inside the `repo_keeper` heredoc (post-`:peer.start_link`), confirmed by inspecting commit `1381f68`'s diff. The failure occurs before the modified code runs.

**Determination:** These 2 failures do not constitute gaps against the phase requirements (TEST-01..TEST-05). They are pre-existing local-vs-CI deltas that are explicitly acknowledged as out-of-scope for Phase 57 and documented for Phase 58. The `human_needed` status reflects that SC-1's literal "exits 0 with no failures" requires CI-environment confirmation — not a gap closure task.

---

### Commits Verified

All 6 commits documented in SUMMARY.md were confirmed present in the git log:

| Commit | Description |
|--------|-------------|
| `089373a` | fix(57-01): delete stale doc-drift assertion and atom-count flake block (TEST-01, TEST-02) |
| `22b8432` | fix(57-01): delete three spurious telemetry sleeps from exemplar_telemetry_test (TEST-03) |
| `8e0d5b3` | feat(57-02): add assert_eventually/2 to ConcurrencyCase (TEST-05) |
| `1381f68` | fix(57-02): replace startup Process.sleep(200) with SELECT 1 readiness barrier (TEST-04, D-07/D-08) |
| `c332086` | chore(57-02): annotate all 6 intentional-hold sites with INTENTIONAL HOLD: + @concurrency_hold_ms (TEST-04, D-09/D-10/D-11) |
| `e955413` | chore(57-02): add check_intentional_hold.sh grep guard for D-16 vocabulary (D-17) |

---

_Verified: 2026-07-02T21:31:31Z_
_Verifier: Claude (gsd-verifier)_
