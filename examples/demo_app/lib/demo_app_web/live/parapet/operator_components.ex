defmodule DemoAppWeb.Parapet.OperatorComponents do
  @moduledoc false
  use DemoAppWeb, :html

  attr :incidents, :list, required: true
  attr :selected, :map, default: nil
  attr :queue_params, :map, default: %{}
  def incident_list(assigns) do
    ~H"""
    <div class="divide-y divide-stone-200">
      <%= for incident <- @incidents do %>
        <.link
          patch={queue_item_path(@queue_params, incident)}
          aria-current={if @selected && @selected.id == incident.id, do: "true", else: "false"}
          class={[
            "block border-l-4 px-4 py-3 transition-colors",
            queue_row_class(@selected, incident)
          ]}
        >
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-2">
                <span class={["px-2 py-1 text-xs font-semibold rounded-full", state_color(incident.state)]}>
                  <%= incident.state %>
                </span>
                <%= if incident.severity do %>
                  <span class={["px-2 py-1 text-xs font-semibold rounded-full border", severity_color(incident.severity)]}>
                    <%= incident.severity %>
                  </span>
                <% end %>
                <%= if incident.attention_chip do %>
                  <span class="px-2 py-1 text-xs font-semibold rounded-full border border-amber-200 bg-amber-50 text-amber-900">
                    <%= incident.attention_chip %>
                  </span>
                <% end %>
              </div>
              <p class="mt-2 truncate text-sm font-semibold text-stone-900"><%= incident.title %></p>
              <%= if incident.secondary_line do %>
                <p class="mt-1 truncate text-sm text-stone-600"><%= incident.secondary_line %></p>
              <% end %>
            </div>
            <div class="shrink-0 text-right">
              <p class="text-xs font-medium uppercase tracking-wide text-stone-500">Updated</p>
              <p class="mt-1 text-sm text-stone-700"><%= incident.updated_at_label %></p>
            </div>
          </div>
        </.link>
      <% end %>

      <%= if Enum.empty?(@incidents) do %>
        <div class="px-4 py-6 text-center">
          <p class="text-sm font-semibold text-stone-800">No active incidents</p>
          <p class="mt-2 text-sm text-stone-500">
            Open and investigating incidents will appear here. Use History to review resolved incidents without disrupting the active queue.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  attr :detail, :map, required: true
  def incident_summary(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-start mb-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900"><%= @detail.incident.title %></h1>
          <p class="text-sm text-gray-500 mt-1"><%= @detail.incident.id %></p>
        </div>
        <span class={["px-3 py-1 text-sm font-medium rounded-full", state_color(@detail.incident.state)]}>
          <%= @detail.incident.state %>
        </span>
      </div>

      <div class="bg-blue-50 p-4 rounded-md mb-6">
        <h4 class="text-sm font-medium text-blue-900 mb-2">Impact Summary</h4>
        <p class="text-sm text-blue-800">
          <%= @detail.derived.impact || "No impact summary recorded." %>
        </p>
      </div>

      <div class="border border-amber-200 bg-amber-50 rounded-lg p-4 mb-6">
        <div class="flex items-start justify-between gap-3 mb-3">
          <div>
            <h4 class="text-sm font-semibold text-amber-950">Escalation Status</h4>
            <p class="text-sm text-amber-900 mt-1">
              <%= escalation_status_copy(@detail.escalation_summary.status) %>
            </p>
          </div>
          <span class="px-2.5 py-1 text-xs font-semibold rounded-full border border-amber-300 bg-white text-amber-900">
            <%= escalation_status_badge(@detail.escalation_summary.status) %>
          </span>
        </div>

        <dl class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
          <%= if @detail.escalation_summary.escalation_chain do %>
            <div class="rounded-md border border-amber-100 bg-white/80 p-3 sm:col-span-2">
              <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Escalation Chain</dt>
              <dd class="mt-2">
                <ol class="grid grid-cols-1 gap-2 md:grid-cols-2">
                  <%= for step <- @detail.escalation_summary.escalation_chain do %>
                    <li class="flex items-center justify-between rounded-md border border-amber-100 bg-amber-50/60 px-3 py-2">
                      <div>
                        <p class="text-sm font-medium text-amber-950"><%= step.label %></p>
                        <%= if step.delay do %>
                          <p class="text-xs text-amber-800 mt-0.5">After <%= step.delay %></p>
                        <% end %>
                      </div>
                      <span class={["px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide rounded-full border", escalation_chain_status_class(step.status)]}>
                        <%= escalation_chain_status_copy(step.status) %>
                      </span>
                    </li>
                  <% end %>
                </ol>
              </dd>
            </div>
          <% end %>
          <%= if @detail.escalation_summary.time_until_next_escalation do %>
            <div class="rounded-md border border-amber-100 bg-white/80 p-3 sm:col-span-2">
              <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Time Until Next Escalation</dt>
              <dd class="mt-1 text-amber-950"><%= countdown_copy(@detail.escalation_summary.time_until_next_escalation) %></dd>
            </div>
          <% end %>
          <div class="rounded-md border border-amber-100 bg-white/80 p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Next Step</dt>
            <dd class="mt-1 text-amber-950"><%= escalation_next_step_copy(@detail.escalation_summary.next_step) %></dd>
          </div>
          <div class="rounded-md border border-amber-100 bg-white/80 p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">System Action</dt>
            <dd class="mt-1 text-amber-950"><%= system_action_copy(@detail.escalation_summary.system_action) %></dd>
          </div>
          <div class="rounded-md border border-amber-100 bg-white/80 p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Suppression</dt>
            <dd class="mt-1 text-amber-950"><%= suppression_copy(@detail.escalation_summary.suppression) %></dd>
          </div>
          <div class="rounded-md border border-amber-100 bg-white/80 p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Latest Evidence</dt>
            <dd class="mt-1 text-amber-950"><%= latest_event_copy(@detail.escalation_summary.latest_event) %></dd>
          </div>
        </dl>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div class="border border-gray-200 rounded-md p-4">
          <h4 class="text-sm font-medium text-gray-700 mb-2">Top Facts</h4>
          <ul class="text-sm text-gray-600 list-disc pl-5">
            <li>Created at <%= @detail.incident.inserted_at %></li>
            <%= if @detail.derived.fault_plane do %>
              <li>Likely fault plane: <%= @detail.derived.fault_plane %></li>
            <% end %>
            <%= if @detail.derived.next_safe_action do %>
              <li>Next safe action: <%= @detail.derived.next_safe_action %></li>
            <% end %>
          </ul>
        </div>
        <div class="border border-gray-200 rounded-md p-4">
          <h4 class="text-sm font-medium text-gray-700 mb-2">Observability</h4>
          <div class="flex flex-col gap-2">
            <%= if trace_id = Map.get(@detail.incident, :trace_id) do %>
              <% template = Application.get_env(:parapet, :trace_url_template) || "#" %>
              <% url = if is_binary(template), do: String.replace(template, "{trace_id}", trace_id), else: "#" %>
              <a href={url} class="text-sm text-indigo-700 hover:underline flex items-center gap-1" target="_blank" rel="noopener noreferrer">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                <span>Trace: <%= trace_id %></span> &nearr;
              </a>
            <% end %>
            <%= for link <- @detail.external_links do %>
              <a href={external_link_url(link)} class="text-sm text-blue-600 hover:underline flex items-center gap-1" target="_blank" rel="noopener noreferrer">
                <span><%= external_link_label(link) %></span> &nearr;
              </a>
            <% end %>
            <%= if Enum.empty?(@detail.external_links) && is_nil(Map.get(@detail.incident, :trace_id)) do %>
              <span class="text-sm text-gray-500">No external links attached.</span>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :detail, :map, required: true
  def incident_timeline(assigns) do
    ~H"""
    <div class="flow-root">
      <ul role="list" class="-mb-8">
        <% timeline_entries = @detail.timeline_entries || Enum.map(@detail.entries, fn entry -> %{entry: entry, presentation: %{actor_class: :evidence, style_variant: :neutral_evidence, system_action?: false}} end) %>
        <%= for item <- timeline_entries do %>
          <% entry = item.entry %>
          <% presentation = item.presentation %>
          <li>
            <div class="relative pb-8">
              <span class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
              <div class="relative flex space-x-3">
                <div>
                  <span class={["h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white text-white text-[11px] font-semibold", timeline_entry_badge_class(presentation)]}>
                    <%= timeline_entry_badge_text(presentation) %>
                  </span>
                </div>
                <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                  <div>
                    <div class="flex items-center gap-2 flex-wrap">
                      <p class="text-sm font-medium text-gray-900"><%= timeline_entry_title(entry, presentation) %></p>
                      <span class={["px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide rounded-full border", timeline_entry_actor_class(presentation)]}>
                        <%= timeline_actor_copy(presentation.actor_class) %>
                      </span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">
                      <%= timeline_entry_body(entry, presentation) %>
                    </p>
                  </div>
                  <div class="whitespace-nowrap text-right text-sm text-gray-500">
                    <time datetime={entry.inserted_at}><%= entry.inserted_at %></time>
                  </div>
                </div>
              </div>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr :entries, :list, required: true
  def suspect_changes_card(assigns) do
    ~H"""
    <%= if not Enum.empty?(@entries) do %>
      <div class="bg-blue-50 border border-blue-200 rounded-md p-4 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-3">Recent System Changes (&plusmn; 60 mins)</h3>
        <div class="flex flex-col gap-3">
          <%= for entry <- @entries do %>
            <% actor = Map.get(entry.payload, "actor") || Map.get(entry.payload, :actor) || "System" %>
            <% flag = Map.get(entry.payload, "flag") || Map.get(entry.payload, :flag) %>
            <% scope = Map.get(entry.payload, "scope") || Map.get(entry.payload, :scope) %>
            <div class="flex justify-between items-start bg-white border border-blue-100 rounded p-3 shadow-sm">
              <div class="flex items-start gap-3">
                <div class="mt-0.5">
                  <span class="h-6 w-6 rounded-full bg-purple-100 text-purple-800 flex items-center justify-center text-xs font-bold ring-2 ring-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd" />
                    </svg>
                  </span>
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900">
                    Flag <span class="font-mono text-xs bg-gray-100 px-1 rounded border border-gray-200"><%= flag %></span> updated
                  </p>
                  <p class="text-xs text-gray-500 mt-0.5">
                    <%= actor %> published ruleset
                  </p>
                </div>
              </div>
              <div class="flex flex-col items-end gap-1">
                <span class="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800 border border-blue-200">
                  <%= inspect(scope) %>
                </span>
                <time datetime={entry.inserted_at} class="text-xs text-gray-500"><%= entry.inserted_at %></time>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  attr :detail, :map, required: true
  def runbook_card(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-md p-4 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-1">
        <%= @detail.derived.runbook_title || "Runbook" %>
      </h3>
      <p class="text-sm text-gray-600 mb-4">
        <%= @detail.derived.runbook_description || "No description provided." %>
      </p>

      <div class="flex flex-col gap-3">
        <%= for step <- @detail.derived.runbook_steps do %>
          <div class="border border-gray-100 bg-gray-50 rounded p-3">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <h4 class="text-sm font-medium text-gray-900"><%= step.label %></h4>
                  <%= if step.state == :executed do %>
                    <span class="px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider rounded bg-green-100 text-green-700 border border-green-200">Executed</span>
                  <% end %>
                </div>
                <p class="text-xs text-gray-500 mt-1"><%= step.description %></p>

                <%= if step.state == :guidance && step.guidance do %>
                  <div class="mt-2 p-2 bg-blue-50 border border-blue-100 rounded text-xs text-blue-800 italic">
                    <%= step.guidance %>
                  </div>
                <% end %>

                <%= if step.warning do %>
                  <div class="mt-2 p-2 bg-amber-50 border border-amber-100 rounded text-xs text-amber-800">
                    <%= step.warning %>
                  </div>
                <% end %>

                <%= if length(step.targeting_hints) > 0 do %>
                  <div class="mt-2 flex flex-wrap gap-1">
                    <%= for hint <- step.targeting_hints do %>
                      <span class="px-1.5 py-0.5 text-[10px] font-mono rounded bg-purple-50 text-purple-700 border border-purple-100" title={hint.title}>
                        <%= hint.kind %>:<%= String.slice(to_string(hint.external_id), 0..7) %>
                      </span>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <div class="ml-4">
                <%= case step.state do %>
                  <% :previewable -> %>
                    <button phx-click="preview_mitigation" phx-value-step={step.id} phx-value-incident_id={@detail.incident.id} class="bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-1.5 px-3 rounded text-xs transition-colors">
                      Preview
                    </button>
                  <% :executable -> %>
                     <button phx-click="preview_mitigation" phx-value-step={step.id} phx-value-incident_id={@detail.incident.id} class="bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-1.5 px-3 rounded text-xs transition-colors">
                      Execute
                    </button>
                  <% :executed -> %>
                    <div class="text-[10px] text-gray-400 text-right">
                      <%!-- show time if available --%>
                    </div>
                  <% _ -> %>
                  <%!-- No button for guidance --%>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :detail, :map, required: true
  def preview_panel(assigns) do
    ~H"""
    <% preview = @detail.derived.active_preview %>
    <div class="fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
      <div class="bg-white border-2 border-indigo-500 rounded-lg shadow-xl overflow-hidden">
        <div class="bg-indigo-500 px-4 py-2 flex justify-between items-center">
          <h3 class="text-sm font-bold text-white uppercase tracking-wider">Recovery Preview</h3>
          <button phx-click="cancel_preview" class="text-white hover:text-indigo-100">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div class="p-4">
          <div class="grid grid-cols-2 gap-4 mb-4">
            <div>
              <p class="text-[10px] text-gray-500 uppercase font-bold">Target Kind</p>
              <p class="text-sm font-medium text-gray-900"><%= preview.data["target_kind"] %></p>
            </div>
            <div>
              <p class="text-[10px] text-gray-500 uppercase font-bold">Affected Count</p>
              <p class="text-sm font-medium text-gray-900"><%= preview.data["count"] %></p>
            </div>
          </div>

          <%= if (preview.data["warnings"] || []) != [] do %>
            <div class="mb-4 p-2 bg-red-50 border border-red-100 rounded">
              <p class="text-[10px] text-red-700 uppercase font-bold mb-1">Warnings</p>
              <ul class="text-xs text-red-600 list-disc pl-4">
                <%= for w <- preview.data["warnings"] do %>
                  <li><%= w %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <%= if preview.data["idempotency_caveats"] do %>
            <div class="mb-4">
              <p class="text-[10px] text-gray-500 uppercase font-bold mb-1">Idempotency</p>
              <p class="text-xs text-gray-600"><%= preview.data["idempotency_caveats"] %></p>
            </div>
          <% end %>

          <div class="flex gap-2">
            <button
              phx-click="confirm_mitigation"
              phx-value-step={preview.step_id}
              phx-value-incident_id={@detail.incident.id}
              phx-value-token={preview.preview_token}
              class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded text-sm shadow-md transition-all active:scale-95"
            >
              Confirm Recovery
            </button>
          </div>
          <p class="text-[10px] text-center text-gray-400 mt-2 italic">
            Preview is active.
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :detail, :map, required: true
  def action_rail(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <%= if @detail.incident.state == "open" do %>
        <div class="bg-white border border-gray-200 rounded-md p-4">
          <h4 class="text-sm font-medium text-gray-900 mb-2">Acknowledge</h4>
          <p class="text-xs text-gray-500 mb-3">Take ownership of this incident.</p>
          <button phx-click="acknowledge" phx-value-id={@detail.incident.id} class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded text-sm transition-colors">
            Acknowledge Incident
          </button>
        </div>
      <% end %>

      <div class="bg-white border border-gray-200 rounded-md p-4">
        <h4 class="text-sm font-medium text-gray-900 mb-2">Escalation Controls</h4>
        <p class="text-xs text-gray-500 mb-3">Use bounded controls only after reviewing current status and the canonical timeline.</p>
        <%= if escalation_controls_enabled?(@detail.incident) do %>
          <button phx-click="trigger_next_escalation" phx-value-id={@detail.incident.id} class="w-full bg-amber-600 hover:bg-amber-700 text-white font-medium py-2 px-4 rounded text-sm transition-colors mb-2">
            Trigger Next Escalation
          </button>
          <button phx-click="suppress_pending_escalation" phx-value-id={@detail.incident.id} phx-value-minutes="30" class="w-full bg-white border border-amber-300 hover:bg-amber-50 text-amber-900 font-medium py-2 px-4 rounded text-sm transition-colors">
            Suppress Pending Escalation
          </button>
        <% else %>
          <p class="text-sm text-gray-600">Escalation controls are available only while the incident is open.</p>
        <% end %>
      </div>

      <div class="bg-white border border-gray-200 rounded-md p-4">
        <h4 class="text-sm font-medium text-gray-900 mb-2">Resolve</h4>
        <p class="text-xs text-gray-500 mb-3">Mark incident as resolved.</p>
        <button phx-click="resolve" phx-value-id={@detail.incident.id} class="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded text-sm transition-colors">
          Resolve Incident
        </button>
      </div>
    </div>
    """
  end

  attr :items, :list, required: true
  def action_item_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <%= for item <- @items do %>
        <.action_item_card item={item} />
      <% end %>
      <%= if Enum.empty?(@items) do %>
        <p class="text-sm text-gray-500 italic">No action items pending.</p>
      <% end %>
    </div>
    """
  end

  attr :item, :map, required: true
  def action_item_card(assigns) do
    resolver = Application.get_env(:parapet, :scoria)[:ui_url_resolver]
    url = case resolver do
      {mod, fun, args} -> apply(mod, fun, args ++ [assigns.item.external_id])
      _ -> nil
    end

    assigns = assign(assigns, :url, url)

    ~H"""
    <div class="bg-white border border-gray-200 rounded-md p-4">
      <div class="flex justify-between items-start mb-2">
        <h4 class="text-sm font-medium text-gray-900"><%= @item.title || "Action Item" %></h4>
        <span class="px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">
          <%= @item.state %>
        </span>
      </div>
      <p class="text-xs text-gray-500 mb-3"><%= @item.integration %>:<%= @item.external_id %></p>
      <%= if @url do %>
        <a href={@url} target="_blank" rel="noopener noreferrer" class="w-full block text-center bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2 px-4 rounded text-sm transition-colors">
          Review in UI &nearr;
        </a>
      <% else %>
        <div class="text-xs text-gray-500 text-center py-2 border border-dashed border-gray-300 rounded">No resolver configured</div>
      <% end %>
    </div>
    """
  end

  attr :journeys, :list, required: true
  def critical_journeys(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-md p-4 mb-4">
      <h3 class="text-sm font-semibold text-gray-700 uppercase tracking-wider mb-3">Critical Journeys</h3>
      <div class="flex flex-col gap-2">
        <%= for journey <- @journeys do %>
          <div class="flex items-center justify-between p-2 rounded bg-gray-50 border border-gray-100">
            <span class="text-sm font-medium text-gray-800"><%= journey.name %></span>
            <span class={["px-2 py-0.5 text-xs font-medium rounded-full", journey_color(journey.status)]}>
              <%= journey.status %>
            </span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp journey_color(:healthy), do: "bg-green-100 text-green-800"
  defp journey_color(:degraded), do: "bg-yellow-100 text-yellow-800"
  defp journey_color(:down), do: "bg-red-100 text-red-800"
  defp journey_color(_), do: "bg-gray-100 text-gray-800"

  defp queue_item_path(queue_params, incident) do
    params =
      queue_params
      |> Map.merge(%{"id" => incident.id})
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == "active" end)

    case params do
      [] -> "/parapet"
      _ -> "/parapet?" <> URI.encode_query(params)
    end
  end

  defp queue_row_class(selected, incident) do
    if selected && selected.id == incident.id do
      "border-l-teal-700 bg-teal-50/80 hover:bg-teal-50"
    else
      "border-l-transparent bg-stone-50/40 hover:bg-stone-100"
    end
  end

  defp state_color("open"), do: "bg-red-100 text-red-800"
  defp state_color("acknowledged"), do: "bg-yellow-100 text-yellow-800"
  defp state_color("resolved"), do: "bg-green-100 text-green-800"
  defp state_color(_), do: "bg-gray-100 text-gray-800"

  defp severity_color("critical"), do: "border-rose-200 bg-rose-50 text-rose-900"
  defp severity_color("high"), do: "border-orange-200 bg-orange-50 text-orange-900"
  defp severity_color("medium"), do: "border-amber-200 bg-amber-50 text-amber-900"
  defp severity_color("low"), do: "border-emerald-200 bg-emerald-50 text-emerald-900"
  defp severity_color(_), do: "border-stone-200 bg-stone-100 text-stone-700"

  defp escalation_status_copy(:suppressed), do: "Pending escalation is durably suppressed until the recorded window expires."
  defp escalation_status_copy(:manual_trigger_requested), do: "An operator requested the next escalation and the worker has not written the outcome yet."
  defp escalation_status_copy(:recently_executed), do: "The system recently executed an escalation step and recorded the result in the timeline."
  defp escalation_status_copy(:recently_short_circuited), do: "The latest escalation attempt was safely short-circuited and logged."
  defp escalation_status_copy(_), do: "No active escalation override is recorded. Continue from the latest durable evidence."

  defp escalation_status_badge(:suppressed), do: "Suppressed"
  defp escalation_status_badge(:manual_trigger_requested), do: "Requested"
  defp escalation_status_badge(:recently_executed), do: "Executed"
  defp escalation_status_badge(:recently_short_circuited), do: "Short-Circuited"
  defp escalation_status_badge(_), do: "Idle"

  defp escalation_next_step_copy(%{kind: :await_suppression_expiry, at: %DateTime{} = at}),
    do: "Wait for suppression to expire at #{at}."

  defp escalation_next_step_copy(%{kind: :await_worker_execution, at: %DateTime{} = at}),
    do: "Await worker execution for the pending escalation request recorded at #{at}."

  defp escalation_next_step_copy(%{kind: :await_next_escalation, at: %DateTime{} = at}),
    do: "Await the next scheduled escalation step at #{at}."

  defp escalation_next_step_copy(%{kind: :monitor_timeline, at: %DateTime{} = at}),
    do: "Monitor the canonical timeline. Latest escalation evidence landed at #{at}."

  defp escalation_next_step_copy(_), do: "Monitor the canonical timeline for the next durable escalation event."

  defp system_action_copy(%{status: :executed, at: %DateTime{} = at, mode: mode}),
    do: "System action executed at #{at}#{if(mode, do: " via #{mode}", else: "")}."

  defp system_action_copy(%{status: :short_circuited, at: %DateTime{} = at}),
    do: "System execution was short-circuited at #{at}."

  defp system_action_copy(_), do: "No recent system action is recorded."

  defp suppression_copy(%{active?: true, until: %DateTime{} = until, actor: actor, reason: reason}) do
    "#{actor || "Operator"} suppressed pending escalation until #{until}. #{reason || "No reason recorded."}"
  end

  defp suppression_copy(_), do: "No active suppression window is recorded."

  defp latest_event_copy(%{type: type, at: %DateTime{} = at, actor_class: actor_class}),
    do: "#{type} at #{at} (#{timeline_actor_copy(actor_class)})."

  defp latest_event_copy(_), do: "No escalation event has been recorded yet."

  defp countdown_copy(%{seconds: seconds, at: %DateTime{} = at}) when is_integer(seconds) and seconds > 0 do
    "Approximately #{humanize_seconds(seconds)} until the next escalation checkpoint (#{at})."
  end

  defp countdown_copy(_), do: "No countdown is currently available from durable evidence."

  defp external_link_label(%{"label" => label, "url" => url}) when is_binary(label) and is_binary(url), do: label
  defp external_link_label(%{label: label, url: url}) when is_binary(label) and is_binary(url), do: label
  defp external_link_label(%{"url" => url}) when is_binary(url), do: url
  defp external_link_label(%{url: url}) when is_binary(url), do: url
  defp external_link_label(link) when is_binary(link), do: link
  defp external_link_label(link), do: inspect(link)

  defp external_link_url(%{"url" => url}) when is_binary(url), do: url
  defp external_link_url(%{url: url}) when is_binary(url), do: url
  defp external_link_url(link) when is_binary(link), do: link
  defp external_link_url(_), do: "#"

  defp timeline_entry_badge_class(%{actor_class: :system}), do: "bg-amber-600"
  defp timeline_entry_badge_class(%{actor_class: :operator}), do: "bg-blue-600"
  defp timeline_entry_badge_class(%{actor_class: :copilot}), do: "bg-violet-600"
  defp timeline_entry_badge_class(%{actor_class: :external}), do: "bg-slate-600"
  defp timeline_entry_badge_class(_), do: "bg-gray-500"

  defp timeline_entry_badge_text(%{actor_class: :system}), do: "SYS"
  defp timeline_entry_badge_text(%{actor_class: :operator}), do: "OP"
  defp timeline_entry_badge_text(%{actor_class: :copilot}), do: "AI"
  defp timeline_entry_badge_text(%{actor_class: :external}), do: "EXT"
  defp timeline_entry_badge_text(_), do: "EV"

  defp timeline_entry_actor_class(%{actor_class: :system}), do: "bg-amber-100 text-amber-900 border-amber-200"
  defp timeline_entry_actor_class(%{actor_class: :operator}), do: "bg-blue-100 text-blue-900 border-blue-200"
  defp timeline_entry_actor_class(%{actor_class: :copilot}), do: "bg-violet-100 text-violet-900 border-violet-200"
  defp timeline_entry_actor_class(%{actor_class: :external}), do: "bg-slate-100 text-slate-900 border-slate-200"
  defp timeline_entry_actor_class(_), do: "bg-gray-100 text-gray-900 border-gray-200"

  defp timeline_actor_copy(:system), do: "System"
  defp timeline_actor_copy(:operator), do: "Operator"
  defp timeline_actor_copy(:copilot), do: "Copilot"
  defp timeline_actor_copy(:external), do: "External"
  defp timeline_actor_copy(_), do: "Evidence"

  defp escalation_chain_status_copy(:completed), do: "Complete"
  defp escalation_chain_status_copy(:current), do: "Current"
  defp escalation_chain_status_copy(_), do: "Pending"

  defp escalation_chain_status_class(:completed),
    do: "bg-green-100 text-green-900 border-green-200"

  defp escalation_chain_status_class(:current),
    do: "bg-amber-100 text-amber-900 border-amber-200"

  defp escalation_chain_status_class(_),
    do: "bg-gray-100 text-gray-900 border-gray-200"

  defp escalation_controls_enabled?(%{state: "open"}), do: true
  defp escalation_controls_enabled?(_incident), do: false

  defp timeline_entry_title(%{type: "mitigation_executed"}, _presentation), do: "Runbook mitigation executed"
  defp timeline_entry_title(%{type: "escalation_trigger_requested"}, _presentation), do: "Escalation requested"
  defp timeline_entry_title(%{type: "escalation_suppressed"}, _presentation), do: "Escalation suppressed"
  defp timeline_entry_title(%{type: "escalation_executed"}, _presentation), do: "Escalation executed"
  defp timeline_entry_title(%{type: "escalation_short_circuited"}, _presentation), do: "Escalation short-circuited"
  defp timeline_entry_title(%{type: "rulestead_flag_change"}, _presentation), do: "Feature flag changed"
  defp timeline_entry_title(%{type: "note"}, _presentation), do: "Operator note"
  defp timeline_entry_title(%{type: "status_change"}, _presentation), do: "Incident status changed"
  defp timeline_entry_title(%{type: "external_link"}, _presentation), do: "External evidence attached"
  defp timeline_entry_title(%{type: type}, _presentation), do: humanize_type(type)

  defp timeline_entry_body(%{type: "mitigation_executed", payload: payload}, presentation) do
    actor = payload_value(payload, "actor") || timeline_actor_copy(presentation.actor_class)
    step_id = payload_value(payload, "step_id") || "unknown-step"
    "#{actor} executed mitigation step #{step_id}."
  end

  defp timeline_entry_body(%{type: "escalation_trigger_requested", payload: payload}, _presentation) do
    actor = payload_value(payload, "actor") || "Operator"
    reason = payload_value(payload, "reason") || "No reason recorded."
    "#{actor} requested the next escalation. #{reason}"
  end

  defp timeline_entry_body(%{type: "escalation_suppressed", payload: payload}, _presentation) do
    actor = payload_value(payload, "actor") || "Operator"
    reason = payload_value(payload, "reason") || "No reason recorded."
    suppressed_until = payload_value(payload, "suppressed_until")
    "#{actor} suppressed pending escalation until #{suppressed_until}. #{reason}"
  end

  defp timeline_entry_body(%{type: "escalation_executed", payload: payload}, _presentation) do
    mode = payload_value(payload, "mode") || "scheduled"
    policy = payload_value(payload, "policy")
    "Escalation executed via #{mode}#{if(policy, do: " using #{policy}", else: "")}."
  end

  defp timeline_entry_body(%{type: "escalation_short_circuited", payload: payload}, _presentation) do
    reason = payload_value(payload, "reason") || "no bounded reason recorded"
    "Escalation was short-circuited because #{reason}."
  end

  defp timeline_entry_body(%{type: "rulestead_flag_change", payload: payload}, _presentation) do
    actor = payload_value(payload, "actor") || "System"
    flag = payload_value(payload, "flag") || "unknown"
    scope = payload_value(payload, "scope")
    "#{actor} changed flag #{flag}#{if(scope, do: " in scope #{inspect(scope)}", else: "")}."
  end

  defp timeline_entry_body(%{type: "note", payload: payload}, _presentation),
    do: payload_value(payload, "text") || "No note text recorded."

  defp timeline_entry_body(%{type: "status_change", payload: payload}, _presentation) do
    "Incident moved to #{payload_value(payload, "new_state") || "an updated state"}."
  end

  defp timeline_entry_body(%{type: "external_link", payload: payload}, _presentation) do
    label = external_link_label(payload)
    url = external_link_url(payload)
    "#{label}: #{url}"
  end

  defp timeline_entry_body(%{type: type}, _presentation),
    do: "#{humanize_type(type)} was recorded as durable evidence."

  defp payload_value(payload, key) when is_map(payload), do: Map.get(payload, key) || Map.get(payload, String.to_atom(key))
  defp payload_value(_payload, _key), do: nil

  defp humanize_type(type) when is_binary(type) do
    type
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize_seconds(seconds) when seconds < 60, do: "#{seconds}s"
  defp humanize_seconds(seconds) when seconds < 3_600, do: "#{div(seconds, 60)}m"
  defp humanize_seconds(seconds), do: "#{div(seconds, 3_600)}h #{div(rem(seconds, 3_600), 60)}m"
end
