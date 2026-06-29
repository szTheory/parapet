# Phase 44: Foundations — token re-skin, fonts & audit apparatus - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 13
**Analogs found:** 11 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | template/config | request-response | self (values-only edit) | exact — in-place reskin |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | component | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact — mirror file |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | template | request-response | self (secondary color edits only) | exact |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | template | request-response | self (secondary color edits only) | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` | live_view | request-response | self (mirror of template) | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` | live_view | request-response | self (mirror of template) | exact |
| `priv/static/parapet/fonts/*.woff2` + `LICENSE.txt` | static asset | file-I/O | no analog — binary assets | no analog |
| `lib/mix/tasks/parapet.gen.ui.ex` | generator/utility | file-I/O | self (add `run/1` override) | exact — extend in place |
| `examples/demo_app/lib/demo_app_web/router.ex` | config/route | request-response | self (additive gallery route) | exact |
| `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` | live_view | request-response | `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` | role-match |
| `examples/demo_app/lib/demo_app_web.ex` | config | request-response | self (additive `static_paths`) | exact |
| `brandbook/notes/operator-audit-matrix.md` | doc/ledger | — | `brandbook/notes/accessibility.md` | partial — same dir, markdown table |
| `test/parapet/operator_ui_contrast_test.exs` | test | batch | self (re-pin `@themes`, add assertions) | exact |
| `test/parapet/operator_ui_demo_contract_test.exs` | test | batch | self (additive assertions only) | exact |
| `test/parapet/operator_ui_fonts_test.exs` | test | file-I/O | `test/parapet/operator_ui_contrast_test.exs` | role-match |
| `mix.exs` | config | — | self (extend `files:` list) | exact |

---

## Pattern Assignments

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (template, values-only reskin)

**Analog:** self — `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Three CSS blocks to rewrite** (all `--parapet-*` and `--po-*` values; selectors/class rules untouched):

**Block 1 — light (lines 8–60):** `.parapet-ui { ... }` — 16 `--parapet-*` vars + 34 `--po-*` vars
**Block 2 — explicit dark (lines 62–115):** `html[data-parapet-theme="dark"] .parapet-ui, html[data-parapet-theme="system"] .parapet-ui:is(.force-system-dark) { ... }`
**Block 3 — media-query dark (lines 123–176):** inside `@media (prefers-color-scheme: dark)`, same var list as Block 2

**Existing light block structure to replace** (lines 8–60):
```css
.parapet-ui {
  color-scheme: light;
  --parapet-bg: #f5f5f4;
  --parapet-panel: #ffffff;
  --parapet-panel-muted: #fafaf9;
  --parapet-text: #1c1917;
  --parapet-text-muted: #57534e;
  --parapet-border: #e7e5e4;
  --parapet-border-strong: rgba(28, 25, 23, 0.14);
  --parapet-shadow: 0 1px 2px rgba(28, 25, 23, 0.06), 0 0 0 1px rgba(28, 25, 23, 0.04);
  --parapet-accent: #0f766e;
  --parapet-accent-strong: #0f5f59;
  --parapet-accent-soft: #ccfbf1;
  --parapet-accent-text: #115e59;
  --parapet-warning-bg: #fffbeb;
  --parapet-warning-text: #78350f;
  --parapet-info-bg: #f5f3ff;
  --parapet-info-text: #4c1d95;
  --po-link: #1d4ed8;
  /* ... 33 more --po-* vars */
}
```

**Replacement light values** (copy verbatim from RESEARCH.md CSS Variable Inventory tables):
- `--parapet-bg: #F8F4EC` (limestone)
- `--parapet-panel: #FFFFFF`
- `--parapet-panel-muted: #EAE2D4` (mortar)
- `--parapet-text: #101820` (parapet-black)
- `--parapet-text-muted: #2E3A42` (wall-slate)
- `--parapet-border: rgba(16,24,32,0.12)`
- `--parapet-border-strong: rgba(16,24,32,0.14)`
- `--parapet-shadow: 0 1px 2px rgba(16,24,32,0.06), 0 0 0 1px rgba(16,24,32,0.04)`
- `--parapet-accent: #256C82` (watch-blue)
- `--parapet-accent-strong: #1A5066`
- `--parapet-accent-soft: #EFF6E8` (healthy-bg)
- `--parapet-accent-text: #256C82`
- `--parapet-warning-bg: #F8EFD7` (watch-bg)
- `--parapet-warning-text: #B45309` (beacon-amber)
- `--parapet-info-bg: #ECEBFF` (ai-bg)
- `--parapet-info-text: #4F46A5` (ai-text)
- `--po-link: #256C82`; `--po-link-hover: #1A5066`
- `--po-focus: #256C82`; `--po-focus-offset: #ffffff`
- `--po-header-bg: #FFFFFF`; `--po-header-border: rgba(16,24,32,0.12)`; `--po-header-title: #101820`; `--po-header-muted: #256C82`
- `--po-nav-fg: #2E3A42`; `--po-nav-hover-bg: #EAE2D4`; `--po-nav-hover-fg: #101820`; `--po-nav-active-bg: #EFF6E8`; `--po-nav-active-fg: #3F5E28`
- `--po-theme-control-bg: #F8F4EC`; `--po-theme-control-border: rgba(16,24,32,0.12)`; `--po-theme-control-fg: #2E3A42`
- Six chip triplets (from tokens.css lines 25-30, see RESEARCH.md status chip table):
  - neutral: bg `#ECEFF1`, fg `#2E3A42`, border `#CBD2D8`
  - success: bg `#EFF6E8`, fg `#3F5E28`, border `#B6C99A`
  - warning: bg `#F8EFD7`, fg `#92400E`, border `#E3B66E`
  - danger: bg `#FCE8E2`, fg `#9F2D2D`, border `#E3A19A`
  - info: bg `#ECEBFF`, fg `#4F46A5`, border `#B9B5F6`
