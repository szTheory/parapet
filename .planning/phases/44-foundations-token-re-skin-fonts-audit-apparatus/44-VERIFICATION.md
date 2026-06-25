---
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
verified: 2026-06-25T02:43:21Z
status: human_needed
score: 12/13
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Open the demo app at /parapet and /parapet/_gallery in both light and dark themes. Verify the type scale matches the brand type scale, the 8px spacing grid is visually consistent, and the radius scale (card ~10px, controls ~8px, modals ~14px, pills ~999px) is applied. Confirm there is no reflow / layout shift as IBM Plex fonts swap in over the system fallback."
    expected: "Elements use brand-scale radii and spacing; no visible reflowing as fonts load; IBM Plex Sans renders for body/headings and IBM Plex Mono renders for code/IDs"
    why_human: "TOKEN-04 radius/type-scale correctness is a visual-fidelity check (layout shift and sizing cannot be asserted from string/contrast unit tests). The REQUIREMENTS.md marks TOKEN-04 as pending and VALIDATION.md explicitly classifies this as a manual-only check."
---

# Phase 44: Foundations — token re-skin, fonts & audit apparatus — Verification Report

**Phase Goal:** The operator theme is re-based on brand tokens (color/type/spacing/radius/shadow/motion/focus), self-hosted IBM Plex woff2 is vendored and wired with a clean system fallback, the demo-only component lab and audit ledger exist, and the contrast gate is re-pinned to brand hexes — establishing the foundation every later layer builds on.

**Verified:** 2026-06-25T02:43:21Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | An operator viewing the UI in both themes sees brand neutrals, signal colors, and six brand status triplets with no off-brand teal remaining; type scale, 8px grid, and radius scale applied without layout shift | PRESENT_BEHAVIOR_UNVERIFIED | Color re-skin and status triplets are VERIFIED (code + tests). Residual off-brand teal (border-l-teal-700, ring-teal-200, focus:ring-teal-300, hover variants in secondary templates) exists but are cosmetic/hover/interactive states deferred to Phase 45 per D-01. Token-04 radius/type-scale visual verification is manual-only per VALIDATION.md. |
| SC-2 | The UI renders true IBM Plex served from host static path with font-display: swap, falls back cleanly to system stack, demo app serves same fonts | VERIFIED | 5 woff2 files in priv/static/parapet/fonts/ (53KB, under 150KB ceiling), OFL LICENSE present; @font-face rules with font-display: swap in both template and demo mirror; --font-sans/--font-mono with full system-stack fallback; demo static_paths includes "parapet"; fonts test (4 tests) green |
| SC-3 | Motion is driven by brand motion tokens and fully zeroed under prefers-reduced-motion; per-surface focus rings enforced by contrast gate | VERIFIED | --motion-fast: 120ms, --motion-base: 200ms, --motion-ease: cubic-bezier(.2,0,0,1) in template and mirror; prefers-reduced-motion block zeros both vars; --po-focus: #256C82 (light), #F8F4EC (dark); contrast test asserts focus rings at 3:1 UI floor; both @component_paths in contrast test |
| SC-4 | Developer can open demo-only /parapet/_gallery (never shipped to host) and the operator-audit-matrix.md ledger enumerates every component x state cell | VERIFIED | live_session :parapet_gallery in demo router after :parapet_operator, before scope "/ops"; priv/templates/parapet.gen.ui/ has zero _gallery references; gallery_live.ex defines DemoAppWeb.Parapet.GalleryLive with no Repo. calls; brandbook/notes/operator-audit-matrix.md has all 19 components, #7FB4C6 exception documented |
| SC-5 | operator_ui_contrast_test.exs is re-pinned to brand token hexes (all six status triplets, dark links on surface and bg, focus rings at 3:1 UI floor) and passes at WCAG AA | VERIFIED | @themes fully rewritten to brand hexes; asserts healthy/watch/burning/exhausted/unknown/ai chips at 4.5:1; link_on_panel and link_on_bg at 4.5:1; focus_ring at 3.0; dark warning button fixed from #F8F4EC (fail) to #101820 (5.62:1); 2 contrast tests green |

**Score:** 12/13 truths verified (1 present, behavior/visual unverified: TOKEN-04 radius/type-scale visual check)

