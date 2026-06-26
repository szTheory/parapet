# Phase 46: Navigation, Shell & Data-Display — Research

**Researched:** 2026-06-25
**Domain:** Phoenix EEx template composition + ARIA landmarks + keyboard accessibility + data-degradation patterns
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-01 | Tabs and nav items show an unambiguous active state with `aria-current="page"` in both themes | `.po-nav-active` CSS rule (line 330) currently has color+bg only; need `border-bottom: 2px solid var(--parapet-accent)` rule added. `nav_item/1` (line 617) already sets `aria-current="page"` and `po-nav-active` class — CSS is the only gap |
| NAV-02 | The app shell (header/nav/theme switcher) is usable at 390px with no horizontal overflow | Current `operator_nav/1` (line 505) uses `flex flex-col gap-3` on mobile — already correct. Three nav items use `flex flex-wrap gap-2` (line 513) — already correct. Queue-refresh notification (line 206) still uses raw `bg-teal-50` — must update per DATA spec |
| NAV-03 | The Light/Dark/System switcher retains its `localStorage` + `data-parapet-theme` behavior and meets AA contrast | Theme switcher JS (lines 473–498) is locked. `theme_control/1` (line 524) already uses `po-theme-option po-focus` — no behavioral change; Phase 46 only verifies focus order participates correctly per NAV-05 |
| NAV-04 | Navigation and IA labels follow least-surprise, plain-language (GOV.UK-style) naming | Current labels verified: "Respond"/"Actions"/"History" (lines 514–516), queue scope labels, detail context labels — all acceptable per UI-SPEC; NO changes required |
| NAV-05 | Keyboard users have a logical landmark structure and a working skip-to-content affordance | No skip-link exists today (confirmed by reading all three templates). `<main>` elements in `operator_live.ex.eex` (lines 125, 139, 196) and `operator_detail_live.ex.eex` (line 218) have no `id="parapet-main"`. The `<aside>` in detail page (line 231) needs `aria-label="Incident actions"` |
| DATA-01 | Incident list/rows and tables truncate or wrap long fields deliberately | `incident_row/1` (line 758) already uses `min-w-0 flex-1` + `truncate` on title/secondary_line + `shrink-0` on timestamp — patterns are correct; Phase 46 confirms no changes needed here |
| DATA-02 | Lists/tables with internal scroll regions scroll correctly, no trapped or nested-scroll dead-ends | No `overflow-y-auto` on incident list or timeline (confirmed by reading templates) — page scroll is correct; Phase 46 adds NO new scroll regions per UI-SPEC contract |
| DATA-03 | The incident timeline renders bounded fields and degrades gracefully with zero, few, and many entries | `incident_timeline/1` (line 915) currently has NO empty-state branch — the `<ul>` renders empty. Final timeline entry spine (`<span class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-stone-200">`) shows on last item — needs suppression |
| DATA-04 | Empty states are designed (icon + explanatory copy + next action) and carry no hover/pointer affordance | Three empty states need ICONS added: `incident_list/1` empty branch (line 744), `action_center/1` empty branch (line 696), cockpit no-selection branch (operator_live.ex.eex line 281). Timeline needs a new empty-state branch. All have correct copy already |
| DATA-05 | Status and severity conveyed by text and/or icon in addition to color (color-blind-safe) | Already implemented: chip text IS the signal, badge letters supplement. No color-only status display found. Queue-row selected state uses `border-l-4` via `po-queue-row-selected` (line 436) — already has shape indicator |
| DATA-06 | Loading/skeleton states are reduced-motion-safe and do not cause layout jumps | No skeleton/loading state currently exists in any template. `prefers-reduced-motion` block (lines 460–471) already zeros `animate-pulse`. Phase 46 adds skeleton ONLY to the incident queue list container in `operator_live.ex.eex` |
| A11Y-03 | Every interactive element is keyboard-reachable with a visible focus indicator | `pagination_link_class/1` (line 468) does NOT include `po-focus` for enabled links — this is the primary gap. Skip-to-content link is new (NAV-05). All other interactive elements already carry `po-focus` |
| A11Y-04 | Tab order is logical with no keyboard traps | DOM order provides correct tab order naturally; only fix is `tabindex="-1"` on disabled pagination `<.link>` elements and optional `tabindex="-1"` on `<main id="parapet-main">` target. No focus traps in Phase 46 scope |
</phase_requirements>

---

## Summary

Phase 46 is a surgical composition + behavior pass on three Phoenix EEx templates (and their byte-mirror counterparts), building directly on the tokenized CSS foundation from Phases 44/45. The templates are already well-structured — the majority of Phase 46 work is small, targeted additions rather than structural changes.

The critical findings from reading the actual templates:

1. **NAV-01 gap is CSS-only.** The `nav_item/1` component (line 617) already emits `aria-current="page"` and the `.po-nav-active` class. The only missing piece is a `border-bottom: 2px solid var(--parapet-accent)` rule in the `.po-nav-active` CSS block (line 330). One CSS rule addition — no markup change needed.

2. **NAV-05 requires three parallel insertions.** No skip-to-content link exists anywhere today. The `<main>` elements in `operator_live.ex.eex` have three branches (`:actions`, `:history`, `:response`) each needing `id="parapet-main"`. `operator_detail_live.ex.eex` has one `<main>` to update. The skip-link itself goes as the first child of `.parapet-ui` in each live template.

3. **DATA-03 has two concrete gaps.** Timeline has no empty-state branch (the `<ul role="list">` simply renders empty). The CSS connector-spine suppression for the last `<li>` is also absent.

4. **DATA-04 has three empty-state icon gaps.** The incident queue empty state (line 744), action-items empty state (line 696), and cockpit no-selection empty state (operator_live line 281) all have text but no icon. The timeline adds a new empty-state branch entirely.

5. **A11Y-03 gap: pagination `po-focus` missing.** The `pagination_link_class(true)` function (line 468–469) returns ring and color utilities but not `po-focus`. This must be added so enabled pagination links show the correct tokenized focus ring.

6. **NAV-02 queue-refresh notification color gap.** The `queue_refresh_available?` notification block (operator_live line 206) still uses `bg-teal-50` and `text-teal-950` — UI-SPEC requires `bg-[color:var(--parapet-accent-soft)] ring-1 ring-[color:var(--parapet-border)]` container + `var(--parapet-text)` text.

