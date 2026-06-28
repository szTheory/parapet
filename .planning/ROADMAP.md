# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- [x] **v1.5 Brand Book & Logo System** — Phases 40-43, 11 plans, shipped 2026-06-24. Archive: [v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- [ ] **v1.6 Operator UI Brand & Design-System Audit** — Phases 44-50, in progress (started 2026-06-24)

## Phases

<details>
<summary>✅ v1.5 Brand Book & Logo System (Phases 40-43) — SHIPPED 2026-06-24</summary>

- [x] Phase 40: Brand Pressure-Test & Critique Gate (1/1 plans) — completed 2026-06-23
- [x] Phase 41: Logo Exploration & User Selection Gate (6/6 rounds) — completed 2026-06-24
- [x] Phase 42: Token System & HTML Brand Book (3/3 plans) — completed 2026-06-24
- [x] Phase 43: Collateral, Wiring & QA/Audit Gate (3/3 plans) — completed 2026-06-24

Full detail: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)

</details>

### v1.6 Operator UI Brand & Design-System Audit (Phases 44-50) — ACTIVE

**Goal**: Re-skin the generated, host-owned Operator UI to the v1.5 brand book and run a layered, researched, JTBD-focused design-system audit that ships an award-winning, WCAG 2.2 AA, mobile-first, on-brand operator console with forward-only regression guardrails. Values-only edits to `operator_theme_bootstrap/1` and the three EEx templates (+ demo mirrors); no public-API, telemetry, or host-ownership change.

**Idempotent layering order** (intentional — must be preserved): foundations → primitives → forms → nav/data → groups → pages → fixtures → guardrails.

- [x] **Phase 44: Foundations — token re-skin, fonts & audit apparatus** — Re-base color/type/spacing/radius/shadow/motion/focus on brand tokens, vendor self-hosted IBM Plex woff2, scaffold the demo `/parapet/_gallery` route, create the audit matrix, and re-pin the contrast gate. (completed 2026-06-25)
- [x] **Phase 45: Primitive components** — Buttons/links/badges/chips/status pills/stat cards/icons/dividers/focus + theme-switcher controls with distinct, accessible, color-blind-safe states. (completed 2026-06-25)
- [x] **Phase 46: Navigation, shell & data-display** — Nav/tabs/theme switcher/cockpit header + incident list/row/timeline/tables with active states, responsive 390px layout, deliberate truncation, working scroll, and keyboard reachability. (completed 2026-06-26)
- [x] **Phase 47: Component groups / meta-components** — Response cockpit, incident summary, runbook card, preview panel, action rail, action-item cards, overlays/modals with correct stacking, focus trap/restore, and brand-eased motion. (completed 2026-06-26)
- [x] **Phase 48: Pages, flows & microcopy** — Response/actions/history tabs + incident detail end-to-end with one h1/landmarks/title, designed empty/loading/error states, brand-voice copy, and full mobile usability. (completed 2026-06-28)
- [x] **Phase 49: Stress fixtures & seed coverage** — Long-string/empty/max-items/mixed-status + combined stress scenarios wired to `PARAPET_DEMO_SCENARIO`, with the gallery covered by screenshot capture and a demo contract test. (completed 2026-06-28)
- [ ] **Phase 50: Guardrails, parity & idempotence gate** — Template↔demo byte-parity test, off-palette-hex gate, motion assertion, screenshot baseline manifest, and the `v1.6-MILESTONE-AUDIT.md` proving no API/telemetry/host-ownership regression and forward-only idempotence.

## Phase Details

### Phase 44: Foundations — token re-skin, fonts & audit apparatus

