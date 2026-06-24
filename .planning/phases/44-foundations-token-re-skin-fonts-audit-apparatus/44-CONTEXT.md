# Phase 44: Foundations — token re-skin, fonts & audit apparatus - Context

**Gathered:** 2026-06-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

First phase of milestone v1.6 (Operator UI Brand & Design-System Audit). Establishes the
foundation every later layer (primitives → forms → nav/data → groups → pages → fixtures →
guardrails) builds on. In scope for Phase 44 only:

- Re-base the operator theme on brand tokens: color (neutrals/signals/6 status triplets),
  type scale, 8px spacing grid, radius scale, shadow, motion, and focus — **values-only** edits
  to `operator_theme_bootstrap/1`'s inline `<style>` and the three EEx templates (+ demo mirrors).
- Vendor + wire self-hosted subsetted IBM Plex woff2.
- Scaffold the demo-only `/parapet/_gallery` stress route.
- Create the committed `brandbook/notes/operator-audit-matrix.md` ledger (idempotence ledger).
- Re-pin `operator_ui_contrast_test.exs` to brand token hexes.

**Hard boundary (do NOT cross):** no public-API, telemetry-contract, class, selector, JS, or
markup-color change. The Operator UI stays generated/host-owned. No new Parapet runtime
dependency. Per-component visual/interaction fixes (buttons, nav, overlays, pages, copy,
fixtures) belong to Phases 45–50, not here.

**Requirements:** TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, FONT-01, FONT-02, FONT-03,
A11Y-01, MOTION-01, GALLERY-01, GUARD-01, GUARD-02.
</domain>

<decisions>
## Implementation Decisions

### Token re-skin mechanics (TOKEN-01..05)
- **D-01:** Re-skin is **values-only**. Re-point the full variable inventory (~16 `--parapet-*`
  + ~40 `--po-*` vars) in the inline `<style>` of `operator_theme_bootstrap/1`. The
  utility-interception layer (e.g. `.bg-stone-* → var(...)`, `.text-teal-* → var(...)`) and all
  `.po-*` class rules stay **byte-identical** — only the `:root`/dark var *values* change. No
  class/selector/JS/markup-color edits.
- **D-02:** Map by semantic role: teal accents (`#0f766e`/`#2dd4bf`/`#5eead4`) → watch-blue /
  budget-moss per role; blue links (`#1d4ed8`) → watch-blue `#256C82`; indigo info → ai-violet
  set; amber warning → beacon-amber (`#B45309` light / `#D97706` dark); stone neutrals →
  limestone / mortar / stone / wall-slate / deep-slate / parapet-black. All six status triplets
  (healthy/watch/burning/exhausted/unknown/ai) come verbatim from `brandbook/tokens/tokens.css`
  lines 25-30.
- **D-03:** Keep `data-parapet-theme` as the theme attribute (it is the public switcher +
  screenshot-script contract). Do **not** rename to the brand book's `data-theme`. Reconcile
  brand at the token-*value* level.
- **D-04:** Update **both** dark-theme definitions in lockstep — the explicit
  `[data-parapet-theme="dark"]` block AND the `@media (prefers-color-scheme: dark)` block. If
  only one is updated, `system`-theme users on an OS-dark machine get a split-brain old-teal
  palette that the contrast test (which reads `@themes` constants, not the media query) will not
  catch. This is the single highest-risk drift point of the phase.
- **D-05:** Apply the type scale, 8px spacing grid, and radius scale (card 10px / control 8px /
  modal 14px / pill 999px) and motion tokens (`--motion-fast` 120ms, `--motion-base` 200ms,
  `--motion-ease` cubic-bezier(.2,0,0,1)) from the brand tokens, with motion zeroed under
  `prefers-reduced-motion`. No layout shift on the system-font fallback.

### Focus rings (A11Y-01)
- **D-06:** Light focus ring stays watch-blue `#256C82`; dark focus ring flips to limestone
  `#F8F4EC` (watch-blue is only ~2.7:1 on deep-slate). The contrast gate enforces per-surface
  focus-ring contrast at the **3:1 UI floor** — it currently has no focus-ring assertion, so
  GUARD-02 adds one. Focus-ring contrast is gate-enforced, not left to component authors.

### Dark-mode link color (TOKEN-02, A11Y-02, GUARD-02, GUARD-04) — DECIDED
- **D-07:** The operator UI dark `--po-link` / `--link` uses **`#7FB4C6`** (5.14:1 on the
  wall-slate panel surface, 7.04:1 on bg), NOT the brand book's `#6FA8BC`. Rationale: operator
  panels use the lighter wall-slate surface `#2E3A42`, where `#6FA8BC` (tuned for the deep-slate
  *bg*) risks dropping below AA; GUARD-02 requires links to pass on surface **and** bg.
