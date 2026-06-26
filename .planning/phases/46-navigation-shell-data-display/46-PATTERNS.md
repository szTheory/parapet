# Phase 46: Navigation, Shell & Data-Display — Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 7 artifacts across 3 template source files + 3 demo mirrors + 1 test file
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified Artifact | Role | Data Flow | Closest Analog | Match Quality |
|----------------------|------|-----------|----------------|---------------|
| `.po-nav-active` CSS rule (~line 330, `operator_components.ex.eex`) | config/CSS | request-response | `.po-nav-item` / `.po-nav-item:hover` CSS rules (lines 321–328, same file) | exact — same `.parapet-ui .po-*` selector scoping pattern |
| Skip-to-content `<a>` + `id="parapet-main"` on `<main>` elements (`operator_live.ex.eex` lines 121/125/139/196, `operator_detail_live.ex.eex` lines 206/218) | template markup | request-response | existing `.parapet-ui` wrapper + `<.operator_nav>` first-child insertion point (line 121/206); existing `<main class="flex-1 ...">` elements (lines 125, 139, 196, 218) | exact — additive attribute/element insertion into known positions |
| `<aside aria-label="Incident actions">` (`operator_detail_live.ex.eex` line 231) | template markup | request-response | existing `<section aria-label="Incident timeline">` (line 225, `operator_detail_live.ex.eex`) | exact — same `aria-label` attribute pattern on sectioning element |
| `incident_timeline/1` empty-state branch + `po-timeline-list` class + spine-suppression CSS (~line 915, `operator_components.ex.eex`) | template/config | request-response | `incident_list/1` empty branch (lines 744–751) + `action_center/1` empty branch (lines 696–701) + `.po-nav-active` CSS rule (line 330) | exact role-match — same `<%= if Enum.empty?(...) do %>` empty-branch pattern + same `.parapet-ui .po-*` CSS rule shape |
| Decorative SVG icon additions to `incident_list/1` (line 744), `action_center/1` (line 696), cockpit no-selection (operator_live line 281) | template markup | request-response | Any existing `aria-hidden="true"` inline SVG in the templates; skip-link SVG-free pattern shows the inline-token-color approach | role-match — additive icon insertion before heading in existing empty-state containers |
| `pagination_link_class/1` + `po-focus` + disabled `aria-disabled`/`tabindex="-1"` (`operator_live.ex.eex` lines 468–472, pagination `<.link>` elements ~175/185/244/254) | utility function + markup | request-response | Phase 45 `control_base()` which appended `po-focus focus:outline-none focus:ring-2 focus:ring-offset-2` (operator_components.ex.eex line 1283–1285); existing `pagination_link_class/1` body (lines 468–472) | exact — same class-string append pattern; disabled attr mirrors Phase 45 anti-pattern note |
| `aria-live="polite"` skeleton wrapper around `<.incident_list />` (`operator_live.ex.eex` ~line 235) | template markup | request-response | existing `prefers-reduced-motion` block (already zeroes `animate-pulse`) in `operator_theme_bootstrap/1`; `<%= if @queue_refresh_available? do %>` conditional wrapper (lines 205–216) as structural analog | partial — same `<%= if ... do %> / <% else %> / <% end %>` conditional wrapper; no prior `aria-live` exists |
| `@detail_template_paths` constant + `"operator detail templates have correct landmarks"` test (`operator_ui_contrast_test.exs`) | test | batch | `@live_template_paths` constant (line 175) + `"operator live templates use semantic tokens"` test (line 180); `@component_paths` constant (line 4) + `"operator components use semantic tokens"` test (line 92) | exact — same `for path <- @*_paths do / content = File.read!(path) / assert content =~` loop pattern |

---

## Pattern Assignments

---

### `.po-nav-active` CSS rule border-bottom addition (NAV-01)

**Artifact:** `operator_components.ex.eex` and its mirror `operator_components.ex`
**Action:** Add `border-bottom: 2px solid var(--parapet-accent)` to the existing rule

**Analog — closest existing `.po-*` rule block** (lines 321–333):
```css
/* operator_components.ex.eex lines 321–333 */
.parapet-ui .po-nav-item {
  color: var(--po-nav-fg);
}

.parapet-ui .po-nav-item:hover {
  background: var(--po-nav-hover-bg);
  color: var(--po-nav-hover-fg);
}

.parapet-ui .po-nav-active {
  background: var(--po-nav-active-bg);
  color: var(--po-nav-active-fg);
}
```

