---
phase: 48-pages-flows-microcopy
plan: 01
subsystem: testing
tags: [phoenix, liveview, exunit, red-green, microcopy, a11y, regex, lazy_html]

# Dependency graph
requires:
  - phase: 47-component-groups-meta-components
    provides: incident_summary/1 + pinned action-rail/risk/preview copy (carried verbatim into the COPY-02/05 survive-pins)
provides:
  - "RED source-string gate set in test/parapet/operator_ui_integration_test.exs (FLOW-04 route order + comment, FLOW-02 :page_title source, COPY-01..05, A11Y-06 source attrs, D-15 voice gate)"
  - "RED rendered-state gate set in examples/demo_app/test/demo_app/operator_smoke_test.exs (FLOW-02 single-h1, FLOW-03 not-found unknown+malformed, page_title(view), skeleton, empty-during-load gate, landmark cross-check)"
  - "The exact done-bar for 48-02 (component layer) and 48-03 (shell/service layer)"
affects: [48-02, 48-03, 48-04, 49-stress-fixtures]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RED-first wave: assertions pin facts before any source change (Phase-47 cadence, D-19)"
    - "Fact-type routing (D-18): template-text facts → lib source-string loops; rendered-state facts → demo Phoenix.LiveViewTest harness"
    - "single-h1 counted via Regex.scan(~r/<h1[\\s>]/, html) over rendered html — not Floki (lazy_html backend), not source grep (two h1 definitions compose onto one page)"
    - "COPY-04 bounded refutes: ~r/\\b(TODO|FIXME|XXX|HACK)\\b/, ~r/\\blorem ipsum\\b/i, ~r/placeholder text/i (never bare /placeholder/i or /todo/i)"

key-files:
  created: []
  modified:
    - test/parapet/operator_ui_integration_test.exs
    - examples/demo_app/test/demo_app/operator_smoke_test.exs

key-decisions:
  - "FLOW-04 route-ordering assert scoped to OperatorDetailLive `live` declaration LINES, not raw substring index — a bare /parapet/:id appears inside explanatory comments (demo gallery note) and would falsely fail/un-green an index-of-substring assert (deviation Rule 1)"
  - "operator_ui_contrast_test.exs left unchanged — no source-string contrast/refute fact needed a RED pin in the contrast scope this wave"
  - "not-found RED manifests as a raised NoResultsError/CastError from live/2 (current bug), which is valid RED evidence that the panel/precheck do not yet exist"

patterns-established:
  - "RED scaffold: every Phase-48 FLOW/COPY/A11Y fact has >=1 failing assertion before source changes (D-19 wave 1)"

requirements-completed: []  # 48-01 is RED scaffold only; FLOW-01..05/COPY-01..05/A11Y-06 are pinned-but-not-satisfied here. They flip complete in 48-02/48-03/48-04.

coverage:
  - id: D1
    description: "RED source-string gates pinning FLOW-04 ordering+comment, FLOW-02 :page_title source, COPY-01..05 literals, COPY-04 bounded refutes, D-15 voice gate, A11Y-06 source attrs in operator_ui_integration_test.exs"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#Phase 48 source-string gates (RED until wave-2/3) — 6 fail RED, FLOW-04 ordering passes as regression guard"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D2
    description: "RED rendered-state gates pinning single-h1, not-found (unknown+malformed), page_title(view), skeleton, empty-during-load gate, landmark cross-check in operator_smoke_test.exs"
    verification:
      - kind: integration
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#Phase 48 rendered-state gates (RED until wave-2/3) — 6 fail RED, landmark cross-check passes"
        status: pass
    human_judgment: false
    rationale: ""

# Metrics
duration: 4min
completed: 2026-06-26
status: complete
---

# Phase 48 Plan 01: Wave-1 RED Scaffold Summary

**12 RED assertions installed across the two existing operator test files — fact-routed per D-18 (source-string → lib integration test, rendered-state → demo smoke test) — pinning every Phase-48 FLOW/COPY/A11Y fact as the exact done-bar for 48-02/48-03, with zero new test files and zero source edits.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-26T20:57:09Z
- **Completed:** 2026-06-26T21:01:06Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added a Phase-48 source-string gate block to `operator_ui_integration_test.exs` (6 new tests fail RED; the FLOW-04 route-ordering regression guard correctly passes since ordering is already structurally correct).
- Added a Phase-48 rendered-state gate block to `operator_smoke_test.exs` (6 new tests fail RED; the A11Y-06 landmark cross-check correctly passes against the existing `main#parapet-main` + labeled detail nav).
- Confirmed the threat-register RED evidence: the malformed-id `/parapet/123` route currently raises `Ecto.Query.CastError` (uncaught 500, T-48-02) and the unknown-UUID route raises `Ecto.NoResultsError` (T-48-01) — both must collapse to the designed in-page not-found panel in wave-3.
- Honored all prohibitions: no new test file, no source/template edit, single-h1 counted via `Regex.scan` (not Floki, not grep), COPY-04 bounded regexes that don't match `placeholder=` or "today".

