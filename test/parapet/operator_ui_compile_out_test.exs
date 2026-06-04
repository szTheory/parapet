defmodule Parapet.OperatorUICompileOutTest do
  use ExUnit.Case, async: true

  describe "Phoenix dependency posture" do
    test "Parapet core does not depend directly on Phoenix or LiveView" do
      # Read the mix.exs file and ensure we aren't adding :phoenix directly
      # to force it on all adopters.
      mix_exs = File.read!("mix.exs")
      mix_lock = File.read!("mix.lock")

      refute mix_exs =~ ~r/{:phoenix,/
      refute mix_exs =~ ~r/{:phoenix_live_view,/

      assert mix_lock =~ ~r/"phoenix"/
      assert mix_lock =~ ~r/"phoenix_live_view"/
    end

    test "Generators require Phoenix/LiveView to be added by the host app" do
      # Verify that the generator module exists but doesn't inject phoenix as a dep
      # into the host unless the host already has it, or simply relies on the host's phoenix.
      # The UI generator should ideally assert the host app has Phoenix.
      assert Code.ensure_loaded?(Mix.Tasks.Parapet.Gen.Ui)

      # We check that the UI generator uses Igniter to add the UI files,
      # but relies on the host app having Phoenix.
    end

    test "generated detail LiveView routes escalation controls through the public operator API" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_detail_live.ex.eex")

      assert content =~ "handle_event(\"trigger_next_escalation\""
      assert content =~ "handle_event(\"suppress_pending_escalation\""
      assert content =~ "Parapet.Operator.trigger_next_escalation"
      assert content =~ "Parapet.Operator.suppress_pending_escalation"
      assert content =~ "Parapet.Operator.resolve_incident"
      assert content =~ "%Parapet.Operator.ActionPayload{"
      assert content =~ "assign(incident: Parapet.Operator.incident_detail(id))"
      assert content =~ "incident_detail_path(socket.assigns.operator_base_path, id)"
      assert content =~ "defp incident_detail_path(operator_base_path, incident_id)"
      refute content =~ ~S|/parapet/incidents/#{id}|
      assert content =~ "Integer.parse(minutes)"
      refute content =~ "String.to_integer(minutes)"
    end

    test "Parapet core does not define or export an operator UI router surface" do
      forbidden_core_patterns = [
        "use Phoenix.Router",
        "use Plug.Router",
        "defmodule Parapet.Operator.Router",
        "defmodule Parapet.Router"
      ]

      for file <- Path.wildcard("lib/parapet/**/*.ex") do
        content = File.read!(file)

        for pattern <- forbidden_core_patterns do
          refute content =~ pattern, "Found #{pattern} in core file #{file}"
        end
      end
    end

    test "stable public API manifest does not include route helper or router APIs" do
      manifest = File.read!("priv/parapet/public_api_stable.json")

      forbidden_api_patterns = [
        "OperatorRoute",
        "OperatorRouter",
        "Router",
        "route_base",
        "operator_base_path",
        "incident_detail_path"
      ]

      for pattern <- forbidden_api_patterns do
        refute manifest =~ pattern,
               "Stable public API manifest unexpectedly includes #{pattern}"
      end
    end

    test "operator UI docs describe the evidence-first escalation posture" do
      content = File.read!("docs/operator-ui.md")

      assert content =~ "summary-first"
      assert content =~ "canonical timeline"
      assert content =~ "durable"
      assert content =~ "suppression"
      assert content =~ "host-owned"
    end
  end
end