7. **Byte-parity is the top operational risk.** Every change to any of the three template files must be applied byte-identically to its demo mirror immediately. The Phase 50 GUARD-03 test will enforce this; Phase 46 must not create drift.

**Primary recommendation:** Group work by template file and process template + demo mirror as an atomic pair in each commit. Run `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs` after each pair. The contrast test already reads both `@component_paths` and `@live_template_paths` so it serves as a continuous parity check.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Nav active indicator (border) | CSS rule in `operator_theme_bootstrap/1` | — | CSS class rules live in the bootstrap; markup already emits correct class |
| Skip-to-content link markup | EEx template LiveView render/1 | Demo mirror `.ex` files | Markup addition to both operator_live and operator_detail_live |
| `id="parapet-main"` attributes | EEx template LiveView `<main>` elements | Demo mirrors | Three branches in operator_live, one in operator_detail_live |
| Skip-link CSS (`.po-skip-link` or inline Tailwind) | CSS rule in `operator_theme_bootstrap/1` | — | Focus-visible style needs the theme's `--parapet-panel` and `--parapet-accent` |
| Timeline empty-state markup | `operator_components.ex.eex` `incident_timeline/1` | Demo mirror | New conditional branch wrapping the `<ul>` |
| Timeline last-entry spine suppression | CSS rule in `operator_theme_bootstrap/1` | — | CSS selector approach is cleaner than conditional markup |
| Empty-state icon additions | `operator_components.ex.eex` empty branches | Demo mirror | Three `<svg aria-hidden="true">` additions in existing empty branches |
| Pagination `po-focus` class | `operator_live.ex.eex` `pagination_link_class/1` function | Demo mirror | Private function returns class string — one-line add |
| Queue-refresh notification color | `operator_live.ex.eex` notification container | Demo mirror | Replace `bg-teal-50 ring-stone-300 text-teal-950` with tokenized variants |
| `aria-label` on `<aside>` | `operator_detail_live.ex.eex` aside element | Demo mirror | One attribute addition |
| Skeleton markup (incident queue) | `operator_live.ex.eex` `:response` branch | Demo mirror | Wrapping `aria-live="polite"` + skeleton pattern |
| Test assertions (NAV/DATA/A11Y) | `operator_ui_contrast_test.exs` | — | Extend existing test file; no new test files |

---

## Standard Stack

No new library or package dependencies for Phase 46. The entire implementation uses:

- Phoenix HEEx (already a project dependency) [VERIFIED: in-use throughout all three templates]
- Tailwind CSS (already compiled into demo app) [VERIFIED: all templates use Tailwind utility classes]
- ExUnit (already the test framework) [VERIFIED: `operator_ui_contrast_test.exs` and `operator_ui_demo_contract_test.exs` exist]
- CSS Custom Properties (native browser feature) [VERIFIED: used in `operator_theme_bootstrap/1`]

**Installation:** No `mix deps.get` or `npm install` needed for Phase 46.

---

## Package Legitimacy Audit

No external packages are introduced in Phase 46.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | N/A |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious SUS:** none

---

## Architecture Patterns

### System Architecture Diagram

```
operator_live.ex.eex ─────────────────────────────────────┐
  render/1                                                 │
    [skip-to-content link]  ← NEW (NAV-05)                │
    <.operator_nav />       ← UNCHANGED (nav_item/1 already│
    <main id="parapet-main">← ADD id= (NAV-05)            │  templates
      :actions branch ───── <main> needs id=              │  (source)
      :history branch ────── <main> needs id=             │
      :response branch                                     │
        [queue-refresh notification] ← color fix (NAV-02) │
        incident list with            ← aria-live wrapper  │
          skeleton OR content         ← DATA-06            │
        pagination ← pagination_link_class add po-focus    │
                                                           │
operator_detail_live.ex.eex                               │
  render/1                                                 │
    [skip-to-content link]  ← NEW (NAV-05)                │
    <.operator_nav />                                      │
    [cockpit-detail sub-header]                            │
    <main id="parapet-main">← ADD id= (NAV-05)            │
    <aside aria-label="Incident actions"> ← ADD aria-label │
                                                           │
operator_components.ex.eex                                │
  operator_theme_bootstrap/1 <style>                       │
    .po-nav-active { border-bottom: ... } ← NAV-01        │
    .po-timeline-list li:last-child ... { display: none }  │
         ← spine suppression DATA-03                      │
  incident_list/1                                          │
    empty branch ← ADD svg icon (DATA-04)                 │
  action_center/1                                          │
    empty branch ← ADD svg icon (DATA-04)                 │
  incident_timeline/1                                      │
    NEW: empty-state branch ← DATA-03/04                  │
    ul.po-timeline-list class added                        │
         ─────────────────────────────────────────────────┘
                 │ byte-mirror (every change)
                 ▼
examples/demo_app/lib/demo_app_web/live/parapet/
  operator_live.ex          (mirror)
  operator_detail_live.ex   (mirror)
  operator_components.ex    (mirror)

test/parapet/operator_ui_contrast_test.exs
  ← EXTEND: NAV-01 assert po-nav-active border
  ← EXTEND: NAV-05 assert skip-link, id="parapet-main"
  ← EXTEND: A11Y-03 assert pagination po-focus
  ← EXTEND: DATA-03 assert timeline empty state
  ← EXTEND: DATA-06 assert aria-live/aria-busy pattern
  ← EXTEND: refute bg-teal-50 in @live_template_paths
```

### Recommended Project Structure (no change)

```
priv/templates/parapet.gen.ui/
├── operator_components.ex.eex   # CSS rules + incident_timeline + empty-state icons
├── operator_live.ex.eex         # skip-link, <main id>, pagination, queue-refresh fix
└── operator_detail_live.ex.eex  # skip-link, <main id>, aside aria-label

examples/demo_app/lib/demo_app_web/live/parapet/
├── operator_components.ex   # byte-mirror of above
├── operator_live.ex         # byte-mirror of above
└── operator_detail_live.ex  # byte-mirror of above

test/parapet/
└── operator_ui_contrast_test.exs  # new Phase 46 assertions added to existing tests
```

