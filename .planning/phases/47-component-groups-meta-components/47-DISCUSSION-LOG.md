# Phase 47: Component groups / meta-components - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-26
**Phase:** 47-component-groups-meta-components
**Mode:** assumptions + per-area subagent research (user-requested deep research before lock)
**Areas analyzed:** Overlay/disclosure reality; Meta-component re-skin + responsive composition;
Incident-summary brand voice; Motion (preview_panel reveal); Verification / test-gate strategy.

## Assumptions Presented

### Overlay / modal reality (GROUP-03/05/06, A11Y-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No true overlays/modals/drawers/scrims exist; `preview_panel` is a mobile-fixed/desktop-inline disclosure with no scrim/focus-trap; GROUP-03/05/06 + A11Y-05 are N/A-by-design, resolved in audit matrix | Confident | zero `modal\|overlay\|drawer\|scrim\|dialog` matches in `.eex`; `operator_components.ex.eex:~1169`; out-of-scope bans new JS focus-trap |

### Meta-component re-skin + responsive (GROUP-01, GROUP-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Raw Tailwind utilities flow through interception layer; GROUP-01/04 is mostly verify responsive composition + disabled affordance inherited from prior phases; cockpit `22rem` grid may need 390px attention | Likely | `response_cockpit:554-616`, `incident_summary:810-928`, `control_base():1393`; audit-matrix rows 19/25/32-33 |

### Incident-summary brand voice (GROUP-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Formula applies to static labels + guidance/fallback copy, not host data; 47 does structural summary copy, defer page microcopy to 48 (COPY-02) | Likely | `incident_summary:810-928`; REQUIREMENTS maps GROUP-02→47, COPY-02→48 |

### Motion (MOTION-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `preview_panel` has no reveal transition; add CSS-only brand-eased reveal, reduced-motion-safe via existing block, no JS | Likely | `preview_panel:1166-1229`; motion tokens `:109-111`; reduced-motion `:466-478` |

### Verification / test-gate
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Wave-0 red-scaffold pattern; string assertions in contrast test (reads template + mirror); A11Y-05 verified via human/gallery walkthrough; no Playwright/axe | Confident | `operator_ui_contrast_test.exs` existing MOTION/DATA/A11Y assertions; 45-01/46-01/46-04 plans |

## Corrections Made

No corrections to the assumptions themselves. The user **confirmed** the pivotal overlay
decision ("Document as N/A-by-design") and then directed: research each area with subagents
(pros/cons/tradeoffs, ecosystem lessons, brandbook/prompts/JTBD lenses, DX/UX, principle of least
surprise, design pillars) and one-shot a coherent, locked set of recommendations.

Five parallel research subagents were spawned (one per area). Their findings sharpened the
"Likely" assumptions into decisive, evidence-cited decisions (see CONTEXT.md D-01..D-18). Key
refinements beyond the original assumptions:

- **Overlay:** added the WCAG 2.4.11 residual-risk fix (`scroll-padding-bottom`, technique C43)
  and the `role="region"`/`aria-label` announcement; turned "document N/A" into a *positive
  negative-guard* test so a future partial-modal regression goes red.
- **Meta-components:** cockpit needs only `break-words` (grid already collapses); risk via
  color+icon+label; audit outcome surfaced honestly from `state` with no fabricated "failed";
  `aria-disabled` over native `disabled` for shown-but-unavailable controls (all component-layer,
  no `ActionItem` schema change).
- **Brand voice:** concrete label rewrites + a firm 47/48 bright line (47 edits only
  `incident_summary/1`; `_copy/1` helpers untouched).
- **Motion:** pure CSS `@keyframes` chosen over `phx-mounted`/`@starting-style` because
  `preview_panel` is a stateless `:html` component diffed in/out — keyframes auto-fire on insert.
- **Test-gate:** 4-wave cadence; parity by assertion-pairing (byte-diff deferred to Phase 50);
  human walkthrough reserved for genuinely-rendered cells only.

## External Research

Per-area subagents researched: ARIA APG Disclosure vs Dialog; WCAG 2.2 SC 2.4.3/2.4.7/2.4.11
(focus order/visible/not-obscured), technique C43; GOV.UK / Radix / Phoenix core_components modal
practice; NN/g bottom sheets; GitLab Pajamas / Smashing / UX Movement destructive-action patterns;
Grafana OnCall audit logging; `aria-disabled` vs `disabled` (Kitty Giraudel, CSS-Tricks, MDN);
CSS keyframes-on-insert (thinkdobecreate), `@starting-style` Baseline (web.dev/MDN), Phoenix
`JS.transition`/`phx-mounted` (HexDocs, ElixirStreams), compositor-only animation (Chrome devs);
incident-response UX writing (Atlassian, incident.io, Google SRE Workbook); accessibility
auto-tooling limits (W3C WAI). Full citations live inline in CONTEXT.md `<specifics>` and the
research summaries that produced D-01..D-18.
