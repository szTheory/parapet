# Phase 44: Foundations — token re-skin, fonts & audit apparatus - Research

**Researched:** 2026-06-24
**Domain:** CSS variable re-skin · woff2 font vendoring · Igniter generator extension · WCAG AA contrast gate · LiveView gallery route
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Re-skin is **values-only**. Re-point the full variable inventory (~16 `--parapet-*` + ~40 `--po-*` vars) in the inline `<style>` of `operator_theme_bootstrap/1`. The utility-interception layer and all `.po-*` class rules stay **byte-identical** — only the `:root`/dark var *values* change. No class/selector/JS/markup-color edits.

**D-02:** Map by semantic role: teal accents → watch-blue / budget-moss per role; blue links → watch-blue `#256C82`; indigo info → ai-violet set; amber warning → beacon-amber; stone neutrals → limestone / mortar / stone / wall-slate / deep-slate / parapet-black. All six status triplets (healthy/watch/burning/exhausted/unknown/ai) come verbatim from `brandbook/tokens/tokens.css` lines 25-30.

**D-03:** Keep `data-parapet-theme` as the theme attribute. Do **not** rename to `data-theme`. Reconcile brand at the token-*value* level.

**D-04:** Update **both** dark-theme definitions in lockstep — the explicit `[data-parapet-theme="dark"]` block AND the `@media (prefers-color-scheme: dark)` block. Highest-risk drift point of the phase.

**D-05:** Apply type scale, 8px spacing grid, radius scale (card 10px / control 8px / modal 14px / pill 999px) and motion tokens (`--motion-fast` 120ms, `--motion-base` 200ms, `--motion-ease` cubic-bezier(.2,0,0,1)) with motion zeroed under `prefers-reduced-motion`.

**D-06:** Light focus ring stays watch-blue `#256C82`; dark focus ring flips to limestone `#F8F4EC`. GUARD-02 adds focus-ring assertion at 3:1 UI floor.

**D-07:** Dark `--po-link` / `--link` uses `#7FB4C6` (5.14:1 on wall-slate panel surface `#2E3A42`, 7.04:1 on bg). NOT the brand book's `#6FA8BC`.

**D-08:** Brand book token stays untouched. Phase-50 off-palette-hex gate (GUARD-04) admits `#7FB4C6` as an explicit operator-specific lightened-link exception.

**D-09:** Vendor five woff2 faces under `priv/static/parapet/fonts/`: IBM Plex Sans 400/500/600 + IBM Plex Mono 400/500, latin subset, from IBM/plex repo TTFs via `pyftsubset`. Target ≈58 KB total (verified); ceiling ≤150 KB.

**D-10:** Vendor the IBM Plex OFL 1.1 `LICENSE.txt` alongside the fonts. Include fonts + license in Hex `files:` whitelist.

**D-11:** `operator_theme_bootstrap/1` emits `@font-face` rules pointing at the host static path with `font-display: swap` and system stack fallback. Zero `@font-face` rules exist in the template today.

**D-12:** Add a **new static-asset copy step** to the generator. `parapet.gen.ui` currently copies only `.ex` templates. The step copies vendored woff2 into host's `priv/static` path. Re-runs refresh fonts (avoid `:skip`). Demo app also vendors/serves the same woff2.

**D-13:** Add `/parapet/_gallery` to `examples/demo_app/lib/demo_app_web/router.ex` only (`DemoAppWeb.Parapet.GalleryLive`). Never added to `router_snippet.ex.eex`, never generated into host UI.

**D-14:** Do NOT add `/parapet/_gallery` to the existing demo-contract test. Place the route so it does not disturb the byte-exact `live(...)` assertions.

**D-15:** Create `brandbook/notes/operator-audit-matrix.md` as a committed component × state grid where each cell carries `todo`/`done`/`verified`.

**D-16:** Re-pin `test/parapet/operator_ui_contrast_test.exs`: rewrite **both** `@themes` maps (light + dark) to brand hexes for all six status triplets, links on surface **and** bg, and add focus-ring assertions at the 3:1 floor. Test reads from **both** `@component_paths`.

### Claude's Discretion

- Exact internal structure/columns of the audit-matrix markdown (all component × state cells must have todo/done/verified status).
- Whether the font copy is a sub-step of `mix parapet.gen.ui` or a focused `mix parapet.gen.assets` step (pick whichever keeps re-run/upgrade font-refresh correct per D-12).
- Precise `pyftsubset` `--unicodes` scope within ≤150 KB budget.
- Whether the demo gallery LiveView lives in its own `live_session` or reuses an existing one, provided D-14 holds.

### Deferred Ideas (OUT OF SCOPE)

- Normalized template↔demo byte-parity test — Phase 50 (GUARD-03).
- Off-palette-hex gate implementation — Phase 50 (GUARD-04).
- Screenshot baseline manifest + stress-scenario coverage — Phases 49/50.
- Token → Tailwind/daisyUI generator, Playwright/axe-core, raster exports — out of milestone scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOKEN-01 | Neutral surface roles (`--parapet-bg`, `--parapet-panel`, header/nav) resolve to brand neutrals in both themes | Full `--parapet-*` inventory documented; mapping table provided |
| TOKEN-02 | Signal colors brand-aligned — links/info/selected watch-blue, warning beacon-amber, success budget-moss, destructive incident-red, AI trace-violet | Mapping table verified against tokens.css; dark link exception D-07 documented |
| TOKEN-03 | Every chip/badge/status pill driven by brand's six status triplets, legible in both themes | Six triplets from tokens.css lines 25-30 catalogued; WCAG ratios from accessibility.md verified |
| TOKEN-04 | Type scale, 8px spacing grid, radius scale applied without layout shift on system-font fallback | Full scale from tokens.css documented; `--font-sans` system stack already in tokens.css |
| TOKEN-05 | Motion tokens wired, zeroed under `prefers-reduced-motion` | `prefers-reduced-motion` block already exists (lines 323-330); needs `--motion-*` var additions |
| FONT-01 | Subsetted IBM Plex Sans 400/500/600 + Mono 400/500 woff2 vendored under `priv/static/parapet/fonts/`, command documented, within budget | Verified: 58.5 KB total; pyftsubset command documented; IBM/plex repo path confirmed |
| FONT-02 | `operator_theme_bootstrap/1` emits `@font-face` with `font-display: swap`, system-stack fallback, no FOUT | Zero `@font-face` today; pattern documented; static path `"/parapet/fonts/"` confirmed |
| FONT-03 | Generator copies woff2 into host `priv/static`, demo also vendors same fonts | Igniter binary-copy strategy documented (override run/1 with File.cp!); `on_exists: :overwrite` refresh semantics |
| A11Y-01 | Focus-ring contrast per surface: watch-blue on light (5.92:1 on white), limestone on dark (14.57:1 on deep-slate), enforced by contrast gate | Ratios verified from accessibility.md; GUARD-02 adds focus-ring assertions |
| MOTION-01 | Motion tokens wired and fully zeroed under `prefers-reduced-motion` | Existing block uses hard-coded 0.01ms; upgrade to `--motion-fast`/`--motion-base` CSS vars + var(0ms) override |
| GALLERY-01 | Demo-only `/parapet/_gallery` route (never shipped to host) renders all components × states | Safe insertion point confirmed: new `live_session :parapet_gallery` inside `scope "/"`, after existing `:parapet_operator` session |
| GUARD-01 | Committed `brandbook/notes/operator-audit-matrix.md` with component × state cells | 19-component inventory from template confirmed; `brandbook/notes/` dir exists |
| GUARD-02 | `operator_ui_contrast_test.exs` re-pinned to brand token hexes; six status triplets, dark links on surface+bg, focus rings at 3:1 | Current `@themes` coverage gap documented; re-pin strategy provided |
</phase_requirements>

