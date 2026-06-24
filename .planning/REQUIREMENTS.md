# Requirements

## Milestone v1.6 Operator UI Brand & Design-System Audit

**Defined:** 2026-06-24
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

**Goal:** Re-skin the generated, host-owned Operator UI to the v1.5 brand book and run a layered, researched, JTBD-focused design-system audit that ships an award-winning, WCAG 2.2 AA, mobile-first, on-brand operator console with forward-only regression guardrails.

**Source artifacts:** `brandbook/tokens/tokens.css` + `tokens.json` (v1.5 token system, ground truth) · `brandbook/notes/research.md` (brand voice/visual principles) · approved plan `~/.claude/plans/design-system-stress-test-glimmering-pie.md`

**Architectural anchor:** The Operator UI is generated, host-owned code scaffolded from three EEx templates under `priv/templates/parapet.gen.ui/` (`operator_components.ex.eex`, `operator_live.ex.eex`, `operator_detail_live.ex.eex`), mirrored into `examples/demo_app/lib/demo_app_web/live/parapet/`. All theme color lives in `operator_theme_bootstrap/1`'s inline `<style>` as `--parapet-*`/`--po-*` CSS variables (light/dark/system via `data-parapet-theme`). The re-skin is **values-only** — re-point those variables at brand values; no public API, telemetry, class, selector, JS, or markup-color change.

## v1 Requirements

### Token Re-skin (Foundations)

- [ ] **TOKEN-01**: The operator theme's neutral surface roles (`--parapet-bg`, `--parapet-panel`, `--parapet-text`, `--parapet-text-muted`, header/nav surfaces) resolve to brand neutrals (limestone/mortar/stone/wall-slate/deep-slate/parapet-black) in both light and dark themes.
- [ ] **TOKEN-02**: Signal colors are brand-aligned — links/info/selected use watch-blue, warning uses beacon-amber, success uses budget-moss, destructive uses incident-red, AI/trace uses trace-violet — replacing the prior teal/blue/indigo/emerald/purple hues across all `--po-*` variables.
- [ ] **TOKEN-03**: Every chip/badge/status pill is driven by the brand's six status triplets (text/bg/border for healthy, watch, burning, exhausted, unknown, ai) and is legible in both themes.
- [ ] **TOKEN-04**: The type scale, 8px spacing grid, and radius scale (card 10px, control 8px, modal 14px, pill 999px) from the brand tokens are applied to the operator UI without layout shift on the system-font fallback.
- [ ] **TOKEN-05**: Motion tokens (`--motion-fast` 120ms, `--motion-base` 200ms, `--motion-ease` cubic-bezier(.2,0,0,1)) are wired through the theme and zeroed under `prefers-reduced-motion`.

### Self-Hosted Fonts

- [ ] **FONT-01**: Subsetted IBM Plex Sans (400/500/600) and IBM Plex Mono (400/500) woff2 files (latin subset) are vendored under `priv/static/parapet/fonts/`, with the subsetting command documented for reproducibility, and added to the Hex `files:` whitelist within a tracked package-size budget.
- [ ] **FONT-02**: `operator_theme_bootstrap/1` emits `@font-face` rules referencing the host static path with `font-display: swap`, and the UI renders correctly on the system-stack fallback before fonts load (no FOUT breakage, no layout shift).
- [ ] **FONT-03**: The generator (`mix parapet.gen.ui` or a focused asset step) copies the vendored woff2 into the host app's static directory, and the demo app vendors/serves the same fonts so screenshots render true IBM Plex.

### Primitive Components

- [ ] **COMP-01**: Buttons (primary/secondary/ghost/destructive/warning) have tokenized, visually distinct rest / hover / active / focus-visible / disabled states in both themes.
- [ ] **COMP-02**: Disabled controls are both visually and semantically disabled (`disabled`/`aria-disabled`, reduced affordance) — no enabled-looking-but-dead controls and no disabled-looking-but-live controls.
- [ ] **COMP-03**: Links meet WCAG AA on their actual surface — watch-blue on light, brightened watch-blue (`#7FB4C6`) on dark surfaces — verified on both card surface and page background.
- [ ] **COMP-04**: Badges, chips, and status pills use the brand status triplets and remain legible (AA) in dark mode.
- [ ] **COMP-05**: Stat/metric cards use the metric type tokens and carry no spurious hover/pointer affordance.
- [ ] **COMP-06**: Every interactive primitive shows a visible `:focus-visible` ring, using the limestone ring on dark surfaces per the brand's documented dark-surface contrast fix.
- [ ] **COMP-07**: Icons, dividers, and separators follow the border-over-shadow philosophy with tokenized borders; icons never carry meaning by shape alone where a label is needed.
- [ ] **COMP-08**: No off-palette/raw-Tailwind hex remains in the templates for color (gate-enforced).

