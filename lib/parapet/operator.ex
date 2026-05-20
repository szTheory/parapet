defmodule Parapet.Operator do
  @moduledoc """
  Phoenix-free public boundary for the in-app Operator UI.
  Provides queue/detail queries and audited command entrypoints for incident mutations.
  """
  import Ecto.Query
  alias Parapet.Spine.Incident
  alias Parapet.Spine.ActionItem
  alias Parapet.Operator.ActionPayload
  alias Parapet.Evidence

  alias Parapet.Operator.WorkbenchContract

  @active_queue_states ["open", "investigating"]
  @default_queue_page_size 30
  @max_queue_page_size 100

  @doc """
  Returns an Ecto.Query for open action items, sorted by inserted_at ascending.
  """
  def action_items_query do
    from(a in ActionItem,
      where: a.state == "open",
      order_by: [asc: a.inserted_at]
    )
  end

  @doc """
  Returns an Ecto.Query for the incident queue, sorting open/investigating first,
  and resolved incidents second (Phase 2 default sort).
  """
  def queue_query do
    from(i in Incident,
      order_by: [
        asc: fragment("case when ? in ('open', 'investigating') then 1 else 2 end", i.state),
        desc: i.updated_at
      ]
    )
  end

  @doc """
  Returns a bounded, active-only incident queue page suitable for operator browsing.
  Invalid cursor or direction params fall back to the first page.
  """
  def list_incident_queue(opts \\ []) do
    options = normalize_queue_options(opts)
    query = build_queue_page_query(options)
    incidents = Evidence.repo().all(query)

    {visible_items, has_more?} =
      incidents
      |> maybe_reverse_queue_items(options.direction)
      |> split_queue_page(options.page_size)

    %{
      scope: options.scope,
      direction: options.direction,
      page_size: options.page_size,
      items: visible_items,
      has_next_page?: has_next_page?(options, has_more?, visible_items),
      has_previous_page?: has_previous_page?(options, has_more?, visible_items),
      next_cursor: next_cursor_for(options, visible_items, has_more?),
      previous_cursor: previous_cursor_for(options, visible_items, has_more?)
    }
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

    entries =
      Evidence.repo().all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident_id,
          order_by: [asc: t.inserted_at]
        )
      )

    action_items =
      Evidence.repo().all(
        from(a in Parapet.Spine.ActionItem,
          where: a.incident_id == ^incident_id
        )
      )

    derived = WorkbenchContract.derive(incident, entries, action_items)

    timeline_entries =
      entries
      |> Enum.zip(derived.timeline_presentations || [])
      |> Enum.map(fn {entry, presentation} ->
        %{entry: entry, presentation: presentation}
      end)

    %{
      incident: incident,
      entries: entries,
      derived: derived,
      action_items: action_items,
      external_links: extract_links(entries),
      escalation_summary: derived.escalation_summary,
      timeline_entries: timeline_entries
    }
  end

  defp extract_links(entries) do
    # Example extraction for external link placeholders
    entries
    |> Enum.filter(&(&1.type == "external_link"))
    |> Enum.map(& &1.payload)
  end

  defp normalize_queue_options(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> normalize_queue_options()

  defp normalize_queue_options(opts) when is_map(opts) do
    page_size = normalize_page_size(Map.get(opts, :page_size) || Map.get(opts, "page_size"))

    with {:ok, direction} <- normalize_queue_direction(Map.get(opts, :direction) || Map.get(opts, "direction")),
         {:ok, cursor} <- normalize_queue_cursor(Map.get(opts, :cursor) || Map.get(opts, "cursor")) do
      %{
        scope: :active,
        direction: direction,
        page_size: page_size,
        cursor: cursor
      }
    else
      :error ->
        default_queue_options(page_size)
    end
  end

  defp normalize_queue_options(_opts), do: default_queue_options(@default_queue_page_size)

  defp default_queue_options(page_size) do
    %{
      scope: :active,
      direction: :next,
      page_size: page_size,
      cursor: nil
    }
  end

  defp normalize_page_size(page_size) when is_integer(page_size) do
    page_size
    |> max(1)
    |> min(@max_queue_page_size)
  end

  defp normalize_page_size(page_size) when is_binary(page_size) do
    case Integer.parse(page_size) do
      {value, ""} -> normalize_page_size(value)
      _ -> @default_queue_page_size
    end
  end

  defp normalize_page_size(_page_size), do: @default_queue_page_size

  defp normalize_queue_direction(nil), do: {:ok, :next}
  defp normalize_queue_direction(:next), do: {:ok, :next}
  defp normalize_queue_direction(:previous), do: {:ok, :previous}
  defp normalize_queue_direction("next"), do: {:ok, :next}
  defp normalize_queue_direction("previous"), do: {:ok, :previous}
  defp normalize_queue_direction(_direction), do: :error

  defp normalize_queue_cursor(nil), do: {:ok, nil}

  defp normalize_queue_cursor(cursor) when is_binary(cursor) do
    with {:ok, decoded} <- Base.url_decode64(cursor, padding: false),
         [updated_at_raw, id] <- String.split(decoded, "|", parts: 2),
         {:ok, updated_at, 0} <- DateTime.from_iso8601(updated_at_raw),
         true <- id != "" do
      {:ok, %{updated_at: updated_at, id: id}}
    else
      _ -> :error
    end
  end

  defp normalize_queue_cursor(_cursor), do: :error

  defp build_queue_page_query(%{direction: direction, cursor: cursor, page_size: page_size}) do
    Incident
    |> where([i], i.state in ^@active_queue_states)
    |> apply_queue_cursor(direction, cursor)
    |> apply_queue_order(direction)
    |> limit(^page_size + 1)
  end

  defp apply_queue_cursor(query, _direction, nil), do: query

  defp apply_queue_cursor(query, :next, %{updated_at: updated_at, id: id}) do
    where(
      query,
      [i],
      i.updated_at < ^updated_at or (i.updated_at == ^updated_at and i.id < ^id)
    )
  end

  defp apply_queue_cursor(query, :previous, %{updated_at: updated_at, id: id}) do
    where(
      query,
      [i],
      i.updated_at > ^updated_at or (i.updated_at == ^updated_at and i.id > ^id)
    )
  end

  defp apply_queue_order(query, :next) do
    order_by(query, [i], [desc: i.updated_at, desc: i.id])
  end

  defp apply_queue_order(query, :previous) do
    order_by(query, [i], [asc: i.updated_at, asc: i.id])
  end

  defp maybe_reverse_queue_items(items, :previous), do: Enum.reverse(items)
  defp maybe_reverse_queue_items(items, _direction), do: items

  defp split_queue_page(items, page_size) do
    visible_items = Enum.take(items, page_size)
    {visible_items, length(items) > page_size}
  end

  defp has_next_page?(%{direction: :next}, has_more?, _items), do: has_more?
  defp has_next_page?(%{direction: :previous, cursor: nil}, _has_more?, _items), do: false
  defp has_next_page?(%{direction: :previous}, _has_more?, items), do: items != []

  defp has_previous_page?(%{direction: :next, cursor: nil}, _has_more?, _items), do: false
  defp has_previous_page?(%{direction: :next}, _has_more?, items), do: items != []
  defp has_previous_page?(%{direction: :previous}, has_more?, _items), do: has_more?

  defp next_cursor_for(%{direction: :next}, items, true), do: encode_queue_cursor(List.last(items))
  defp next_cursor_for(%{direction: :previous, cursor: nil}, _items, _has_more?), do: nil
  defp next_cursor_for(%{direction: :previous}, items, _has_more?), do: encode_queue_cursor(List.last(items))
  defp next_cursor_for(_options, _items, _has_more?), do: nil

  defp previous_cursor_for(%{direction: :next, cursor: nil}, _items, _has_more?), do: nil
  defp previous_cursor_for(%{direction: :next}, items, _has_more?), do: encode_queue_cursor(List.first(items))
  defp previous_cursor_for(%{direction: :previous}, items, true), do: encode_queue_cursor(List.first(items))
  defp previous_cursor_for(_options, _items, _has_more?), do: nil

  defp encode_queue_cursor(nil), do: nil

  defp encode_queue_cursor(%{updated_at: %DateTime{} = updated_at, id: id}) when is_binary(id) do
    "#{DateTime.to_iso8601(updated_at)}|#{id}"
    |> Base.url_encode64(padding: false)
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
  Executes an audited `acknowledge_incident` command.
  Transitions the incident to 'investigating' state and adds an 'acknowledge' timeline entry.
  """
  def acknowledge_incident(%Incident{} = incident, %ActionPayload{} = payload) do
    if valid_payload?(payload) do
      incident_changeset = Ecto.Changeset.change(incident, %{state: "investigating"})

      timeline_attrs = %{
        type: "acknowledge",
        payload: %{}
      }

      audit_attrs = build_audit("operator_acknowledge_incident", payload)

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
  Executes an audited `resolve_incident` command.
  Transitions the incident to 'resolved' state and attaches an automated retrospective.
  """
  def resolve_incident(%Incident{} = incident, %ActionPayload{} = payload) do
    if valid_payload?(payload) do
      # Fetch entries to generate an accurate retrospective including the simulated final step
      entries =
        Evidence.repo().all(
          from(t in Parapet.Spine.TimelineEntry,
            where: t.incident_id == ^incident.id,
            order_by: [asc: t.inserted_at]
          )
        )

      simulated_resolve_entry = %Parapet.Spine.TimelineEntry{
        type: "status_change",
        payload: %{"new_state" => "resolved"},
        inserted_at: DateTime.utc_now()
      }

      retrospective =
        Parapet.Evidence.Retrospective.generate_markdown(
          %{incident | state: "resolved"},
          entries ++ [simulated_resolve_entry]
        )

      runbook_data = incident.runbook_data || %{}
      runbook_data = Map.put(runbook_data, "retrospective", retrospective)

      incident_changeset =
        Ecto.Changeset.change(incident, %{state: "resolved", runbook_data: runbook_data})

      timeline_attrs = %{
        type: "status_change",
        payload: %{"new_state" => "resolved"}
      }

      audit_attrs = build_audit("operator_resolve_incident", payload)

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
  def record_note(%Incident{} = incident, text, %ActionPayload{} = payload)
      when is_binary(text) do
    if valid_payload?(payload) do
      # No state change
      incident_changeset = Ecto.Changeset.change(incident, %{})

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
  def attach_change_marker(%Incident{} = incident, change_ref, %ActionPayload{} = payload)
      when is_binary(change_ref) do
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
  def request_approval(%Incident{} = incident, approval_key, %ActionPayload{} = payload)
      when is_binary(approval_key) do
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
  Records an explicit operator request to trigger the next escalation.
  Persists only bounded current-state metadata and leaves execution to the worker.
  """
  def trigger_next_escalation(%Incident{state: state}, _payload)
      when state in ["investigating", "resolved"] do
    {:error, :invalid_incident_state}
  end

  def trigger_next_escalation(%Incident{} = incident, %ActionPayload{} = payload) do
    if valid_payload?(payload) do
      escalation_data =
        incident
        |> escalation_command_state()
        |> Map.put("pending_trigger", true)
        |> Map.put("triggered_by", payload.actor)
        |> Map.put("trigger_reason", payload.reason)
        |> Map.put("trigger_requested_at", DateTime.utc_now() |> DateTime.truncate(:second))

      incident_changeset =
        Ecto.Changeset.change(incident, %{
          runbook_data: put_escalation_command_state(incident.runbook_data, escalation_data)
        })

      timeline_attrs = %{
        type: "escalation_trigger_requested",
        payload: %{
          "actor" => payload.actor,
          "reason" => payload.reason,
          "mode" => "manual",
          "pending_trigger" => true
        }
      }

      audit_attrs = build_audit("operator_trigger_next_escalation", payload)

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
  Records a temporary suppression window for pending escalation execution.
  """
  def suppress_pending_escalation(
        %Incident{state: state},
        _suppressed_until,
        _payload
      )
      when state in ["investigating", "resolved"] do
    {:error, :invalid_incident_state}
  end

  def suppress_pending_escalation(
        %Incident{} = incident,
        %DateTime{} = suppressed_until,
        %ActionPayload{} = payload
      ) do
    if valid_payload?(payload) do
      case validate_suppression_window(suppressed_until) do
        :ok ->
          bounded_until = DateTime.truncate(suppressed_until, :second)

          escalation_data =
            incident
            |> escalation_command_state()
            |> Map.put("suppressed_until", bounded_until)
            |> Map.put("suppressed_by", payload.actor)
            |> Map.put("suppression_reason", payload.reason)
            |> Map.delete("pending_trigger")

          incident_changeset =
            Ecto.Changeset.change(incident, %{
              runbook_data: put_escalation_command_state(incident.runbook_data, escalation_data)
            })

          timeline_attrs = %{
            type: "escalation_suppressed",
            payload: %{
              "actor" => payload.actor,
              "reason" => payload.reason,
              "suppressed_until" => bounded_until
            }
          }

          audit_attrs = build_audit("operator_suppress_pending_escalation", payload)

          Evidence.run_operator_command(
            incident_changeset: incident_changeset,
            timeline_attrs: timeline_attrs,
            audit_attrs: audit_attrs
          )

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Executes a mitigation step securely via dynamic dispatch from a runbook.
  """
  def execute_runbook_step(%Incident{} = incident, step_id, %ActionPayload{} = payload)
      when is_binary(step_id) or is_atom(step_id) do
    if valid_payload?(payload) do
      with {:ok, module} <- extract_module(incident.runbook_data),
           {:ok, step_atom} <- parse_step_id(step_id),
           true <-
             function_exported?(module, :execute_mitigation, 2) ||
               {:error, :function_not_exported},
           {:ok, mitigation_result} <- apply(module, :execute_mitigation, [step_atom, incident]) do
        incident_changeset = Ecto.Changeset.change(incident, %{})

        timeline_attrs = %{
          type: "mitigation_executed",
          payload: %{
            "step_id" => to_string(step_atom),
            "module" => to_string(module),
            "result" => inspect(mitigation_result),
            "actor" => payload.actor
          }
        }

        audit_attrs = build_audit("operator_execute_mitigation", payload)

        Evidence.run_operator_command(
          incident_changeset: incident_changeset,
          timeline_attrs: timeline_attrs,
          audit_attrs: audit_attrs
        )
      else
        {:error, :function_not_exported} -> {:error, :step_no_longer_exists}
        error -> error
      end
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Previews a recovery action for a runbook step.
  Resolves the named capability and returns a bounded preview payload.
  """
  def preview_runbook_step(%Incident{} = incident, step_id, %ActionPayload{} = payload) do
    if valid_payload?(payload) do
      with {:ok, module} <- extract_module(incident.runbook_data),
           {:ok, step_id_atom} <- parse_step_id(step_id),
           true <- function_exported?(module, :__runbook_schema__, 0) || {:error, :not_a_runbook},
           schema <- module.__runbook_schema__(),
           step <- Enum.find(schema.steps, &(&1.id == step_id_atom)),
           {:ok, step} <- validate_step_exists(step),
           capability_id <- step.capability,
           capability when not is_nil(capability) <-
             Parapet.Capabilities.get_recovery(capability_id) do
        preview_data = compute_preview(capability, incident, step)

        timeline_attrs = %{
          type: "recovery_preview",
          payload: preview_data
        }

        audit_attrs = build_audit("operator_preview_recovery", payload)

        Evidence.run_operator_command(
          incident_changeset: Ecto.Changeset.change(incident, %{}),
          timeline_attrs: timeline_attrs,
          audit_attrs: audit_attrs
        )
        |> case do
          {:ok, result} -> {:ok, Map.put(result, :preview, preview_data)}
          error -> error
        end
      else
        nil -> {:error, :capability_unwired}
        {:error, _} = error -> error
      end
    else
      {:error, :invalid_payload}
    end
  end

  @doc """
  Confirms and executes a recovery action.
  Validates the preview_token and requires an idempotency_key in the payload.
  """
  def confirm_runbook_step(
        %Incident{} = incident,
        step_id,
        preview_token,
        %ActionPayload{} = payload
      ) do
    if valid_payload?(payload) do
      with {:ok, module} <- extract_module(incident.runbook_data),
           {:ok, step_id_atom} <- parse_step_id(step_id),
           true <- function_exported?(module, :__runbook_schema__, 0) || {:error, :not_a_runbook},
           schema <- module.__runbook_schema__(),
           step <- Enum.find(schema.steps, &(&1.id == step_id_atom)),
           {:ok, step} <- validate_step_exists(step),
           capability_id <- step.capability,
           capability when not is_nil(capability) <-
             Parapet.Capabilities.get_recovery(capability_id),
           {:ok, preview_entry} <- find_recent_preview(incident.id, step_id_atom, preview_token) do
        if DateTime.compare(preview_entry.expires_at, DateTime.utc_now()) == :gt do
          # Execute the capability
          if is_function(capability.execute, 2) do
            case capability.execute.(incident, preview_entry.target_refs) do
              {:ok, exec_result} ->
                timeline_attrs = %{
                  type: "recovery_confirmed",
                  payload: %{
                    "step_id" => to_string(step_id_atom),
                    "capability" => to_string(capability_id),
                    "result" => inspect(exec_result)
                  }
                }

                audit_attrs = build_audit("operator_confirm_recovery", payload)

                Evidence.run_operator_command(
                  incident_changeset: Ecto.Changeset.change(incident, %{}),
                  timeline_attrs: timeline_attrs,
                  audit_attrs: audit_attrs
                )

              {:error, reason} ->
                {:error, reason}
            end
          else
            {:error, :capability_no_execute_callback}
          end
        else
          {:error, :stale_preview}
        end
      else
        nil -> {:error, :capability_unwired}
        {:error, _} = error -> error
      end
    else
      {:error, :invalid_payload}
    end
  end

  defp validate_step_exists(nil), do: {:error, :step_not_found}
  defp validate_step_exists(step), do: {:ok, step}

  defp compute_preview(capability, incident, step) do
    expires_at = DateTime.utc_now() |> DateTime.add(300, :second)
    preview_token = :crypto.strong_rand_bytes(16) |> Base.encode16()

    base_preview = %{
      "capability" => to_string(capability.id),
      "step_id" => to_string(step.id),
      "target_kind" => capability.target_kind || step.target_kind,
      "target_refs" => [],
      "count" => 0,
      "preconditions" => [],
      "warnings" => [],
      "idempotency_caveats" => "Standard idempotency applies.",
      "expires_at" => expires_at,
      "preview_token" => preview_token
    }

    if is_function(capability.preview, 2) do
      case capability.preview.(incident, step) do
        {:ok, host_data} ->
          # Convert host_data keys to strings for consistency in timeline payload
          host_data_str = for {k, v} <- host_data, into: %{}, do: {to_string(k), v}
          Map.merge(base_preview, host_data_str)

        _ ->
          base_preview
      end
    else
      base_preview
    end
  end

  defp find_recent_preview(incident_id, step_id, token) do
    # Fetch from Evidence repo
    entries =
      Evidence.repo().all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident_id and t.type == "recovery_preview",
          order_by: [desc: t.inserted_at]
        )
      )

    # Find matching token
    match =
      Enum.find(entries, fn entry ->
        entry.payload["preview_token"] == token and
          entry.payload["step_id"] == to_string(step_id)
      end)

    case match do
      %{payload: payload} ->
        expires_at =
          case payload["expires_at"] do
            %DateTime{} = dt ->
              dt

            str when is_binary(str) ->
              {:ok, dt, _} = DateTime.from_iso8601(str)
              dt

            _ ->
              DateTime.utc_now()
          end

        {:ok, %{expires_at: expires_at, target_refs: payload["target_refs"]}}

      _ ->
        {:error, :mismatched_preview}
    end
  end

  defp extract_module(%{"module" => mod_str}) when is_binary(mod_str) do
    try do
      {:ok, String.to_existing_atom(mod_str)}
    rescue
      ArgumentError -> {:error, :invalid_module}
    end
  end

  defp extract_module(%{module: mod_str}) when is_binary(mod_str) do
    try do
      {:ok, String.to_existing_atom(mod_str)}
    rescue
      ArgumentError -> {:error, :invalid_module}
    end
  end

  defp extract_module(_), do: {:error, :missing_runbook}

  defp parse_step_id(step_id) when is_atom(step_id), do: {:ok, step_id}

  defp parse_step_id(step_id) when is_binary(step_id) do
    try do
      {:ok, String.to_existing_atom(step_id)}
    rescue
      ArgumentError -> {:error, :invalid_step_id}
    end
  end

  @doc """
  Delegates dynamic capability queries (e.g., UI mitigations) to the capability registry.
  """
  def capabilities(type) do
    Parapet.Capabilities.capabilities(type)
  end

  defp valid_payload?(%ActionPayload{} = payload) do
    # Basic presence check for mandatory audit fields
    has_audit =
      not is_nil(payload.actor) and not is_nil(payload.reason) and
        not is_nil(payload.correlation_id) and
        not is_nil(payload.action_type)

    # Mutating recovery actions must have an idempotency key
    if has_audit do
      if payload.action_type == :execute_mitigation do
        not is_nil(payload.idempotency_key)
      else
        true
      end
    else
      false
    end
  end

  defp escalation_command_state(%Incident{runbook_data: runbook_data})
       when is_map(runbook_data) do
    case Map.get(runbook_data, "escalation") || Map.get(runbook_data, :escalation) do
      escalation when is_map(escalation) -> normalize_map_keys(escalation)
      _ -> %{}
    end
  end

  defp escalation_command_state(_incident), do: %{}

  defp put_escalation_command_state(runbook_data, escalation_data) do
    runbook_data
    |> normalize_map_keys()
    |> Map.put("escalation", escalation_data)
  end

  defp normalize_map_keys(runbook_data) when is_map(runbook_data) do
    Map.new(runbook_data, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_map_keys(_), do: %{}

  defp validate_suppression_window(%DateTime{} = suppressed_until) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    max_until = DateTime.add(now, 86_400, :second)

    cond do
      DateTime.compare(suppressed_until, now) != :gt ->
        {:error, :invalid_suppression_window}

      DateTime.compare(suppressed_until, max_until) == :gt ->
        {:error, :invalid_suppression_window}

      true ->
        :ok
    end
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
