defmodule TestWeb do
  def live_view do
    quote do
      use Phoenix.LiveView, layout: false
      import Phoenix.Component
      import Phoenix.LiveView
      import Phoenix.LiveView.Helpers
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.LiveView.Helpers
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule Test.Repo do
  use Agent

  alias Parapet.Operator.WorkbenchContract
  alias Parapet.Spine.{ActionItem, Incident, TimelineEntry, ToolAudit}

  def start_link(_opts) do
    Agent.start_link(fn -> %{incidents: [], entries: %{}, action_items: []} end, name: __MODULE__)
  end

  def seed!(attrs) do
    Agent.update(__MODULE__, fn _state ->
      %{
        incidents: Map.fetch!(attrs, :incidents) |> Enum.map(&enrich_incident/1),
        entries: Map.get(attrs, :entries, %{}),
        action_items: Map.get(attrs, :action_items, [])
      }
    end)
  end

  def all(%Ecto.Query{from: %{source: {_, Incident}}} = query) do
    query
    |> inspect()
    |> then(fn query_text ->
      resolved_query? = resolved_query?(query)

      Agent.get(__MODULE__, fn state ->
        incidents =
          state.incidents
          |> filter_incidents(query_text, resolved_query?)
          |> apply_cursor(query_text)
          |> apply_order(query_text)
          |> Enum.take(limit_from(query_text))

        if resolved_query? do
          Enum.map(incidents, &WorkbenchContract.queue_row/1)
        else
          incidents
        end
      end)
    end)
  end

  def all(%Ecto.Query{from: %{source: {_, TimelineEntry}}, wheres: wheres}) do
    incident_id = timeline_incident_id(wheres)

    Agent.get(__MODULE__, fn state ->
      Map.get(state.entries, incident_id, [])
    end)
  end

  def all(%Ecto.Query{from: %{source: {_, ActionItem}}}) do
    Agent.get(__MODULE__, & &1.action_items)
  end

  def get!(Incident, incident_id) do
    Agent.get(__MODULE__, fn state ->
      Enum.find(state.incidents, &(&1.id == incident_id)) ||
        raise "missing incident #{incident_id}"
    end)
  end

  def insert(changeset, _opts \\ []) do
    if changeset.valid? do
      struct =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> ensure_id()

      persist_insert(struct)
      {:ok, struct}
    else
      {:error, changeset}
    end
  end

  def update(changeset, _opts \\ []) do
    if changeset.valid? do
      struct =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> enrich_incident()

      Agent.update(__MODULE__, fn state ->
        %{state | incidents: replace_incident(state.incidents, struct)}
      end)

      {:ok, struct}
    else
      {:error, changeset}
    end
  end

  def transaction(%Ecto.Multi{} = multi) do
    multi
    |> Ecto.Multi.to_list()
    |> Enum.reduce_while({:ok, %{}}, fn operation, {:ok, acc} ->
      case execute_multi_op(operation, acc) do
        {:ok, name, result} -> {:cont, {:ok, Map.put(acc, name, result)}}
        {:error, name, reason} -> {:halt, {:error, name, reason, acc}}
      end
    end)
  end

  defp timeline_incident_id([%{params: [{incident_id, _}]}, _]), do: incident_id
  defp timeline_incident_id([%{params: [{incident_id, _}]}]), do: incident_id

  defp filter_incidents(incidents, query_text, resolved_query?) do
    cond do
      resolved_query? ->
        Enum.filter(incidents, &(&1.state == "resolved"))

      String.contains?(query_text, "state in ^[\"open\", \"investigating\"]") ->
        Enum.filter(incidents, &(&1.state in ["open", "investigating"]))

      true ->
        incidents
    end
  end

  defp apply_order(incidents, query_text) do
    sorter =
      if query_text =~ "order_by: [asc: i0.updated_at, asc: i0.id]" do
        :asc
      else
        :desc
      end

    Enum.sort_by(incidents, &{&1.updated_at, &1.id}, sorter)
  end

  defp apply_cursor(incidents, query_text) do
    cond do
      String.contains?(query_text, "updated_at < ^~U[") ->
        {updated_at, incident_id} = extract_cursor(query_text, "<")

        Enum.filter(incidents, fn incident ->
          DateTime.compare(incident.updated_at, updated_at) == :lt or
            (DateTime.compare(incident.updated_at, updated_at) == :eq and
               incident.id < incident_id)
        end)

      String.contains?(query_text, "updated_at > ^~U[") ->
        {updated_at, incident_id} = extract_cursor(query_text, ">")

        Enum.filter(incidents, fn incident ->
          DateTime.compare(incident.updated_at, updated_at) == :gt or
            (DateTime.compare(incident.updated_at, updated_at) == :eq and
               incident.id > incident_id)
        end)

      true ->
        incidents
    end
  end

  defp extract_cursor(query_text, operator) do
    regex =
      ~r/updated_at #{Regex.escape(operator)} \^~U\[(?<updated_at>[^\]]+)\].*i0\.id #{Regex.escape(operator)} \^"(?<incident_id>[^"]+)"/s

    %{"updated_at" => updated_at, "incident_id" => incident_id} =
      Regex.named_captures(regex, query_text)

    {:ok, parsed, 0} = DateTime.from_iso8601(updated_at)
    {parsed, incident_id}
  end

  defp limit_from(query_text) do
    cond do
      captures = Regex.named_captures(~r/limit: \^(?<page_size>\d+) \+ 1/, query_text) ->
        String.to_integer(captures["page_size"]) + 1

      captures = Regex.named_captures(~r/limit: \^(?<limit>\d+)/, query_text) ->
        String.to_integer(captures["limit"])

      true ->
        31
    end
  end

  defp resolved_query?(%Ecto.Query{wheres: wheres}) do
    Enum.any?(wheres, fn %{params: params} ->
      Enum.any?(params, fn
        {"resolved", _meta} -> true
        _other -> false
      end)
    end)
  end

  defp execute_multi_op({name, {:update, changeset, _opts}}, _acc) do
    case update(changeset) do
      {:ok, struct} -> {:ok, name, struct}
      {:error, changeset} -> {:error, name, changeset}
    end
  end

  defp execute_multi_op({name, {:insert, changeset_or_fun, _opts}}, acc) do
    changeset =
      if is_function(changeset_or_fun, 1),
        do: changeset_or_fun.(acc),
        else: changeset_or_fun

    case insert(changeset) do
      {:ok, struct} -> {:ok, name, struct}
      {:error, changeset} -> {:error, name, changeset}
    end
  end

  defp execute_multi_op({name, {:run, fun}}, acc) do
    case fun.(__MODULE__, acc) do
      {:ok, result} -> {:ok, name, result}
      {:error, reason} -> {:error, name, reason}
    end
  end

  defp ensure_id(%{id: nil} = struct), do: %{struct | id: Ecto.UUID.generate()}
  defp ensure_id(struct), do: struct

  defp persist_insert(%TimelineEntry{} = entry) do
    Agent.update(__MODULE__, fn state ->
      updated_entries = Map.update(state.entries, entry.incident_id, [entry], &[entry | &1])
      %{state | entries: updated_entries}
    end)
  end

  defp persist_insert(%ToolAudit{}), do: :ok
  defp persist_insert(_struct), do: :ok

  defp enrich_incident(%Incident{} = incident) do
    incident
    |> Map.merge(WorkbenchContract.queue_row(incident))
    |> Map.put(:incident_id, incident.id)
  end

  defp enrich_incident(other), do: other

  defp replace_incident(incidents, updated_incident) do
    Enum.map(incidents, fn incident ->
      if incident.id == updated_incident.id, do: updated_incident, else: incident
    end)
  end