## RED Evidence

**Lib integration test** — `mix test test/parapet/operator_ui_integration_test.exs` → **29 tests, 6 failures** (all 6 are the new Phase-48 gates):

| # | Assertion | REQ-ID | Fact-type | RED reason |
|---|---|---|---|---|
| 1 | not-found heading + body copy pinned verbatim | COPY-03 | source-string | components have no `This incident isn't in the evidence store` panel yet (D-02) |
| 2 | the 10+1 re-authored microcopy strings | COPY-03 | source-string | D-13 strings (`Untitled runbook`, harmonized ack, error flashes…) not yet authored |
| 3 | `:page_title` + `page_title(` helper presence | FLOW-02 | source-string | operator_live/detail assign no `:page_title` yet (D-07) |
| 4 | catch-all-last explanatory comment | FLOW-04 | source-string | router_snippet lacks the `:id` catch-all-last comment (D-04) |
| 5 | no `inspect(` in flashes; no banned tone | COPY/D-15 | source-string | `#{inspect(reason)}` still in detail flashes; banned constructions present |
| 6 | A11Y-06 source attrs incl. `nav[aria-label="Incident context"]` | A11Y-06 | source-string | detail context strip not yet wrapped in the named nav (D-08) |

The FLOW-04 **route-ordering** assert (`/parapet/incidents/:id` before `/parapet/:id`) **passes** — it is a regression guard and the routes are already correctly ordered. COPY-01 (nav labels), COPY-02/05 (pinned Phase-47 strings survive), and the COPY-04 bounded-regex self-check also pass (those facts are already green and must stay green).

**Demo smoke test** — `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` → **17 tests, 6 failures** (all 6 are the new Phase-48 gates):

| # | Assertion | REQ-ID | Fact-type | RED reason |
|---|---|---|---|---|
| 1 | exactly one `<h1>` per page (Regex.scan) | FLOW-02 | rendered | pages emit two h1s (operator_nav + incident_summary) (D-06) |
| 2 | unknown-UUID detail renders not-found copy | FLOW-03 | rendered | `incident_detail/1` raises `Ecto.NoResultsError` (T-48-01) |
| 3 | malformed `/parapet/123` renders not-found copy | FLOW-03 | rendered | `incident_detail/1` raises `Ecto.Query.CastError` → 500 (T-48-02/D-01) |
| 4 | `page_title(view)` per page | FLOW-02 | rendered | `:page_title` unset, demo layout not yet patched (D-07) |
| 5 | uniform disconnected skeleton (animate-pulse + aria-busy) on Actions/History | FLOW-03 | rendered | skeleton only exists on the Response queue (D-09) |
| 6 | empty state only on connected render, not during load | FLOW-03 | rendered | empty-during-load gate (`@socket_connected and Enum.empty?`) not wired (D-10) |

