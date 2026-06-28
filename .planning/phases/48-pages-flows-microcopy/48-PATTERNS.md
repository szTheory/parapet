# Phase 48: Pages, flows & microcopy - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/parapet/operator.ex` | service | request-response | `lib/parapet/operator.ex` (existing `incident_detail/1`) | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | request-response | `operator_components.ex.eex` (existing empty states at `:728-738`, `:781-793`, `:961-974`) | exact |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | controller | request-response | `operator_live.ex.eex` (existing `handle_params`, skeleton `:247-253`) | exact |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | controller | request-response | `operator_detail_live.ex.eex` (existing `mount`/`handle_params`/`handle_event`) | exact |
| `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | config | request-response | `router_snippet.ex.eex` (existing route order `:16-17`) | exact |
| `examples/demo_app/lib/demo_app_web/components/layouts.ex` | config | request-response | `layouts.ex` (existing `<.live_title>` `:12`) | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/*.ex` | controller/component | request-response | `operator_live.ex.eex`, `operator_detail_live.ex.eex`, `operator_components.ex.eex` | exact (byte-parity mirrors) |
| `test/parapet/operator_ui_contrast_test.exs` | test | request-response | `operator_ui_contrast_test.exs` (existing `@*_paths` paired loops) | exact |
| `test/parapet/operator_ui_integration_test.exs` | test | request-response | `operator_ui_integration_test.exs` (existing `index_of/2`, verbatim copy pins `:186-196`) | exact |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | test | request-response | `operator_smoke_test.exs` (existing `ConnCase` + `get/2` + `live/2`) | exact |

---

## Pattern Assignments

### `lib/parapet/operator.ex` — additive `fetch_incident_detail/1` (D-01)

**Analog:** `lib/parapet/operator.ex` lines 107-152 (existing `incident_detail/1`)

**Existing function to keep unmodified** (lines 107-152):
```elixir
@doc since: "1.0.0"
@doc """
Fetches an incident by ID along with its timeline entries and returns a
workbench-ready map containing the incident, entries, and derived fields.
"""
def incident_detail(incident_id) do
  incident = Evidence.repo().get!(Incident, incident_id)
  # ... (rest of body unchanged)
end
```

**New additive function — copy this pattern, add UUID precheck + nil-guard:**
```elixir
# Pattern: Ecto.UUID.cast/1 collapses CastError class; Repo.get (not get!) + nil-guard
# collapses NoResultsError class. Both stale-link failures become {:error, :not_found}.
def fetch_incident_detail(incident_id) do
  case Ecto.UUID.cast(incident_id) do
    {:ok, uuid} ->
      case Evidence.repo().get(Incident, uuid) do
        nil -> {:error, :not_found}
        incident ->
          # delegate to the same body as incident_detail/1 but return {:ok, detail}
          {:ok, build_detail(incident)}
      end
    :error ->
      {:error, :not_found}
  end
end
```

**Key rule:** Do NOT alter `incident_detail/1` success shape or signature. `fetch_incident_detail/1` is purely additive. Extract shared body into a private `build_detail/1` so both public fns share it without duplication.

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` — multiple edits

#### A. Demote `operator_nav` h1 → `<p>` (D-05)

**Analog:** lines 537-554 (existing `operator_nav`)

**Current pattern to change** (line 543):
```heex
<h1 class="po-operator-title mt-1 text-lg font-semibold">Active response workbench</h1>
```

**Target pattern** (same class, tag demoted):
```heex
<p class="po-operator-title mt-1 text-lg font-semibold">Active response workbench</p>
```

Note: The integration test refute at line 200 checks `text-white">Active response workbench` (a palette class, not the tag) — the tag change is safe.

#### B. `incident_summary` heading-level prop (D-06)

**Analog:** lines 832-840 (existing `incident_summary` attr block + h1)

