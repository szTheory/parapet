# Phase 10: tighten-archive-retention-semantics - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/parapet/evidence/archiver.ex` | service | batch | `lib/parapet/evidence/archiver.ex` | exact |
| `lib/mix/tasks/parapet.archive.ex` | config | request-response | `lib/mix/tasks/parapet.archive.ex` | exact |
| `test/parapet/evidence/archiver_test.exs` | test | batch | `test/parapet/evidence/archiver_test.exs` | exact |
| `test/mix/tasks/parapet.archive_test.exs` | test | request-response | `test/mix/tasks/parapet.archive_test.exs` | exact |
| `test/parapet/evidence/archive_worker_test.exs` | test | event-driven | `test/parapet/evidence/archive_worker_test.exs` | exact |
| `.planning/v0.9-phases/2/VERIFICATION.md` | config | request-response | `.planning/v0.9-phases/3/VERIFICATION.md` | role-match |

## Pattern Assignments

### `lib/parapet/evidence/archiver.ex` (service, batch)

**Analog:** `lib/parapet/evidence/archiver.ex`

**Imports and alias pattern** ([lib/parapet/evidence/archiver.ex](/Users/jon/projects/parapet/lib/parapet/evidence/archiver.ex:6)):
```elixir
import Ecto.Query, only: [from: 2]

alias Parapet.Spine.Incident
```

**Core batch/archive pattern** ([lib/parapet/evidence/archiver.ex](/Users/jon/projects/parapet/lib/parapet/evidence/archiver.ex:12)):
```elixir
@spec archive(module(), Path.t(), pos_integer()) :: {:ok, :ok}
def archive(repo, path, retention_days) when is_integer(retention_days) and retention_days > 0 do
  cutoff =
    DateTime.utc_now()
    |> DateTime.add(-retention_days, :day)
    |> DateTime.truncate(:second)

  File.mkdir_p!(Path.dirname(path))

  repo.transaction(fn ->
    Incident
    |> archive_query(cutoff)
    |> repo.stream(max_rows: chunk_size())
    |> Stream.chunk_every(chunk_size())
    |> Enum.each(fn incidents ->
      full_incidents = repo.preload(incidents, [timeline_entries: :tool_audits])
```

**Eligibility predicate to narrow, not redesign** ([lib/parapet/evidence/archiver.ex](/Users/jon/projects/parapet/lib/parapet/evidence/archiver.ex:44)):
```elixir
defp archive_query(queryable, cutoff) do
  from(
    incident in queryable,
    where: incident.state != "open",
    where: incident.inserted_at < ^cutoff
  )
end
```

**Delete path to preserve for FK-safe behavior** ([lib/parapet/evidence/archiver.ex](/Users/jon/projects/parapet/lib/parapet/evidence/archiver.ex:34)):
```elixir
File.write!(path, jsonl <> "\n", [:append, :utf8])

ids = Enum.map(incidents, & &1.id)
repo.delete_all(from incident in Incident, where: incident.id in ^ids)
```

### `lib/mix/tasks/parapet.archive.ex` (config, request-response)

**Analog:** `lib/mix/tasks/parapet.archive.ex`

**Thin Mix task shape** ([lib/mix/tasks/parapet.archive.ex](/Users/jon/projects/parapet/lib/mix/tasks/parapet.archive.ex:13)):
```elixir
use Mix.Task

@default_days 90
@default_path "priv/parapet/archive.jsonl"
```

**CLI delegation pattern to keep stable** ([lib/mix/tasks/parapet.archive.ex](/Users/jon/projects/parapet/lib/mix/tasks/parapet.archive.ex:18)):
```elixir
@impl Mix.Task
def run(args) do
  Application.load(:parapet)
  Mix.Task.run("app.config")

  {opts, _, _} = OptionParser.parse(args, switches: [days: :integer, path: :string])

  repo = Application.fetch_env!(:parapet, :repo)
  days = Keyword.get(opts, :days, @default_days)
  path = Keyword.get(opts, :path, @default_path)

  _result = Parapet.Evidence.Archiver.archive(repo, path, days)

  Mix.shell().info(Jason.encode!(%{status: "ok", result: "ok"}))
```

**Doc wording that should match runtime semantics** ([lib/mix/tasks/parapet.archive.ex](/Users/jon/projects/parapet/lib/mix/tasks/parapet.archive.ex:4)):
```elixir
@moduledoc """
Archives non-open incidents older than the retention window to a JSONL file.
```

### `test/parapet/evidence/archiver_test.exs` (test, batch)

