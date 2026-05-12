defmodule Mix.Tasks.Parapet.Doctor do
  # credo:disable-for-this-file Credo.Check.Refactor.Nesting
  @shortdoc "Validates Parapet SLO definitions and security."

  @moduledoc """
  Statically analyzes the application's Parapet configuration, checking for:
  - SLOs missing actionable runbook links (Fatal)
  - Exposed `/metrics` or `live_dashboard` endpoints without auth in the Router (Warn)
  - Exposed Parapet operator UI endpoints without auth in the Router (Warn)
  - Missing Parapet.Instrumenter in Endpoint (Warn)

  Returns 0 on success, 1 on warnings, 2 on fatal errors.

  ## Examples

      mix parapet.doctor
      mix parapet.doctor --ci

  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [ci: :boolean])
    is_ci = Keyword.get(opts, :ci, false)

    # We use static analysis so we don't strictly need to start the app tree,
    # but we need config. For SLOs we just load it.
    Application.load(:parapet)
    Mix.Task.run("app.config")

    # We check 4 things:
    # 1. Runbooks
    # 2. Router Security
    # 3. Operator UI
    # 4. Endpoint Configuration

    results = %{
      runbooks: check_runbooks(),
      router: check_router(),
      operator_ui: check_operator_ui(),
      endpoint: check_endpoint()
    }

    # Aggregate status
    fatals = Enum.filter(Map.values(results), fn r -> r.status == :fatal end)
    warnings = Enum.filter(Map.values(results), fn r -> r.status == :warn end)

    exit_code =
      cond do
        fatals != [] -> 2
        warnings != [] -> 1
        true -> 0
      end

    if is_ci do
      print_json(results, exit_code)
    else
      print_human(results)
    end

    if exit_code > 0, do: halt(exit_code)
    :ok
  end

  defp check_runbooks do
    slos = Parapet.SLO.all()

    invalid_slos =
      Enum.filter(slos, fn slo ->
        is_nil(slo.runbook) or String.trim(slo.runbook) == ""
      end)

    if invalid_slos == [] do
      %{status: :ok, messages: ["All SLOs have runbooks."]}
    else
      messages = Enum.map(invalid_slos, &"SLO #{inspect(&1.name)} is missing a valid runbook")
      %{status: :fatal, messages: messages}
    end
  end

  defp check_router do
    app_name = Mix.Project.config()[:app]
    router_path = "lib/#{app_name}_web/router.ex"

    if File.exists?(router_path) do
      source = File.read!(router_path)

      if Code.ensure_loaded?(Sourceror) do
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
          %{status: :ok, messages: ["Router security looks good."]}
        else
          %{status: :warn, messages: violations}
        end
      else
        %{status: :ok, messages: ["Sourceror not available, skipping router static analysis."]}
      end
    else
      %{status: :ok, messages: ["No router found at #{router_path}."]}
    end
  end

  defp check_operator_ui do
    app_name = Mix.Project.config()[:app]
    router_path = "lib/#{app_name}_web/router.ex"

    if File.exists?(router_path) do
      source = File.read!(router_path)

      if Code.ensure_loaded?(Sourceror) do
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
          %{status: :ok, messages: ["Operator UI security looks good."]}
        else
          %{status: :warn, messages: violations}
        end
      else
        %{
          status: :ok,
          messages: ["Sourceror not available, skipping operator UI static analysis."]
        }
      end
    else
      %{status: :ok, messages: ["No router found at #{router_path}."]}
    end
  end

  defp check_endpoint do
    app_name = Mix.Project.config()[:app]
    endpoint_path = "lib/#{app_name}_web/endpoint.ex"

    if File.exists?(endpoint_path) do
      source = File.read!(endpoint_path)

      if String.contains?(source, "Parapet.Plug.Metrics") do
        %{status: :ok, messages: ["Endpoint has Parapet.Plug.Metrics."]}
      else
        %{status: :warn, messages: ["Endpoint is missing Parapet.Plug.Metrics."]}
      end
    else
      %{status: :ok, messages: ["No endpoint found at #{endpoint_path}."]}
    end
  end

  defp extract_plugs(args) do
    text = Macro.to_string(args)
    String.contains?(text, "auth") or String.contains?(text, "require_authenticated")
  end

  defp has_auth_plug?(scopes) do
    Enum.any?(scopes, fn {_, has_auth} -> has_auth end)
  end

  defp print_human(results) do
    Enum.each(results, fn {check, result} ->
      color =
        case result.status do
          :ok -> [:green]
          :warn -> [:yellow]
          :fatal -> [:red]
        end

      printer =
        if result.status == :ok,
          do: fn msg -> Mix.shell().info(msg) end,
          else: fn msg -> Mix.shell().error(msg) end

      printer.(
        IO.ANSI.format(color ++ ["==> #{check}: #{result.status}"] ++ [:reset])
        |> IO.iodata_to_binary()
      )

      Enum.each(result.messages, fn msg ->
        printer.("  - #{msg}")
      end)
    end)
  end

  defp print_json(results, exit_code) do
    output = %{
      exit_code: exit_code,
      checks: results
    }

    if Code.ensure_loaded?(Jason) do
      Mix.shell().info(Jason.encode!(output))
    else
      Mix.shell().info(inspect(output))
    end
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