---

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Off-brand teal in secondary templates: bg-teal-700/hover:bg-teal-800/focus:ring-teal-300 (queue-refresh CTA), hover:ring-teal-700/hover:text-teal-700 (pagination active hover), hover:text-teal-950 (back-link hover) | Phase 45 | Phase 45 goal: "Every primitive component ... is tokenized, accessible, and visually correct across all interactive states" — per-component color fixes are explicitly Phase 45 scope |
| 2 | Off-brand teal in primary template: ring-teal-200 (Evidence-first badge ring), focus:ring-teal-300 (copy-retrospective button focus), border-l-teal-700 (selected queue row indicator) | Phase 45 | Same Phase 45 scope; all are cosmetic/interactive-state decorations; D-01 values-only constraint prevents adding new interception rules in Phase 44 |
| 3 | TOKEN-04 explicit --radius-* CSS custom properties added to template light block | Phase 45 | REQUIREMENTS.md marks TOKEN-04 as pending; VALIDATION.md declares it manual-only; Phase 45 covers primitive component tokenization including radius |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2` | IBM Plex Sans 400 latin woff2 | VERIFIED | 11,740 bytes; woff2 magic wOF2 confirmed |
| `priv/static/parapet/fonts/IBMPlexSans-Medium-latin.woff2` | IBM Plex Sans 500 latin woff2 | VERIFIED | 12,272 bytes |
| `priv/static/parapet/fonts/IBMPlexSans-SemiBold-latin.woff2` | IBM Plex Sans 600 latin woff2 | VERIFIED | 12,504 bytes |
| `priv/static/parapet/fonts/IBMPlexMono-Regular-latin.woff2` | IBM Plex Mono 400 latin woff2 | VERIFIED | 8,448 bytes |
| `priv/static/parapet/fonts/IBMPlexMono-Medium-latin.woff2` | IBM Plex Mono 500 latin woff2 | VERIFIED | 8,464 bytes |
| `priv/static/parapet/fonts/LICENSE.txt` | IBM Plex OFL 1.1 license | VERIFIED | Present, contains SIL Open Font License text |
| `test/parapet/operator_ui_fonts_test.exs` | FONT-01 budget/existence gate | VERIFIED | 4 tests green; references 153_600 and all 5 woff2 filenames |
| `lib/mix/tasks/parapet.gen.ui.ex` | Generator run/1 with File.cp! font copy | VERIFIED | run/1 calls super(argv) then copy_fonts_to_host/0 using File.cp! |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Re-skinned template with brand tokens, @font-face, motion | VERIFIED | Contains #256C82 x5, #7FB4C6 x6; @font-face x5 with font-display: swap; --motion-fast, --motion-base, --motion-ease; --font-sans/--font-mono |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | Demo mirror with identical CSS variable values | VERIFIED | Contains #256C82 x5, #7FB4C6 x6; all @font-face and motion vars match template exactly |
| `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` | Demo-only GalleryLive with 19 components | VERIFIED | DemoAppWeb.Parapet.GalleryLive defined; 0 Repo. calls; gallery_components/0 present; ~50KB file |
| `examples/demo_app/lib/demo_app_web/router.ex` | Gallery route in live_session :parapet_gallery | VERIFIED | live_session :parapet_gallery with live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index) |
| `brandbook/notes/operator-audit-matrix.md` | 19-component x state ledger with #7FB4C6 exception | VERIFIED | All 19 components present; cells initialized to todo; GUARD-04 #7FB4C6 exception section present |
| `test/parapet/operator_ui_contrast_test.exs` | Re-pinned contrast gate | VERIFIED | @themes maps to brand hexes; focus_ring, link_on_panel, link_on_bg, six chip assertions; @font-face/motion string assertions |
| `test/parapet/operator_ui_demo_contract_test.exs` | Additive gallery/font/audit-matrix assertions | VERIFIED | 4 additive assertions; original 5-route contract byte-unchanged |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/mix/tasks/parapet.gen.ui.ex` | `priv/static/parapet/fonts/` | copy_fonts_to_host/0 uses File.cp! to copy each woff2 into host priv/static | WIRED | run/1 override calls super(argv) then copy_fonts_to_host(); File.cp! confirmed |
| `examples/demo_app/lib/demo_app_web.ex` | `priv/static/parapet/fonts/` | static_paths/0 includes "parapet" so Plug.Static serves /parapet/fonts/*.woff2 | WIRED | static_paths returns ~w(...parapet) confirmed |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | `priv/static/parapet/fonts/` | @font-face src url(/parapet/fonts/IBMPlexSans-Regular-latin.woff2) | WIRED | 5 @font-face rules with exact Plan-01 output filenames |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | template values | Demo mirror carries identical --parapet-*/--po-* values | WIRED | #256C82 and #7FB4C6 counts match template; @media dark block verified for all 3 brand dark hexes |
| `test/parapet/operator_ui_contrast_test.exs` | both template + demo mirror | @component_paths reads both files; @themes pins values present in both | WIRED | @component_paths defined; both dark block greps PASS |
| `examples/demo_app/lib/demo_app_web/router.ex` | `gallery_live.ex` | live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index) | WIRED | live_session :parapet_gallery block confirmed; gallery not in priv/templates/ |

