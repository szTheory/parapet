defmodule Parapet.OperatorUIParityTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Ui

  @pairs [
    %{
      name: "operator_components",
      generated: "lib/demo_app_web/live/parapet/operator_components.ex",
      mirror: "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex"
    },
    %{
      name: "operator_live",
      generated: "lib/demo_app_web/live/parapet/operator_live.ex",
      mirror: "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
    },
    %{
      name: "operator_detail_live",
      generated: "lib/demo_app_web/live/parapet/operator_detail_live.ex",
      mirror: "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
    }
  ]

  test "GUARD-03: generated operator files are byte-equal to committed mirrors under Code.format_string! normalization" do
    igniter =
      test_project(app_name: :demo_app)
      |> Ui.igniter()

    for %{name: pair_name, generated: generated_path, mirror: mirror_path} <- @pairs do
      generated_content = generated_source(igniter, generated_path)

      try do
        normalized_generated =
          generated_content |> Code.format_string!() |> IO.iodata_to_binary()

        normalized_mirror =
          File.read!(mirror_path) |> Code.format_string!() |> IO.iodata_to_binary()

        assert normalized_generated == normalized_mirror,
               parity_failure_message(pair_name, normalized_generated, normalized_mirror)
      rescue
        e in SyntaxError ->
          flunk("Parity failure (parse error) in #{pair_name}: #{Exception.message(e)}")

        e in TokenMissingError ->
          flunk("Parity failure (parse error) in #{pair_name}: #{Exception.message(e)}")
      end
    end
  end

  defp generated_source(igniter, path) do
    igniter.rewrite
    |> Rewrite.source!(path)
    |> Rewrite.Source.get(:content)
  end

  defp parity_failure_message(pair_name, normalized_generated, normalized_mirror) do
    gen_lines = String.split(normalized_generated, "\n")
    mirror_lines = String.split(normalized_mirror, "\n")

    {first_diff_line, first_diff_number} =
      gen_lines
      |> Enum.zip(mirror_lines)
      |> Enum.with_index(1)
      |> Enum.find_value(fn {{gen, mir}, idx} ->
        if gen != mir, do: {gen, idx}, else: nil
      end)
      |> case do
        nil ->
          # Lines are the same but counts differ (one is longer)
          max_idx = max(length(gen_lines), length(mirror_lines))

          {"(line count differs: generated=#{length(gen_lines)}, mirror=#{length(mirror_lines)})",
           max_idx}

        {line, idx} ->
          {line, idx}
      end

    """
    Parity failure: #{pair_name}
    First divergent line #{first_diff_number}: #{String.slice(first_diff_line, 0, 120)}
    Regenerate: mix parapet.gen.ui into examples/demo_app, then mix format.
    """
  end
end