### Form Components

- [ ] **FORM-01**: The theme switcher and any action-confirmation inputs have tokenized states, accessible labels, and AA-contrast focus indicators.
- [ ] **FORM-02**: Form/confirmation controls expose correct accessible names and error/disabled states (not color-only).

### Navigation & Shell

- [ ] **NAV-01**: Tabs and nav items show an unambiguous active state with `aria-current="page"` in both themes.
- [ ] **NAV-02**: The app shell (header / nav / theme switcher) is usable at 390px with no horizontal overflow and no squished controls.
- [ ] **NAV-03**: The Light/Dark/System switcher retains its `localStorage` + `data-parapet-theme` behavior and meets AA contrast in all three modes.
- [ ] **NAV-04**: Navigation and IA labels follow least-surprise, plain-language (GOV.UK-style) naming aligned with the domain vocabulary.
- [ ] **NAV-05**: Keyboard users have a logical landmark structure and a working skip-to-content affordance.

### Data Display

- [ ] **DATA-01**: Incident list/rows and tables truncate or wrap long fields deliberately — no collapsed or unreadably squished columns.
- [ ] **DATA-02**: Lists/tables with internal scroll regions scroll correctly and are not trapped or broken; the page does not produce nested-scroll dead-ends.
- [ ] **DATA-03**: The incident timeline renders bounded fields and degrades gracefully with zero, few, and many entries.
- [ ] **DATA-04**: Empty states are designed (icon + explanatory copy + next action) and carry no hover/pointer affordance.
- [ ] **DATA-05**: Status and severity are conveyed by text and/or icon in addition to color (color-blind-safe), never by color alone.
- [ ] **DATA-06**: Loading/skeleton states are reduced-motion-safe and do not cause layout jumps.

### Component Groups (Meta-Components)

- [ ] **GROUP-01**: The response cockpit composes header/summary/actions coherently across all breakpoints.
- [ ] **GROUP-02**: Incident summary copy follows the brand voice formula (symptom → evidence → correlation → safe next action → where to inspect).
- [ ] **GROUP-03**: The runbook card and preview panel render fully above their scrim and are never clipped or hidden.
- [ ] **GROUP-04**: The action rail and action-item cards communicate risk and audit outcome; disabled actions are clearly disabled.
- [ ] **GROUP-05**: Every overlay/modal/drawer traps focus, is dismissible via Esc + close button + scrim click, and restores focus to its trigger on close.
- [ ] **GROUP-06**: Overlays have correct stacking order (modal above scrim above content) — no modal hidden behind its own scrim.

### Pages & Flows

- [ ] **FLOW-01**: The response → actions → history → incident-detail click-through has no dead-ends or broken back-navigation.
- [ ] **FLOW-02**: Each page has exactly one h1, ordered headings, correct landmarks, and a descriptive page title.
- [ ] **FLOW-03**: Empty, loading, and error page states are designed (not blank) and distinguish no-data vs unavailable vs permission-denied where applicable.
- [ ] **FLOW-04**: The compatibility detail route `/parapet/:id` still renders alongside the preferred `/parapet/incidents/:id`.
- [ ] **FLOW-05**: Every page is fully usable on mobile (390px) across all states.

### Accessibility (WCAG 2.2 AA)

- [ ] **A11Y-01**: Focus-ring contrast is handled per surface — watch-blue on light, limestone on dark — enforced by the contrast gate, not left to component authors.
- [ ] **A11Y-02**: All text meets 4.5:1 (3:1 for large text) and UI components/graphics meet 3:1 in both themes.
- [ ] **A11Y-03**: Every interactive element is keyboard-reachable with a visible focus indicator.
- [ ] **A11Y-04**: Tab order is logical with no keyboard traps.
- [ ] **A11Y-05**: Modal/overlay focus management (trap + restore) is correct and verified.
- [ ] **A11Y-06**: Landmarks, headings, ARIA labels, and page titles are present and correct on every page.

### Motion

- [ ] **MOTION-01**: Motion tokens are wired and fully zeroed under `prefers-reduced-motion`.
- [ ] **MOTION-02**: Hover/press micro-interactions are fast (≈120ms) and purposeful, not decorative; no `transition-all` thrash.
- [ ] **MOTION-03**: Reveal/confirm/orient transitions (preview panel, overlays) use the brand easing, are interruptible, and are reduced-motion-safe.

### Microcopy