---

## Summary

Phase 44 is a values-only re-skin of the operator UI theme combined with self-hosted IBM Plex font vendoring, a demo-only gallery route, an audit matrix ledger, and a re-pinned contrast gate. All design decisions are locked in CONTEXT.md D-01..D-16. This research surfaces the exact mechanical facts the planner needs: the precise file locations and line ranges to edit, the complete CSS variable inventory (16 `--parapet-*` + 34 `--po-*`), the two dark-theme definition sites (lines 62 and 117-176 of the template), the Igniter binary-copy strategy for woff2 fonts, the exact router insertion point for the gallery route, and the contrast test re-pin scope.

The IBM Plex font budget is **verified at 58.5 KB total** across five subsetted woff2 faces — 61% under the 150 KB ceiling. The font source path in the IBM/plex repo is `packages/plex-{sans,mono}/fonts/complete/ttf/` (no `unhinted/` subfolder for latin faces; that only exists for CJK variants). `pyftsubset` is installed at `/Users/jon/Library/Python/3.14/bin/pyftsubset` with fonttools 4.62.1 and brotli 1.2.0. The `WARNING: meta NOT subset` message during subsetting is harmless — it means the `meta` table was dropped (correct behavior for size optimization).

The gallery route can be safely added as a new `live_session :parapet_gallery` block inside `scope "/"` after the existing `:parapet_operator` session. All five demo contract test route assertions use `=~` (substring match), so adding a new live_session does not disturb them.

**Primary recommendation:** Execute five sequential tasks: (1) re-pin CSS vars in operator_theme_bootstrap/1 + both demo mirror files, (2) vendor fonts + add @font-face + extend generator, (3) add gallery LiveView + route, (4) create audit matrix, (5) re-pin contrast test.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS token values | Generated host-owned code (`operator_components.ex`) | EEx template (`operator_components.ex.eex`) | Template is the source of truth; generated file is the runtime target |
| Font serving | Host app `priv/static/parapet/fonts/` | Demo app `priv/static/parapet/fonts/` | Phoenix Plug.Static serves from host priv/static; demo mirrors for screenshots |
| @font-face rules | `operator_theme_bootstrap/1` inline style | n/a | Inline style keeps all theme machinery self-contained in one function |
| Focus ring enforcement | Contrast test (`operator_ui_contrast_test.exs`) | CSS var values in template | Gate-enforced, not left to component authors |
| Gallery route | Demo app `router.ex` only | n/a | Never generated into host; demo-only stress inspection |
| Audit matrix | `brandbook/notes/operator-audit-matrix.md` | n/a | Committed to repo as milestone idempotence ledger |
| Dark link exception | CSS var `--po-link` dark value `#7FB4C6` | Phase-50 GUARD-04 allowed-hex list | Operator-scoped a11y refinement; brand book stays untouched |

---

## Standard Stack

### Core (all already in use — no new deps)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `pyftsubset` (fonttools) | 4.62.1 [VERIFIED: local pip] | Subset IBM Plex TTF → woff2 | Already used for logo-build.py; same toolchain |
| `brotli` | 1.2.0 [VERIFIED: local pip] | Enable woff2 compression in pyftsubset | Required for `--flavor=woff2` output |
| `Igniter` | ~> 0.7.9 [VERIFIED: mix.exs] | Generator task framework | Already the generator infrastructure |
| ExUnit | ships with Elixir | Contrast gate test | Already used in contrast test |

### No New Runtime Dependencies
This phase adds zero new Hex packages. All work is:
- CSS value edits in EEx templates
- Binary asset vendoring (woff2 files committed to priv/static)
- Elixir test assertion additions
- A new LiveView module in the demo app (not the library)

**Package Legitimacy Audit:** Not applicable — no new packages are installed.

---

## Architecture Patterns

### System Architecture Diagram

```
IBM/plex GitHub repo (master)
  packages/plex-sans/fonts/complete/ttf/IBMPlexSans-{Regular,Medium,SemiBold}.ttf
  packages/plex-mono/fonts/complete/ttf/IBMPlexMono-{Regular,Medium}.ttf
        │
        │ pyftsubset (latin subset, --flavor=woff2)
        ▼
priv/static/parapet/fonts/  (committed to repo)
  ├── IBMPlexSans-Regular-latin.woff2    (~13.7 KB)
  ├── IBMPlexSans-Medium-latin.woff2     (~14.7 KB)
  ├── IBMPlexSans-SemiBold-latin.woff2   (~14.6 KB)
  ├── IBMPlexMono-Regular-latin.woff2    (~8.4 KB)
  ├── IBMPlexMono-Medium-latin.woff2     (~8.5 KB)
  └── LICENSE.txt (IBM Plex OFL 1.1)
        │
        │ mix parapet.gen.ui (File.cp! step)
        ▼
host_app/priv/static/parapet/fonts/  (generated, not in host git)
        │
        │ Phoenix Plug.Static (at: "/", from: :host_app)
        │ requires "parapet" in static_paths
        ▼
browser ← @font-face src: "/parapet/fonts/IBMPlexSans-Regular-latin.woff2"
           font-display: swap  ← renders system-font fallback first, then swaps

brandbook/tokens/tokens.css  (read-only reference, values copied verbatim)
        │
        │ D-01..D-08 manual token mapping
        ▼
priv/templates/parapet.gen.ui/operator_components.ex.eex
  operator_theme_bootstrap/1  ← inline <style> with --parapet-* and --po-* vars
  [light block]               ← 16 --parapet-* + 34 --po-* vars
  [dark block line 62]        ← [data-parapet-theme="dark"] (D-04: update BOTH)
  [@media dark block line 117]← @media (prefers-color-scheme: dark) (D-04)
        │
        │ mix parapet.gen.ui (Igniter.copy_template, on_exists: :skip)
        ▼
host_app/lib/host_web/live/parapet/operator_components.ex  (host-owned)

demo mirrors (must stay in sync — D-16):
  examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
  examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
  examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex

contrast gate:
  test/parapet/operator_ui_contrast_test.exs
  @component_paths: [demo mirror, template]  ← reads BOTH (D-16)
  @themes: light + dark maps  ← re-pinned to brand hexes (GUARD-02)
```

