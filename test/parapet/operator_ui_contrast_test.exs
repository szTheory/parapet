defmodule Parapet.OperatorUIContrastTest do
  use ExUnit.Case, async: true

  @component_paths [
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex",
    "priv/templates/parapet.gen.ui/operator_components.ex.eex"
  ]

  @themes %{
    light: %{
      panel: "#ffffff",
      header_bg: "#ffffff",
      header_title: "#1c1917",
      header_muted: "#0f766e",
      link: "#1d4ed8",
      link_hover: "#1e3a8a",
      nav_fg: "#44403c",
      nav_hover_bg: "#f5f5f4",
      nav_hover_fg: "#1c1917",
      nav_active_bg: "#5eead4",
      nav_active_fg: "#042f2e",
      theme_control_bg: "#fafaf9",
      theme_control_fg: "#44403c",
      neutral_bg: "#f5f5f4",
      neutral_fg: "#292524",
      success_bg: "#dcfce7",
      success_fg: "#14532d",
      warning_bg: "#fef3c7",
      warning_fg: "#78350f",
      danger_bg: "#ffe4e6",
      danger_fg: "#881337",
      info_bg: "#e0e7ff",
      info_fg: "#312e81",
      warning_button_bg: "#b45309",
      warning_button_fg: "#ffffff"
    },
    dark: %{
      panel: "#1c1917",
      header_bg: "#0c0a09",
      header_title: "#fafaf9",
      header_muted: "#5eead4",
      link: "#93c5fd",
      link_hover: "#bfdbfe",
      nav_fg: "#e7e5e4",
      nav_hover_bg: "#292524",
      nav_hover_fg: "#ffffff",
      nav_active_bg: "#5eead4",
      nav_active_fg: "#042f2e",
      theme_control_bg: "#1c1917",
      theme_control_fg: "#e7e5e4",
      neutral_bg: "#292524",
      neutral_fg: "#f5f5f4",
      success_bg: "#052e16",
      success_fg: "#bbf7d0",
      warning_bg: "#451a03",
      warning_fg: "#fde68a",
      danger_bg: "#4c0519",
      danger_fg: "#fecdd3",
      info_bg: "#1e1b4b",
      info_fg: "#c7d2fe",
      warning_button_bg: "#92400e",
      warning_button_fg: "#fff7ed"
    }
  }

  test "semantic operator tokens meet contrast minimums" do
    for {theme, tokens} <- @themes do
      assert_contrast(theme, :header_title, tokens.header_title, tokens.header_bg, 4.5)
      assert_contrast(theme, :header_muted, tokens.header_muted, tokens.header_bg, 4.5)
      assert_contrast(theme, :link, tokens.link, tokens.panel, 4.5)
      assert_contrast(theme, :link_hover, tokens.link_hover, tokens.panel, 4.5)
      assert_contrast(theme, :nav, tokens.nav_fg, tokens.header_bg, 4.5)
      assert_contrast(theme, :nav_hover, tokens.nav_hover_fg, tokens.nav_hover_bg, 4.5)
      assert_contrast(theme, :nav_active, tokens.nav_active_fg, tokens.nav_active_bg, 4.5)

      assert_contrast(
        theme,
        :theme_control,
        tokens.theme_control_fg,
        tokens.theme_control_bg,
        4.5
      )

      assert_contrast(theme, :neutral_chip, tokens.neutral_fg, tokens.neutral_bg, 4.5)
      assert_contrast(theme, :success_chip, tokens.success_fg, tokens.success_bg, 4.5)
      assert_contrast(theme, :warning_chip, tokens.warning_fg, tokens.warning_bg, 4.5)
      assert_contrast(theme, :danger_chip, tokens.danger_fg, tokens.danger_bg, 4.5)
      assert_contrast(theme, :info_chip, tokens.info_fg, tokens.info_bg, 4.5)

      assert_contrast(
        theme,
        :warning_button,
        tokens.warning_button_fg,
        tokens.warning_button_bg,
        4.5
      )
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
