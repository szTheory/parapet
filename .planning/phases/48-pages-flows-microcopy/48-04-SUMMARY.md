---
phase: 48-pages-flows-microcopy
plan: 04
subsystem: gate
tags: [phoenix, liveview, exunit, audit-matrix, n-a-by-design, human-gate, gallery, phase-close]

# Dependency graph
requires:
  - phase: 48-pages-flows-microcopy
    provides: "Wave-1 RED scaffold (48-01) + component-layer green (48-02) + shell/service green (48-03) — every FLOW/COPY/A11Y assertion driven green"
provides:
  - "Phase-48 closing gate: lib + demo suites verified green (every 48-01 assertion satisfied, D-19 wave 4)"
  - "operator-audit-matrix.md FLOW/COPY/A11Y component×state cells flipped to done/verified with per-cell evidence pointers"
  - "Two named N/A-by-Design rows (unavailable + permission-denied) with grep proof (D-12)"
  - "Blocking human /parapet/_gallery walkthrough instructions (four human-only facts)"
affects: [49-stress-fixtures, 50-guardrails-parity-idempotence]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gate + ledger plan: runs the full lib + demo suites, flips the audit-matrix ledger, runs a blocking human visual walkthrough — never edits source/template/test (failures route back to 48-02/48-03)"
    - "N/A-by-Design rows with grep proof (Phase-47 GROUP convention) for FLOW-03 unavailable (synchronous in-node reads) + permission-denied (host-owned authz at router) — never a stubbed pane (D-12)"

key-files:
  created: []
  modified:
    - brandbook/notes/operator-audit-matrix.md

key-decisions:
  - "Both N/A-by-Design rows recorded as ledger rows with grep proof, never stubbed panes (D-12): unavailable proven by zero assign_async/Task in operator templates; permission-denied proven by host-owned auth pipeline in router_snippet"
  - "operator_nav/critical_journeys overflow + empty cells flipped using each Phase-48 gate's proving test name as the evidence pointer"

requirements-completed: [FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05, COPY-01, COPY-02, COPY-03, COPY-04, COPY-05, A11Y-06]

coverage:
  - id: G1
    description: "Full lib suite (mix test) green — every 48-01 source-string + rendered assertion satisfied; only 2 pre-existing/unrelated failures remain (out of scope, deferred-items.md)"
    verification:
      - kind: integration
        ref: "mix test — 570 tests, 2 failures (DocsPhase33Test + ExecutorClusterSmokeTest only; all Phase-48 gates pass)"
        status: pass
    human_judgment: false
    rationale: ""
  - id: G2
    description: "Full demo suite (cd examples/demo_app && mix test) green — every rendered-state Phase-48 gate (single-h1, not-found unknown+malformed, page_title, skeleton, empty-during-load, landmark) passes"
    verification:
      - kind: integration
        ref: "cd examples/demo_app && mix test — 25 tests, 0 failures"
        status: pass
    human_judgment: false
    rationale: ""
  - id: G3
    description: "operator-audit-matrix FLOW/COPY/A11Y cells flipped to done/verified with per-cell evidence pointers; two N/A-by-Design rows (unavailable + permission-denied) with grep proof"
    verification:
      - kind: other
        ref: "brandbook/notes/operator-audit-matrix.md — Phase-48 rows carry test-name evidence pointers; N/A-by-Design section has both rows + grep-proof commands"
        status: pass
    human_judgment: false
    rationale: ""
  - id: G4
    description: "Blocking human /parapet/_gallery walkthrough — four human-only facts (390px copy reading-flow, heading-hierarchy legibility after h1 demotion, empty-state feels-designed, keyboard focus-visibility)"
    verification:
      - kind: manual_procedural
        ref: "Blocking human gallery walkthrough at /parapet/_gallery (DemoAppWeb.Parapet.GalleryLive) — APPROVED: all four human-only facts pass"
        status: pass
    human_judgment: true
    rationale: "Visual/keyboard facts the automated suite cannot prove (390px reading-flow calmness, post-demotion heading legibility, empty-state intentionality, focus-ring visibility). Human walked the gallery and approved all four checks (approved-with-non-blocking-follow-up; the follow-up polish items are out of Phase-48 scope and do not block closure)."