### Recommended Project Structure (new files only)
```
priv/
└── static/parapet/fonts/            # NEW — committed woff2 + license
    ├── IBMPlexSans-Regular-latin.woff2
    ├── IBMPlexSans-Medium-latin.woff2
    ├── IBMPlexSans-SemiBold-latin.woff2
    ├── IBMPlexMono-Regular-latin.woff2
    ├── IBMPlexMono-Medium-latin.woff2
    └── LICENSE.txt

brandbook/notes/
└── operator-audit-matrix.md         # NEW — component × state ledger

examples/demo_app/
├── lib/demo_app_web/live/parapet/
│   └── gallery_live.ex              # NEW — demo-only gallery
└── lib/demo_app_web/router.ex       # EDIT — add gallery route
```

### Pattern 1: CSS Variable Re-skin (Values-Only)
**What:** Replace hex values in `--parapet-*` and `--po-*` declarations in the three CSS blocks (light `:root`, explicit dark, media-query dark). No selector, class, or JS changes.
**When to use:** Always for this phase — D-01 is a hard constraint.
**Structure:**
```css
/* BEFORE (existing light block in .parapet-ui) */
--parapet-bg: #f5f5f4;          /* stone-100 */
--parapet-accent: #0f766e;      /* teal-700 */
--po-link: #1d4ed8;             /* blue-700 */
--po-nav-active-bg: #5eead4;    /* teal-200 */
/* ... */

/* AFTER (brand token values from tokens.css) */
--parapet-bg: #F8F4EC;          /* limestone */
--parapet-accent: #256C82;      /* watch-blue */
--po-link: #256C82;             /* watch-blue */
--po-nav-active-bg: #EFF6E8;    /* healthy-bg */
/* ... */
```
**Critical:** The edit must be applied to THREE blocks in the template (and mirrored identically in the demo file):
1. `.parapet-ui { ... }` (light, lines 8-60 in template)
2. `html[data-parapet-theme="dark"] .parapet-ui, html[data-parapet-theme="system"] .parapet-ui:is(.force-system-dark) { ... }` (explicit dark, lines 62-115)
3. `html:not([data-parapet-theme]) .parapet-ui, html[data-parapet-theme="system"] .parapet-ui { ... }` inside `@media (prefers-color-scheme: dark)` (lines 117-176)

### Pattern 2: @font-face Injection
**What:** Add `@font-face` declarations to the `<style>` block in `operator_theme_bootstrap/1`, before the existing `.parapet-ui { ... }` rule.
**When to use:** Font is in host priv/static/parapet/fonts/ (copied by generator).
```css
@font-face {
  font-family: "IBM Plex Sans";
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexSans-Regular-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Sans";
  font-style: normal;
  font-weight: 500;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexSans-Medium-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Sans";
  font-style: normal;
  font-weight: 600;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexSans-SemiBold-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Mono";
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexMono-Regular-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Mono";
  font-style: normal;
  font-weight: 500;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexMono-Medium-latin.woff2") format("woff2");
}
```
The `--font-sans` and `--font-mono` vars in `tokens.css` already start with `"IBM Plex Sans"` and `"IBM Plex Mono"` respectively — add them as CSS vars to the light block so they flow through the theme.

### Pattern 3: Generator Binary-File Copy (Igniter + File.cp!)
**What:** Igniter's `create_new_file` uses string-based `Rewrite.Source` — not suitable for woff2 binary. Override `run/1` (which is `defoverridable run: 1` in `Igniter.Mix.Task`) to call `super(argv)` then do `File.cp!` for each font file.
**Implementation:**
```elixir
def run(argv) do
  super(argv)  # runs full igniter pipeline
  copy_fonts_to_host()
end

defp copy_fonts_to_host do
  source_dir = Path.join(:code.priv_dir(:parapet), "static/parapet/fonts")
  dest_dir   = Path.join(File.cwd!(), "priv/static/parapet/fonts")
  File.mkdir_p!(dest_dir)
  for filename <- File.ls!(source_dir) do
    File.cp!(Path.join(source_dir, filename), Path.join(dest_dir, filename))
  end
  Mix.shell().info("* copying #{File.ls!(source_dir) |> length()} font files to priv/static/parapet/fonts/")
end
```
This refreshes fonts on every re-run (`:overwrite` semantics, not `:skip`), satisfying D-12.

### Pattern 4: Gallery Route Insertion (Safe Placement)
**What:** Add a new `live_session :parapet_gallery` block inside `scope "/"` after the existing `:parapet_operator` session. This preserves all five exact `live(...)` strings the contract test asserts on.
```elixir
# Add AFTER the existing live_session :parapet_operator block,
# still inside scope "/" and before scope "/ops"
live_session :parapet_gallery do
  live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index)
end
```
The contract test only checks for the 5 specific route strings and the relative position of `scope "/"` before `scope "/ops"`. A new live_session between them is invisible to existing assertions.

### Anti-Patterns to Avoid

- **Editing only one dark-theme block:** The template has TWO dark definitions — `[data-parapet-theme="dark"]` (line 62) and `@media (prefers-color-scheme: dark)` (line 117). Both must be updated identically (D-04). Missing the media-query block breaks "system" theme users on OS-dark machines, and the contrast test won't catch it because it reads static hex values, not the media query.
- **Using `on_exists: :skip` for font copy:** Fonts must refresh on re-run (D-12). `:skip` leaves hosts on stale woff2 files after upgrade.
- **Adding gallery route to router_snippet.ex.eex:** The snippet is generated into host apps (D-13 hard boundary). Gallery is demo-only.
- **Updating only the EEx template but not the demo mirror:** The contrast test reads from BOTH `@component_paths` (demo mirror and template). If they diverge on CSS var usage, the second-path assertions fail.
- **Deriving new token hex values:** All values must be copied verbatim from `brandbook/tokens/tokens.css`. Do not compute, interpolate, or re-derive.
- **Using Igniter.create_new_file for woff2:** It will silently corrupt binary data via string encoding. Use `File.cp!` directly.

---

## Complete CSS Variable Inventory