- [ ] **COPY-01**: Navigation/IA labels are plain and least-surprise.
- [ ] **COPY-02**: Incident and summary copy follows symptom → evidence → correlation → safe next action → where to inspect.
- [ ] **COPY-03**: Empty/error/loading copy is calm, specific, and evidence-backed (no "oops"/"something went wrong"/blame).
- [ ] **COPY-04**: No placeholder, lorem, or TODO strings remain in the templates.
- [ ] **COPY-05**: Action copy states the risk and the safe next step for any mutating/destructive action.

### Stress Fixtures

- [ ] **FIXTURE-01**: A long-string/overflow demo scenario (long titles, IDs, module names, URLs) exists.
- [ ] **FIXTURE-02**: An empty-collection demo scenario (no incidents / empty timeline / no actions) exists.
- [ ] **FIXTURE-03**: A max-items / dense-list demo scenario exists.
- [ ] **FIXTURE-04**: A mixed-status demo scenario surfacing all six status triplets at once exists.
- [ ] **FIXTURE-05**: A combined "stress" scenario is wired to `PARAPET_DEMO_SCENARIO` and covered by the screenshot capture script (desktop + mobile, light + dark).

### Component Gallery (Demo-Only)

- [ ] **GALLERY-01**: A demo-only `/parapet/_gallery` route (never shipped into generated host UI) renders every component across {light, dark, empty, overflow, disabled, long-string} states for manual + screenshot audit.
- [ ] **GALLERY-02**: The gallery route is covered by the screenshot capture script and asserted by a demo contract test.

### Forward-Only Guardrails

- [ ] **GUARD-01**: A committed audit matrix (`brandbook/notes/operator-audit-matrix.md`) enumerates every component × state cell with a `todo`/`done`/`verified` status, serving as the idempotence ledger.
- [ ] **GUARD-02**: `operator_ui_contrast_test.exs` is re-pinned to the brand token hexes (all six status triplets, dark links on surface and bg, focus rings at the 3:1 UI floor) and passes at WCAG AA.
- [ ] **GUARD-03**: A normalized template↔demo byte-parity test reproduces the generator transform and fails if any `.eex` template and its demo mirror diverge.
- [ ] **GUARD-04**: An off-palette-hex gate over the templates fails if any non-token color hex appears (mirrors the v1.5 `brandbook/` palette gate).
- [ ] **GUARD-05**: A motion / reduced-motion assertion test verifies the brand easing is used and motion is zeroed under `prefers-reduced-motion`.
- [ ] **GUARD-06**: The screenshot capture script covers the stress scenario and the gallery; a committed baseline manifest + documented re-run/compare procedure exists (no rasters committed — repo-lean).
- [ ] **GUARD-07**: `v1.6-MILESTONE-AUDIT.md` records per-requirement evidence and proves no public-API/telemetry/host-ownership regression, the font package-size delta, and that the audit is forward-only/idempotent.

## Future Requirements

Tracked but deferred — not in this milestone's roadmap.

- Token → Tailwind/daisyUI theme generator + HEEx component snippets for the generated Operator UI (adopt token values now; build the generator later).
- Automated browser a11y/interaction testing (Playwright + axe-core) as demo dev-dependencies.
- Raster exports: PNG/ICO favicons and OpenGraph social-card images.
- Animated/motion logo, Figma source-of-truth, multi-page PDF brand book.

## Out Of Scope

Explicitly excluded for this milestone, with reasoning, to prevent scope creep.

| Exclusion | Reason |
|---|---|
| Any public API or telemetry contract change | Frozen under `docs/stability.md`; this milestone is a UI/design-system pass only |
| New Parapet-owned auth/router/runtime UI dependency | Operator UI stays host-owned/generated — a load-bearing project boundary |
| `phoenix_storybook` (or any new runtime dep) for the component lab | Demo-only `/parapet/_gallery` covers stress-inspection without a dependency or host-shipped catalog |
| Playwright / axe-core toolchain | Existing Elixir contrast test + screenshot matrix + manual ARIA-APG walkthrough cover AA this milestone; revisit as a tooling milestone |
| Token → Tailwind generator | Adopt token *values* in-place; a generator is separate-concern scope creep |
| Re-litigating brand palette / logo / voice | Locked in v1.5 (`decision-log.md` D-003) — operationalize only |
| Rasters / font binaries outside `priv/static/parapet/fonts/` | Repo-lean stays the default; only operator-UI woff2 fonts relax the binary rule, and only there |

## Traceability

Populated during roadmap creation (Phases 44–50). Each requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| _pending roadmap_ | — | Pending |

**Coverage:**
- v1 requirements: 56 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 56 ⚠️

---
*Requirements defined: 2026-06-24*
*Last updated: 2026-06-24 after initial definition*