**Target state — copy this shape:**
```css
/* operator_components.ex.eex line 330 — REPLACE entire block */
.parapet-ui .po-nav-active {
  background: var(--po-nav-active-bg);
  color: var(--po-nav-active-fg);
  border-bottom: 2px solid var(--parapet-accent);
}
/* No dark override needed — var(--parapet-accent) already resolves to #7FB4C6
   in both dark blocks via the existing cascade. */
```

**CSS scoping rule (shared pattern):** Every new CSS rule MUST be prefixed `.parapet-ui .po-*`. Source: all existing rules at lines 321–397.

**Byte-mirror constraint:** Apply identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` in the same commit.

---

### Skip-to-content link + `id="parapet-main"` markup (NAV-05)

**Artifacts:**
- `operator_live.ex.eex` lines 121 (insert after), 125/139/196 (modify `<main>` opening tags)
- `operator_detail_live.ex.eex` lines 206 (insert after), 218 (modify `<main>` opening tag)
- Both demo mirrors (identical edits)

**Analog — `operator_live.ex.eex` line 121 (existing `.parapet-ui` wrapper, insertion point):**
```heex
<%# operator_live.ex.eex lines 120–122 %>
<.operator_theme_bootstrap />
<div class="parapet-ui antialiased flex min-h-screen flex-col bg-stone-100 text-stone-900">
  <.operator_nav active={@page_mode} operator_base_path={@operator_base_path} />
```

**Analog — `operator_detail_live.ex.eex` line 206 (insertion point):**
```heex
<%# operator_detail_live.ex.eex lines 205–207 %>
<.operator_theme_bootstrap />
<div class="parapet-ui antialiased flex min-h-screen w-full max-w-full flex-col overflow-x-hidden bg-stone-100 text-stone-900">
  <.operator_nav active={detail_nav_active(@incident)} operator_base_path={@operator_base_path} />
```

**Analog — existing `<main>` element shape to add `id=` and `tabindex=` to:**
```heex
<%# operator_live.ex.eex lines 125, 139, 196 — all three take the same addition %>
<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
<%# becomes: %>
<main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">

<%# operator_detail_live.ex.eex line 218 %>
<main class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
<%# becomes: %>
<main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
```

**Skip-link markup to insert (first child inside `.parapet-ui` div, before `<.operator_nav>`):**
```heex
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

**`po-focus` placement rule:** The `po-focus` class on the skip-link follows the same `focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus` group used in `control_base()` (operator_components.ex.eex line 1284) and confirmed on the queue-refresh button (operator_live.ex.eex line 211).

**Pitfall:** Insert the skip-link INSIDE `<div class="parapet-ui ...">`, never before it. The `po-focus` CSS variable resolves via the theme container.

**Pitfall:** `operator_live.ex.eex` has THREE `<main>` elements (lines 125, 139, 196 — one per page-mode branch). All three must receive `id="parapet-main" tabindex="-1"`. Search `operator_live.ex.eex` for `<main class=` to locate all three.

**Byte-mirror constraint:** Both `operator_live.ex` and `operator_detail_live.ex` demo mirrors must be edited identically in the same commit as their templates.

---

### `<aside aria-label="Incident actions">` (NAV-05)

**Artifact:** `operator_detail_live.ex.eex` line 231 and its demo mirror

**Analog — existing sectioning element with `aria-label` in the same file (line 225):**
```heex
<%# operator_detail_live.ex.eex line 225 %>
<section class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5 md:p-6" aria-label="Incident timeline">
```

**Target change (line 231):**
```heex
<%# Current: %>
<aside class="min-w-0 space-y-6">

<%# Replace with: %>
<aside class="min-w-0 space-y-6" aria-label="Incident actions">
```

**Byte-mirror constraint:** Apply identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`.

---

### `incident_timeline/1` empty-state branch + spine-suppression CSS (DATA-03/04)

**Artifact:** `operator_components.ex.eex` ~line 915 and its demo mirror

**Analog — `incident_list/1` empty branch** (lines 744–751):
```heex
<%# operator_components.ex.eex lines 744–751 %>
<%%= if Enum.empty?(@incidents) do %>
  <div class="px-4 py-6 text-center">
    <p class="text-sm font-semibold text-stone-800">No active incidents</p>
    <p class="mt-2 text-sm text-stone-500">
      Open and investigating incidents will appear here. Use History to review resolved incidents without disrupting the active queue.
    </p>
  </div>
