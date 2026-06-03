# Phase 36: demo-state-coverage-browser-verification - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Complete

## Phase Boundary

Phase 36 finishes v1.3 by making the demo app express the important Operator UI states and by producing browser-backed evidence for the generated route experience.

Scope is limited to `UI-DEMO-01`, `UI-DEMO-02`, `UI-VERIFY-01`, and `UI-VERIFY-02`: richer demo seeds, generated/demo route parity, source/smoke coverage, and desktop/mobile screenshots.

This phase does not change stable `Parapet.Operator` API semantics, auth ownership, default install ownership, or the dependency/support surface.

## Decisions

- Keep Phase 36 because `.planning/REQUIREMENTS.md` mapped four unchecked requirements to it even though `.planning/STATE.md` had prematurely marked v1.3 complete after Phase 35.
- Preserve Phase 34 route semantics: `/parapet` response, `/parapet/actions`, `/parapet/history`, preferred `/parapet/incidents/:id`, and compatibility `/parapet/:id`.
- Use demo seed source contracts plus demo smoke tests to prove state and route coverage without depending on seeded dev DB state in ExUnit.
- Use the locally installed Chromium binary for browser screenshots and write durable evidence into `.planning/phases/36-demo-state-coverage-browser-verification/screenshots/`.
- Do not add Playwright, Wallaby, npm packages, Hex packages, or CI dependency changes for screenshot capture.

## Canonical References

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/phases/34-operator-ia-navigation-foundation/34-CONTEXT.md`
- `.planning/phases/35-design-system-consolidation/35-CONTEXT.md`
- `examples/demo_app/priv/repo/seeds.exs`
- `examples/demo_app/lib/demo_app_web/router.ex`
- `examples/demo_app/test/demo_app/operator_smoke_test.exs`
- `examples/demo_app/scripts/capture_operator_ui_screenshots.sh`

## Notes

- Existing full-repo formatting debt remains outside this phase. Touched-file formatting is the relevant gate.
- The demo smoke lane still emits the pre-existing `Parapet.Escalation.Worker.new/1` warning from `lib/parapet/evidence.ex`; tests pass.
