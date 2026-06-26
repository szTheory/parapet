defmodule DemoAppWeb.Parapet.OperatorDetailLive do
  @moduledoc false
  use DemoAppWeb, :live_view

  import DemoAppWeb.Parapet.OperatorComponents

  @default_operator_base_path "/parapet"

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(operator_base_path: @default_operator_base_path)
     |> assign_incident_detail(id)}
  end

  def handle_params(%{"id" => id}, uri, socket) do
    socket =
      socket
      |> assign(operator_base_path: operator_base_path(uri))
      |> assign_incident_detail(id)

    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action, socket.assigns))}
  end

  # Wires fetch_incident_detail/1 into the not-found-aware assigns. On {:ok, detail}
  # the page renders normally; on {:error, :not_found} it degrades to the in-page
  # not-found panel (no push_navigate) while keeping requested_id for the panel.
  defp assign_incident_detail(socket, id) do
    case Parapet.Operator.fetch_incident_detail(id) do
      {:ok, detail} ->
        assign(socket, incident: detail, incident_not_found: false, requested_id: id)

      {:error, :not_found} ->
        assign(socket, incident: nil, incident_not_found: true, requested_id: id)
    end
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
         |> put_flash(:info, "Incident acknowledged. Audit record and timeline entry written.")
         |> push_navigate(to: incident_detail_path(socket.assigns.operator_base_path, id))}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Acknowledge didn't complete — no audit record was written. The incident is unchanged; refresh the timeline, then retry."
         )}
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
        {:noreply,
         push_navigate(socket, to: incident_detail_path(socket.assigns.operator_base_path, id))}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Resolve didn't complete — the incident stays in its current state and no audit record was written. Refresh the timeline, then retry."
         )}
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
         |> refresh_incident_detail(id)}

      {:error, reason} ->
        require Logger
        Logger.error("trigger_next_escalation failed: #{inspect(reason)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           "Couldn't record the escalation request — no escalation was triggered. Refresh to confirm current status, then retry."
         )}
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
           |> refresh_incident_detail(id)}

        {:error, reason} ->
          require Logger
          Logger.error("suppress_pending_escalation failed: #{inspect(reason)}")

          {:noreply,
           put_flash(
             socket,
             :error,
             "Couldn't record the suppression — pending escalation is unchanged. Refresh current status, then retry."
           )}
      end
    else
      _ ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Suppression window must be a whole number of minutes greater than zero."
         )}
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
         |> refresh_incident_detail(incident_id)}

      {:error, reason} ->
        require Logger
        Logger.error("preview_runbook_step failed: #{inspect(reason)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           "Preview couldn't be generated — nothing has run and the incident is unchanged. Refresh the timeline, then retry."
         )}
    end
  end

  def handle_event(
        "confirm_mitigation",
        %{"step" => step, "incident_id" => incident_id, "token" => token},
        socket
      ) do
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
         |> refresh_incident_detail(incident_id)}

      {:short_circuited, reason} ->
        {level, message} = Parapet.Operator.UI.short_circuit_flash(reason)

        {:noreply,
         socket
         |> put_flash(level, message)
         |> refresh_incident_detail(incident_id)}

      {:conflicted, _claim_id} ->
        {:noreply,
         socket
         |> put_flash(
           :warning,
           "Another node is executing this recovery — refresh to see the outcome"
         )
         |> refresh_incident_detail(incident_id)}

      {:error, reason} ->
        require Logger
        Logger.error("confirm_runbook_step failed: #{inspect(reason)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           "Recovery did not execute — nothing was changed and no audit record was written. Refresh the timeline to confirm current state before retrying."
         )}

      # Forward-compatibility: a future additive return variant degrades to a
      # refresh instead of crashing this (possibly older) generated LiveView.
      other ->
        require Logger
        Logger.warning("Unhandled confirm_runbook_step/4 result: #{inspect(other)}")

        {:noreply,
         socket
         |> put_flash(:warning, "Recovery returned an unexpected result — refresh to review")
         |> refresh_incident_detail(incident_id)}
    end
  end

  def handle_event("cancel_preview", _params, socket) do
    # Simply refresh without an active preview in local state if we had one
    # Though it's derived from timeline, so we might need a "cancel" timeline event
    # For now, just a UI refresh
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.operator_theme_bootstrap />
    <div class="parapet-ui antialiased flex min-h-screen w-full max-w-full flex-col overflow-x-hidden bg-stone-100 text-stone-900">
      <a
        href="#parapet-main"
        class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 flex min-h-[40px] items-center rounded-lg px-4 py-2 text-sm font-semibold bg-[color:var(--parapet-panel)] text-[color:var(--parapet-accent)] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
      >
        Skip to main content
      </a>
      <.operator_nav active={detail_nav_active(@incident)} operator_base_path={@operator_base_path} />

      <nav aria-label="Incident context" class="border-b border-stone-200 bg-white px-4 py-3 md:px-6">
        <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <.link navigate={detail_back_path(@operator_base_path, @incident)} class="inline-flex min-h-[40px] items-center rounded-lg text-sm font-semibold underline decoration-stone-300 underline-offset-4 po-link">
            <span>&larr; <%= detail_back_label(@incident) %></span>
          </.link>
          <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500"><%= detail_context_label(@incident) %></p>
        </div>
      </nav>

      <%= if @incident_not_found do %>
        <main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
          <div class="mx-auto max-w-2xl">
            <.incident_not_found operator_base_path={@operator_base_path} requested_id={@requested_id} />
          </div>
        </main>
      <% else %>
        <main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8 scroll-pb-72 md:scroll-pb-0">
          <div class="mx-auto grid max-w-7xl gap-6 lg:grid-cols-[minmax(0,1fr)_22rem]">
            <section class="min-w-0 space-y-6">
              <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5 md:p-6">
                <.incident_summary detail={@incident} heading_level="h1" />
              </div>

              <section class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5 md:p-6" aria-label="Incident timeline">
                <h3 class="mb-4 text-lg font-semibold text-stone-950">Timeline</h3>
                <.incident_timeline detail={@incident} />
              </section>
            </section>

            <aside class="min-w-0 space-y-6" aria-label="Incident actions">
              <.suspect_changes_card entries={Enum.filter(@incident.entries, &(&1.type == "rulestead_flag_change"))} />

              <.retrospective_card detail={@incident} />

              <%= if @incident.derived.runbook_steps != [] do %>
                <.runbook_card detail={@incident} />
              <% end %>

              <%= if @incident.incident.state != "resolved" && @incident.derived.active_preview do %>
                <.preview_panel detail={@incident} />
              <% end %>

              <.action_rail detail={@incident} operator_base_path={@operator_base_path} />
            </aside>
          </div>
        </main>
      <% end %>
    </div>
    """
  end

  # Refreshes after a mutating action. If the incident vanished mid-action
  # (concurrent resolve/prune), degrade to the in-page not-found panel instead
  # of crashing — keeping the operator oriented (D-01/D-02).
  defp refresh_incident_detail(socket, id) do
    case Parapet.Operator.fetch_incident_detail(id) do
      {:ok, detail} ->
        assign(socket, incident: detail, incident_not_found: false, requested_id: id)

      {:error, :not_found} ->
        assign(socket, incident: nil, incident_not_found: true, requested_id: id)
    end
  end

  defp page_title(:show, %{incident: %{incident: %{title: title}}}) when is_binary(title),
    do: "Incident: #{title}"

  defp page_title(_action, _assigns), do: "Incident detail"

  defp detail_nav_active(%{incident: %{state: "resolved"}}), do: :history
  defp detail_nav_active(_incident), do: :response

  defp detail_back_path(operator_base_path, %{incident: %{state: "resolved"}}),
    do: operator_base_path <> "/history"

  defp detail_back_path(operator_base_path, _incident), do: operator_base_path

  defp incident_detail_path(operator_base_path, incident_id),
    do: operator_base_path <> "/incidents/#{incident_id}"

  defp operator_base_path(uri) when is_binary(uri) do
    uri
    |> URI.parse()
    |> Map.get(:path)
    |> operator_base_path_from_path()
  end

  defp operator_base_path(_uri), do: @default_operator_base_path

  defp operator_base_path_from_path(path) when is_binary(path) do
    segments = String.split(path, "/", trim: true)
    reversed_segments = Enum.reverse(segments)

    case Enum.find_index(reversed_segments, &(&1 == "parapet")) do
      nil ->
        @default_operator_base_path

      reverse_index ->
        keep_count = length(segments) - reverse_index

        case Enum.take(segments, keep_count) do
          [] -> @default_operator_base_path
          scoped_segments -> "/" <> Enum.join(scoped_segments, "/")
        end
    end
  end

  defp operator_base_path_from_path(_path), do: @default_operator_base_path

  defp detail_back_label(%{incident: %{state: "resolved"}}), do: "Back to history"
  defp detail_back_label(_incident), do: "Back to active response"

  defp detail_context_label(%{incident: %{state: "resolved"}}), do: "Resolved incident review"
  defp detail_context_label(_incident), do: "Active incident detail"
end