**Current pattern** (line 832-840):
```elixir
attr(:detail, :map, required: true)
attr(:operator_base_path, :string, default: "/parapet")

def incident_summary(assigns) do
  ~H"""
  <div class="min-w-0 overflow-hidden">
    ...
    <h1 class="max-w-xs whitespace-normal break-words text-2xl font-bold text-stone-900 sm:max-w-none sm:text-balance">
      <%= @detail.incident.title %>
    </h1>
```

**Target pattern** — add `heading_level` attr, default `"h2"` (detail page passes `"h1"`):
```elixir
attr(:detail, :map, required: true)
attr(:operator_base_path, :string, default: "/parapet")
attr(:heading_level, :string, default: "h2")

def incident_summary(assigns) do
  ~H"""
  <div class="min-w-0 overflow-hidden">
    ...
    # Use Phoenix.HTML.Tag or a simple cond:
    <%%= if @heading_level == "h1" do %>
      <h1 class="max-w-xs whitespace-normal break-words text-2xl font-bold text-stone-900 sm:max-w-none sm:text-balance">
        <%%= @detail.incident.title %>
      </h1>
    <%% else %>
      <h2 class="max-w-xs whitespace-normal break-words text-2xl font-bold text-stone-900 sm:max-w-none sm:text-balance">
        <%%= @detail.incident.title %>
      </h2>
    <%% end %>
```

#### C. New `incident_not_found` panel component (D-02)

**Analog:** Actions empty state (lines 728-738) — dashed-border, centered, icon + heading + body + action link

**Pattern to copy from** (lines 729-737):
```heex
<div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">
  <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
       fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
    <path stroke-linecap="round" stroke-linejoin="round" d="..." />
  </svg>
  <p class="text-sm font-semibold text-stone-800">No pending action items</p>
  <p class="mt-2 text-sm text-stone-500">Recovery work appears here ...</p>
</div>
```

**New component pattern** (add attr block + component, place near other empty states):
```elixir
attr(:operator_base_path, :string, default: "/parapet")
attr(:requested_id, :string, required: true)

def incident_not_found(assigns) do
  ~H"""
  <div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-8 text-center shadow-sm">
    <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8"
         style="color: var(--parapet-text-muted);"
         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
      <%#- Use an appropriate single-line-weight icon, e.g. archive/document-missing %>
    </svg>
    <h1 class="mt-3 text-sm font-semibold" style="color: var(--parapet-text);">
      This incident isn't in the evidence store
    </h1>
    <p class="mt-2 text-sm" style="color: var(--parapet-text-muted);">
      No durable incident matches this link. It may have been pruned by retention, or the
      link is stale. Active incidents stay in the response queue until resolved.
    </p>
    <div class="mt-6 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
      <.link navigate={@operator_base_path} class={[control_class(:primary)]}>
        Back to active response
      </.link>
      <.link navigate={@operator_base_path <> "/history"} class={[control_class(:secondary)]}>
        View resolved history
      </.link>
    </div>
    <p class="mt-4 text-xs font-mono" style="color: var(--parapet-text-muted);">
      Requested id: <%%= @requested_id %>
    </p>
  </div>
  """
end
```

**Critical:** `@requested_id` is interpolated as escaped text content only — never in an `href` or `id` attribute. Phoenix HEEx escapes `<%= %>` by default; `@requested_id` must never flow into raw HTML attributes.

#### D. Empty-state anatomy standardization + skeleton extension (D-09, D-10, D-11)

**Analog — existing designed empty states to use as the template:**

Actions empty (lines 728-738) — dashed border, `var(--parapet-text-muted)` icon:
```heex
<div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">
  <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);" ...>
  <p class="text-sm font-semibold text-stone-800">No pending action items</p>
  <p class="mt-2 text-sm text-stone-500">...</p>
</div>
```

Timeline empty (lines 962-974) — uses `var(--parapet-text)` + `var(--parapet-text-muted)` tokens:
```heex
<div class="flex min-h-[12rem] items-center justify-center text-center px-4 py-8">
  <div>
    <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);" ...>
    <p class="text-sm font-semibold" style="color: var(--parapet-text);">No timeline entries yet</p>
    <p class="mt-1 text-sm" style="color: var(--parapet-text-muted);">...</p>
  </div>
</div>
```

