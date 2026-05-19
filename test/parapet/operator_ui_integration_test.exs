defmodule Parapet.OperatorUIIntegrationTest do
  use ExUnit.Case, async: true

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  describe "UI generator integration" do
    test "generated UI templates align with Parapet.Operator actions" do
      # The UI template should assume the existence of Parapet.Operator.queue_query
      # or Parapet.Operator.incident_detail, not old/fake functions.

      template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
      content = File.read!(template_path)

      # We expect the generator to tell the user to use the correct API:
      assert content =~ "Parapet.Operator.queue_query"
      assert content =~ "Parapet.Operator.incident_detail(id)"
    end

    test "doctor check enforces authenticated mount for generated UI" do
      # We know doctor expects OperatorLive and OperatorDetailLive to be behind auth.
      # Let's verify that Mix.Tasks.Parapet.Doctor check_operator_ui behaves as expected.
      # Doctor looks for "OperatorLive" or "OperatorDetailLive" in a live() macro and checks for scopes.

      # We verify the doctor code handles it by reading its source.
      doctor_code = File.read!("lib/mix/tasks/parapet.doctor.ex")
      assert doctor_code =~ "check_operator_ui"
      assert doctor_code =~ "OperatorLive"
      assert doctor_code =~ "OperatorDetailLive"
      assert doctor_code =~ "has_auth_plug?"
    end

    test "generated UI templates enforce responsive layout contracts" do
      template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
      content = File.read!(template_path)

      # Assert structural elements of the layout to ensure it meets the 3-pane responsive contract
      # without needing a full e2e browser test suite.
      assert content =~ "md:flex-row", "Outer container should shift to row on desktop"
      assert content =~ "md:w-80", "Panes 1 and 3 should have fixed desktop widths"
      assert content =~ "hidden md:flex", "Panes should collapse/hide on mobile conditionally"

      assert content =~ "md:hidden",
             "Mobile specific elements (like back button) should hide on desktop"
    end

    test "UI stays generator-first and host-owned" do
      # Parapet must not define its own Plug.Router or Phoenix.Router for the UI.
      # Let's verify no router modules exist in Parapet core.
      core_files = Path.wildcard("lib/parapet/**/*.ex")

      for file <- core_files do
        content = File.read!(file)
        refute content =~ "use Phoenix.Router", "Found Phoenix.Router in core file: \#{file}"
        refute content =~ "use Plug.Router", "Found Plug.Router in core file: \#{file}"
      end
    end

    test "detail components render escalation summary before the canonical timeline" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "Escalation Status"
      assert content =~ "@detail.escalation_summary"
      assert content =~ "@detail.timeline_entries"

      assert index_of(content, "Escalation Status") <
               index_of(content, "def incident_timeline"),
             "Escalation summary should be defined ahead of timeline rendering in the template"
    end

    test "timeline rows render typed system and escalation evidence without generic payload dumps" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "timeline_entry_title"
      assert content =~ "timeline_entry_body"
      assert content =~ "presentation.actor_class"
      refute content =~ "inspect(entry.payload)"
    end

    test "manual escalation controls appear after summary context inside the generated component surface" do
      components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert components_content =~ "Trigger Next Escalation"
      assert components_content =~ "Suppress Pending Escalation"

      assert index_of(components_content, "Escalation Status") <
               index_of(components_content, "Trigger Next Escalation"),
             "Escalation controls should appear after summary context"

      assert index_of(components_content, "def incident_timeline") <
               index_of(components_content, "Trigger Next Escalation"),
             "Escalation controls should stay below the canonical timeline"
    end
  end
end
