# Phase 11: harden-multi-node-proof-rerunnability - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/parapet/automation/executor_cluster_smoke_test.exs` | test | event-driven | `test/parapet/automation/executor_cluster_smoke_test.exs` | exact |
| `test/support/concurrency_case.ex` | test-support | control | `test/support/concurrency_case.ex` | exact |
| `.planning/v0.9-phases/5/VERIFICATION.md` | config | transform | `.planning/v0.9-phases/10/VERIFICATION.md` | role-match |
| `.planning/v0.9-phases/5/05-VALIDATION.md` | config | transform | `.planning/phases/10-tighten-archive-retention-semantics/10-VALIDATION.md` | role-match |
| `.planning/v0.9-phases/5/05-02-SUMMARY.md` | config | transform | `.planning/phases/10-tighten-archive-retention-semantics/10-02-SUMMARY.md` | role-match |
| `.planning/v0.9-phases/11/VERIFICATION.md` | config | transform | `.planning/v0.9-phases/10/VERIFICATION.md` | role-match |
| `.planning/phases/11-harden-multi-node-proof-rerunnability/11-VALIDATION.md` | config | transform | `.planning/phases/10-tighten-archive-retention-semantics/10-VALIDATION.md` | role-match |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |

## Pattern Assignments

### `test/parapet/automation/executor_cluster_smoke_test.exs` (test, event-driven)

**Primary analog:** `test/parapet/automation/executor_cluster_smoke_test.exs`

**Imports and test harness pattern** (lines 1-8):
```elixir
defmodule Parapet.Automation.ExecutorClusterSmokeTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Automation.Executor
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry, ToolAudit}
```

**Bounded setup/teardown pattern** (lines 27-36):
```elixir
@tag :unboxed
test "shared claim semantics survive one local-plus-peer race canary" do
  Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)
  Application.put_env(:parapet, :executor_test_pid, self())

  on_exit(fn ->
    Application.delete_env(:parapet, :automation)
    Application.delete_env(:parapet, :executor_test_pid)
    Application.delete_env(:parapet, :repo)
  end)
```

**Existing peer-canary scaffold to preserve** (lines 54-63, 115-161):
```elixir
started_node? = ensure_distributed_node!()

{:ok, peer, node} = :peer.start_link(%{name: :peer.random_name()})

try do
  assert Node.ping(node) == :pong
  :ok = :erpc.call(node, :code, :add_paths, [:code.get_path()])
  {:ok, _apps} = :erpc.call(node, Application, :ensure_all_started, [:elixir])
  {:ok, _apps} = :erpc.call(node, Application, :ensure_all_started, [:ecto_sql])

  local_task =
    Task.async(fn ->
      unboxed_run(fn ->
        send(parent, {:ready, :local})

        receive do
          :go -> Executor.perform(job)
        end
      end)
    end)

  remote_task =
    Task.async(fn ->
      send(parent, {:ready, :peer})

      receive do
        :go ->
          script = """
          Ecto.Adapters.SQL.Sandbox.unboxed_run(Parapet.TestSupport.ConcurrencyRepo, fn ->
            Parapet.Automation.Executor.perform(%Oban.Job{
              args: %{"incident_id" => "#{incident.id}", "step_id" => "auto_step"}
            })
          end)
          """

          {result, _binding} = :erpc.call(node, Code, :eval_string, [script])
          result
      end
    end)

  assert_receive {:ready, :local}, 1_000
  assert_receive {:ready, :peer}, 1_000

  send(local_task.pid, :go)
  send(remote_task.pid, :go)

  results = [Task.await(local_task, 5_000), Task.await(remote_task, 5_000)]

  assert Enum.count(results, &(&1 == :ok)) == 1
  assert Enum.count(results, fn
           {:discard, "Automation claim conflicted for step auto_step"} -> true
           _ -> false
         end) == 1
```

**Cleanup pattern** (lines 188-194):
```elixir
after
  :peer.stop(peer)

  if started_node? do
    :net_kernel.stop()
  end
end
```

