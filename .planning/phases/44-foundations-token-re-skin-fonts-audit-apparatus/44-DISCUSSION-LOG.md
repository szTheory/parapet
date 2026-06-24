# Phase 44: Foundations — token re-skin, fonts & audit apparatus - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-24
**Phase:** 44-foundations-token-re-skin-fonts-audit-apparatus
**Mode:** assumptions
**Areas analyzed:** Token re-skin mechanics, Focus rings, Dark-link hex, Font vendoring/wiring, Gallery route, Audit matrix + contrast-test re-pin

## Assumptions Presented

### Token re-skin mechanics (TOKEN-01..05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Values-only re-point of ~16 `--parapet-*` + ~40 `--po-*` vars; interception layer + `.po-*` rules stay byte-identical | Confident | `operator_components.ex.eex` light/dark/media blocks; locked plan "values-only" |
| Role mapping teal/blue/indigo/amber/stone → brand neutrals/signals/status triplets | Confident | TOKEN-01/02/03; `brandbook/tokens/tokens.css:25-30` |
| Keep `data-parapet-theme` (not renamed to `data-theme`) | Confident | Public switcher + screenshot-script contract (plan caveat) |
| Update BOTH dark blocks (`[data-parapet-theme=dark]` + `@media prefers-color-scheme:dark`) in lockstep | Confident | Two dark definitions in template; contrast test reads `@themes`, not media query |

### Focus rings (A11Y-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Light ring watch-blue `#256C82`, dark ring limestone `#F8F4EC`; gate adds 3:1 focus assertions | Confident | `tokens.css:75-80`; current test has no focus assertion |

### Dark-link hex (TOKEN-02 / A11Y-02 / GUARD-02 / GUARD-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Use `#7FB4C6` over brand book `#6FA8BC` for operator dark link | Likely | `operator_ui_contrast_test.exs:70-71` pins link vs panel/surface; `tokens.json:30` notes `#6FA8BC` tuned for deep-slate bg; operator panel = wall-slate `#2E3A42` |

### Font vendoring/wiring (FONT-01..03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 5 woff2 (Sans 400/500/600 + Mono 400/500) latin subset → `priv/static/parapet/fonts/`; new generator static-copy step; `@font-face` + swap in bootstrap | Likely | `priv/static/parapet/fonts/` absent; `parapet.gen.ui.ex` has only template copies; zero `@font-face` in template; `mix.exs` whitelists bare `priv` |

### Gallery route (GALLERY-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `/parapet/_gallery` in demo `router.ex` only; not in `router_snippet.ex.eex`; not in demo-contract test | Likely | Demo router scopes; `operator_ui_demo_contract_test.exs:55-102` pins exact 5-route shape; locked plan "demo only" |

### Audit matrix + contrast-test re-pin (GUARD-01, GUARD-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `brandbook/notes/operator-audit-matrix.md` grid (todo/done/verified); re-pin both `@themes` maps + run vs template AND demo mirror | Confident | `brandbook/notes/` exists; `operator_ui_contrast_test.exs:4-7,100-126` loops both paths |

## Corrections Made

### Dark-link hex
- **Original assumption:** Use `#7FB4C6` (Likely), with the open question of how to reconcile the brand-book conflict.
- **User decision:** Use `#7FB4C6` AND widen the off-palette-hex gate to admit it as an operator-specific lightened-link exception; leave the v1.5 brand book token `#6FA8BC` untouched. (Resolved D-07 + D-08.)
- **Reason:** Fixes the real a11y gap on the operator panel surface while keeping the v1.5 brand book locked.

All other assumptions (token mechanics, focus rings, fonts, gallery, audit matrix) confirmed as-is ("All good — proceed").

## External Research

Performed (general-purpose agent) to firm up FONT-01:
- **IBM Plex source + toolchain:** Start from unhinted `.ttf` in the IBM/plex git repo
  (`packages/plex-{sans,mono}/fonts/complete/ttf/unhinted/`, `IBMPlex{Family}-{Regular|Medium|SemiBold}.ttf`).
  npm ships woff2-only (not a subsetting source). `pyftsubset` ships with `fonttools`; woff2
  output needs `brotli`. Copy-paste command per face captured in CONTEXT.md `<specifics>`.
  `font-display` is a CSS `@font-face` descriptor, not a subset flag.
  (Sources: github.com/IBM/plex, fonttools.readthedocs.io/en/latest/subset/)
- **OFL 1.1:** subsetting + woff2 conversion permitted, no rename required; vendor `LICENSE.txt`
  with the fonts and include in `mix.exs files:`. (Source: github.com/IBM/plex/blob/master/LICENSE.txt, openfontlicense.org/ofl-faq/)
- **Size budget:** ~20–25 KB/face latin subset → ~110–125 KB total for 5 faces; set tracked
  ceiling ≤150 KB. (Sources: gwfh.mranftl.com/fonts/ibm-plex-sans, carbon-design-system font assets)
