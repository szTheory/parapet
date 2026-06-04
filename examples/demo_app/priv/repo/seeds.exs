# Belt-and-suspenders: config/config.exs already sets this, but explicit here
# so `mix run priv/repo/seeds.exs` works standalone without full config load.
Application.put_env(:parapet, :repo, DemoApp.Repo)

Code.require_file("demo_seed_scenarios.exs", __DIR__)

scenario = System.get_env("PARAPET_DEMO_SCENARIO", "all")
DemoApp.DemoSeedScenarios.seed(scenario)

IO.puts(
  "Seeds complete for scenario #{scenario}: #{Enum.join(DemoApp.DemoSeedScenarios.scenarios(), ", ")}"
)
