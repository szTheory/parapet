---
phase: 43
slug: collateral-wiring
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-24
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> v1.5 is brand/design assets only — there are no ExUnit tests. The validation
> surface is the COLLAT-03 QA gate (bash grep/find/du), the `mix docs` build, and
> author-blind headless-Chrome visual confirmation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — bash QA gate + `mix docs` build + headless-Chrome screenshots |
| **Config file** | none (no test framework; assets-only milestone) |
| **Quick run command** | `grep -rohiE '#[0-9a-f]{6}' brandbook/assets/*.svg \| sort -u \| grep -viE '101820\|18232B\|2E3A42\|D8D0C3\|EAE2D4\|F8F4EC\|256C82\|B45309\|D97706\|567236\|B13A32\|6D5BD0' && echo OFF-PALETTE FOUND \|\| echo OK` |
| **Full suite command** | QA gate (palette + binary + size + scope) then `mix docs` |
| **Estimated runtime** | ~30 seconds (grep/find/du instant; `mix docs` ~10–20s) |

---

## Sampling Rate

- **After every task commit:** Run the relevant QA check for the artifact just produced (palette grep for SVGs, `mix docs` after the HexDocs swap).
- **After every plan wave:** Run the full COLLAT-03 QA gate.
- **Before `/gsd-verify-work`:** Full QA gate green + `mix docs` clean + headless-Chrome confirms each example renders.
- **Max feedback latency:** 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-* | 01 | 1 | COLLAT-01 | — / — | N/A | visual | `"$CHROME" --headless=new --screenshot=/tmp/out.png "file://$PWD/brandbook/examples/components.html"` | ❌ W0 | ⬜ pending |
| 43-01-* | 01 | 1 | COLLAT-01 | — / — | N/A | visual | screenshot `landing-section.html` + `readme-header.svg` | ❌ W0 | ⬜ pending |
| 43-02-* | 02 | 2 | COLLAT-02 | — / — | N/A | build | `mix docs` (zero errors/warnings) + inspect `doc/index.html` sidebar | ✅ | ⬜ pending |
| 43-03-* | 03 | 3 | COLLAT-03 | — / — | N/A | unit (bash) | palette grep → `OK`; `find` binaries → empty; `du -sh brandbook` ≤ ~250 KB; `git diff --name-only` scoped | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No test framework is installed or needed — the validation surface is bash QA commands (grep/find/du/git), the `mix docs` build (already wired via `mix.exs:59-60`), and headless-Chrome screenshots (Chrome present at `/Applications/Google Chrome.app`). The only "❌ W0" entries above are the example HTML/SVG artifacts that this phase itself produces — they become testable as soon as their producing task commits.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Collateral examples are on-brand and render correctly | COLLAT-01 | Visual/aesthetic judgement; SVG/HTML output is author-blind | Headless-Chrome screenshot each `examples/*.html` and open `readme-header.svg`; confirm tokens drive light+dark, mark/lockup correct |
| New logo reads well in the ExDoc sidebar | COLLAT-02 | ExDoc renders the logo as a small `<img>`; "reads best small" is a visual judgement | `mix docs && open doc/index.html`; if the stacked mark is too tall, swap to `parapet-mark.svg` or `parapet-horizontal.svg` and rebuild |

---

## Validation Sign-Off

- [x] All tasks have an automated verify command or are explicitly manual-only with instructions
- [x] Sampling continuity: every task maps to a QA command or visual procedure
- [x] Wave 0 covers all MISSING references (none — no framework needed)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-24
