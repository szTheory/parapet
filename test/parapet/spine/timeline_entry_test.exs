defmodule Parapet.Spine.TimelineEntryTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.TimelineEntry

  describe "schema" do
    test "has expected fields" do
      assert Map.has_key?(%TimelineEntry{}, :type)
      assert Map.has_key?(%TimelineEntry{}, :payload)
      assert Map.has_key?(%TimelineEntry{}, :incident_id)
      assert %TimelineEntry{}.__struct__.__schema__(:association, :incident)
    end
  end

  describe "changeset/2" do
    test "requires type and incident_id" do
      changeset = TimelineEntry.changeset(%TimelineEntry{}, %{})
      assert %{type: ["can't be blank"], incident_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "valid with required fields" do
      changeset = TimelineEntry.changeset(%TimelineEntry{}, %{
        type: "status_change",
        incident_id: Ecto.UUID.generate()
      })
      assert changeset.valid?
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