Bare `text-stone-*` empties to migrate (`:781`, `:961`):
```heex
<%# Current (bare stone tokens — migrate to --parapet-* vars): %>
<p class="text-sm font-semibold text-stone-800">No active incidents</p>
<p class="mt-2 text-sm text-stone-500">...</p>
```

**Target anatomy for all non-hero empty states:**
```heex
<%# dashed-border container — no hover:/transition (D-11 audit rule) %>
<div class="rounded-xl border border-dashed border-[color:var(--parapet-border)] bg-white/70 p-6 text-center shadow-sm">
  <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);" ...>
  <p class="text-sm font-semibold" style="color: var(--parapet-text);">Heading</p>
  <p class="mt-2 text-sm" style="color: var(--parapet-text-muted);">Guidance body.</p>
  <%# optional single next-action link %>
  <.link navigate={...} class="mt-4 inline-block text-sm font-medium underline" style="color: var(--parapet-accent);">...</.link>
</div>
```

**Gate empty states on `@socket_connected` (D-10):**
```heex
<%%= if @socket_connected and Enum.empty?(@incidents) do %>
  <%#- empty state here %>
<%% end %>
```

**Skeleton pattern to extend** (existing `:247-253`):
```heex
<div aria-live="polite" aria-busy={if !@socket_connected, do: "true", else: "false"}>
  <%%= if !@socket_connected do %>
    <div class="animate-pulse space-y-3" aria-hidden="true">
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
    </div>
  <%% else %>
    <%#- real list here %>
  <%% end %>
</div>
```

Copy this exact structure for Actions and History lists (`h-16` = real row height, zero layout shift, no literal "Loading…" text).

#### E. Mobile overflow fixes (D-16)

**Analog — `preview_panel` wrapper** (lines 1194-1196):
```heex
<div class="po-preview-reveal fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div role="region" aria-label="Recovery Preview"
       class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
```

**R1 fix — add height bounds to prevent clipping on short viewports:**
```heex
<div class="po-preview-reveal fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6 max-h-[100dvh]">
  <div role="region" aria-label="Recovery Preview"
       class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden max-h-[calc(100dvh-2rem)] overflow-y-auto overscroll-contain">
```

**Analog — `action_item_card` header** (lines 1343-1345):
```heex
<div class={surface_class(:action_card)}>
  <div class="flex justify-between items-start mb-2">
    <h4 class="text-sm font-medium text-stone-900"><%%= @item.title || "Action Item" %></h4>
```

**R2 fix — `min-w-0` on flex parent, `break-all` for `external_id`:**
```heex
<div class="flex justify-between items-start mb-2 min-w-0">
  ...
  <%#- wherever external_id is rendered: %>
  <span class="break-all font-mono"><%%= @item.external_id %></span>
```

**Analog — `preview_panel` data grid** (line 1205):
```heex
<div class="grid grid-cols-2 gap-4 mb-4">
```

**R3 fix:**
```heex
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <p class="text-xs text-stone-500 uppercase font-bold">Target Kind</p>
    <p class="text-sm font-medium text-stone-900 min-w-0 break-words"><%%= preview.data["target_kind"] %></p>
  </div>
```

**R5 fix — runbook step text wrapper** (line ~1128, `flex-1`):
```heex
<%#- change flex-1 → flex-1 min-w-0; h4/p get break-words; button column stays shrink-0 %>
<div class="flex-1 min-w-0">
  <h4 class="text-sm font-semibold break-words">...</h4>
  <p class="text-sm break-words">...</p>
</div>
<div class="shrink-0">
  <%#- button %>
</div>
```

#### F. Microcopy rewrites (D-13)

**Analog — existing verbatim copy pins** (`operator_ui_integration_test.exs` lines 186-196):
```elixir
assert content =~
         "Preview scoped changes before execution. No recovery action runs until confirm."
assert content =~
         "Execute bounded recovery. Writes a durable audit record with actor, reason, correlation id, and outcome."
```

