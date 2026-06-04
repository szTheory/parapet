# Phase 39: Adoption Proof - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.md` | utility | transform | `README.md` | exact |
| `docs/operator-ui.md` | utility | transform | `docs/operator-ui.md` | exact |
| `docs/troubleshooting.md` | utility | transform | `docs/troubleshooting.md` | exact |
| `.planning/QUALITY-EVALUATION.md` | utility | transform | `.planning/QUALITY-EVALUATION.md` + Phase 37/38 summaries | exact |
| `.planning/phases/39-adoption-proof/39-03-SUMMARY.md` or closeout artifact if planner chooses | utility | transform | `.planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md` | role-match |
| `test/parapet/operator_ui_integration_test.exs` | test | transform | `test/parapet/operator_ui_integration_test.exs` | exact |
| `test/mix/tasks/parapet.archive_test.exs` | test | file-I/O | `test/mix/tasks/parapet.archive_test.exs` | role-match |

## Pattern Assignments

### `README.md` (utility, transform)

**Analog:** `README.md`

**First-contact docs pattern** (lines 53-77):
````markdown
Then install and configure Parapet with the single Day-1 entrypoint:

```bash
mix deps.get
mix parapet.install
```

`mix parapet.install` composes the core paved road in order:
...
If you want the shortest explanation of what Parapet is trying to help an adopter do, read [Parapet Adopter Flows](docs/adopter-flows.md).
````

**Operator UI concise pointer pattern** (lines 174-178):
```markdown
### 5. Operator UI Workbench

Parapet can generate an optional, evidence-first LiveView operator workbench directly inside your host application. This UI is not part of the default install path unless you opt in with `mix parapet.install --with-ui`, and it remains host-owned.

For instructions on generating the UI and securing its routes, see the [Operator UI Guide](docs/operator-ui.md).
```

**Apply:** Add short archive maintenance and scoped UI adoption pointers without turning README into a full operations manual. Include `mix parapet.archive`, `mix parapet.archive --days 30`, `mix parapet.archive --path priv/parapet/archive.jsonl`, default path, and links to `docs/operator-ui.md` / `docs/troubleshooting.md`.

---

### `docs/operator-ui.md` (utility, transform)

**Analog:** `docs/operator-ui.md`

**Auth/ownership pattern** (lines 47-50):
```markdown
### Mounting the Operator UI

The generated files belong to your application. The UI is only relevant when Phoenix LiveView is present, and Parapet does **not** provide its own authentication system. You must mount the operator routes inside your application's authenticated scope to ensure the UI is secured according to your app's existing authorization policies.
```

**Default route example pattern** (lines 53-70):
```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do

    live "/parapet", MyAppWeb.Parapet.OperatorLive, :index
    live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions
    live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history
    live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
    live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
  end
end
```

**Scoped route example pattern** (lines 73-90):
```elixir
scope "/ops", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do

    live "/parapet", MyAppWeb.Parapet.OperatorLive, :index
    live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions
    live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history
    live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
    live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
  end
end
```

**Generated link-helper pattern** (lines 93-95):
```markdown
The route map keeps `/parapet` as the active-response overview, `/parapet/actions` as pending recovery work, and `/parapet/history` as resolved incident review. /parapet/incidents/:id is the preferred incident detail route, while /parapet/:id remains available for compatibility with existing deep links.

Generated local links derive from the current LiveView URI through the generated `operator_base_path` helper, so the same editable host-owned files render links for `/parapet` or nested mounts such as `/ops/parapet`. Host app scopes, pipelines, authentication, and authorization remain owner-controlled.
```

**Apply:** Keep `/ops/parapet` as the canonical nested example. Add a short gotchas block for stale generated files, missing auth/live_session protection, and partial nested mounts that break local links. Do not add generator flags, Parapet router modules, auth ownership, or stable public API claims.

---

### `docs/troubleshooting.md` (utility, transform)

**Analog:** `docs/troubleshooting.md`

**Q&A support style pattern** (lines 1-5):
```markdown
# Parapet Troubleshooting

This guide answers common obstacles you may hit after following [Parapet Getting Started](docs/getting-started.md). Each section names the exact surface involved so you can confirm the fix against your specific setup.

For UI-specific doctor checks, see [Parapet Operator UI Guide](docs/operator-ui.md).
```