### Pattern 1: Adding CSS Rule to `.po-nav-active` (NAV-01)

**What:** Add `border-bottom` shape indicator to the existing `.po-nav-active` CSS rule in `operator_theme_bootstrap/1`.
**When to use:** Active nav items need a non-color visual indicator.

Current rule (line 330 of `operator_components.ex.eex`):
```css
/* CURRENT — color+bg only, no shape indicator */
.parapet-ui .po-nav-active {
  background: var(--po-nav-active-bg);
  color: var(--po-nav-active-fg);
}
```

Replace with:
```css
/* NAV-01 fix: add shape indicator */
.parapet-ui .po-nav-active {
  background: var(--po-nav-active-bg);
  color: var(--po-nav-active-fg);
  border-bottom: 2px solid var(--parapet-accent);
}

/* No dark override needed — --parapet-accent already overrides to #7FB4C6 in dark blocks */
```

Note: No need to add dark-block overrides for the border because `var(--parapet-accent)` is already overridden to `#7FB4C6` in both dark blocks. The cascade handles this automatically.

### Pattern 2: Skip-to-Content Link (NAV-05)

**What:** Add skip-link as first child of `.parapet-ui` in each LiveView `render/1` function.
**When to use:** Both `operator_live.ex.eex` and `operator_detail_live.ex.eex`.

```heex
<%!-- First child inside <div class="parapet-ui ..."> --%>
<a
  href="#parapet-main"
  class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50
         flex min-h-[40px] items-center rounded-lg px-4 py-2 text-sm font-semibold
         bg-[color:var(--parapet-panel)] text-[color:var(--parapet-accent)]
         focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
>
  Skip to main content
</a>
```

In `operator_live.ex.eex` (current line 121): insert immediately after `<div class="parapet-ui antialiased flex min-h-screen flex-col bg-stone-100 text-stone-900">`.

In `operator_detail_live.ex.eex` (current line 206): insert immediately after `<div class="parapet-ui antialiased flex min-h-screen w-full max-w-full flex-col overflow-x-hidden bg-stone-100 text-stone-900">`.

### Pattern 3: `id="parapet-main"` on `<main>` Elements (NAV-05)

**What:** Add `id="parapet-main"` to all `<main>` elements. Optionally add `tabindex="-1"` so programmatic focus from skip-link works.

In `operator_live.ex.eex` there are THREE `<main>` elements (one per page mode branch):
- Line 125: `:actions` branch `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">`
- Line 139: `:history` branch `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">`
- Line 196: `:response` branch `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">`

All three become: `<main id="parapet-main" tabindex="-1" class="...">`

In `operator_detail_live.ex.eex`:
- Line 218: `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">` becomes `<main id="parapet-main" tabindex="-1" class="...">`

### Pattern 4: Timeline Empty State + Spine Suppression (DATA-03)

**What:** Wrap the `<ul>` in `incident_timeline/1` with an empty-state conditional; add CSS to suppress the last entry's spine.

Current `incident_timeline/1` structure (line 915–960): bare `<div class="flow-root"><ul role="list" class="-mb-8">`. No empty branch.

Replace:
```heex
<div class="flow-root">
  <%= if Enum.empty?(timeline_entries) do %>
    <div class="flex min-h-[12rem] items-center justify-center text-center px-4 py-8">
      <div>
        <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p class="text-sm font-semibold" style="color: var(--parapet-text);">No timeline entries yet</p>
        <p class="mt-1 text-sm" style="color: var(--parapet-text-muted);">
          Evidence and operator actions will appear here as they are recorded.
        </p>
      </div>
    </div>
  <% else %>
    <ul role="list" class="po-timeline-list -mb-8">
      <%%= for item <- timeline_entries do %>
        ...existing loop...
      <%% end %>
    </ul>
  <% end %>
</div>
```

