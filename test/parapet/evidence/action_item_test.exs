defmodule Parapet.Evidence.ActionItemTest do
  use ExUnit.Case, async: false

  alias Parapet.Evidence

  defmodule DummyRepo do
    def insert(changeset, _opts \\ []) do
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end

    def update_all(query, updates) do
      send(self(), {:update_all, query, updates})
      {1, nil}
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  describe "create_action_item/1" do
    test "creates a narrow exact follow-up item linked to an incident when provided" do
      incident_id = Ecto.UUID.generate()

      attrs = %{
        title: "Inspect suppressed delivery",
        integration: "mailglass",
        external_id: "delivery-ref-123",
        incident_id: incident_id,
        kind: "suppressed_delivery"
      }

      assert {:ok, item} = Evidence.create_action_item(attrs)
      assert item.title == "Inspect suppressed delivery"
      assert item.incident_id == incident_id
      assert item.kind == "suppressed_delivery"
      assert item.state == "open"
    end
  end

  describe "resolve_action_item/1" do
    test "idempotently marks an action item as resolved by id" do
      id = Ecto.UUID.generate()
      assert {1, nil} = Evidence.resolve_action_item(id)
    end

    test "idempotently resolves by exact lookup criteria" do
      assert {1, nil} =
               Evidence.resolve_action_item(
                 incident_id: Ecto.UUID.generate(),
                 integration: "mailglass",
                 external_id: "delivery-ref-123",
                 kind: "suppressed_delivery"
               )

      assert_received {:update_all, _query, [set: [state: "resolved"]]}
    end
  end
end