<%% end %>
```

**Analog — `action_center/1` empty branch** (lines 696–701):
```heex
<%# operator_components.ex.eex lines 696–701 %>
<%%= if Enum.empty?(@items) do %>
  <div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">
    <p class="text-sm font-semibold text-stone-800">No pending action items</p>
    <p class="mt-2 text-sm text-stone-500">Recovery work appears here when an incident has a concrete item to inspect or resolve.</p>
  </div>
<%% end %>
```

**Current timeline structure to refactor** (lines 917–958):
```heex
<%# operator_components.ex.eex lines 917–958 — current state (no empty branch) %>
<div class="flow-root">
  <ul role="list" class="-mb-8">
    <%% timeline_entries = @detail.timeline_entries || Enum.map(@detail.entries, ...) %>
    <%%= for item <- timeline_entries do %>
      <li>
        <div class="relative pb-8">
          <span class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-stone-200" aria-hidden="true"></span>
          ...
        </div>
      </li>
    <%% end %>
  </ul>
</div>
```

**Target pattern — hoist variable, add conditional, add class:**
```heex
<div class="flow-root">
  <%% timeline_entries = @detail.timeline_entries || Enum.map(@detail.entries, ...) %>
  <%%= if Enum.empty?(timeline_entries) do %>
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
  <%% else %>
    <ul role="list" class="po-timeline-list -mb-8">
      <%%= for item <- timeline_entries do %>
        ...existing loop...
      <%% end %>
    </ul>
  <%% end %>
</div>
```

**Critical pitfall:** The `timeline_entries` EEx assignment (currently at line 919, inside the `for`) must be HOISTED to before the `if Enum.empty?` conditional. EEx executes top-to-bottom; referencing `timeline_entries` in the empty-check before it is assigned causes a compile error.

**Spine-suppression CSS rule (add to `operator_theme_bootstrap/1` style block, after existing `.po-queue-row-selected` rule):**
```css
/* DATA-03: Suppress connector spine on the final timeline entry */
/* Analog selector shape: operator_components.ex.eex lines 330–333 (.po-nav-active) */
.parapet-ui .po-timeline-list > li:last-child > div > span[aria-hidden="true"] {
  display: none;
}
```

**Byte-mirror constraint:** Apply all changes identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` in the same commit.

---

### Decorative SVG icon additions to existing empty states (DATA-04)

**Artifacts:**
- `operator_components.ex.eex` lines 744–751 (`incident_list/1` empty branch)
- `operator_components.ex.eex` lines 696–701 (`action_center/1` empty branch)
- `operator_live.ex.eex` lines 281–288 (cockpit no-selection branch)
- All three demo mirrors

**Analog — existing `aria-hidden="true"` SVG in the templates (timeline badge at line 928):**
```heex
<%# operator_components.ex.eex line 928 — model for aria-hidden inline SVG shape %>
<span class={["h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white text-white text-[11px] font-semibold", timeline_entry_badge_class(presentation)]}>
  <%%= timeline_entry_badge_text(presentation) %>
</span>
```

**SVG to insert before heading in `incident_list/1` empty branch (line 746, before `<p class="text-sm font-semibold"`):**
```html
<svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
  <path stroke-linecap="round" stroke-linejoin="round"
    d="M2.25 13.5h3.86a2.25 2.25 0 012.012 1.244l.256.512a2.25 2.25 0 002.013 1.244h3.218a2.25 2.25 0 002.013-1.244l.256-.512a2.25 2.25 0 012.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 00-2.15-1.588H6.911a2.25 2.25 0 00-2.15 1.588L2.35 13.177a2.25 2.25 0 00-.1.661z" />
</svg>
```

**SVG to insert in `action_center/1` empty branch (line 698, before `<p class="text-sm font-semibold"`) — inbox/checkmark icon:**
```html
<svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
  <path stroke-linecap="round" stroke-linejoin="round"
    d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
</svg>
```