- `--po-button-warning-bg: #B45309`; `--po-button-warning-fg: #ffffff`; `--po-button-warning-hover: #92400E`

**Replacement dark values** (both dark blocks must be byte-identical to each other):
- `--parapet-bg: #18232B` (deep-slate)
- `--parapet-panel: #2E3A42` (wall-slate)
- `--parapet-panel-muted: #101820` (parapet-black)
- `--parapet-text: #F8F4EC` (limestone)
- `--parapet-text-muted: #D8D0C3` (stone)
- `--parapet-border: rgba(248,244,236,0.16)`
- `--parapet-border-strong: rgba(248,244,236,0.20)`
- `--parapet-shadow: 0 1px 2px rgba(0,0,0,0.42), 0 0 0 1px rgba(248,244,236,0.08)`
- `--parapet-accent: #7FB4C6`; `--parapet-accent-strong: #A8D0DE`; `--parapet-accent-soft: rgba(37,108,130,0.16)`; `--parapet-accent-text: #A8D0DE`
- `--parapet-warning-bg: rgba(180,83,9,0.24)`; `--parapet-warning-text: #D97706`
- `--parapet-info-bg: rgba(109,91,208,0.24)`; `--parapet-info-text: #B9B5F6`
- `--po-link: #7FB4C6`; `--po-link-hover: #A8D0DE`
- `--po-focus: #F8F4EC` (limestone, D-06); `--po-focus-offset: #18232B`
- `--po-header-bg: #101820`; `--po-header-border: rgba(248,244,236,0.16)`; `--po-header-title: #F8F4EC`; `--po-header-muted: #7FB4C6`
- `--po-nav-fg: #D8D0C3`; `--po-nav-hover-bg: #2E3A42`; `--po-nav-hover-fg: #F8F4EC`; `--po-nav-active-bg: #3F5E28`; `--po-nav-active-fg: #F8F4EC`
- `--po-theme-control-bg: #18232B`; `--po-theme-control-border: rgba(248,244,236,0.16)`; `--po-theme-control-fg: #D8D0C3`
- Six chip triplets dark (inverted, from tokens.css):
  - neutral: bg `#2E3A42`, fg `#ECEFF1`, border `#556B77`
  - success: bg `#3F5E28`, fg `#EFF6E8`, border `#567236`
  - warning: bg `#92400E`, fg `#F8EFD7`, border `#B45309`
  - danger: bg `#9F2D2D`, fg `#FCE8E2`, border `#B13A32`
  - info: bg `#4F46A5`, fg `#ECEBFF`, border `#6D5BD0`
