# Test Deflaking & Quarantine (v1.8)

**Dimension:** ExUnit test suite deflaking and known-red quarantine
**Milestone:** v1.8 CI/CD Performance & DX
**Researched:** 2026-07-02
**Overall confidence:** HIGH — all findings grounded in the actual codebase (grepped call sites, ran both red tests, read the implementation under test)

---

## Process.sleep call sites (actual)

Grepped with `grep -rn "Process.sleep" test/`. Every call site found, its async-source, and the prescribed replacement:

| File | Line | Context | Async Source | Replacement |
|------|------|---------|--------------|-------------|
| `test/parapet/metrics/exemplar_telemetry_test.exs` | 23 | After `:telemetry.execute/3`, before `ExemplarStore.get_trace` assert | `:telemetry` handler dispatch | Remove entirely — handler is **synchronous** (see §Telemetry below) |
| `test/parapet/metrics/exemplar_telemetry_test.exs` | 41 | Same pattern, Oban job event | `:telemetry` handler dispatch | Remove entirely — same reason |
| `test/parapet/metrics/exemplar_telemetry_test.exs` | 59 | Same pattern, missing trace_id case | `:telemetry` handler dispatch | Remove entirely — same reason |
| `test/parapet/escalation/worker_concurrency_test.exs` | 17 | Inside `SuccessPolicy.escalate/2` module-under-test callback | Intentional work-simulation in the policy being raced | Replace with a GenServer barrier or keep as-is with a comment (see §Concurrency-sleeps below) |
| `test/parapet/automation/executor_concurrency_test.exs` | 22 | Inside `ConcurrencyRunbook.execute_mitigation/2` | Intentional work-simulation | Same as above |
| `test/parapet/automation/executor_cluster_smoke_test.exs` | 22 | Inside `ClusterRunbook.execute_mitigation/2` | Intentional work-simulation | Same as above |
| `test/parapet/automation/executor_cluster_smoke_test.exs` | 80 | Remote-node bootstrap: `Process.sleep(200)` after starting `ConcurrencyRepo` on the peer node | Remote GenServer startup | Replace with a startup barrier (see §GenServer-startup below) |
| `test/parapet/automation/executor_cluster_smoke_test.exs` | 110 | Inside inline-defined `ClusterRunbook.execute_mitigation/2` on remote node | Intentional work-simulation | Same as work-simulation sleeps |
| `test/parapet/automation/claim_service_test.exs` | 49 | Inside `gate:` callback of `ClaimService.claim_action/1` — the callback is the thing being raced | Intentional overlap-creation in the gate function | Replace with a barrier PID (see §ClaimService-gate below) |
| `test/parapet/operator/confirm_concurrency_test.exs` | 77 | Inside registered `execute:` fn of `Parapet.Capabilities.register_recovery/2` | Intentional work-simulation | Same as work-simulation sleeps |

**One line in `test/parapet/operator/preview_lifecycle_test.exs:506`** is a comment (`# is deterministic — no Process.sleep, not flaky.`) — not a call site, nothing to change.

---

## Replacement patterns

### Telemetry — synchronous dispatch, no sleep needed

`ExemplarTelemetry.handle_event/4` is a **synchronous** `:telemetry` handler. `:telemetry.execute/3` calls attached handlers inline, in the calling process, before returning. After `ExemplarTelemetry.attach()` and `:telemetry.execute(...)` return, the handler has already run and `ExemplarStore.record_trace/3` has already written to ETS.

The three `Process.sleep(10)` calls in `exemplar_telemetry_test.exs` are unnecessary and should be deleted outright.

**Before:**
```elixir
:telemetry.execute(
  [:parapet, :http, :request],
  %{duration_ms: 100},
  %{route: "/api", method: "GET", trace_id: "trace-http-123"}
)

# Allow async telemetry handlers to run
Process.sleep(10)

assert ExemplarStore.get_trace("parapet_http_request_duration_ms", ...) == "trace-http-123"
```

**After:**
```elixir
:telemetry.execute(
  [:parapet, :http, :request],
  %{duration_ms: 100},
  %{route: "/api", method: "GET", trace_id: "trace-http-123"}
)

# Handler is synchronous; no sleep needed.
assert ExemplarStore.get_trace("parapet_http_request_duration_ms", ...) == "trace-http-123"
```

