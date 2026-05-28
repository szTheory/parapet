defmodule DemoAppWeb.Parapet.OperatorDetailLive do
  @moduledoc false
  use DemoAppWeb, :live_view

  import DemoAppWeb.Parapet.OperatorComponents

  def mount(%{"id" => id}, _session, socket) do
    selected = load_detail(id)

    {:ok, assign(socket, incident: selected)}
  end

  def handle_event("acknowledge", %{"id" => id}, socket) do
    incident = DemoApp.Repo.get!(Parapet.Spine.Incident, id)
    payload = %Parapet.Operator.ActionPayload{
      actor: "operator_ui",
      reason: "Acknowledged via UI",
      correlation_id: Ecto.UUID.generate(),
      action_type: :acknowledge
    }

    case Parapet.Operator.acknowledge_incident(incident, payload) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Incident acknowledged successfully")
         |> push_navigate(to: "/parapet/#{id}")}
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to acknowledge")}
    end
  end

  def handle_event("resolve", %{"id" => id}, socket) do
    incident = DemoApp.Repo.get!(Parapet.Spine.Incident, id)
    payload = %Parapet.Operator.ActionPayload{
      actor: "operator_ui",
      reason: "Resolved via UI",
      correlation_id: Ecto.UUID.generate(),
      action_type: :resolve
    }

    case Parapet.Operator.resolve_incident(incident, payload) do
      {:ok, _result} ->
        {:noreply, push_navigate(socket, to: "/parapet/#{id}")}
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to resolve")}
    end
  end

  def handle_event("trigger_next_escalation", %{"id" => id}, socket) do
    incident = DemoApp.Repo.get!(Parapet.Spine.Incident, id)
    payload = %Parapet.Operator.ActionPayload{
      actor: "operator_ui",
      reason: "Requested next escalation from UI",
      correlation_id: Ecto.UUID.generate(),
      action_type: :trigger_next_escalation
    }

    case Parapet.Operator.trigger_next_escalation(incident, payload) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Escalation request recorded")
         |> assign(incident: load_detail(id))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to request escalation: #{inspect(reason)}")}
    end
  end

  def handle_event("suppress_pending_escalation", %{"id" => id, "minutes" => minutes}, socket) do
    incident = DemoApp.Repo.get!(Parapet.Spine.Incident, id)
    with {minutes, ""} <- Integer.parse(minutes),
         true <- minutes > 0 do
      suppress_until =
        DateTime.utc_now()
        |> DateTime.add(minutes * 60, :second)
        |> DateTime.truncate(:second)

      payload = %Parapet.Operator.ActionPayload{
        actor: "operator_ui",
        reason: "Temporarily suppressed pending escalation from UI",
        correlation_id: Ecto.UUID.generate(),
        action_type: :suppress_pending_escalation
      }

      case Parapet.Operator.suppress_pending_escalation(incident, suppress_until, payload) do
        {:ok, _result} ->
          {:noreply,
           socket
           |> put_flash(:info, "Escalation suppression recorded")
           |> assign(incident: load_detail(id))}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to suppress escalation: #{inspect(reason)}")}
      end
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Invalid suppression window")}
    end
  end

  def handle_event("preview_mitigation", %{"step" => step, "incident_id" => incident_id}, socket) do
    incident = DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)
    payload = %Parapet.Operator.ActionPayload{
      actor: "operator_ui",
      reason: "Previewed mitigation from UI",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    case Parapet.Operator.preview_runbook_step(incident, step, payload) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Preview generated")
         |> assign(incident: load_detail(incident_id))}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Preview failed: #{inspect(reason)}")}
    end
  end

  def handle_event("confirm_mitigation", %{"step" => step, "incident_id" => incident_id, "token" => token}, socket) do
    incident = DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)
    payload = %Parapet.Operator.ActionPayload{
      actor: "operator_ui",
      reason: "Confirmed mitigation from UI",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    case Parapet.Operator.confirm_runbook_step(incident, step, token, payload) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Mitigation confirmed and executed")
         |> assign(incident: load_detail(incident_id))}

      {:short_circuited, reason} ->
        {:noreply,
         socket
         |> put_flash(:warning, short_circuit_flash(reason))
         |> assign(incident: load_detail(incident_id))}

      {:conflicted, _claim_id} ->
        {:noreply,
         socket
         |> put_flash(:warning, "Another node is executing this recovery — refresh to see the outcome")
         |> assign(incident: load_detail(incident_id))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Confirmation failed: #{inspect(reason)}")}
    end
  end

  def handle_event("cancel_preview", _params, socket) do
    {:noreply, socket}
  end

  defp short_circuit_flash(:preview_expired), do: "Preview expired — please re-Preview before confirming"
  defp short_circuit_flash(:incident_resolved), do: "Incident already resolved — no action needed"
  defp short_circuit_flash(:breaker_open), do: "Circuit breaker open — recovery temporarily disabled"
  defp short_circuit_flash(:target_refs_drift), do: "Target state changed since Preview — please re-Preview"

  # Server-side resolution of the capability's user-facing action name onto the
  # active preview map. CONTEXT D-09 forbids editing WorkbenchContract.find_active_preview/1,
  # so we augment the LiveView assigns just-in-time (RESEARCH Option B).
  defp load_detail(id) do
    id
    |> Parapet.Operator.incident_detail()
    |> augment_active_preview()
  end

  defp augment_active_preview(%{derived: %{active_preview: nil}} = detail), do: detail

  defp augment_active_preview(%{derived: %{active_preview: preview} = derived} = detail)
       when is_map(preview) do
    capability_id = Map.get(preview.data || %{}, "capability")
    enriched = Map.put(preview, :action_name, resolve_action_name(capability_id))
    %{detail | derived: %{derived | active_preview: enriched}}
  end

  defp augment_active_preview(detail), do: detail

  defp resolve_action_name(nil), do: nil

  defp resolve_action_name(capability_id) when is_binary(capability_id) do
    case safe_to_atom(capability_id) do
      nil -> nil
      atom -> resolve_action_name(atom)
    end
  end

  defp resolve_action_name(capability_id) when is_atom(capability_id) do
    case Parapet.Capabilities.get_recovery(capability_id) do
      %{name: name} -> name
      _ -> nil
    end
  end

  defp resolve_action_name(_), do: nil

  # Strings stored in preview payloads are produced via to_string(capability.id)
  # where capability.id is one of the 5 atoms in Parapet.Capabilities @valid_capabilities.
  # We only convert known capability id strings to atoms (never user input).
  defp safe_to_atom(string) when is_binary(string) do
    try do
      String.to_existing_atom(string)
    rescue
      ArgumentError -> nil
    end
  end

  defp safe_to_atom(_), do: nil

  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen bg-gray-50 md:hidden">
      <div class="p-4 bg-white border-b border-gray-200 sticky top-0 z-10">
        <.link navigate={"/parapet"} class="text-blue-600 hover:text-blue-800 flex items-center gap-2 mb-4">
          <span>&larr; Back to Queue</span>
        </.link>
        <.incident_summary detail={@incident} />
      </div>

      <div class="p-4 bg-white border-b border-gray-200">
        <h3 class="text-lg font-semibold mb-4">Timeline</h3>
        <.incident_timeline detail={@incident} />
      </div>

      <div class="p-4 bg-gray-50 pb-24">
        <.suspect_changes_card entries={Enum.filter(@incident.entries, &(&1.type == "rulestead_flag_change"))} />

        <%= if @incident.incident.state == "resolved" && is_map(@incident.incident.runbook_data) && Map.get(@incident.incident.runbook_data, "retrospective") do %>
          <div class="mb-6 p-4 border border-gray-200 rounded-lg bg-white shadow-sm">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-semibold">Automated Retrospective</h3>
              <button
                onclick="navigator.clipboard.writeText(this.dataset.content); alert('Copied to clipboard!')"
                data-content={@incident.incident.runbook_data["retrospective"]}
                class="px-3 py-1 bg-gray-100 hover:bg-gray-200 border border-gray-300 rounded text-sm text-gray-700 transition-colors"
                type="button"
              >
                Copy to Clipboard
              </button>
            </div>
            <pre class="bg-gray-800 text-gray-100 p-4 rounded text-sm overflow-x-auto whitespace-pre-wrap font-mono"><code><%= @incident.incident.runbook_data["retrospective"] %></code></pre>
          </div>
        <% end %>

        <%= if @incident.derived.runbook_steps != [] do %>
          <.runbook_card detail={@incident} />
        <% end %>

        <%= if @incident.derived.active_preview do %>
          <.preview_panel detail={@incident} />
        <% end %>

        <h3 class="text-lg font-semibold mb-4">Actions</h3>
        <.action_rail detail={@incident} />
      </div>
    </div>
    """
  end
end
