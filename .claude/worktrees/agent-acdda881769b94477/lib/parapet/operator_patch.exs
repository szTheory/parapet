@doc """
Previews a mutating recovery step.
"""
def preview_runbook_step(%Incident{} = incident, step_id, target_refs, %ActionPayload{} = payload) do
  if valid_payload?(payload) do
    with {:ok, module} <- extract_module(incident.runbook_data),
         {:ok, step_atom} <- parse_step_id(step_id),
         schema <- module.__runbook_schema__(),
         step when not is_nil(step) <- Enum.find(schema.steps, &(&1.id == step_atom)),
         capability_id when not is_nil(capability_id) <- Map.get(step, :capability),
         capability when not is_nil(capability) <-
           Parapet.Capabilities.get_recovery(capability_id),
         preview_fn when not is_nil(preview_fn) <- capability.preview do
      preview_data = preview_fn.(incident, target_refs)

      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)
      preview_token = Ecto.UUID.generate()

      preview_payload = %{
        "capability" => capability_id,
        "target_kind" => capability.target_kind || Map.get(step, :target_kind),
        "target_refs" => target_refs,
        "count" => Enum.count(List.wrap(target_refs)),
        "preconditions" => Map.get(preview_data, :preconditions, []),
        "warnings" => Map.get(preview_data, :warnings, []),
        "idempotency_caveats" => Map.get(preview_data, :idempotency_caveats, ""),
        "expires_at" => expires_at,
        "preview_token" => preview_token
      }

      incident_changeset = Ecto.Changeset.change(incident, %{})

      timeline_attrs = %{
        type: "recovery_previewed",
        payload: preview_payload
      }

      audit_attrs = build_audit("operator_preview_runbook_step", payload)

      case Evidence.run_operator_command(
             incident_changeset: incident_changeset,
             timeline_attrs: timeline_attrs,
             audit_attrs: audit_attrs
           ) do
        {:ok, _result} -> {:ok, preview_payload}
        error -> error
      end
    else
      nil -> {:error, :step_not_found}
      %{capability: nil} -> {:error, :no_capability_wired}
      error -> error
    end
  else
    {:error, :invalid_payload}
  end
end

@doc """
Confirms and executes a previously previewed runbook step.
"""
def confirm_runbook_step(
      %Incident{} = incident,
      step_id,
      preview_token,
      %ActionPayload{} = payload
    ) do
  if valid_payload?(payload) do
    entries =
      Evidence.repo().all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident.id and t.type == "recovery_previewed"
        )
      )

    preview_entry =
      Enum.find(entries, fn e ->
        is_map(e.payload) and e.payload["preview_token"] == preview_token
      end)

    expires_at_dt =
      if preview_entry && preview_entry.payload["expires_at"] do
        case preview_entry.payload["expires_at"] do
          %DateTime{} = dt ->
            dt

          str when is_binary(str) ->
            case DateTime.from_iso8601(str) do
              {:ok, dt, _} -> dt
              _ -> nil
            end

          _ ->
            nil
        end
      else
        nil
      end

    with true <- not is_nil(preview_entry),
         true <-
           not is_nil(expires_at_dt) and
             DateTime.compare(expires_at_dt, DateTime.utc_now()) == :gt,
         {:ok, module} <- extract_module(incident.runbook_data),
         {:ok, step_atom} <- parse_step_id(step_id),
         schema <- module.__runbook_schema__(),
         step when not is_nil(step) <- Enum.find(schema.steps, &(&1.id == step_atom)),
         capability_id when not is_nil(capability_id) <- Map.get(step, :capability),
         capability when not is_nil(capability) <-
           Parapet.Capabilities.get_recovery(capability_id),
         execute_fn when not is_nil(execute_fn) <- capability.execute do
      target_refs = preview_entry.payload["target_refs"]

      execution_result = execute_fn.(incident, target_refs)

      incident_changeset = Ecto.Changeset.change(incident, %{})

      timeline_attrs = %{
        type: "recovery_executed",
        payload: %{
          "capability" => capability_id,
          "preview_token" => preview_token,
          "target_refs" => target_refs,
          "result" => inspect(execution_result)
        }
      }

      audit_attrs = build_audit("operator_confirm_runbook_step", payload)

      Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
    else
      false -> {:error, :stale_or_invalid_preview}
      nil -> {:error, :step_not_found}
      %{capability: nil} -> {:error, :no_capability_wired}
      error -> error
    end
  else
    {:error, :invalid_payload}
  end
end
