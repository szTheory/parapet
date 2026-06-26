defmodule DemoAppWeb.Parapet.OperatorComponentsRenderTest do
  @moduledoc """
  Render-level coverage for `action_item_card/1`.

  Phase 47 added a risk chip driven by the action item's `:kind`. The
  `operator_ui_contrast_test` suite only asserts on template *source strings*, so it
  could not catch a render-time `KeyError` — which is exactly what happened when the
  gallery passed fixture maps that lacked `:kind` (the gallery uses plain maps, not
  `%ActionItem{}` structs, so the schema default never applies).

  These tests actually render the component to guard against that class of bug:
  a missing `:kind` must degrade to the neutral "Routine" tier, never raise.
  """
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias DemoAppWeb.Parapet.OperatorComponents

  defp render_card(item) do
    render_component(&OperatorComponents.action_item_card/1, item: item)
  end

  test "renders without raising when :kind is absent (degrades to Routine)" do
    item = %{
      id: "ai-x",
      title: "No kind provided",
      state: "pending",
      integration: "linear",
      external_id: "ENG-1"
    }

    html = render_card(item)
    assert html =~ "Routine"
    assert html =~ "No kind provided"
  end

  test "renders without raising when :kind is nil (degrades to Routine)" do
    item = %{
      id: "ai-nil",
      title: "Nil kind",
      state: "pending",
      integration: "linear",
      external_id: "ENG-2",
      kind: nil
    }

    assert render_card(item) =~ "Routine"
  end

  test "maps each real ActionItem.kind to its risk label" do
    cases = [
      {"dead_letter", "High risk"},
      {"orphaned_callback", "Medium risk"},
      {"stalled_workflow", "Medium risk"},
      {"suppressed_delivery", "Low risk"},
      {"exact_follow_up", "Routine"}
    ]

    for {kind, label} <- cases do
      item = %{
        id: "ai-#{kind}",
        title: "Item #{kind}",
        state: "pending",
        integration: "linear",
        external_id: "ENG-#{kind}",
        kind: kind
      }

      assert render_card(item) =~ label,
             "expected kind #{inspect(kind)} to render risk label #{inspect(label)}"
    end
  end
end