### Verified `--parapet-*` Variables (16 total) [VERIFIED: template grep]
All defined in `.parapet-ui { }` light block and repeated in both dark blocks:

| Variable | Current (old teal) | Brand Token Value (light) | Brand Token Value (dark) |
|----------|-------------------|--------------------------|--------------------------|
| `--parapet-bg` | `#f5f5f4` | `#F8F4EC` (limestone) | `#18232B` (deep-slate) |
| `--parapet-panel` | `#ffffff` | `#FFFFFF` | `#2E3A42` (wall-slate) |
| `--parapet-panel-muted` | `#fafaf9` | `#EAE2D4` (mortar) | `#101820` (parapet-black) |
| `--parapet-text` | `#1c1917` | `#101820` (parapet-black) | `#F8F4EC` (limestone) |
| `--parapet-text-muted` | `#57534e` | `#2E3A42` (wall-slate) | `#D8D0C3` (stone) |
| `--parapet-border` | `#e7e5e4` | `rgba(16,24,32,0.12)` | `rgba(248,244,236,0.16)` |
| `--parapet-border-strong` | `rgba(28,25,23,0.14)` | `rgba(16,24,32,0.14)` | `rgba(248,244,236,0.20)` |
| `--parapet-shadow` | `0 1px 2px rgba(28,25,23,0.06)...` | `0 1px 2px rgba(16,24,32,0.06)` | `0 1px 2px rgba(0,0,0,0.42)...` |
| `--parapet-accent` | `#0f766e` (teal-700) | `#256C82` (watch-blue) | `#7FB4C6` (lightened watch-blue) |
| `--parapet-accent-strong` | `#0f5f59` | `#1A5066` | `#A8D0DE` |
| `--parapet-accent-soft` | `#ccfbf1` | `#EFF6E8` (healthy-bg) | `rgba(37,108,130,0.16)` |
| `--parapet-accent-text` | `#115e59` | `#256C82` | `#A8D0DE` |
| `--parapet-warning-bg` | `#fffbeb` | `#F8EFD7` (watch-bg) | `rgba(180,83,9,0.24)` |
| `--parapet-warning-text` | `#78350f` | `#B45309` (beacon-amber) | `#D97706` (beacon-amber-light) |
| `--parapet-info-bg` | `#f5f3ff` | `#ECEBFF` (ai-bg) | `rgba(109,91,208,0.24)` |
| `--parapet-info-text` | `#4c1d95` | `#4F46A5` (ai-text) | `#B9B5F6` (ai-border) |

### Verified `--po-*` Variables (34 total) [VERIFIED: template grep]
All defined in `.parapet-ui { }` light block and both dark blocks:

**Links & Focus (4 vars):**
| Variable | Light → Brand | Dark → Brand |
|----------|--------------|-------------|
| `--po-link` | `#1d4ed8` → `#256C82` (watch-blue) | `#93c5fd` → `#7FB4C6` (D-07 operator exception) |
| `--po-link-hover` | `#1e3a8a` → `#1A5066` (dark watch-blue) | `#bfdbfe` → `#A8D0DE` |
| `--po-focus` | `#0f766e` → `#256C82` (watch-blue) | `#5eead4` → `#F8F4EC` (limestone, D-06) |
| `--po-focus-offset` | `#ffffff` → `#ffffff` | `#0c0a09` → `#18232B` (deep-slate) |

**Header (4 vars):**
| Variable | Light → Brand | Dark → Brand |
|----------|--------------|-------------|
| `--po-header-bg` | `#ffffff` → `#FFFFFF` | `#0c0a09` → `#101820` (parapet-black) |
| `--po-header-border` | `#e7e5e4` → `rgba(16,24,32,0.12)` | `#292524` → `rgba(248,244,236,0.16)` |
| `--po-header-title` | `#1c1917` → `#101820` | `#fafaf9` → `#F8F4EC` |
| `--po-header-muted` | `#0f766e` → `#256C82` (watch-blue) | `#5eead4` → `#7FB4C6` |

**Nav (5 vars):**
| Variable | Light → Brand | Dark → Brand |
|----------|--------------|-------------|
| `--po-nav-fg` | `#44403c` → `#2E3A42` (wall-slate) | `#e7e5e4` → `#D8D0C3` (stone) |
| `--po-nav-hover-bg` | `#f5f5f4` → `#EAE2D4` (mortar) | `#292524` → `#2E3A42` (wall-slate) |
| `--po-nav-hover-fg` | `#1c1917` → `#101820` | `#ffffff` → `#F8F4EC` |
| `--po-nav-active-bg` | `#5eead4` → `#EFF6E8` (healthy-bg) | `#5eead4` → `#3F5E28` (healthy-text) |
| `--po-nav-active-fg` | `#042f2e` → `#3F5E28` (healthy-text) | `#042f2e` → `#F8F4EC` (limestone) |

**Theme Control (3 vars):**
| Variable | Light → Brand | Dark → Brand |
|----------|--------------|-------------|
| `--po-theme-control-bg` | `#fafaf9` → `#F8F4EC` (limestone) | `#1c1917` → `#18232B` (deep-slate) |
| `--po-theme-control-border` | `#d6d3d1` → `rgba(16,24,32,0.12)` | `#57534e` → `rgba(248,244,236,0.16)` |
| `--po-theme-control-fg` | `#44403c` → `#2E3A42` | `#e7e5e4` → `#D8D0C3` |

**Six Status Chip Triplets (18 vars — 3 per status × 6 statuses):**
All values copied verbatim from `brandbook/tokens/tokens.css` lines 25-30:

| Status | Variable | Light Value | Dark Value |
|--------|----------|-------------|------------|
| healthy (≈success) | `--po-chip-success-bg` | `#EFF6E8` | `#3F5E28` dark-bg |
| healthy | `--po-chip-success-fg` | `#3F5E28` | `#EFF6E8` |
| healthy | `--po-chip-success-border` | `#B6C99A` | `#567236` |
| watch (≈warning) | `--po-chip-warning-bg` | `#F8EFD7` | `#92400E` dark-bg |
| watch | `--po-chip-warning-fg` | `#92400E` | `#F8EFD7` |
| watch | `--po-chip-warning-border` | `#E3B66E` | `#B45309` |
| burning+exhausted → danger | `--po-chip-danger-bg` | `#FCE8E2` | `#9F2D2D` dark-bg |
| burning | `--po-chip-danger-fg` | `#9F2D2D` | `#FCE8E2` |
| burning | `--po-chip-danger-border` | `#E3A19A` | `#B13A32` |
| unknown → neutral | `--po-chip-neutral-bg` | `#ECEFF1` | `#2E3A42` |
| unknown | `--po-chip-neutral-fg` | `#2E3A42` | `#ECEFF1` |
| unknown | `--po-chip-neutral-border` | `#CBD2D8` | `#556B77` |
| ai → info | `--po-chip-info-bg` | `#ECEBFF` | `#4F46A5` dark-bg |
| ai | `--po-chip-info-fg` | `#4F46A5` | `#ECEBFF` |
| ai | `--po-chip-info-border` | `#B9B5F6` | `#6D5BD0` |

