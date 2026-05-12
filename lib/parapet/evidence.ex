defmodule Parapet.Evidence do
  @moduledoc """
  Public API boundary for Spine schemas.
  Enforces a boundary that prevents high-volume telemetry from writing directly
  to the durable Ecto database.
  """

  alias Parapet.Spine.{Incident, TimelineEntry, ToolAudit}

  @doc """
  Returns the configured Ecto.Repo for the host application.
  Raises if not configured.
  """
  def repo do
    Application.get_env(:parapet, :repo) ||
      raise ArgumentError,
            "Parapet requires a :repo to be configured. Please set `config :parapet, repo: MyApp.Repo`."
  end

  @doc """
  Creates a new Incident.
  """
  def create_incident(attrs \\ %{}) do
    %Incident{}
    |> Incident.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Appends a TimelineEntry to an existing Incident.
  """
  def append_timeline(incident_id, attrs \\ %{}) do
    %TimelineEntry{}
    |> TimelineEntry.changeset(Map.put(attrs, :incident_id, incident_id))
    |> repo().insert()
  end

  @doc """
  Logs a ToolAudit entry.
  """
  def log_tool_audit(attrs \\ %{}) do
    %ToolAudit{}
    |> ToolAudit.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Executes an operator command as a single transactional seam.
  Requires `incident_changeset`, `timeline_attrs`, and `audit_attrs` keyword list args.
  """
  @dialyzer {:nowarn_function, run_operator_command: 1}
  def run_operator_command(opts) do
    incident_changeset = Keyword.fetch!(opts, :incident_changeset)
    timeline_attrs = Keyword.fetch!(opts, :timeline_attrs)
    audit_attrs = Keyword.fetch!(opts, :audit_attrs)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:incident, incident_changeset)
      |> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} ->
        %TimelineEntry{}
        |> TimelineEntry.changeset(Map.put(timeline_attrs, :incident_id, incident.id))
      end)
      |> Ecto.Multi.insert(:tool_audit, fn %{timeline_entry: entry} ->
        %ToolAudit{}
        |> ToolAudit.changeset(Map.put(audit_attrs, :timeline_entry_id, entry.id))
      end)

    repo().transaction(multi)
  end
end
