defmodule Parapet.GeneratedOperatorLivePagingTest do
  use ExUnit.Case, async: false
  use Phoenix.ConnTest

  import Igniter.Test
  import Phoenix.LiveViewTest

  alias Mix.Tasks.Parapet.Gen.Ui
  alias Parapet.Spine.{ActionItem, Incident, TimelineEntry}

  @endpoint __MODULE__.Endpoint
  @pubsub __MODULE__.PubSub

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :parapet

    socket "/live", Phoenix.LiveView.Socket
  end

  defmodule TestWeb do
    def __using__(:live_view) do
      quote do
        use Phoenix.LiveView, layout: false
        import Phoenix.Component
        import Phoenix.LiveView
        import Phoenix.LiveView.Helpers
      end
    end

    def __using__(:html) do
      quote do
        use Phoenix.Component
        import Phoenix.LiveView.Helpers
      end
    end
  end

  defmodule TestRepo do
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> %{incidents: [], entries: %{}, action_items: []} end, name: __MODULE__)
    end

    def seed!(attrs) do
      Agent.update(__MODULE__, fn _state ->
        %{
          incidents: Map.fetch!(attrs, :incidents),
          entries: Map.get(attrs, :entries, %{}),
          action_items: Map.get(attrs, :action_items, [])
        }
      end)
    end

    def all(%Ecto.Query{from: %{source: {_, Incident}}} = query) do
      query
      |> inspect()
      |> then(fn query_text ->
        Agent.get(__MODULE__, fn state ->
          state.incidents
          |> Enum.filter(&(&1.state in ["open", "investigating"]))
          |> apply_cursor(query_text)
          |> apply_order(query_text)
          |> Enum.take(limit_from(query_text))
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

    defp timeline_incident_id([%{params: [{incident_id, _}]}, _]), do: incident_id
    defp timeline_incident_id([%{params: [{incident_id, _}]}]), do: incident_id

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
      %{"page_size" => page_size} =
        Regex.named_captures(~r/limit: \^(?<page_size>\d+) \+ 1/, query_text)

      String.to_integer(page_size) + 1
    end
  end

  setup_all do
    start_supervised!({Phoenix.PubSub, name: @pubsub})

    Application.put_env(:parapet, Endpoint,
      secret_key_base: String.duplicate("a", 64),
      live_view: [signing_salt: "generated-operator-live"],
      pubsub_server: @pubsub,
      server: false
    )

    start_supervised!(Endpoint)
    start_supervised!(TestRepo)

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
    Code.compile_string(operator_live_source)

    Application.put_env(:parapet, :repo, TestRepo)

    on_exit(fn ->
      Application.delete_env(:parapet, Endpoint)
      Application.delete_env(:parapet, :repo)
    end)

    :ok
  end

  setup do
    TestRepo.seed!(%{
      incidents: seeded_incidents(),
      entries: seeded_entries(),
      action_items: []
    })

    :ok
  end

  test "generated operator live renders only the current bounded page and pages by URL cursor" do
    {:ok, view, html} = live_isolated(build_conn(), TestWeb.Parapet.OperatorLive)

    assert html =~ "Active incident 1"
    assert html =~ "Active incident 30"
    refute html =~ "Active incident 31"
    refute html =~ "Resolved incident 61"

    assert count_visible_titles(html) == 30

    next_cursor =
      Base.url_encode64("2026-05-10T11:30:00Z|inc-030", padding: false)

    html =
      render_patch(
        view,
        "/parapet?cursor=#{next_cursor}&direction=next"
      )

    assert html =~ "Active incident 31"
    assert html =~ "Active incident 60"
    refute html =~ "Active incident 1"
    refute html =~ "Resolved incident 61"
    assert count_visible_titles(html) == 30
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
    Regex.scan(~r/Active incident \d+/, html) |> Enum.count() |> div(2)
  end
end
