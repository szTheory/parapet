---
phase: 46-navigation-shell-data-display
plan: "01"
subsystem: test-harness
tags: [tdd, red-tests, accessibility, navigation, data-display]
dependency_graph:
  requires: []
  provides: [46-02-PLAN.md, 46-03-PLAN.md]
  affects: [test/parapet/operator_ui_contrast_test.exs]
tech_stack:
  added: []
  patterns: [File.read!-assert-loop, ~S-sigil-literal-quotes]
key_files:
  created: []
  modified:
    - test/parapet/operator_ui_contrast_test.exs
decisions:
  - "Used ~S|...| sigil for all assertion strings containing double quotes (e.g. aria-label=\"Incident actions\") per 46-PATTERNS.md guidance"
  - "Extended existing @component_paths and @live_template_paths tests additively — no existing assertions removed or reordered"
  - "New @detail_template_paths constant placed immediately after @live_template_paths for consistent module-attr grouping"
metrics:
  duration: 5
  completed: "2026-06-26"
status: complete
---

# Phase 46 Plan 01: Red-Test Gate — Nyquist Wave 0 Summary

**One-liner:** Extended operator_ui_contrast_test.exs with @detail_template_paths + 14 new NAV/DATA/A11Y string assertions that are RED against current templates and will gate plans 46-02/46-03.

---

## What Was Built

### @detail_template_paths constant added

```elixir
@detail_template_paths [
  "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
  "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
]
```

Placed immediately after the existing `@live_template_paths` constant (line 178).

### New test: "operator detail templates have correct landmarks"

```elixir
test "operator detail templates have correct landmarks" do
  for path <- @detail_template_paths do
    content = File.read!(path)
    assert content =~ ~S|aria-label="Incident actions"|
    assert content =~ ~S|id="parapet-main"|
    assert content =~ "Skip to main content"
  end
end
```

**Requirement:** NAV-05 (aside landmark + skip-link for detail view)

### Assertions appended to @live_template_paths test

| Assertion | Requirement |
|-----------|-------------|
| `refute content =~ "bg-teal-50"` | NAV-02 |
| `refute content =~ "text-teal-950"` | NAV-02 |
| `assert content =~ "Skip to main content"` | NAV-05 |
| `assert content =~ ~S\|id="parapet-main"\|` | NAV-05 |
| `assert content =~ ~S\|aria-live="polite"\|` | DATA-06 |
| `assert content =~ "aria-disabled"` | A11Y-03 |
| `refute content =~ "overflow-y-auto"` | DATA-02 |

### Assertions appended to @component_paths test

| Assertion | Requirement |
|-----------|-------------|
| `assert content =~ "border-bottom: 2px solid var(--parapet-accent)"` | NAV-01 |
| `assert content =~ "No timeline entries yet"` | DATA-03 |
| `assert content =~ "po-timeline-list"` | DATA-03 |
| `assert content =~ "li:last-child"` | DATA-03 |
| `assert content =~ "animate-pulse"` | DATA-06 |
| `refute content =~ "overflow-y-auto"` | DATA-02 |

---

## Verification: New Assertions Are RED

```
mix test test/parapet/operator_ui_contrast_test.exs
Running ExUnit with seed: 692776, max_cases: 36

  1) test operator live templates use semantic tokens... (Parapet.OperatorUIContrastTest)
     Refute with =~ failed
     code:  refute content =~ "bg-teal-50"
     ...

  2) test operator detail templates have correct landmarks (Parapet.OperatorUIContrastTest)
     Assertion with =~ failed
     code:  assert content =~ ~S|aria-label="Incident actions"|
     ...

  3) test operator components use semantic tokens... (Parapet.OperatorUIContrastTest)
     Assertion with =~ failed
     code:  assert content =~ "border-bottom: 2px solid var(--parapet-accent)"
     ...

Finished in 0.1 seconds (0.1s async, 0.00s sync)
4 tests, 3 failures
```

**Result:** 3 new assertion groups are RED (expected); 1 pre-existing test ("semantic operator tokens meet contrast minimums") remains GREEN. No regression.

---

## Deviations from Plan

None — plan executed exactly as written. Added assertions additively, no existing assertions removed.

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | ede74c1 | test(46-01): add @detail_template_paths constant + landmark test (NAV-05 gate) |
| Task 2 | 755854a | test(46-01): extend @live_template_paths + @component_paths with NAV/DATA/A11Y assertions |

---

## Self-Check: PASSED

- [x] test/parapet/operator_ui_contrast_test.exs modified (14 lines assertions + constant + test)
- [x] Commits ede74c1 and 755854a exist in git log
- [x] @detail_template_paths constant present
- [x] "operator detail templates have correct landmarks" test present
- [x] All new assertions are RED (3 test failures)
- [x] Pre-existing test still GREEN
- [x] No new test files introduced