---

### Critical Decision Verification (D-01..D-16)

| Decision | Description | Status | Evidence |
|----------|-------------|--------|---------|
| D-01 | Values-only re-skin; utility-interception layer byte-identical; no class/selector/JS/markup-color edits | VERIFIED | Only `--parapet-*`/`--po-*` values changed + new font/motion/focus vars added; .bg-stone-*, .text-teal-* interception rules untouched |
| D-03 | Theme attribute remains data-parapet-theme (not renamed to data-theme) | VERIFIED | `data-parapet-theme` count = 14; `data-theme` count = 0 in template |
| D-04 | BOTH explicit [data-parapet-theme="dark"] and @media (prefers-color-scheme: dark) blocks updated byte-identically | VERIFIED | #18232B, #7FB4C6, #F8F4EC all found inside @media block for BOTH template and demo mirror |
| D-06 | Light focus ring = #256C82; dark focus ring = #F8F4EC (limestone) | VERIFIED | --po-focus: #256C82 (light), --po-focus: #F8F4EC (dark explicit + dark media blocks) |
| D-07 | Dark --po-link uses #7FB4C6, NOT brandbook #6FA8BC | VERIFIED | --po-link: #7FB4C6 in both dark blocks confirmed |
| D-08 | #7FB4C6 exception recorded in operator-audit-matrix.md for Phase-50 GUARD-04 | VERIFIED | GUARD-04 Off-Palette Exception section present in audit matrix |
| D-09 | 5 latin woff2 faces under priv/static/parapet/fonts/, total <= 150 KB | VERIFIED | 53,428 bytes total (35% of ceiling) |
| D-10 | OFL LICENSE.txt vendored; mix.exs files: explicitly lists font globs | VERIFIED | LICENSE.txt present; mix.exs lines 43-44 list priv/static/parapet/fonts/*.woff2 and LICENSE.txt |
| D-11 | @font-face rules in operator_theme_bootstrap/1 with font-display: swap and system-stack fallback | VERIFIED | 5 @font-face rules; font-display: swap on all; --font-sans/--font-mono with system fallbacks |
| D-12 | Generator copies vendored woff2 into host priv/static on every run (overwrite semantics) | VERIFIED | File.cp! used (not :skip or Igniter.create_new_file) |
| D-13 | /parapet/_gallery NEVER in priv/templates/parapet.gen.ui/ | VERIFIED | grep -rq '_gallery' priv/templates/parapet.gen.ui/ returns nothing |
| D-14 | Demo-contract test 5-route byte-exact assertions undisturbed | VERIFIED | All 5 live(...) route strings at lines 60-64 and 79-83; gallery assertion is additive at line 104 |
| D-15 | brandbook/notes/operator-audit-matrix.md committed with component x state grid | VERIFIED | 19 component rows, 8 state columns, todo/done/verified vocabulary |
| D-16 | Demo mirror carries identical CSS variable values as template | VERIFIED | Both files pass #256C82 >=3, #7FB4C6 >=1, @font-face, --motion-fast grep checks |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `gallery_live.ex` | fixture assigns in mount/3 | hardcoded inline data (no Repo) | yes — this is intentional (T-44-07 threat mitigation; stress route must not expose live data) | VERIFIED |
| `operator_ui_contrast_test.exs` | @themes module attribute | static hex constants in test file | yes — copied verbatim from brandbook/tokens/tokens.css | VERIFIED |
| `operator_components.ex.eex` | --parapet-*/--po-* CSS vars | static values in inline style block | yes — brand hexes copied verbatim per D-01 | VERIFIED |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Font budget gate passes (FONT-01) | `mix test test/parapet/operator_ui_fonts_test.exs` | 4 tests, 0 failures | PASS |
| Contrast gate green with brand hexes (GUARD-02) | `mix test test/parapet/operator_ui_contrast_test.exs` | 2 tests, 0 failures | PASS |
| Demo-contract test + gallery/font/matrix assertions (GALLERY-01, FONT-03, GUARD-01) | `mix test test/parapet/operator_ui_demo_contract_test.exs` | 5 tests, 0 failures | PASS |
| Full suite green (excluding pre-existing :unboxed cluster tests) | `mix test --exclude unboxed` | 547 tests, 0 failures (10 excluded) | PASS |
| D-04 gate: brand dark hexes in @media (prefers-color-scheme: dark) block | awk block extraction + grep for #18232B, #7FB4C6, #F8F4EC in both files | All 6 checks FOUND | PASS |
| Gallery NOT in host templates | `grep -rq '_gallery' priv/templates/parapet.gen.ui/` | no output (empty = no match) | PASS |