**SVG to insert in cockpit no-selection empty state (`operator_live.ex.eex` line 283, before `<p class="text-sm font-semibold"`) — cursor/select icon:**
```html
<svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
  <path stroke-linecap="round" stroke-linejoin="round"
    d="M15.042 21.672L13.684 16.6m0 0l-2.51 2.225.569-9.47 5.227 7.917-3.286-.672zM12 2.25V4.5m5.834.166l-1.591 1.591M20.25 10.5H18M7.757 14.743l-1.59 1.59M6 10.5H3.75m4.007-4.243l-1.59-1.59" />
</svg>
```

**Container rule:** Do NOT add `cursor-pointer` or `hover:bg-*` to any empty state container. The existing `action_center/1` container (`rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm`, line 697) has no pointer cursor — preserve this. The cockpit no-selection container (`max-w-md rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm`, line 282) is identical — preserve.

**Color pattern:** All SVG icons use `style="color: var(--parapet-text-muted);"` with `stroke="currentColor"`. This is consistent with the skip-link's `text-[color:var(--parapet-accent)]` approach — use inline style for CSS variable color, not Tailwind `text-[color:...]` on elements where the token is the sole color source.

**Byte-mirror constraint:** `operator_components.ex.eex` changes → `operator_components.ex`; `operator_live.ex.eex` cockpit change → `operator_live.ex`.

---

### `pagination_link_class/1` + `po-focus` + disabled `aria-disabled`/`tabindex` (A11Y-03)

**Artifact:** `operator_live.ex.eex` lines 468–472 (function) + pagination `<.link>` elements (~lines 172–189, 243–261) and demo mirror

**Analog — Phase 45 `control_base()` which added `po-focus` group** (operator_components.ex.eex line 1283–1285, post-Phase-45 state):
```elixir
# operator_components.ex.eex — control_base() after Phase 45
defp control_base do
  "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-[--motion-fast] ease-out active:scale-[0.96] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
end
```

**Current `pagination_link_class/1`** (lines 468–472 — the analog to modify):
```elixir
# operator_live.ex.eex lines 468–472 — CURRENT
defp pagination_link_class(true),
  do: "ring-1 ring-stone-300 bg-white text-stone-900 hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)]"

defp pagination_link_class(false),
  do: "pointer-events-none ring-1 ring-stone-200 bg-stone-100 text-stone-400"
```

**Target state:**
```elixir
# operator_live.ex.eex lines 468–472 — REPLACE
defp pagination_link_class(true),
  do: "ring-1 ring-stone-300 bg-white text-stone-900 hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"

defp pagination_link_class(false),
  do: "pointer-events-none ring-1 ring-stone-200 bg-stone-100 text-stone-400"
```

**Disabled link attributes — add at call sites, NOT via the class function:**
```heex
<%# operator_live.ex.eex — pagination <.link> pattern for disabled state %>
<%# Current at ~line 243: %>
<.link
  patch={queue_page_path(@operator_base_path, @queue_params, @queue_page.previous_cursor, "previous")}
  class={[
    "flex min-h-[40px] items-center justify-center rounded-lg px-3 py-2 text-sm font-semibold transition-transform duration-[--motion-fast] ease-out active:scale-[0.96]",
    pagination_link_class(@queue_page.has_previous_page?)
  ]}
>
  Previous
</.link>

<%# Target — add aria-disabled and tabindex attributes: %>
<.link
  patch={queue_page_path(@operator_base_path, @queue_params, @queue_page.previous_cursor, "previous")}
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

Apply this pattern to all four pagination `<.link>` elements: `has_previous_page?` Previous/Newer and `has_next_page?` Next/Older.

**Anti-pattern:** Do NOT use the `disabled` HTML attribute on `<.link>` elements. `disabled` has no effect on `<a>` tags. Use `aria-disabled="true"` + `tabindex="-1"` only.

**Byte-mirror constraint:** Apply identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`.

---

### Queue-refresh notification tokenized colors (NAV-02)

**Artifact:** `operator_live.ex.eex` line 206 and demo mirror

**Current state** (line 206–207):
```heex
<%# operator_live.ex.eex lines 206–207 — CURRENT %>
<div class="mt-4 rounded-xl bg-teal-50 px-4 py-3 shadow-sm ring-1 ring-stone-300">
  <p class="text-sm font-medium text-teal-950">New incidents or queue changes are available.</p>
```

