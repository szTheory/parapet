---
phase: 46
slug: navigation-shell-data-display
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-26
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 46-RESEARCH.md "## Validation Architecture".

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

- **After every task commit:** Run the quick command.
- **After every plan wave:** Run `mix test --exclude unboxed`.
- **Before phase verification:** Full suite green.
- **Max feedback latency:** ~15 seconds (targeted run).

---

## Per-Requirement Verification Map

| Req ID | Behavior | Automated? | Command / Assertion |
|--------|----------|-----------|---------------------|
| NAV-01 | `.po-nav-active` border-bottom indicator + `aria-current="page"` | YES | `assert content =~ "border-bottom: 2px solid var(--parapet-accent)"`; `aria-current` already asserted via `po-nav-active` (`@component_paths`) |
| NAV-02 | queue-refresh notification tokenized, no `bg-teal-50` | YES | `refute content =~ "bg-teal-50"` / `text-teal-950` (`@live_template_paths`) |
| NAV-03 | theme switcher JS unchanged, `aria-pressed` present | YES | already asserted via `po-theme-option` / `aria-pressed` |
| NAV-04 | IA labels (Respond/Actions/History) | YES | already asserted in demo-contract `@live_template_paths` |
| NAV-05 | skip-link + `id="parapet-main"` + `<aside aria-label>` | YES | `assert content =~ "Skip to main content"`, `id="parapet-main"`, `aria-label="Incident actions"` (`@live_template_paths` + new `@detail_template_paths`) |
| DATA-01 | deliberate truncate/wrap (`min-w-0 flex-1` + `truncate`) | YES | `assert content =~ "min-w-0 flex-1"` + `truncate` (`@component_paths`) |
| DATA-02 | no `overflow-y-auto` added (natural-flow scroll) | YES | `refute content =~ "overflow-y-auto"` (`@component_paths` + `@live_template_paths`) |
| DATA-03 | timeline empty-state branch + last-spine suppression | YES | `assert content =~ "No timeline entries yet"`, `po-timeline-list`, `li:last-child` (`@component_paths`) |
| DATA-04 | empty states have icon (`aria-hidden` SVG) + no `cursor-pointer` | PARTIAL | `aria-hidden="true"` presence (string); `refute cursor-pointer` already asserted; correctness = gallery |
| DATA-05 | status by text/icon + color (never color-only) | YES | `po-chip` + chip text patterns already asserted |
| DATA-06 | `aria-live="polite"` + `animate-pulse` zeroed under reduced-motion | YES | `assert aria-live="polite"`, `animate-pulse`, existing `prefers-reduced-motion` / `--motion-fast: 0ms` |
| A11Y-03 | `po-focus` on enabled pagination + `aria-disabled` on disabled | PARTIAL/YES | inspect `pagination_link_class` body for `po-focus`; `assert aria-disabled` (`@live_template_paths`) |
| A11Y-04 | logical tab order, no keyboard trap (no modal in scope → Phase 47) | N/A | no automatable surface this phase |

---

## Wave 0 Requirements

- [ ] Add a `@detail_template_paths` constant + `"operator detail templates have correct landmarks"` test to `test/parapet/operator_ui_contrast_test.exs` (covers `operator_detail_live.ex.eex` + mirror).
- [ ] Extend the existing `@live_template_paths` test with NAV-02/NAV-05/DATA-02/DATA-06/A11Y-03 assertions (refute `bg-teal-50`/`overflow-y-auto`; assert skip-link, `id="parapet-main"`, `aria-live="polite"`, `aria-disabled`).
- [ ] Extend the `@component_paths` test with NAV-01 (`border-bottom: 2px solid var(--parapet-accent)`), DATA-03 (`No timeline entries yet`, `po-timeline-list`, `li:last-child`) assertions.

*No new test files — all additive to the existing Phase 44/45 harness.*

---

## Manual / Gallery-Only Verifications

| Behavior | Requirement | Why manual | Verification |
|----------|-------------|------------|--------------|
| 390px no horizontal overflow | NAV-02 | needs browser rendering | gallery at 390px (`make gallery-shot` mobile capture) |
| End-to-end tab order, no keyboard trap | A11Y-04 | needs browser + keyboard | gallery manual walkthrough |
| Skip-link visible on focus | NAV-05 | needs focus rendering | gallery, Tab from top |
| Timeline last-spine suppression visual | DATA-03 | rendering context | gallery timeline (1–3 entries) |
| Skeleton no layout-jump | DATA-06 | real LiveView mount cycle | smoke test while seeds load |

*Mobile/responsive + keyboard checks lean on the gallery (`make gallery` / `gallery-shot`, mobile 414px capture) — automatable string assertions cover the markup contracts; the gallery covers the rendered behavior.*

---

## Validation Sign-Off

- [ ] Every requirement has an automated assertion or a Wave 0 dependency (except the inherently-visual NAV-02/A11Y-04/DATA-06 rendered behaviors, routed to gallery)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the new `@detail_template_paths` group + extended assertions
- [ ] Feedback latency < 15s (targeted run)
- [ ] `nyquist_compliant: true` set after plan-checker pass

**Approval:** pending