These are pinned — do not churn. Only replace the 10+1 strings listed in D-13:

| Location | Old string (partial) | New string |
|---|---|---|
| `operator_components.ex.eex:1118` | (untitled runbook fallback) | `"Untitled runbook"` |
| `operator_components.ex.eex:1121` | (no description fallback) | `"No runbook description was recorded. Follow the steps below; each one previews before it runs."` |
| `operator_components.ex.eex:1249` | `"Preview is active."` | `"This preview reflects scoped changes only — nothing has run. Confirm to execute, or close to discard."` |
| `operator_detail_live.ex.eex:36` | `"Incident acknowledged successfully"` | `"Incident acknowledged. Audit record and timeline entry written."` |
| `operator_detail_live.ex.eex:40` | `"Failed to acknowledge"` | `"Acknowledge didn't complete — no audit record was written. The incident is unchanged; refresh the timeline, then retry."` |
| `operator_detail_live.ex.eex:59` | `"Failed to resolve"` | `"Resolve didn't complete — the incident stays in its current state and no audit record was written. Refresh the timeline, then retry."` |
| `operator_detail_live.ex.eex:81` | `"Failed to request escalation: #{inspect(reason)}"` | `"Couldn't record the escalation request — no escalation was triggered. Refresh to confirm current status, then retry."` |
| `operator_detail_live.ex.eex:111` | (suppress fail) | `"Couldn't record the suppression — pending escalation is unchanged. Refresh current status, then retry."` |
| `operator_detail_live.ex.eex:115` | (invalid window) | `"Suppression window must be a whole number of minutes greater than zero."` |
| `operator_detail_live.ex.eex:137` | (preview fail) | `"Preview couldn't be generated — nothing has run and the incident is unchanged. Refresh the timeline, then retry."` |
| `operator_detail_live.ex.eex:181` | (confirm fail) | `"Recovery did not execute — nothing was changed and no audit record was written. Refresh the timeline to confirm current state before retrying."` |

---

### `priv/templates/parapet.gen.ui/operator_live.ex.eex` — page semantics + titles

#### A. Per-page h1 headings (D-06)

**Analog — existing History h2** (line 161):
```heex
<h2 class="mt-1 text-2xl font-semibold text-stone-950 text-balance">Review resolved incidents</h2>
```

**Promotion pattern (History):** change `<h2>` → `<h1>` for the History page heading; demote any now-conflicting sibling h2.

**Response page — sr-only h1** (place at top of `<main>`, before the cockpit section):
```heex
<h1 class="sr-only">Active response</h1>
```

**Actions page — visible h1** (place at top of Actions `<main>`):
```heex
<h1 class="...">Action queue</h1>
```

#### B. `:page_title` assigns via `handle_params` (D-07)

**Analog — existing `handle_params` assign block** (lines 39-60):
```elixir
def handle_params(params, uri, socket) do
  page_mode = page_mode(socket.assigns.live_action)
  ...
  {:noreply,
   socket
   |> assign(operator_base_path: operator_base_path)
   |> assign(
     selected_incident: selected,
     ...
     socket_connected: true
   )
```

**Pattern to add** — private helper + assign in `handle_params`:
```elixir
defp page_title(:index, _params), do: "Active response"
defp page_title(:actions, _params), do: "Action queue"
defp page_title(:history, _params), do: "Resolved history"

# In handle_params, add to the assign block:
|> assign(:page_title, page_title(socket.assigns.live_action, params))
```

**Analog — LiveDashboard / Oban Web convention:** assign `:page_title` in `handle_params`; host layout's `<.live_title>` consumes it. Never auto-patch the host layout — that's the host's seam.

#### C. Connected-skeleton pattern for Actions/History lists

**Analog — existing Response queue skeleton** (lines 247-253):
```heex
<div aria-live="polite" aria-busy={if !@socket_connected, do: "true", else: "false"}>
  <%%= if !@socket_connected do %>
    <div class="animate-pulse space-y-3" aria-hidden="true">
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
      <div class="h-16 rounded-lg bg-[color:var(--parapet-panel-muted)]"></div>
    </div>
  <%% else %>
    <.incident_list ... />
  <%% end %>
</div>
```