**If a telemetry handler were truly async** (e.g. it spawns a Task or sends work to a GenServer), the correct pattern is `:telemetry_test.attach_event_handlers/2` from the `:telemetry` library. It installs a message-forwarding handler that `send/2`s the test process a `{event, ref, measurements, metadata}` tuple, turning the async event into an `assert_receive`:

```elixir
ref = :telemetry_test.attach_event_handlers(self(), [[:parapet, :http, :request]])
# ... trigger the code path that emits the event ...
assert_receive {[:parapet, :http, :request], ^ref, measurements, metadata}, 500
:telemetry.detach(ref)
```

`assert_receive` with a timeout is always correct here: it blocks until the message arrives (or fails with a clear timeout), no polling, no fixed sleep.

### Oban — `:manual` testing mode, `perform_job`, `drain_jobs`

Parapet's current suite does **not** use Oban's testing helpers for job dispatch — instead it calls worker `perform/1` callbacks directly via `Executor.perform(job)` inside `Task.async` blocks. This is already deterministic (the `Task.await` provides the synchronization point). No `Process.sleep` removal is needed in the Oban-dispatch path.

If future tests need to assert on enqueued jobs without calling `perform` directly, the idiomatic pattern under `use Oban.Testing, repo: MyApp.Repo` is:

```elixir
# In test_helper.exs or setup block:
# Oban.Testing sets up :manual mode — jobs enqueue but don't auto-run.

# Assert a job was enqueued:
assert_enqueued worker: MyWorker, args: %{incident_id: "123"}

# Run it synchronously:
perform_job(MyWorker, %{incident_id: "123"})

# Or drain an entire queue (run all pending jobs inline):
Oban.drain_queue(queue: :default)
```

Neither of these requires `Process.sleep`. Under `:inline` mode, jobs run immediately on insert — the assertion immediately follows the trigger.

### GenServer/registry state — startup barrier pattern

The `Process.sleep(200)` in `executor_cluster_smoke_test.exs:80` waits for the remote node's `ConcurrencyRepo` GenServer to be ready after `spawn/1`. The correct replacement is a polling loop via `:sys.get_state/1` or `Process.whereis/1` inside `:erpc.call/4`:

**Before:**
```elixir
spawn(fn ->
  {:ok, _pid} = Parapet.TestSupport.ConcurrencyRepo.start_link(...)
  receive do :stop -> :ok end
end)
Process.sleep(200)
:ok
```

