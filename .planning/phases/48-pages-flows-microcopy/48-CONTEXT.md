# Phase 48: Pages, flows & microcopy - Context

**Gathered:** 2026-06-26 (assumptions mode + 6 parallel advisor-researcher deep-dives)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the **full operator flow navigable end-to-end** — response → actions → history →
incident-detail — with correct page semantics (one h1, ordered headings, landmarks, descriptive
page titles), **designed** empty/loading/error states, brand-voice microcopy, and complete mobile
usability at 390px. This is the user-facing payoff where the re-skinned primitives (Phase 45),
nav/shell/data-display (Phase 46), and meta-components (Phase 47) become a coherent, on-brand
console.

Requirements in scope: **FLOW-01..05, COPY-01..05, A11Y-06**.

**Fixed milestone boundaries (v1.6, inherited from Phases 44/47):** token/values-driven re-skin
with **only the minimal structural markup edits this phase's requirements demand** (heading-level
fixes, designed states, overflow hardening); **no public API or telemetry contract change** (one
*additive* failure-path helper is allowed — see D-01); UI stays **host-owned / generated** (real
templates in `priv/templates/parapet.gen.ui/*.eex`, byte-parity demo mirrors under
`examples/demo_app/lib/demo_app_web/live/parapet/*.ex`); **no new Parapet-owned runtime UI/JS
dependency**; brand/palette/logo locked. Every template edit lands in its demo mirror in the same
task. This phase clarifies HOW, never WHETHER to add capabilities.

**47/48 bright line (inherited):** Phase 47 owned `incident_summary/1` only. Phase 48 owns
everything else — page semantics, page titles, empty/loading/error states, not-found,
`runbook_card`/`preview_panel`/flash microcopy, mobile overflow. The pinned `_copy/1` helpers and
Phase-47 action-rail/risk/preview strings are **on-voice and test-pinned — do NOT churn them.**
</domain>

<decisions>
## Implementation Decisions

### A. Not-found / no-data incident detail (FLOW-03, FLOW-04, COPY-03)

**Root cause (verified):** `Parapet.Spine.Incident` uses `@primary_key {:id, :binary_id}`, so
`Evidence.repo().get!(Incident, id)` (`lib/parapet/operator.ex:117`) raises **two** distinct
failures on a stale `/parapet/:id` link — `Ecto.NoResultsError` (well-formed-but-missing UUID →
404 via phoenix_ecto) **and** `Ecto.Query.CastError` (malformed id, e.g. a typo or `/parapet/123`
→ **uncaught 500 with stack trace**). The malformed-id 500 is the more common stale-link/scanner
case and the real bug. **User decision: fix it with a designed not-found state.**

- **D-01:** Add an **additive** `Parapet.Operator.fetch_incident_detail/1 :: {:ok, detail} |
  {:error, :not_found}`. Precheck `Ecto.UUID.cast(id)` (collapses the `CastError` class), then
  `Repo.get` (not `get!`) + nil-guard (collapses the `NoResultsError` class) — both stale-link
  classes become one `{:error, :not_found}`. Keep the existing public `incident_detail/1`
  (`@doc since: "1.0.0"`) but make it nil-tolerant; **do NOT change its success-shape or
  signature** (additive failure-path only — no breaking change, no major-version bump). The
  generated `OperatorDetailLive` `mount`/`handle_params` and all **6 `handle_event` refresh
  sites** call the new fn and degrade to the not-found state if the incident vanished
  mid-action (real concurrent-resolve/prune case).
- **D-02:** Render a **designed in-page not-found panel** (new component in
  `operator_components.ex.eex` + demo mirror) that keeps operator nav, the back link, and brand
  chrome — **do NOT `push_navigate` away** and do NOT delegate to the host error page (operator
  stays oriented mid-incident). Zero host config. **Locked copy** (operator register, blameless):
  - Heading: `This incident isn't in the evidence store`
  - Body: `No durable incident matches this link. It may have been pruned by retention, or the
    link is stale. Active incidents stay in the response queue until resolved.`
  - Primary action: `Back to active response` → `@operator_base_path` (reuse `detail_back_*`)
  - Secondary action: `View resolved history` → `@operator_base_path <> "/history"`
  - Where to inspect (mono, de-emphasized): `Requested id: <%= @requested_id %>` — **render the
    requested id as escaped text only; never raw-interpolate untrusted URL input into attributes.**