Copy this exact structure wrapping the Actions and History `<.incident_list>` / `<.action_item_list>` calls.

---

### `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — not-found state + page semantics

#### A. `mount`/`handle_params` switch to `fetch_incident_detail/1` (D-01)

**Analog — existing mount/handle_params** (lines 9-19):
```elixir
def mount(%{"id" => id}, _session, socket) do
  selected = Parapet.Operator.incident_detail(id)
  {:ok, assign(socket, incident: selected, operator_base_path: @default_operator_base_path)}
end

def handle_params(%{"id" => id}, uri, socket) do
  {:noreply,
   socket
   |> assign(operator_base_path: operator_base_path(uri))
   |> assign(incident: Parapet.Operator.incident_detail(id))}
end
```

**Target pattern:**
```elixir
def mount(%{"id" => id}, _session, socket) do
  case Parapet.Operator.fetch_incident_detail(id) do
    {:ok, detail} ->
      {:ok, assign(socket,
        incident: detail,
        incident_not_found: false,
        requested_id: id,
        operator_base_path: @default_operator_base_path
      )}
    {:error, :not_found} ->
      {:ok, assign(socket,
        incident: nil,
        incident_not_found: true,
        requested_id: id,
        operator_base_path: @default_operator_base_path
      )}
  end
end
```

**All 6 `handle_event` refresh sites** — replace `Parapet.Operator.incident_detail(id)` with `fetch_incident_detail/1` and assign `incident_not_found: false` on success, `incident_not_found: true` on `{:error, :not_found}`.

**Analog — existing `handle_event("trigger_next_escalation")` refresh** (lines 78-79):
```elixir
|> assign(incident: Parapet.Operator.incident_detail(id))
```

**Target:**
```elixir
case Parapet.Operator.fetch_incident_detail(id) do
  {:ok, detail} -> assign(socket, incident: detail, incident_not_found: false)
  {:error, :not_found} -> assign(socket, incident: nil, incident_not_found: true)
end
```

#### B. `page_title/2` helper (D-07)

**Pattern** — add to private helpers at bottom of file:
```elixir
defp page_title(:show, %{"id" => _id} = _params, %{incident: %{incident: %{title: title}}})
     when is_binary(title), do: "Incident: #{title}"
defp page_title(_action, _params, _assigns), do: "Incident detail"
```

And assign in `handle_params`:
```elixir
|> assign(:page_title, page_title(socket.assigns.live_action, params, socket.assigns))
```

#### C. Landmark nav wrap for back-link context strip (D-08)

**Analog — existing context strip** (lines 215-222):
```heex
<div class="border-b border-stone-200 bg-white px-4 py-3 md:px-6">
  <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
    <.link navigate={detail_back_path(@operator_base_path, @incident)} ...>
```

**Target:**
```heex
<nav aria-label="Incident context" class="border-b border-stone-200 bg-white px-4 py-3 md:px-6">
  <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
    <.link navigate={detail_back_path(@operator_base_path, @incident)} ...>
```

#### D. `incident_summary` heading-level prop usage (D-06)

**Analog — current usage** (line 228):
```heex
<.incident_summary detail={@incident} />
```

**Target** — detail page is the subject page, so `<h1>`:
```heex
<.incident_summary detail={@incident} heading_level="h1" />
```

Response cockpit usage in `operator_live.ex.eex` gets the default `heading_level="h2"` (no change needed there).

#### E. Render `incident_not_found` component in the `render/1` (D-02)

**Analog — existing render guard for runbook/preview** (lines 242-248):
```heex
<%%= if @incident.derived.runbook_steps != [] do %>
  <.runbook_card detail={@incident} />
<%% end %>
<%%= if @incident.incident.state != "resolved" && @incident.derived.active_preview do %>
  <.preview_panel detail={@incident} />
<%% end %>
```