**Winner/loser assertion pattern to keep authoritative**  
**Source:** `test/parapet/automation/executor_concurrency_test.exs` (lines 76-143)
```elixir
results = Enum.map(contenders, &Task.await(&1, 5_000))

assert Enum.count(results, &(&1 == :ok)) == 1

assert Enum.count(results, fn
         {:discard, "Automation claim conflicted for step auto_step"} -> true
         _ -> false
       end) == 1

assert_receive {:mitigated, _node}, 1_000
refute_receive {:mitigated, _node}, 200

unboxed_run(fn ->
  claims =
    ConcurrencyRepo.all(
      from(claim in ActionClaim,
        where:
          claim.incident_id == ^incident.id and claim.action_kind == "automation" and
            claim.action_key == "auto_step"
      )
    )

  assert length(claims) == 1
  assert hd(claims).status == "executed"
  assert hd(claims).idempotency_key == "auto_exec_#{incident.id}_auto_step"
  ...
  assert ConcurrencyRepo.aggregate(ToolAudit, :count, :id) == 1
end)
```

**Honest skip wording pattern**  
**Source:** `lib/mix/tasks/parapet.doctor.ex` (lines 379-385) and `test/mix/tasks/parapet.doctor_test.exs` (lines 194-200)
```elixir
%{
  status: :skip,
  messages: [
    "Runtime cluster check skipped because `config :parapet, :repo` is not configured.",
    "Runtime cluster checks report live facts, but they still cannot prove distributed correctness in isolation."
  ]
}
```

```elixir
test "cluster mode can report live facts as skip when repo config is unavailable" do
  assert Doctor.run(["cluster"]) == :ok

  messages = get_all_shell_messages()
  assert String.contains?(messages, "==> cluster_runtime: skip")
  assert String.contains?(messages, "cannot prove distributed correctness")
end
```

**Implementation note:** Keep the remote/local race and DB assertions intact. Change only the environment preflight seam so `:nodistribution` becomes an explicit skip that states the peer lane was not exercised.

---

### `test/support/concurrency_case.ex` (test-support, control)

**Primary analog:** `test/support/concurrency_case.ex`

**Existing support-module shape** (lines 1-24):
```elixir
defmodule Parapet.TestSupport.ConcurrencyCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Parapet.TestSupport.{ConcurrencyBootstrap, ConcurrencyRepo}
```

**Current shared helper export pattern** (lines 7-14, 23-24):
```elixir
using do
  quote do
    import Parapet.TestSupport.ConcurrencyCase, only: [unboxed_run: 1, allow: 2]
    alias Parapet.TestSupport.{ConcurrencyBootstrap, ConcurrencyRepo}
  end
end

def allow(owner, pid), do: Sandbox.allow(ConcurrencyRepo, owner, pid)
def unboxed_run(fun), do: Sandbox.unboxed_run(ConcurrencyRepo, fun)
```

**Implementation note:** Add peer-canary startup/cleanup helpers in this same lightweight utility style. Preserve the existing sandbox/repo setup and extend the `import ... only:` list if the smoke test should call the new helpers directly.

---

### `.planning/v0.9-phases/5/VERIFICATION.md` (config, transform)

**Analog:** `.planning/v0.9-phases/10/VERIFICATION.md`

**Frontmatter and verification header pattern** (lines 1-15):
```markdown
---
phase: 10-tighten-archive-retention-semantics
verified: 2026-05-22T11:10:10Z
status: verified
score: 4/4 truths verified
human_verification: []
---

# Phase 10: Tighten Archive Retention Semantics Verification Report

**Phase Goal:** Bring archival behavior back into line with the milestone contract so active work never gets pruned.
**Verified:** 2026-05-22T11:10:10Z
**Status:** verified
**Re-verification:** Yes - the archive runtime and proof surfaces were corrected in this session and rechecked against the targeted archive lanes.
```

**Observable truths table pattern** (lines 18-27):
```markdown
### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `Parapet.Evidence.Archiver.archive/3` archives only resolved incidents older than the retention window. | ✓ VERIFIED | `lib/parapet/evidence/archiver.ex` now uses `state == "resolved"` with the existing `inserted_at < ^cutoff` retention filter. |
...
```

**Behavioral spot-checks pattern with rerunnable commands** (lines 29-35):
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core archiver resolved-only proof | `mix test test/parapet/evidence/archiver_test.exs` | 1 test, 0 failures | ✓ PASS |
| CLI and worker entry-surface proof | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` | 5 tests, 0 failures | ✓ PASS |
| Full targeted archive suite | `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` | 6 tests, 0 failures | ✓ PASS |
```

**Gap-summary honesty pattern** (lines 55-57):
```markdown
### Gaps Summary

No known Phase 10 execution gaps remain inside the archive-retention scope. The historical milestone audit remains intentionally unchanged and still requires a fresh rerun before milestone closure is claimed.
```

