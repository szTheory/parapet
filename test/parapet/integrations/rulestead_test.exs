defmodule Parapet.Integrations.RulesteadTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      send(self(), {:dummy_repo_insert, changeset})

      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)

    # Detach to prevent duplicate handlers
    :telemetry.detach("parapet-rulestead-telemetry")
    Parapet.Integrations.Rulestead.attach()

    on_exit(fn ->
      :telemetry.detach("parapet-rulestead-telemetry")
      Application.delete_env(:parapet, :repo)
    end)

    :ok
  end

  test "attach/0 registers the telemetry handler" do
    handlers = :telemetry.list_handlers([:rulestead, :admin, :ruleset, :published])
    assert Enum.any?(handlers, fn h -> h.id == "parapet-rulestead-telemetry" end)
  end

  test "firing telemetry inserts a SystemEvent with rulestead_flag_change type" do
    metadata = %{
      flag_name: "feature_x",
      ruleset_id: "rs_123",
      published_by: "user_456"
    }

    :telemetry.execute([:rulestead, :admin, :ruleset, :published], %{}, metadata)

    assert_receive {:dummy_repo_insert, changeset}
    assert changeset.data.__struct__ == Parapet.Spine.SystemEvent
    assert Ecto.Changeset.get_field(changeset, :type) == "rulestead_flag_change"
    
    payload = Ecto.Changeset.get_field(changeset, :payload)
    assert payload["flag_name"] == "feature_x"
    assert payload["ruleset_id"] == "rs_123"
  end

  test "exceptions in the handler are rescued and do not crash the caller" do
    # Pass bad metadata that would cause a crash if not rescued
    assert Parapet.Integrations.Rulestead.handle_event(
             [:rulestead, :admin, :ruleset, :published],
             %{},
             :not_a_map,
             nil
           ) == :ok
  end
end