end

defmodule Parapet.GeneratedOperatorLivePagingTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Ui
  alias Phoenix.LiveView.{Lifecycle, Utils}
  alias Parapet.Spine.{Incident, TimelineEntry}

  setup_all do
    start_supervised!(Test.Repo)

    igniter =
      test_project(app_name: :test)
      |> Ui.igniter()

    operator_components_source =
      Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
      |> Rewrite.Source.get(:content)

    operator_live_source =
      Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_live.ex")
      |> Rewrite.Source.get(:content)

    Code.compile_string(operator_components_source)
    [{live_module, _bytecode}] = Code.compile_string(operator_live_source)

    Application.put_env(:parapet, :repo, Test.Repo)

    on_exit(fn -> Application.delete_env(:parapet, :repo) end)

    {:ok, live_module: live_module}
  end

  setup do
    Test.Repo.seed!(%{
      incidents: seeded_incidents(),
      entries: seeded_entries(),
      action_items: []
    })

    :ok
  end

  test "generated operator live renders only the current bounded page and pages by URL cursor",
       %{live_module: live_module} do
    socket = configured_socket(live_module, URI.parse("http://example.com/parapet"))

    {:ok, socket} = live_module.mount(%{}, %{}, socket)
    {:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
    html = render_live(live_module, socket)

    assert html =~ "Active incident 1"
    assert html =~ "Active incident 30"
    refute html =~ "Active incident 31"
    refute html =~ "Resolved incident 61"

    assert count_visible_titles(html) == 30

    next_cursor =
      Base.url_encode64("2026-05-10T11:30:00Z|inc-030", padding: false)

    {:noreply, socket} =
      live_module.handle_params(
        %{"cursor" => next_cursor, "direction" => "next"},
        "http://example.com/parapet?cursor=#{next_cursor}&direction=next",
        socket
      )

    html = render_live(live_module, socket)

    assert html =~ "Active incident 31"
    assert html =~ "Active incident 60"
    refute html =~ "Active incident 1"
    refute html =~ "Resolved incident 61"
    assert count_visible_titles(html) == 30
  end

  test "generated operator live resolves an active incident into resolved history",
       %{live_module: live_module} do
    socket = configured_socket(live_module, URI.parse("http://example.com/parapet"))

    {:ok, socket} = live_module.mount(%{}, %{}, socket)
    {:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)

    assert render_live(live_module, socket) =~ ">Active incident 1<"

    {:noreply, socket} = live_module.handle_event("resolve", %{"id" => "inc-001"}, socket)

    {:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
    active_html = render_live(live_module, socket)

    refute active_html =~ ">Active incident 1<"
    assert active_html =~ ">Active incident 31<"

    {:noreply, socket} =
      live_module.handle_params(
        %{"status" => "resolved"},
        "http://example.com/parapet?status=resolved",
        socket
      )

    resolved_html = render_live(live_module, socket)

    assert resolved_html =~ ">Active incident 1<"
    assert Test.Repo.get!(Incident, "inc-001").state == "resolved"
  end

  defp seeded_incidents do
    active_incidents =
      for index <- 1..60 do
        %Incident{
          id: "inc-#{String.pad_leading(Integer.to_string(index), 3, "0")}",
          state: if(rem(index, 2) == 0, do: "investigating", else: "open"),
          title: "Active incident #{index}",
          updated_at: DateTime.add(~U[2026-05-10 12:00:00Z], -index * 60, :second),
          inserted_at: DateTime.add(~U[2026-05-10 12:00:00Z], -(index + 10) * 60, :second),
          runbook_data: %{
            "triage" => %{
              "symptom" => "Active incident #{index}",
              "integration" => "mailglass",
              "fault_plane" => "webhook",
              "severity" => if(rem(index, 3) == 0, do: "high", else: nil),
              "affected_journey" => "checkout"
            }
          }
        }
      end

    resolved_incidents =
      for index <- 61..65 do
        %Incident{
          id: "inc-#{String.pad_leading(Integer.to_string(index), 3, "0")}",
          state: "resolved",
          title: "Resolved incident #{index}",
          updated_at: DateTime.add(~U[2026-05-10 12:00:00Z], -index * 60, :second),
          inserted_at: DateTime.add(~U[2026-05-10 12:00:00Z], -(index + 10) * 60, :second),
          runbook_data: %{
            "triage" => %{
              "symptom" => "Resolved incident #{index}",
              "integration" => "mailglass"
            }
          }
        }
      end

    active_incidents ++ resolved_incidents
  end

  defp seeded_entries do
    Map.new(seeded_incidents(), fn incident ->
      {incident.id,
       [
         %TimelineEntry{
           incident_id: incident.id,
           type: "triage_snapshot",
           payload: %{
             "symptom" => incident.title,
             "integration" => "mailglass",
             "fault_plane" => "webhook"
           },
           inserted_at: incident.updated_at
         }
       ]}
    end)
  end

  defp count_visible_titles(html) do
    Regex.scan(~r/Active incident \d+/, html) |> Enum.count()
  end

  defp configured_socket(view, host_uri) do
    Utils.configure_socket(
      %Phoenix.LiveView.Socket{view: view, router: TestWeb, endpoint: TestWeb},
      %{
        assign_new: {%{}, []},
        connect_params: %{},
        connect_info: %{},
        conn_session: %{},
        lifecycle: Lifecycle.build([]),
        root_view: view,
        live_temp: %{}
      },
      nil,
      %{},
      host_uri
    )
  end

  defp render_live(live_module, socket) do
    socket.assigns
    |> live_module.render()
    |> Phoenix.LiveViewTest.rendered_to_string()
  end
end