- **D-03:** Distinguish the three FLOW-03 conditions honestly — **no-data = applicable** (the
  not-found panel above); **unavailable (infra) = N/A-by-design** (DB/process failure is genuinely
  the host's 5xx concern — do **NOT** rescue `DBConnection` errors into the not-found panel, that
  would mask an outage as "incident not found"); **permission-denied = N/A-by-design** (auth is
  host-owned — `router_snippet.ex.eex:2-3`; LiveViews are only reached post-authorization; the
  not-found panel must not imply authz).
- **D-04:** Keep the `/parapet/:id` catch-all route **declared LAST** (after `/parapet/actions`,
  `/parapet/history`, `/parapet/incidents/:id`) and keep the explanatory comment. Phoenix matches
  in declaration order; an earlier `:id` swallows `actions`/`history`/`_gallery` into the detail
  LiveView. Add a **router-ordering regression assert** (`index_of(content,
  ~S|/parapet/incidents/:id|) < index_of(content, ~S|/parapet/:id|)`) for snippet + demo router.

### B. Page semantics — single h1, page title, landmarks (FLOW-02, A11Y-06)

**Verified:** every rendered page emits **two `<h1>`s** — `operator_nav` "Active response
workbench" (`operator_components.ex.eex:543`, on all 4 pages) + `incident_summary`'s incident
title (`:840`). The generated LiveViews assign **no** `:page_title` (host owns `<.live_title>`;
demo hardcodes "Demo App" at `examples/demo_app/.../layouts.ex:12`). Existing landmarks are
already strong (skip link → `#parapet-main`, `<main tabindex="-1">`, `<header>`, `<nav
aria-label>`, `aria-current="page"`, labeled asides).

- **D-05:** Demote the **nav** `<h1>` "Active response workbench" → `<p class="po-operator-title">`
  — it's a persistent app/brand banner, not a page heading, and is identical on all 4 pages
  (an anti-pattern as a heading). The contrast-test refute (`text-white">Active response
  workbench`) is string-unaffected; no test asserts the `<h1>` tag.
- **D-06:** Give each page **exactly one distinct, descriptive h1** (FLOW-02 literal + WCAG 2.4.6):
  - **Response** → visually-hidden `<h1 class="sr-only">Active response</h1>` at the top of
    `<main>` (the incident is contextual, not the page subject; empty-state page also needs it).
  - **Actions** → visible `<h1>Action queue</h1>`.
  - **History** → promote the existing descriptive `<h2>` ("Review resolved incidents" /
    "Resolved history", `operator_live.ex.eex:161`) to `<h1>`; demote any now-conflicting sibling
    h2 to keep heading order monotonic.
  - **Detail** → the incident **is** the page subject, so `incident_summary` keeps `<h1>` **via a
    heading-level prop** (default `<h2>` when embedded in the Response cockpit at
    `operator_live.ex.eex:294`; detail passes `<h1>` at `operator_detail_live.ex.eex:228`). This
    is the one shared-component nuance — do not blanket-demote or the detail page loses its h1.
