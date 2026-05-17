defmodule Parapet.Spine.ActionItemTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.ActionItem

  describe "schema" do
    test "keeps the default state open and the default kind exact_follow_up" do
      assert %ActionItem{}.state == "open"
      assert %ActionItem{}.kind == "exact_follow_up"
      assert Map.has_key?(%ActionItem{}, :incident_id)
      assert Map.has_key?(%ActionItem{}, :external_id)
    end
  end

  describe "changeset/2" do
    test "requires title, integration, and external_id" do
      changeset = ActionItem.changeset(%ActionItem{}, %{})

      assert %{
               title: ["can't be blank"],
               integration: ["can't be blank"],
               external_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "accepts narrow exact-follow-up linkage fields" do
      changeset =
        ActionItem.changeset(%ActionItem{}, %{
          title: "Inspect discarded delivery",
          integration: "mailglass",
          external_id: "delivery-ref-123",
          incident_id: Ecto.UUID.generate(),
          kind: "suppressed_delivery"
        })

      assert changeset.valid?
    end

    test "rejects generic task-style kinds" do
      changeset =
        ActionItem.changeset(%ActionItem{}, %{
          title: "Investigate broadly",
          integration: "mailglass",
          external_id: "delivery-ref-123",
          kind: "generic_task"
        })

      assert %{kind: ["is invalid"]} = errors_on(changeset)
    end

    test "validates state inclusion" do
      changeset =
        ActionItem.changeset(%ActionItem{}, %{
          title: "Test",
          integration: "scoria",
          external_id: "123",
          state: "invalid"
        })

      assert %{state: ["is invalid"]} = errors_on(changeset)
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