**Goal**: The operator theme is re-based on brand tokens (color/type/spacing/radius/shadow/motion/focus), self-hosted IBM Plex woff2 is vendored and wired with a clean system fallback, the demo-only component lab and audit ledger exist, and the contrast gate is re-pinned to brand hexes — establishing the foundation every later layer builds on.
**Depends on**: Nothing (first phase of milestone)
**Requirements**: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, FONT-01, FONT-02, FONT-03, A11Y-01, MOTION-01, GALLERY-01, GUARD-01, GUARD-02
**Success Criteria** (what must be TRUE):

  1. An operator viewing the UI in both light and dark themes sees brand neutrals, brand signal colors, and the six brand status triplets — with no off-brand teal/blue/indigo/emerald/purple hues remaining — and the type scale, 8px grid, and radius scale applied with no layout shift on the system-font fallback.
  2. The UI renders true subsetted IBM Plex Sans/Mono served from the host static path with `font-display: swap`, falls back cleanly to the system stack before fonts load (no FOUT breakage, no layout shift), and the demo app serves the same fonts.
  3. Motion is driven by the brand motion tokens and fully zeroed under `prefers-reduced-motion`; per-surface focus rings (watch-blue on light, limestone on dark) are enforced by the contrast gate, not left to component authors.
  4. A developer can open the demo-only `/parapet/_gallery` route (never shipped into generated host UI) and the committed `operator-audit-matrix.md` ledger enumerates every component × state cell with a todo/done/verified status.
  5. `operator_ui_contrast_test.exs` is re-pinned to the brand token hexes (all six status triplets, dark links on surface and bg, focus rings at the 3:1 UI floor) and passes at WCAG AA.

**Plans**: 4/4 plans complete
**Wave 1**

