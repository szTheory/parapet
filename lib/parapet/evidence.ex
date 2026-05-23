defmodule Parapet.Evidence do
  @moduledoc """
  Public API boundary for Spine schemas.
  Enforces a boundary that prevents high-volume telemetry from writing directly
  to the durable Ecto database.
  """

  alias Parapet.Spine.{ActionItem, Incident, TimelineEntry, ToolAudit}
  import Ecto.Query

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
  Creates a new ActionItem.
  """
  def create_action_item(attrs \\ %{}) do
    %ActionItem{}
    |> ActionItem.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Idempotently marks an ActionItem as resolved.
  Accepts either the internal primary key ID or a keyword list of criteria.
  """
  def resolve_action_item(criteria) when is_list(criteria) do
    from(a in ActionItem, where: ^criteria)
    |> repo().update_all(set: [state: "resolved"])
  end

  def resolve_action_item(id) do
    from(a in ActionItem, where: a.id == ^id)
    |> repo().update_all(set: [state: "resolved"])
  end

  @doc """
  Creates a new Incident.
  """
  def create_incident(attrs \\ %{}) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:incident, Incident.changeset(%Incident{}, attrs))
      |> maybe_enqueue_escalation()

    case repo().transaction(multi) do
      {:ok, %{incident: incident}} -> {:ok, incident}
      {:error, :incident, changeset, _} -> {:error, changeset}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  defp maybe_enqueue_escalation(multi) do
    worker = Parapet.Escalation.Worker

    if Code.ensure_loaded?(worker) and Application.get_env(:parapet, :escalation_policy) do
      Ecto.Multi.insert(multi, :escalation_job, fn %{incident: incident} ->
        apply(worker, :new, [%{"incident_id" => incident.id}])
      end)
    else
      multi
    end
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
    case Application.get_env(:parapet, :audit_mode, :dual_write) do
      :threadline_deferred ->
        :telemetry.execute([:parapet, :audit, :created], %{}, %{audit_attrs: attrs})
        {:ok, :deferred}

      :dual_write ->
        result =
          %ToolAudit{}
          |> ToolAudit.changeset(attrs)
          |> repo().insert()

        case result do
          {:ok, struct} ->
            :telemetry.execute([:parapet, :audit, :created], %{}, %{audit_attrs: attrs})
            {:ok, struct}

          error ->
            error
        end
    end
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

    multi =
      case Application.get_env(:parapet, :audit_mode, :dual_write) do
        :threadline_deferred ->
          Ecto.Multi.run(multi, :tool_audit, fn _repo, %{timeline_entry: entry} ->
            full_attrs = Map.put(audit_attrs, :timeline_entry_id, entry.id)
            :telemetry.execute([:parapet, :audit, :created], %{}, %{audit_attrs: full_attrs})
            {:ok, :deferred}
          end)

        :dual_write ->
          multi
          |> Ecto.Multi.insert(:tool_audit, fn %{timeline_entry: entry} ->
            %ToolAudit{}
            |> ToolAudit.changeset(Map.put(audit_attrs, :timeline_entry_id, entry.id))
          end)
          |> Ecto.Multi.run(:broadcast_audit, fn _repo, %{timeline_entry: entry} ->
            full_attrs = Map.put(audit_attrs, :timeline_entry_id, entry.id)
            :telemetry.execute([:parapet, :audit, :created], %{}, %{audit_attrs: full_attrs})
            {:ok, :broadcasted}
          end)
      end

    repo().transaction(multi)
  end
end