**Phase-11-specific content to preserve from current file**  
**Source:** `.planning/v0.9-phases/5/VERIFICATION.md` (lines 11-14, 51-55, 60-62)
```markdown
**Phase Goal:** Prove bounded auto-mitigation and escalation behavior stays safe under contention, retries, and a narrow multi-node canary without overstating guarantees.
...
| `SCALE-02` multi-node or concurrency simulation | ✓ SATISFIED | Real Postgres contention suites plus the narrow `:peer` automation canary passed. |
...
No known Phase 5 execution gaps remain. The implementation stays honest about its guarantee boundary: DB-backed effectively-once intent with advisory static checks, not generalized distributed workflow semantics.
```

**Implementation note:** Reword `SCALE-02` and the Phase 5 canary rows so the DB-backed contention suite is the closure-grade proof and the `:peer` lane is explicitly conditional corroboration that is skipped when unsupported, not a universal pass surface.

---

### `.planning/v0.9-phases/5/05-VALIDATION.md` (config, transform)

**Analog:** `.planning/phases/10-tighten-archive-retention-semantics/10-VALIDATION.md`

**Validation frontmatter pattern** (lines 1-8):
```markdown
---
phase: 10
slug: tighten-archive-retention-semantics
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---
```

**Per-task verification map pattern for doc assertions** (lines 37-45):
```markdown
## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |

**Implementation note:** Keep validation secondary to verification, use exact command strings, and make the peer lane explicitly conditional and skipped when unsupported instead of described as an always-on pass surface.

---

### `.planning/v0.9-phases/11/VERIFICATION.md` (config, transform)

**Analog:** `.planning/v0.9-phases/10/VERIFICATION.md`

**Verification report structure pattern**:
```markdown
---
phase: 10-tighten-archive-retention-semantics
verified: 2026-05-22T11:10:10Z
status: verified
score: 4/4 truths verified
human_verification: []
---

# Phase 10: Tighten Archive Retention Semantics Verification Report
```

**Rerunnable command table pattern**:
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core archiver resolved-only proof | `mix test ...` | 1 test, 0 failures | ✓ PASS |
```

**Implementation note:** Mirror the recent phase-local closure-report shape, but tailor the truths and command table to Phase 11's narrower proof-lane repair. State that the DB-backed contention suite remains the closure-grade proof and that the peer-node canary is environment-conditional and skipped when unsupported.

---

### `.planning/phases/11-harden-multi-node-proof-rerunnability/11-VALIDATION.md` (config, transform)

**Analog:** `.planning/phases/10-tighten-archive-retention-semantics/10-VALIDATION.md`

**Validation frontmatter pattern**:
```markdown
---
phase: 10
slug: tighten-archive-retention-semantics
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---
```

**Manual proof-honesty review pattern**:
```markdown
## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
```

**Implementation note:** Keep the Phase 11 validation map aligned to Plans 11-01 through 11-03, set final frontmatter truthfully after execution, and make the manual note review the exact "skipped when unsupported" wording so proof artifacts never imply peer coverage ran when it did not.
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-02-01 | 02 | 2 | `SCALE-01.b`, `AC-02` | T-10-02 | Phase 2 verification and active milestone truth surfaces stop claiming the contradicted non-open semantics. | doc assertion | `rg -n "resolved incidents|investigating|SCALE-01.b|AC-02" .planning/v0.9-phases/2/VERIFICATION.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/v0.9-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |
```

**Manual proof-honesty review pattern** (lines 58-63):
```markdown
## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verification wording stays truthful and does not overclaim broader archival semantics. | `SCALE-01.b`, `AC-02` | This is a proof-honesty judgment across planning artifacts, not just a unit-test concern. | Review `.planning/v0.9-phases/2/VERIFICATION.md` and `.planning/v0.9-MILESTONE-AUDIT.md` together; confirm the repaired evidence says resolved-only archival and still points to rerunnable test commands. |
```

**Existing Phase 5 validation posture to preserve**  
**Source:** `.planning/v0.9-phases/5/05-VALIDATION.md` (lines 3-20)
```markdown
## Reconciled Post-Verification Note

This validation surface was reconciled post-verification after `.planning/v0.9-phases/5/VERIFICATION.md` landed as the canonical closure proof. The validation map records covered proof lanes, but validation is not the closure-grade proof artifact for Phase 5.

## Nyquist Validation Coverage

| Requirement | Verification Method | Status |
|-------------|---------------------|--------|
| SCALE-02 multi-node or concurrency simulation | Real Postgres concurrency suites plus the narrow `:peer` smoke canary documented in `.planning/v0.9-phases/5/VERIFICATION.md`. | COVERED |
```

