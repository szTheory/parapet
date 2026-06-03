---
phase: 36-demo-state-coverage-browser-verification
plan: "01"
subsystem: ui
tags: [phoenix-liveview, demo-app, browser-verification, operator-ui]
requires:
  - phase: 34-operator-ia-navigation-foundation
    provides: active-response route map
  - phase: 35-design-system-consolidation
    provides: generated/demo component helper surface
provides:
  - Rich demo seed state matrix for Operator UI inspection
  - Demo route smoke coverage for response/actions/history/detail routes
  - Browser screenshot evidence for desktop and mobile routes
requirements-completed:
  - UI-DEMO-01
  - UI-DEMO-02
  - UI-VERIFY-01
  - UI-VERIFY-02
completed: 2026-06-03
---

# Phase 36 Plan 01 Summary

Phase 36 completed the v1.3 demo and verification slice.

## Accomplishments

- Demo seeds now express the full Phase 36 state matrix: active, investigating, resolved, recovery-previewable, guidance-only, warning, action-item, escalation, audit, external-link, and retrospective.
- Demo routes and generated route guidance cover response, actions, history, preferred detail, and compatibility detail paths.
- Added `test/parapet/operator_ui_demo_contract_test.exs` to pin demo seed, route, smoke, and browser-script contracts.
- Added `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` to capture Chromium screenshots without adding repo dependencies.
- Captured desktop and mobile screenshots for response, actions, history, and incident detail routes under `screenshots/`.

## Verification

- Root generated/demo contract tests passed.
- Demo smoke route tests passed.
- Demo reset and asset build completed.
- Browser screenshot script produced eight PNGs.
- Touched-file formatting passed.

## Residuals

- Full-repo formatting still has unrelated pre-existing failures outside this phase.
- Demo smoke compilation still reports the pre-existing `Parapet.Escalation.Worker.new/1` warning from `lib/parapet/evidence.ex`; tests pass.