Note: The `timeline_entries` variable needs to be extracted before the conditional (it's already computed in the existing template at line 919 as `timeline_entries = @detail.timeline_entries || ...`). Extract this assignment before the conditional.

CSS spine suppression rule (add to `operator_theme_bootstrap/1`):
```css
/* DATA-03: Hide connector spine on the last timeline entry */
.parapet-ui .po-timeline-list > li:last-child > div > span[aria-hidden="true"] {
  display: none;
}
```

### Pattern 5: Empty-State Icon Addition (DATA-04)

**What:** Add a decorative `<svg aria-hidden="true">` before the heading in each existing empty-state container.

**`incident_list/1` empty branch (line 744)** — add before `<p class="text-sm font-semibold ...">`:
```html
<svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
  <path stroke-linecap="round" stroke-linejoin="round"
    d="M2.25 13.5h3.86a2.25 2.25 0 012.012 1.244l.256.512a2.25 2.25 0 002.013 1.244h3.218a2.25 2.25 0 002.013-1.244l.256-.512a2.25 2.25 0 012.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 00-2.15-1.588H6.911a2.25 2.25 0 00-2.15 1.588L2.35 13.177a2.25 2.25 0 00-.1.661z" />
</svg>
```

The containing `<div>` must be updated from `px-4 py-6 text-center` to include a min-height and proper layout:
```html
<div class="px-4 py-8 text-center">
  [icon]
  <p class="text-sm font-semibold text-stone-800">No active incidents</p>
  ...
</div>
```

**`action_center/1` empty branch (line 696)** — currently `<div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">`, add inbox SVG icon before heading.

**Cockpit no-selection empty state (operator_live.ex.eex line 281)** — currently `<div class="max-w-md rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">`, add cursor-click SVG icon.

**Empty-state container rule:** None of these containers should have `cursor-pointer` or `hover:bg-*`. The existing ones do not — preserve this.

### Pattern 6: Pagination `po-focus` Addition (A11Y-03)

**What:** Add `po-focus` to the enabled branch of `pagination_link_class/1`.

Current (operator_live.ex.eex line 468–472):
```elixir
defp pagination_link_class(true),
  do: "ring-1 ring-stone-300 bg-white text-stone-900 hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)]"

defp pagination_link_class(false),
  do: "pointer-events-none ring-1 ring-stone-200 bg-stone-100 text-stone-400"
```

Replace:
```elixir
defp pagination_link_class(true),
  do: "ring-1 ring-stone-300 bg-white text-stone-900 hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"

defp pagination_link_class(false),
  do: "pointer-events-none aria-disabled:true tabindex:-1 ring-1 ring-stone-200 bg-stone-100 text-stone-400"
```

Note: For disabled pagination `<.link>` elements, use `aria-disabled="true"` and `tabindex="-1"` in the markup (not the class string, since Tailwind cannot set HTML attributes). The planner must add these as attributes on the `<.link>` element when `!@queue_page.has_previous_page?` etc. Actually, the correct approach: pass `aria-disabled` and `tabindex` as explicit attributes on the `<.link>` tag, not via the class function. The class function returns styling only; add disabled pagination attributes in the template call sites.

Updated pattern for disabled pagination links:
```heex
<.link
  patch={queue_page_path(...)}
  aria-disabled={unless @queue_page.has_previous_page?, do: "true"}
  tabindex={unless @queue_page.has_previous_page?, do: "-1"}
  class={[
    "flex min-h-[40px] items-center justify-center rounded-lg px-3 py-2 text-sm font-semibold transition-transform duration-[--motion-fast] ease-out active:scale-[0.96]",
    pagination_link_class(@queue_page.has_previous_page?)
  ]}
>
  Previous
</.link>
```

### Pattern 7: Queue-Refresh Notification Color (NAV-02)

**What:** Replace raw `bg-teal-50 ring-stone-300 text-teal-950` in the queue-refresh notification block with tokenized values.

Current (operator_live.ex.eex line 206):
```html
<div class="mt-4 rounded-xl bg-teal-50 px-4 py-3 shadow-sm ring-1 ring-stone-300">
  <p class="text-sm font-medium text-teal-950">New incidents or queue changes are available.</p>
```

Replace:
```html
<div class="mt-4 rounded-xl px-4 py-3 shadow-sm ring-1 bg-[color:var(--parapet-accent-soft)] ring-[color:var(--parapet-border)]">
  <p class="text-sm font-medium" style="color: var(--parapet-text);">New incidents or queue changes are available.</p>
```

The `<button>` inside already uses tokenized classes (from Phase 45 fix confirmed at line 211) — no change needed to the button.

### Pattern 8: Skeleton Loading State (DATA-06)

**What:** Wrap the incident list container in an `aria-live="polite"` wrapper with a skeleton visible during loading.

**Context:** The current templates do NOT have an explicit loading state. The UI-SPEC directs adding a skeleton ONLY to the incident queue list where a jarring blank-then-populated flash could occur.

```heex
<div aria-live="polite" aria-busy={if assigns[:loading?], do: "true", else: "false"}>
  <%= if assigns[:loading?] do %>
    <div class="animate-pulse space-y-3" aria-hidden="true">
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
    </div>
  <% else %>
    <.incident_list ... />
  <% end %>
</div>
```

Note: `@loading?` is not currently assigned in `operator_live.ex.eex`. The planner must decide whether to add `loading?: false` as a default assign in `mount/3`, or to gate the skeleton only on Phoenix LiveView's built-in `connected?/1` check (skeleton shows on initial SSR, content appears after LiveView mounts). The latter is more idiomatic: `<%= if !connected?(assigns) do %>`. This avoids needing a new assign.

### Pattern 9: `aside aria-label` Addition (NAV-05)

In `operator_detail_live.ex.eex` (line 231):
```html
<aside class="min-w-0 space-y-6">
```
Becomes:
```html
<aside class="min-w-0 space-y-6" aria-label="Incident actions">
```

### Anti-Patterns to Avoid

- **Adding `overflow-x: hidden` to fix 390px overflow:** The shell already stacks correctly via `flex-col`. Do not add clip overflow — fix the root cause if any element overflows.
- **Adding `overflow-y-auto` or `overflow-y-scroll` to any Phase 46 container:** All page content uses natural document scroll. No internal scroll regions added in this phase.
- **Adding positive `tabindex` values:** Never use `tabindex="1"` or higher — DOM order is sufficient.
- **Putting disabled state on `<.link>` via the HTML `disabled` attribute:** `disabled` is for form elements only. Use `aria-disabled="true"` + `tabindex="-1"` on anchor-based links.
- **Using `transition-all` on new elements:** Prohibited. Use `transition-colors` for color changes only.
- **Changing CSS variable values:** Locked in Phases 44/45. Phase 46 only ADDS class rules (nav-active border, timeline-list last-child spine); it does NOT change any `--parapet-*` or `--po-*` variable values.
- **Editing Phase 45 CSS class rules:** Do not touch `.po-button-*`, `.po-chip-*`, `.po-focus`, `.po-link`, `.po-timeline-badge-*`, `.po-queue-row-selected` rules.
- **Breaking `prefers-reduced-motion`:** `animate-pulse` on skeletons is automatically zeroed by the existing `@media (prefers-reduced-motion: reduce)` block (lines 460–471) which sets `transition-duration: 0.01ms !important`. No additional reduced-motion handling needed.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark-mode color switching for new nav-active border | Per-theme JS or inline style | `var(--parapet-accent)` in the CSS rule (already overrides to `#7FB4C6` in both dark blocks) | CSS variable cascade handles all three theme modes automatically |
| Skip-link visibility toggle | JS-based show/hide | `sr-only focus:not-sr-only` Tailwind combination | Browser-native focus state; zero JS overhead |
| Contrast verification for new nav-active pairs | Manual calculation | Add to `@themes` map in `operator_ui_contrast_test.exs` | Existing `assert_contrast/4` helper handles all the math |
| Off-palette detection | Per-PR grep | Existing `refute content =~ "bg-teal-50"` pattern in `@live_template_paths` test | Phase 46 extends the existing test with `refute content =~ "bg-teal-50"` — catches the queue-refresh regression |
| Timeline empty state loading detection | Custom assign + handle_params tracking | `!connected?(assigns)` Phoenix LiveView built-in | Idiomatic LiveView pattern; avoids new socket assign |
| Spine suppression on last timeline entry | EEx conditional `if loop_index == last_index` | CSS `.po-timeline-list > li:last-child > div > span[aria-hidden] { display: none }` | CSS approach is cleaner and doesn't require threading loop index through the template |

**Key insight:** Phase 46 changes are systematically small — every gap has a clear one-or-two-line fix. The risk is not the complexity of any individual change but the disciplined application of byte-parity across 6 files (3 templates × 2 mirrors) without introducing regressions in the contrast/demo-contract test suite.

---

## Runtime State Inventory

Phase 46 is template markup and CSS additions only. No rename, migration, or data change.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — no data stored for HTML attributes | None |
| Live service config | None — template-only changes | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None — no compiled binaries affected | None |

**Nothing found in any category** — verified by nature of the phase (additive HTML/CSS/EEx edits only).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / mix | Running tests | ✓ | (project already running) | — |
| ExUnit | Contrast + demo-contract tests | ✓ | built-in | — |

No external tools, services, or CLIs needed beyond the normal Elixir development toolchain.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs` |
| Full suite command | `mix test --exclude unboxed` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Automatable? |
|--------|----------|-----------|-------------------|-------------|
| NAV-01 | `.po-nav-active` has border-bottom indicator | string search assert | `assert content =~ "border-bottom: 2px solid var(--parapet-accent)"` in contrast test `@component_paths` | YES — extend contrast test |
| NAV-01 | `aria-current="page"` present on nav_item | string search assert | `assert content =~ ~S|aria-current={if @active, do: "page"|}` | YES — already asserts `po-nav-active` |
| NAV-02 | No `bg-teal-50` in live templates | string search refute | `refute content =~ "bg-teal-50"` in contrast test `@live_template_paths` | YES — extend contrast test |
| NAV-03 | Theme switcher JS unchanged, `aria-pressed` present | string search assert | `assert content =~ "aria-pressed"` (already asserted via `po-theme-option`) | YES — no new assertion needed |
| NAV-04 | IA labels correct | string search assert | `assert content =~ "Respond"` etc. (already in demo-contract `@live_template_paths`) | YES — no new assertion needed |
| NAV-05 | Skip-link present | string search assert | `assert content =~ "Skip to main content"` in `@live_template_paths` test | YES — extend contrast test |
| NAV-05 | `id="parapet-main"` present | string search assert | `assert content =~ ~S|id="parapet-main"|` in `@live_template_paths` test | YES — extend contrast test |
| NAV-05 | `<aside aria-label="Incident actions">` present | string search assert | `assert content =~ ~S|aria-label="Incident actions"|` in detail template path | YES — extend contrast test with `@detail_template_paths` |
| DATA-01 | `truncate` + `min-w-0 flex-1` on incident row | string search assert | `assert content =~ "min-w-0 flex-1"` and `assert content =~ "truncate"` in `@component_paths` | YES — already present, add refute for absence if needed |
| DATA-02 | No `overflow-y-auto` added | string search refute | `refute content =~ "overflow-y-auto"` in `@component_paths` and `@live_template_paths` | YES — extend contrast test |
| DATA-03 | Timeline empty state present | string search assert | `assert content =~ "No timeline entries yet"` in `@component_paths` | YES — extend contrast test |
| DATA-03 | Timeline spine suppression CSS present | string search assert | `assert content =~ "po-timeline-list"` and `assert content =~ "li:last-child"` in `@component_paths` | YES — extend contrast test |
| DATA-04 | Empty states have SVG icons | string search assert | `assert content =~ ~S|aria-hidden="true"|` (multiple — needs count check or targeted context) | PARTIAL — string match can find SVG presence; visual check needed for correctness |
| DATA-04 | No `cursor-pointer` on empty state containers | string search refute | Already asserted: `refute content =~ "cursor-pointer"` (existing COMP-05 assertion) | YES — already in test |
| DATA-05 | No color-only status display | string search assert | `assert content =~ "po-chip"` and chip text content patterns — already covered by existing chip assertions | YES — already covered |
| DATA-06 | `aria-live="polite"` wrapper present | string search assert | `assert content =~ ~S|aria-live="polite"|` in `@live_template_paths` | YES — extend contrast test |
| DATA-06 | `animate-pulse` + `prefers-reduced-motion` zeroed | string search assert | `assert content =~ "animate-pulse"` + already asserts `"prefers-reduced-motion"` + `"--motion-fast: 0ms"` | YES — add animate-pulse presence check |
| A11Y-03 | `po-focus` on pagination enabled links | string search assert | `assert content =~ "pagination_link_class"` + `assert content =~ "po-focus"` in `pagination_link_class` context | PARTIAL — check that `pagination_link_class` definition includes `po-focus`; inspect function body |
| A11Y-03 | `aria-disabled` on disabled pagination | string search assert | `assert content =~ ~S|aria-disabled={|` in `@live_template_paths` | YES — extend contrast test |
| A11Y-04 | No keyboard traps (no modal in scope) | N/A — no modal in Phase 46 | N/A | N/A — Phase 47 |

### Behaviors that require gallery/manual verification (not automatable in ExUnit string tests)

| Behavior | Why not automatable | Verification approach |
|----------|--------------------|-----------------------|
| 390px no horizontal overflow | Requires browser rendering | Gallery at 390px viewport via screenshot script |
| Tab order correctness end-to-end | Requires browser + keyboard | Gallery manual walkthrough; flag in demo-contract as manual |
| Skip-link visual appearance on focus | Requires browser rendering | Gallery screenshot with forced focus state |
| `last:hidden` spine suppression visual | Rendering context needed | Gallery timeline section with 1–3 entries |
| Skeleton layout-jump absence | Requires real LiveView mount cycle | Manual smoke test (load page while seeds running) |

### New Assertions to Add to `operator_ui_contrast_test.exs`

Add a new `@live_template_paths` block (if not already scoped) or extend the existing `"operator live templates use semantic tokens"` test:

```elixir
# In the @live_template_paths test loop:
# NAV-02: queue-refresh notification tokenized
refute content =~ "bg-teal-50"
refute content =~ "text-teal-950"

# NAV-05: skip-link + main landmark
assert content =~ "Skip to main content"
assert content =~ ~S|id="parapet-main"|

# DATA-06: aria-live on queue list
assert content =~ ~S|aria-live="polite"|

# A11Y-03: disabled pagination aria-disabled
assert content =~ ~S|aria-disabled|

# DATA-02: no overflow-y-auto added
refute content =~ "overflow-y-auto"
```

Add a new `@detail_template_paths` group if not present:
```elixir
@detail_template_paths [
  "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
  "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
]

test "operator detail templates have correct landmarks" do
  for path <- @detail_template_paths do
    content = File.read!(path)
    assert content =~ ~S|aria-label="Incident actions"|
    assert content =~ ~S|id="parapet-main"|
    assert content =~ "Skip to main content"
  end
end
```

Extend `@component_paths` test with:
```elixir
# NAV-01: nav-active border-bottom indicator
assert content =~ "border-bottom: 2px solid var(--parapet-accent)"

# DATA-03: timeline empty state
assert content =~ "No timeline entries yet"
assert content =~ "po-timeline-list"

# DATA-03: spine suppression selector
assert content =~ "li:last-child"

# DATA-06: animate-pulse defined
assert content =~ "animate-pulse"
```

### Sampling Rate

- **Per task commit:** `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs`
- **Per wave merge:** `mix test --exclude unboxed`
- **Phase gate:** `mix test --exclude unboxed` green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] Add new assertion block for `@detail_template_paths` to `operator_ui_contrast_test.exs` (covers NAV-05 detail landmark, A11Y-03)
- [ ] Extend `@live_template_paths` test with NAV-02 refute, NAV-05 asserts, DATA-06 asserts, A11Y-03 asserts
- [ ] Extend `@component_paths` test with NAV-01 border assert, DATA-03 empty-state asserts

*(No new test files needed — all assertions are additive to the existing contrast test file)*

---

## Security Domain

Phase 46 introduces no new network endpoints, authentication paths, user input handling, or data access patterns. All changes are HTML attributes, CSS rules, and EEx markup additions.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | Static markup additions; no new user input paths |
| V6 Cryptography | no | — |

### Known Threat Patterns for Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via `aria-*` attribute injection | Tampering | Phoenix HEEx auto-escapes all interpolations; `aria-current={...}` and `aria-label="..."` are safe |
| Skip-link target manipulation | Elevation of privilege | `href="#parapet-main"` is a fragment link to a same-page element — no URL injection possible; `id="parapet-main"` is a static string |

No new threat surface. Phase 44 threat scan remains the applicable baseline.

---

## Current Code State: Exact Line Numbers

These are the verified locations (read from actual template files) that Phase 46 plans must reference:

### `operator_components.ex.eex` (template)

| Location | Line | Current State | Phase 46 Action |
|----------|------|---------------|-----------------|
| `.po-nav-active` CSS rule | 330 | `background` + `color` only | ADD `border-bottom: 2px solid var(--parapet-accent)` |
| `operator_nav/1` function | 505 | `<header class="po-operator-header border-b">` | No change to structure |
| `nav_item/1` aria-current | 621 | `aria-current={if @active, do: "page", else: nil}` | VERIFIED correct — no change |
| `nav_item/1` class | 623 | `po-focus flex min-h-[40px] ...` + conditional `po-nav-active`/`po-nav-item` | VERIFIED correct — no change |
| `incident_list/1` empty branch | 744 | `<div class="px-4 py-6 text-center">` with text only | ADD svg icon before heading |
| `incident_row/1` text truncation | 777 | `truncate text-sm font-semibold text-stone-900` on title | VERIFIED correct — no change |
| `incident_timeline/1` function | 915 | `<div class="flow-root"><ul role="list" class="-mb-8">` — no empty branch | ADD empty-state branch; ADD `po-timeline-list` class to `<ul>` |
| Timeline spine `<span>` | 925 | `<span class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-stone-200" aria-hidden="true">` | Suppressed via CSS `.po-timeline-list > li:last-child > div > span[aria-hidden]` |
| `action_center/1` empty branch | 696 | `<div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">` | ADD svg icon before heading |

### `operator_live.ex.eex` (template)

| Location | Line | Current State | Phase 46 Action |
|----------|------|---------------|-----------------|
| `.parapet-ui` div | 121 | `<div class="parapet-ui antialiased flex min-h-screen flex-col bg-stone-100 text-stone-900">` | ADD skip-link as first child |
| `:actions` `<main>` | 125 | `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">` | ADD `id="parapet-main" tabindex="-1"` |
| `:history` `<main>` | 139 | `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">` | ADD `id="parapet-main" tabindex="-1"` |
| Queue-refresh notification | 206 | `bg-teal-50 ring-stone-300` container, `text-teal-950` text | Replace with token-based classes |
| `:response` `<main>` | 196 | `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">` | ADD `id="parapet-main" tabindex="-1"` |
| Incident list container | 235–241 | `<.incident_list ... />` directly in response section | WRAP with `aria-live="polite"` + skeleton pattern |
| Cockpit no-selection empty state | 281 | `<div class="flex min-h-[28rem] items-center justify-center p-8 text-stone-500">` | ADD svg icon inside existing container |
| `pagination_link_class(true)` | 468 | Returns `ring-1 ring-stone-300 bg-white text-stone-900 hover:*` — no `po-focus` | ADD `focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus` |
| Pagination `<.link>` elements | ~175, ~185, ~245, ~255 | No `aria-disabled` or `tabindex` attributes | ADD `aria-disabled` + `tabindex="-1"` on disabled links |

### `operator_detail_live.ex.eex` (template)

| Location | Line | Current State | Phase 46 Action |
|----------|------|---------------|-----------------|
| `.parapet-ui` div | 206 | `<div class="parapet-ui antialiased flex min-h-screen w-full max-w-full flex-col overflow-x-hidden bg-stone-100 text-stone-900">` | ADD skip-link as first child |
| `<main>` | 218 | `<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">` | ADD `id="parapet-main" tabindex="-1"` |
| `<aside>` | 231 | `<aside class="min-w-0 space-y-6">` | ADD `aria-label="Incident actions"` |

---

## Common Pitfalls

### Pitfall 1: Dark-Block CSS Override for `.po-nav-active` Border

**What goes wrong:** Adding `border-bottom: 2px solid var(--parapet-accent)` to the base `.parapet-ui .po-nav-active` rule is sufficient — `var(--parapet-accent)` auto-resolves to `#7FB4C6` in dark mode via the dark block variable override. Do NOT add a separate dark-block selector for this border.
**Why it happens:** Developers unfamiliar with the CSS variable cascade assume they need explicit dark overrides for every new property.
**How to avoid:** Trust the variable cascade. The `--parapet-accent` variable is already overridden in both dark blocks (line 143 for explicit dark, line 207 for media-query dark). Adding a redundant dark selector creates drift risk.
**Warning signs:** If you see a `html[data-parapet-theme="dark"] .parapet-ui .po-nav-active { border-bottom: ... }` rule being added, it's unnecessary.

### Pitfall 2: Skip-Link Position Inside vs Outside `.parapet-ui`

**What goes wrong:** The skip-link is placed OUTSIDE the `.parapet-ui` wrapper div, which means it doesn't inherit the CSS variable theme and will display with wrong colors.
**Why it happens:** The UI-SPEC says "first child of `.parapet-ui`" — it must be INSIDE the `.parapet-ui` div.
**How to avoid:** Insert the skip-link immediately after `<div class="parapet-ui ...">`, not before it.
**Warning signs:** Skip-link appears but shows raw color values instead of token-resolved colors.

### Pitfall 3: Three `<main>` Branches in `operator_live.ex.eex`

**What goes wrong:** `id="parapet-main"` is added only to the `:response` branch `<main>` but not to the `:actions` and `:history` branches.
**Why it happens:** The template has three conditional branches each rendering a `<main>` — easy to miss the other two.
**How to avoid:** Search for `<main class=` in `operator_live.ex.eex` — there are exactly 3 occurrences (lines ~125, ~139, ~196). All three must receive `id="parapet-main" tabindex="-1"`.
**Warning signs:** Skip-link works on response page but broken on actions/history tabs; ExUnit string test passes because template contains the id somewhere but manual testing reveals gaps.

### Pitfall 4: `timeline_entries` Variable Scope in Timeline Empty-State Refactor

**What goes wrong:** The `timeline_entries` variable is currently computed inline at line 919 inside the existing `<% timeline_entries = ... %>` assignment. When wrapping with a conditional, this assignment must move to BEFORE the `<%= if Enum.empty?(timeline_entries) do %>` check — otherwise it's referenced before being assigned.
**Why it happens:** EEx templates execute top-to-bottom; the variable must exist before it's used in the conditional.
**How to avoid:** The refactored `incident_timeline/1` must have the `timeline_entries` assignment as the FIRST line inside the function body's template block, before any conditional.

### Pitfall 5: Demo Mirror Divergence on Multi-File Commits

**What goes wrong:** A commit updates `operator_live.ex.eex` but forgets to apply the same changes to `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`.
**Why it happens:** Phase 46 touches ALL THREE template files — the surface area is larger than Phase 45 (which mainly touched `operator_components.ex.eex`). Each of the three templates has a corresponding mirror.
**How to avoid:** Process ONE template + ONE mirror per commit. Never commit changes to a template without the corresponding mirror in the same commit. After each commit, run `mix test test/parapet/operator_ui_contrast_test.exs` — the contrast test reads both paths.
**Warning signs:** `mix test` passes on template assertions but gallery shows different behavior from what a host-generated app would see.

### Pitfall 6: `aria-disabled` on `<.link>` vs `disabled` on `<button>`

**What goes wrong:** Using the HTML `disabled` attribute on `<.link>` (which renders as `<a>`) — `disabled` has no effect on `<a>` elements. The link remains interactive.
**Why it happens:** Developers apply `disabled` thinking it's universal.
**How to avoid:** Use `aria-disabled="true"` + `tabindex="-1"` on `<.link>` elements. Use native `disabled` only on `<button>` elements. The `pagination_link_class(false)` already includes `pointer-events-none` (CSS); `aria-disabled` is the accessible complement; `tabindex="-1"` removes it from tab order.

### Pitfall 7: NAV-02 Queue-Refresh Fix Missed in Demo Mirror

**What goes wrong:** The `bg-teal-50` in the queue-refresh notification (operator_live.ex.eex line 206) is fixed in the template but not in `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`. The new `@live_template_paths` test only reads the template path by default.
**How to avoid:** The existing `@live_template_paths` array in the contrast test already includes BOTH paths (`priv/templates/.../operator_live.ex.eex` AND `examples/.../operator_live.ex`). Extending the test with `refute content =~ "bg-teal-50"` will catch the mirror if it diverges.

---

## Code Examples

### NAV-01: Complete `.po-nav-active` Rule

```css
/* Source: operator_components.ex.eex line 330 — current rule + Phase 46 addition */
.parapet-ui .po-nav-active {
  background: var(--po-nav-active-bg);
  color: var(--po-nav-active-fg);
  border-bottom: 2px solid var(--parapet-accent);
}
/* No dark override needed — --parapet-accent resolves to #7FB4C6 in dark via existing dark blocks */
```

### DATA-03: Timeline List Class + Last-Entry CSS

```css
/* Source: operator_components.ex.eex — add to <style> block after .po-queue-row-selected */
/* DATA-03: Suppress connector spine on the final timeline entry */
.parapet-ui .po-timeline-list > li:last-child > div > span[aria-hidden="true"] {
  display: none;
}
```

```heex
<%!-- Add class="po-timeline-list" to the <ul> in incident_timeline/1 --%>
<ul role="list" class="po-timeline-list -mb-8">
```

### NAV-05: Complete Skip-Link + Landmark Pattern (operator_live)

```heex
<.operator_theme_bootstrap />
<div class="parapet-ui antialiased flex min-h-screen flex-col bg-stone-100 text-stone-900">
  <%!-- NAV-05: Skip-to-content — first child --%>
  <a
    href="#parapet-main"
    class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50
           flex min-h-[40px] items-center rounded-lg px-4 py-2 text-sm font-semibold
           bg-[color:var(--parapet-panel)] text-[color:var(--parapet-accent)]
           focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
  >
    Skip to main content
  </a>
  <.operator_nav active={@page_mode} operator_base_path={@operator_base_path} />

  <%%= if @page_mode == :actions do %>
    <main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
      ...
    </main>
  <%% else %>
    <%%= if @page_mode == :history do %>
      <main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
        ...
      </main>
    <%% else %>
      <main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
        ...
      </main>
    <%% end %>
  <%% end %>
</div>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw `bg-teal-*` for off-palette surfaces | Token-based `var(--parapet-*)` expressions | Phase 44/45 | Dark mode works automatically |
| Button focus rings with `focus:ring-teal-300` | `.po-focus` class with `--po-focus` variable | Phase 44/45 | Per-surface focus ring (limestone on dark) |
| No explicit skip link / landmark structure | Skip-to-content + `id="parapet-main"` + `<aside aria-label>` | Phase 46 | Keyboard navigation for assistive technology |
| Timeline renders empty `<ul>` when no entries | Empty-state branch with icon + copy | Phase 46 | Users understand why timeline is empty |
| Pagination links omit `po-focus` | `po-focus` on enabled pagination links | Phase 46 | Consistent tokenized focus ring across all interactive elements |

**Deprecated/outdated:**
- `bg-teal-50` in queue-refresh notification: replaced with `bg-[color:var(--parapet-accent-soft)]`.
- Bare `<ul role="list">` in timeline (no class): replaced with `<ul role="list" class="po-timeline-list">` for CSS spine-suppression targeting.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The three `<main>` elements in `operator_live.ex.eex` are at approximately lines 125, 139, 196 | Current Code State table | LOW: Line numbers shift if earlier edits are inserted; planner must search for `<main class=` not use fixed line numbers |
| A2 | The `timeline_entries` variable in `incident_timeline/1` is computed as an EEx assignment that can be moved to before the conditional without side effects | Data-03 pattern | LOW: The expression `@detail.timeline_entries \|\| Enum.map(...)` is a pure function call with no side effects — safe to hoist |
| A3 | `!connected?(assigns)` is the correct Phoenix LiveView idiom for detecting server-side render vs live-mounted state for skeleton display | Data-06 pattern | MEDIUM: If the LiveView uses `on_mount` hooks or has other initial-load behavior, the skeleton may flash even when not needed. Planner should verify or default to `loading?: false` assign approach if this is unclear |
| A4 | `tabindex="-1"` on `<main id="parapet-main">` is safe and does not create unexpected focus behavior | NAV-05 pattern | LOW: `tabindex="-1"` on non-interactive elements is a well-established pattern for programmatic focus targets; it does not add the element to tab order, only allows focus via `element.focus()` or fragment navigation |
| A5 | The `aria-disabled` + `tabindex="-1"` attributes on disabled `<.link>` pagination elements can be expressed as inline HEEx attributes (not class strings) | A11Y-03 pattern | LOW: Phoenix HEEx fully supports arbitrary HTML attributes on `<.link>` components |

**If this table is empty:** N/A — see above assumptions.

---

## Open Questions

1. **Skeleton loading approach: `connected?/1` vs explicit `loading?` assign**
   - What we know: `operator_live.ex.eex` does not currently set a `loading?` assign. Phoenix LiveView's `connected?/1` returns `false` during SSR and `true` after WebSocket mount.
   - What's unclear: Whether the skeleton should appear only during SSR (one flash), or whether a `loading?` assign should gate it more granularly.
   - Recommendation: Use `!connected?(assigns)` as the gate — it's idiomatic and avoids adding a new assign. The skeleton shows during SSR only, disappears once the LiveView mounts. If the user wants a more controlled loading state, the planner can add `loading?: false` in mount with a handle_info that sets it true during data load.

2. **`@live_template_paths` test group in contrast test**
   - What we know: The existing test at line 180 defines `@live_template_paths` for the secondary templates. The Phase 46 new assertions target these paths.
   - What's unclear: Whether the test at line 180 includes or excludes the detail template.
   - Recommendation: Planner should add a separate `@detail_template_paths` constant and test so assertions targeting `operator_detail_live.ex.eex` can be cleanly separated from `operator_live.ex.eex` assertions.

---

## Sources

### Primary (HIGH confidence — VERIFIED against actual file contents)

- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — Full CSS block, nav_item/1 (~617), incident_list/1 (~713), incident_timeline/1 (~915), action_center/1 (~677), all private functions including pagination_link_class/1 — VERIFIED by direct file reads
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — render/1 structure, three `<main>` branches, pagination links, queue-refresh notification (~206), pagination_link_class function (~468) — VERIFIED by direct file reads
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — render/1 structure, single `<main>` (~218), `<aside>` (~231) — VERIFIED by direct file reads
- `test/parapet/operator_ui_contrast_test.exs` — @themes, @component_paths, @live_template_paths, all existing assertions — VERIFIED by full file read
- `test/parapet/operator_ui_demo_contract_test.exs` — Existing assertions — VERIFIED by full file read
- `.planning/phases/46-navigation-shell-data-display/46-UI-SPEC.md` — APPROVED design contract; all requirement contracts; CSS patterns; copy specifications — VERIFIED by full file read
- `.planning/REQUIREMENTS.md` — 13 NAV/DATA/A11Y requirement definitions — VERIFIED by full file read

### Secondary (MEDIUM confidence — cited from planning docs)

- `.planning/phases/45-primitive-components/45-RESEARCH.md` — Phase 45 architecture patterns; contrast test extension approach; demo-mirror sync protocol
- `.planning/ROADMAP.md` — Phase 46 success criteria; Phase 50 GUARD-03 byte-parity constraint
- `brandbook/tokens/tokens.css` — Token source of truth for CSS variable values (locked v1.5)

### Tertiary (LOW confidence — N/A for this research)

No external web sources required. All findings are derived from codebase inspection.

---

## Metadata

**Confidence breakdown:**
- Current code state / line numbers: HIGH — every location verified by reading actual files
- CSS rule patterns: HIGH — all use existing `--parapet-*` variables confirmed in templates
- Test extension patterns: HIGH — existing test helpers verified; new assertions follow exact same patterns
- Skeleton `!connected?/1` approach: MEDIUM — idiomatic but not verified against the specific LiveView mount behavior

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (stable Elixir/Phoenix project; token values locked by brand book; template structure is stable)
