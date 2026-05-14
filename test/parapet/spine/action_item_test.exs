defmodule Parapet.Spine.ActionItemTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.ActionItem

  describe "schema" do
    test "has expected fields and default state" do
      assert %ActionItem{}.state == "open"
      assert Map.has_key?(%ActionItem{}, :title)
      assert Map.has_key?(%ActionItem{}, :integration)
      assert Map.has_key?(%ActionItem{}, :external_id)
    end
  end

  describe "changeset/2" do
    test "requires title, integration, and external_id" do
      changeset = ActionItem.changeset(%ActionItem{}, %{})
      assert %{title: ["can't be blank"], integration: ["can't be blank"], external_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates state inclusion" do
      changeset = ActionItem.changeset(%ActionItem{}, %{title: "Test", integration: "scoria", external_id: "123", state: "invalid"})
      assert %{state: ["is invalid"]} = errors_on(changeset)

      valid_states = ["open", "resolved"]

      for state <- valid_states do
        changeset = ActionItem.changeset(%ActionItem{}, %{title: "Test", integration: "scoria", external_id: "123", state: state})
        assert changeset.valid?
      end
    end
  end

  # Helper to parse errors
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