- `--po-button-warning-bg: #D97706`; `--po-button-warning-fg: #F8F4EC`; `--po-button-warning-hover: #B45309`

**New motion tokens to add** (append inside light `.parapet-ui { }` block after existing vars):
```css
--motion-fast: 120ms;
--motion-base: 200ms;
--motion-ease: cubic-bezier(.2, 0, 0, 1);
```

**Updated `prefers-reduced-motion` block** (existing block is at lines ~323-330; add motion var zeroing):
```css
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-fast: 0ms;
    --motion-base: 0ms;
  }
  .parapet-ui * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

**New `@font-face` block** (insert at top of `<style>`, before `.parapet-ui { ... }` rule, line 7):
```css
@font-face {
  font-family: "IBM Plex Sans";
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexSans-Regular-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Sans";
  font-style: normal;
  font-weight: 500;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexSans-Medium-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Sans";
  font-style: normal;
  font-weight: 600;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexSans-SemiBold-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Mono";
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexMono-Regular-latin.woff2") format("woff2");
}
@font-face {
  font-family: "IBM Plex Mono";
  font-style: normal;
  font-weight: 500;
  font-display: swap;
  src: url("/parapet/fonts/IBMPlexMono-Medium-latin.woff2") format("woff2");
}
```

**CRITICAL:** Also add `--font-sans` and `--font-mono` CSS vars inside `.parapet-ui { }` light block:
```css
--font-sans: "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif;
--font-mono: "IBM Plex Mono", ui-monospace, monospace;
```

---

### `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` (mirror — same edits)

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`

This file is a hand-maintained mirror of the EEx template (with `<%= ... %>` EEx expressions already evaluated). Apply **identical CSS variable value replacements** as the template. The contrast test reads `@component_paths` which includes this file (line 6 of contrast test). If this file diverges from the template on CSS variable values, the per-path string assertions fail.

Pattern: the file starts with `defmodule DemoAppWeb.Parapet.OperatorComponents do` (no EEx interpolation). The `<style>` block structure is identical to the template output. Make the same three-block CSS edit as the template.

---

### `priv/templates/parapet.gen.ui/operator_live.ex.eex` + `operator_detail_live.ex.eex` (secondary edits)

**Analog:** self

Secondary templates may contain hardcoded color references outside the `operator_theme_bootstrap/1` inline style. Scan for any hardcoded Tailwind color classes (e.g. `text-teal-*`, `bg-stone-*`, `text-blue-*`) that are not intercepted by the utility-interception layer in `operator_components.ex.eex`. If found, verify they are intercepted by the `.parapet-ui .bg-stone-*` rules — if not intercepted, replace with the semantically equivalent `var(--po-*)` class. Do NOT change markup structure, only token values.

---

### `lib/mix/tasks/parapet.gen.ui.ex` (generator — add `run/1` override for font copy)

**Analog:** self — `lib/mix/tasks/parapet.gen.ui.ex`

**Existing generator pattern** (lines 1–6, 17–66): Uses `use Igniter.Mix.Task`, implements `igniter/1` (not `run/1`). Three `Igniter.copy_template/4` calls with `on_exists: :skip`.

**Pattern to add** (append after the `igniter/1` function, before end of module):
```elixir
def run(argv) do
  super(argv)
  copy_fonts_to_host()
end

defp copy_fonts_to_host do
  source_dir = Path.join(:code.priv_dir(:parapet), "static/parapet/fonts")
  dest_dir   = Path.join(File.cwd!(), "priv/static/parapet/fonts")
  File.mkdir_p!(dest_dir)

  for filename <- File.ls!(source_dir) do
    File.cp!(Path.join(source_dir, filename), Path.join(dest_dir, filename))
  end

  Mix.shell().info(
    "* copying #{length(File.ls!(source_dir))} font files to priv/static/parapet/fonts/"
  )
end
```

**Critical:** `run/1` is `defoverridable` in `Igniter.Mix.Task` (verified from Igniter 0.7.9 source). Calling `super(argv)` runs the full Igniter pipeline first (all `copy_template` calls), then the font copy appends after. Do NOT use `Igniter.create_new_file` for binary woff2 data — it corrupts binary via UTF-8 string encoding.

