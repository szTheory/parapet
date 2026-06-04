defmodule Parapet.AdoptionDocsTest do
  use ExUnit.Case, async: true

  @readme Path.expand("../../README.md", __DIR__)
  @operator_ui Path.expand("../../docs/operator-ui.md", __DIR__)
  @troubleshooting Path.expand("../../docs/troubleshooting.md", __DIR__)
  @quality_evaluation Path.expand("../../.planning/QUALITY-EVALUATION.md", __DIR__)

  test "archive maintenance docs expose the CLI contract boundary and cadence" do
    readme = File.read!(@readme)
    troubleshooting = File.read!(@troubleshooting)
    docs = readme <> "\n" <> troubleshooting

    assert readme =~ "mix parapet.archive"
    assert readme =~ "mix parapet.archive --days 30"
    assert readme =~ "mix parapet.archive --path priv/parapet/archive.jsonl"

    for phrase <- [
          "priv/parapet/archive.jsonl",
          "JSONL",
          "manifest",
          "status",
          "run_id",
          "path",
          "manifest_path",
          "retention_days",
          "cutoff",
          "selected_count",
          "archived_count",
          "deleted_count",
          "skipped_count",
          "bytes_written",
          "checksum",
          "config :parapet, :repo",
          "--days",
          "--path",
          "when to run archive maintenance",
          "routine resolved-incident retention",
          "before widening retention or pruning old evidence",
          "after confirming host backups cover host-owned data",
          "Parapet archive maintenance is operational evidence export/prune for Parapet-owned records, not host backup/restore.",
          "Retention currently means resolved incidents created before the cutoff (`inserted_at < cutoff`), not incidents resolved before the cutoff."
        ] do
      assert docs =~ phrase
    end
  end

  test "archive troubleshooting documents first failure fields and safe reruns" do
    troubleshooting = File.read!(@troubleshooting)

    for phrase <- [
          "stage",
          "reason",
          "write",
          "verify",
          "manifest",
          "publish",
          "delete",
          "run_id",
          "path",
          "manifest_path",
          "selected_count",
          "archived_count",
          "deleted_count",
          "safe rerun"
        ] do
      assert troubleshooting =~ phrase
    end
  end

  test "README and operator UI docs show default and scoped router examples" do
    readme = File.read!(@readme)
    operator_ui = File.read!(@operator_ui)

    for docs <- [readme, operator_ui] do
      assert docs =~ "Default mount: `/parapet`"
      assert docs =~ "Scoped mount: `/ops/parapet`"
      assert docs =~ "scope \"/\", MyAppWeb do"
      assert docs =~ "scope \"/ops\", MyAppWeb do"
      assert docs =~ "pipe_through [:browser, :require_authenticated_user]"
      assert docs =~ "live_session :parapet_operator"

      for route <- operator_ui_routes() do
        assert docs =~ route
      end

      assert docs =~ "Generated Operator UI files are host-owned."

      assert docs =~
               "Host apps own authentication, authorization, pipelines, live sessions, and router scopes."
    end
  end

  test "scoped mounting troubleshooting covers stale files auth protection and partial route maps" do
    troubleshooting = File.read!(@troubleshooting)
    operator_ui = File.read!(@operator_ui)

    assert operator_ui =~ "### Scoped Mount Gotchas"

    assert operator_ui =~
             "Scoped support does not require a generator flag, Parapet router abstraction, stable public API change, or dependency change."

    for phrase <- [
          "stale generated UI files",
          "authenticated pipeline",
          "live_session",
          "partial nested route maps",
          "operator_base_path",
          "stale generated UI files still point at `/parapet`",
          "scoped Operator UI mount is visible without auth",
          "some `/ops/parapet` links return 404",
          "regenerate or manually port `operator_base_path` helpers",
          "mount the whole route map under the same `/ops` scope",
          "keep routes inside the host app's authenticated pipeline and `live_session`"
        ] do
      assert operator_ui <> "\n" <> troubleshooting =~ phrase
    end
  end

  test "quality evaluation records v1.4 top risk closeout without overclaiming" do
    quality_evaluation = File.read!(@quality_evaluation)

    for phrase <- [
          "v1.4 Top-Risk Closeout",
          "2026-06-04",
          "Phase 37",
          "Phase 38",
          "Phase 39",
          "37-03-SUMMARY.md",
          "38-03-SUMMARY.md",
          "39-01-SUMMARY.md",
          "archive durability",
          "scoped route compatibility",
          "adoption supportability docs",
          "does not claim every quality-evaluation item is closed"
        ] do
      assert quality_evaluation =~ phrase
    end
  end

  defp operator_ui_routes do
    [
      ~S|live "/parapet", MyAppWeb.Parapet.OperatorLive, :index|,
      ~S|live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions|,
      ~S|live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history|,
      ~S|live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|,
      ~S|live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|
    ]
  end
end
