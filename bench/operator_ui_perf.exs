Mix.Task.run("app.start")

defmodule Parapet.OperatorUIPerf.BenchRepo do
  use Agent

  alias Parapet.Spine.{ActionItem, Incident, TimelineEntry}

  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{incidents: [], entries: %{}, action_items: []} end,
      Keyword.put_new(opts, :name, __MODULE__)
    )
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
    query_text = inspect(query)

    Agent.get(__MODULE__, fn state ->
      state.incidents
      |> filter_by_scope(query_text)
      |> apply_cursor(query_text)
      |> apply_order(query_text)
      |> Enum.take(limit_from(query_text))
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

  defp filter_by_scope(incidents, query_text) do
    cond do
      query_text =~ ~s/state in ^["open", "investigating"]/ ->
        Enum.filter(incidents, &(&1.state in ["open", "investigating"]))

      query_text =~ ~s/state == ^"resolved"/ ->
        Enum.filter(incidents, &(&1.state == "resolved"))

      true ->
        incidents
    end
  end

  defp apply_order(incidents, query_text) do
    sorter =
      if query_text =~ "order_by: [asc: i0.updated_at, asc: i0.id]" or
           query_text =~ "order_by: [asc: incident.updated_at, asc: incident.id]" do
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
      ~r/updated_at #{Regex.escape(operator)} \^~U\[(?<updated_at>[^\]]+)\].*id #{Regex.escape(operator)} \^"(?<incident_id>[^"]+)"/s

    %{"updated_at" => updated_at, "incident_id" => incident_id} =
      Regex.named_captures(regex, query_text)

    {:ok, parsed, 0} = DateTime.from_iso8601(updated_at)
    {parsed, incident_id}
  end

  defp limit_from(query_text) do
    cond do
      captures = Regex.named_captures(~r/limit: \^(?<page_size>\d+) \+ 1/, query_text) ->
        String.to_integer(captures["page_size"]) + 1

      captures = Regex.named_captures(~r/limit: \^(?<page_size>\d+)/, query_text) ->
        String.to_integer(captures["page_size"])

      true ->
        31
    end
  end

  defp timeline_incident_id([%{params: [{incident_id, _}]}, _]), do: incident_id
  defp timeline_incident_id([%{params: [{incident_id, _}]}]), do: incident_id
end

defmodule Parapet.OperatorUIPerf.BenchmarkWeb do
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

defmodule Parapet.OperatorUIPerf do
  alias Phoenix.LiveView.{Lifecycle, Utils}
  alias Parapet.Spine.{Incident, TimelineEntry}

  @page_size 30
  @active_incident_count 50_000
  @resolved_incident_count 120

  def run do
    ensure_repo_started!()

    incidents = seeded_incidents()
    entries = seeded_entries(incidents)
    total_incidents = length(incidents)

    Parapet.OperatorUIPerf.BenchRepo.seed!(%{
      incidents: incidents,
      entries: entries,
      action_items: []
    })

    Application.put_env(:parapet, :repo, Parapet.OperatorUIPerf.BenchRepo)

    live_module = compile_generated_live_view!()
    warm_queue_page = Parapet.Operator.list_incident_queue(page_size: @page_size)
    warm_render = render_queue_page(live_module)

    queue_fetch_runs =
      measure_runs(fn ->
        page = Parapet.Operator.list_incident_queue(page_size: @page_size)
        assert_queue_shape!(page)
        page
      end)

    render_runs =
      measure_runs(fn ->
        rendered = render_queue_page(live_module)
        assert_render_shape!(rendered)
        rendered
      end)

    IO.puts("Parapet Operator UI advisory performance lane")
    IO.puts("dataset.total_incidents=#{total_incidents}")
    IO.puts("dataset.active_incidents=#{@active_incident_count}")
    IO.puts("dataset.resolved_incidents=#{@resolved_incident_count}")
    IO.puts("queue.page_size=#{@page_size}")
    IO.puts("queue.visible_rows=#{length(warm_queue_page.items)}")
    IO.puts("queue.has_next_page?=#{warm_queue_page.has_next_page?}")
    IO.puts("render.visible_rows=#{count_visible_rows(warm_render.html)}")
    IO.puts("render.html_bytes=#{byte_size(warm_render.html)}")
    IO.puts("queue_fetch_ms=#{format_summary(queue_fetch_runs)}")
    IO.puts("first_render_ms=#{format_summary(render_runs)}")
    IO.puts("advisory=true")
    IO.puts("merge_gate=disabled")
    IO.puts("operator_queue_reordering=explicit_refresh_only")
  after
    Application.delete_env(:parapet, :repo)
  end

  defp ensure_repo_started! do
    case Process.whereis(Parapet.OperatorUIPerf.BenchRepo) do
      nil ->
        {:ok, _pid} = Parapet.OperatorUIPerf.BenchRepo.start_link()

      _pid ->
        :ok
    end
  end

  defp compile_generated_live_view! do
    bindings = [
      assigns: [
        web_module: Parapet.OperatorUIPerf.BenchmarkWeb,
        repo_module: Parapet.OperatorUIPerf.BenchRepo
      ]
    ]

    components_source =
      EEx.eval_file("priv/templates/parapet.gen.ui/operator_components.ex.eex", bindings)

    live_source =
      EEx.eval_file("priv/templates/parapet.gen.ui/operator_live.ex.eex", bindings)

    Code.compile_string(components_source)
    [{live_module, _bytecode}] = Code.compile_string(live_source)
    live_module
  end

  defp measure_runs(fun, iterations \\ 5) do
    for _ <- 1..iterations do
      started_at = System.monotonic_time()
      _result = fun.()
      elapsed = System.monotonic_time() - started_at
      System.convert_time_unit(elapsed, :native, :microsecond) / 1000
    end
  end

  defp render_queue_page(live_module) do
    socket = configured_socket(live_module, URI.parse("http://example.com/parapet"))

    {:ok, socket} = live_module.mount(%{}, %{}, socket)
    {:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)

    html =
      socket.assigns
      |> live_module.render()
      |> Phoenix.LiveViewTest.rendered_to_string()

    %{html: html, queue_page: socket.assigns.queue_page}
  end

  defp configured_socket(view, host_uri) do
    Utils.configure_socket(
      %Phoenix.LiveView.Socket{view: view, router: Parapet.OperatorUIPerf.BenchmarkWeb, endpoint: Parapet.OperatorUIPerf.BenchmarkWeb},
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

  defp assert_queue_shape!(page) do
    if length(page.items) != @page_size or not page.has_next_page? do
      raise "unexpected queue page shape: #{inspect(page)}"
    end

    page
  end

  defp assert_render_shape!(%{html: html, queue_page: queue_page}) do
    visible_rows = count_visible_rows(html)

    cond do
      visible_rows != @page_size ->
        raise "expected #{@page_size} rendered rows, got #{visible_rows}"

      html =~ "Resolved incident" ->
        raise "resolved incidents leaked into active queue first render"

      not queue_page.has_next_page? ->
        raise "expected additional bounded pages for active queue benchmark"

      true ->
        :ok
    end
  end

  defp count_visible_rows(html) do
    Regex.scan(~r/Active incident \d+/, html) |> Enum.count()
  end

  defp seeded_incidents do
    base_time = ~U[2026-05-10 12:00:00Z]

    active_incidents =
      for index <- 1..@active_incident_count do
        id = "inc-#{String.pad_leading(Integer.to_string(index), 5, "0")}"
        updated_at = DateTime.add(base_time, -index, :second)

        %Incident{
          id: id,
          state: if(rem(index, 2) == 0, do: "investigating", else: "open"),
          title: "Active incident #{index}",
          inserted_at: DateTime.add(updated_at, -60, :second),
          updated_at: updated_at,
          runbook_data: %{
            "triage" => %{
              "symptom" => "Active incident #{index}",
              "integration" => "mailglass",
              "fault_plane" => "webhook",
              "severity" => severity_for(index),
              "affected_journey" => "checkout"
            }
          }
        }
      end

    resolved_incidents =
      for offset <- 1..@resolved_incident_count do
        index = @active_incident_count + offset
        id = "inc-#{String.pad_leading(Integer.to_string(index), 5, "0")}"
        updated_at = DateTime.add(base_time, -index, :second)

        %Incident{
          id: id,
          state: "resolved",
          title: "Resolved incident #{index}",
          inserted_at: DateTime.add(updated_at, -60, :second),
          updated_at: updated_at,
          runbook_data: %{
            "triage" => %{
              "symptom" => "Resolved incident #{index}",
              "integration" => "mailglass",
              "fault_plane" => "webhook",
              "severity" => "low"
            }
          }
        }
      end

    active_incidents ++ resolved_incidents
  end

  defp seeded_entries(incidents) do
    Map.new(incidents, fn incident ->
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

  defp severity_for(index) when rem(index, 15) == 0, do: "critical"
  defp severity_for(index) when rem(index, 5) == 0, do: "high"
  defp severity_for(_index), do: nil

  defp format_summary(values) do
    mean = Enum.sum(values) / length(values)
    min = Enum.min(values)
    max = Enum.max(values)

    "mean=#{format_ms(mean)} min=#{format_ms(min)} max=#{format_ms(max)} runs=#{length(values)}"
  end

  defp format_ms(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 2)
  end
end

Parapet.OperatorUIPerf.run()
