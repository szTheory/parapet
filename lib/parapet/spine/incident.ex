defmodule Parapet.Spine.Incident do
  @moduledoc """
  Ecto schema representing a durable evidence incident.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @triage_fields ~w(
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
  )

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          state: String.t() | nil,
          correlation_key: String.t() | nil,
          trace_id: String.t() | nil,
          runbook_data: map() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "parapet_incidents" do
    field(:title, :string)
    field(:description, :string)
    field(:state, :string, default: "open")
    field(:correlation_key, :string)
    field(:trace_id, :string)
    field(:runbook_data, :map)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:title, :description, :state, :correlation_key, :trace_id, :runbook_data])
    |> validate_required([:title])
    |> validate_inclusion(:state, ["open", "investigating", "resolved"])
    |> validate_triage_summary()
  end

  def triage_summary(%__MODULE__{runbook_data: runbook_data}) when is_map(runbook_data) do
    case Map.get(runbook_data, "triage") || Map.get(runbook_data, :triage) do
      summary when is_map(summary) -> summary
      _ -> nil
    end
  end

  def triage_summary(_incident), do: nil

  def put_triage_summary(runbook_data, nil) when is_map(runbook_data), do: runbook_data
  def put_triage_summary(nil, nil), do: %{}

  def put_triage_summary(runbook_data, summary) when is_map(summary) do
    runbook_data
    |> ensure_runbook_data()
    |> Map.put("triage", filter_triage_summary(summary))
  end

  def put_triage_summary(runbook_data, _summary), do: ensure_runbook_data(runbook_data)

  def put_runbook_schema(runbook_data, schema) when is_map(schema) do
    runbook_data
    |> ensure_runbook_data()
    |> Map.merge(schema)
  end

  defp validate_triage_summary(changeset) do
    case get_field(changeset, :runbook_data) do
      runbook_data when is_map(runbook_data) ->
        case Map.get(runbook_data, "triage") || Map.get(runbook_data, :triage) do
          nil ->
            changeset

          summary when is_map(summary) ->
            invalid_fields =
              summary
              |> Map.keys()
              |> Enum.map(&to_string/1)
              |> Enum.reject(&(&1 in @triage_fields))

            if invalid_fields == [] do
              changeset
            else
              add_error(changeset, :runbook_data, "triage contains unsupported fields")
            end

          _ ->
            add_error(changeset, :runbook_data, "triage must be a map")
        end

      _ ->
        changeset
    end
  end

  defp filter_triage_summary(summary) do
    summary
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      key = to_string(key)

      if key in @triage_fields and present_value?(value) do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end

  defp ensure_runbook_data(runbook_data) when is_map(runbook_data), do: runbook_data
  defp ensure_runbook_data(_), do: %{}

  defp present_value?(value) when is_binary(value), do: value != ""
  defp present_value?(nil), do: false
  defp present_value?(value), do: value != ""
end