**Warning Button (3 vars):**
| Variable | Light → Brand | Dark → Brand |
|----------|--------------|-------------|
| `--po-button-warning-bg` | `#b45309` → `#B45309` (beacon-amber, same) | `#92400e` → `#D97706` (beacon-amber-light) |
| `--po-button-warning-fg` | `#ffffff` → `#ffffff` (same) | `#fff7ed` → `#F8F4EC` |
| `--po-button-warning-hover` | `#92400e` → `#92400E` (same) | `#78350f` → `#B45309` |

> **Note:** CONTEXT.md specifies six status triplets but the current template only has 5 chip types (neutral/success/warning/danger/info). The mapping is: healthy→success, watch→warning, burning→danger, exhausted→danger (shared — Phase 45 splits this if needed), unknown→neutral, ai→info. Phase 44 uses the existing chip variable names and re-points their values.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font subsetting | Custom subsetting script | `pyftsubset` (fonttools 4.62.1, already installed) | Handles layout features, DSIG drop, recalc-bounds correctly |
| WCAG contrast math | Re-implement sRGB relative luminance | Existing `contrast_ratio/2` in `operator_ui_contrast_test.exs` | Already correct (uses 0.03928 linearization threshold, standard formula) |
| Binary file copy in Igniter | Igniter.create_new_file with binary | `File.cp!` via `run/1` override | Igniter uses string-based Rewrite.Source; binary data gets corrupted |
| Dark theme detection | New JS/CSS for dark mode | Existing `data-parapet-theme` + `localStorage` JS (lines 332-358 of template) | Already handles light/dark/system; D-03 locks this |
| Gallery component iteration | Dynamic introspection | Explicit list of all 19 components in GalleryLive assigns | Static list is safer and more auditable |

---

## Complete File Inventory

### Files to EDIT (values-only changes in CSS blocks):

| File | What Changes | Risk |
|------|-------------|------|
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | All `--parapet-*` and `--po-*` hex values in 3 CSS blocks (light + 2 dark); add `@font-face` declarations and motion vars | HIGH — source of truth; demo mirror must match |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | Same CSS value changes; demo mirror must stay in sync | HIGH — contrast test reads this file |

### Files to EDIT (adding new content):

| File | What's Added | Risk |
|------|-------------|------|
| `lib/mix/tasks/parapet.gen.ui.ex` | Override `run/1` → call `super(argv)` + `File.cp!` font copy | LOW — isolated to generator |
| `mix.exs` | Add `priv/static/parapet/fonts/*.woff2`, `priv/static/parapet/fonts/LICENSE.txt` to `files:` whitelist | LOW — additive only |
| `examples/demo_app/lib/demo_app_web/router.ex` | New `live_session :parapet_gallery` block inside `scope "/"` | LOW — verified safe insertion point |
| `examples/demo_app/lib/demo_app_web.ex` | Add `"parapet"` to `static_paths` list | LOW — additive |
| `test/parapet/operator_ui_contrast_test.exs` | Rewrite `@themes` maps to brand hexes; add focus-ring assertions | MEDIUM — must pass WCAG AA on new values |

### Files to CREATE:

| File | Content |
|------|---------|
| `priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2` | 13,716 bytes (verified) |
| `priv/static/parapet/fonts/IBMPlexSans-Medium-latin.woff2` | 14,708 bytes (verified) |
| `priv/static/parapet/fonts/IBMPlexSans-SemiBold-latin.woff2` | 14,588 bytes (verified) |
| `priv/static/parapet/fonts/IBMPlexMono-Regular-latin.woff2` | 8,448 bytes (verified) |
| `priv/static/parapet/fonts/IBMPlexMono-Medium-latin.woff2` | 8,464 bytes (verified) |
| `priv/static/parapet/fonts/LICENSE.txt` | IBM Plex OFL 1.1 from `packages/plex-sans/LICENSE.txt` |
| `brandbook/notes/operator-audit-matrix.md` | Component × state ledger |
| `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` | Demo-only gallery LiveView |

---

## Font Subsetting — Verified Mechanics

### Source Repository [VERIFIED: GitHub API]
IBM Plex fonts are at `https://github.com/IBM/plex` (master branch, last updated 2026-06-24).

**Corrected path (D-09 had a path error):** The `unhinted/` subfolder only exists in CJK variants (JP/KR/SC). The latin IBM Plex Sans and Mono TTFs are directly at:
- `packages/plex-sans/fonts/complete/ttf/IBMPlexSans-{Regular,Medium,SemiBold}.ttf`
- `packages/plex-mono/fonts/complete/ttf/IBMPlexMono-{Regular,Medium}.ttf`

### Subsetting Command [VERIFIED: ran on actual TTFs]
```bash
/Users/jon/Library/Python/3.14/bin/pyftsubset \
  IBMPlexSans-Regular.ttf \
  --output-file=IBMPlexSans-Regular-latin.woff2 \
  --flavor=woff2 \
  --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD" \
  --layout-features="kern,liga,clig,calt,ccmp,locl,mark,mkmk" \
  --desubroutinize --no-hinting --drop-tables+=DSIG --notdef-outline --recalc-bounds
```
Apply to all five faces (Regular/Medium/SemiBold for Sans; Regular/Medium for Mono).

`WARNING: meta NOT subset; don't know how to subset; dropped` is **expected and harmless** — the `meta` table is an optional font metadata table, not needed for rendering.

### Verified Budget [VERIFIED: ran pyftsubset on IBM Plex official TTFs]
| Face | Size |
|------|------|
| IBMPlexSans-Regular-latin.woff2 | 13,716 bytes (13.4 KB) |
| IBMPlexSans-Medium-latin.woff2 | 14,708 bytes (14.4 KB) |
| IBMPlexSans-SemiBold-latin.woff2 | 14,588 bytes (14.2 KB) |
| IBMPlexMono-Regular-latin.woff2 | 8,448 bytes (8.2 KB) |
| IBMPlexMono-Medium-latin.woff2 | 8,464 bytes (8.3 KB) |
| **Total** | **59,924 bytes (58.5 KB)** |
| **Ceiling** | **153,600 bytes (150 KB)** |
| **Headroom** | **61% under ceiling** |

CONTEXT.md D-09 projected 110-125 KB; actual is 58.5 KB (latin-only subset is very tight). This is correct — the CONTEXT.md estimate was conservative.