- **D-08:** The v1.5 brand book token stays **untouched** (`brandbook/tokens.css`/`.json` keep
  `#6FA8BC`). Instead, the Phase-50 off-palette-hex gate (GUARD-04) is configured to **admit
  `#7FB4C6` as an explicit operator-specific lightened-link exception** to its allowed-hex list.
  The brand book remains locked from v1.5; this is an operator-UI-scoped a11y refinement, not a
  re-litigation of the palette.

### Self-hosted fonts (FONT-01..03)
- **D-09:** Vendor five woff2 faces under `priv/static/parapet/fonts/`: IBM Plex Sans 400/500/600
  + IBM Plex Mono 400/500, **latin subset**, produced from the unhinted `.ttf` in the IBM/plex
  git repo (`packages/plex-{sans,mono}/fonts/complete/ttf/unhinted/`) via `pyftsubset`
  (fonttools + brotli). The exact subsetting command is documented for reproducibility (the team
  already uses fonttools for the logo). Target ≈110–125 KB total; **tracked budget ceiling
  ≤150 KB**.
- **D-10:** Vendor the IBM Plex OFL 1.1 `LICENSE.txt` alongside the fonts and include it (and the
  woff2) in the Hex `files:` whitelist. `mix.exs` already whitelists bare `priv`, but list the
  font assets + license explicitly so they cannot be silently pruned.
- **D-11:** `operator_theme_bootstrap/1` emits `@font-face` rules pointing at the host static
  path with `font-display: swap` and the system stack (`--font-sans`/`--font-mono`) as fallback —
  correct render before fonts load, no FOUT breakage, no layout shift. (Currently there are zero
  `@font-face` rules in the template.)
- **D-12:** Add a **new static-asset copy step** to the generator. `parapet.gen.ui` currently
  copies only `.ex` templates (no static copy). The step copies the vendored woff2 into the
  host's `priv/static` path. Prefer wiring such that re-runs refresh fonts (avoid a `:skip` that
  leaves hosts on stale font files on upgrade). The demo app vendors/serves the same woff2 so
  screenshots render true IBM Plex (FONT-03).

### Gallery route (GALLERY-01)
- **D-13:** Add `/parapet/_gallery` to `examples/demo_app/lib/demo_app_web/router.ex` **only**
  (new demo LiveView, e.g. `DemoAppWeb.Parapet.GalleryLive`). It is **never** added to
  `router_snippet.ex.eex` and **never** generated into host UI. It renders every component ×
  {light, dark, empty, overflow, disabled, long-string} for manual + screenshot audit.
- **D-14:** Do **not** add `/parapet/_gallery` to the existing demo-contract test, which pins an
  exact 5-route shape/ordering. Place the route so it does not disturb those byte-exact `live(...)`
  assertions.

### Audit matrix + contrast-test re-pin (GUARD-01, GUARD-02)
- **D-15:** Create `brandbook/notes/operator-audit-matrix.md` (the `brandbook/notes/` dir already
  exists) as a committed component × state grid where each cell carries `todo` / `done` /
  `verified`. It is the milestone's idempotence ledger — re-runs only revisit non-verified or
  regressed cells.
- **D-16:** Re-pin `test/parapet/operator_ui_contrast_test.exs`: rewrite **both** `@themes` maps
  (light + dark) to brand hexes for all six status triplets, links on surface **and** bg, and add
  focus-ring assertions at the 3:1 floor. The test reads from **both** `@component_paths` (the
  generated template AND the demo mirror), so the demo mirror must be re-skinned identically or
  the per-path assertions break. Test passes at WCAG AA on the new palette.

### Claude's Discretion
- Exact internal structure/columns of the audit-matrix markdown (as long as every component ×
  state cell is enumerable with a todo/done/verified status).
- Whether the font copy is a sub-step of `mix parapet.gen.ui` or a focused `mix parapet.gen.assets`
  step — pick whichever keeps re-run/upgrade font-refresh correct (D-12).
- Precise `pyftsubset` `--unicodes` scope (Google-Fonts latin range vs ASCII-only) within the
  ≤150 KB budget.
- Whether the demo gallery LiveView lives in its own `live_session` or reuses an existing one,
  provided D-14 holds.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `~/.claude/plans/design-system-stress-test-glimmering-pie.md` — approved milestone plan
  (locked decisions, load-bearing contrast caveats, font mechanism, phase breakdown).