**Analog:** `test/parapet/evidence/archiver_test.exs`

**Fake repo transaction/stream pattern** ([test/parapet/evidence/archiver_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archiver_test.exs:24)):
```elixir
def transaction(fun) when is_function(fun, 0) do
  Agent.update(__MODULE__, fn state ->
    %{state | in_transaction?: true, transactions: state.transactions + 1}
  end)

  result =
    try do
      {:ok, fun.()}
    after
      Agent.update(__MODULE__, &%{&1 | in_transaction?: false})
    end
```

**Current fixture/query bug lock to replace** ([test/parapet/evidence/archiver_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archiver_test.exs:90)):
```elixir
defp matching_ids_from_query(query) do
  cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

  Agent.get(__MODULE__, fn state ->
    state.incidents
    |> Enum.filter(fn incident ->
      incident.state != "open" and DateTime.compare(incident.inserted_at, cutoff) == :lt
    end)
    |> Enum.map(& &1.id)
  end)
end
```

**Regression fixture pattern to preserve but flip expectations** ([test/parapet/evidence/archiver_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archiver_test.exs:142)):
```elixir
old_investigating =
  %Incident{
    id: Ecto.UUID.generate(),
    title: "Old investigating incident",
    description: "archive me too",
    state: "investigating",
    inserted_at: days_ago(31),
    updated_at: days_ago(31)
  }
```

**Assertion shape to update** ([test/parapet/evidence/archiver_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archiver_test.exs:190)):
```elixir
test "archives resolved or investigating incidents older than retention, preloads nested evidence, and deletes archived rows",
     %{archive_path: archive_path, archive_ids: archive_ids} do
  assert {:ok, :ok} = Archiver.archive(FakeRepo, archive_path, 30)

  ...

  assert Enum.map(lines, & &1["id"]) == archive_ids
  assert Enum.map(lines, & &1["state"]) == ["resolved", "investigating"]
```

### `test/mix/tasks/parapet.archive_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/parapet.archive_test.exs`

**Mix shell + env setup pattern** ([test/mix/tasks/parapet.archive_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.archive_test.exs:75)):
```elixir
setup do
  Mix.shell(Mix.Shell.Process)
  Mix.Task.reenable("app.config")

  archive_path =
    Path.join(System.tmp_dir!(), "parapet-archive-task-#{System.unique_integer([:positive])}.jsonl")

  old_incident = %Incident{id: Ecto.UUID.generate(), state: "resolved", inserted_at: days_ago(120)}
  recent_incident = %Incident{id: Ecto.UUID.generate(), state: "resolved", inserted_at: days_ago(10)}

  Application.put_env(:parapet, :repo, FakeRepo)
```

**CLI execution/assertion pattern** ([test/mix/tasks/parapet.archive_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.archive_test.exs:96)):
```elixir
test "parses CLI args, fetches repo from config, invokes the archiver, and prints JSON", %{
  archive_path: archive_path,
  archived_id: archived_id
} do
  assert :ok = Archive.run(["--days", "90", "--path", archive_path])

  assert_receive {:mix_shell, :info, [output]}
  assert %{"status" => "ok", "result" => "ok"} = Jason.decode!(output)
```

**Current archive filter stub to broaden the regression coverage around** ([test/mix/tasks/parapet.archive_test.exs](/Users/jon/projects/parapet/test/mix/tasks/parapet.archive_test.exs:48)):
```elixir
cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

state.incidents
|> Enum.filter(fn incident ->
  incident.state != "open" and DateTime.compare(incident.inserted_at, cutoff) == :lt
end)
|> Stream.map(& &1)
```

### `test/parapet/evidence/archive_worker_test.exs` (test, event-driven)

**Analog:** `test/parapet/evidence/archive_worker_test.exs`

**Conditional compile pattern** ([test/parapet/evidence/archive_worker_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archive_worker_test.exs:1)):
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Evidence.ArchiveWorkerTest do
    use ExUnit.Case, async: false
```

**Worker job execution pattern** ([test/parapet/evidence/archive_worker_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archive_worker_test.exs:97)):
```elixir
test "defines an Oban worker" do
  changeset = ArchiveWorker.new(%{"days" => 90})
  assert Ecto.Changeset.get_change(changeset, :worker) == "Parapet.Evidence.ArchiveWorker"
end

test "archives using explicit job args", %{archive_path: archive_path, archived_id: archived_id} do
  job = %Oban.Job{args: %{"days" => 90, "path" => archive_path}}

  assert {:ok, :ok} = ArchiveWorker.perform(job)