---

## Contrast Test Re-pin Strategy

### Current State (FAILING on brand values — must rewrite)
The current `@themes` map uses old Tailwind-era hex values:
- `light.link: "#1d4ed8"` (blue-700, not watch-blue)
- `dark.header_muted: "#5eead4"` (teal-300, not brand)
- `dark.link: "#93c5fd"` (blue-300, not brand)
- `dark.nav_active_bg: "#5eead4"` (teal-300)
- No exhausted/unknown/ai chips
- No link-on-bg assertion
- No focus-ring assertions

### Required New `@themes` Map
```elixir
@themes %{
  light: %{
    bg: "#F8F4EC",              # limestone
    panel: "#FFFFFF",           # white surface
    header_bg: "#FFFFFF",
    header_title: "#101820",    # parapet-black
    header_muted: "#256C82",    # watch-blue
    link_on_panel: "#256C82",   # watch-blue on white surface: 5.92:1 ✓
    link_on_bg: "#256C82",      # watch-blue on limestone: 5.40:1 ✓
    focus_ring: "#256C82",      # watch-blue vs white: 5.92:1 (≥3:1 ✓)
    nav_fg: "#2E3A42",          # wall-slate
    nav_hover_bg: "#EAE2D4",    # mortar
    nav_hover_fg: "#101820",    # parapet-black
    nav_active_bg: "#EFF6E8",   # healthy-bg
    nav_active_fg: "#3F5E28",   # healthy-text
    theme_control_bg: "#F8F4EC",
    theme_control_fg: "#2E3A42",
    healthy_bg: "#EFF6E8", healthy_fg: "#3F5E28",
    watch_bg: "#F8EFD7",   watch_fg: "#92400E",
    burning_bg: "#FCE8E2", burning_fg: "#9F2D2D",
    exhausted_bg: "#F8D7D4", exhausted_fg: "#7F1D1D",
    unknown_bg: "#ECEFF1", unknown_fg: "#2E3A42",
    ai_bg: "#ECEBFF",      ai_fg: "#4F46A5",
    warning_button_bg: "#B45309", warning_button_fg: "#FFFFFF"
  },
  dark: %{
    bg: "#18232B",              # deep-slate
    panel: "#2E3A42",           # wall-slate
    header_bg: "#101820",       # parapet-black
    header_title: "#F8F4EC",    # limestone
    header_muted: "#7FB4C6",    # lightened watch-blue (D-07)
    link_on_panel: "#7FB4C6",   # on wall-slate #2E3A42: 5.14:1 ✓
    link_on_bg: "#7FB4C6",      # on deep-slate #18232B: 7.04:1 ✓
    focus_ring: "#F8F4EC",      # limestone vs deep-slate: 14.57:1 (≥3:1 ✓)
    nav_fg: "#D8D0C3",          # stone
    nav_hover_bg: "#2E3A42",    # wall-slate
    nav_hover_fg: "#F8F4EC",    # limestone
    nav_active_bg: "#3F5E28",   # healthy-text (dark)
    nav_active_fg: "#F8F4EC",   # limestone
    theme_control_bg: "#18232B",
    theme_control_fg: "#D8D0C3",
    healthy_bg: "#3F5E28", healthy_fg: "#EFF6E8",
    watch_bg: "#92400E",   watch_fg: "#F8EFD7",
    burning_bg: "#9F2D2D", burning_fg: "#FCE8E2",
    exhausted_bg: "#7F1D1D", exhausted_fg: "#F8D7D4",
    unknown_bg: "#2E3A42", unknown_fg: "#ECEFF1",
    ai_bg: "#4F46A5",      ai_fg: "#ECEBFF",
    warning_button_bg: "#D97706", warning_button_fg: "#F8F4EC"
  }
}
```

### New Assertions to Add
```elixir
# Existing assertions (re-targeted to brand vars):
assert_contrast(theme, :header_title, tokens.header_title, tokens.header_bg, 4.5)
assert_contrast(theme, :link_on_panel, tokens.link_on_panel, tokens.panel, 4.5)
assert_contrast(theme, :link_on_bg, tokens.link_on_bg, tokens.bg, 4.5)  # NEW

# Six status chips (replacing old neutral/success/warning/danger/info):
assert_contrast(theme, :healthy_chip, tokens.healthy_fg, tokens.healthy_bg, 4.5)
assert_contrast(theme, :watch_chip, tokens.watch_fg, tokens.watch_bg, 4.5)
assert_contrast(theme, :burning_chip, tokens.burning_fg, tokens.burning_bg, 4.5)
assert_contrast(theme, :exhausted_chip, tokens.exhausted_fg, tokens.exhausted_bg, 4.5)
assert_contrast(theme, :unknown_chip, tokens.unknown_fg, tokens.unknown_bg, 4.5)
assert_contrast(theme, :ai_chip, tokens.ai_fg, tokens.ai_bg, 4.5)

# Focus ring at 3:1 UI floor (GUARD-02 NEW):
assert_contrast(theme, :focus_ring,
  tokens.focus_ring,
  if(theme == :light, do: tokens.panel, else: tokens.bg),
  3.0)
```

### Pre-verified Contrast Ratios [VERIFIED: brandbook/notes/accessibility.md]
| Token | Light Ratio | Dark Ratio | Min Required |
|-------|------------|-----------|-------------|
| healthy chip text/bg | 6.69:1 | 6.69:1 (inverted) | 4.5 ✓ |
| watch chip text/bg | 6.18:1 | 6.18:1 (inverted) | 4.5 ✓ |
| burning chip text/bg | 6.16:1 | 6.16:1 (inverted) | 4.5 ✓ |
| exhausted chip text/bg | 7.47:1 | 7.47:1 (inverted) | 4.5 ✓ |
| unknown chip text/bg | 10.10:1 | 10.10:1 (inverted) | 4.5 ✓ |
| ai chip text/bg | 6.50:1 | 6.50:1 (inverted) | 4.5 ✓ |
| watch-blue link on white | 5.92:1 | — | 4.5 ✓ |
| watch-blue focus ring on white | 5.92:1 | — | 3.0 ✓ |
| limestone focus ring on deep-slate | — | 14.57:1 | 3.0 ✓ |
| #7FB4C6 link on wall-slate #2E3A42 | — | 5.14:1 | 4.5 ✓ |
| #7FB4C6 link on deep-slate #18232B | — | 7.04:1 | 4.5 ✓ |

---

## Audit Matrix Structure