**Command and recovery-step pattern** (lines 63-75):
````markdown
## Prometheus target is blank

If Prometheus shows no metrics from your app, the most common causes are a missing metrics plug and a missing `/metrics` route or reporter.

Run the doctor to check both:

```bash
mix parapet.doctor
```

The doctor's `endpoint` check reads your `endpoint.ex` and emits a `:warn` finding if `Parapet.Plug.Metrics` is not present. The `router` check looks for an exposed `/metrics` route.
````

**Operational warning pattern** (lines 77-88):
````markdown
## The doctor reports a warning but I am not sure if CI will fail

The doctor uses a severity model with three levels: `info` (0), `warn` (1), `error` (2). Which severity causes an exit code of `1` depends on the threshold in effect.

```bash
mix parapet.doctor        # threshold :error - exits 1 only on :error findings
mix parapet.doctor --ci   # threshold :warn  - exits 1 on :warn OR :error findings (stricter)
```
````

**Apply:** Add focused sections with headings a stranger would search for. Cover archive write, manifest, publish, delete-stage failures, missing `:parapet, :repo`, invalid `--days`/`--path` usage, and safe reruns. Add scoped UI troubleshooting for stale generated files, missing auth scope/live session, and partial `/ops/parapet` mounts.

---

### `.planning/QUALITY-EVALUATION.md` (utility, transform)

**Analog:** `.planning/QUALITY-EVALUATION.md` plus completed phase summaries.

**Original risk-source pattern** (lines 7-22):
```markdown
## 1. Executive Summary

**Weakest dimension:** Reliability, resilience, and durable evidence truth model
**Score:** 2
**Why weakest:** Parapet's core promise is evidence operators can trust. The audit found paths where durable evidence can drift from runtime truth...

**Second-weakest dimension:** Host-app compatibility and generated UI integration
**Score:** 2
**Why:** Generated UI code still assumes literal `/parapet` paths while docs recommend mounting under authenticated host scopes such as `/admin`.

**Third-weakest dimension:** Adoption-path truth
**Score:** 2
```

**Do-not-overclaim pattern** (lines 78-92):
```markdown
**First fixes:** Release failed claims immediately, return per-alert batch failures, and design a durable archive manifest/staging flow before expanding archive use.

**Do not over-fix:** Do not build a full backup system. The host app owns database backups; Parapet only needs its archive/delete semantics to be honest.
...
**Do not over-fix:** Do not invent a routing framework. Keep the generated code inspectable and host-owned.
```

**Phase evidence pattern** (`.planning/phases/37-archive-durability/37-03-SUMMARY.md` lines 54-61):
```markdown
## Accomplishments

- Documented `archive/3` returning `{:ok, %Summary{}}` and `{:error, %Failure{}}` in `Parapet.Evidence.Archiver` moduledoc.
- Documented the archive boundary as Parapet-owned evidence export/prune, not host backup/restore.
- Documented the retention limitation: resolved incidents created before cutoff via `inserted_at < cutoff`, not resolved-before-cutoff semantics.
- Added an Unreleased changelog note for the Experimental archive return-shape change and CLI failure behavior.
- Closed the verifier's D-15 gap by adding encode failure, verification mismatch, manifest failure, and delete-stage rerun/idempotency tests.
```

**Phase evidence pattern** (`.planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md` lines 62-67):
```markdown
## Accomplishments

- Added default `/parapet` and nested `/ops/parapet` examples to the generated router snippet and generator fallback notice.
- Updated operator UI docs with focused scoped-route mounting guidance, generated `operator_base_path` behavior, and explicit host-owned auth/router ownership.
- Added compile-out and integration guards for direct Phoenix/LiveView root deps, stable public API route-helper drift, Parapet-owned router modules, route emitter literals, and external-link handling.
- Ran the Phase 38 focused lane, formatting check, warnings-as-errors compile, full suite, dependency diff, and core router scan.
```

**Apply:** Prefer a dated addendum in `.planning/QUALITY-EVALUATION.md` that preserves the audit snapshot and states which named top risks are closed by Phase 37, Phase 38, and Phase 39 evidence. Do not say every quality-evaluation item is closed.

---

### `.planning/phases/39-adoption-proof/39-03-SUMMARY.md` or closeout artifact (utility, transform)

**Analog:** `.planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md`

