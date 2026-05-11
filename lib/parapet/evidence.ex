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
end