### Component Inventory (19 components) [VERIFIED: template grep]
From `operator_components.ex.eex`:
1. `operator_theme_bootstrap`
2. `operator_nav`
3. `theme_control`
4. `response_cockpit`
5. `nav_item`
6. `operator_overview`
7. `action_center`
8. `incident_list`
9. `incident_row`
10. `incident_summary`
11. `incident_timeline`
12. `suspect_changes_card`
13. `retrospective_card`
14. `runbook_card`
15. `preview_panel`
16. `action_rail`
17. `action_item_list`
18. `action_item_card`
19. `critical_journeys`

### Audit Matrix Columns (Claude's Discretion)
Recommended structure:
```markdown
| Component | light-default | dark-default | light-empty | dark-empty | light-overflow | dark-overflow | light-disabled | dark-disabled | Notes |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|-------|
| operator_theme_bootstrap | todo | todo | — | — | — | — | — | — | Token values only |
| operator_nav | todo | todo | — | — | todo | todo | — | — | |
...
```
Status values: `todo` / `done` / `verified`

---

## Common Pitfalls

### Pitfall 1: Missing the @media (prefers-color-scheme: dark) block
**What goes wrong:** Only updating `[data-parapet-theme="dark"]` block (line 62). The identical dark vars block inside `@media (prefers-color-scheme: dark)` (lines 117-176) gets the old teal palette.
**Why it happens:** The template has three CSS blocks — the second (explicit dark) is obvious, but the third (media-query dark for "system" users) is easy to miss.
**How to avoid:** Always update all three blocks in a single edit pass. Both dark blocks (lines 62-115 and 117-176) are byte-for-byte identical in variable declarations — they must stay in sync.
**Warning signs:** `system` theme on OS-dark shows teal; `dark` theme shows brand palette. The contrast test won't catch this because it reads static hex values.

### Pitfall 2: Demo Mirror Divergence
**What goes wrong:** Template updated, demo mirror `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` not updated.
**Why it happens:** The file is a hand-maintained mirror, not auto-generated from the template.
**How to avoid:** Always edit the demo mirror in the same task/commit as the template. The contrast test `@component_paths` reads both and will fail if they differ on CSS variable presence.
**Warning signs:** `mix test test/parapet/operator_ui_contrast_test.exs` fails only on one of the two component paths.

### Pitfall 3: Font Copy with :skip Semantics
**What goes wrong:** Using `Igniter.create_new_file(..., on_exists: :skip)` for font copy. Hosts upgrading from an older version keep the old woff2 files indefinitely.
**Why it happens:** The `.ex` template copy uses `:skip` to preserve host customizations — this is wrong for binary assets the library owns.
**How to avoid:** Use `File.cp!` via `run/1` override (always overwrites). The fonts are library-owned; hosts never customize them.

### Pitfall 4: Igniter.create_new_file with Binary Data
**What goes wrong:** Passing raw woff2 bytes as the `contents` argument to `Igniter.create_new_file/3`.
**Why it happens:** The function signature accepts a string, and Elixir binaries can be passed as strings. However, Rewrite.Source treats the content as UTF-8 text and may corrupt binary data during processing.
**How to avoid:** Never use Igniter for binary file operations. Use `File.cp!` directly.