# Metrics
duration: human-gated (Task 1 automated work same-session; closed at human sign-off 2026-06-28)
completed: 2026-06-28
status: complete
---

# Phase 48 Plan 04: Wave-4 Closing Gate Summary

**The phase-completion gate, now CLOSED: both full suites verified green (lib 570/2 pre-existing-only, demo 25/0 — every 48-01 assertion satisfied), the operator-audit-matrix FLOW/COPY/A11Y cells flipped to done/verified with per-cell test-name evidence pointers, two N/A-by-Design rows (unavailable + permission-denied) recorded with grep proof, and a human has walked the `/parapet/_gallery` route and APPROVED all four facts the automated suite cannot prove. Phase 48 is complete.**

## Automated Work Completed

### Suite gate (Task 1) — both green

- **Lib suite** (`mix test`): **570 tests, 2 failures.** The only two failures are `Parapet.DocsPhase33Test` (Phase-33 Compose-doc assertion) and `Parapet.Automation.ExecutorClusterSmokeTest` (a known timing-sensitive local-plus-peer race canary) — both pre-existing/unrelated, confirmed failing on clean HEAD with this milestone's work in earlier waves, and logged to `deferred-items.md` (SCOPE BOUNDARY). **Every Phase-48 (48-01) assertion is GREEN.**
- **Demo suite** (`cd examples/demo_app && mix test`): **25 tests, 0 failures.** All rendered-state Phase-48 gates pass: single-h1 per page, not-found (unknown UUID + malformed id, not a 500), `page_title(view)` per page, uniform disconnected skeleton, empty-during-load gate, landmark cross-check.

No source/template/test file was modified by this plan (gate + ledger only) — verified via `git status` (only `brandbook/notes/operator-audit-matrix.md` changed).

### Audit-matrix flip (Task 1)

Flipped every Phase-48 component×state cell in `brandbook/notes/operator-audit-matrix.md` to `done`/`verified`, each with a one-line evidence pointer (the proving test name). Rows touched: `operator_nav`, `response_cockpit`, `nav_item`, `operator_overview`, `action_center`, `incident_list`, `incident_row`, `incident_summary`, `incident_timeline`, `suspect_changes_card`, `retrospective_card`, `runbook_card`, `preview_panel`, `action_item_card`, `critical_journeys`, plus a **new `incident_not_found` row** (D-02 designed panel).

Example evidence pointers:
- `incident_not_found` → lib `COPY-03: not-found heading + body copy pinned verbatim (D-02)` + demo `FLOW-03: detail with unknown UUID renders the not-found panel in-page` / `…malformed id…(not a 500)`.
- `operator_nav` → contrast `text-white">Active response workbench` refute + demo `FLOW-02: each operator page renders exactly one h1`.
- `runbook_card` → lib `COPY-03: the 10+1 re-authored microcopy strings are pinned verbatim (D-13)`.

### Two N/A-by-Design rows (D-12) — grep proof, never stubbed

Added a `Phase-48 N/A-by-Design Exception: FLOW-03 unavailable + permission-denied` section reusing the Phase-47 GROUP-03/05/06 convention:

- **`unavailable` (infra)** → N/A-by-design. Grep proof: `grep -rEn "assign_async|Task\.(async|start)|start_async"` over the three operator templates → **zero matches** (synchronous in-node repo reads; DB/process failure is genuinely the host's 5xx, not an in-page "not found" state — D-03).
- **`permission-denied`** → N/A-by-design. Grep proof: `grep -nE "pipe_through|require_authenticated|on_mount|auth" router_snippet.ex.eex` → the host auth-pipeline guidance (`# Parapet does not provide its own auth.`, `pipe_through [:browser, :require_authenticated_user]`, `on_mount {…UserAuth, :ensure_authenticated}`). LiveViews reached only post-authorization; the not-found panel must not imply authz.

## Threat re-verification (gate)

- **T-48-01 (reflected XSS, `@requested_id`):** the malformed-id and unknown-UUID not-found rendered asserts pass (demo smoke green); 48-02 grep confirmed `@requested_id` is escaped text content only. Human walkthrough will additionally confirm the requested id displays as inert text.
- **T-48-02 (uncaught 500, malformed `:id`):** the `FLOW-03: …malformed id renders the not-found panel in-page (not a 500)` demo assert passes — the dual-exception footgun is collapsed to one designed in-page panel.

## Task Commits

1. **Task 1: audit-matrix FLOW/COPY/A11Y flip + two N/A-by-Design rows** — `214f206` (docs)

## Deviations from Plan

None — plan executed exactly as written. Both suites were already green from waves 1-3; no failure had to be routed back to 48-02/48-03, and no source/template/test edit was needed.

## Known Stubs

None — the two N/A-by-Design conditions are recorded as ledger rows with grep proof, never stubbed panes (D-12 honored).

## Human Gate (Task 2) — APPROVED

Task 2 was a `checkpoint:human-verify` with `gate="blocking-human"`. The human launched the gallery (`cd examples/demo_app && make gallery` → DB-less `/parapet/_gallery` on a free loopback port), walked the real flow (`/parapet` → `/parapet/actions` → `/parapet/history` → incident detail, plus a bogus-id not-found panel), and signed off.

### Sign-off (recorded verbatim, coordinator-relayed)

> The human completed the /parapet/_gallery walkthrough and APPROVED the four checks (copy reading-flow @390px, heading hierarchy after the h1 demotion, designed empty-states, keyboard focus-visibility). Approval is "approved with follow-up": the four blocking facts all pass and Phase 48's verification contract is satisfied — close the plan as complete.

All four blocking human-only facts pass:

1. **Copy reading-flow at 390px** — PASS (symptom → evidence → safe next action; zero horizontal scroll).
2. **Heading-hierarchy legibility after the h1 demotion** — PASS (banner reads as banner; each page's real h1 is the page subject; order monotonic).
3. **Empty-state feels designed not broken** — PASS (intentional icon + heading + body + single next-action).
4. **Keyboard focus-visibility** — PASS (skip-to-content link works; nav + not-found links show a visible focus ring).

Phase 48's verification contract is satisfied; the plan is closed as **complete**.

## Non-Blocking Follow-up (out of Phase-48 scope)

Alongside the approval, the human raised visual-polish refinements being handled as a **dedicated follow-up commit set beyond Phase 48's scope** — recorded here so they are not lost, but they **do NOT block phase closure**:

- Chip spacing
- Timeline timestamp formatting
- Retrospective markdown rendering
- Preview-panel layout
- Responsive font sizing

These are cosmetic refinements on top of an already-passing verification contract — no FLOW/COPY/A11Y assertion or audit-matrix cell depends on them. Candidate to fold into Phase 49 (stress fixtures) or a dedicated polish pass.

## Self-Check: PASSED

- `48-04-SUMMARY.md` exists on disk with `status: complete`.
- `brandbook/notes/operator-audit-matrix.md` exists and is modified (Phase-48 cells flipped + two N/A-by-Design rows present).
- Commit `214f206` (audit-matrix flip) present in git log.
- Commit `3031703` (SUMMARY automated portion) present in git log.
- Lib suite 570/2 (pre-existing-only) and demo suite 25/0 reproduced — every 48-01 assertion green.
- No source/template/test file modified by this plan (gate + ledger only).
- Blocking human gallery gate satisfied (all four facts APPROVED) — atomic close-out invariant honored: the plan stayed open until the human gate cleared.

---
*Phase: 48-pages-flows-microcopy*
*Completed: 2026-06-28 — Phase 48 complete*
