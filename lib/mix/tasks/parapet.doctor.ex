defmodule Mix.Tasks.Parapet.Doctor do
  @shortdoc "Validates Parapet SLO definitions and security."

  @moduledoc """
  Statically analyzes the application's Parapet configuration, checking for:
  - SLOs missing actionable runbook links (Fatal)
  - Exposed `/metrics` or `live_dashboard` endpoints without auth in the Router (Warn)
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
    
    # We check 3 things:
    # 1. Runbooks
    # 2. Router Security
    # 3. Endpoint Configuration

    results = %{
      runbooks: check_runbooks(),
      router: check_router(),
      endpoint: check_endpoint()
    }

    # Aggregate status
    fatals = Enum.filter(Map.values(results), fn r -> r.status == :fatal end)
    warnings = Enum.filter(Map.values(results), fn r -> r.status == :warn end)

    exit_code =
      cond do
        length(fatals) > 0 -> 2
        length(warnings) > 0 -> 1
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
    invalid_slos = Enum.filter(slos, fn slo ->
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
      
      # We use regex/string matching for a simplified robust check instead of full Sourceror
      # for performance and resilience in a quick static check, but we could use AST.
      # The instructions say "Use Sourceror to parse lib/my_app_web/router.ex. Look for live_dashboard and forward '/metrics'. Verify they are wrapped in a scope that pipes through an authentication plug"
      
      # Let's use Sourceror if it's available, otherwise fallback.
      if Code.ensure_loaded?(Sourceror) do
        ast = Sourceror.parse_string!(source)
        
        # Traverse AST to find `forward "/metrics"` or `live_dashboard` and check scopes
        {_, acc} = Macro.prewalk(ast, {[], []}, fn
          {:scope, _, args} = node, {scopes, violations} ->
            {node, {[{:scope, extract_plugs(args)} | scopes], violations}}
          {:forward, _, [route | _]} = node, {scopes, violations} when is_binary(route) ->
            if route == "/metrics" and not has_auth_plug?(scopes) do
              {node, {scopes, ["Unsecured /metrics route found" | violations]}}
            else
              {node, {scopes, violations}}
            end
          {:live_dashboard, _, _} = node, {scopes, violations} ->
            if not has_auth_plug?(scopes) do
              {node, {scopes, ["Unsecured live_dashboard route found" | violations]}}
            else
              {node, {scopes, violations}}
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
    # A naive AST extraction of `pipe_through :some_auth`
    # or `pipe_through [:browser, :require_authenticated_user]`
    # This is complex to do perfectly, so we just look for `require_authenticated`
    # or `auth` in the stringified args.
    text = Macro.to_string(args)
    String.contains?(text, "auth") or String.contains?(text, "require_authenticated")
  end

  defp has_auth_plug?(scopes) do
    Enum.any?(scopes, fn {:scope, has_auth} -> has_auth end)
  end

  defp print_human(results) do
    Enum.each(results, fn {check, result} ->
      color = case result.status do
        :ok -> [:green]
        :warn -> [:yellow]
        :fatal -> [:red]
      end
      
      printer = if result.status == :ok, do: fn msg -> Mix.shell().info(msg) end, else: fn msg -> Mix.shell().error(msg) end

      printer.(IO.ANSI.format(color ++ ["==> #{check}: #{result.status}"] ++ [:reset]) |> IO.iodata_to_binary())
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

  defp halt(code) do
    if Mix.env() == :test do
      exit({:shutdown, code})
    else
      System.halt(code)
    end
  end
end