- `.planning/REQUIREMENTS.md` — Phase 44 requirement text (TOKEN/FONT/A11Y/MOTION/GALLERY/GUARD).
- `brandbook/tokens/tokens.css` + `brandbook/tokens/tokens.json` — token source of truth
  (read-only reference; values copied verbatim, not re-derived).
- `brandbook/notes/accessibility.md`, `brandbook/notes/decision-log.md` — v1.5 a11y findings and
  the locked brand/palette decision (D-003).
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — `operator_theme_bootstrap/1` +
  the 20 function components (primary re-skin target).
- `priv/templates/parapet.gen.ui/operator_live.ex.eex`,
  `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — secondary templates.
- `examples/demo_app/lib/demo_app_web/live/parapet/{operator_components,operator_live,operator_detail_live}.ex`
  — demo mirrors (must stay in sync with templates).
- `test/parapet/operator_ui_contrast_test.exs` — contrast gate to re-pin (reads both paths).
- `test/parapet/operator_ui_demo_contract_test.exs` — pins the exact demo route shape (do not
  disturb; gallery route excluded).
- `examples/demo_app/lib/demo_app_web/router.ex` — where the demo-only gallery route is added.
- `mix.exs` — Hex `files:` whitelist (fonts + OFL license).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `operator_theme_bootstrap/1` is a strong, self-contained theming foundation: inline `<style>`
  with `--parapet-*`/`--po-*` CSS vars, light/dark/system via `data-parapet-theme` + `localStorage`,
  a Light/Dark/System switcher, reduced-motion support, and ARIA labels. Reskin in place.
- The utility-interception layer (`bg-stone-*`/`bg-teal-*` → CSS var) inherits brand values "for
  free" once the vars are re-pointed — no per-utility edits needed.
- The pure-Elixir WCAG contrast test already enforces 4.5:1 and rejects raw Tailwind colors, and
  already loops over both the template and the demo mirror — re-pin, don't rebuild.
- The team already uses Python `fonttools` (logo outlining in `brandbook/notes/logo-build.py`),
  so `pyftsubset` is the natural subsetting tool.

### Established Patterns
- Three EEx templates are the source of truth, mirrored into the demo app; sync is currently
  enforced only by shared string markers (no true byte-parity test yet — that arrives in Phase 50).
- v1.5 discipline: "operationalize / copy verbatim, don't re-derive." Token hexes are copied from
  `tokens.css`, never recomputed.
- `brandbook/`-style palette gate (off-palette-hex) is the precedent for GUARD-04.

### Integration Points
- Generator (`parapet.gen.ui`) copies `.ex` templates into a host app — gains a new static-asset
  (font) copy step.
- `mix.exs` `files:` whitelist controls what ships in the Hex package (fonts + OFL license).
- Demo router gains the gallery route; demo seed scenarios (Phase 49) and screenshot script
  (Phases 49/50) consume the gallery later.
</code_context>

<specifics>
## Specific Ideas

- Dark link `#7FB4C6` (5.14:1 on surface, 7.04:1 on bg) is the plan-computed, one-step
  brightening of the brand's dark-link direction — chosen over `#6FA8BC` for operator panels.
- Subsetting command (per face), latin subset, from unhinted `.ttf`:
  `pyftsubset IBMPlex{Sans|Mono}-{Regular|Medium|SemiBold}.ttf --output-file=... --flavor=woff2
  --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,
  U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD" --layout-features="kern,liga,clig,calt,
  ccmp,locl,mark,mkmk" --desubroutinize --no-hinting --drop-tables+=DSIG --notdef-outline
  --recalc-bounds` (needs `pip install fonttools brotli`; `font-display` is CSS-side, not a subset
  flag).
- OFL 1.1: no rename needed; vendor `LICENSE.txt` next to the fonts and include in `mix.exs files:`.
- Font budget: ~20–25 KB/face → ~110–125 KB total; ceiling ≤150 KB (overshoot signals a
  mis-scoped subset).
</specifics>

<deferred>
## Deferred Ideas

- Normalized template↔demo byte-parity test — Phase 50 (GUARD-03).
- Off-palette-hex gate implementation — Phase 50 (GUARD-04); Phase 44 only records the
  `#7FB4C6` exception decision (D-08) for that gate to honor.
- Screenshot baseline manifest + stress-scenario coverage — Phases 49/50.
- Token → Tailwind/daisyUI generator, Playwright/axe-core, raster exports — out of milestone
  scope (Future Requirements).

### Reviewed Todos (not folded)
None — todo query returned no matches for this phase.
</deferred>