**Target — top-level render branch:**
```heex
<%%= if @incident_not_found do %>
  <main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
    <div class="mx-auto max-w-2xl">
      <.incident_not_found
        operator_base_path={@operator_base_path}
        requested_id={@requested_id}
      />
    </div>
  </main>
<%% else %>
  <%#- existing main content %>
<%% end %>
```

---

### `priv/templates/parapet.gen.ui/router_snippet.ex.eex` — route ordering regression (D-04)

**Analog — existing route block** (lines 13-17):
```elixir
#     live "/parapet", <%= inspect(@web_module) %>.Parapet.OperatorLive, :index
#     live "/parapet/actions", <%= inspect(@web_module) %>.Parapet.OperatorLive, :actions
#     live "/parapet/history", <%= inspect(@web_module) %>.Parapet.OperatorLive, :history
#     live "/parapet/incidents/:id", <%= inspect(@web_module) %>.Parapet.OperatorDetailLive, :show
#     live "/parapet/:id", <%= inspect(@web_module) %>.Parapet.OperatorDetailLive, :show
```

Confirmed: `/parapet/incidents/:id` already declared before `/parapet/:id`. Ensure the comment "keep `:id` catch-all LAST" is present. Add the router-ordering regression assert in the integration test using `index_of/2`.

---

### `examples/demo_app/lib/demo_app_web/components/layouts.ex` — page title patch (D-07)

**Analog — existing hardcoded title** (line 12):
```heex
<.live_title>Demo App</.live_title>
```

**Target** — enable runtime page titles while preserving "Demo App" fallback:
```heex
<.live_title suffix=" · Parapet">{assigns[:page_title] || "Demo App"}</.live_title>
```

This is the only demo-owned file that needs this patch. Do NOT auto-patch host root layouts.

---

### Test files — assertion patterns (D-18)

#### `test/parapet/operator_ui_integration_test.exs` — source-string assertions

**Analog — existing `index_of/2` helper** (lines 4-9):
```elixir
defp index_of(content, needle) do
  case :binary.match(content, needle) do
    {index, _length} -> index
    :nomatch -> nil
  end
end
```

**Pattern for route-ordering regression assert:**
```elixir
assert index_of(content, ~S|/parapet/incidents/:id|) <
         index_of(content, ~S|/parapet/:id|)
```

**Pattern for `:page_title` source assert** (FLOW-02 source check):
```elixir
assert content =~ ":page_title"
assert content =~ "page_title("
```

**Pattern for COPY-04 bounded-regex refutes:**
```elixir
refute content =~ ~r/\b(TODO|FIXME|XXX|HACK)\b/
refute content =~ ~r/\blorem ipsum\b/i
refute content =~ ~r/placeholder text/i
```

**Pattern for verbatim copy pins** (extend the `:186-196` block style):
```elixir
assert content =~
         "Acknowledge didn't complete — no audit record was written. The incident is unchanged; refresh the timeline, then retry."
assert content =~
         "This incident isn't in the evidence store"
```

#### `examples/demo_app/test/demo_app/operator_smoke_test.exs` — rendered assertions

**Analog — existing `get/2` + `resp_body` pattern** (lines 6-9, 33-36):
```elixir
test "GET /parapet returns 200", %{conn: conn} do
  conn = get(conn, "/parapet")
  assert conn.status == 200
end

test "GET /parapet/history returns 200", %{conn: conn} do
  {:ok, _incident} = Parapet.Evidence.create_incident(%{title: "...", state: "resolved"})
  conn = get(conn, "/parapet/history")
  assert conn.status == 200
  assert conn.resp_body =~ "resolved history smoke incident"
end
```

**Pattern for FLOW-02 single-h1 rendered assert** (use `get/2` static render — no Floki, DOM backend is `lazy_html`):
```elixir
test "each page renders exactly one h1", %{conn: conn} do
  for path <- ["/parapet", "/parapet/actions", "/parapet/history"] do
    conn = get(conn, path)
    html = conn.resp_body
    assert length(Regex.scan(~r/<h1[\s>]/, html)) == 1,
           "Expected exactly one h1 on #{path}"
  end
end
```

