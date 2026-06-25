---
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
plan: "03"
subsystem: demo-gallery + audit-ledger
tags: [gallery, audit-matrix, GALLERY-01, GUARD-01]
status: complete

dependency_graph:
  requires:
    - 44-01-SUMMARY.md
    - 44-02-SUMMARY.md
  provides:
    - DemoAppWeb.Parapet.GalleryLive (demo-only gallery route)
    - brandbook/notes/operator-audit-matrix.md (milestone idempotence ledger)
  affects:
    - examples/demo_app/lib/demo_app_web/router.ex (new live_session :parapet_gallery)

tech_stack:
  added: []
  patterns:
    - demo-only live_session isolation (live_session :parapet_gallery after :parapet_operator)
    - explicit static component list in gallery (not dynamic introspection)
    - hardcoded fixture data in gallery mount (T-44-07 threat mitigated)
    - markdown table idempotence ledger with todo/done/verified vocabulary

key_files:
  created:
    - examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex
    - brandbook/notes/operator-audit-matrix.md
  modified:
    - examples/demo_app/lib/demo_app_web/router.ex

decisions:
  - "Gallery route isolated to demo router only (live_session :parapet_gallery); never added to router_snippet.ex.eex (D-13)"
  - "Gallery uses hardcoded fixture data in mount/3 — no Repo/Ecto calls (T-44-07)"
  - "Explicit static gallery_components/0 list of all 19 components (not dynamic introspection)"
  - "Audit matrix all 19 cells initialized to todo, D-07/D-08 #7FB4C6 exception documented"
  - "response_cockpit empty state achieved by omitting detail attr (default: nil) instead of passing nil explicitly, avoiding Phoenix compile-time type-check warning"

metrics:
  duration: "~22 minutes"
  completed: "2026-06-25"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 44 Plan 03: Gallery LiveView and Audit Matrix Summary

Demo-only `/parapet/_gallery` route rendering all 19 operator components across light/dark/state variants, plus committed `brandbook/notes/operator-audit-matrix.md` idempotence ledger with GUARD-04 dark-link exception.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add GalleryLive demo LiveView and the demo-only gallery route | f76e348 | `gallery_live.ex`, `router.ex` |
| 2 | Create the operator-audit-matrix.md component × state ledger | 2aa393a | `brandbook/notes/operator-audit-matrix.md` |

## Outcome

### Task 1: GalleryLive and gallery route

- `DemoAppWeb.Parapet.GalleryLive` created at `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex`
- All 19 operator components rendered across {light, dark} × {default, empty, overflow, disabled, long-string} states
- `mount/3` uses only hardcoded fixture data — zero `Repo.` or `Ecto` calls (T-44-07 mitigated)
- `gallery_components/0` is an explicit static list of 19 atom keys (not dynamic introspection)
- Dark variants rendered via `data-parapet-theme="dark"` wrapper sections
- `live_session :parapet_gallery` inserted in demo router AFTER `:parapet_operator`, BEFORE `scope "/ops"` (safe insertion per RESEARCH.md Pattern 4 / D-14)
- `priv/templates/parapet.gen.ui/` contains zero `_gallery` references (D-13 hard boundary intact)
- Demo app compiles cleanly with `mix compile --warnings-as-errors`
- All 5 existing demo-contract test assertions continue to pass unchanged

### Task 2: Operator audit matrix

- `brandbook/notes/operator-audit-matrix.md` created with all 19 component rows
- 8 state columns: light/dark × default/empty/overflow/disabled
- All applicable cells initialized to `todo`
- `—` used for non-applicable cells (e.g. operator_theme_bootstrap has no empty/overflow/disabled states)
- "Notes / Exceptions" section records the GUARD-04 off-palette exception for `#7FB4C6`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Phoenix compile-time type warning: nil passed for :map attr**

- **Found during:** Task 1 (first compile run)
- **Issue:** `response_cockpit` has `attr(:detail, :map, default: nil)`. Passing `detail={nil}` explicitly triggers a Phoenix compile-time type-check warning that fails `--warnings-as-errors`.
- **Fix:** Omit the `detail` attribute entirely for the empty-state renders (uses the `default: nil`). The component renders the "no active incidents" empty state when `@detail` is nil via `if @detail do` guard.
- **Files modified:** `gallery_live.ex`
- **Commit:** f76e348 (included in task 1 commit)

## Known Stubs

None — the gallery is a display surface (fixture data only). No data flows to UI rendering that requires live data.

## Threat Flags

No new security-relevant surface beyond what the plan's threat model anticipated (T-44-06, T-44-07 both mitigated per acceptance criteria).

## Self-Check: PASSED

- [x] `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` exists and defines `DemoAppWeb.Parapet.GalleryLive`
- [x] `brandbook/notes/operator-audit-matrix.md` exists with all 19 components and `#7FB4C6` exception
- [x] `live_session :parapet_gallery` present in router.ex, absent from `priv/templates/parapet.gen.ui/`
- [x] Demo app compiles with `--warnings-as-errors`
- [x] 5 existing demo-contract tests still pass
- [x] Commits f76e348 and 2aa393a exist in git history