- **D-07:** **Page titles** — assign `:page_title` per `live_action` in `handle_params` (private
  `page_title/2` helper) in both `operator_live` and `operator_detail_live` (idiomatic Phoenix
  seam; auto-patches `document.title` on live nav). Strings (suffix ` · Parapet` applied by
  `live_title`): Response `Active response` · Actions `Action queue` · History `Resolved history`
  · Detail `Incident: <title>`. **Patch the demo layout** (`layouts.ex:12`) to
  `<.live_title suffix=" · Parapet">{assigns[:page_title] || "Demo App"}</.live_title>` so the
  gallery walkthrough proves titles at runtime. Add **one host-doc sentence** (install guide:
  "Parapet pages set `:page_title`; ensure your root layout's `<.live_title>` renders
  `{assigns[:page_title]}`"). **Do NOT auto-patch the host root layout** (host-owned seam).
- **D-08:** Landmark gap: wrap the detail-page back-link/context strip
  (`operator_detail_live.ex.eex:~215`, a bare `<div>` between `<header>` and `<main>`) in
  `<nav aria-label="Incident context">` so the back link isn't an orphan landmark. No other
  landmark changes needed.

### C. Empty / loading / error states (FLOW-03, FLOW-05)

**Honest LiveView model:** all Parapet data loads **synchronously in mount/handle_params** (no
`assign_async`/`Task`), so the only honest "loading" window is the dead-render → connected
upgrade. A spinner would be dishonest (data is already present). A `connected?`-keyed skeleton
exists for the Response queue only (`operator_live.ex.eex:33, 247-253`); Actions/History render
their lists directly and can flash an **empty state during load** — a lie ("nothing here" when the
truth is "still arriving").

- **D-09:** Loading = **skeleton-or-nothing, no spinners anywhere.** Extend the existing
  `connected?`-keyed skeleton **uniformly** to the Actions and History lists, identical
  `aria-busy={!@socket_connected}` + `aria-live="polite"` + `animate-pulse` wrapper with
  **matched row geometry** (`h-16` blocks = real row height → zero layout shift). Never bake a
  literal "Loading…" string (it would persist if the upgrade stalls — ARIA only). Reduced-motion
  is already neutralized (`operator_components.ex.eex:471`).
- **D-10:** **Gate every empty state on `@socket_connected and Enum.empty?(...)`** so an empty
  state never renders during the disconnected load (closes the empty-during-load lie on
  Actions/History).
- **D-11:** Standardize on **one empty-state anatomy** so the design system is internally
  consistent: decorative icon (`aria-hidden`, single line-weight, **never the sole carrier of
  meaning**) + `text-sm font-semibold` heading + token-colored guidance body + **optional single
  next-action link** (empty states are wayfinding moments, not dead ends) + dashed-border
  non-interactive token-driven container. **No `hover:`/`transition` on the non-interactive card**
  (the known v1.6 audit bug). Mobile-floored, **light/dark/system parity** — migrate the bare
  `text-stone-*` empties (`:781`, `:961`) to `--parapet-*` tokens. The cockpit all-clear (`:613`,
  "No active incidents need response.") stays a distinct **hero** variant (it's the desired
  resting state). Add a **History-empty** designed state. *(Extracting shared `<.empty_state>` /
  `<.list_skeleton>` components is recommended for consistency but extract-vs-inline is Claude's
  discretion as long as byte-parity holds.)*
- **D-12:** Document **unavailable** + **permission-denied** as named **N/A-by-Design** rows in
  `brandbook/notes/operator-audit-matrix.md` (grep proof: synchronous in-node repo reads;
  host-owned authz), reusing the Phase-47 GROUP-03/05/06 N/A convention — never a stubbed pane.

### D. Microcopy & voice (COPY-01..05)

**Verified:** COPY-04 already passes (no lorem/TODO/oops/"something went wrong"). The shared
`_copy/1` helpers (`operator_components.ex.eex:~1535-1774`) + Phase-47 action-rail/risk/preview
strings are on-voice and **pinned** by `operator_ui_integration_test.exs:186-196` — **excluded
from churn.** The job is dragging the outlier strings up to that bar.

- **D-13:** Re-author exactly these **10 strings (+ 1 harmonization)**; everything else kept.
  **Drop every `#{inspect(reason)}` from user-facing flashes** (keep `inspect` in `Logger` only):
  - `runbook_card` title fallback (`:1118`): `"Untitled runbook"`
  - `runbook_card` description fallback (`:1121`): `"No runbook description was recorded. Follow
    the steps below; each one previews before it runs."`
  - `preview_panel` line (`:1249`): `"This preview reflects scoped changes only — nothing has run.
    Confirm to execute, or close to discard."`
  - Flash ack fail (`detail_live:40`): `"Acknowledge didn't complete — no audit record was
    written. The incident is unchanged; refresh the timeline, then retry."`
  - Flash resolve fail (`:59`): `"Resolve didn't complete — the incident stays in its current
    state and no audit record was written. Refresh the timeline, then retry."`
  - Flash escalation fail (`:81`): `"Couldn't record the escalation request — no escalation was
    triggered. Refresh to confirm current status, then retry."`
  - Flash suppress fail (`:111`): `"Couldn't record the suppression — pending escalation is
    unchanged. Refresh current status, then retry."`
  - Invalid window (`:115`): `"Suppression window must be a whole number of minutes greater than
    zero."`
  - Flash preview fail (`:137`): `"Preview couldn't be generated — nothing has run and the
    incident is unchanged. Refresh the timeline, then retry."`
  - Flash confirm fail (`:181`, destructive path): `"Recovery did not execute — nothing was
    changed and no audit record was written. Refresh the timeline to confirm current state before
    retrying."`
  - Harmonize ack success (`:36`): `"Incident acknowledged. Audit record and timeline entry
    written."` (drops "successfully").
- **D-14:** **COPY-05** (risk + safe next step) is already satisfied on the **action** side by
  Phase-47 chips/bodies (acknowledge/resolve/escalate/suppress/preview/confirm each pair a risk
  frame + safe next step — keep, do not churn). The only gap was the **error** side, closed by
  D-13. **No new chips/action-rail churn.** **COPY-01** nav labels `Respond / Actions / History`
  kept (plain, least-surprise, verb/noun-coherent). **COPY-04** stays green.
- **D-15:** Planner **voice-consistency gate** (7 checks): (1) no `inspect` in user-facing flashes
  (Logger only); (2) no "Oops/Sorry/successfully/something went wrong/Failed to" bare-verb
  constructions; (3) every mutating-action error answers *what didn't happen + is state/audit
  unchanged? + safe next step*; (4) empty/fallback strings use the `"No X is recorded yet"`
  evidence-absence pattern (never blame absence); (5) domain nouns/verbs consistent (incident,
  evidence, runbook, **recovery** [not "mitigation" in operator copy], escalation, audit record,
  canonical timeline); (6) pinned `_copy/1` + Phase-47 strings still pass verbatim; (7) COPY-04
  grep clean.

### E. Mobile usability at 390px (FLOW-05)

Phases 45–47 already shipped the structural stacking + most overflow hardening. Residual is narrow
and **values/utility-only** — exactly right for a token audit.

- **D-16:** Apply these residual fixes (all in `operator_components.ex.eex` + demo mirror), by
  severity:
  - **R1 (High):** `preview_panel` bottom-sheet (`:1194/1196`) has **no height bound** — on a short
    viewport (landscape / on-screen keyboard) the warnings + Confirm/Close can clip, **blocking a
    live recovery action**. Add `max-h-[100dvh]` to the wrapper and `max-h-[calc(100dvh-2rem)]
    overflow-y-auto overscroll-contain` to the inner card. *(The DATA-02 `overflow-y-auto` refute
    is scoped to `@live_template_paths` only — `preview_panel` lives in components, so this is
    permitted; planner must confirm the gate scope.)*
  - **R2:** `action_item_card` id (`:1370`, `integration:external_id`) → wrap value in
    `<span class="break-all font-mono">`; header flex gets `min-w-0`.
  - **R3:** `preview_panel` data grid (`:1205`, unconditional `grid-cols-2`) →
    `grid-cols-1 sm:grid-cols-2`; value `<p>`s get `min-w-0 break-words`.
  - **R4:** suspect-changes flag chip (`:1044`, `font-mono`) → add `break-all min-w-0`.
  - **R5:** runbook step text wrapper (`:1128`, `flex-1`) → `flex-1 min-w-0`; `<h4>`/`<p>` get
    `break-words`; verify the button column is `shrink-0`.
  - **R6/R7 (verify-only):** `incident_row` `truncate` (`:819/821`) — keep, full value is reachable
    on the detail page; `incident_summary` trace span (`:876`) → add `break-all min-w-0` to match
    the timeline-link convention (`:999`).
  - **Touch targets (verify-then-fix):** controls already clear WCAG 2.5.8 (24×24) — buttons
    `min-h-[40px]`, theme options `min-h-[32px]`. **Do not blanket-pad** display chips/badges
    (non-interactive). Only raise a genuine sub-24px *interactive* element if the visual audit
    flags one.
- **D-17:** Adopt the **9-point overflow/responsive checklist** as the design-system "390px gate"
  (pays dividends in Phase 49 stress fixtures): `min-w-0` on every flex/grid text child;
  `break-all` for machine strings (IDs/UUIDs/hashes/module names/URLs) vs `break-words` for prose;
  `truncate` only when the full value is reachable elsewhere; no unconditional multi-column grids
  (collapse to `grid-cols-1` at base); bound fixed/sticky sheet height (`max-h` + `overflow-y-auto
  overscroll-contain`); `tabular-nums font-mono` spans are break candidates; the variable-text
  sibling in a `justify-between` row is `shrink-0`; no `whitespace-nowrap` on long content; genuine
  controls ≥24×24, chips exempt. **Zero horizontal scroll at 390px** — fix vertically, never
  `overflow-x-auto` a table.

### F. Test-gate strategy (cross-cutting — FLOW/COPY/A11Y verification)

Split **by fact-type**: template-text facts → source-string paired loops; rendered-state facts →
the **existing** demo `Phoenix.LiveViewTest` harness. **No new test files.**

- **D-18:** Assertion routing:
  - **Source-string** (existing `operator_ui_contrast_test.exs` / `operator_ui_integration_test.exs`
    paired `@*_paths` loops): COPY-01..05 literal pins (reuse the `:186-196` verbatim style);
    **COPY-04** bounded-regex refutes — `~r/\b(TODO|FIXME|XXX|HACK)\b/`, `~r/\blorem ipsum\b/i`,
    `~r/placeholder text/i` (**not** bare `/placeholder/i` → matches `placeholder=` attrs, **not**
    bare `/todo/i` → matches "today"); **A11Y-06** attribute presence (`id="parapet-main"`, nav
    landmark + `aria-label`, `aria-current`); **FLOW-01/04** route presence + ordering (`index_of`,
    D-04); **FLOW-02** `:page_title` *assign* presence (source).
  - **Rendered** (existing `examples/demo_app/test/.../operator_smoke_test.exs`, `ConnCase` +
    Ecto sandbox, seeded per-test): **FLOW-02 single-h1** — `assert
    length(Regex.scan(~r/<h1[\s>]/, html)) == 1` for **each** rendered page (`/parapet`,
    `/parapet/actions`, `/parapet/history`, detail, and the queue-with-selected-incident). **NOT
    a source grep** (2 legit h1 *definitions* compose onto one page — a grep is structurally
    blind) and **NOT Floki** (it's not a dep; the DOM backend is `lazy_html`; `element/2` raises on
    >1 match so it can't count). **page_title** — `assert page_title(view) =~ ...` (reads the
    assign the host `<.live_title>` consumes; never assert the host `<title>` string). **FLOW-03**
    — empty (`/parapet/history` with no resolved incidents seeded), not-found (`live(conn,
    "/parapet/incidents/#{Ecto.UUID.generate()}")` → designed not-found copy), disconnected
    skeleton (`get/2` static render `=~` skeleton). One rendered A11Y cross-check
    (`has_element?(view, "main#parapet-main")`, `nav[aria-label]`).
- **D-19:** **4-wave cadence** mirroring Phase 47, no new test files:
  - **48-01** RED scaffold — additive source asserts (contrast/integration loops) **and** demo
    render asserts (`operator_smoke_test.exs`), asserted **RED**.
  - **48-02** green — template + demo-mirror edits in the **same task** (D-18 pairing): h1
    demotion/promotion + heading-level prop, `:page_title` assigns + demo layout patch, designed
    empty/loading/not-found states, the 10+1 microcopy strings, R1–R7 overflow fixes, landmark
    nav wrap. Flip red→green in `.eex` **and** `examples/demo_app/.../*.ex` together.
  - **48-03** (optional) shell mirror — only if `operator_live`/`operator_detail_live` shell edits
    warrant a separate wave; else fold into 48-02.
  - **48-04** (`autonomous: false`) — full-suite gate (**lib `mix test` + demo `mix test`**) +
    audit-matrix flip + **blocking** human `/parapet/_gallery` walkthrough. Human-only items:
    copy reading-flow at 390px (does symptom→evidence→action read calmly), heading-hierarchy
    legibility after the h1 demotion, empty-state *feels designed not broken*, keyboard
    focus-visibility of skip-link/nav. Everything else is automated.

### Claude's Discretion
- Extract shared `<.empty_state>` / `<.list_skeleton>` components vs inline (D-11) — byte-parity
  holds either way.
- Fold the shell edits into 48-02 vs a separate 48-03 wave (D-19).
- Exact `sr-only` vs visible phrasing per page h1, and exact icon glyphs for empty/not-found states.
- Exact `max-h` calc offset for the bottom sheet and the precise break utility per long-string site.
- Optional `aria-labelledby` tying `<main>` to its h1 (belt-and-suspenders once single-h1 lands).
- Optional `incident_summary` `as` prop name for the heading-level variant.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/47-component-groups-meta-components/47-CONTEXT.md` and
  `.planning/phases/44-foundations-token-re-skin-fonts-audit-apparatus/44-CONTEXT.md` — locked
  milestone mechanics (values-driven re-skin, demo-mirror byte-parity via assertion-pairing,
  motion tokens, N/A-by-design convention, audit matrix as idempotence ledger, 4-wave cadence).
- `lib/parapet/operator.ex` (`incident_detail/1` ~112-152; the `get!` → `fetch_incident_detail/1`
  fix, D-01) and `lib/parapet/spine/incident.ex` (binary_id PK ~line 27 — root cause of the
  dual-exception not-found bug).
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — `operator_nav` (h1 `:543`),
  `incident_summary` (h1 `:840`, heading-level prop), empty states (`:613, 728, 781, 884, 961,
  1025, 1322`), `runbook_card` (`:1118/1121`), `preview_panel` (`:1194-1310`), `action_item_card`
  (`:1370`), risk chips (`:1386-1401`), `_copy/1` helpers (`~1535-1774`, pinned — do not churn),
  reduced-motion block (`:471`).
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — page_mode/live_action shells, skeleton
  (`:33, 247-253`), History heading (`:161`), empty detail (`:307-318`), `handle_params`
  (page_title assign site).
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — mount/handle_params + 6
  handle_event refresh sites (`:10-192`), flash strings (`:40, 59, 81, 111, 115, 137, 181`),
  context bar (`:215`), main/aside landmarks (`:224, 237`), `detail_back_*` (`:261-299`).
- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` (routes `:16-17`, `:id` catch-all last) and
  `examples/demo_app/lib/demo_app_web/router.ex` (mirror `:30-31`).
- `examples/demo_app/lib/demo_app_web/components/layouts.ex` (`:12` hardcoded `<.live_title>` —
  patch per D-07) and the four byte-parity mirrors under
  `examples/demo_app/lib/demo_app_web/live/parapet/*.ex`.
- `test/parapet/operator_ui_contrast_test.exs` (paired `@*_paths` loops, scroll-pb gate `:248`,
  DATA-02 `overflow-y-auto` refute scoped to live templates `:276`),
  `test/parapet/operator_ui_integration_test.exs` (route/IA/copy contract, `index_of/2` helper,
  verbatim copy pins `:186-196`), and `examples/demo_app/test/.../operator_smoke_test.exs` +
  `operator_components_render_test.exs` (the rendered `Phoenix.LiveViewTest` harness for FLOW-02/03).
- `brandbook/notes/operator-audit-matrix.md` (component × state ledger; N/A-by-design rows),
  `brandbook/index.html` (voice formula ~line 253), `brandbook/notes/accessibility.md`,
  `brandbook/notes/research.md`.
- `.planning/research/JTBD-MAP.md` (solo-operator response/recovery JTBD), `prompts/` deep-research
  (`sre-best-practices-solo-founder-deep-research.md`, `parapet-engineering-dna-from-sibling-libs.md`)
  and `prompts/prior-art/` (chimeway host-app seam, threadline audit domain).

The demo gallery audit route is `DemoAppWeb.Parapet.GalleryLive` at `/parapet/_gallery`
(demo-only; never generated into host UI).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Disconnected skeleton** already proven on the Response queue (`operator_live.ex.eex:247-253`,
  `connected?`-keyed, `animate-pulse`, `aria-busy`) — extend uniformly, matched geometry.
- **Four on-voice empty states** + the cockpit all-clear hero — already "designed not blank";
  standardize anatomy + token-migrate the two bare `text-stone-*` ones.
- **`detail_back_label`/`detail_back_path` helpers** (`operator_detail_live.ex.eex:261-299`) —
  reuse for the not-found panel actions.
- **`index_of/2` test helper** (`operator_ui_integration_test.exs`) — reuse for route-ordering.
- **`Phoenix.LiveViewTest` + `ConnCase` demo harness** already CI-wired
  (`operator_smoke_test.exs` boots `/parapet`, `/parapet/history`, `/parapet/incidents/:id`
  against an Ecto sandbox) — the seam for FLOW-02/03 rendered asserts.
- Phase-47 risk chips + action-rail risk/safe-next-step copy already satisfy COPY-05's action side.

### Established Patterns
- **Token/values re-skin** (D-01 from Phase 44): palette utilities flow through a CSS
  interception layer; markup classes stay, only var *values* change. Phase 48 adds only the
  minimal structural markup its requirements demand.
- **Demo-mirror parity by assertion-pairing** (not byte-diff — that's Phase 50): every `.eex` edit
  lands in its `examples/demo_app/.../*.ex` mirror in the same task.
- **N/A-by-Design exception** convention (Phase 47 GROUP-03/05/06) for documenting intentional
  absence with grep proof in the audit matrix — reused for `unavailable`/`permission-denied`.
- **`assign(:page_title)` in `handle_params`** is the idiomatic LiveView seam; `<.live_title>` is
  host-owned (LiveDashboard/Oban Web convention).

### Integration Points
- `incident_detail/1` is public (`@doc since: "1.0.0"`) → the not-found fix is **additive**
  (`fetch_incident_detail/1`), not a breaking return-shape change.
- `incident_summary/1` is shared by the Response cockpit (embedded, `<h2>`) and the detail page
  (subject, `<h1>`) → heading level must be a **prop**, default `<h2>`.
- Demo layout `<.live_title>` is hardcoded "Demo App" → must be patched or the gallery can't prove
  page titles.
- DOM backend is `lazy_html` (Floki is **not** a dependency) → count h1 via regex, not `Floki.find`.
</code_context>

<specifics>
## Specific Ideas

- **Brand voice formula** (verbatim, `brandbook/index.html:253`): symptom → measured evidence →
  likely correlation → safe next action → where to inspect. Operator register (addresses the
  engineer recovering the system, not the affected customer): calm, blameless, evidence-first.
  Never: panicked, salesy, cute, macho. Banned flavor: "oops", "something went wrong", "nothing to
  show", "war room", "single pane of glass", "autopilot", 🔥, "successfully" as filler.
- **`Repo.get!` + binary_id dual-failure footgun:** well-formed-missing UUID → `NoResultsError`
  (404); malformed id → `Ecto.Query.CastError` (uncaught **500**). The designed not-found state
  must absorb both via `Ecto.UUID.cast/1` precheck + `Repo.get` nil-guard.
- **Ecosystem leanings folded in:** LiveDashboard/Oban Web (server-rendered tables, no client
  spinners; centralized missing-resource handling; card+`divide-y` lists over `<table>` for mobile);
  GOV.UK ("what, then service" title order; inline disclosure default); Linear/incident.io (empty
  states as wayfinding with a single next-action link); Grafana (no-data visually distinct from
  query-error); incident.io/PagerDuty/Stripe/Google SRE (blameless, state-unchanged-first error
  copy; no `inspect` leaks; no apology spam).
</specifics>

<deferred>
## Deferred Ideas

- A real modal/dialog/scrim/focus-trap surface — permanently out of scope (Phase 47 N/A-by-design).
- A "failed" audit-outcome state or any `risk`/`outcome` column on `ActionItem` — future **API
  milestone** (schema/telemetry change is out of v1.6 bounds).
- Literal byte-diff demo-mirror parity gate, off-palette-hex gate, motion assertion, screenshot
  baseline manifest — **Phase 50** (guardrails/parity/idempotence gate).
- Stress fixtures (long-string/empty/max-items/mixed-status scenarios wired to
  `PARAPET_DEMO_SCENARIO`) and gallery screenshot capture — **Phase 49** (Phase 48's 390px
  checklist + the not-found/empty states are the worst-case data those fixtures will exercise).
- Automated browser a11y/interaction testing (Playwright + axe-core) — deferred post-v1.6
  (this phase verifies a11y via source asserts + the rendered LiveViewTest harness + a blocking
  human gallery walkthrough, no browser-automation dependency).
- Async `assign_async` data loading (which would introduce a genuine post-mount loading state) —
  not in scope; the synchronous model makes skeleton-or-nothing the honest loading affordance.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
