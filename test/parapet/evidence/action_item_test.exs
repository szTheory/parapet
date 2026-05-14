defmodule Parapet.Evidence.ActionItemTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end

    def update_all(_query, _updates) do
      # Mock update_all returning a fake count
      {1, nil}
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  describe "create_action_item/1" do
    test "inserts an action item" do
      attrs = %{title: "Needs Approval", integration: "scoria", external_id: "wf_123"}
      assert {:ok, item} = Parapet.Evidence.create_action_item(attrs)
      assert item.title == "Needs Approval"
      assert item.state == "open"
    end
  end

  describe "resolve_action_item/1" do
    test "idempotently marks an action item as resolved" do
      id = Ecto.UUID.generate()
      assert {1, nil} = Parapet.Evidence.resolve_action_item(id)
    end
  end
end