**Analog — queue-refresh button (line 211) already using tokenized classes:**
```heex
<%# operator_live.ex.eex line 211 — MODEL for container tokenization %>
class="mt-3 flex min-h-[40px] items-center justify-center rounded-lg bg-[color:var(--parapet-accent)] px-4 py-2 text-sm font-semibold text-white transition-colors duration-[--motion-fast] ease-out active:scale-[0.96] hover:bg-[color:var(--parapet-accent-strong)] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
```

**Target state:**
```heex
<div class="mt-4 rounded-xl px-4 py-3 shadow-sm ring-1 bg-[color:var(--parapet-accent-soft)] ring-[color:var(--parapet-border)]">
  <p class="text-sm font-medium" style="color: var(--parapet-text);">New incidents or queue changes are available.</p>
```

The `<button>` inside (line 211) requires NO changes — it already uses tokenized classes.

**Byte-mirror constraint:** Apply identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`.

---

### Skeleton `aria-live="polite"` wrapper + `animate-pulse` (DATA-06)

**Artifact:** `operator_live.ex.eex` ~line 235 (wrapping the `<.incident_list />` call) and demo mirror

**Analog — existing conditional `<%= if @queue_refresh_available? do %>` wrapper** (lines 205–216):
```heex
<%# operator_live.ex.eex lines 205–216 — structural analog for conditional wrapper %>
<%%= if @queue_refresh_available? do %>
  <div class="mt-4 rounded-xl ...">
    ...
  </div>
