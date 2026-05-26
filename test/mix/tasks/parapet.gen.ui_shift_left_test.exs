defmodule Mix.Tasks.Parapet.Gen.UiShiftLeftTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Ui

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  describe "mix parapet.gen.ui shift-left verification" do
    test "generated operator detail keeps escalation summary ahead of the canonical timeline" do
      igniter =
        test_project(app_name: :test)
        |> Ui.igniter()

      components_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
        |> Rewrite.Source.get(:content)

      detail_live_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_detail_live.ex")
        |> Rewrite.Source.get(:content)

      assert components_source =~ "Escalation Status"
      assert components_source =~ "Escalation Chain"
      assert components_source =~ "Time Until Next Escalation"
      assert components_source =~ "def incident_summary(assigns)"
      assert components_source =~ "def incident_timeline(assigns)"

      assert index_of(components_source, "def incident_summary(assigns)") <
               index_of(components_source, "def incident_timeline(assigns)")

      assert index_of(detail_live_source, "<.incident_summary detail={@incident} />") <
               index_of(detail_live_source, "<.incident_timeline detail={@incident} />")
    end

    test "generated operator detail guards escalation controls for non-open incidents" do
      igniter =
        test_project(app_name: :test)
        |> Ui.igniter()

      components_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
        |> Rewrite.Source.get(:content)

      assert components_source =~ "if escalation_controls_enabled?(@detail.incident) do"

      assert components_source =~
               "Escalation controls are available only while the incident is open."

      assert components_source =~
               "defp escalation_controls_enabled?(%{state: \"open\"}), do: true"

      assert components_source =~ "defp escalation_controls_enabled?(_incident), do: false"

      assert index_of(components_source, "if escalation_controls_enabled?(@detail.incident) do") <
               index_of(
                 components_source,
                 "Escalation controls are available only while the incident is open."
               )
    end
  end
end