**Pattern for FLOW-03 not-found rendered assert:**
```elixir
test "detail with unknown UUID renders not-found panel in-page", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/parapet/incidents/#{Ecto.UUID.generate()}")
  assert has_element?(view, "[data-testid='incident-not-found']") or
         render(view) =~ "This incident isn't in the evidence store"
end

test "detail with malformed id renders not-found panel in-page", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/parapet/123")
  assert render(view) =~ "This incident isn't in the evidence store"
end
```

**Pattern for `page_title` rendered assert:**
```elixir
test "page titles are set per page", %{conn: conn} do
  {:ok, view, _} = live(conn, "/parapet")
  assert page_title(view) =~ "Active response"
  {:ok, view, _} = live(conn, "/parapet/actions")
  assert page_title(view) =~ "Action queue"
end
```

**Pattern for disconnected skeleton assert:**
```elixir
test "static render includes skeleton markup", %{conn: conn} do
  conn = get(conn, "/parapet")
  assert conn.resp_body =~ "animate-pulse"
  assert conn.resp_body =~ ~s(aria-busy="true")
end
```

**Pattern for A11Y landmark cross-check:**
```elixir
test "main landmark present", %{conn: conn} do
  {:ok, view, _} = live(conn, "/parapet")
  assert has_element?(view, "main#parapet-main")
  assert has_element?(view, "nav[aria-label]")
end
```

---

## Shared Patterns

### Escape rule for untrusted URL input (D-02)
**Source:** Phoenix HEEx default escaping
**Apply to:** `incident_not_found` component, anywhere `@requested_id` is rendered

```heex
<%#- CORRECT — escaped text content only, never in href/id/attribute %>
<p class="text-xs font-mono" style="color: var(--parapet-text-muted);">
  Requested id: <%%= @requested_id %>
</p>
<%#- NEVER: href={"/parapet/incidents/#{@requested_id}"} or id={@requested_id} %>
```

### Token-driven empty/error states (D-11)
**Source:** `operator_components.ex.eex:961-974` (timeline empty state — best token practice)
**Apply to:** all empty states, not-found panel, skeleton containers

Use `style="color: var(--parapet-text-muted);"` for icons and secondary text, `style="color: var(--parapet-text);"` for headings. Do not use bare `text-stone-500` / `text-stone-800` on new or migrated empties.

### `socket_connected` guard on empty states (D-10)
**Source:** `operator_live.ex.eex:33` (`socket_connected: connected?(socket)` in mount) + `:247` (`!@socket_connected` skeleton guard)
**Apply to:** every `Enum.empty?` empty-state render

```heex
<%%= if @socket_connected and Enum.empty?(@items) do %>
  <%#- designed empty state %>
<%% end %>
```

### Demo-mirror parity
**Source:** Phase 44 CONTEXT.md constraint — every `.eex` edit lands in its `examples/demo_app/lib/demo_app_web/live/parapet/*.ex` mirror in the same task.

Mirrors are:
- `operator_live.ex.eex` → `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`
- `operator_detail_live.ex.eex` → `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`
- `operator_components.ex.eex` → `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`

### No `inspect` in user-facing flash strings (D-13, D-15)
**Source:** `operator_detail_live.ex.eex:81` (anti-pattern: `"Failed to request escalation: #{inspect(reason)}"`)
**Apply to:** all `put_flash/3` calls in `operator_detail_live.ex.eex`

Remove all `#{inspect(reason)}` from flash strings. Keep `Logger.error(inspect(reason))` for server-side logging.

---

## No Analog Found

All files in this phase have close analogs. No fallback to RESEARCH.md patterns needed.

---

## Metadata

**Analog search scope:** `lib/parapet/`, `priv/templates/parapet.gen.ui/`, `examples/demo_app/`, `test/parapet/`, `examples/demo_app/test/`
**Files scanned:** 10 source files read directly
**Pattern extraction date:** 2026-06-26
