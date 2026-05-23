defmodule Mix.Tasks.Parapet.Doctor do
  # credo:disable-for-this-file Credo.Check.Refactor.Nesting
  @shortdoc "Validates Parapet installation safety, SLO posture, and cluster readiness."

  @moduledoc """
  Statically analyzes the application's Parapet configuration and exposes a runtime-oriented
  `cluster` mode for live facts.

  Statuses:
  - `info`: informational or healthy
  - `warn`: risk or ambiguity that should fail CI when threshold is `warn`
  - `error`: concrete contradiction or unsafe setup
  - `skip`: check not applicable or unavailable

  Exit codes:
  - `0`: no findings at or above the active threshold
  - `1`: at least one finding at or above the active threshold
  - `2`: doctor execution failed or a runtime probe could not run
  """
  use Mix.Task

  @static_checks ~w(runbooks router operator_ui endpoint cardinality cluster_static)
  @severity_order %{skip: 0, info: 0, warn: 1, error: 2}

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args, switches: [ci: :boolean, threshold: :string])

    if invalid != [] do
      Mix.raise("Invalid options for mix parapet.doctor: #{inspect(invalid)}")
    end

    is_ci = Keyword.get(opts, :ci, false)
    threshold = parse_threshold(opts[:threshold], is_ci)
    {mode, requested_checks} = parse_requested_checks(positional)

    Application.load(:parapet)
    Mix.Task.run("app.config")

    case run_checks(mode, requested_checks) do
      {:ok, results} ->
        exit_code = findings_exit_code(results, threshold)
        print_results(results, exit_code, is_ci)
        if exit_code > 0, do: halt(exit_code)
        :ok

      {:error, reason} ->
        print_probe_failure(reason, is_ci)
        halt(2)
    end
  end

  defp parse_threshold(nil, true), do: :warn
  defp parse_threshold(nil, false), do: :error
  defp parse_threshold("warn", _is_ci), do: :warn
  defp parse_threshold("error", _is_ci), do: :error

  defp parse_threshold(other, _is_ci) do
    Mix.raise("Unsupported --threshold value #{inspect(other)}. Use warn or error.")
  end

  defp parse_requested_checks([]), do: {:static, @static_checks}
  defp parse_requested_checks(["cluster"]), do: {:cluster, []}

  defp parse_requested_checks(checks) do
    unsupported = Enum.reject(checks, &(&1 in @static_checks))

    if unsupported == [] do
      {:static, checks}
    else
      Mix.raise("Unsupported doctor checks: #{Enum.join(unsupported, ", ")}")
    end
  end

  defp run_checks(:static, requested_checks) do
    results =
      Enum.reduce(requested_checks, %{}, fn check, acc ->
        Map.put(acc, String.to_atom(check), run_static_check(check))
      end)

    {:ok, results}
  end

  defp run_checks(:cluster, _requested_checks) do
    run_cluster_probe()
  end

  defp run_static_check("runbooks"), do: check_runbooks()
  defp run_static_check("router"), do: check_router()
  defp run_static_check("operator_ui"), do: check_operator_ui()
  defp run_static_check("endpoint"), do: check_endpoint()
  defp run_static_check("cardinality"), do: check_cardinality()
  defp run_static_check("cluster_static"), do: check_cluster_static()

  defp check_runbooks do
    slos = Parapet.SLO.all()

    invalid_slos =
      Enum.filter(slos, fn slo ->
        is_nil(slo.runbook) or String.trim(slo.runbook) == ""
      end)

    cond do
      slos == [] ->
        %{status: :skip, messages: ["No SLOs defined, so runbook validation was skipped."]}

      invalid_slos == [] ->
        %{status: :info, messages: ["All SLOs have runbooks."]}

      true ->
        messages = Enum.map(invalid_slos, &"SLO #{inspect(&1.name)} is missing a valid runbook")
        %{status: :error, messages: messages}
    end
  end

  defp check_router do
    app_name = Mix.Project.config()[:app]
    router_path = "lib/#{app_name}_web/router.ex"

    cond do
      not File.exists?(router_path) ->
        %{status: :skip, messages: ["No router found at #{router_path}."]}

      not Code.ensure_loaded?(Sourceror) ->
        %{status: :skip, messages: ["Sourceror not available, skipping router static analysis."]}

      true ->
        source = File.read!(router_path)
        ast = Sourceror.parse_string!(source)

        {_, acc} =
          Macro.prewalk(ast, {[], []}, fn
            {:scope, _, args} = node, {scopes, violations} ->
              {node, {[{:scope, extract_plugs(args)} | scopes], violations}}

            {:forward, _, [route | _]} = node, {scopes, violations} when is_binary(route) ->
              if route == "/metrics" and not has_auth_plug?(scopes) do
                {node, {scopes, ["Unsecured /metrics route found" | violations]}}
              else
                {node, {scopes, violations}}
              end

            {:live_dashboard, _, _} = node, {scopes, violations} ->
              if has_auth_plug?(scopes) do
                {node, {scopes, violations}}
              else
                {node, {scopes, ["Unsecured live_dashboard route found" | violations]}}
              end

            node, acc ->
              {node, acc}
          end)

        {_, violations} = acc

        if violations == [] do
          %{status: :info, messages: ["Router security looks good."]}
        else
          %{status: :warn, messages: Enum.reverse(violations)}
        end
    end
  end

  defp check_operator_ui do
    app_name = Mix.Project.config()[:app]
    router_path = "lib/#{app_name}_web/router.ex"

    cond do
      not File.exists?(router_path) ->
        %{status: :skip, messages: ["No router found at #{router_path}."]}

      not Code.ensure_loaded?(Sourceror) ->
        %{
          status: :skip,
          messages: ["Sourceror not available, skipping operator UI static analysis."]
        }

      true ->
        source = File.read!(router_path)
        ast = Sourceror.parse_string!(source)

        {_, acc} =
          Macro.prewalk(ast, {[], []}, fn
            {:scope, _, args} = node, {scopes, violations} ->
              {node, {[{:scope, extract_plugs(args)} | scopes], violations}}

            {:live_session, _, args} = node, {scopes, violations} ->
              {node, {[{:live_session, extract_plugs(args)} | scopes], violations}}

            {:live, _, args} = node, {scopes, violations} ->
              text = Macro.to_string(args)

              is_operator_ui =
                String.contains?(text, "OperatorLive") or
                  String.contains?(text, "OperatorDetailLive")

              if is_operator_ui and not has_auth_plug?(scopes) do
                {node, {scopes, ["Unsecured operator UI LiveView found" | violations]}}
              else
                {node, {scopes, violations}}
              end

            node, acc ->
              {node, acc}
          end)

        {_, violations} = acc

        if violations == [] do
          %{status: :info, messages: ["Operator UI security looks good."]}
        else
          %{status: :warn, messages: Enum.reverse(violations)}
        end
    end
  end

  defp check_endpoint do
    app_name = Mix.Project.config()[:app]
    endpoint_path = "lib/#{app_name}_web/endpoint.ex"

    cond do
      not File.exists?(endpoint_path) ->
        %{status: :skip, messages: ["No endpoint found at #{endpoint_path}."]}

      String.contains?(File.read!(endpoint_path), "Parapet.Plug.Metrics") ->
        %{status: :info, messages: ["Endpoint has Parapet.Plug.Metrics."]}

      true ->
        %{status: :warn, messages: ["Endpoint is missing Parapet.Plug.Metrics."]}
    end
  end

  defp check_cardinality do
    slos = Parapet.SLO.all()

    cond do
      slos == [] ->
        %{status: :skip, messages: ["No SLOs defined, so cardinality checks were skipped."]}

      true ->
        violations =
          Enum.flat_map(slos, fn slo ->
            [slo.good_events, slo.total_events]
            |> Enum.reject(&is_nil/1)
            |> Enum.flat_map(fn query ->
              labels = extract_labels(query)

              try do
                Parapet.Internal.LabelPolicy.assert_safe!(labels)
                []
              rescue
                e in ArgumentError ->
                  ["SLO #{inspect(slo.name)} has unsafe labels: #{e.message}"]
              end
            end)
          end)

        if violations == [] do
          %{status: :info, messages: ["SLO PromQL cardinality looks safe."]}
        else
          %{status: :error, messages: violations}
        end
    end
  end

  defp extract_labels(query) do
    by_labels =
      Regex.scan(~r/by\s*\(([^)]+)\)/, query)
      |> Enum.flat_map(fn [_, match] -> String.split(match, ",") |> Enum.map(&String.trim/1) end)

    brace_labels =
      Regex.scan(~r/\{([^}]+)\}/, query)
      |> Enum.flat_map(fn [_, match] ->
        String.split(match, ",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(fn kv ->
          case String.split(kv, ~r/(=|!=|=~|!~)/, parts: 2) do
            [key, _] -> String.trim(key)
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      end)

    Enum.uniq(by_labels ++ brace_labels)
  end

  defp check_cluster_static do
    worker_path = "lib/parapet/escalation/worker.ex"

    if not File.exists?(worker_path) do
      %{
        status: :skip,
        messages: [
          "No escalation worker found, so static cluster checks were skipped.",
          "Static check cannot prove distributed correctness without an escalation worker."
        ]
      }
    else
      worker_source = File.read!(worker_path)
      errors = []
      warnings = []

      errors =
        if String.contains?(worker_source, "unique:") do
          errors
        else
          [
            "Escalation worker is missing Oban uniqueness; concurrent nodes could execute the same escalation twice."
            | errors
          ]
        end

      warnings =
        if String.contains?(worker_source, "ClaimService.claim_action") do
          warnings
        else
          [
            "Escalation worker does not appear to route through the DB-backed claim layer; static analysis cannot confirm retry-resume or conflict protection."
            | warnings
          ]
        end

      warnings =
        if Application.get_env(:parapet, :escalation_policy) do
          warnings
        else
          [
            "Escalation policy is not configured, so static analysis cannot prove scheduled dispatch behavior."
            | warnings
          ]
        end

      messages =
        Enum.reverse(errors) ++
          Enum.reverse(warnings) ++
          [
            "Static check cannot prove distributed correctness; run the escalation contention and retry tests for the real proof surface."
          ]

      status =
        cond do
          errors != [] -> :error
          warnings != [] -> :warn
          true -> :info
        end

      %{status: status, messages: messages}
    end
  end

  defp run_cluster_probe do
    case Application.get_env(:parapet, :doctor_cluster_probe) do
      fun when is_function(fun, 0) ->
        case fun.() do
          {:ok, results} when is_map(results) -> {:ok, results}
          {:error, reason} -> {:error, reason}
          other -> {:error, "invalid cluster probe response: #{inspect(other)}"}
        end

      _ ->
        {:ok, %{cluster_runtime: default_cluster_runtime_result()}}
    end
  rescue
    error -> {:error, Exception.message(error)}
  catch
    type, value -> {:error, "#{type}: #{inspect(value)}"}
  end

  defp default_cluster_runtime_result do
    repo = Application.get_env(:parapet, :repo)
    escalation_policy = Application.get_env(:parapet, :escalation_policy)

    oban_started? =
      Enum.any?(Application.started_applications(), fn {app, _, _} -> app == :oban end)

    cond do
      is_nil(repo) ->
        %{
          status: :skip,
          messages: [
            "Runtime cluster check skipped because `config :parapet, :repo` is not configured.",
            "Runtime cluster checks report live facts, but they still cannot prove distributed correctness in isolation."
          ]
        }

      true ->
        messages = [
          "Runtime cluster facts: repo=#{inspect(repo)}, oban_started=#{oban_started?}, escalation_policy=#{inspect(escalation_policy)}",
          "Runtime cluster checks report live facts, but they still cannot prove distributed correctness in isolation."
        ]

        status =
          cond do
            is_nil(escalation_policy) -> :warn
            true -> :info
          end

        %{status: status, messages: messages}
    end
  end

  defp findings_exit_code(results, threshold) do
    if Enum.any?(results, fn {_check, result} ->
         finding_at_or_above_threshold?(result.status, threshold)
       end) do
      1
    else
      0
    end
  end

  defp finding_at_or_above_threshold?(status, threshold) do
    Map.fetch!(@severity_order, status) >= Map.fetch!(@severity_order, threshold)
  end

  defp extract_plugs(args) do
    text = Macro.to_string(args)
    String.contains?(text, "auth") or String.contains?(text, "require_authenticated")
  end

  defp has_auth_plug?(scopes) do
    Enum.any?(scopes, fn {_, has_auth} -> has_auth end)
  end

  defp print_results(results, exit_code, true) do
    output = %{
      exit_code: exit_code,
      checks:
        Map.new(results, fn {check, result} ->
          {to_string(check), %{status: to_string(result.status), messages: result.messages}}
        end)
    }

    if Code.ensure_loaded?(Jason) do
      Mix.shell().info(Jason.encode!(output))
    else
      Mix.shell().info(inspect(output))
    end
  end

  defp print_results(results, _exit_code, false) do
    Enum.each(results, fn {check, result} ->
      color =
        case result.status do
          :info -> [:green]
          :warn -> [:yellow]
          :error -> [:red]
          :skip -> [:cyan]
        end

      printer =
        if result.status in [:warn, :error],
          do: fn message -> Mix.shell().error(message) end,
          else: fn message -> Mix.shell().info(message) end

      printer.(
        IO.ANSI.format(color ++ ["==> #{check}: #{result.status}"] ++ [:reset])
        |> IO.iodata_to_binary()
      )

      Enum.each(result.messages, fn msg ->
        printer.("  - #{msg}")
      end)
    end)
  end

  defp print_probe_failure(reason, true) do
    output = %{
      exit_code: 2,
      error: reason
    }

    if Code.ensure_loaded?(Jason) do
      Mix.shell().info(Jason.encode!(output))
    else
      Mix.shell().info(inspect(output))
    end
  end

  defp print_probe_failure(reason, false) do
    Mix.shell().error("==> doctor: error")
    Mix.shell().error("  - #{reason}")
  end

  @dialyzer {:nowarn_function, halt: 1}
  defp halt(code) do
    if Mix.env() == :test do
      exit({:shutdown, code})
    else
      System.halt(code)
    end
  end
end
