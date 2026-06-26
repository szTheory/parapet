# Phase 47: Component groups / meta-components - Context

**Gathered:** 2026-06-26 (assumptions mode + per-area subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Re-skin and harden the **composed meta-components** of the generated Operator UI so the
response surfaces an operator actually works in behave correctly under interaction:
`response_cockpit`, `incident_summary`, `runbook_card`, `preview_panel`, `action_rail`,
`action_item_list` / `action_item_card`, and the (non-existent) overlay/modal/drawer surfaces.

Requirements in scope: GROUP-01..06, A11Y-05, MOTION-03.

**Fixed milestone boundaries (v1.6, inherited from Phase 44):** values-only / token-driven
re-skin; **no public API or telemetry change**; UI stays **host-owned / generated** (real
templates in `priv/templates/parapet.gen.ui/*.eex`, byte-parity demo mirrors under
`examples/demo_app/lib/demo_app_web/live/parapet/*.ex`); **no new Parapet-owned runtime UI/JS
dependency**; brand/palette/logo locked; demo mirrors stay parity-enforced. This phase clarifies
HOW to implement what is scoped — never WHETHER to add new capabilities.

**Ground-truth pivot (drives the whole phase):** a repo-wide grep for
`modal|overlay|drawer|scrim|dialog|aria-modal|role="dialog"` across all `.eex` returns **zero
matches**. There are NO true modals/overlays/drawers/scrims. The only layered surface is
`preview_panel` — a mobile `fixed inset-x-0 bottom-0 z-50` bottom sheet that becomes
`md:relative` inline on desktop, with a working close button but no scrim, Esc handler, or
focus-trap. It is the ARIA **Disclosure** pattern, not the Dialog pattern. `runbook_card` is a
plain inline `<div>`. Therefore GROUP-03/05/06 + A11Y-05 are **N/A-by-design**, resolved in the
audit matrix with documented rationale — NOT implemented as new modal/focus-trap machinery.
</domain>

<decisions>
## Implementation Decisions

### Overlay / disclosure reality (GROUP-03, GROUP-05, GROUP-06, A11Y-05)
- **D-01:** Treat overlay/modal/drawer/scrim + focus-trap requirements as **N/A-by-design**.
  Keep `preview_panel` a **non-modal inline disclosure** (ARIA Disclosure pattern). Do **NOT**
  add focus-trap, scrim, `aria-modal`, or a full-screen backdrop — that would contradict the
  locked no-modals reality, *trap* keyboard users in non-modal content, and require new JS,
  breaking the milestone boundary. (Confirmed: `preview_panel` at
  `priv/templates/parapet.gen.ui/operator_components.ex.eex:~1169`; trigger "Preview Recovery"
  and panel both live in the same `<aside>` in `operator_detail_live`.)
- **D-02:** Fix the one genuine residual a11y gap (**WCAG 2.2 SC 2.4.11 Focus Not Obscured**):
  on a short mobile viewport the opened fixed bottom sheet can fully cover the just-activated
  trigger. Add **`scroll-padding-bottom` on the mobile page scroll container** (e.g.
  `scroll-pb-72 md:scroll-pb-0`, tuned to the measured sheet height) — WCAG technique C43,
  CSS-only, no JS, no markup restructure.
- **D-03:** Add `role="region"` + `aria-label="Recovery Preview"` to the `preview_panel` root so
  assistive tech announces it. The existing close button (`phx-click="cancel_preview"`,
  `aria-label="Close Recovery Preview"`, visible `focus:ring-2`, 40×40 hit target) already
  satisfies dismissibility and SC 2.4.7.
- **D-04:** Document overlay-absence as intentional & defensible in
  `brandbook/notes/operator-audit-matrix.md`: cite ARIA APG **Disclosure vs Dialog**, and WCAG
  **2.4.3** (focus order — content follows trigger in DOM), **2.4.7** (focus visible), **2.4.11**
  (focus not obscured, satisfied via D-02). Mark GROUP-03/05/06 + A11Y-05 overlay cells as
  **`n/a`** (not `todo`/`done`) with the rationale.

### Meta-component re-skin + responsive composition (GROUP-01, GROUP-04)
- **D-05:** `response_cockpit` stays a **CSS-grid single-column-by-default** layout; **no
  breakpoint hack, no JS**. The `lg:grid-cols-[...]` two-column track already collapses below
  `lg` (1024px) to a stacked single column with `gap-6`. At 390px keep **source order**
  (title → impact → evidence → journeys/counts) — impact-first is the right least-surprise read
  on a phone; do not use `order-*`.
- **D-06:** The only structural cockpit edit is **adding `break-words` to the cockpit `<h2>`
  impact title** (≈`operator_components.ex.eex:561`) to match the overflow hardening already on
  `incident_summary` (`whitespace-normal break-words`), so a long unbroken title can't blow out
  width at 390px.
- **D-07:** Convey **action RISK by color + icon + label, never color alone** (WCAG 1.4.1),
  reusing the existing `po-chip-{success,warning,danger,info,neutral}` status triplets and
  `severity_color/1`. Derive an action-item risk tier in a **component-layer helper**
  (`defp action_item_risk(kind)`) from the existing `ActionItem.kind` — **no `ActionItem` schema
  change** (the schema has only `state` + `kind`; adding a column is out of bounds).
- **D-08:** Surface **AUDIT OUTCOME** (currently promised in copy but never rendered) using the
  existing `chip_class(:execution, :executed)` success chip plus a neutral "Pending" sibling,
  mapped honestly from `state`: `resolved` → "Resolved · audited", `open` → "Pending". **Do not
  fabricate a "failed" state** — there is no failure field in the data; note it as out of scope
  until a future API milestone adds an outcome field.
- **D-09:** Disabled affordance: **keep** the existing **hide-with-explanation** pattern for
  gated escalation controls (no ghost controls — good). For any control that is *shown but
  unavailable*, use **`aria-disabled="true"`** (keeps it focusable + announced with a reason),
  **not** native `disabled` (which drops it from tab order so AT users never discover it). Add an
  `[aria-disabled='true']` CSS sibling giving the same `opacity-50` + `cursor-not-allowed` as
  `control_base()`'s `:disabled` (values/CSS-only). This matches the existing pagination pattern.

### Incident-summary brand voice (GROUP-02)
- **D-10:** Re-author **only the body of `incident_summary/1`** (≈`operator_components.ex.eex:810-928`)
  so reading top-to-bottom traces the brand formula **symptom → evidence → correlation → safe
  next action → where to inspect** (verbatim at `brandbook/index.html:253`). Reuse the three
  existing card containers and the existing `@detail.*` / `@detail.derived.*` fields — **zero
  data-shape change**; only static labels, section order, connective copy, and fallback strings
  change.
- **D-11:** Rename the five section labels to name the formula steps in **sentence case**:
  "Impact Summary" → **"What users are seeing"**; "Top Facts" → **"Evidence on record"**;
  "Observability" → **"Where to inspect"**; "Next Step" → **"Safe next step"**; "Escalation
  Status" → **"Escalation status"**. Rewrite the two in-summary fallbacks: "No impact summary
  recorded." → "No user-facing impact has been recorded yet."; "No external links attached." →
  "No trace or external links are attached to this incident yet."
- **D-12:** **47-vs-48 bright line:** Phase 47 (GROUP-02) edits **only** `incident_summary/1`.
  Phase 48 (COPY-02) owns everything else — `runbook_card`/`preview_panel` copy,
  `incident_timeline` empty state, cross-page microcopy, and the shared `_copy/1` helpers
  (≈1494-1560, already strongly on-voice — **do not churn them in 47**). Keep the operator
  register **neutral and blameless** — no apology, no "oops"/"something went wrong", no alarmist
  flavor (addresses the engineer recovering the system, not the affected customer).

### Motion — preview_panel reveal (MOTION-03)
- **D-13:** Add a **pure CSS `@keyframes po-preview-reveal`** (opacity 0→1 + `translateY(8px→0)`,
  compositor-only props) applied via a `.po-preview-reveal` class on the `preview_panel`
  container, driven by `animation: po-preview-reveal var(--motion-base) var(--motion-ease) both;`.
  A keyframe animation **auto-fires the instant the node is inserted** by LiveView's conditional
  render — no class toggle, no `display` change, **no JS**. `preview_panel` is a stateless `:html`
  function component diffed in/out by the parent LiveView, which is exactly why the keyframe
  approach fits.
- **D-14:** **Reject** `phx-mounted={JS.transition(...)}` (option c) and `@starting-style` +
  `allow-discrete` (option b). Not on dependency grounds (LiveView ships with the host) but
  architecturally: the keyframe needs no `display` toggle, no `JS` alias on a stateless
  component, and no client runtime. **No new reduced-motion rule needed** — the existing block
  (≈`operator_components.ex.eex:466-478`: `--motion-base: 0ms` + `.parapet-ui *
  { animation-duration: 0.01ms !important }`) already neutralizes it; document inline like the
  DATA-06 comment. **Interruptibility is free** — a one-shot opacity/transform reveal never gates
  pointer/`phx-click`, so Confirm/Cancel stay live mid-animation.

### Verification / test-gate strategy (cross-cutting)
- **D-15:** Follow the established **4-wave cadence** (mirrors Phases 45/46), **no new test
  files**: **47-01** red test scaffold (additive assertions to
  `test/parapet/operator_ui_contrast_test.exs`, asserted RED) → **47-02** template + demo-mirror
  markup edits flipping red→green → **(optional) 47-03** mirror any `operator_live` /
  `operator_detail_live` shell edits → **47-04** (`autonomous: false`) full-suite gate +
  audit-matrix flip + **blocking** human gallery walkthrough.
- **D-16:** Verify the N/A overlay requirements (GROUP-03/05/06, A11Y-05) as a **positive
  negative-guard, not silent omission**: in the paired `@component_paths` loop, `refute content
  =~ "role=\"dialog\""`, `refute "aria-modal"`, `refute "fixed inset-0"` (no full-screen scrim),
  **and** `assert "md:relative md:inset-auto"` + `assert aria-label="Close Recovery Preview"`
  (proves the disclosure shape). Matrix cells = `n/a`. These are **not** human-walkthrough items.
  (If a future edit adds `role="dialog"` without a focus-trap, the gate goes red.)
- **D-17:** Verify GROUP-02 + GROUP-04 as **literal string assertions** in the paired component
  loop (formula labels, audit-record copy, `disabled:opacity` / `aria-disabled`). Verify
  MOTION-03 with the existing MOTION-01/02 pattern (`assert "@keyframes po-preview-reveal"`,
  `assert "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"`, `refute
  "transition-all"`, plus the reduced-motion zeroing already asserted).
- **D-18:** Hold demo-mirror parity by **assertion-pairing** — every `.eex` edit is regenerated
  into its `examples/demo_app/.../*.ex` mirror **in the same task** so each `@*_paths` assertion
  moves together. Defer the literal byte-diff parity gate to **Phase 50**. Reserve the **human
  gallery walkthrough** (`/parapet/_gallery`) for genuinely-rendered cells only: 390px cockpit
  composition, preview-panel disclosure open/close + focus-to-close on mobile, and MOTION-03
  reveal feel.

### Claude's Discretion
- Exact `scroll-padding-bottom` value (D-02) — tune to the measured tallest sheet height.
- Whether to also add the optional Esc-to-cancel (`phx-window-keydown="cancel_preview"
  phx-key="escape"` — pure LiveView attr, keyboard parity only, not a conformance need).
- Exact icon glyphs for the risk / audit-outcome chips (D-07/D-08).
- Whether the live/detail shell edits warrant a separate wave `47-03` or fold into `47-02`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/44-foundations-token-re-skin-fonts-audit-apparatus/44-CONTEXT.md` — locked
  milestone mechanics (values-only re-skin, dual dark-theme blocks, demo-mirror byte-parity,
  motion tokens, off-palette gate, audit matrix as idempotence ledger).
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — the generated meta-components
  (`response_cockpit`, `incident_summary`, `runbook_card`, `preview_panel`, `action_rail`,
  `action_item_list`/`action_item_card`, `control_base`/`control_class`/`surface_class`/
  `chip_class`/`severity_color`/`state_color` helpers, motion tokens ≈109-111,
  prefers-reduced-motion block ≈466-478).
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` and `operator_detail_live.ex.eex` — page
  shells; `preview_panel` is conditionally mounted in `operator_detail_live` via
  `@incident.derived.active_preview`.
- `examples/demo_app/lib/demo_app_web/live/parapet/{operator_components,operator_live,operator_detail_live}.ex`
  — byte-parity demo mirrors; every template edit lands here in the same task.
- `test/parapet/operator_ui_contrast_test.exs` — the gate (paired `@component_paths` /
  `@live_template_paths` / `@detail_template_paths` loops; string + numeric-contrast assertions).
- `test/parapet/operator_ui_integration_test.exs` — route/IA/copy contract; `test/mix/tasks/parapet.gen.ui_test.exs` — generation-side assertions.
- `brandbook/notes/operator-audit-matrix.md` — component × state ledger (todo/done/verified/n-a).
- `brandbook/index.html` (voice formula ≈line 253), `brandbook/notes/accessibility.md`,
  `brandbook/notes/research.md`, `brandbook/tokens/tokens.css` (status triplets, motion tokens).
- `.planning/research/JTBD-MAP.md` — operator response/recovery JTBD (risk + audit-outcome needs).

The demo gallery audit route is `DemoAppWeb.Parapet.GalleryLive` at `/parapet/_gallery`
(demo-only; never generated into host UI).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Full status-triplet system already tokenized: `po-chip` + `po-chip-{success,warning,danger,
  info,neutral}` → `--po-chip-*-{bg,fg,border}` vars; `po-button-{primary,recovery,warning,
  destructive,success}` → `--po-button-*` vars. Helpers: `chip_class/2` (has `:state`/`:severity`/
  `:journey`/`:execution` clauses), `severity_color/1`, `state_color/1`, `control_class/2` (has an
  unused `:destructive` variant), `control_base()` (already ships `disabled:opacity-50
  disabled:cursor-not-allowed disabled:pointer-events-none` + `transition-transform
  duration-[--motion-fast]`).
- Motion infra: `--motion-fast` 120ms / `--motion-base` 200ms / `--motion-ease`
  `cubic-bezier(.2,0,0,1)`; global `prefers-reduced-motion` block zeros durations.
- Overflow hardening precedent: `incident_summary` already uses `whitespace-normal break-words`.
- `aria-disabled` + `tabindex=-1` shown-but-unavailable precedent: pagination in `operator_live`.

### Established Patterns
- **Re-skin mechanic (D-01 from Phase 44):** raw Tailwind palette utilities (`text-teal-*`,
  `bg-stone-*`, `bg-violet-50/50`, `text-amber-*`) flow through a utility-interception CSS layer
  (`.bg-stone-* → var(...)`) — markup classes stay put; only `:root`/dark var *values* change.
- **Wave-0 red-scaffold → green → gate + gallery walkthrough** cadence from Phases 45/46.
- **Demo-mirror parity by assertion-pairing** (paired `@*_paths` loops), not byte-diff (Phase 50).
- `preview_panel` is a stateless `Phoenix.Component` (`:html`) — it cannot alias `JS`; reveals
  must be CSS authored in its own markup.

### Integration Points
- `ActionItem` schema (`lib/parapet/spine/action_item.ex`) has only `state` (open/resolved) +
  `kind` (5 values) — risk + audit-outcome must be **derived in the component layer**, never via
  a schema/migration change.
- `preview_panel` mount/unmount is driven by `@incident.derived.active_preview` in
  `operator_detail_live` — a LiveView diff insert (relevant to the CSS-keyframe reveal choice).
</code_context>

<specifics>
## Specific Ideas

- Brand voice formula (verbatim, `brandbook/index.html:253`): **symptom → measured evidence →
  likely correlation → safe next action → where to inspect**; "Separate facts, hypotheses, and
  actions — never blur them." Does NOT sound: panicked, salesy, cute, macho, blameful.
- Ecosystem leanings folded in: GOV.UK (no modal by default; inline disclosure is the accessible
  default), Radix/Phoenix core_components (focus-trap belongs only to `modal=true`), GitLab
  Pajamas / Smashing (risk via redundant color+icon+label), Grafana OnCall (audit outcome = an
  explicit, visible state-change record), Kitty Giraudel / CSS-Tricks (`aria-disabled` over native
  `disabled` for discoverable gated controls), thinkdobecreate (keyframes auto-fire on insert),
  Atlassian/incident.io/Google SRE (impact-first, calm, blameless incident copy — operator-facing,
  not customer-apology register).
</specifics>

<deferred>
## Deferred Ideas

- A real modal/dialog pattern with scrim + focus-trap + Esc + restore — **out of scope
  permanently** for this UI unless a genuine modal surface is introduced (would need new JS and
  break the host-owned/no-new-dependency boundary).
- A "failed" audit-outcome state and any `risk`/`outcome` column on `ActionItem` — needs a future
  **API milestone** (telemetry/schema change is out of v1.6 bounds).
- Page-level microcopy, `runbook_card`/`preview_panel` copy, `incident_timeline` empty state, and
  shared `_copy/1` voice tuning — **Phase 48 (COPY-02)**.
- Literal byte-diff demo-mirror parity gate — **Phase 50 (PARITY)**.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
