defmodule Parapet.Integrations.IntegrationBehaviourTest do
  use ExUnit.Case, async: false

  @integration_modules [
    Parapet.Integrations.Sigra,
    Parapet.Integrations.Accrue,
    Parapet.Integrations.Threadline,
    Parapet.Integrations.Chimeway,
    Parapet.Integrations.Mailglass,
    Parapet.Integrations.Rindle,
    Parapet.Integrations.Scoria,
    Parapet.Integrations.Rulestead
  ]

  setup do
    # Detach to prevent duplicate handlers when Rulestead.setup/0 is called
    :telemetry.detach("parapet-rulestead-telemetry")

    on_exit(fn ->
      :telemetry.detach("parapet-rulestead-telemetry")
    end)

    :ok
  end

  describe "Parapet.Integration behaviour conformance" do
    test "all eight integration modules export setup/0" do
      for mod <- @integration_modules do
        # Ensure the module is loaded before checking exported functions
        Code.ensure_loaded!(mod)

        assert function_exported?(mod, :setup, 0),
               "Expected #{inspect(mod)} to export setup/0, but it does not"
      end
    end
  end

  describe "Parapet.attach/1 uniform activation" do
    test "Parapet.attach(adapters: [:rulestead]) returns {:ok, [:rulestead]} without raising" do
      result = Parapet.attach(adapters: [:rulestead])
      assert result == {:ok, [:rulestead]}
    end

    test "Parapet.attach(adapters: [:rulestead]) registers the parapet-rulestead-telemetry handler" do
      Parapet.attach(adapters: [:rulestead])
      handlers = :telemetry.list_handlers([:rulestead, :admin, :ruleset, :published])

      assert Enum.any?(handlers, fn h -> h.id == "parapet-rulestead-telemetry" end),
             "Expected parapet-rulestead-telemetry handler to be registered"
    end
  end
end
