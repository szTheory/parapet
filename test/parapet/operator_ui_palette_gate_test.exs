defmodule Parapet.OperatorUIPaletteGateTest do
  use ExUnit.Case, async: true

  alias Parapet.TestSupport.OperatorUIPaths

  # Operator-specific exceptions — each has a rationale in
  # brandbook/notes/operator-audit-matrix.md GUARD-04 exception section
  @palette_exceptions MapSet.new([
                        # dark --po-link (lightened Watch Blue for AA on dark surfaces)
                        "#7FB4C6",
                        # dark link-hover / accent-strong
                        "#A8D0DE",
                        # light link-hover / accent-strong (darkened Watch Blue for AA on light)
                        "#1A5066",
                        # dark chip-neutral-border
                        "#556B77",
                        # destructive-hover (darkened Incident Red for hover contrast)
                        "#8C2E27"
                      ])

  test "GUARD-04: tokens.css yields >= 31 hex tokens (fail-closed allowlist guard)" do
    tokens_css = File.read!("brandbook/tokens/tokens.css")

    allowlist =
      Regex.scan(~r/#[0-9a-fA-F]{6}\b/, tokens_css, capture: :first)
      |> List.flatten()
      |> Enum.map(&String.upcase/1)
      |> MapSet.new()

    assert MapSet.size(allowlist) >= 31,
           "tokens.css hex parse returned only #{MapSet.size(allowlist)} tokens — expected ≥ 31. " <>
             "Check brandbook/tokens/tokens.css for truncation or parse regression."
  end

  test "GUARD-04: no off-palette #rrggbb hex literals in operator templates (allowlist ∪ documented exceptions)" do
    tokens_css = File.read!("brandbook/tokens/tokens.css")

    allowlist =
      Regex.scan(~r/#[0-9a-fA-F]{6}\b/, tokens_css, capture: :first)
      |> List.flatten()
      |> Enum.map(&String.upcase/1)
      |> MapSet.new()

    assert MapSet.size(allowlist) >= 31,
           "tokens.css hex parse returned only #{MapSet.size(allowlist)} tokens — fail-closed."

    effective_allowlist = MapSet.union(allowlist, @palette_exceptions)

    all_paths =
      OperatorUIPaths.component_paths() ++
        OperatorUIPaths.live_template_paths() ++
        OperatorUIPaths.detail_template_paths()

    for path <- all_paths do
      content = File.read!(path)
      found_hexes = Regex.scan(~r/#[0-9a-fA-F]{6}/, content, capture: :first) |> List.flatten()

      for hex <- found_hexes do
        assert MapSet.member?(effective_allowlist, String.upcase(hex)),
               "Off-palette hex #{hex} found in #{path}. " <>
                 "Add to brandbook/tokens/tokens.css or document in the " <>
                 "GUARD-04 exception section of brandbook/notes/operator-audit-matrix.md."
      end
    end
  end
end