**Implementation note:** Keep validation secondary to verification. Update the `SCALE-02` row and any manual/doc-assertion text so the peer lane is environment-conditional and the DB-first contention suite is clearly the authoritative closure lane.

---

### `.planning/v0.9-phases/5/05-02-SUMMARY.md` (config, transform)

**Analog:** `.planning/phases/10-tighten-archive-retention-semantics/10-02-SUMMARY.md`

**Summary metadata and objective pattern** (lines 1-12):
```markdown
---
phase: 10-tighten-archive-retention-semantics
plan: 02
status: completed
completed_at: 2026-05-22
---

# Phase 10 Plan 02 Summary

## Objective

Reconcile the proof surfaces and milestone truth artifacts to the repaired archive contract without rewriting historical gap evidence out of sequence.
```

**Completed-work and verification-command pattern** (lines 14-29):
````markdown
## Completed Work

1. Created `.planning/v0.9-phases/10/VERIFICATION.md` as the phase-local closure report for the repaired archive-retention contract.
2. Corrected `.planning/v0.9-phases/2/VERIFICATION.md` so the inherited Phase 2 proof now describes resolved-only archival ...

## Verification

```bash
rg -n 'resolved incidents older than the retention window|`investigating` remains active work|mix test test/parapet/evidence/archiver_test\.exs|mix test test/mix/tasks/parapet.archive_test\.exs|mix test test/parapet/evidence/archive_worker_test\.exs' .planning/v0.9-phases/2/VERIFICATION.md .planning/v0.9-phases/10/VERIFICATION.md
```
````

**Current Phase 5 summary language to tighten**  
**Source:** `.planning/v0.9-phases/5/05-02-SUMMARY.md` (lines 21-40)
````markdown
6. Added `test/parapet/automation/executor_concurrency_test.exs` as the real Postgres contention proof: two concurrent executor attempts, one executed claim/effect path, one conflict no-op, one audit row.
7. Added `test/parapet/automation/executor_cluster_smoke_test.exs` as a narrow multi-BEAM canary using one `:peer` node sharing the same Postgres truth, asserting the same one-winner durable end state across nodes.

```bash
mix test test/parapet/automation/executor_concurrency_test.exs test/parapet/automation/executor_cluster_smoke_test.exs
```

Result: passed (`2 tests, 0 failures`).

## Deviations

None. The multi-node canary stayed intentionally narrow and DB-first, and the real Postgres contention suite remains the primary proof surface.
````

**Implementation note:** Keep the history intact, but adjust summary wording if needed so it no longer reads like the peer canary is an unconditional pass lane in all environments.

---

### `.planning/ROADMAP.md` (config, transform)

**Analog:** `.planning/ROADMAP.md`

**Current phase-entry pattern** (lines 83-103):
```markdown
### Phase 10: Tighten Archive Retention Semantics
**Goal:** Bring archival behavior back into line with the milestone contract so active work never gets pruned.
**Requirements:** `SCALE-01.b`, `AC-02`
**Plans:** 2/2 plans complete
Plans:
- [x] 10-01-PLAN.md — Repair the resolved-only archive predicate and regression-test every archive entry surface without changing the public CLI contract.
- [x] 10-02-PLAN.md — Reconcile Phase 2 and Phase 10 verification artifacts plus roadmap/requirements truth to the repaired archive contract.
**Gap Closure:** Closes the audit requirement, integration, and flow gaps around archive retention semantics.
...
**Closure:** Verified by `.planning/v0.9-phases/10/VERIFICATION.md`, the corrected `.planning/v0.9-phases/2/VERIFICATION.md`, and the verified `SCALE-01.b` / `AC-02` rows in `.planning/REQUIREMENTS.md`; a fresh `$gsd-audit-milestone` rerun is still separate and still pending.
```