---

### `mix.exs` (extend `files:` whitelist)

**Analog:** self — `mix.exs` lines 42–44

**Existing pattern** (lines 42–44):
```elixir
files:
  ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* LICENSE* docs),
```

**Replacement:** The bare `priv` glob already includes everything under `priv/`, but list the font assets and license explicitly so they cannot be silently pruned by future glob changes:
```elixir
files:
  ~w(lib priv priv/static/parapet/fonts/*.woff2 priv/static/parapet/fonts/LICENSE.txt
     .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* LICENSE* docs),
```

---

### `examples/demo_app/lib/demo_app_web/router.ex` (add gallery route)

**Analog:** self — `examples/demo_app/lib/demo_app_web/router.ex`

**Existing structure** (lines 16–38):
```elixir
scope "/" do
  pipe_through(:browser)

  live_session :parapet_operator do
    live("/parapet", DemoAppWeb.Parapet.OperatorLive, :index)
    live("/parapet/actions", DemoAppWeb.Parapet.OperatorLive, :actions)
    live("/parapet/history", DemoAppWeb.Parapet.OperatorLive, :history)
    live("/parapet/incidents/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
    live("/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
  end
end

scope "/ops" do
  ...
end
```

**Pattern to add** (insert between the closing `end` of `live_session :parapet_operator` and the closing `end` of `scope "/"`, i.e. after line 25 before line 26):
```elixir
    live_session :parapet_gallery do
      live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index)
    end
```

**Why this placement is safe:** The demo-contract test (lines 59–86) checks 5 specific `live(...)` strings with `=~` (substring match) and checks `scope "/" do` appears before `scope "/ops" do` via `:binary.match` comparison. A new `live_session` block inside `scope "/"` does not disturb any of these assertions (verified in RESEARCH.md).

**Do NOT add** this route to `priv/templates/parapet.gen.ui/router_snippet.ex.eex` — gallery is demo-only (D-13 hard boundary).

---

### `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` (new demo LiveView)

**Analog:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`

**Pattern to replicate** (from operator_live.ex lines 1–11):
```elixir
defmodule DemoAppWeb.Parapet.GalleryLive do
  @moduledoc false
  use DemoAppWeb, :live_view

  import DemoAppWeb.Parapet.OperatorComponents

  def mount(_params, _session, socket) do
    {:ok, assign(socket, components: gallery_components())}
  end

  def render(assigns) do
    ~H"""
    <.operator_theme_bootstrap />
    <div class="parapet-ui">
      <!-- iterate all 19 components × {light, dark, empty, overflow, disabled, long-string} -->
    </div>
    """
  end

  defp gallery_components do
    [
      :operator_theme_bootstrap,
      :operator_nav,
      :theme_control,
      :response_cockpit,
      :nav_item,
      :operator_overview,
      :action_center,
      :incident_list,
      :incident_row,
      :incident_summary,
      :incident_timeline,
      :suspect_changes_card,
      :retrospective_card,
      :runbook_card,
      :preview_panel,
      :action_rail,
      :action_item_list,
      :action_item_card,
      :critical_journeys
    ]
  end