<%% end %>
```

**Analog — existing `prefers-reduced-motion` block in `operator_theme_bootstrap/1`** (operator_components.ex.eex ~line 460–471) which already zeroes `animate-pulse`:
```css
/* operator_components.ex.eex ~lines 460–471 — already zeroes animation; no new reduced-motion rule needed */
@media (prefers-reduced-motion: reduce) {
  .parapet-ui * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Current `<.incident_list />` call site** (lines 235–241):
```heex
<%# operator_live.ex.eex lines 235–241 — CURRENT %>
<.incident_list
  incidents={@visible_incidents}
  selected={selected_queue_incident(@selected_incident)}
  queue_params={@queue_params}
  page_mode={@page_mode}
  operator_base_path={@operator_base_path}
/>
```

**Target pattern — wrap with `aria-live` + skeleton gate:**
```heex
<div aria-live="polite" aria-busy={if !connected?(assigns), do: "true", else: "false"}>
  <%%= if !connected?(assigns) do %>
    <div class="animate-pulse space-y-3" aria-hidden="true">
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
    </div>
  <%% else %>
    <.incident_list
      incidents={@visible_incidents}
      selected={selected_queue_incident(@selected_incident)}
      queue_params={@queue_params}
      page_mode={@page_mode}
      operator_base_path={@operator_base_path}
    />
  <%% end %>
</div>
```

**`!connected?(assigns)` idiom:** Returns `true` during SSR (before LiveView WebSocket mount), `false` after. Skeleton shows during the initial server render only, disappears once LiveView mounts. No new socket assign needed.

**Skeleton height rule:** Each skeleton block uses `h-16` (64px) matching the approximate height of an `incident_row/1` so no layout reflow occurs when content replaces the skeleton.

**Byte-mirror constraint:** Apply identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`.

---

### `@detail_template_paths` constant + landmark test (`operator_ui_contrast_test.exs`) (NAV-05 / A11Y-03 / DATA-06)

**Artifact:** `test/parapet/operator_ui_contrast_test.exs` — additive only

**Analog — `@live_template_paths` constant + test** (lines 175–188):
```elixir
# test/parapet/operator_ui_contrast_test.exs lines 175–188
@live_template_paths [
  "priv/templates/parapet.gen.ui/operator_live.ex.eex",
  "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
]

test "operator live templates use semantic tokens (no raw stone-950 primary button colors)" do
  for path <- @live_template_paths do
    content = File.read!(path)

    # COMP-08 gap-closure: Return to Response button must use token-based primary
    refute content =~ "bg-stone-950"
  end
end
```

**Analog — `@component_paths` test loop pattern** (lines 92–172):
```elixir
# test/parapet/operator_ui_contrast_test.exs lines 92–94 — copy this loop shape
test "operator components use semantic tokens for known dark-mode risk surfaces" do
  for path <- @component_paths do
    content = File.read!(path)
    assert content =~ "marker"
    refute content =~ "forbidden"
  end
end
```

**New constant to add (after `@live_template_paths` at line 178):**
```elixir
@detail_template_paths [
  "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
  "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
]
```

**New test to add:**
```elixir
test "operator detail templates have correct landmarks" do
  for path <- @detail_template_paths do
    content = File.read!(path)
    assert content =~ ~S|aria-label="Incident actions"|
    assert content =~ ~S|id="parapet-main"|
    assert content =~ "Skip to main content"
  end
end
```

**Extensions to existing `@live_template_paths` test** (insert in the `for path <- @live_template_paths do` block after line 187):
```elixir
# NAV-02: queue-refresh notification tokenized (no raw teal)
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

**Extensions to existing `@component_paths` test** (insert in the `for path <- @component_paths do` block after line 172, before the closing `end`):
```elixir
# NAV-01: nav-active border-bottom shape indicator
assert content =~ "border-bottom: 2px solid var(--parapet-accent)"

# DATA-03: timeline empty state copy
assert content =~ "No timeline entries yet"

# DATA-03: po-timeline-list class applied to <ul>
assert content =~ "po-timeline-list"

# DATA-03: spine suppression CSS selector
assert content =~ "li:last-child"

# DATA-06: animate-pulse defined in templates (zeroed by prefers-reduced-motion)
assert content =~ "animate-pulse"
```

---

## Shared Patterns

### Byte-mirror parity (CRITICAL — applies to every artifact in this phase)

**Source:** Phase 44/45 PATTERNS.md + `operator_ui_demo_contract_test.exs` (Phase 50 GUARD-03)
**Apply to:** All three template files and all three demo mirrors

Every change to a template must be applied byte-identically to its demo mirror in the SAME commit. Process one template+mirror pair per commit. Run after each pair:
```bash
mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs
```

Mirror pairs:
| Template | Demo Mirror |
|----------|-------------|
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` |

### `.parapet-ui .po-*` CSS selector scoping

**Source:** `operator_components.ex.eex` lines 321–397 (every existing `.po-*` rule)
**Apply to:** All new CSS rules (`.po-nav-active` border addition, `.po-timeline-list` spine suppression)

Every CSS rule must be prefixed `.parapet-ui` to avoid leaking into host application styles.

### `po-focus` group placement

**Source:** `operator_components.ex.eex` `control_base()` (line 1284, post-Phase-45); `operator_live.ex.eex` queue-refresh button (line 211)
**Apply to:** Skip-to-content link, pagination `pagination_link_class(true)` return value

Group: `focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus` — always all four together.

### `File.read!` + `assert content =~` / `refute content =~` test pattern

**Source:** `test/parapet/operator_ui_contrast_test.exs` lines 92–172 (`@component_paths` test) and 180–188 (`@live_template_paths` test)
**Apply to:** All new Phase 46 test assertions and the new `@detail_template_paths` test

```elixir
# Canonical test loop shape
for path <- @some_paths do
  content = File.read!(path)
  assert content =~ "expected_string"
  refute content =~ "forbidden_string"
end
```

### CSS variable color on inline SVG icons

**Source:** Queue-refresh notification button (operator_live.ex.eex line 211) and skip-link pattern from 46-RESEARCH.md
**Apply to:** All three decorative SVG icon additions in empty-state containers

Use `style="color: var(--parapet-text-muted);"` + `stroke="currentColor"` on the `<svg>` element. Do not use `text-[color:...]` Tailwind utility on SVG elements where `currentColor` inheritance is the color source.

---

## No Analog Found

All Phase 46 artifacts have close analogs in the codebase. No new patterns are introduced that require falling back to RESEARCH.md.

| File | Why analog is close enough |
|------|---------------------------|
| `aria-live="polite"` skeleton wrapper | No prior `aria-live` exists, but the `<%= if ... do %> / else / end %>` conditional wrapper is directly analogous to the `queue_refresh_available?` conditional (line 205). The `animate-pulse` class is already zeroed by the existing `prefers-reduced-motion` block. |

---

## Metadata

**Analog search scope:** `priv/templates/parapet.gen.ui/`, `examples/demo_app/lib/demo_app_web/live/parapet/`, `test/parapet/`
**Files read:** `operator_components.ex.eex` (lines 320–380, 688–760, 910–958), `operator_live.ex.eex` (lines 118–296, 460–484), `operator_detail_live.ex.eex` (lines 203–237), `operator_ui_contrast_test.exs` (lines 1–190), `45-PATTERNS.md` (full)
**Pattern extraction date:** 2026-06-25
