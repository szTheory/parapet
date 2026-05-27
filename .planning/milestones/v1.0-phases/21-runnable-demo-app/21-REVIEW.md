---
phase: 21
status: issues
depth: standard
reviewed_files: 27
critical_count: 2
warning_count: 4
info_count: 3
---

# Phase 21 Code Review

## Summary

The demo app skeleton, migrations, seeds, CI wiring, and router are all sound. Seeds use only `Parapet.Evidence.*` Stable API with string-keyed JSONB maps throughout. The CI `release_gate` correctly depends on `[test, demo]` with no `continue-on-error`. Two blockers prevent a fully functional demo: the resolved-history page will crash at runtime due to a struct field mismatch, and the app ships with no JavaScript, leaving LiveView purely static (no interactive events). Four warnings cover latent crashes and compilation noise.

---

## Findings

### Critical

---

#### CR-01: Resolved-history page crashes when any resolved incidents exist

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex:334-336`

**Issue:** `resolved_history_page/1` queries `Parapet.Spine.Incident` directly and produces a list of raw `%Parapet.Spine.Incident{}` structs. It then passes those structs through `queue_stream_item/1`, which accesses `item.incident_id` (line 234). The `Incident` schema has no `:incident_id` field — only `:id`. On a struct, accessing a non-existent field raises `KeyError`. Because the seeds create a resolved incident, clicking the "History" link immediately triggers this crash for every visitor of the demo.

`WorkbenchContract.queue_row/1` (the path the active-queue takes) correctly maps `incident.id → :incident_id`, but `resolved_history_page` bypasses that mapping.

**Fix:**
```elixir
# In resolved_history_page/1, replace the direct Repo.all() result:
# BEFORE
items: Enum.map(visible_items, &queue_stream_item/1),

# AFTER — map through WorkbenchContract first, just like the active queue does
alias Parapet.Operator.WorkbenchContract
items: Enum.map(visible_items, fn inc -> inc |> WorkbenchContract.queue_row() |> queue_stream_item() end),
```

---

#### CR-02: No JavaScript asset — LiveView is entirely non-interactive

**File:** `examples/demo_app/lib/demo_app_web/components/layouts.ex` (root template), `examples/demo_app/assets/` (directory)

**Issue:** The app has no `assets/js/` directory, no `assets/js/app.js` entry point, no esbuild or npm setup, and the root layout includes only `app.css` — no `<script>` tag. Without `phoenix.js` loaded in the browser, the LiveView WebSocket connection is never established. Every `phx-click` event (Acknowledge, Resolve, Trigger Escalation, Suppress, Preview, Confirm, History navigation via patch) is silently dropped. The demo renders a static snapshot of seeded data but is entirely non-interactive. The CI smoke test only asserts HTTP 200, so the gate passes while the phase goal of a "functional Operator UI" is unmet.

**Fix:** Add `assets/js/app.js` importing phoenix and phoenix_live_view, wire esbuild (or import from Phoenix's priv/static via CDN), and include the script tag in the root layout:

```heex
# In layouts.ex root/1, add before </head>:
<script src={~p"/assets/app.js"} defer></script>
```

```javascript
// assets/js/app.js
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: ""}})
liveSocket.connect()
window.liveSocket = liveSocket
```

And add esbuild to `mix.exs` deps and aliases:
```elixir
{:esbuild, "~> 0.8", runtime: Mix.env() == :dev}
```

---

### Warnings

---

#### WR-01: `action_item_card/1` crashes with `nil[:ui_url_resolver]` when `:scoria` is not configured

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex:461`

**Issue:** `resolver = Application.get_env(:parapet, :scoria)[:ui_url_resolver]` — when `:scoria` is not configured (as in the demo app), `Application.get_env` returns `nil`. Accessing `nil[:ui_url_resolver]` raises `UndefinedFunctionError` because `nil` does not implement the `Access` protocol. The demo app seeds no action items so this is not triggered in CI, but any host that seeds action items will see a crash.

**Fix:**
```elixir
resolver =
  case Application.get_env(:parapet, :scoria) do
    config when is_list(config) -> Keyword.get(config, :ui_url_resolver)
    config when is_map(config) -> Map.get(config, :ui_url_resolver)
    _ -> nil
  end
```

---

#### WR-02: `Repo.get!` in LiveView event handlers crashes the process on unknown IDs

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex:68,90`; `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex:14,34,51,72,104,124`

**Issue:** Every event handler fetches the incident with `DemoApp.Repo.get!(Parapet.Spine.Incident, id)` where `id` comes from user-controlled `phx-value-id`. If the ID is invalid or the incident was deleted between page load and click, `Ecto.NoResultsError` terminates the LiveView process and renders a 500 to the user.

**Fix:** Use `Repo.get/2` (returns `nil`) and handle the not-found case explicitly, or wrap in a `rescue`:
```elixir
case DemoApp.Repo.get(Parapet.Spine.Incident, id) do
  nil -> {:noreply, put_flash(socket, :error, "Incident not found")}
  incident -> # proceed