The A11Y-06 rendered landmark cross-check (`main#parapet-main` + `nav[aria-label]`) **passes** against the existing detail landmarks — it is a belt-and-suspenders guard; the NEW `Incident context` nav is RED-pinned on the source side (lib test #6).

**Combined: 12 newly-added assertions fail RED, 0 source edits, 0 new test files.**

## Task Commits

1. **Task 1: RED source-string assertions in lib integration test** - `2143774` (test)
2. **Task 2: RED rendered-state assertions in demo smoke test** - `74b10c2` (test)

## Files Created/Modified

- `test/parapet/operator_ui_integration_test.exs` - Added `describe "Phase 48 source-string gates (RED until wave-2/3)"` block: route-ordering + comment, `:page_title` source presence, COPY-01..05 literal pins, the 10+1 D-13 strings + not-found copy verbatim, COPY-04 bounded refutes + a self-check, D-15 voice gate, A11Y-06 source attrs.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` - Added `describe "Phase 48 rendered-state gates (RED until wave-2/3)"` block: single-h1 via `Regex.scan`, not-found (unknown UUID + malformed id), `page_title(view)` per page, disconnected skeleton, empty-during-load gate, landmark cross-check.

## Decisions Made

- **FLOW-04 ordering scoped to declaration lines (not raw substring index).** A bare `/parapet/:id` substring also appears inside an explanatory comment in the demo router (the gallery "declare before the `/parapet/:id` catch-all" note at line 19). An `index_of(content, "/parapet/:id")` over the whole file therefore matched the comment first and produced a *false* RED that could never go green. The assert now filters to lines that name `OperatorDetailLive` and carry a `live` macro for the route, so it verifies the real declaration ordering and is a stable regression guard. (See Deviations — Rule 1.)
- **Contrast test left untouched.** Per the Task 1 conditional, `operator_ui_contrast_test.exs` only changes if a source-string contrast/refute fact needs a RED pin in the contrast scope. None did this wave; the contrast suite stays green (4 tests, 0 failures).
- **not-found RED = a raised exception.** The unknown-UUID and malformed-id tests fail by `live/2` raising (`NoResultsError` / `CastError`) rather than asserting-false. This is the canonical RED for not-yet-existing behavior and is the literal threat-register evidence (T-48-01/T-48-02) — wave-3's `fetch_incident_detail/1` makes `live/2` succeed, after which the copy assertion evaluates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FLOW-04 route-ordering assert matched a comment substring instead of the route declaration**
- **Found during:** Task 1 (RED source-string assertions)
- **Issue:** The plan's suggested `index_of(content, ~S|/parapet/:id|)` form matched the bare `/parapet/:id` text inside the demo router's gallery-ordering *comment* (line 19), making the demo-router branch fail for the wrong reason and rendering the assert un-greenable even after correct ordering.
- **Fix:** Scoped the ordering comparison to lines that name `OperatorDetailLive` AND carry a `live` macro AND the route literal, then compared `index_of` of those declaration lines. The assert now reflects real route-declaration order (still uses `index_of/2` and the two route literals, per the acceptance criterion) and correctly passes as a regression guard.
- **Files modified:** test/parapet/operator_ui_integration_test.exs
- **Verification:** `mix test test/parapet/operator_ui_integration_test.exs` — the FLOW-04 ordering test passes (routes already correctly ordered); the separate catch-all-last *comment* test remains RED as intended.
- **Committed in:** 2143774 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — Rule 1).
**Impact on plan:** Narrow correctness fix to a single assertion so it pins the real fact (declaration order) rather than incidental comment text. No scope creep; all other assertions match the plan/PATTERNS spec verbatim.

## Wave-2 / Wave-3 Notes (carried forward)

- **DATA-02 ↔ R1 latent conflict.** `operator_ui_contrast_test.exs` line ~189 refutes `overflow-y-auto` inside the **`@component_paths`** loop, but D-16 R1 adds `overflow-y-auto` to `preview_panel` (which lives in components). When wave-2 lands R1, that refute must be narrowed to `@live_template_paths` only (the D-16 note already anticipates this). Not changed in this RED plan — flagged for 48-02.
- **Demo layout patch required for FLOW-02 page_title (rendered).** `page_title(view)` will stay RED until the demo `layouts.ex` `<.live_title>` is patched (D-07) AND the LiveViews assign `:page_title` — that pairing lands in 48-02/48-03.

## Issues Encountered
None — both tasks executed per plan aside from the single Rule-1 assertion-scoping fix documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The full Phase-48 RED done-bar is installed and confirmed (12 assertions RED). 48-02 (component layer) and 48-03 (shell/service layer) can now drive these green.
- Carry the two wave-2 notes above (DATA-02/R1 refute narrowing; demo layout `<.live_title>` patch) into 48-02 planning/execution.

## Self-Check: PASSED

- `48-01-SUMMARY.md` exists on disk.
- `test/parapet/operator_ui_integration_test.exs` exists (modified, not new).
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` exists (modified, not new).
- Commit `2143774` (Task 1) present in git log.
- Commit `74b10c2` (Task 2) present in git log.
- `git diff` over both task commits shows only the two existing `_test.exs` files (no new test files, no source/template edits).
- 12 newly-added assertions confirmed RED (6 lib integration + 6 demo smoke).

---
*Phase: 48-pages-flows-microcopy*
*Completed: 2026-06-26*
