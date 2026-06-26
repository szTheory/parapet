defmodule Parapet.OperatorUIContrastTest do
  use ExUnit.Case, async: true

  @component_paths [
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex",
    "priv/templates/parapet.gen.ui/operator_components.ex.eex"
  ]

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
      warning_button_bg: "#B45309", warning_button_fg: "#FFFFFF",
      primary_button_bg: "#101820", primary_button_fg: "#FFFFFF",
      destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
      success_button_bg: "#567236", success_button_fg: "#FFFFFF"
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
      warning_button_bg: "#D97706", warning_button_fg: "#101820",
      primary_button_bg: "#F8F4EC", primary_button_fg: "#2E3A42",
      destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
      success_button_bg: "#3F5E28", success_button_fg: "#EFF6E8"
    }
  }

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
      assert_contrast(theme, :primary_button, tokens.primary_button_fg, tokens.primary_button_bg, 4.5)
      assert_contrast(theme, :destructive_button, tokens.destructive_button_fg, tokens.destructive_button_bg, 4.5)
      assert_contrast(theme, :success_button, tokens.success_button_fg, tokens.success_button_bg, 4.5)
      # GUARD-02: focus ring at 3:1 UI floor
      focus_surface = if theme == :light, do: tokens.panel, else: tokens.bg
      assert_contrast(theme, :focus_ring, tokens.focus_ring, focus_surface, 3.0)
    end
  end

  test "operator components use semantic tokens for known dark-mode risk surfaces" do
    for path <- @component_paths do
      content = File.read!(path)

      assert content =~ "--po-chip-warning-bg"
      assert content =~ "po-chip-warning"
      assert content =~ "po-button-warning"
      assert content =~ "po-link"
      assert content =~ "--po-header-bg"
      assert content =~ "--po-theme-control-bg"
      assert content =~ "po-operator-header"
      assert content =~ "po-operator-brand"
      assert content =~ "po-theme-control"
      assert content =~ "po-theme-option"
      assert content =~ "po-nav-active"
      assert content =~ ~S|aria-label="Close Recovery Preview"|

      refute content =~ "text-blue-600"
      refute content =~ "border-stone-900/10 bg-stone-950 text-stone-50"
      refute content =~ "text-teal-300"
      refute content =~ "text-white\">Active response workbench"
      refute content =~ "bg-stone-900 px-1 py-1 ring-1 ring-stone-700"
      refute content =~ "bg-teal-400 text-stone-950"
      refute content =~ "bg-amber-100 text-amber"
      refute content =~ "text-[10px]"

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

      # COMP-08: off-palette class remediation complete
      refute content =~ "bg-indigo-600"
      refute content =~ "bg-indigo-500"
      refute content =~ "bg-indigo-50 ring-indigo-100"
      refute content =~ "bg-emerald-600"
      refute content =~ "bg-purple-100"
      refute content =~ "bg-violet-100"
      refute content =~ "bg-blue-50"
      refute content =~ "bg-teal-700"
      refute content =~ "hover:ring-teal-700"
      refute content =~ "#042f2e"

      # MOTION-02: duration token used; no transition-all
      refute content =~ "transition-all"
      assert content =~ "duration-[--motion-fast]"

      # COMP-06: po-focus on all controls
      assert content =~ "po-focus"

      # COMP-07: no raw badge color utilities
      refute content =~ "bg-purple-100 text-purple-800"
      refute content =~ "bg-violet-100 text-violet-800"
      refute content =~ "bg-indigo-700"
      refute content =~ "bg-violet-700"
      refute content =~ "bg-slate-700"

      # COMP-05: no spurious pointer cursor on stat cards
      refute content =~ "cursor-pointer"

      # COMP-02: disabled affordance wired in control_base()
      assert content =~ "disabled:opacity"

      # COMP-04: no raw amber border utilities in escalation-chain markup
      refute content =~ "border-amber-"

      # COMP-08 gap-closure (phase-verifier residuals): off-palette color utilities
      # that were not in the original 20-item inventory and were found post-phase
      refute content =~ "bg-purple-50"
      refute content =~ "bg-red-50"
      refute content =~ "text-red-700"
      refute content =~ "text-red-600"
      refute content =~ "ring-amber-300"
    end
  end

  @live_template_paths [
    "priv/templates/parapet.gen.ui/operator_live.ex.eex",
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
  ]

  test "operator live templates use semantic tokens (no raw stone-950 primary button colors)" do
    for path <- @live_template_paths do
      content = File.read!(path)

      # COMP-08 gap-closure: Return to Response button must use token-based primary
      # (bg-stone-950 was the off-palette color that operator_components.ex.eex
      #  migrated in Plan 45-03; the same button in operator_live was a missed residual)
      refute content =~ "bg-stone-950"
    end
  end

  defp assert_contrast(theme, token, foreground, background, minimum) do
    ratio = contrast_ratio(foreground, background)

    assert ratio >= minimum,
           "#{theme}.#{token} contrast #{Float.round(ratio, 2)} is below #{minimum}"
  end

  defp contrast_ratio(foreground, background) do
    [l1, l2] =
      [relative_luminance(foreground), relative_luminance(background)]
      |> Enum.sort(:desc)

    (l1 + 0.05) / (l2 + 0.05)
  end

  defp relative_luminance(hex) do
    [r, g, b] = rgb(hex)

    0.2126 * linear_channel(r) + 0.7152 * linear_channel(g) + 0.0722 * linear_channel(b)
  end

  defp rgb("#" <> <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    Enum.map([r, g, b], fn channel ->
      {value, ""} = Integer.parse(channel, 16)
      value / 255
    end)
  end

  defp linear_channel(value) when value <= 0.03928, do: value / 12.92
  defp linear_channel(value), do: :math.pow((value + 0.055) / 1.055, 2.4)
end