**Current Phase 11 stub to extend** (lines 96-103):
```markdown
### Phase 11: Harden Multi-Node Proof Rerunnability
**Goal:** Make the multi-node proof lane honest, bounded, and rerunnable in environments without distributed Erlang.
**Requirements:** `SCALE-02`
**Gap Closure:** Closes the audit requirement, integration, and flow gaps around the Phase 5 concurrency proof.
- Make the peer-node smoke lane skip cleanly when distributed Erlang is unavailable instead of failing hard with `:nodistribution`.
- Preserve a closure-grade proof path for multi-node safety that remains explicit about its environment contract.
- Reconcile Phase 5 verification so the milestone claim matches executable behavior in this environment class.
```

**Implementation note:** Follow the recent Phase 10 pattern if Phase 11 marks plans complete or adds closure text: explicit proof artifact references, explicit separation from a fresh milestone-audit rerun, and no broader runtime-guarantee claim.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** `.planning/REQUIREMENTS.md`

**Requirement definition and traceability row pattern** (lines 35-57):
```markdown
### SCALE-02: Multi-Node Consistency
- [ ] System test suite includes multi-node or concurrency simulation tests verifying that Ecto-backed circuit breakers prevent race conditions when multiple nodes attempt auto-mitigation simultaneously.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCALE-02 | Phase 11 | Pending |
```

**Verified-row precedent**  
**Source:** `.planning/REQUIREMENTS.md` (lines 49-56)
```markdown
| SCALE-01.a | Phase 2 | Verified |
| SCALE-01.b | Phase 10 | Verified |
| SCALE-01.c | Phase 7 | Verified |
| DX-01.a | Phase 8 | Verified |
| DX-01.b | Phase 8 | Verified |
| SCALE-02 | Phase 11 | Pending |
| AC-01 | Phase 8 | Verified |
| AC-02 | Phase 10 | Verified |
```

**Implementation note:** Update only the requirement wording and/or traceability row needed to reflect the repaired proof hierarchy. Keep the requirement framed as multi-node or concurrency simulation, with the DB-backed concurrency lane carrying the closure claim.

## Shared Patterns

### Honest Conditional Capability Reporting
**Source:** `lib/mix/tasks/parapet.doctor.ex` (lines 289-350, 379-391)
**Apply to:** `test/parapet/automation/executor_cluster_smoke_test.exs`, `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/v0.9-phases/5/05-VALIDATION.md`
```elixir
%{
  status: :skip,
  messages: [
    "No escalation worker found, so static cluster checks were skipped.",
    "Static check cannot prove distributed correctness without an escalation worker."
  ]
}

...

messages = [
  "Runtime cluster facts: repo=#{inspect(repo)}, oban_started=#{oban_started?}, escalation_policy=#{inspect(escalation_policy)}",
  "Runtime cluster checks report live facts, but they still cannot prove distributed correctness in isolation."
]
```

### DB-First Closure Proof
**Source:** `test/parapet/automation/executor_concurrency_test.exs` (lines 54-143)
**Apply to:** `test/parapet/automation/executor_cluster_smoke_test.exs`, `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/REQUIREMENTS.md`
```elixir
job = %Oban.Job{args: %{"incident_id" => incident.id, "step_id" => "auto_step"}}

contenders =
  for _ <- 1..2 do
    Task.async(fn ->
      unboxed_run(fn ->
        send(parent, {:ready, self()})

        receive do
          :go -> Executor.perform(job)
        end
      end)
    end)
  end

assert Enum.count(results, &(&1 == :ok)) == 1
assert Enum.count(results, fn
         {:discard, "Automation claim conflicted for step auto_step"} -> true
         _ -> false
       end) == 1
```

### Proof Reconciliation Without Rewriting Audit History
**Source:** `.planning/v0.9-phases/10/VERIFICATION.md` (lines 55-57) and `.planning/phases/10-tighten-archive-retention-semantics/10-02-SUMMARY.md` (lines 31-34)
**Apply to:** `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/v0.9-phases/5/05-02-SUMMARY.md`, `.planning/ROADMAP.md`
```markdown
### Gaps Summary

No known Phase 10 execution gaps remain inside the archive-retention scope. The historical milestone audit remains intentionally unchanged and still requires a fresh rerun before milestone closure is claimed.
```

```markdown
## Deviations from Plan

Phase 10 validation still documents the targeted archive file set with an obsolete `mix test -x` flag. The verification report records the rerunnable current-form commands that were actually executed in this session.
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `test/parapet/automation/`, `test/mix/tasks/`, `test/support/`, `lib/mix/tasks/`, `.planning/v0.9-phases/`, `.planning/phases/`, `.planning/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-22
