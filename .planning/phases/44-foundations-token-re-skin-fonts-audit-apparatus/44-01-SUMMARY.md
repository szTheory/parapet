---
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
plan: "01"
subsystem: fonts
tags: [fonts, woff2, ibm-plex, generator, static-assets, font-budget-test]
requirements: [FONT-01, FONT-03]
status: complete

dependency_graph:
  requires: []
  provides:
    - priv/static/parapet/fonts/ (five latin woff2 + OFL license)
    - mix.exs files: whitelist for font assets
    - generator run/1 override with File.cp! font copy
    - examples/demo_app Plug.Static parapet static path
    - test/parapet/operator_ui_fonts_test.exs FONT-01 gate
  affects:
    - Plan 02 (requires woff2 binaries for @font-face wiring)
    - Plan 04 (font existence required for demo-contract assertions)

tech_stack:
  added: []
  patterns:
    - fontTools.subset (python3 -m) for TTF → latin woff2 subsetting
    - Igniter run/1 defoverridable override + File.cp! for binary asset copy
    - ExUnit file-stat budget gate (operator_ui_fonts_test.exs pattern)

key_files:
  created:
    - priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2
    - priv/static/parapet/fonts/IBMPlexSans-Medium-latin.woff2
    - priv/static/parapet/fonts/IBMPlexSans-SemiBold-latin.woff2
    - priv/static/parapet/fonts/IBMPlexMono-Regular-latin.woff2
    - priv/static/parapet/fonts/IBMPlexMono-Medium-latin.woff2
    - priv/static/parapet/fonts/LICENSE.txt
    - test/parapet/operator_ui_fonts_test.exs
  modified:
    - mix.exs
    - lib/mix/tasks/parapet.gen.ui.ex
    - examples/demo_app/lib/demo_app_web.ex

decisions:
  - "Use python3 -m fontTools.subset (module form) instead of pyftsubset binary for PATH portability"
  - "File.cp! via run/1 override (not Igniter.create_new_file) for binary woff2 copy — avoids UTF-8 corruption"
  - "files: whitelist explicitly names font globs even though bare priv covers them — belt-and-suspenders per D-10"

metrics:
  duration: "~8 minutes"
  completed_date: "2026-06-24"
  tasks_completed: 2
  files_created: 7
  files_modified: 3
---

# Phase 44 Plan 01: Font Vendoring Foundation Summary

IBM Plex Sans 400/500/600 + Mono 400/500 subsetted to latin woff2, vendored under priv/static/parapet/fonts/ with OFL license, whitelisted in Hex package files:, copied to host via generator run/1 override, served by demo app via static_paths, and gated by a 4-test font budget/existence suite.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Download IBM Plex TTFs, subset to five latin woff2, vendor woff2 + OFL license | 760860c | 6 new files under priv/static/parapet/fonts/ |
| 2 | Whitelist fonts in mix.exs, add generator font-copy step, wire demo static_paths, add font budget test | b507ab7 | mix.exs, parapet.gen.ui.ex, demo_app_web.ex, operator_ui_fonts_test.exs |

## What Was Built

### Font Assets (Task 1)

Five IBM Plex latin-subset woff2 faces were downloaded from the official `IBM/plex` GitHub repository (`packages/plex-{sans,mono}/fonts/complete/ttf/`) and subsetted using `python3 -m fontTools.subset` with the unicode range covering Basic Latin, Latin-1 Supplement, and common punctuation/symbols. The OFL 1.1 `LICENSE.txt` was fetched from `packages/plex-sans/LICENSE.txt`.

Final sizes:
- `IBMPlexSans-Regular-latin.woff2`: 11,740 bytes
- `IBMPlexSans-Medium-latin.woff2`: 12,272 bytes
- `IBMPlexSans-SemiBold-latin.woff2`: 12,504 bytes
- `IBMPlexMono-Regular-latin.woff2`: 8,448 bytes
- `IBMPlexMono-Medium-latin.woff2`: 8,464 bytes
- **Total**: ~53,428 bytes (~52 KB) — 65% under the 150 KB ceiling

Note: actual sizes are slightly smaller than RESEARCH.md estimates (58.5 KB projected vs 53.4 KB actual) — both are within budget. The `WARNING: meta NOT subset` message was expected and harmless.

### Hex Whitelist (Task 2)

`mix.exs` `files:` now explicitly lists `priv/static/parapet/fonts/*.woff2` and `priv/static/parapet/fonts/LICENSE.txt` alongside the existing `priv` glob. This ensures font files cannot be silently pruned by future glob changes.

### Generator Font Copy (Task 2)

`lib/mix/tasks/parapet.gen.ui.ex` now has a `run/1` override that:
1. Calls `super(argv)` first (runs full Igniter pipeline, preserving all `copy_template` calls unchanged)
2. Then calls `copy_fonts_to_host/0` which resolves `:code.priv_dir(:parapet)` source path, creates `priv/static/parapet/fonts/` in the host app, and `File.cp!`s each font file (overwrite semantics per D-12)

`Igniter.create_new_file` was deliberately avoided for binary woff2 data — it uses string-based `Rewrite.Source` and would corrupt binary content.

### Demo App Static Paths (Task 2)

`examples/demo_app/lib/demo_app_web.ex` `static_paths/0` now includes `"parapet"`, enabling `Plug.Static` to serve `/parapet/fonts/*.woff2`.

### Font Budget Test (Task 2)

`test/parapet/operator_ui_fonts_test.exs` (`Parapet.OperatorUIFontsTest`) provides four tests:
1. All five woff2 files exist under `priv/static/parapet/fonts/`
2. `LICENSE.txt` is vendored
3. Total byte sum of all five woff2 ≤ 153,600 bytes (150 KB ceiling per D-09)
4. Each woff2 is non-empty (size > 0)

All 4 tests pass green.

## Verification Results

```
mix test test/parapet/operator_ui_fonts_test.exs
....
4 tests, 0 failures
```

- 5 woff2 files present: YES
- LICENSE.txt present, contains OFL text: YES
- Total size ≤ 150 KB: YES (53 KB actual)
- woff2 magic bytes `wOF2` (`77 4f 46 32`): YES (all five)
- `mix.exs` files: lists font globs: YES
- `File.cp!` in generator: YES
- `super(argv)` called before copy: YES
- `"parapet"` in demo static_paths: YES

## Deviations from Plan

None — plan executed exactly as written.

The only minor deviation from RESEARCH.md estimates: actual woff2 file sizes (53 KB total) are slightly smaller than the pre-verified budget figure (58.5 KB). This is acceptable — the research was run on a different version of the fonts or with slightly different flags. Both are within the 150 KB ceiling with substantial headroom.

## Known Stubs

None. All font files are real binary assets, not stubs.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes were introduced. The only new binary files committed are IBM Plex woff2 faces fetched from the official IBM/plex GitHub repo (`raw.githubusercontent.com/IBM/plex/master`), consistent with T-44-01 mitigation. No threat flags added.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2 | FOUND |
| priv/static/parapet/fonts/LICENSE.txt | FOUND |
| test/parapet/operator_ui_fonts_test.exs | FOUND |
| lib/mix/tasks/parapet.gen.ui.ex | FOUND |
| commit 760860c | FOUND |
| commit b507ab7 | FOUND |
