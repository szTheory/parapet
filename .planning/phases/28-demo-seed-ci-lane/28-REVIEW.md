---
phase: 28-demo-seed-ci-lane
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex
  - examples/demo_app/lib/demo_app/recovery/retry_async_item.ex
  - examples/demo_app/lib/demo_app/application.ex
  - examples/demo_app/priv/repo/seeds.exs
  - examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs
  - examples/demo_app/mix.exs
  - examples/demo_app/test/demo_app/recovery_loop_test.exs
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 28: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The implementation covers a demo app exercising Parapet's Preview/Confirm recovery loop via a
`StalledExecutor` runbook, a `RetryAsyncItem` capability, migration for `parapet_action_claims`,
seeds populating four incidents, and four ExUnit scenarios.

Two blockers were found. The more serious is a select-then-update race in `RetryAsyncItem.execute/2`
that is not wrapped in a transaction, allowing a concurrent confirm to double-update or miss the row
entirely. The second blocker is that the test inserts an `ActionItem` with `kind: "async_item"`, a
value that does not appear in the `@kinds` allowlist on `Parapet.Spine.ActionItem`; the current
migration has no DB-level CHECK constraint, so the invalid kind silently persists and the test
exercises a code path the schema explicitly rejects. Three warnings round out the findings.

---

## Critical Issues

### CR-01: Select-then-update in `execute/2` is not atomic — concurrent confirms can double-update or skip the row

**File:** `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex:28-45`

**Issue:** `execute/2` uses a two-step pattern: `Repo.one/1` (select the first open item's id),
then `Repo.update_all/2` (update by that id). The two statements run in separate database
round-trips with no enclosing transaction and no `SELECT ... FOR UPDATE` lock. In the narrow
window between the `one/1` return and the `update_all/2` execution, a second concurrent
confirmation of the same incident (e.g. two operators racing, or a stale claim that gets stolen
and retried) can independently select the same `item_id` and run both updates. The result is that
`state` is set to `"retrying"` twice (harmless per-row, but the `retried_count` the two callers
each return is `{1, _}`, masking the race), or — if the item was concurrently resolved between
the two calls — the `update_all` can match zero rows and return `{0, _}` while the function still
returns `{:ok, %{retried_count: 0}}`, which is indistinguishable from "no open items found" and
loses the intent.

The `ClaimService` claim mechanism provides outer serialisation per `(incident_id, action_kind,
action_key)`, but `execute/2` is an adopter callback invoked _inside_ the won-claim window. A
second concurrent actor winning a _different_ claim key (or a stale lease being stolen and
re-executed) bypasses that guard.

**Fix:** Wrap the select-and-update in a single `Repo.transaction/1` call and acquire a row-level
lock via `FOR UPDATE SKIP LOCKED` on the select:

```elixir
def execute(incident, _target_refs) do
  import Ecto.Query

  DemoApp.Repo.transaction(fn ->
    case DemoApp.Repo.one(
           from(a in Parapet.Spine.ActionItem,
             where: a.incident_id == ^incident.id and a.state == "open",
             limit: 1,
             lock: "FOR UPDATE SKIP LOCKED",
             select: a.id
           )
         ) do
      nil ->
        %{retried_count: 0, note: "no open items found"}

      item_id ->
        {n, _} =
          DemoApp.Repo.update_all(
            from(a in Parapet.Spine.ActionItem, where: a.id == ^item_id),
            set: [state: "retrying"]
          )

        %{retried_count: n}
    end
  end)
  |> case do
    {:ok, result} -> {:ok, result}
    {:error, reason} -> {:error, reason}
  end
end
```

The `SKIP LOCKED` clause also prevents two concurrent transactions from selecting the same row
and blocking each other; the second transaction skips already-locked rows and either picks a
different open item or returns nil.

---

### CR-02: Test inserts `ActionItem` with `kind: "async_item"` — a value not in `@kinds` allowlist

**File:** `examples/demo_app/test/demo_app/recovery_loop_test.exs:27`

**Issue:** The setup block directly inserts a struct `%Parapet.Spine.ActionItem{kind: "async_item",
...}` via `Repo.insert/1`. Because this bypasses the changeset, `validate_inclusion(:kind, @kinds)`
never fires. The `@kinds` list in `Parapet.Spine.ActionItem` is:

```
["exact_follow_up", "suppressed_delivery", "stalled_workflow",
 "orphaned_callback", "dead_letter"]
```

`"async_item"` is absent. There is no DB-level `CHECK` constraint on the `kind` column (migration
000001 adds the column as plain `:string`), so the insert succeeds silently. The test therefore
exercises `execute/2` against a row the schema does not officially recognise. If `@kinds` ever
gains a DB `CHECK` constraint (a natural hardening step), this setup will begin failing with an
obscure Postgres error rather than a clear test error.

Two sub-consequences:
1. The `execute/2` filter `where: a.state == "open"` works regardless of `kind`, so the happy-path
   test passes, but the test is exercising an invalid fixture.
2. The `target_kind: :async_item` on the runbook step implies this is a deliberate concept that
   simply has not been added to `@kinds`.

**Fix:** Add `"async_item"` to `@kinds` in `Parapet.Spine.ActionItem` to legitimise the concept,
or — if `"async_item"` is intentionally out of scope — replace the test fixture with a valid kind
(e.g. `"stalled_workflow"`) and update the runbook step's `target_kind` accordingly:

```elixir
# Option A: in lib/parapet/spine/action_item.ex
@kinds [
  "exact_follow_up",
  "suppressed_delivery",
  "stalled_workflow",
  "orphaned_callback",
  "dead_letter",
  "async_item"          # add this
]

# Option B: in the test setup, use a valid kind
kind: "stalled_workflow",
```

---

## Warnings

### WR-01: `execute/2` writes state `"retrying"` which is outside the `ActionItem` changeset state machine

**File:** `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex:41-43`

**Issue:** `update_all` sets `state: "retrying"` directly in SQL, bypassing the changeset.
`ActionItem.changeset/2` validates `state` as one of `["open", "resolved"]`, so `"retrying"` is an
undeclared state. No DB `CHECK` constraint enforces the allowed states either. Items left in
`"retrying"` will be invisible to the `action_items_query` (which filters `state == "open"`) and
invisible to any query filtering `state == "resolved"`. If the underlying job backend never
transitions the item back to a terminal state, the row becomes permanently orphaned in a grey state
that no query surface handles.

**Fix:** Either add `"retrying"` to the `ActionItem` state machine (changeset + migration CHECK
constraint), or transition to `"resolved"` once the retry is dispatched (if the item's lifecycle
ends at the dispatch point):

```elixir
# If "retrying" is a legitimate transit state, declare it:
# In Parapet.Spine.ActionItem:
|> validate_inclusion(:state, ["open", "retrying", "resolved"])

# And in the migration (optional but recommended):
execute("ALTER TABLE parapet_action_items ADD CONSTRAINT action_items_state_check
         CHECK (state IN ('open', 'retrying', 'resolved'))")
```

---

### WR-02: `find_recent_preview` crashes on malformed `expires_at` string with a `MatchError`

**File:** `lib/parapet/operator.ex:1078` (library code, exercised by the test)

**Issue:** The `binary` branch in `find_recent_preview` does:

```elixir
{:ok, dt, _} = DateTime.from_iso8601(str)
```

`DateTime.from_iso8601/1` returns `{:error, reason}` for a non-ISO-8601 string. The bare
`= ...` match raises `MatchError` instead of returning `{:error, :mismatched_preview}`. This
exception is raised inside the `with` chain of `confirm_runbook_step/4`, outside the
`try/rescue` block that only wraps `capability.execute/2`, so it propagates uncaught and will
crash the calling LiveView process.

In the test this never fires because the aging fragment writes a `DateTime.to_iso8601/1`-produced
string. But any external write to the `payload` column (admin tooling, a migration, a manual
`psql` fix) that stores a non-standard datetime string would make every `confirm` call against that
incident raise rather than returning a safe `{:error, ...}`.

**Fix:**

```elixir
str when is_binary(str) ->
  case DateTime.from_iso8601(str) do
    {:ok, dt, _} -> dt
    _ -> DateTime.utc_now()   # treat unparseable as already-expired (safe-fail)
  end
```

---

### WR-03: Scenario 1 ToolAudit assertion does not verify incident scope — passes vacuously if any prior audit exists

**File:** `examples/demo_app/test/demo_app/recovery_loop_test.exs:67-70`

**Issue:**

```elixir
assert DemoApp.Repo.exists?(
  from a in Parapet.Spine.ToolAudit,
    where: a.tool_name == "operator_confirm_recovery"
)
```

The query has no `incident_id` or `timeline_entry_id` predicate. Within the Ecto sandbox the test
is isolated, so in practice this will only match the audit written by this test's confirm. However,
the assertion proves nothing more than "some confirm_recovery audit exists anywhere in the sandbox
transaction." If the test setup were ever changed to inherit pre-existing data (e.g. moved to
`:shared` sandbox or a module-level `setup_all`), this assertion would pass even if the confirm
itself failed to write the audit.