end
```

**Key differences from OperatorLive:**
- No Ecto/Repo calls — all data is hardcoded fixture data (security requirement per RESEARCH.md threat table: "Gallery must use hardcoded fixture data, not `Repo.all()` live data")
- No `handle_params/3` — no pagination, no URL params
- No `handle_event/3` beyond no-op stubs if needed
- Explicit static component list (not dynamic introspection) for auditability (per RESEARCH.md "Don't Hand-Roll" table)

---

### `examples/demo_app/lib/demo_app_web.ex` (add "parapet" to static_paths)

**Analog:** self — `examples/demo_app/lib/demo_app_web.ex` line 20

**Existing pattern** (line 20):
```elixir
def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
```

**Replacement:**
```elixir
def static_paths, do: ~w(assets fonts images favicon.ico robots.txt parapet)
```

This enables Phoenix `Plug.Static` to serve `/parapet/fonts/*.woff2` from `priv/static/parapet/`.

---

### `test/parapet/operator_ui_contrast_test.exs` (re-pin @themes, add assertions)

**Analog:** self — full file read above

**Existing `@themes` structure** (lines 9–64): Two maps (`:light` and `:dark`) with Tailwind-era hex values.

**Pattern — replace the entire `@themes` module attribute** (lines 9–64) with brand token hexes from RESEARCH.md "Required New @themes Map":

```elixir
@themes %{
  light: %{
    bg: "#F8F4EC",
    panel: "#FFFFFF",
    header_bg: "#FFFFFF",
    header_title: "#101820",
    header_muted: "#256C82",
    link_on_panel: "#256C82",
    link_on_bg: "#256C82",
    focus_ring: "#256C82",
    nav_fg: "#2E3A42",
    nav_hover_bg: "#EAE2D4",
    nav_hover_fg: "#101820",
    nav_active_bg: "#EFF6E8",
    nav_active_fg: "#3F5E28",
    theme_control_bg: "#F8F4EC",
    theme_control_fg: "#2E3A42",
    healthy_bg: "#EFF6E8", healthy_fg: "#3F5E28",
    watch_bg: "#F8EFD7",   watch_fg: "#92400E",
    burning_bg: "#FCE8E2", burning_fg: "#9F2D2D",
    exhausted_bg: "#F8D7D4", exhausted_fg: "#7F1D1D",
    unknown_bg: "#ECEFF1", unknown_fg: "#2E3A42",
    ai_bg: "#ECEBFF",      ai_fg: "#4F46A5",
    warning_button_bg: "#B45309", warning_button_fg: "#FFFFFF"
  },
  dark: %{
    bg: "#18232B",
    panel: "#2E3A42",
    header_bg: "#101820",
    header_title: "#F8F4EC",
    header_muted: "#7FB4C6",
    link_on_panel: "#7FB4C6",
    link_on_bg: "#7FB4C6",
    focus_ring: "#F8F4EC",
    nav_fg: "#D8D0C3",
    nav_hover_bg: "#2E3A42",
    nav_hover_fg: "#F8F4EC",
    nav_active_bg: "#3F5E28",
    nav_active_fg: "#F8F4EC",
    theme_control_bg: "#18232B",
    theme_control_fg: "#D8D0C3",
    healthy_bg: "#3F5E28", healthy_fg: "#EFF6E8",
    watch_bg: "#92400E",   watch_fg: "#F8EFD7",
    burning_bg: "#9F2D2D", burning_fg: "#FCE8E2",
    exhausted_bg: "#7F1D1D", exhausted_fg: "#F8D7D4",
    unknown_bg: "#2E3A42", unknown_fg: "#ECEFF1",
    ai_bg: "#4F46A5",      ai_fg: "#ECEBFF",
    warning_button_bg: "#D97706", warning_button_fg: "#F8F4EC"
  }
}
```

**Pattern — replace the test body** of `"semantic operator tokens meet contrast minimums"` (lines 66–98):
```elixir
test "semantic operator tokens meet contrast minimums" do
  for {theme, tokens} <- @themes do
    assert_contrast(theme, :header_title, tokens.header_title, tokens.header_bg, 4.5)
    assert_contrast(theme, :header_muted, tokens.header_muted, tokens.header_bg, 4.5)
    assert_contrast(theme, :link_on_panel, tokens.link_on_panel, tokens.panel, 4.5)
    assert_contrast(theme, :link_on_bg, tokens.link_on_bg, tokens.bg, 4.5)
    assert_contrast(theme, :nav, tokens.nav_fg, tokens.header_bg, 4.5)
    assert_contrast(theme, :nav_hover, tokens.nav_hover_fg, tokens.nav_hover_bg, 4.5)
    assert_contrast(theme, :nav_active, tokens.nav_active_fg, tokens.nav_active_bg, 4.5)
    assert_contrast(theme, :theme_control, tokens.theme_control_fg, tokens.theme_control_bg, 4.5)
    assert_contrast(theme, :healthy_chip, tokens.healthy_fg, tokens.healthy_bg, 4.5)
    assert_contrast(theme, :watch_chip, tokens.watch_fg, tokens.watch_bg, 4.5)
    assert_contrast(theme, :burning_chip, tokens.burning_fg, tokens.burning_bg, 4.5)
    assert_contrast(theme, :exhausted_chip, tokens.exhausted_fg, tokens.exhausted_bg, 4.5)
    assert_contrast(theme, :unknown_chip, tokens.unknown_fg, tokens.unknown_bg, 4.5)
    assert_contrast(theme, :ai_chip, tokens.ai_fg, tokens.ai_bg, 4.5)
    assert_contrast(theme, :warning_button, tokens.warning_button_fg, tokens.warning_button_bg, 4.5)
    # GUARD-02: focus ring at 3:1 UI floor
    focus_surface = if theme == :light, do: tokens.panel, else: tokens.bg
    assert_contrast(theme, :focus_ring, tokens.focus_ring, focus_surface, 3.0)
  end
end
```

The `assert_contrast/4`, `contrast_ratio/2`, `relative_luminance/1`, `rgb/1`, and `linear_channel/1` private functions (lines 128–157) are **unchanged** — copy them as-is.

**Pattern — add motion + font string assertions** to the `"operator components use semantic tokens for known dark-mode risk surfaces"` test (lines 100–126). Append inside the `for path <- @component_paths do` block:
```elixir
# MOTION-01: motion tokens wired
assert content =~ "--motion-fast"
assert content =~ "--motion-base"
assert content =~ "--motion-ease"
# MOTION-01: motion zeroed under prefers-reduced-motion
assert content =~ "prefers-reduced-motion"
assert content =~ "--motion-fast: 0ms"
# FONT-02: @font-face emitted
assert content =~ "@font-face"
assert content =~ "IBM Plex Sans"
assert content =~ "font-display: swap"
```

---

### `test/parapet/operator_ui_demo_contract_test.exs` (additive assertions only)

**Analog:** self — full file read above

**Do NOT disturb** any existing assertions, especially the 5 `live(...)` route substring checks (lines 60–65) and the `:binary.match` ordering check (lines 72–73).

**Pattern — add new assertions** after the existing `test "demo routes mirror the generated operator UI route shape"` assertions (after line 86, before the closing `end` of that test):
```elixir
# GALLERY-01: gallery route exists in demo router (demo-only)
assert router =~ ~S|live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index)|
assert router =~ "live_session :parapet_gallery"

# FONT-03: generator wires font static path in demo
assert File.exists?("priv/static/parapet/fonts/IBMPlexSans-Regular-latin.woff2")

# GUARD-01: audit matrix is committed
assert File.exists?("brandbook/notes/operator-audit-matrix.md")
```

---

### `test/parapet/operator_ui_fonts_test.exs` (new — Wave 0 font budget test)

**Analog:** `test/parapet/operator_ui_contrast_test.exs` (same ExUnit structure)

**Pattern — module structure** (replicate the `use ExUnit.Case, async: true` pattern):
```elixir
defmodule Parapet.OperatorUIFontsTest do
  use ExUnit.Case, async: true

  @font_dir "priv/static/parapet/fonts"
  @font_budget_bytes 153_600  # 150 KB ceiling per D-09

  @font_files ~w(
    IBMPlexSans-Regular-latin.woff2
    IBMPlexSans-Medium-latin.woff2
    IBMPlexSans-SemiBold-latin.woff2
    IBMPlexMono-Regular-latin.woff2
    IBMPlexMono-Medium-latin.woff2
  )

  test "all IBM Plex woff2 files are vendored" do
    for filename <- @font_files do
      path = Path.join(@font_dir, filename)
      assert File.exists?(path), "Missing font file: #{path}"
    end
  end

  test "IBM Plex OFL license is vendored" do
    assert File.exists?(Path.join(@font_dir, "LICENSE.txt"))
  end

  test "total font budget is within 150 KB ceiling" do
    total =
      @font_files
      |> Enum.map(&Path.join(@font_dir, &1))
      |> Enum.map(&File.stat!(&1).size)
      |> Enum.sum()

    assert total <= @font_budget_bytes,
           "Font budget #{total} bytes exceeds #{@font_budget_bytes} byte ceiling"
  end

  test "each font file is a valid woff2 binary (non-zero, non-empty)" do
    for filename <- @font_files do
      path = Path.join(@font_dir, filename)
      stat = File.stat!(path)
      assert stat.size > 0, "Font file #{filename} is empty"
    end
  end
end
```

---

### `brandbook/notes/operator-audit-matrix.md` (new — component × state ledger)

**Analog:** `brandbook/notes/accessibility.md` (same directory, markdown table format)

**Pattern — markdown table structure** (Claude's Discretion per D-15 and RESEARCH.md):
```markdown
# Operator UI Audit Matrix

Phase 44 idempotence ledger. Each cell: `todo` / `done` / `verified`.
Re-runs revisit only non-`verified` or regressed cells.

| Component | light-default | dark-default | light-empty | dark-empty | light-overflow | dark-overflow | light-disabled | dark-disabled | Notes |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|-------|
| operator_theme_bootstrap | todo | todo | — | — | — | — | — | — | Token values + @font-face |
| operator_nav | todo | todo | — | — | todo | todo | — | — | |
| theme_control | todo | todo | — | — | — | — | — | — | |
| response_cockpit | todo | todo | todo | todo | — | — | — | — | |
| nav_item | todo | todo | — | — | todo | todo | todo | todo | |
| operator_overview | todo | todo | todo | todo | — | — | — | — | |
| action_center | todo | todo | todo | todo | — | — | todo | todo | |
| incident_list | todo | todo | todo | todo | todo | todo | — | — | |
| incident_row | todo | todo | — | — | todo | todo | todo | todo | |
| incident_summary | todo | todo | todo | todo | todo | todo | — | — | |
| incident_timeline | todo | todo | todo | todo | todo | todo | — | — | |
| suspect_changes_card | todo | todo | todo | todo | — | — | — | — | |
| retrospective_card | todo | todo | todo | todo | — | — | — | — | |
| runbook_card | todo | todo | todo | todo | — | — | — | — | |
| preview_panel | todo | todo | todo | todo | — | — | todo | todo | |
| action_rail | todo | todo | — | — | — | — | — | — | |
| action_item_list | todo | todo | todo | todo | todo | todo | — | — | |
| action_item_card | todo | todo | todo | todo | todo | todo | todo | todo | |
| critical_journeys | todo | todo | todo | todo | — | — | — | — | |
```

---

## Shared Patterns

### ExUnit test module structure
**Source:** `test/parapet/operator_ui_contrast_test.exs` lines 1–3
**Apply to:** `test/parapet/operator_ui_fonts_test.exs`
```elixir
defmodule Parapet.OperatorUI<Name>Test do
  use ExUnit.Case, async: true
  # module attributes before tests
end
```

### File.read! + string assertions
**Source:** `test/parapet/operator_ui_contrast_test.exs` lines 101–125 and `operator_ui_demo_contract_test.exs` lines 56–86
**Apply to:** new string assertions added to existing test files
```elixir
content = File.read!(path)
assert content =~ "marker_string"
refute content =~ "forbidden_string"
```

### Igniter generator task structure
**Source:** `lib/mix/tasks/parapet.gen.ui.ex` lines 1–16
**Apply to:** extended `run/1` addition
```elixir
use Igniter.Mix.Task

def info(_argv, _composing_task) do
  %Igniter.Mix.Task.Info{group: :parapet, example: @example}
end

def igniter(igniter) do
  # Igniter pipeline (existing — do not modify)
end

def run(argv) do
  super(argv)   # must call super first
  copy_fonts_to_host()
end
```

### Demo LiveView module skeleton
**Source:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` lines 1–11
**Apply to:** `gallery_live.ex`
```elixir
defmodule DemoAppWeb.Parapet.GalleryLive do
  @moduledoc false
  use DemoAppWeb, :live_view
  import DemoAppWeb.Parapet.OperatorComponents
end
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/static/parapet/fonts/*.woff2` | static binary asset | file-I/O | No existing binary assets in repo; produced by pyftsubset CLI, committed directly |
| `priv/static/parapet/fonts/LICENSE.txt` | license file | — | No precedent for vendored third-party licenses in priv/static |

---

## Metadata

**Analog search scope:** `priv/templates/`, `examples/demo_app/`, `lib/mix/tasks/`, `test/parapet/`, `mix.exs`, `brandbook/notes/`
**Files read:** 9 source files
**Pattern extraction date:** 2026-06-24