end
```

---

#### WR-03: `import Phoenix.LiveView.Helpers` is deprecated

**File:** `examples/demo_app/lib/demo_app_web.ex:73`

**Issue:** `Phoenix.LiveView.Helpers` still exists in LiveView 1.1.30 as a deprecated compatibility shim, so the import compiles and all existing fns are re-exported from `Phoenix.Component`. However, every compilation will emit deprecation warnings for the import and for any functions used from it. If Phoenix.LiveView removes the shim in a future 1.x release, the app will break without any code change.

**Fix:**
```elixir
# Remove:
import Phoenix.LiveView.Helpers

# Functions like live_patch/live_redirect were already replaced by <.link patch=...>
# and <.link navigate=...> which are in scope via Phoenix.Component (imported above).
```

---

#### WR-04: `operator_live.ex` directly queries `Parapet.Spine.Incident` — bypasses Stable API boundary

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex:321-381`

**Issue:** `resolved_history_page/1` constructs raw Ecto queries against `Parapet.Spine.Incident` directly. This bypasses the `Parapet.Evidence` and `Parapet.Operator` Stable API boundary. If the spine schema changes (column rename, new index, row-level security) in a future Parapet version, this private query will silently break without a deprecation notice. The direct `Repo.get!` calls in event handlers (lines 68, 90) have the same issue but are more excusable as one-line lookups.

**Fix:** Expose a `Parapet.Operator.list_resolved_incidents/1` function in the Stable API (analogous to `list_incident_queue/1`) and delegate to it. Until then, add a `# DEMO ONLY — not a pattern for production use` comment on the raw-query block so adopters who read this code do not copy the pattern.

---

### Info

---

#### IN-01: Root layout missing CSRF meta tag and live-reload script

**File:** `examples/demo_app/lib/demo_app_web/components/layouts.ex:5-20`

**Issue:** The root layout omits `<meta name="csrf-token" content={get_csrf_token()} />` (needed by phoenix.js for AJAX-style requests) and the `<.live_reload :if={@socket.endpoint.code_reloading?} />` component (dev hot-reload). Once JavaScript is wired (CR-02 fix), these absences will produce console errors and missing hot-reload.

**Fix:** Add both to the `<head>` block:
```heex
<meta name="csrf-token" content={get_csrf_token()} />
<.live_reload :if={@socket.endpoint.code_reloading?} />
```

---

#### IN-02: `DemoApp.ParapetInstrumenter.setup/0` is defined but never called

**File:** `examples/demo_app/lib/demo_app/parapet_instrumenter.ex:4-8`; `examples/demo_app/lib/demo_app/application.ex`

**Issue:** `DemoApp.ParapetInstrumenter.setup/0` calls `Parapet.Metrics.Probe.setup/0` but is never invoked — not in `Application.start/2` and not in any other startup path. Metrics telemetry events will not be attached.

**Fix:** Call it from `Application.start/2`:
```elixir
def start(_type, _args) do
  DemoApp.ParapetInstrumenter.setup()
  # ...
end
```

---

#### IN-03: Tailwind content glob is redundant — both parent and child paths included

**File:** `examples/demo_app/assets/tailwind.config.js:6-10`

**Issue:** The content array includes both `"../lib/demo_app_web/**/*.{ex,heex}"` (which already covers all subdirectories recursively) **and** `"../lib/demo_app_web/live/parapet/**/*.ex"` (a subset of the first glob). The second entry is redundant and adds a stale comment implying it covers something the first does not.

**Fix:** Remove the redundant second glob:
```js
content: [
  "./js/**/*.js",
  "../lib/demo_app_web/**/*.{ex,heex}",
  "../../../priv/templates/parapet.gen.ui/*.eex"
],
```

---

## Files Reviewed

- `examples/demo_app/mix.exs`
- `examples/demo_app/.formatter.exs`
- `examples/demo_app/.gitignore`
- `examples/demo_app/config/config.exs`
- `examples/demo_app/config/dev.exs`
- `examples/demo_app/config/test.exs`
- `examples/demo_app/lib/demo_app/application.ex`
- `examples/demo_app/lib/demo_app/repo.ex`
- `examples/demo_app/lib/demo_app/parapet_instrumenter.ex`
- `examples/demo_app/lib/demo_app_web.ex`
- `examples/demo_app/lib/demo_app_web/endpoint.ex`
- `examples/demo_app/lib/demo_app_web/telemetry.ex`
- `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`
- `examples/demo_app/lib/demo_app_web/components/layouts.ex`
- `examples/demo_app/lib/demo_app_web/controllers/error_html.ex`
- `examples/demo_app/lib/demo_app_web/router.ex`
- `examples/demo_app/assets/css/app.css`
- `examples/demo_app/assets/tailwind.config.js`
- `examples/demo_app/README.md`
- `examples/demo_app/priv/repo/seeds.exs`
- `examples/demo_app/test/test_helper.exs`
- `examples/demo_app/test/support/conn_case.ex`
- `examples/demo_app/test/demo_app/operator_smoke_test.exs`
- `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs`
- `.github/workflows/ci.yml`
- `docs/getting-started.md`

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
