defmodule Parapet.AdoptionDocsTest do
  use ExUnit.Case, async: true

  @readme Path.expand("../../README.md", __DIR__)
  @troubleshooting Path.expand("../../docs/troubleshooting.md", __DIR__)

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
end
