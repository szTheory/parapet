---
phase: 43-collateral-wiring
plan: "02"
subsystem: brand-assets
tags: [brand, hexdocs, exdoc, logo, favicon, repo-hygiene]
dependency_graph:
  requires: [43-01-collateral-examples]
  provides: [COLLAT-02]
  affects: [docs/assets/, brandbook/notes/]
tech_stack:
  added: []
  patterns: [zero-config-path-stable-swap, palette-locked-svg]
key_files:
  created: []
  modified:
    - docs/assets/parapet-logo.svg
    - docs/assets/favicon.svg
  deleted:
    - brandbook/notes/logo-options.html
    - brandbook/notes/logo-round-2.html
    - brandbook/notes/logo-round-3.html
    - brandbook/notes/logo-round-4.html
    - brandbook/notes/logo-round-5.html
decisions:
  - "parapet-mark.svg chosen for docs/assets/parapet-logo.svg (ExDoc sidebar) — most compact 32x52 viewBox, reads well at small sizes; mix docs confirmed clean"
  - "Zero-config path-stable swap: mix.exs doc-block paths unchanged (lines 59-60 still logo: docs/assets/parapet-logo.svg and favicon: docs/assets/favicon.svg)"
  - "Five exploration HTMLs deleted (logo-options + logo-round-2..5, ~49 KB); logo-round-6.html retained as final-round record (D-003 provenance)"
metrics:
  duration_seconds: 180
  completed_date: "2026-06-24"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 2
  files_deleted: 5
status: complete
---

# Phase 43 Plan 02: HexDocs Logo Swap + Repo Cleanup (COLLAT-02) Summary

**One-liner:** Corbelled-tower mark (`parapet-mark.svg`) copied over the off-brand Tailwind-slate/Arial `docs/assets/parapet-logo.svg` and `favicon.svg` — zero-config path-stable swap; `mix docs` builds clean; five superseded exploration HTMLs deleted.

## What Was Built

### Task 1: Swap HexDocs logo + favicon (zero-config)

Replaced the off-brand assets in `docs/assets/` with palette-locked branded assets from `brandbook/assets/`:

| File | Before | After |
|------|--------|-------|
| `docs/assets/parapet-logo.svg` | 753 B — `#0f172a` cage, Arial text, off-palette strokes | Corbelled-tower mark (parapet-mark.svg), 32×52 viewBox, `#101820` / `#256C82`, transparent |
| `docs/assets/favicon.svg` | 622 B — same off-brand defects | Same mark geometry as logo, `#101820` / `#256C82`, transparent |

**Asset chosen:** `parapet-mark.svg` (tower-only, 32×52 viewBox) — the most compact asset per RESEARCH §2 recommendation. The mark's square-ish proportions render cleanly at the small ExDoc sidebar size without clipping or overflow. The stacked logo (183.9×106, tall) and horizontal (252×62.5, wide) were considered but not needed — the mark confirmed readable after `mix docs` eyeball.

**`mix.exs` paths unchanged (zero-config):**
- Line 59: `logo: "docs/assets/parapet-logo.svg"` — not touched
- Line 60: `favicon: "docs/assets/favicon.svg"` — not touched

**Verification results:**

| Check | Result |
|-------|--------|
| `mix.exs` logo path unchanged | OK |
| `mix.exs` favicon path unchanged | OK |
| `docs/assets/parapet-logo.svg` contains `#256C82` | OK |
| `docs/assets/favicon.svg` contains `#256C82` | OK |
| Off-palette hex in parapet-logo.svg | NONE |
| Off-palette hex in favicon.svg | NONE |
| Old off-brand markers (`#0f172a`, `#38bdf8`, `#94a3b8`, Arial) | NONE |
| `mix docs` exit code | 0 |
| `mix docs` output errors/warnings | NONE |
| `doc/assets/logo.svg` contains Watch Blue | CONFIRMED |

### Task 2: Trim superseded exploration HTMLs (repo-lean)

Deleted five superseded intermediate exploration pages from `brandbook/notes/`:

| File | Size | Outcome |
|------|------|---------|
| `logo-options.html` | ~15 KB | DELETED |
| `logo-round-2.html` | ~11 KB | DELETED |
| `logo-round-3.html` | ~8 KB | DELETED |
| `logo-round-4.html` | ~7 KB | DELETED |
| `logo-round-5.html` | ~8 KB | DELETED |

**Retained:** `brandbook/notes/logo-round-6.html` (final-round stacked emblem tournament — D-003 provenance record).

**`brandbook/assets/explorations/`** — 8 round-1 option SVGs kept untouched (small, provenance).

**Brandbook size after cleanup:** 192 KB (baseline was 224 KB before examples; with examples added in plan 01 and cleanup in this plan: comfortably under 250 KB budget).

## Verification Results

| Check | Result |
|-------|--------|
| `logo-options.html` deleted | OK |
| `logo-round-2.html` deleted | OK |
| `logo-round-3.html` deleted | OK |
| `logo-round-4.html` deleted | OK |
| `logo-round-5.html` deleted | OK |
| `logo-round-6.html` retained | OK |
| `explorations/` directory untouched | OK |
| `brandbook/` size | 192 KB (≤ 250 KB budget) |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: logo + favicon swap | `66fa54c` | feat(43-02): swap HexDocs logo + favicon to on-brand corbelled-tower mark |
| Task 2: exploration HTML cleanup | `8a191f3` | chore(43-02): delete superseded exploration HTMLs (repo-lean) |

## Deviations from Plan

None — plan executed exactly as written. The `parapet-mark.svg` was confirmed as the correct ExDoc logo choice (as RESEARCH recommended) without needing to fall back to the horizontal asset.

## Threat Flags

None. This plan touches only static brand assets (SVG file copies and file deletions). No network endpoints, auth paths, user input, or runtime behavior introduced.

**STRIDE mitigations verified:**
- T-43-02a (off-brand content surviving): Both files verified — Watch Blue present, zero off-palette hex, zero old off-brand markers
- T-43-02b (wrong asset not rendering): `mix docs` confirmed clean; `doc/assets/logo.svg` contains `#256C82` (ExDoc picked up the new mark)
- T-43-02c (unintended mix.exs edits): mix.exs paths at lines 59-60 confirmed unchanged

## Known Stubs

None. Both `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` are fully on-brand, palette-locked assets. No placeholder content.

## Self-Check: PASSED

- [x] `docs/assets/parapet-logo.svg` exists and contains `#256C82`, no off-palette hex, no off-brand markers
- [x] `docs/assets/favicon.svg` exists and contains `#256C82`, no off-palette hex, no off-brand markers
- [x] `mix.exs` lines 59-60 unchanged
- [x] `mix docs` built clean (zero errors, zero warnings)
- [x] `doc/index.html` exists
- [x] `doc/assets/logo.svg` contains Watch Blue (new mark rendered by ExDoc)
- [x] `brandbook/notes/logo-round-6.html` still exists
- [x] Five exploration HTMLs (`logo-options`, `logo-round-2..5`) deleted
- [x] `brandbook/assets/explorations/` untouched
- [x] Commit `66fa54c` exists (Task 1)
- [x] Commit `8a191f3` exists (Task 2)
