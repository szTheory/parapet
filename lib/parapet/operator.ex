defmodule Parapet.Operator do
  @moduledoc """
  Phoenix-free public boundary for the in-app Operator UI.
  Provides queue/detail queries and audited command entrypoints for incident mutations.
  """
  import Ecto.Query
  alias Parapet.Spine.Incident
  alias Parapet.Operator.ActionPayload
  alias Parapet.Evidence

  alias Parapet.Operator.WorkbenchContract

  @doc """
  Returns an Ecto.Query for the incident queue, sorting open/investigating first,
  and resolved incidents second (Phase 2 default sort).
  """
  def queue_query do
    from i in Incident,
      order_by: [
        asc: fragment("case when ? in ('open', 'investigating') then 1 else 2 end", i.state),
        desc: i.updated_at
      ]
  end

  @doc """
  Fetches an incident by ID along with its timeline entries and returns a
  workbench-ready map containing the incident, entries, and derived fields.
  """
  def incident_detail(incident_id) do
    # In a real implementation with Repo, we would:
    # incident = Evidence.repo().get(Incident, incident_id)
    # entries = Evidence.repo().all(from t in TimelineEntry, where: t.incident_id == ^incident_id, order_by: [desc: t.inserted_at])
    # For now, we define the API shape:
    incident = Evidence.repo().get!(Incident, incident_id)
    
    entries = Evidence.repo().all(
      from t in Parapet.Spine.TimelineEntry,
        where: t.incident_id == ^incident_id,
        order_by: [desc: t.inserted_at]
    )

    derived = WorkbenchContract.derive(incident, entries)

    %{
      incident: incident,
      entries: entries,
      derived: derived,
      external_links: extract_links(entries)
    }
  end

  defp extract_links(entries) do
    # Example extraction for external link placeholders
    entries
    |> Enum.filter(&(&1.type == "external_link"))
    |> Enum.map(& &1.payload)
  end

  @doc """
  Executes an audited `mark_investigating` command on an incident.
  """
  def mark_investigating(%Incident{} = incident, %ActionPayload{} = payload) do
    if valid_payload?(payload) do
      incident_changeset = Ecto.Changeset.change(incident, %{state: "investigating"})
      
      timeline_attrs = %{
        type: "status_change",
        payload: %{"new_state" => "investigating"}
      }
      
      audit_attrs = build_audit("operator_mark_investigating", payload)
      
      Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Executes an audited `record_note` command.
  """
  def record_note(%Incident{} = incident, text, %ActionPayload{} = payload) when is_binary(text) do
    if valid_payload?(payload) do
      incident_changeset = Ecto.Changeset.change(incident, %{}) # No state change
      
      timeline_attrs = %{
        type: "note",
        payload: %{"text" => text}
      }
      
      audit_attrs = build_audit("operator_record_note", payload)
      
      Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Executes an audited `attach_change_marker` command.
  """
  def attach_change_marker(%Incident{} = incident, change_ref, %ActionPayload{} = payload) when is_binary(change_ref) do
    if valid_payload?(payload) do
      incident_changeset = Ecto.Changeset.change(incident, %{})
      
      timeline_attrs = %{
        type: "change_marker",
        payload: %{"change_ref" => change_ref}
      }
      
      audit_attrs = build_audit("operator_attach_change_marker", payload)
      
      Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Executes an audited `request_approval` command.
  """
  def request_approval(%Incident{} = incident, approval_key, %ActionPayload{} = payload) when is_binary(approval_key) do
    if valid_payload?(payload) do
      incident_changeset = Ecto.Changeset.change(incident, %{})
      
      timeline_attrs = %{
        type: "approval_requested",
        payload: %{"approval_key" => approval_key, "state" => "pending"}
      }
      
      audit_attrs = build_audit("operator_request_approval", payload)
      
      Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Delegates dynamic capability queries (e.g., UI mitigations) to the capability registry.
  """
  def capabilities(type) do
    Parapet.Capabilities.capabilities(type)
  end

  defp valid_payload?(%ActionPayload{actor: actor, reason: reason, correlation_id: correlation_id, action_type: action_type}) do
    not is_nil(actor) and not is_nil(reason) and not is_nil(correlation_id) and not is_nil(action_type)
  end

  defp build_audit(tool_name, %ActionPayload{} = payload) do
    %{
      tool_name: tool_name,
      success: true,
      input: %{
        "actor" => payload.actor,
        "reason" => payload.reason,
        "correlation_id" => payload.correlation_id,
        "idempotency_key" => payload.idempotency_key,
        "action_type" => Atom.to_string(payload.action_type)
      }
    }
  end
end
