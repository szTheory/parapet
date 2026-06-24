# Phase 43 — Collateral, Wiring & QA/Audit Gate — HANDOFF / CONTEXT

> **Resume doc.** Read this + `.planning/ROADMAP.md` + `brandbook/notes/decision-log.md` to continue v1.5 in a fresh context. Phases 40–42 are DONE and committed. This is the final phase.

## Milestone: v1.5 Brand Book & Logo System

Operationalize the text-only brand research into a shippable, repo-lean HTML brand book under `brandbook/` with real logo assets, design tokens, and collateral; replace the off-brand HexDocs logo. Full plan: `/Users/jon/.claude/plans/existing-brand-book-is-jaunty-mitten.md`.

## Status

| Phase | State | Commit |
|---|---|---|
| 40 Brand Pressure-Test | ✅ done | `09e1cb8` |
| 41 Logo (6-round tournament) | ✅ done — identity LOCKED | `6a1c519` |
| 42 Tokens + Brand Book | ✅ done | `e1bf9db` |
| 43 Collateral + Wiring + Audit | ⏳ **THIS PHASE** | — |

## ⚠️ LOCKED — do NOT re-open the logo

Identity is **final** (6 rounds, user-approved). See `brandbook/notes/decision-log.md` D-003.
**Stacked emblem:** a corbelled parapet tower (reads as parapet/chess-rook; works as standalone avatar AND stacked) above **PARAPET** in **Space Grotesk** tight caps; single **Watch Blue `#256C82`** loophole accent. Wordmark is **outlined to paths** (font-independent).
Final assets (9 SVGs, all transparent/palette-locked/outlined) live in `brandbook/assets/`:
`parapet-logo.svg` (primary stacked) · `parapet-inverse.svg` · `parapet-mono.svg` · `parapet-horizontal.svg` (+`-inverse`) · `parapet-mark.svg` (+`-inverse`) · `favicon.svg` · `parapet-tagline.svg`.
Regenerate (only if a tweak is needed): `python3 brandbook/notes/logo-build.py` (needs network for the OFL font; never commit the font binary).

## What exists in `brandbook/`

```
brandbook/
  index.html                 # the brand book (done) — driven by tokens.css; IBM Plex via Google Fonts
  tokens/tokens.css          # CSS custom properties (done)
  tokens/tokens.json         # machine-readable mirror (done)
  assets/*.svg               # 9 final logo assets (done)
  assets/explorations/*.svg  # round-1 option SVGs (provenance)
  notes/research.md          # cited brand reference (done)
  notes/accessibility.md     # WCAG AA matrix (done)
  notes/decision-log.md      # D-001..D-003 (done; D-003 = logo decision)
  notes/contrast.py          # contrast calculator
  notes/logo-build.py        # reproducible logo generator
  notes/logo-options.html, logo-round-2..6.html   # 6 exploration rounds (provenance — TRIM in this phase)
```

## Phase 43 TODO (requirements COLLAT-01..03)

1. **COLLAT-01 — Collateral examples** (build on `tokens.css`, open from `file://`):
   - `brandbook/examples/components.html` — buttons / cards / badges / callouts / form inputs on tokens (light + dark). (Much can be lifted from the components section already in `index.html`.)
   - `brandbook/examples/landing-section.html` — a Deep Slate hero using `assets/parapet-inverse.svg`, a headline in the brand voice, install snippet, restrained.
   - `brandbook/examples/readme-header.svg` — a wide README/social banner (e.g. 1280×320 viewBox) using the horizontal lockup + tagline, transparent or Limestone.
2. **COLLAT-02 — Wire HexDocs (the one shipping change):**
   - Replace `docs/assets/parapet-logo.svg` ← `brandbook/assets/parapet-logo.svg` (or `parapet-horizontal.svg` — pick what reads best in the ExDoc sidebar; ExDoc shows the logo small/square-ish, so the **mark** or a compact lockup may read better than the tall stacked one — eyeball `mix docs`).
   - Replace `docs/assets/favicon.svg` ← `brandbook/assets/favicon.svg`.
   - `mix.exs:59-60` paths stay **unchanged** (`logo: "docs/assets/parapet-logo.svg"`, `favicon: "docs/assets/favicon.svg"`) → zero-config swap.
   - Verify: `mix docs` builds clean and renders the new mark. (Note: ExDoc renders the logo as `<img>`, so the outlined/font-independent asset is required — ✓.)
3. **Cleanup (repo-lean):** delete the intermediate exploration pages `brandbook/notes/logo-options.html` and `logo-round-2.html`..`logo-round-5.html` (keep `logo-round-6.html` as the final-round record, or move all to an `explorations/` note). Brandbook is ~216 KB; target ≤ ~250 KB but trim the dead weight. Keep `assets/explorations/` round-1 SVGs or drop them too.
4. **COLLAT-03 — Repo-hygiene audit + milestone audit:**
   - Run the QA checks (below). Record pass/fail.
   - Write `.planning/milestones/v1.5-MILESTONE-AUDIT.md` (mirror v1.4's format: requirements ✓, phases ✓, which brand-doc sections realized).
   - Update `.planning/MILESTONES.md` with the v1.5 entry; mark COLLAT-01..03 complete in `REQUIREMENTS.md`; check Phase 43 in `ROADMAP.md` + progress table.
   - Consider `/gsd-complete-milestone` to archive.

## QA checks (Phase 43 gate)

```bash
cd /Users/jon/projects/parapet
# 1. no off-palette hex in any asset (catches stray Tailwind colors)
grep -rohiE '#[0-9a-f]{6}' brandbook/assets/*.svg | sort -u | \
  grep -viE '101820|18232B|2E3A42|D8D0C3|EAE2D4|F8F4EC|256C82|B45309|D97706|567236|B13A32|6D5BD0' \
  && echo "OFF-PALETTE FOUND" || echo "OK"
# 2. no raster/font binaries in brandbook
find brandbook \( -name '*.png' -o -name '*.jpg' -o -name '*.woff*' -o -name '*.ttf' -o -name '*.otf' \) -print
# 3. size budget
du -sh brandbook
# 4. brand book + examples open from file:// (render via headless Chrome; see commands in session)
# 5. mix docs renders new logo:  mix docs && open doc/index.html
# 6. scoped diff: git status limited to brandbook/, docs/assets/*.svg, (no mix.exs change needed)
```

Headless-Chrome render pattern used all session (for visual verification — assets are author-blind):
```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
  --window-size=1200,2000 --virtual-time-budget=4500 --screenshot=/tmp/out.png "file://$PWD/brandbook/index.html"
```

## Non-negotiables (carry forward)

Transparent logos, no background cage · palette-locked (brand tokens only) · no font binaries committed · repo-lean · no subtitle on the primary lockup · values copied from the research doc, not re-derived · commit via `gsd-tools query commit` per the session pattern.

## Commit pattern

```bash
GSD_TOOLS="$HOME/.claude/gsd-core/bin/gsd-tools.cjs"
node "$GSD_TOOLS" query commit "feat(phase-43): <what>" --files <paths>
```
