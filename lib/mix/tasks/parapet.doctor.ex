defmodule Mix.Tasks.Parapet.Doctor do
  @shortdoc "Validates Parapet SLO definitions."

  @moduledoc """
  Statically analyzes the application's Parapet configuration, specifically
  enforcing that every defined SLO contains an actionable runbook link.

  Missing runbooks will cause this task to print an error and exit with code 2.

  ## Examples

      mix parapet.doctor

  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # Load the application to ensure modules are compiled and SLOs are registered
    Mix.Task.run("app.config")
    
    # We might need to ensure the application starts or is loaded, 
    # but since SLOs might be defined in modules that run on startup or are loaded,
    # we ensure loaded.
    Application.load(:parapet)

    # In many Phoenix apps, calling `Mix.Task.run("app.start")` might be required
    # to actually execute `Parapet.SLO.define/2` if they are defined inside application startup.
    # However, if they are defined at compile time using module attributes, they are available.
    # Let's see what happens.
    
    # Actually, SLOs might only be in `Application.get_env(:parapet, :slos, [])`.
    slos = Parapet.SLO.all()

    invalid_slos =
      Enum.filter(slos, fn slo ->
        is_nil(slo.runbook) or String.trim(slo.runbook) == ""
      end)

    if invalid_slos != [] do
      Enum.each(invalid_slos, fn slo ->
        Mix.shell().error("Error: SLO #{inspect(slo.name)} is missing a valid runbook. A runbook URL is required for actionable alerts.")
      end)

      halt(2)
    else
      Mix.shell().info("Parapet configuration is valid. All SLOs have runbooks.")
      :ok
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
