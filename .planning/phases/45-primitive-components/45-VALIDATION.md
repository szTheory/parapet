---
phase: 45
slug: primitive-components
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-25
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 45-RESEARCH.md "## Validation Architecture".

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
- **Before `/gsd-verify-work`:** Full suite (`mix test --exclude unboxed`) must be green
- **Max feedback latency:** ~15 seconds (targeted run)

---

## Per-Task Verification Map

| Req ID | Wave | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|------|----------|-----------|-------------------|-------------|--------|
| COMP-01 | W0+ | Button variants tokenized — rest/hover/active/focus/disabled in both themes | unit (string + contrast) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ add button_bg/fg pairs to `@themes` | ⬜ pending |
| COMP-02 | — | Disabled controls visually + semantically disabled | string search + manual gallery audit | `grep -c "disabled\|aria-disabled" …operator_components.ex.eex` | manual + assert | ⬜ pending |
| COMP-03 | — | Links meet AA on surface | unit (contrast) | `mix test …operator_ui_contrast_test.exs` | ✅ already asserts link_on_panel/link_on_bg | ⬜ pending |
| COMP-04 | — | Chips/badges use brand status triplets, AA dark | unit (contrast) | `mix test …operator_ui_contrast_test.exs` | ✅ six chip triplets already asserted | ⬜ pending |
| COMP-05 | — | Stat/metric cards — no spurious hover/pointer | unit (refute) | `refute content =~ "cursor-pointer"` | ✅ add refute | ⬜ pending |
| COMP-06 | — | Focus rings visible via `po-focus` | unit (assert) | `assert content =~ "po-focus"` | ✅ strengthen assertion | ⬜ pending |
| COMP-07 | — | Icons/dividers tokenized, no raw color badge utils | unit (refute) | `refute content =~ "bg-purple-100 text-purple-800"` | ✅ add refute | ⬜ pending |
| COMP-08 | — | No off-palette/raw-Tailwind hex remains (gate) | unit (refute) | `refute content =~ "bg-indigo-600"` … `refute content =~ "#042f2e"` | ✅ add refutes | ⬜ pending |
| FORM-01 | — | Theme switcher tokenized + accessible labels | unit (assert) | `assert content =~ ~S|aria-label="Operator color theme"|` | ✅ exists + po-focus assert | ⬜ pending |
| FORM-02 | — | Form controls — accessible names, error/disabled not color-only | unit (assert) | `assert content =~ ~S|aria-pressed|` | ✅ add assert | ⬜ pending |
| A11Y-02 | W0+ | All text 4.5:1 (3:1 large); UI 3:1 both themes | unit (extend `@themes`) | `mix test …operator_ui_contrast_test.exs` | ✅ add new button pairs | ⬜ pending |
| MOTION-02 | — | No `transition-all`; `--motion-fast` used (~120ms) | unit (refute + assert) | `refute content =~ "transition-all"` / `assert content =~ "duration-[--motion-fast]"` | ✅ add refute/assert | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `@themes` in `test/parapet/operator_ui_contrast_test.exs` with primary/destructive/success button bg+fg pairs (light + dark) and add `assert_contrast/5` calls for each (COMP-01, A11Y-02).
- [ ] Add refute/assert assertions for COMP-08 / MOTION-02 / COMP-06 / COMP-07 / COMP-05 / FORM-02 to the second test in `operator_ui_contrast_test.exs`.

*No new test files needed — all assertions are additive to the existing Phase 44 harness (`operator_ui_contrast_test.exs`, `operator_ui_demo_contract_test.exs`).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Disabled controls have reduced affordance and are not "disabled-looking-but-live" | COMP-02 | Visual affordance can't be fully asserted by string search | Open `/parapet/_gallery`, toggle both themes, confirm disabled buttons read as disabled and are non-interactive |
| Hover/press micro-interactions feel fast and purposeful | MOTION-02 | Perceived motion timing is qualitative | Hover/press each button variant in the gallery in both themes; confirm no `transition-all` thrash |

*All gate-enforceable behaviors (COMP-08 hex gate, contrast minimums) have automated verification; the two rows above are confirmatory visual checks the gallery + screenshot capture support.*

---

## Validation Sign-Off

- [ ] All requirements have an `<automated>` verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new `@themes` button pairs + new refute/assert set)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s (targeted run)
- [ ] `nyquist_compliant: true` set in frontmatter after plan-checker pass

**Approval:** pending
