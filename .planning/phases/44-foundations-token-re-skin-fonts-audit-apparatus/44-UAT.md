---
status: testing
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
source: [44-VERIFICATION.md]
started: 2026-06-25T02:45:00Z
updated: 2026-06-25T02:45:00Z
---

## Current Test

number: 1
name: TOKEN-04 — type scale, radius scale, 8px spacing grid, and no-layout-shift visual check
expected: |
  In the demo app at /parapet and /parapet/_gallery (light + dark): heading/body/mono
  type scale matches the brand type scale; cards ~10px radius, controls ~8px, modals
  ~14px, badges pill (near-full); spacing follows an 8px grid; and NO visible reflow /
  layout shift as IBM Plex fonts swap in over the system-stack fallback. IBM Plex Sans
  renders for UI text, IBM Plex Mono for code/ID spans.
awaiting: user response

## Tests

### 1. TOKEN-04 — type/radius/spacing visual fidelity + no-FOUT-reflow
expected: |
  Visual fidelity matches the brand design specification; no FOUT-induced reflow as
  fonts load; IBM Plex Sans for UI text and IBM Plex Mono for code/IDs. Radii applied
  via Tailwind utilities mapping to the brand scale (rounded-lg≈10px, rounded-md≈8px,
  rounded-xl≈14px, rounded-full=999px); brand type/spacing/radius/shadow tokens are now
  declared in operator_theme_bootstrap/1 as the foundation for later phases.
how_to_test: |
  1. cd examples/demo_app && mix phx.server
  2. Open http://localhost:4000/parapet and http://localhost:4000/parapet/_gallery
  3. Toggle Light / Dark / System via the theme switcher
  4. Confirm (a) type scale, (b) radii per scale, (c) 8px spacing grid, (d) no reflow as
     IBM Plex swaps in over the system fallback
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