- [x] 44-01-PLAN.md — Vendor + subset IBM Plex woff2, whitelist for Hex, generator font-copy step, demo static_paths, font budget test (Wave 1)
- [x] 44-02-PLAN.md — Values-only token re-skin across all 3 CSS blocks + @font-face + motion + focus rings in template & demo mirror; verify secondary templates (Wave 1)
- [x] 44-03-PLAN.md — Demo-only `/parapet/_gallery` GalleryLive + route, and the `operator-audit-matrix.md` ledger (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 44-04-PLAN.md — Re-pin `operator_ui_contrast_test.exs` to brand hexes + additive demo-contract assertions (Wave 2)

**UI hint**: yes

### Phase 45: Primitive components

**Goal**: Every primitive component (buttons, links, badges, chips, status pills, stat cards, icons, dividers, focus rings, and the theme-switcher form controls) is tokenized, accessible, and visually correct across all interactive states in both themes — the building blocks every meta-component and page will compose.
**Depends on**: Phase 44
**Requirements**: COMP-01, COMP-02, COMP-03, COMP-04, COMP-05, COMP-06, COMP-07, COMP-08, FORM-01, FORM-02, A11Y-02, MOTION-02
**Success Criteria** (what must be TRUE):

  1. An operator can visually distinguish a button's rest / hover / active / focus-visible / disabled states in both themes, and disabled controls are both visually and semantically disabled — no enabled-looking-but-dead or disabled-looking-but-live controls.
  2. Links meet WCAG AA on their actual surface (watch-blue on light, brightened `#7FB4C6` on dark) on both card and page background, and every interactive primitive shows a visible `:focus-visible` ring using the limestone ring on dark surfaces.
  3. Badges, chips, and status pills use the brand status triplets and remain legible (AA) in dark mode; stat/metric cards carry no spurious hover/pointer affordance.
  4. The theme switcher and action-confirmation inputs expose correct accessible names, AA-contrast focus indicators, and error/disabled states conveyed by more than color alone.
  5. All primitive text meets 4.5:1 (3:1 for large text) and UI components meet 3:1 in both themes; hover/press micro-interactions are fast (~120ms) and purposeful with no `transition-all` thrash, and no off-palette/raw-Tailwind color hex remains in the templates (gate-enforced).

**Plans**: 4/4 plans complete

- [x] 45-01-PLAN.md — Wire Phase-45 verification gate into the contrast test (new button contrast pairs + off-palette/motion/focus/cursor refute-assert block; red scaffold)
- [x] 45-02-PLAN.md — CSS foundation + Elixir functions in operator_components.ex.eex + mirror (new .po-button-*/.po-guidance/.po-timeline-*/.po-queue-row-selected rules + vars; control_base/control_class/timeline/queue functions; #042f2e fix)
- [x] 45-03-PLAN.md — Inline markup re-skin in operator_components.ex.eex + mirror (preview_panel, suspect_changes_card, runbook_card, three standalone primary buttons; stat-card affordance)
- [x] 45-04-PLAN.md — Secondary templates operator_live/operator_detail_live + mirrors; phase-wide off-palette gate dry-run + full suite + audit-matrix update + gallery walkthrough

**UI hint**: yes

### Phase 46: Navigation, shell & data-display

**Goal**: The app shell (header / nav / tabs / theme switcher / cockpit header) and all data-display surfaces (incident list/rows, timeline, tables) are responsive, keyboard-navigable, and render long and degenerate data deliberately — so an operator can orient and read evidence at any breakpoint and with any data shape.
**Depends on**: Phase 45
**Requirements**: NAV-01, NAV-02, NAV-03, NAV-04, NAV-05, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05, DATA-06, A11Y-03, A11Y-04
**Success Criteria** (what must be TRUE):

  1. Tabs and nav items show an unambiguous active state with `aria-current="page"` in both themes, IA labels follow plain-language least-surprise naming, and the Light/Dark/System switcher retains its `localStorage` + `data-parapet-theme` behavior at AA contrast in all three modes.
  2. The app shell is fully usable at 390px with no horizontal overflow and no squished controls, and keyboard users have a logical landmark structure with a working skip-to-content affordance.
  3. Incident lists/rows and tables truncate or wrap long fields deliberately (no collapsed or unreadably squished columns), and internal scroll regions scroll correctly with no trapped or nested-scroll dead-ends.
  4. The incident timeline renders bounded fields and degrades gracefully with zero, few, and many entries; empty states are designed (icon + copy + next action) and carry no hover/pointer affordance; loading/skeleton states are reduced-motion-safe with no layout jumps.
  5. Status and severity are conveyed by text and/or icon in addition to color (color-blind-safe), every interactive element is keyboard-reachable with a visible focus indicator, and tab order is logical with no keyboard traps.

**Plans**: 4/4 plans complete

- [x] 46-01-PLAN.md — Wave 0 test scaffold: @detail_template_paths + extended NAV/DATA/A11Y red assertions in operator_ui_contrast_test.exs
- [x] 46-02-PLAN.md — operator_components.ex.eex + mirror: nav-active border (NAV-01), timeline empty-state + spine CSS (DATA-03), empty-state icons (DATA-04)
- [x] 46-03-PLAN.md — operator_live + operator_detail_live + mirrors: skip-link/landmarks (NAV-05), queue-refresh color (NAV-02), skeleton (DATA-06), pagination focus/disabled (A11Y-03)
- [x] 46-04-PLAN.md — full-suite gate + human gallery walkthrough: 390px (NAV-02), tab order (A11Y-04), timeline/empty-state/skeleton rendered behaviors

**UI hint**: yes

### Phase 47: Component groups / meta-components

**Goal**: The composed meta-components (response cockpit, incident summary, runbook card, preview panel, action rail, action-item cards, and all overlays/modals/drawers) render coherently across breakpoints with correct stacking, focus management, and brand-eased motion — so the response surfaces an operator actually works in behave correctly under interaction.
**Depends on**: Phase 46
**Requirements**: GROUP-01, GROUP-02, GROUP-03, GROUP-04, GROUP-05, GROUP-06, A11Y-05, MOTION-03
**Success Criteria** (what must be TRUE):

  1. The response cockpit composes header/summary/actions coherently across all breakpoints, and incident summary copy follows the brand voice formula (symptom → evidence → correlation → safe next action → where to inspect).
  2. The runbook card and preview panel render fully above their scrim and are never clipped or hidden, and overlays have correct stacking order (modal above scrim above content) — no modal hidden behind its own scrim.
  3. The action rail and action-item cards communicate risk and audit outcome, with disabled actions clearly disabled.
  4. Every overlay/modal/drawer traps focus, is dismissible via Esc + close button + scrim click, and restores focus to its trigger on close — verified.
  5. Reveal/confirm/orient transitions (preview panel, overlays) use the brand easing, are interruptible, and are reduced-motion-safe.

**Plans**: 3/3 plans complete
**Wave 1**

- [x] 47-01-PLAN.md — RED test scaffold: additive Phase-47 assertions to operator_ui_contrast_test.exs (D-15)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 47-02-PLAN.md — Template + demo-mirror markup edits (red→green): incident_summary voice, risk/audit chips, aria-disabled, preview_panel reveal + landmark, cockpit break-words, scroll-pb (D-06/07/08/09/10/11/13/02/03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 47-03-PLAN.md — Gate: full suite + audit-matrix N/A-by-design flip + blocking human gallery walkthrough (D-04/15/16/18)

**UI hint**: yes

### Phase 48: Pages, flows & microcopy

**Goal**: The full operator flow (response → actions → history → incident detail) is navigable end-to-end with correct page semantics, designed empty/loading/error states, brand-voice microcopy, and complete mobile usability — the user-facing payoff where the re-skinned primitives and groups become a coherent, on-brand console.
**Depends on**: Phase 47
**Requirements**: FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05, COPY-01, COPY-02, COPY-03, COPY-04, COPY-05, A11Y-06
**Success Criteria** (what must be TRUE):

  1. An operator can click response → actions → history → incident-detail with no dead-ends or broken back-navigation, and the compatibility route `/parapet/:id` still renders alongside the preferred `/parapet/incidents/:id`.
  2. Each page has exactly one h1, ordered headings, correct landmarks, ARIA labels, and a descriptive page title; empty, loading, and error states are designed (not blank) and distinguish no-data vs unavailable vs permission-denied where applicable.
  3. Navigation/IA labels are plain and least-surprise, and incident/summary copy follows symptom → evidence → correlation → safe next action → where to inspect.
  4. Empty/error/loading copy is calm, specific, and evidence-backed (no "oops"/"something went wrong"/blame), action copy states the risk and safe next step for any mutating/destructive action, and no placeholder/lorem/TODO strings remain in the templates.
  5. Every page is fully usable on mobile (390px) across all states.

**Plans**: 4 plans
**Wave 1**

- [x] 48-01-PLAN.md — RED scaffold: source-string + rendered-state assertions for all FLOW/COPY/A11Y facts (no new test files) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 48-02-PLAN.md — green (components): not-found panel, incident_summary heading-level prop, empty-state anatomy + uniform skeleton, component microcopy, R1-R7 overflow fixes [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 48-03-PLAN.md — green (shell/service): additive fetch_incident_detail/1, not-found wiring (mount + 6 refresh sites), per-page h1 + :page_title, nav landmark, route-order lock, demo layout patch, flash microcopy [wave 3]

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 48-04-PLAN.md — gate: full lib + demo suite green, audit-matrix flip (+ N/A-by-Design rows), blocking human /parapet/_gallery walkthrough [wave 4]

**UI hint**: yes

### Phase 49: Stress fixtures & seed coverage

**Goal**: The demo app carries reproducible stress scenarios (long-string overflow, empty collections, max-items density, mixed-status, and a combined stress scenario) wired to `PARAPET_DEMO_SCENARIO`, and the component gallery is covered by the screenshot capture script and a demo contract test — so the audit can be re-run against worst-case data on demand.
**Depends on**: Phase 48
**Requirements**: FIXTURE-01, FIXTURE-02, FIXTURE-03, FIXTURE-04, FIXTURE-05, GALLERY-02
**Success Criteria** (what must be TRUE):

  1. A developer can select a long-string/overflow scenario (long titles, IDs, module names, URLs), an empty-collection scenario (no incidents / empty timeline / no actions), and a max-items / dense-list scenario via the demo seed.
  2. A mixed-status scenario surfaces all six status triplets at once, and a combined "stress" scenario is wired to `PARAPET_DEMO_SCENARIO`.
  3. The combined stress scenario is covered by the screenshot capture script across desktop + mobile and light + dark.
  4. The `/parapet/_gallery` route is covered by the screenshot capture script and asserted by a demo contract test.

**Plans**: 2/3 plans executed

- [x] 49-01-PLAN.md — RED scaffold: gallery render contract test + fixture-existence pins + static script grep pin in operator_smoke_test.exs
- [x] 49-02-PLAN.md — Seed work: extend demo_seed_scenarios.exs with long_string/empty/max_items/mixed_status/stress scenarios
- [x] 49-03-PLAN.md — Capture-script: add four /parapet/_gallery captures (desktop+mobile, light+dark) to the canonical audit script

**UI hint**: yes

### Phase 50: Guardrails, parity & idempotence gate

**Goal**: Forward-only regression guardrails are in place — template↔demo byte-parity, off-palette-hex gate, motion assertion, and a committed screenshot baseline manifest — and `v1.6-MILESTONE-AUDIT.md` proves per-requirement evidence, zero public-API/telemetry/host-ownership regression, the font package-size delta, and that the audit is forward-only and idempotent.
**Depends on**: Phase 49
**Requirements**: GUARD-03, GUARD-04, GUARD-05, GUARD-06, GUARD-07
**Success Criteria** (what must be TRUE):

  1. A normalized template↔demo byte-parity test reproduces the generator transform and fails if any `.eex` template and its demo mirror diverge.
  2. An off-palette-hex gate over the templates fails if any non-token color hex appears (mirroring the v1.5 `brandbook/` palette gate), and a motion / reduced-motion assertion verifies the brand easing is used and motion is zeroed under `prefers-reduced-motion`.
  3. The screenshot capture script covers the stress scenario and the gallery, and a committed baseline manifest plus a documented re-run/compare procedure exists (no rasters committed — repo-lean).
  4. `v1.6-MILESTONE-AUDIT.md` records per-requirement evidence and proves no public-API/telemetry/host-ownership regression, the font package-size delta, and that the audit is forward-only/idempotent.

**Plans**: TBD

---

## Next Milestone

**v1.6 Operator UI Brand & Design-System Audit is now the active milestone** (Phases 44-50, see Phase Details above).

After v1.6 ships, candidate follow-up work (deferred from v1.5/v1.6):

- Token → Tailwind/daisyUI theme generator + HEEx component snippets for the generated Operator UI (this milestone adopts token *values* in-place; the generator is separate-concern scope).
- Automated browser a11y/interaction testing (Playwright + axe-core) as demo dev-dependencies.
- Raster exports: PNG/ICO favicons and OpenGraph social-card images.
- Animated/motion logo, Figma source-of-truth, multi-page PDF brand book.

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 40. Brand Pressure-Test & Critique Gate | v1.5 | 1/1 | Complete | 2026-06-23 |
| 41. Logo Exploration & User Selection Gate | v1.5 | 6/6 | Complete | 2026-06-24 |
| 42. Token System & HTML Brand Book | v1.5 | 3/3 | Complete | 2026-06-24 |
| 43. Collateral, Wiring & QA/Audit Gate | v1.5 | 3/3 | Complete | 2026-06-24 |
| 44. Foundations — token re-skin, fonts & audit apparatus | v1.6 | 4/4 | Complete   | 2026-06-25 |
| 45. Primitive components | v1.6 | 4/4 | Complete   | 2026-06-25 |
| 46. Navigation, shell & data-display | v1.6 | 4/4 | Complete    | 2026-06-26 |
| 47. Component groups / meta-components | v1.6 | 3/3 | Complete   | 2026-06-26 |
| 48. Pages, flows & microcopy | v1.6 | 4/4 | Complete   | 2026-06-28 |
| 49. Stress fixtures & seed coverage | v1.6 | 3/3 | Complete   | 2026-06-28 |
| 50. Guardrails, parity & idempotence gate | v1.6 | 0/? | Pending | - |
