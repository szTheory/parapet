defmodule Parapet.Spine.TimelineEntry do
  @moduledoc """
  Ecto schema representing an entry in a durable incident timeline.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Parapet.Spine.Incident

  @triage_snapshot_fields ~w(
    integration
    symptom
    fault_plane
    impact
    queue
    pipeline_stage
    delay_bucket
    failure_class
    next_safe_action
    confidence
    evidence_facts
  )

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_timeline_entries" do
    field(:type, :string)
    field(:payload, :map)

    belongs_to(:incident, Incident, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(timeline_entry, attrs) do
    timeline_entry
    |> cast(attrs, [:type, :payload, :incident_id])
    |> validate_required([:type, :incident_id])
    |> validate_typed_payload()
  end

  defp validate_typed_payload(changeset) do
    case {get_field(changeset, :type), get_field(changeset, :payload)} do
      {"triage_snapshot", payload} when is_map(payload) ->
        changeset
        |> validate_triage_snapshot_fields(payload)
        |> validate_evidence_facts(payload)

      _ ->
        changeset
    end
  end

  defp validate_triage_snapshot_fields(changeset, payload) do
    invalid_fields =
      payload
      |> Map.keys()
      |> Enum.map(&to_string/1)
      |> Enum.reject(&(&1 in @triage_snapshot_fields))

    if invalid_fields == [] do
      changeset
    else
      add_error(changeset, :payload, "triage_snapshot contains unsupported fields")
    end
  end

  defp validate_evidence_facts(changeset, payload) do
    case Map.get(payload, "evidence_facts") || Map.get(payload, :evidence_facts) do
      nil ->
        add_error(changeset, :payload, "triage_snapshot requires evidence_facts")

      facts when is_list(facts) ->
        bounded =
          Enum.all?(facts, fn fact ->
            is_binary(fact) and fact != "" and String.length(fact) <= 160
          end)

        if bounded and length(facts) in 1..4 do
          changeset
        else
          add_error(changeset, :payload, "evidence_facts must contain 1 to 4 short facts")
        end

      _ ->
        add_error(changeset, :payload, "evidence_facts must be a list")
    end
  end
end