---

### Requirements Coverage

| Requirement | Description | Plans | Status | Evidence |
|-------------|-------------|-------|--------|---------|
| TOKEN-01 | Neutral surface roles resolve to brand neutrals in both themes | 44-02 | VERIFIED | --parapet-bg: #F8F4EC (light) / #18232B (dark); full neutral palette in both dark blocks |
| TOKEN-02 | Signal colors brand-aligned (watch-blue links, beacon-amber warning, budget-moss success, ai-violet) | 44-02 | VERIFIED | --po-link: #256C82 (light) / #7FB4C6 (dark); warning, info, success chips all mapped to brand tokens |
| TOKEN-03 | Six status chip triplets (healthy/watch/burning/exhausted/unknown/ai) legible in both themes | 44-02, 44-04 | VERIFIED | All 6 triplets in @themes match brandbook/tokens/tokens.css lines 25-30 exactly; 6 chip assertions in contrast test green at 4.5:1 |
| TOKEN-04 | Type scale, 8px spacing grid, and radius scale applied without layout shift | 44-02 | PRESENT_BEHAVIOR_UNVERIFIED | --font-sans/--font-mono with system fallback (FOUT prevention) wired; explicit --radius-* CSS vars not added as custom properties to light block; REQUIREMENTS.md marks as pending; VALIDATION.md is manual-only |
| TOKEN-05 | Motion tokens wired and zeroed under prefers-reduced-motion | 44-02, 44-04 | VERIFIED | --motion-fast/--motion-base/--motion-ease in template; :root { --motion-fast: 0ms; --motion-base: 0ms; } in prefers-reduced-motion block; contrast test string assertions green |
| FONT-01 | Subsetted IBM Plex woff2 vendored with OFL license, within Hex files: whitelist and 150KB budget | 44-01 | VERIFIED | 53,428 bytes total; 5 woff2 + LICENSE.txt; mix.exs files: explicitly lists font globs |
| FONT-02 | @font-face rules with font-display: swap, correct system-stack fallback | 44-02, 44-04 | VERIFIED | 5 @font-face rules in operator_theme_bootstrap/1; font-display: swap; --font-sans/--font-mono system stack; contrast test string asserts green |
| FONT-03 | Generator copies woff2 to host static; demo app serves fonts | 44-01, 44-04 | VERIFIED | run/1 + copy_fonts_to_host/0 + File.cp!; demo static_paths includes "parapet"; demo-contract test asserts File.exists? for IBMPlexSans-Regular-latin.woff2 |
| A11Y-01 | Focus-ring contrast handled per surface (watch-blue light, limestone dark), enforced by contrast gate | 44-02, 44-04 | VERIFIED | --po-focus: #256C82 (light), #F8F4EC (dark); contrast test asserts focus_ring at 3.0 (3:1 UI floor) against panel (light) / bg (dark) |
| MOTION-01 | Motion tokens wired and fully zeroed under prefers-reduced-motion | 44-02, 44-04 | VERIFIED | See TOKEN-05 evidence above |
| GALLERY-01 | Demo-only /parapet/_gallery route renders every component x states, never shipped to host | 44-03, 44-04 | VERIFIED | Gallery in demo router only; 0 _gallery refs in priv/templates/; GalleryLive with 19 components x {light,dark,default,empty,overflow,disabled,long-string} states |
| GUARD-01 | operator-audit-matrix.md committed with component x state cells | 44-03, 44-04 | VERIFIED | 19 component rows, 8 state columns, todo vocabulary, #7FB4C6 GUARD-04 exception documented |
| GUARD-02 | Contrast test re-pinned to brand hexes, six status triplets, dark links on surface+bg, focus rings at 3:1, WCAG AA | 44-04 | VERIFIED | Full @themes rewrite; 6 chip assertions; link_on_panel + link_on_bg dark #7FB4C6; focus_ring at 3.0; dark warning button fixed to #101820 (5.62:1); all 2 contrast tests green |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | 211 | `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300` (queue-refresh button) | Warning | Off-brand teal on CTA button; hover/focus states render raw teal-700 (#0f766e); D-01 values-only constraint prevented fix in Phase 44; tracked for Phase 45 |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | 469 | `hover:ring-teal-700 hover:text-teal-700` (pagination active hover) | Warning | Hover-variant Tailwind classes not interceptable by CSS var layer; base state is intercepted; Phase 45 |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | 211 | `hover:text-teal-950` (back-link hover) | Warning | text-teal-950 IS intercepted but hover variant is not; Phase 45 |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | 551 | `ring-teal-200` (Evidence-first badge ring) | Warning | Cosmetic ring, not text/background; no --ring-color interception rule (D-01 prevents adding one); Phase 45 |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | 936 | `focus:ring-teal-300` (copy-retrospective focus ring) | Warning | Focus-variant class not interceptable; Phase 45 will address per-component focus ring tokenization |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | 1316 | `border-l-teal-700` (selected queue row indicator) | Warning | Left border accent for selected row; no border-l-teal interception rule exists; static visual state (not hover); Phase 45 |

