---
phase: 44
slug: foundations-token-re-skin-fonts-audit-apparatus
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-24
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 44-RESEARCH.md "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds (targeted) / full suite per project norm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs`
- **After every plan wave:** Run `mix test test/parapet/`
- **Before `/gsd-verify-work`:** Full suite (`mix test`) must be green
- **Max feedback latency:** ~15 seconds (targeted tests)

---

## Per-Task Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| TOKEN-01 | Neutral vars resolve to brand neutrals (light + both dark blocks) | unit (string + contrast assert) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs re-pin | ⬜ pending |
| TOKEN-02 | Signal vars brand-aligned on panel + bg | unit (contrast assert) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs re-pin | ⬜ pending |
| TOKEN-03 | Six status triplets legible in both themes | unit (6 chips × 2 themes) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs 4 new assertions | ⬜ pending |
| TOKEN-04 | Type/spacing/radius applied, no layout shift on fallback | manual screenshot | Demo `/parapet` + `/parapet/_gallery` visual check | ❌ manual | ⬜ pending |
| TOKEN-05 | Motion tokens wired | unit (string search `--motion-fast`/`--motion-base`/`--motion-ease`) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs string assertions | ⬜ pending |
| FONT-01 | woff2 faces exist and within ≤150 KB budget; OFL LICENSE present | unit (File.exists? + File.stat!) | `mix test test/parapet/operator_ui_fonts_test.exs` | ❌ W0 (new file) | ⬜ pending |
| FONT-02 | `@font-face` rules in emitted bootstrap style with font-display: swap | unit (string search) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs string assertion | ⬜ pending |
| FONT-03 | Generator copies woff2 to host static path on run/re-run | unit (demo serves fonts) + manual gen run | `mix test test/parapet/operator_ui_demo_contract_test.exs` | ✅ needs assertion | ⬜ pending |
| A11Y-01 | Per-surface focus ring contrast ≥3:1 (watch-blue light / limestone dark) | unit (contrast_ratio assert) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs new assertion | ⬜ pending |
| MOTION-01 | Motion fully zeroed under `prefers-reduced-motion` | unit (string search in template) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs string assertion | ⬜ pending |
| GALLERY-01 | Demo-only `/parapet/_gallery` route exists, host UI untouched | unit (string search) | `mix test test/parapet/operator_ui_demo_contract_test.exs` | ✅ needs 1 new assertion | ⬜ pending |
| GUARD-01 | `brandbook/notes/operator-audit-matrix.md` committed with component × state cells | unit (File.exists? + content) | `mix test test/parapet/operator_ui_demo_contract_test.exs` | ✅ needs assertion | ⬜ pending |
| GUARD-02 | Contrast test re-pinned to brand hexes and passes WCAG AA | unit | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs full re-pin | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/parapet/operator_ui_fonts_test.exs` — new test covering FONT-01:
  - `assert File.exists?("priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2")` (× 5 faces)
  - `assert File.stat!(<each face>).size <= 153_600` and total ≤ 150 KB
  - `assert File.exists?("priv/static/parapet/fonts/LICENSE.txt")`
- [ ] Add `"parapet"` to `static_paths` in `examples/demo_app/lib/demo_app_web.ex` — code gap (not a test) required before FONT-03 can pass
- [ ] IBM Plex TTF download + `pyftsubset` run producing the five woff2 files (download step; sources not committed)

*All remaining Wave 0 work is string/assertion additions to existing test files (`operator_ui_contrast_test.exs`, `operator_ui_demo_contract_test.exs`), not new files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No layout shift on system-font fallback; type/spacing/radius visually applied | TOKEN-04 | Layout-shift / visual fidelity not assertable from string/contrast unit tests | Open demo `/parapet` and `/parapet/_gallery` in light + dark; confirm no reflow as fonts swap in; spot-check type scale, 8px grid, radii |
| Component × state visual audit | GALLERY-01 / GUARD-01 | Visual audit of every component × {light,dark,empty,overflow,disabled,long-string} | Walk `/parapet/_gallery`, mark each cell todo/done/verified in `operator-audit-matrix.md` |
| Generator copies fonts into a fresh host on `mix parapet.gen.ui` (and refresh on re-run) | FONT-03 | Requires running the generator in a scratch host project | Run `mix parapet.gen.ui` in a test project, confirm woff2 land in host `priv/static`, re-run to confirm refresh |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (fonts test, static_paths, TTF subsetting)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s (targeted suite)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