```

**Current filter stub to update with investigating coverage** ([test/parapet/evidence/archive_worker_test.exs](/Users/jon/projects/parapet/test/parapet/evidence/archive_worker_test.exs:49)):
```elixir
cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

state.incidents
|> Enum.filter(fn incident ->
  incident.state != "open" and DateTime.compare(incident.inserted_at, cutoff) == :lt
end)
|> Stream.map(& &1)
```

### `.planning/v0.9-phases/2/VERIFICATION.md` (config, request-response)

**Analog:** `.planning/v0.9-phases/3/VERIFICATION.md`

**Frontmatter and report header pattern** ([.planning/v0.9-phases/3/VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md:1)):
```markdown
---
phase: 03-operator-ui-performance
verified: 2026-05-21T19:50:25Z
status: verified
score: 3/3 requirements verified
human_verification: []
---

# Phase 3: Operator UI Performance Verification Report
```

**Observable truths table pattern** ([.planning/v0.9-phases/3/VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md:18)):
```markdown
### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `Parapet.Operator.list_incident_queue/1` is the bounded public queue seam and emits low-cardinality queue-page telemetry. | ✓ VERIFIED | `lib/parapet/operator.ex` bounds page size to `30` by default, caps it at `100`, keeps the active queue ordered by `updated_at` and `id`, and emits `page_size_bucket` / `result_size_bucket` telemetry. |
```

**Behavioral spot-check table pattern** ([.planning/v0.9-phases/3/VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md:28)):
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Queue seam and telemetry proof | `mix test test/parapet/operator/queue_pagination_test.exs` | 4 tests, 0 failures | ✓ PASS |
```

**Requirements and gaps wording pattern** ([.planning/v0.9-phases/3/VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md:45)):
```markdown
### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `SCALE-01.c` operator queue paging proof | ✓ SATISFIED | Queue pagination tests plus generated UI tests passed in this session, proving bounded active-page fetch and current-page rendering. |

### Gaps Summary

No known Phase 3 execution gaps remain within the operator UI performance scope.
```

**Current contradictory text to rewrite** ([.planning/v0.9-phases/2/VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/2/VERIFICATION.md:22)):
```markdown
| 3 | Old non-open incidents are exported to JSONL in bounded chunks and then hard-deleted through the repo layer. | ✓ VERIFIED | `Parapet.Evidence.Archiver.archive/3` streams, preloads nested evidence, appends JSONL, and `delete_all`s archived IDs in `lib/parapet/evidence/archiver.ex`, covered by `test/parapet/evidence/archiver_test.exs`. |
```

## Shared Patterns

### Active Queue Contract
**Source:** [lib/parapet/operator.ex](/Users/jon/projects/parapet/lib/parapet/operator.ex:14), [docs/operator-ui.md](/Users/jon/projects/parapet/docs/operator-ui.md:91)
**Apply to:** `lib/parapet/evidence/archiver.ex`, all archive tests, Phase 2 verification wording
```elixir
@active_queue_states ["open", "investigating"]

Incident
|> where([i], i.state in ^@active_queue_states)
```

```markdown
- The default queue remains active-only (`open` and `investigating`).
- Uses `50,000` active incidents plus `120` resolved incidents so the active queue and resolved history both exist without changing the default queue scope.
```

### Thin Entrypoint Delegation
**Source:** [lib/mix/tasks/parapet.archive.ex](/Users/jon/projects/parapet/lib/mix/tasks/parapet.archive.ex:19), [lib/parapet/evidence/archive_worker.ex](/Users/jon/projects/parapet/lib/parapet/evidence/archive_worker.ex:12)
**Apply to:** archive CLI/task wording, worker-related tests
```elixir
repo = Application.fetch_env!(:parapet, :repo)
days = Keyword.get(opts, :days, @default_days)
path = Keyword.get(opts, :path, @default_path)

_result = Parapet.Evidence.Archiver.archive(repo, path, days)
```

```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: args}) do
  repo = Application.fetch_env!(:parapet, :repo)
  days = Map.get(args, "days", @default_days)
  path = Map.get(args, "path", @default_path)

  Parapet.Evidence.Archiver.archive(repo, path, days)
end
```

### Closure Proof Structure
**Source:** [.planning/v0.9-phases/3/VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md:16)
**Apply to:** `.planning/v0.9-phases/2/VERIFICATION.md`
```markdown
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/`, `test/`, `docs/`, `.planning/`
**Files scanned:** 11 primary files plus repo-wide pattern search
**Pattern extraction date:** 2026-05-22
