# Belt-and-suspenders: config/config.exs already sets this, but explicit here
# so `mix run priv/repo/seeds.exs` works standalone without full config load.
Application.put_env(:parapet, :repo, DemoApp.Repo)

# DemoApp.DemoSeedScenarios is compiled from lib/demo_app/demo_seed_scenarios.ex
# (not loaded via Code.require_file — the module is part of the compiled app).

scenario = System.get_env("PARAPET_DEMO_SCENARIO", "all")
DemoApp.DemoSeedScenarios.seed(scenario)

IO.puts(
  "Seeds complete for scenario #{scenario}: #{Enum.join(DemoApp.DemoSeedScenarios.scenarios(), ", ")}"
)