**Fix:** Scope the assertion to the specific incident:

```elixir
assert DemoApp.Repo.exists?(
  from a in Parapet.Spine.ToolAudit,
    join: t in Parapet.Spine.TimelineEntry,
    on: a.timeline_entry_id == t.id,
    where: t.incident_id == ^incident.id and a.tool_name == "operator_confirm_recovery"
)
```

---

## Info

### IN-01: `DemoAppWeb.ConnCase` used for a test that exercises no HTTP/LiveView surface

**File:** `examples/demo_app/test/demo_app/recovery_loop_test.exs:2`

**Issue:** `use DemoAppWeb.ConnCase` imports `Plug.Conn`, `Phoenix.ConnTest`, and
`Phoenix.LiveViewTest`, none of which are used in `recovery_loop_test.exs`. The test is a
pure Ecto/Operator integration test. Using `ConnCase` is not wrong — the sandbox setup it
provides is exactly what the test needs — but it adds unused compile-time imports that will
trigger Elixir warnings when `--warnings-as-errors` is enabled.

**Fix:** Create a `DemoApp.DataCase` (Ecto sandbox without Phoenix imports) and use it here, or
simply note the unused imports. If `DataCase` doesn't yet exist in the demo app, the minimal
version is:

```elixir
defmodule DemoApp.DataCase do
  use ExUnit.CaseTemplate

  setup _tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DemoApp.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DemoApp.Repo, {:shared, self()})
    :ok
  end
end
```

---

### IN-02: Seeds `IO.puts` count message will mislead if seed content changes

**File:** `examples/demo_app/priv/repo/seeds.exs:138`

**Issue:**

```elixir
IO.puts("Seeds complete: 4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 tool audit")
```

The message is a hardcoded string. The actual breakdown is: 4 incidents, 6 timeline entries (2
for incident 1, 2 for incident 2, 2 for incident 3 — incident 4 has 1 entry = 7 total; counting
is technically correct now), 1 tool audit. The count is fine today, but any future change to seed
content will leave the message stale without a compile-time error. This is a maintenance hazard in
a demo context where the seeds file is the first thing new adopters run.

**Fix:** Either omit the count message or derive counts from the actual insert results:

```elixir
IO.puts("Seeds complete.")
```

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