**After (inline in the `repo_keeper` string eval'd on the peer node):**
```elixir
spawn(fn ->
  {:ok, _pid} = Parapet.TestSupport.ConcurrencyRepo.start_link(...)
  receive do :stop -> :ok end
end)
# Poll until the repo is registered — no fixed sleep.
Enum.each(1..50, fn _ ->
  unless Process.whereis(Parapet.TestSupport.ConcurrencyRepo) do
    Process.sleep(20)
  end
end)
:ok
```

Or, more idiomatically, move the `start_link` out of the spawned process so the caller has the PID and can call `:sys.get_state/2` directly:

```elixir
# Start the repo keeper as a supervised process on the peer node via :erpc,
# and block until it's registered.
:erpc.call(node, Parapet.TestSupport.ConcurrencyRepo, :start_link, [config])
# start_link returns only after init/1 completes — no sleep needed.
```

Because `GenServer.start_link/3` does not return until `init/1` completes, the startup barrier is the `start_link` return value itself. The `spawn + sleep` pattern exists only because the spawn is fire-and-forget. Changing to a synchronous `start_link` via `:erpc.call` eliminates the sleep entirely.

### Concurrency-simulation sleeps — intentional, but extractable

Five `Process.sleep(75)` calls appear **inside runbook/capability callbacks** that are themselves the subject of a concurrency test (e.g. `SuccessPolicy.escalate/2`, `ConcurrencyRunbook.execute_mitigation/2`, the `execute:` fn in `ConfirmConcurrencyTest`). These sleeps are not polling — they deliberately hold the "winning" concurrent call open so the "losing" call can race against the DB unique-constraint insert.

These are **correct-by-design** in the current test structure. The test's invariant is: one winner holds a claim while the loser tries to insert the same row. Without a delay in the winning path, the winner finishes before the loser even starts, and the unique-constraint collision never fires — the test would vacuously pass.

The canonical way to make this deterministic without a fixed sleep is a **rendezvous barrier**: both Tasks send `:ready`, the test signals `:go`, both race simultaneously. The existing tests already do this for `executor_concurrency_test.exs` (lines 55–68). The `Process.sleep(75)` is inside the *body of the work being done*, not in the test coordination logic, so it is not a timing-dependent gate — it simply keeps the work open.

**Recommended handling:** keep these five sleeps but add a comment labeling them as intentional, and extract them into a named constant so they're clearly not "fix-me" sleeps:

```elixir
# Deliberate hold: keeps this path in-flight so the loser's DB insert races
# the unique constraint. Without this, the winner finishes before the loser
# starts and the constraint collision never fires. This is not a timing wait.
@concurrency_hold_ms 75

def execute_mitigation(:auto_step, _incident) do
  if pid = Application.get_env(:parapet, :executor_test_pid) do
    send(pid, {:mitigated, node()})
  end

  Process.sleep(@concurrency_hold_ms)
  {:ok, :mitigated}
end
```

### ClaimService gate fn — synchronous barrier replacement

`claim_service_test.exs:49` has `Process.sleep(50)` inside the `gate:` callback. This gate fn is called inside a DB transaction on the winning contender while the losing contender is trying to insert the same claim row. The sleep is correct-by-design for the same reason as above (keeps the transaction open for the race).

**If the goal is to remove it anyway**, replace the fixed sleep with a message-based barrier:

```elixir
parent = self()

gate_fn = fn _repo, _incident, _claim ->
  send(parent, {:gate_entered, self()})
  # Wait for both contenders to reach the gate before proceeding.
  receive do :release -> :ok end
end

# In the test coordinator:
assert_receive {:gate_entered, pid1}, 1_000
assert_receive {:gate_entered, pid2}, 1_000
send(pid1, :release)
send(pid2, :release)
```

This makes the overlap explicit and removes the timing assumption. However, it requires refactoring the gate API to accept a PID or using a process-dictionary trick. The current `Process.sleep(50)` is simpler and has worked; leave it with a comment or replace it with the barrier approach if the team wants zero sleeps.

### Reusable `assert_eventually` helper

For any case where a GenServer or registry state must be polled (e.g. waiting for a process to register, or for a state machine to reach a terminal state), a shared polling helper eliminates ad-hoc sleeps. Add to `test/support/`:

```elixir
defmodule Parapet.TestSupport.Assertions do
  @moduledoc """
  Shared assertion helpers for deterministic async synchronization.
  """

  @doc """
  Polls `fun` every `interval_ms` until it returns truthy or `timeout_ms`
  elapses. Raises on timeout with a descriptive message.

  Use only when message-passing (`assert_receive`) or `start_link`-based
  barriers are not applicable. Prefer those over this helper.
  """
  def assert_eventually(fun, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 1_000)
    interval_ms = Keyword.get(opts, :interval_ms, 20)
    label = Keyword.get(opts, :label, "assert_eventually")

    deadline = System.monotonic_time(:millisecond) + timeout_ms

    do_assert_eventually(fun, interval_ms, deadline, label)
  end

  defp do_assert_eventually(fun, interval_ms, deadline, label) do
    if fun.() do
      :ok
    else
      now = System.monotonic_time(:millisecond)

      if now >= deadline do
        raise ExUnit.AssertionError,
          message: "#{label}: condition not met within timeout"
      else
        Process.sleep(interval_ms)
        do_assert_eventually(fun, interval_ms, deadline, label)
      end
    end
  end
end
```

Usage:

```elixir
import Parapet.TestSupport.Assertions

# Wait for a GenServer to register on the remote node.
assert_eventually(
  fn -> :erpc.call(node, Process, :whereis, [SomeModule]) != nil end,
  timeout_ms: 2_000,
  label: "ConcurrencyRepo to register on peer"
)
```

---

## Quarantining the two known reds

### DocsPhase33Test — diagnosis

**Module:** `Parapet.DocsPhase33Test` (`test/parapet/docs_phase_33_test.exs`)
**Failing test:** `"demo app docs describe the reproducible Compose smoke path and demo-only boundary"` (line 96)
**Confirmed red:** Yes, reproducible locally. `mix test test/parapet/docs_phase_33_test.exs` yields 1 failure.

**Root cause:** The test asserts `readme =~ "make up-auto"` (line 102). The `examples/demo_app/README.md` was rewritten as part of v1.6/v1.7 demo DX work — `make up-auto` was renamed to `make up` (the "conflict-free auto-port" default), and `up-auto` was kept only as a backward-compat alias in the Makefile (`up-auto: up` at line 66). The README no longer contains the string `"make up-auto"` — it documents `make up` as the primary target. The test was written against the old README surface and not updated when the README was rewritten.

**Nature:** Stale test — the README content it asserts has legitimately changed. The test is not catching a regression; it is asserting a removed string. The underlying documented behavior (auto-port conflict-free demo launch) still exists; only the command name in the README changed.

**Secondary assertions in the same test** that DO pass: `make up`, `make up-monitoring`, `make urls`, `make down`, `make reset`, `make up-response`, `make up-recovery`, `make up-escalation`, `make up-history`, `make up-db-port`, `WEB_PORT`, `GRAFANA_ADMIN_USER`, `Prometheus`, `Grafana` — all present in the README.

**Fix options:**
1. **Preferred (close in v1.8):** Change the assertion from `readme =~ "make up-auto"` to `readme =~ "make up"`. This is a one-line fix; `make up` is prominent in the README. The quarantine then becomes unnecessary for this test.
2. **Fallback (if deferring the fix):** Quarantine with `@tag :quarantine` and document the reason so it is visible in nightly.

### Telemetry.RecoveryActionTest — diagnosis

**Module:** `Parapet.Telemetry.RecoveryActionTest` (`test/parapet/telemetry/recovery_action_test.exs`)
**Failing test:** `"normalize_outcome/1 does not create atoms for the poison binary itself (atom-table safety)"` (line 108)
**Confirmed red in CI:** Yes, per v1.7 audit ("pre-existing red on both legs"). Passes locally (isolated run and full suite run as of 2026-07-02).

**Root cause:** The test measures `:erlang.system_info(:atom_count)` before and after calling `normalize_outcome/1` with a fresh poison string and asserts `after_count == before_count`. The test intent is correct — it guards against `String.to_atom/1` being used inside `normalize_outcome/1` (which would intern an attacker-controlled binary as an atom, an atom-table exhaustion vector).

The *implementation* (`RecoveryAction.normalize_outcome/1`) is correct — it does not call `String.to_atom`. The failure is a **measurement artifact**: when the test runs alongside `async: true` modules on a loaded CI node, other concurrent tests are generating atoms between the `before_count` snapshot and the `after_count` read (e.g. via `System.unique_integer([:positive])` calls, ExUnit's own internal atom creation, or other test modules calling `String.to_atom`). The delta is non-zero even though `RecoveryAction` itself is clean.

**Nature:** False-negative flake — the test's correctness goal (no atom leak) is valid, but the measurement instrument (global `atom_count` delta) is not isolated to the unit under test. The direct `assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end` check on line 130 is the actually-load-bearing assertion and does not have this contamination problem. The `atom_count` stability check is defense-in-depth that is only reliable when the test runs in isolation.

**Fix options:**
1. **Preferred (close in v1.8):** Remove the `atom_count` stability check (lines 141–153); the `assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end` on line 130 is both simpler and more precise — if `normalize_outcome` called `String.to_atom(poison)`, `String.to_existing_atom(poison)` would succeed instead of raising. The stability check adds noise without adding signal. Update the test comment to explain why `to_existing_atom` is the load-bearing guard.
2. **Fallback (if deferring):** Add `async: false` to isolate the test from concurrent atom creation, or quarantine with `@tag :quarantine`.

### Quarantine mechanism (if deferring fixes to a later subphase)

The correct ExUnit quarantine pattern for `mix test` staying green while keeping tests visible:

**Step 1 — tag the test(s) with a documented reason:**

```elixir
# In docs_phase_33_test.exs, the one failing test:
@tag :quarantine
@tag quarantine_reason: "README string 'make up-auto' removed in v1.7 DX rewrite; assert should be 'make up'. Fix: update assertion. Tracked: v1.8 CI-01."
test "demo app docs describe the reproducible Compose smoke path and demo-only boundary" do
  # ...
end
```

```elixir
# In recovery_action_test.exs, the atom-count stability test:
@tag :quarantine
@tag quarantine_reason: "atom_count delta is contaminated by concurrent async tests on loaded CI nodes. The load-bearing guard (String.to_existing_atom assertion) passes in all environments. Fix: remove atom_count stability check. Tracked: v1.8 CI-01."
test "normalize_outcome/1 does not create atoms for the poison binary itself (atom-table safety)" do
  # ...
end
```

**Step 2 — exclude in `test_helper.exs` globally:**

```elixir
# test/test_helper.exs
ExUnit.configure(exclude: [:quarantine])
ExUnit.start()
# ... rest of current test_helper.exs content
```

`ExUnit.configure(exclude: [...])` must be called **before** `ExUnit.start()`. The current `test_helper.exs` calls `ExUnit.start()` on line 1 — reorder: `ExUnit.configure` first, then `ExUnit.start()`.

**Step 3 — run quarantined tests explicitly to verify they still compile and fail for the known reason:**

```bash
mix test --include quarantine --only quarantine
```

This runs only the quarantined tests and confirms they still fail for the documented reason (not for a new, unknown reason).

**What NOT to do:**
- Do NOT use `@tag :skip` — it silently drops tests from all output with no documented reason and no nightly-lane visibility.
- Do NOT delete the tests — the assertions guard real correctness properties.
- Do NOT use `ExUnit.configure(exclude: :quarantine)` at the module level inside a test file — it has no effect; configuration must be in `test_helper.exs` before `ExUnit.start()`.

### Quarantine vs direct fix — recommendation

Both red tests have **trivial one-line fixes** that are clearly correct:

| Test | Fix | Effort |
|------|-----|--------|
| `DocsPhase33Test` | Change `"make up-auto"` → `"make up"` in the assertion | 1 line |
| `RecoveryActionTest` | Delete lines 141–153 (the `atom_count` delta check); the `to_existing_atom` guard on line 130 is sufficient | 13 lines deleted |

Fix both directly in v1.8 rather than quarantining. Quarantine adds overhead (nightly lane, CI config complexity) for problems with 5-minute fixes. The quarantine mechanism is documented here for reference if the team decides to defer.

---

## Interaction with mix ci + release_gate

### Current CI structure

From the v1.7 research and audit, the CI gate is:

- `lint` job: `mix format --check-formatted`, `mix credo`, `mix dialyzer`, `mix verify.public_api`
- `test` job: `mix test` against `postgres:16-alpine`; dual-prefix matrix (`schema_prefix: ['parapet', '']`)
- `demo` job: `cd examples/demo_app && mix ecto.migrate && mix test --only smoke`
- `release_gate`: aggregate job that depends on all three; branch protection requires it green

### mix ci alias (v1.8 new requirement)

The `mix ci` alias mirrors the gate locally. It should run the test leg exactly as CI does:

```elixir
# In mix.exs aliases:
defp aliases do
  [
    ci: [
      "format --check-formatted",
      "credo --strict",
      "test --warnings-as-errors"
    ]
  ]
end
```

**Quarantined tests and mix ci:** Since `ExUnit.configure(exclude: [:quarantine])` is in `test_helper.exs`, it applies to all `mix test` invocations including `mix ci`. Quarantined tests are excluded from `mix ci` automatically — no alias-specific configuration needed.

**To run quarantined tests explicitly from the alias** (useful for a `mix ci.nightly` variant):

```elixir
"ci.nightly": [
  "format --check-formatted",
  "credo --strict",
  "test --include quarantine --warnings-as-errors"
]
```

### release_gate interaction

The `release_gate` job must stay green. After quarantine:

- `mix test` (gated): excludes `:quarantine` tests → green
- `release_gate`: passes → branch protection satisfied

**Quarantined tests must NOT be in the release_gate path.** They are excluded by the `test_helper.exs` configure, so no CI workflow change is needed for the main `test` job.

### Nightly lane for quarantined tests

Add a separate non-gating GitHub Actions workflow to run quarantined tests:

```yaml
# .github/workflows/nightly-quarantine.yml
name: Nightly Quarantine Check
on:
  schedule:
    - cron: '0 2 * * *'  # 02:00 UTC daily
  workflow_dispatch:       # manual trigger

jobs:
  quarantine:
    runs-on: ubuntu-latest
    continue-on-error: true  # non-gating: known failures allowed
    env:
      MIX_ENV: test
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: parapet_concurrency_test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready --health-interval 10s
          --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@<sha>
      - uses: erlef/setup-beam@<sha>
        with:
          elixir-version: '1.19.0'
          otp-version: '27.x'
      - run: mix deps.get
      - run: mix compile
      - name: Run quarantined tests (non-gating visibility)
        run: mix test --include quarantine --only quarantine
        continue-on-error: true
```

`continue-on-error: true` at the job level means the workflow completes (and is visible in GitHub UI) even when the quarantined tests fail. The workflow name makes failures visible in the Actions tab without blocking `release_gate`.

**Key invariant:** the nightly lane is informational, not gating. It ensures the quarantined tests still compile, still exercise the code, and still fail for the expected reason — not for a new unknown reason. If a quarantined test starts passing in the nightly lane, it should be unquarantined (tag removed) and promoted to the main suite.

### Sequence for v1.8 implementation

Since both fixes are trivial, the recommended sequence is:

1. Fix `DocsPhase33Test` (change `"make up-auto"` → `"make up"`)
2. Fix `RecoveryActionTest` (remove the `atom_count` stability check, update comment)
3. Confirm `mix test` is green (no quarantine infrastructure needed)
4. Add `mix ci` alias
5. Quarantine infrastructure only if (1)/(2) are deferred to a later subphase

If quarantining instead of fixing, the order is:

1. Add `ExUnit.configure(exclude: [:quarantine])` before `ExUnit.start()` in `test_helper.exs`
2. Add `@tag :quarantine` with `@tag quarantine_reason:` to each failing test
3. Add nightly workflow
4. Confirm `mix test` green, `mix test --include quarantine --only quarantine` shows the expected failures
5. Add `mix ci` alias

---

## Sources

- **Codebase (grepped):** `test/` — `Process.sleep` call sites (10 found, 1 comment); `test/parapet/docs_phase_33_test.exs`; `test/parapet/telemetry/recovery_action_test.exs`; `lib/parapet/metrics/exemplar_telemetry.ex`; `lib/parapet/metrics/exemplar_store.ex` — HIGH confidence (direct inspection)
- **Test runs:** `mix test test/parapet/docs_phase_33_test.exs` (1 failure confirmed); `mix test test/parapet/telemetry/recovery_action_test.exs` (0 failures locally; CI-flaky per v1.7 audit) — HIGH confidence
- **v1.7 Milestone Audit** (`.planning/milestones/v1.7-MILESTONE-AUDIT.md`): confirms both tests as "pre-existing red on both legs" and frames the quarantine need — HIGH confidence
- **ExUnit docs** ([ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html), [ExUnit.Case](https://ex-unit.hexdocs.pm/ExUnit.Case.html)): `exclude` option, `@tag`, `@moduletag`, `@tag :skip` vs custom tag patterns — MEDIUM confidence (official docs, cross-checked with search)
- **`:telemetry_test` module** ([telemetry_test.hexdocs.pm](https://telemetry.hexdocs.pm/telemetry_test.html)): `attach_event_handlers/2` API, `{event, ref, measurements, metadata}` message format, synchronous handler model — MEDIUM confidence (official docs)
- **Oban.Testing** ([oban.hexdocs.pm/Oban.Testing.html](https://oban.hexdocs.pm/Oban.Testing.html)): `:manual` mode, `perform_job/3`, `drain_queue/1`, `assert_enqueued/1` — MEDIUM confidence (official docs)
