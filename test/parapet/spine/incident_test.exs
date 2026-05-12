defmodule Parapet.Spine.IncidentTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.Incident

  describe "schema" do
    test "has expected fields" do
      assert %Incident{}.state == "open"
      assert Map.has_key?(%Incident{}, :title)
      assert Map.has_key?(%Incident{}, :description)
    end
  end

  describe "changeset/2" do
    test "requires title" do
      changeset = Incident.changeset(%Incident{}, %{})
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates state inclusion" do
      changeset = Incident.changeset(%Incident{}, %{title: "Test", state: "invalid"})
      assert %{state: ["is invalid"]} = errors_on(changeset)

      valid_states = ["open", "investigating", "resolved"]

      for state <- valid_states do
        changeset = Incident.changeset(%Incident{}, %{title: "Test", state: state})
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