**Frontmatter pattern** (lines 1-15):
```markdown
---
phase: 38-scoped-ui-routes
plan: 03
subsystem: ui
tags: [phoenix-liveview, generated-ui, route-scoping, compile-out, public-api]

requires:
  - phase: 38-scoped-ui-routes
    provides: Generated and demo scoped Operator UI route behavior from Plans 01 and 02
provides:
  - Generator router guidance for default `/parapet` and nested `/ops/parapet` host-owned mounts
  - Focused operator docs for scoped mounting through generated `operator_base_path`
  - Static guards for compile-out, public API, dependency, router ownership, route emitters, and external links
affects: [generated-operator-ui, operator-ui-docs, host-route-scopes, UIROUTE-01, UIROUTE-02, UIROUTE-03]
```

**Closeout evidence pattern** (lines 76-83):
```markdown
## Files Created/Modified

- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` - Adds default and `/ops` scoped host-owned route examples.
- `lib/mix/tasks/parapet.gen.ui.ex` - Keeps fallback router notice in parity with the template without changing CLI shape.
- `docs/operator-ui.md` - Documents default and scoped mounts plus generated local-link derivation.
- `test/mix/tasks/parapet.gen.ui_test.exs` - Pins generator notices and formatted scoped helper assertions.
- `test/parapet/operator_ui_integration_test.exs` - Pins docs/guidance, route emitter guards, and external-link behavior.
```

**Apply:** Only use a separate closeout artifact if the planner chooses not to append directly to `.planning/QUALITY-EVALUATION.md`. It must link back to the quality evaluation and distinguish closed Phase 37/38/39 risks from unrelated open risks.

---

### `test/parapet/operator_ui_integration_test.exs` (test, transform)

**Analog:** `test/parapet/operator_ui_integration_test.exs`

**Docs guard pattern** (lines 331-354):
```elixir
test "operator UI docs show preferred and compatibility route map" do
  content = File.read!("docs/operator-ui.md")

  for route <- [
        ~S|live "/parapet", MyAppWeb.Parapet.OperatorLive, :index|,
        ~S|live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions|,
        ~S|live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history|,
        ~S|live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|,
        ~S|live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|
      ] do
    assert content =~ route
  end

  assert content =~ "/parapet/incidents/:id is the preferred incident detail route"
  assert content =~ "/parapet/:id remains available for compatibility"
  assert content =~ "Parapet does **not** provide its own authentication system"
  assert content =~ "Default mount: `/parapet`"
  assert content =~ "Scoped mount: `/ops/parapet`"
  assert content =~ ~S|scope "/ops", MyAppWeb do|
  assert content =~ "generated `operator_base_path` helper"
end
```

**Boundary guard pattern** (lines 394-404):
```elixir
test "UI stays generator-first and host-owned" do
  # Parapet must not define its own Plug.Router or Phoenix.Router for the UI.
  core_files = Path.wildcard("lib/parapet/**/*.ex")

  for file <- core_files do
    content = File.read!(file)
    refute content =~ "use Phoenix.Router", "Found Phoenix.Router in core file: \#{file}"
    refute content =~ "use Plug.Router", "Found Plug.Router in core file: \#{file}"
  end
end
```

**Apply:** If docs changes need tests, add narrow string assertions here for operator UI docs/troubleshooting cross-links and scoped gotchas. Keep tests focused on durable claims, not every prose sentence.

---

### `test/mix/tasks/parapet.archive_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/parapet.archive_test.exs`

**CLI summary shape pattern** (lines 214-242):
```elixir
test "parses CLI args, invokes the archiver, and prints summary JSON", %{
  archive_path: archive_path,
  archived_id: archived_id
} do
  assert :ok = Archive.run(["--days", "90", "--path", archive_path])

  assert_receive {:mix_shell, :info, [output]}

  assert %{
           "status" => "ok",
           "run_id" => @run_id,
           "manifest_path" => manifest_path,
           "selected_count" => 1,
           "archived_count" => 1,
           "deleted_count" => 1,
           "bytes_written" => bytes_written,
           "checksum" => checksum
         } = Jason.decode!(output)
