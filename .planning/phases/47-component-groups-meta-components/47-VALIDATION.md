---
phase: 47
slug: component-groups-meta-components
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-26
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 47-RESEARCH.md "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs` |
| **Full suite command** | `mix test --exclude unboxed` |
| **Estimated runtime** | ~15 seconds (targeted) / full suite per project norm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs`
- **After every plan wave:** Run `mix test --exclude unboxed`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds (targeted run)

---

## Per-Task Verification Map

> Task IDs are provisional (assigned during planning). All assertions are **additive** to the
> existing `test/parapet/operator_ui_contrast_test.exs` paired loops — no new test files (D-15).
> The `@component_paths` loop reads both the template and its demo mirror, so every assertion
> enforces demo-mirror parity implicitly (D-18).

| Task ID | Wave | Requirement | Secure Behavior | Test Type | Automated Command (assertion) | File Exists | Status |
|---------|------|-------------|-----------------|-----------|-------------------------------|-------------|--------|
| 47-01 | 1 | GROUP-01 | N/A | unit (string assert) | `assert content =~ "break-words"` (`@component_paths`) | ✅ | ⬜ pending |
| 47-01 | 1 | GROUP-02 | N/A | unit (string assert) | `assert content =~ "What users are seeing"` / `"Evidence on record"` / `"Where to inspect"` / `"Safe next step"` (`@component_paths`) | ✅ | ⬜ pending |
| 47-01 | 1 | GROUP-02 | N/A | unit (string assert) | `assert content =~ "No user-facing impact has been recorded yet."` and `"No trace or external links are attached to this incident yet."` | ✅ | ⬜ pending |
| 47-01 | 1 | GROUP-03/05/06 | N/A-by-design guard | unit (negative guard) | `refute content =~ "role=\"dialog\""` · `refute content =~ "aria-modal"` · `refute content =~ ~S\|class="fixed inset-0\|` | ✅ | ⬜ pending |
| 47-01 | 1 | A11Y-05 | Disclosure (not Dialog) | unit (string assert) | `assert content =~ "md:relative md:inset-auto"` · `assert content =~ ~S\|role="region"\|` · `assert content =~ ~S\|aria-label="Recovery Preview"\|` | ✅ | ⬜ pending |
| 47-01 | 1 | GROUP-04 | risk by color+icon+label; `aria-disabled` discoverable | unit (string assert) | `assert content =~ "action_item_risk"` · `assert content =~ "Resolved · audited"` · `assert content =~ ~S\|[aria-disabled="true"]\|` | ✅ | ⬜ pending |
| 47-01 | 1 | MOTION-03 | reduced-motion-safe | unit (string assert) | `assert content =~ "@keyframes po-preview-reveal"` · `assert content =~ "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"` | ✅ | ⬜ pending |
| 47-01 | 1 | A11Y-05 / D-02 | WCAG 2.4.11 focus-not-obscured | unit (string assert) | `assert content =~ "scroll-pb-72"` (`@detail_template_paths`) | ✅ | ⬜ pending |
| 47-02 | 2 | GROUP-01/02/04, MOTION-03, D-02 | — | unit (red→green flip) | template + demo-mirror edits make 47-01 asserts pass; `mix test test/parapet/operator_ui_contrast_test.exs` exits 0 | ✅ | ⬜ pending |
| 47-03 | 3 (optional) | A11Y-05 (Esc parity) | — | unit (string assert, if shell edit) | shell-edit mirror (`operator_detail_live`) assertions if any; else folded into 47-02 | ✅ | ⬜ pending |
| 47-04 | 4 | all (gate) | — | full suite + audit matrix | `mix test --exclude unboxed` exits 0; audit-matrix cells flipped; **blocking human gallery walkthrough** | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All test additions land in the existing `test/parapet/operator_ui_contrast_test.exs` — **no new test
files** (D-15). Wave 47-01 adds the assertions in RED (they fail until Wave 47-02 ships the markup):

- [ ] GROUP-01 — `break-words` on cockpit `<h2>` assert (`@component_paths`)
- [ ] GROUP-02 — formula-label asserts + updated-fallback asserts (`@component_paths`)
- [ ] GROUP-03/05/06 — N/A negative-guards: `refute role="dialog"`, `refute aria-modal`, `refute class="fixed inset-0` (guard the full-screen scrim pattern only — `preview_panel` legitimately uses `fixed inset-x-0 bottom-0`)
- [ ] A11Y-05 — Disclosure-shape asserts (`md:relative md:inset-auto`, `role="region"`, `aria-label="Recovery Preview"`)
- [ ] GROUP-04 — `action_item_risk`, `Resolved · audited`, `[aria-disabled="true"]` CSS asserts
- [ ] MOTION-03 — `@keyframes po-preview-reveal` + `animation: po-preview-reveal var(--motion-base) var(--motion-ease)` asserts
- [ ] D-02 (A11Y-05) — `scroll-pb-72` assert on `@detail_template_paths`

*Existing infrastructure (paired `@component_paths` / `@detail_template_paths` loops, contrast +
string assertions) covers all phase requirements.*

---

## Manual-Only Verifications

> Reserved for the blocking human gallery walkthrough (`/parapet/_gallery`) at Wave 47-04 (D-18).
> Genuinely-rendered cells only — everything else is automated above.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 390px cockpit composition (source-order stack: title → impact → evidence → journeys/counts) | GROUP-01 | Visual layout/reflow not assertable by string search | Open gallery at 390px; confirm cockpit grid collapses to single column with `gap-6`, impact-first read, no width blowout from long titles |
| Preview-panel disclosure open/close + focus-to-close on mobile | A11Y-05 | Focus restoration + bottom-sheet reveal is interaction behavior | On a short mobile viewport, open preview, confirm trigger not obscured (D-02), close via button, confirm focus returns to trigger |
| MOTION-03 reveal feel + interruptibility | MOTION-03 | Animation timing/feel + mid-animation interaction not assertable statically | Open preview; confirm lift+fade reveal uses brand easing; click Confirm/Cancel mid-animation — must stay live; verify reduced-motion neutralizes it |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies (manual items are render-only gallery cells)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (all assertions additive to existing test file)
- [x] No watch-mode flags
- [x] Feedback latency < 15s (targeted run)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-26
