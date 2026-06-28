---
phase: 49-stress-fixtures-seed-coverage
verified: 2026-06-28T20:58:25Z
status: passed
score: 7/7
behavior_unverified: 0
overrides_applied: 0
---

# Phase 49: Stress Fixtures & Seed Coverage — Verification Report

**Phase Goal:** The demo app carries reproducible stress scenarios (long-string overflow, empty collections, max-items density, mixed-status, and a combined stress scenario) wired to `PARAPET_DEMO_SCENARIO`, and the component gallery is covered by the screenshot capture script and a demo contract test — so the audit can be re-run against worst-case data on demand.
**Verified:** 2026-06-28T20:58:25Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A developer can select long-string, empty, and max-items scenarios via PARAPET_DEMO_SCENARIO | VERIFIED | `DemoApp.DemoSeedScenarios.seed/1` clauses for "long_string", "empty", "max_items" are compiled and wired in `lib/demo_app/demo_seed_scenarios.ex:39-47`; `seeds.exs` routes `PARAPET_DEMO_SCENARIO` to `DemoSeedScenarios.seed/1`; fixture pins FIXTURE-01, FIXTURE-02, FIXTURE-03 pass in the live test suite (25 tests, 0 failures) |
| 2 | A mixed-status scenario surfaces all three incident states + escalation diversity, and a combined stress scenario is wired to PARAPET_DEMO_SCENARIO | VERIFIED | `seed("mixed_status")` at line 49 composes checkout_webhook_failures/stalled_async_executor/signup_email_resolved/retry_storm helpers plus a bare idle incident and 5 open ActionItems (one per kind); `seed("stress")` at line 53 calls long_string_incident()+max_items_dense()+mixed_status_spread() — union composition, no duplication; FIXTURE-04 and FIXTURE-05 pins pass |
| 3 | The combined stress scenario is covered by the screenshot capture script across desktop+mobile and light+dark | VERIFIED | `capture_operator_ui_screenshots.sh` lines 85-88 add 4 gallery captures; the stress scenario seeds ≥1 active incident (DETAIL_ID precondition satisfied via max_items_dense() seeding 35 active incidents); the operator pages already covered by lines 69-81 run against whatever scenario is seeded; static grep pin in smoke test asserts ≥4 `capture … _gallery` lines and passes |
| 4 | GET /parapet/_gallery returns 200 with operator-component markers against an empty sandbox — DB-independent and not swallowed by the /:id catch-all | VERIFIED | Router at line 22 declares `live_session :parapet_gallery` BEFORE the /:id catch-all at line 31; gallery contract test asserts 200 + `parapet-ui` + `Parapet Operator UI Gallery` + `po-operator-title` + `po-chip` against unseeded sandbox; passes green |
| 5 | The gallery route is covered by the screenshot capture script (4 captures: desktop+mobile, light+dark) | VERIFIED | Script lines 85-88 contain exactly 4 `capture "gallery-…" "…" "/parapet/_gallery"` calls with tall window sizes (1440,5200 desktop / 414,7600 mobile); `grep -c "capture.*_gallery" …` independently returns 4; `bash -n` syntax check passes |
| 6 | The gallery route is asserted by a demo contract test | VERIFIED | `operator_smoke_test.exs:291-308` asserts GET /parapet/_gallery 200 + 4 markers; `operator_ui_demo_contract_test.exs` at line 5 reads `@seed_scenarios_path "examples/demo_app/lib/demo_app/demo_seed_scenarios.ex"` (updated per deviation); both contract test files pass |
| 7 | All five new scenario names are registered in DemoSeedScenarios.scenarios/0 so the typo-guard cannot fire | VERIFIED | `@scenarios ~w(response recovery escalation history all long_string empty max_items mixed_status stress)` at line 4 of the compiled module; registry pin test passes; `seed(scenario)` typo-guard at line 59 remains the last clause |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/demo_app/lib/demo_app/demo_seed_scenarios.ex` | Compiled module with 5 new seed/1 clauses + 3 private helpers | VERIFIED | 517 lines; @scenarios includes all 10 names; seed("empty")/:ok, seed("long_string"), seed("max_items"), seed("mixed_status"), seed("stress") all present above typo-guard catch-all |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | Extended with Phase-49 describe block (gallery contract + 6 fixture pins + grep pin) | VERIFIED | Lines 285-435 contain `describe "Phase 49 gallery + fixture coverage"` with 1 gallery test + 6 fixture tests + 1 grep pin; 25 tests, 0 failures |
| `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` | Extended with 4 /parapet/_gallery captures (desktop+mobile, light+dark) | VERIFIED | Lines 82-88 add GALLERY-02 block with 4 capture calls; tall window sizes 1440,5200/414,7600; bash -n passes |
| `examples/demo_app/priv/repo/seeds.exs` | Routes PARAPET_DEMO_SCENARIO to DemoSeedScenarios.seed/1 | VERIFIED | Line 8: `scenario = System.get_env("PARAPET_DEMO_SCENARIO", "all")`; line 9: `DemoApp.DemoSeedScenarios.seed(scenario)`; no Code.require_file |
| `test/parapet/operator_ui_demo_contract_test.exs` | @seed_scenarios_path updated to lib path | VERIFIED | Line 5: `@seed_scenarios_path "examples/demo_app/lib/demo_app/demo_seed_scenarios.ex"` — correct path to compiled module |
| `examples/demo_app/priv/repo/demo_seed_scenarios.exs` | Replaced with tombstone (module moved) | VERIFIED | File contains tombstone comment only; redirects to new lib location |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `seeds.exs:8-9` | `DemoApp.DemoSeedScenarios.seed/1` | `PARAPET_DEMO_SCENARIO` env var → `seed(scenario)` call | WIRED | seeds.exs reads env var, calls compiled module; module available at runtime because it is in lib/ and compiled into the app |
| `operator_smoke_test.exs:342-411` | `DemoApp.DemoSeedScenarios.seed/1` | Direct call inside Ecto sandbox | WIRED | Each fixture test calls seed/1 then asserts via Repo.aggregate; ConnCase provides the sandbox |
| `capture_operator_ui_screenshots.sh:85-88` | `/parapet/_gallery` route | `capture()` helper reuse with `?parapet_theme=` convention | WIRED | capture() helper at lines 47-67 appends `?parapet_theme=` for the path with no existing query string; gallery path has no query string → else branch fires correctly |
| `seed("stress")` | `long_string_incident()` + `max_items_dense()` + `mixed_status_spread()` | Direct private function calls — union composition | WIRED | Lines 53-57 call three helpers in sequence; no code duplication; stress guarantees ≥1 active incident via max_items_dense (35 active created) |
| `operator_ui_demo_contract_test.exs` | `examples/demo_app/lib/demo_app/demo_seed_scenarios.ex` | `File.read!(@seed_scenarios_path)` | WIRED | Path updated to new compiled module location; file exists (18849 bytes); all marker assertions in the test are satisfied by the compiled module's content |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase produces seed data infrastructure (not a UI component that renders dynamic data to be traced). The seed module is the data source; the smoke tests verify the flow by querying Repo.aggregate directly after seeding.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 25 smoke tests green including all FIXTURE-01..05 + GALLERY-02 pins | `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` | 25 tests, 0 failures | PASS |
| Capture script has valid bash syntax | `bash -n examples/demo_app/scripts/capture_operator_ui_screenshots.sh` | exit 0 | PASS |
| Script contains exactly 4 gallery capture lines | `grep -c "capture.*_gallery" …sh` | 4 | PASS |
| scenarios/0 includes all 5 new names | `grep "@scenarios" …demo_seed_scenarios.ex` | `~w(… long_string empty max_items mixed_status stress)` | PASS |
| Lib suite failures are pre-existing and unrelated to phase 49 | `mix test test/parapet/` | 470 tests, 1 failure — Parapet.DocsPhase33Test asserts README contains "make up-auto" (pre-existing, verified at base commit 848693f, no phase-49 files touched) | PASS |

---

### Probe Execution

No probes declared or conventional `scripts/*/tests/probe-*.sh` found for this phase. Step 7c skipped.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FIXTURE-01 | 49-01, 49-02 | Long-string/overflow demo scenario exists | SATISFIED | `seed("long_string")` creates ≥1 incident with title >100 chars, long unbroken description/correlation_key/runbook steps/external_link URL, and ActionItem with long external_id; FIXTURE-01 pin passes |
| FIXTURE-02 | 49-01, 49-02 | Empty-collection demo scenario exists | SATISFIED | `seed("empty"), do: :ok` — zero incidents and zero action items in sandbox; FIXTURE-02 pin passes |
| FIXTURE-03 | 49-01, 49-02 | Max-items/dense-list demo scenario exists | SATISFIED | `max_items_dense/0` seeds 35 active incidents (31 open, 4 investigating) + ActionItems on every 5th + long timeline on first; FIXTURE-03 pin asserts >30 active via Ecto.Query, passes |
| FIXTURE-04 | 49-01, 49-02 | Mixed-status scenario surfacing all status triplets | SATISFIED | `mixed_status_spread/0` reuses 4 escalation helpers (3 states covered: investigating/resolved/open) + idle incident + 5 open ActionItems one per kind; FIXTURE-04 pin asserts state superset and open action items, passes |
| FIXTURE-05 | 49-01, 49-02, 49-03 | Combined stress scenario wired to PARAPET_DEMO_SCENARIO + covered by screenshot script | SATISFIED | `seed("stress")` union composition; registry pin verifies all 5 names in scenarios/0; active-incident pin passes; capture script covers stress scenario via existing operator page captures + new gallery captures |
| GALLERY-02 | 49-01, 49-03 | Gallery route covered by screenshot capture script and demo contract test | SATISFIED | Smoke test asserts GET /parapet/_gallery 200 + 4 markers; static grep pin asserts ≥4 capture+_gallery lines; contract test @seed_scenarios_path updated; all pass |

No orphaned requirements: REQUIREMENTS.md traceability table maps FIXTURE-01..05 and GALLERY-02 to Phase 49; all 6 are covered above.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | — |

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, `return null`, or hardcoded empty-value stubs found in any phase-49-modified file. All seed clauses produce real data (verified by fixture pins). No unreferenced debt markers.

---

### Deviation Audit: Module Promotion (priv/repo → lib/)

**Deviation:** `DemoApp.DemoSeedScenarios` was promoted from `priv/repo/demo_seed_scenarios.exs` (script) to `lib/demo_app/demo_seed_scenarios.ex` (compiled module).

**Soundness verdict: SOUND.** The deviation is architecturally correct and self-validated:

1. **Root cause is valid:** `priv/repo/*.exs` scripts are loaded only via `Code.require_file` at `mix run` time, not compiled into the application. `elixirc_paths(:test)` is `["test/support", "lib"]` — the .exs script is never available in the Ecto sandbox. Tests calling `DemoApp.DemoSeedScenarios.seed/1` would have raised `UndefinedFunctionError` without the promotion.

2. **PARAPET_DEMO_SCENARIO seam is unchanged:** `seeds.exs` still reads `System.get_env("PARAPET_DEMO_SCENARIO", "all")` and calls `DemoApp.DemoSeedScenarios.seed(scenario)`. No new env var or seam was introduced.

3. **All 5 scenarios are reachable via the existing seam:** The typo-guard catch-all at line 59 rejects unknown names; all 10 names including the 5 new ones are registered in `@scenarios`. The seam is symmetric: any value not in `@scenarios` raises `ArgumentError` with a descriptive message.

4. **Contract test updated correctly:** `operator_ui_demo_contract_test.exs` `@seed_scenarios_path` now points to the compiled module at `lib/demo_app/demo_seed_scenarios.ex`, which contains all required marker strings.

5. **Tombstone in place:** `priv/repo/demo_seed_scenarios.exs` contains only a comment directing to the new location — no confusing dead code.

---

### Human Verification Required

None. All phase-49 deliverables are covered by automated tests running in the Ecto sandbox. The only deferred human artifact is the operator running the capture script against a PARAPET_DEMO_SCENARIO=stress-seeded DB to produce PNGs — this is Phase 50 scope (committed baselines, D-09), not a Phase 49 gate.

---

### Gaps Summary

No gaps. All 7 truths verified, all 6 requirements satisfied, all 3 plans complete, no debt markers, no stubs, and no orphaned requirements.

The pre-existing `Parapet.DocsPhase33Test` failure (1 failure in the lib suite, asserting README contains "make up-auto") is out of scope — it exists at base commit 848693f before any phase-49 file was touched, and no phase-49 artifact touches the README or any file that test reads.

---

_Verified: 2026-06-28T20:58:25Z_
_Verifier: Claude (gsd-verifier)_