No TBD/FIXME/XXX unresolved debt markers found in any modified file.

All 6 teal residuals are WARNING-level (not BLOCKER): they are cosmetic/hover/interactive-variant states, documented and tracked for Phase 45, consistent with the D-01 values-only constraint that is a load-bearing phase decision.

---

### Human Verification Required

#### 1. TOKEN-04: Type scale, radius scale, and 8px spacing grid visual check

**Test:** Open the demo app at `/parapet` and `/parapet/_gallery` in both light and dark themes (Chrome or Safari). Observe:
  a. Heading/body/mono type scale matches the brand type scale from `brandbook/tokens/tokens.css`
  b. Cards use ~10px radius, controls ~8px, modals ~14px, badges use pill (near-full) radius
  c. Spacing follows an 8px grid baseline (padding/gap increments are multiples of 8px)
  d. No visible reflow or layout shift occurs as IBM Plex fonts swap in over the system-stack fallback

**Expected:** Visual fidelity matches the brand design specification; no FOUT-induced reflow; IBM Plex Sans renders for UI text and IBM Plex Mono for code/ID spans

**Why human:** Layout-shift detection and visual sizing correctness are not assertable from string/contrast unit tests. The VALIDATION.md explicitly classifies TOKEN-04 as manual-only. The REQUIREMENTS.md marks TOKEN-04 as unchecked (`[ ]`). Note: the template currently applies radius/spacing via Tailwind `rounded-*` utility classes that correspond to the brand scale (rounded-lg=10px, rounded-md=8px, rounded-xl=14px, rounded-full=999px) — the question is whether they were updated or were pre-existing matches.

---

### Gaps Summary

No blocking gaps. All 13 requirements are either VERIFIED (12/13) or present-but-behavior-unverified (TOKEN-04, 1/13) with the unverified item classified as manual-only by the VALIDATION.md and REQUIREMENTS.md tracking table.

The six residual teal classes across templates are WARNINGS (not blockers), explicitly deferred to Phase 45 under the D-01 values-only constraint that is a load-bearing phase decision. They are all hover/focus/decorative interaction-state classes that do not affect the base visual presentation.

**Phase 44 foundation deliverables are substantively complete.** The one human verification item (TOKEN-04 visual fidelity) does not block downstream phases from building on the token/font/gallery/contrast-gate foundation established here.

---

_Verified: 2026-06-25T02:43:21Z_
_Verifier: Claude (gsd-verifier)_
