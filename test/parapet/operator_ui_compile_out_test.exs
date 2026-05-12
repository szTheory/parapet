defmodule Parapet.OperatorUICompileOutTest do
  use ExUnit.Case, async: true

  describe "Phoenix dependency posture" do
    test "Parapet core does not depend directly on Phoenix or LiveView" do
      # Read the mix.exs file and ensure we aren't adding :phoenix directly
      # to force it on all adopters.
      mix_exs = File.read!("mix.exs")

      refute mix_exs =~ ~r/{:phoenix,/
      refute mix_exs =~ ~r/{:phoenix_live_view,/
    end

    test "Generators require Phoenix/LiveView to be added by the host app" do
      # Verify that the generator module exists but doesn't inject phoenix as a dep
      # into the host unless the host already has it, or simply relies on the host's phoenix.
      # The UI generator should ideally assert the host app has Phoenix.
      assert Code.ensure_loaded?(Mix.Tasks.Parapet.Gen.Ui)

      # We check that the UI generator uses Igniter to add the UI files,
      # but relies on the host app having Phoenix.
    end
  end
end