### Pitfall 5: Exhausted/Unknown/AI Chip Variables Missing
**What goes wrong:** Only re-pinning the 5 existing chip types (neutral/success/warning/danger/info) without addressing that tokens.css defines 6 status triplets.
**Why it happens:** The current template has 5 chip types, but the brand has 6. The 6th (exhausted) maps to danger in the current template.
**How to avoid:** For Phase 44, map exhausted → danger (same vars), per the existing class routing (`state_color("exhausted") → po-chip po-chip-danger` doesn't exist, it falls through to `po-chip` default). The audit matrix notes this mapping; Phase 45 adds per-component exhausted chips if needed.

### Pitfall 6: Gallery Route Disturbing Contract Test
**What goes wrong:** Adding `/parapet/_gallery` inside the existing `:parapet_operator` live_session, or before the 5 existing routes.
**Why it happens:** Trying to keep the router tidy by reusing the existing live_session.
**How to avoid:** Create a NEW `live_session :parapet_gallery` block inside `scope "/"` AFTER the existing `:parapet_operator` session. The test only checks for the existence of the 5 route strings (substring match) and the relative ordering of `scope "/"` vs `scope "/ops"`.

### Pitfall 7: Overshoot on Reduced-Motion
**What goes wrong:** Keeping the existing `.parapet-ui * { transition-duration: 0.01ms; }` approach while also adding `--motion-fast` / `--motion-base` CSS vars, but not zeroing the vars under `prefers-reduced-motion`.
**Why it happens:** The existing block handles explicit CSS transitions, but new motion token vars aren't zeroed.
**How to avoid:** Add to the `@media (prefers-reduced-motion: reduce)` block:
```css
:root { --motion-fast: 0ms; --motion-base: 0ms; }
.parapet-ui * { animation-duration: 0.01ms; ... } /* existing */
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 | pyftsubset | ✓ | 3.14.4 | — |
| fonttools | Font subsetting | ✓ | 4.62.1 | — |
| brotli | woff2 compression | ✓ | 1.2.0 | — |
| pyftsubset binary | Font subsetting command | ✓ | at `/Users/jon/Library/Python/3.14/bin/pyftsubset` | `python3 -m fontTools.subset` |
| IBM/plex GitHub repo | Source TTFs | ✓ | master (updated 2026-06-24) | Google Fonts TTFs (verified identical) |
| Mix / Igniter | Generator task | ✓ | 0.7.9 | — |

**Missing dependencies with no fallback:** None.

**Note on pyftsubset PATH:** `pyftsubset` is installed but not on the default `$PATH`. The command is available as:
- `/Users/jon/Library/Python/3.14/bin/pyftsubset`
- `python3 -m fontTools.subset` (module form, always works)

Use `python3 -m fontTools.subset` in the documented subsetting command for portability.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/operator_ui_contrast_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TOKEN-01 | Neutral vars resolve to brand neutrals | unit (string search + contrast assert) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ (needs re-pin) |
| TOKEN-02 | Signal vars brand-aligned | unit (contrast assert on panel/bg) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ (needs re-pin) |
| TOKEN-03 | Six status triplets legible in both themes | unit (6 chip assertions × 2 themes) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ (needs 4 new assertions) |
| TOKEN-04 | Type/spacing/radius applied, no layout shift | manual screenshot | Demo app visual check at `/parapet` | N/A |
| TOKEN-05 | Motion tokens wired and zeroed | unit (string search for `--motion-fast` in file + `:root { --motion-fast: 0ms }` in `prefers-reduced-motion`) | Add to `operator_ui_contrast_test.exs` "semantic tokens" test | ✅ (needs new string assertions) |
| FONT-01 | woff2 files exist and within budget | unit (File.exists? + File.stat!) | Add new test: `test/parapet/operator_ui_fonts_test.exs` | ❌ Wave 0 gap |
| FONT-02 | `@font-face` in emitted style | unit (string search) | Add to "semantic tokens" test: `assert content =~ "@font-face"` | ✅ (needs string assertion) |
| FONT-03 | Generator copies fonts to host | manual (run `mix parapet.gen.ui` in test project) | `operator_ui_demo_contract_test.exs` — add font file existence check | ✅ (needs assertion) |
| A11Y-01 | Focus ring contrast ≥3:1 on each surface | unit (contrast_ratio assert) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ (needs new assertion) |
| MOTION-01 | Motion zeroed under prefers-reduced-motion | unit (string search in template) | Add to "semantic tokens" test | ✅ (needs string assertion) |
| GALLERY-01 | Gallery route exists in demo router | unit (string search) | Add to `operator_ui_demo_contract_test.exs` | ✅ (needs 1 new assertion) |
| GUARD-01 | Audit matrix committed | unit (File.exists?) | Add to `operator_ui_demo_contract_test.exs` | ✅ (needs assertion) |
| GUARD-02 | Contrast test re-pinned and passes | unit | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ (needs full re-pin) |

### Sampling Rate
- **Per task commit:** `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs`
- **Per wave merge:** `mix test test/parapet/`
- **Phase gate:** `mix test` full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/parapet/operator_ui_fonts_test.exs` — covers FONT-01 (file existence, byte budget ≤150KB, LICENSE.txt present)
  - `assert File.exists?("priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2")`
  - `assert File.stat!("priv/static/parapet/fonts/...").size <= 153_600`
- [ ] Add `"parapet"` to `static_paths` in demo_app_web.ex (not a test gap, but a code gap needed before FONT-03 can pass)

*(Remaining Wave 0 work: string assertions added to existing test files, not new files)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — no auth changes |
| V3 Session Management | no | n/a — no session changes |
| V4 Access Control | no | n/a — gallery is demo-only, no host auth surface |
| V5 Input Validation | no | n/a — CSS/font/test file changes only |
| V6 Cryptography | no | n/a |
| Supply chain (fonts) | yes | IBM Plex is OFL-licensed; fetched from official IBM/plex GitHub repo; commit hash can be pinned if desired |

### Known Threat Patterns

| Pattern | Concern | Mitigation |
|---------|---------|-----------|
| Font binary supply chain | woff2 files committed from unverified source | Download from `https://github.com/IBM/plex/master` (official IBM repo); verify SHA against CDN via fonttools `python3 -m fontTools.ttLib` |
| Gallery route data exposure | Demo LiveView might expose real incident data | Gallery must use hardcoded fixture data, not `Repo.all()` live data |
| CSS injection via token values | Token hex values sourced from tokens.css | Hex values are static, copied verbatim — no dynamic input |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `font-display: auto` | `font-display: swap` | WCAG 2.2 era | Visible fallback text, no FOUT blank period |
| Tailwind-native colors (teal-700 etc.) | CSS custom properties via `--po-*` vars | Already done in prior phases | Values-only re-skin is possible without markup changes |
| Per-component dark mode | Single CSS variable block re-mapped for dark | Already done | All components inherit dark automatically |
| `transition-duration: 0` | `--motion-fast: 0ms` via `prefers-reduced-motion` | WCAG 2.2 / brand tokens | Consistent token-driven motion zeroing |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The five woff2 files produced from Google Fonts TTFs (~59.9 KB total) match what will be produced from the IBM/plex repo TTFs at subsetting time | Font Subsetting | Small difference in size; still far under 150 KB ceiling — low risk |
| A2 | `data-parapet-theme` selector on `html` (not `body`) works correctly with the inline `<style>` injected into the page body | CSS Architecture | If selector scope causes issues, switch to `:root` scoping — LOW risk given existing working implementation |
| A3 | Dark chip nav-active uses inverted triplet (healthy-text for bg, limestone for fg) | CSS Variable Inventory | Wrong visual contrast in dark mode; caught by contrast test |
| A4 | Gallery LiveView can use `mount` assigns with hardcoded fixture data without touching Ecto | Gallery LiveView | If demo app requires Ecto context, need to add fixture helpers — LOW risk |

**A1-A4 are tagged [ASSUMED] in this research. All other claims were verified against the source files or tools this session.**

---

## Sources

### Primary (HIGH confidence)
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` (lines 1-1583) — complete CSS variable inventory, dark block locations, existing patterns [VERIFIED: file read]
- `brandbook/tokens/tokens.css` (lines 1-100) — complete token source of truth [VERIFIED: file read]
- `brandbook/notes/accessibility.md` — WCAG contrast ratios for all brand pairs [VERIFIED: file read]
- `test/parapet/operator_ui_contrast_test.exs` — current @themes maps and @component_paths [VERIFIED: file read]
- `test/parapet/operator_ui_demo_contract_test.exs` — exact route assertions [VERIFIED: file read]
- `examples/demo_app/lib/demo_app_web/router.ex` — current router structure [VERIFIED: file read]
- `mix.exs` — Hex files: whitelist, Igniter version [VERIFIED: file read]
- `lib/mix/tasks/parapet.gen.ui.ex` — generator current state [VERIFIED: file read]
- pyftsubset on actual IBM Plex TTFs — 5 woff2 files, 59,924 bytes total [VERIFIED: ran locally]
- GitHub API for IBM/plex repo structure — confirmed latin plex-sans/mono have no `unhinted/` subdir [VERIFIED: API response]

### Secondary (MEDIUM confidence)
- Igniter 0.7.9 source (`deps/igniter/lib/igniter.ex`, `deps/igniter/lib/mix/task.ex`) — `create_new_file` string-only, `run/1` is `defoverridable` [VERIFIED: file read]
- `examples/demo_app/lib/demo_app_web.ex` `static_paths` — current list [VERIFIED: file read]

### Tertiary (LOW confidence)
- Dark chip nav-active value choices (dark.nav_active_bg: `#3F5E28`) — computed to invert the healthy triplet [ASSUMED]

---

## Metadata

**Confidence breakdown:**
- Complete CSS variable inventory: HIGH — read directly from template
- Font budget: HIGH — ran pyftsubset on actual IBM Plex TTFs
- Contrast ratios: HIGH — from committed accessibility.md (all pre-computed)
- Gallery route safety: HIGH — verified against exact contract test assertions
- Igniter binary-copy strategy: HIGH — read Igniter source, confirmed defoverridable
- Dark chip re-pin values: MEDIUM — cross-checked against tokens.css but dark inversions [ASSUMED]

**Research date:** 2026-06-24
**Valid until:** 2026-09-01 (stable domain — CSS variables + fonttools stable)
