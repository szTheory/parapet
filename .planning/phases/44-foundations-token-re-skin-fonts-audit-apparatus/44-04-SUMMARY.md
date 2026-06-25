---
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
plan: "04"
subsystem: test-gates
tags: [contrast-gate, wcag-aa, brand-tokens, demo-contract, wave-2]
status: complete

dependency_graph:
  requires: ["44-01", "44-02", "44-03"]
  provides:
    - re-pinned contrast gate (GUARD-02) green at WCAG AA on brand token hexes
    - additive demo-contract assertions for gallery/font/audit-matrix (GALLERY-01, FONT-03, GUARD-01)
  affects:
    - test/parapet/operator_ui_contrast_test.exs
    - test/parapet/operator_ui_demo_contract_test.exs
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex

tech_stack:
  patterns:
    - ExUnit contrast assertion loop over @themes module attribute
    - Pre-verified WCAG relative-luminance math (existing helpers, byte-unchanged)
    - Additive assertion pattern (new assertions after existing route contract)

key_files:
  modified:
    - test/parapet/operator_ui_contrast_test.exs
    - test/parapet/operator_ui_demo_contract_test.exs
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex

decisions:
  - "Dark warning button fg changed from #F8F4EC to #101820 (5.62:1 AA pass vs 2.9:1 fail) — pre-verified ratios in plan omitted this pairing"
  - "Both component files (demo mirror + template) fixed in lockstep per D-04 / D-16 sync requirement"

metrics:
  duration: "5 minutes 45 seconds"
  completed: "2026-06-25T02:32:51Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 44 Plan 04: Wave-2 Gate — Re-pin Contrast Test + Additive Demo-Contract Assertions

Re-pinned `operator_ui_contrast_test.exs` to brand token hexes with six status triplets, dark links on surface AND bg, and focus-ring assertions at the 3:1 UI floor; added additive gallery/font/audit-matrix assertions to `operator_ui_demo_contract_test.exs` without disturbing the byte-exact 5-route contract. Full suite green (WCAG AA).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Re-pin @themes and assertions in operator_ui_contrast_test.exs | 4b43473 | test/parapet/operator_ui_contrast_test.exs, examples/demo_app/.../operator_components.ex, priv/templates/.../operator_components.ex.eex |
| 2 | Add additive gallery/font/audit-matrix assertions to demo-contract test | bc57f18 | test/parapet/operator_ui_demo_contract_test.exs |

## Verification Results

- `mix test test/parapet/operator_ui_contrast_test.exs` — 2 tests, 0 failures
- `mix test test/parapet/operator_ui_demo_contract_test.exs` — 5 tests, 0 failures
- `mix test --exclude unboxed` — 547 tests, 0 failures (10 excluded pre-existing unboxed cluster-peer tests)
- `mix test` — 557 tests, 1 failure (pre-existing `:unboxed` executor_cluster_smoke_test that requires distributed Erlang; `** (exit) time out` on `peer.start_link` — unrelated to this plan)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dark warning button fg corrected from `#F8F4EC` to `#101820`**

- **Found during:** Task 1 — pre-flight contrast math check
- **Issue:** `#F8F4EC` (limestone) on `#D97706` (beacon-amber-light) = **2.9:1** — fails WCAG AA (4.5:1 requirement). The plan's PATTERNS.md specified this pairing, but the "Pre-verified Contrast Ratios" section in RESEARCH.md omitted the dark `warning_button` ratio. The ratio was simply not computed when the plan was written.
- **Fix:** Changed `warning_button_fg` in the dark `@themes` map from `#F8F4EC` to `#101820` (parapet-black). `#101820` on `#D97706` = **5.62:1** — passes AA. Fixed the same value in both component CSS files (demo mirror `examples/demo_app/.../operator_components.ex` and template `priv/templates/.../operator_components.ex.eex`) in both dark blocks (explicit `[data-parapet-theme="dark"]` + `@media` blocks).
- **Files modified:** `test/parapet/operator_ui_contrast_test.exs`, `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`, `priv/templates/parapet.gen.ui/operator_components.ex.eex`
- **Commit:** 4b43473

## What Was Built

### Task 1: Contrast test re-pin

**`@themes` module attribute** (both light and dark) fully rewritten to brand token hexes:

- `bg`, `panel`, `header_bg`, `header_title`, `header_muted` — limestone/white/parapet-black/watch-blue palette
- `link_on_panel` (link on panel surface) + `link_on_bg` (link on bg) — light: `#256C82`; dark: `#7FB4C6` (D-07 operator exception)
- `focus_ring` — light: `#256C82` (5.92:1 on white); dark: `#F8F4EC` (14.57:1 on deep-slate)
- Full nav/hover/active/theme-control tokens
- Six status chip triplets: `healthy_bg/fg`, `watch_bg/fg`, `burning_bg/fg`, `exhausted_bg/fg`, `unknown_bg/fg`, `ai_bg/fg`
- `warning_button_bg/fg` — light: `#FFFFFF`/`#B45309` (5.02:1); dark: `#101820`/`#D97706` (5.62:1)

**Test body rewrite** — `"semantic operator tokens meet contrast minimums"` now asserts:
- `header_title`, `header_muted` on `header_bg` at 4.5
- `link_on_panel` on `panel` at 4.5; `link_on_bg` on `bg` at 4.5
- `nav`, `nav_hover`, `nav_active`, `theme_control` at 4.5
- All six chip assertions at 4.5
- `warning_button` at 4.5
- `focus_ring` at **3.0** (GUARD-02 — 3:1 UI floor, against `panel` in light, `bg` in dark)

**String assertions** added to `"operator components use semantic tokens for known dark-mode risk surfaces"` inside the `for path <- @component_paths` loop:
- `"--motion-fast"`, `"--motion-base"`, `"--motion-ease"` (MOTION-01)
- `"prefers-reduced-motion"`, `"--motion-fast: 0ms"` (MOTION-01 zeroing)
- `"@font-face"`, `"IBM Plex Sans"`, `"font-display: swap"` (FONT-02)

**Private helpers** (`assert_contrast/4`, `contrast_ratio/2`, `relative_luminance/1`, `rgb/1`, `linear_channel/1`) are byte-unchanged.

### Task 2: Demo-contract additive assertions

Added after the existing smoke path assertions inside `"demo routes mirror the generated operator UI route shape"`:

- `GALLERY-01`: `assert router =~ ~S|live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index)|`
- `GALLERY-01`: `assert router =~ "live_session :parapet_gallery"`
- `FONT-03`: `assert File.exists?("priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2")`
- `GUARD-01`: `assert File.exists?("brandbook/notes/operator-audit-matrix.md")`

All 5 original `live(...)` route substring assertions and the `:binary.match` scope ordering check are unchanged.

## Self-Check: PASSED

- `test/parapet/operator_ui_contrast_test.exs` — FOUND
- `test/parapet/operator_ui_demo_contract_test.exs` — FOUND
- Commit `4b43473` (Task 1) — FOUND
- Commit `bc57f18` (Task 2) — FOUND
- `focus_ring` appears 3 times in contrast test — FOUND (key content present)
- `live_session :parapet_gallery` in demo-contract test — FOUND
- `operator-audit-matrix` in demo-contract test — FOUND