end
```

**Failure-message shape pattern** (lines 259-277):
```elixir
test "raises with archive failure context and emits no success JSON", %{
  archive_path: archive_path
} do
  FakeRepo.set_delete_result({0, nil})

  error =
    assert_raise Mix.Error, fn ->
      Archive.run(["--days", "90", "--path", archive_path])
    end

  assert error.message =~ "Archive failed"
  assert error.message =~ "stage=delete_records"
  assert error.message =~ "run_id=#{@run_id}"
  assert error.message =~ "selected=1"
  assert error.message =~ "archived=1"
  assert error.message =~ "deleted=0"
  assert error.message =~ "manifest_path=#{archive_path}.#{@run_id}.manifest.json"
end
```

**Apply:** Use this as factual source for docs copy and optional docs guards. Do not change archive runtime. If adding README/troubleshooting assertions, pin only the fields Phase 39 promises: `status`, `run_id`, `path`, `manifest_path`, `retention_days`, `selected_count`, `archived_count`, `deleted_count`, `skipped_count`, `bytes_written`, `checksum`, and failure `stage`.

## Shared Patterns

### Archive CLI Truth
**Source:** `lib/mix/tasks/parapet.archive.ex`
**Apply to:** `README.md`, `docs/troubleshooting.md`, optional docs tests
```elixir
@default_days 90
@default_path "priv/parapet/archive.jsonl"

{opts, _, _} = OptionParser.parse(args, switches: [days: :integer, path: :string])

repo = Application.fetch_env!(:parapet, :repo)
days = Keyword.get(opts, :days, @default_days)
path = Keyword.get(opts, :path, @default_path)
```

### Archive Success And Failure Fields
**Source:** `lib/mix/tasks/parapet.archive.ex`
**Apply to:** `README.md`, `docs/troubleshooting.md`
```elixir
%{
  status: "ok",
  run_id: summary.run_id,
  path: summary.path,
  manifest_path: summary.manifest_path,
  retention_days: summary.retention_days,
  cutoff: encode_time(summary.cutoff),
  selected_count: summary.selected_count,
  archived_count: summary.archived_count,
  deleted_count: summary.deleted_count,
  skipped_count: summary.skipped_count,
  bytes_written: summary.bytes_written,
  checksum: summary.checksum
}
```

```elixir
[
  "Archive failed",
  "stage=#{failure.stage}",
  "path=#{failure.path || summary_value(summary, :path)}",
  "run_id=#{failure.run_id || summary_value(summary, :run_id)}",
  "selected=#{summary_value(summary, :selected_count)}",
  "archived=#{summary_value(summary, :archived_count)}",
  "deleted=#{summary_value(summary, :deleted_count)}",
  "manifest_path=#{failure.manifest_path || summary_value(summary, :manifest_path)}",
  "reason=#{inspect(failure.reason)}"
]
```

### Router Guidance Parity
**Source:** `priv/templates/parapet.gen.ui/router_snippet.ex.eex`
**Apply to:** `README.md`, `docs/operator-ui.md`, `docs/troubleshooting.md`, UI docs tests
```elixir
# Ensure you place these routes inside an existing authenticated scope,
# or define a new pipeline with your app's standard authentication plugs.
# Parapet does not provide its own auth.
#
# Default mount: /parapet
...
# Scoped mount: /ops/parapet
```

### Docs Test Scope
**Source:** `test/parapet/operator_ui_integration_test.exs`
**Apply to:** optional docs tests
```elixir
content = File.read!("docs/operator-ui.md")

for route <- [
      ~S|live "/parapet", MyAppWeb.Parapet.OperatorLive, :index|,
      ~S|live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions|,
      ~S|live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history|,
      ~S|live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|,
      ~S|live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|
    ] do
  assert content =~ route
end
```

## No Analog Found

None. All likely docs/proof files have close existing analogs. If the planner chooses a new closeout artifact instead of editing `.planning/QUALITY-EVALUATION.md`, use the Phase 38 summary frontmatter and closeout structure as the role-match analog.

## Metadata

**Analog search scope:** `README.md`, `docs/`, `.planning/QUALITY-EVALUATION.md`, `.planning/phases/37-archive-durability/`, `.planning/phases/38-scoped-ui-routes/`, `test/`, `lib/mix/tasks/parapet.archive.ex`, `priv/templates/parapet.gen.ui/`
**Files scanned:** 200+ paths from README/docs/planning/test/lib/template surfaces; 11 strong analogs read or line-located
**Pattern extraction date:** 2026-06-04
