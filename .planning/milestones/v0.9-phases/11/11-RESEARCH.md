# Phase 11: harden-multi-node-proof-rerunnability - Research

**Researched:** 2026-05-22
**Domain:** Elixir/OTP multi-node test rerunnability, Phase 5 proof reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Proof hierarchy
- **D-01:** Keep the closure-grade proof for `SCALE-02` anchored in the real Postgres-backed contention suite.
- **D-02:** Treat the multi-BEAM `:peer` lane as a narrow canary, not as an always-on required proof surface in every environment class.

### Smoke lane skip semantics
- **D-03:** Replace the current hard failure at distributed-node bootstrap with an explicit bounded skip when distributed Erlang is unavailable.
- **D-04:** The canary must be honest about its environment contract and must not pretend to have exercised peer-node behavior when the environment cannot support it.

### Verification reconciliation
- **D-05:** Rewrite the Phase 5 verification and validation surfaces so they describe the peer-node canary as environment-conditional and rerunnable rather than as an unconditional pass everywhere.
- **D-06:** Reconcile `SCALE-02` truth across roadmap-adjacent proof artifacts so the executable behavior, verification wording, and milestone audit posture agree.

### Doctor posture
- **D-07:** Keep `mix parapet.doctor` advisory-only for distributed posture; do not widen it into a proof of distributed correctness.
- **D-08:** Preserve the existing certainty boundary: doctor reports live or static facts and explicit uncertainty, while executable tests remain the proof surface.

### the agent's Discretion
- Exact skip mechanism in the test lane, provided it is explicit, bounded, and non-misleading.
- Exact verification wording and artifact phrasing, provided the proof hierarchy and environment contract stay clear.
- Exact helper extraction or test harness refactoring, provided the runtime product contract does not widen.

### Deferred Ideas (OUT OF SCOPE)
- Replacing the DB-first proof contract with a distributed-only proof hierarchy.
- Broad cluster-test infrastructure beyond the narrow peer canary needed for this phase.
- Any expansion of `mix parapet.doctor` into a distributed assurance or runtime enforcement surface.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `SCALE-02` | System test suite includes multi-node or concurrency simulation tests verifying that Ecto-backed circuit breakers prevent race conditions when multiple nodes attempt auto-mitigation simultaneously. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `test/parapet/automation/executor_concurrency_test.exs` as the requirement-closing proof lane, keep `test/parapet/automation/executor_cluster_smoke_test.exs` as a bounded canary, add an explicit environment preflight/skip path, and rewrite Phase 5 proof wording to match that hierarchy. [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] |
</phase_requirements>

## Project Constraints

- Use a recommendation-first, codebase-first posture and auto-decide low-impact details in the artifact. [VERIFIED: AGENTS.md]
- Escalate only if the plan would change runtime behavior, support surface, operator semantics, safety guarantees, or another listed high-impact boundary. [VERIFIED: AGENTS.md]
- Do not widen scope beyond the locked Phase 11 goal. [VERIFIED: AGENTS.md]

## Summary

The authoritative `SCALE-02` proof is already the real-Postgres contention suite, not the peer-node lane. `test/parapet/automation/executor_concurrency_test.exs` passed locally on 2026-05-22, while the peer-node canary initially failed at `Node.start/2` with `{:EXIT, :nodistribution}` from `ensure_distributed_node!/0`, matching the milestone audit gap. [VERIFIED: mix test test/parapet/automation/executor_concurrency_test.exs test/mix/tasks/parapet.doctor_test.exs] [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

That failure is environment-stateful, not a code-level concurrency regression. Official OTP docs state that `epmd` is part of distributed node startup and that a distributed node fails to start if `epmd` is not running; in this workspace, the smoke test failed before `epmd` was up, `Node.start/2` later succeeded in a direct probe, and the same smoke test then passed on rerun. [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html] [CITED: https://www.erlang.org/docs/17/man/epmd] [VERIFIED: elixir -e '... Node.start ...'] [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs]

OTP also documents that `:peer` supports alternative control connections such as `standard_io`, and a local experiment confirmed `:peer.start_link(%{connection: :standard_io})` works even when `Node.alive?()` is `false`. However, that path still needs explicit code-path bootstrap for Parapet modules and would materially reshape the current canary seam, so it is a viable future hardening option but not the narrowest Phase 11 plan. [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html] [VERIFIED: elixir -e 'case :peer.start_link(%{name: :peer.random_name(), connection: :standard_io}) do ... end'] [VERIFIED: mix run -e '... :peer.call(peer, :code, :add_paths, [:code.get_path()]) ...']

**Primary recommendation:** Keep the DB-backed contention test as the closure lane, add an explicit distribution-readiness preflight plus bounded skip semantics to the peer canary, and rewrite Phase 5 verification/validation text so it describes the canary as conditional rather than universal. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Durable winner/loser concurrency proof for `SCALE-02` | Database / Storage | API / Backend | The guarantee comes from `ActionClaim` uniqueness and claim-time gating against the real Repo, which is what the passing contention suite exercises. [VERIFIED: lib/parapet/automation/claim_service.ex] [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] |
| Peer-node smoke verification | API / Backend | Browser / Client | The canary exercises `Parapet.Automation.Executor.perform/1` across BEAMs; no browser tier is involved. [VERIFIED: lib/parapet/automation/executor.ex] [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] |
| Distribution-readiness detection and skip semantics | Test Harness | API / Backend | The bounded skip contract belongs in the test/helper layer, not in product runtime code or doctor. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| Operator-facing certainty boundary | Documentation / Verification Artifacts | API / Backend | The runtime contract stays unchanged; the work is to align verification text with executable behavior and existing advisory doctor semantics. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |

## Standard Stack

### Core

| Library / Runtime | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir | `1.19.5` | Test/runtime language for the canary and contention suites. [VERIFIED: elixir --version] | The repo targets `~> 1.19` and the local runtime matches that target. [VERIFIED: mix.exs] [VERIFIED: elixir --version] |
| Erlang/OTP | `28` | Provides distributed node startup and the `:peer` module behavior constraining this phase. [VERIFIED: erl -eval '...' -noshell] | Phase 11 is directly about OTP distribution readiness and peer-node behavior. [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html] |
| `:stdlib` / `:peer` | `7.3` | Narrow multi-BEAM canary seam. [VERIFIED: elixir -e 'IO.inspect(Application.spec(:stdlib, :vsn))'] | `:peer` is the current OTP-native node-control module and supports both distribution and alternative control connections. [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html] |
| ExUnit | `1.19.5` | Primary validation framework and the built-in skip semantics this phase should reuse. [VERIFIED: test/test_helper.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.html] | The repo already uses ExUnit everywhere, and official docs explicitly support skipped tests via `@tag :skip`. [VERIFIED: test/test_helper.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.html] |
| Ecto SQL | `3.13.5` | Real-Repo transaction and sandbox behavior for the closure-grade concurrency proof. [VERIFIED: mix.lock] | The proof hierarchy is locked to real Postgres contention, not mocks. [VERIFIED: test/support/concurrency_case.ex] [VERIFIED: test/support/concurrency_bootstrap.ex] |
| Postgrex | `0.22.2` | Postgres adapter backing the shared concurrency harness. [VERIFIED: mix.lock] | The contention suite depends on actual Postgres uniqueness and locking behavior. [VERIFIED: test/support/concurrency_bootstrap.ex] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Oban | `2.22.1` | Defines the executor worker shape and the enqueue-time uniqueness seam that remains secondary to DB claims. [VERIFIED: mix.lock] [VERIFIED: lib/parapet/automation/executor.ex] | Use because the executor canary and contention suite both call `Parapet.Automation.Executor.perform/1`. [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] |
| `epmd` | local command present | Required by the current `Node.start/2`-based canary path when using normal distributed startup. [VERIFIED: command -v epmd && epmd -names] [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html] | Use only as an environment prerequisite/probe for the current canary design; do not make it part of Parapet’s product guarantee. [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Unconditional `Node.start/2` + `:peer.start_link/1` canary | Bounded distribution preflight plus explicit skip | This is the narrowest change and matches locked Decisions D-02 through D-05. It does not improve peer coverage in unsupported environments, but it makes the proof lane honest and rerunnable. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] |
| Bounded skip as the primary Phase 11 move | `:peer` with `connection: :standard_io` plus manual code-path bootstrap | A direct experiment proved this is feasible without `Node.start/2`, but it requires refactoring the canary seam and its message/assertion flow. That is useful follow-on hardening, not the minimum locked-scope fix. [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html] [VERIFIED: elixir -e 'case :peer.start_link(%{name: :peer.random_name(), connection: :standard_io}) do ... end'] [VERIFIED: mix run -e '... :peer.call(peer, :code, :add_paths, [:code.get_path()]) ...'] |

**Installation:** No new package installation is required for the preferred Phase 11 plan; all relevant dependencies are already present in the repo/runtime. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Version verification:** Repo/runtime versions were verified locally on 2026-05-22 from `mix.exs`, `mix.lock`, and direct runtime probes. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: elixir --version]

## Architecture Patterns

### System Architecture Diagram

```text
mix test executor_cluster_smoke_test.exs
        |
        v
distribution-readiness preflight
        |
        +--> unsupported / ambient prerequisite missing
        |         |
        |         v
        |     explicit bounded skip
        |     + verification wording says canary not exercised
        |
        +--> supported
                  |
                  v
       local Executor.perform/1   +   peer Executor.perform/1
                  \                       /
                   \                     /
                    v                   v
                  ClaimService.claim_action/1
                            |
                            v
                      Postgres ActionClaim
                            |
                            v
           TimelineEntry / ToolAudit / executed-vs-conflict assertions
```

### Recommended Project Structure

```text
test/
├── parapet/automation/          # contention and peer-canary proof lanes
├── support/                     # shared Postgres/bootstrap/probe helpers
└── mix/tasks/                   # doctor certainty-boundary tests

.planning/
├── v0.9-phases/5/               # canonical Phase 5 verification + validation
└── phases/11-harden-multi-node-proof-rerunnability/  # planning artifacts
```

### Pattern 1: Explicit Environment Preflight For The Peer Canary

**What:** Convert `ensure_distributed_node!/0` from a hard `{:ok, _pid}` match into a probe that returns either `{:ok, started?}` or `{:skip, reason}`, and keep the test explicit about when peer behavior was not exercised. [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.html]

**When to use:** Use for the narrow multi-BEAM smoke test only, not for the DB-first contention suite. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]

**Example:**

```elixir
# Source: repo pattern + ExUnit skip semantics
case ensure_peer_canary_env() do
  {:ok, started_node?} ->
    # run the existing local-plus-peer race assertions
    ...

  {:skip, reason} ->
    @tag skip: reason
end
```

### Pattern 2: Requirement Closure Through The DB-First Contention Lane

**What:** Treat `test/parapet/automation/executor_concurrency_test.exs` as the requirement-closing proof because it exercises one-winner claim semantics, one conflict no-op, one audit row, and the real Repo-backed contract. [VERIFIED: test/parapet/automation/executor_concurrency_test.exs]

**When to use:** Use in verification text, validation text, and planner task acceptance criteria for `SCALE-02`. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/5/05-VALIDATION.md]

**Example:**

```elixir
# Source: test/parapet/automation/executor_concurrency_test.exs
assert Enum.count(results, &(&1 == :ok)) == 1
assert Enum.count(results, fn
         {:discard, "Automation claim conflicted for step auto_step"} -> true
         _ -> false
       end) == 1
```

### Anti-Patterns to Avoid

- **Treating a second-run pass as proof of rerunnability:** the same canary failed first and passed later in this workspace because the ambient distribution prerequisite changed. Phase 11 must remove that hidden dependency from the proof story. [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: elixir -e '... Node.start ...']
- **Letting doctor become a proof lane:** doctor is already locked to advisory facts and uncertainty wording, and its tests enforce that boundary. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs]
- **Promoting the peer canary above the DB-first contention suite:** that would contradict the locked proof hierarchy. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-node correctness proof | A custom distributed lock or a brand-new cluster test framework | Existing `ActionClaim` + contention suite + bounded `:peer` canary | The real safety guarantee already lives in the DB-backed claim service and its real-Repo tests. [VERIFIED: lib/parapet/automation/claim_service.ex] [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] |
| Skip/reporting semantics | Custom ad hoc shell exit handling in the test lane | ExUnit skip semantics plus explicit verification wording | The repo already uses honest skip language in doctor and other environment-sensitive surfaces. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: test/mix/tasks/parapet.gen.prometheus_test.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.html] |
| Distributed capability reporting | A new runtime checker in product code | Test preflight + existing advisory `mix parapet.doctor cluster` wording | The locked scope forbids widening doctor into proof or runtime enforcement. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |

**Key insight:** Phase 11 is an honesty-and-rerunnability repair, not a distributed-systems expansion. The planner should optimize for explicit preconditions and truthful evidence, not for broader cluster machinery. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Ambient `epmd` State Masquerading As Test Flakiness

**What goes wrong:** The canary fails hard on the first run because `Node.start/2` cannot bring up a distributed node, then later passes after the environment has changed. [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: elixir -e '... Node.start ...']
**Why it happens:** Distributed startup depends on `epmd`; OTP documents both the automatic start behavior and the failure mode when `epmd` is not running. [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html] [CITED: https://www.erlang.org/docs/17/man/epmd]
**How to avoid:** Probe readiness explicitly and skip with a clear reason instead of hard matching `{:ok, _pid}`. [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.html]
**Warning signs:** `inet_tcp register/listen error: econnrefused`, `:nodistribution`, or a first-run fail followed by a second-run pass. [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs]

### Pitfall 2: Overclaiming From The Peer Canary

**What goes wrong:** Verification prose says the multi-BEAM canary universally passed and closes `SCALE-02` everywhere. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md]
**Why it happens:** The original Phase 5 artifact treated the canary as a stable pass rather than an environment-conditional smoke lane. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/5/05-VALIDATION.md]
**How to avoid:** Phrase the DB-first contention suite as the closure-grade proof and the peer canary as conditional corroboration. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]
**Warning signs:** words like “passed” or “satisfied” attached to the peer lane without any environment qualifier. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md]

### Pitfall 3: Solving This In `mix parapet.doctor`

**What goes wrong:** The plan tries to move proof responsibility into doctor because doctor already reports cluster facts. [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
**Why it happens:** Doctor already has skip/warn/info semantics, so it is tempting to reuse it as a proof surface. [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
**How to avoid:** Leave doctor unchanged except possibly documentation cross-references; keep proof in tests and verification artifacts. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs]
**Warning signs:** new doctor checks that claim distributed correctness or gate milestone closure. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]

## Code Examples

Verified patterns from official sources and current repo seams:

### Start A Distributed Node Dynamically

```elixir
# Source: https://hexdocs.pm/elixir/Node.html
{:ok, pid} = Node.start(:example, name_domain: :shortnames, hidden: true)
```

### Start A Peer With Alternative Control Connection

```erlang
%% Source: https://www.erlang.org/doc/apps/stdlib/peer.html
{ok, Peer, Node} = peer:start_link(#{name => peer:random_name(), connection => standard_io}).
```

### Current DB-First Winner/Loser Assertion Pattern

```elixir
# Source: test/parapet/automation/executor_concurrency_test.exs
assert Enum.count(results, &(&1 == :ok)) == 1
assert Enum.count(results, fn
         {:discard, "Automation claim conflicted for step auto_step"} -> true
         _ -> false
       end) == 1
```

## State of the Art

| Old Approach | Current / Recommended Approach | When Changed | Impact |
|--------------|-------------------------------|--------------|--------|
| Unconditional peer canary with hard `Node.start/2` match. [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] | Bounded preflight + explicit skip, while the DB-first contention suite remains the closure lane. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] | Phase 11 planning target on 2026-05-22. [VERIFIED: .planning/ROADMAP.md] | Removes environment-fragile false negatives and aligns proof wording with executable behavior. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| Phase 5 verification text describes the peer canary as an unconditional pass. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] | Phase 5 verification text should describe the canary as conditional corroboration for the DB-first proof. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] | Phase 11 planning target on 2026-05-22. [VERIFIED: .planning/ROADMAP.md] | Prevents milestone artifacts from overstating support in this environment class. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |

**Deprecated/outdated:**

- “Real Postgres concurrency suites plus the narrow `:peer` smoke canary passed” as an unqualified current truth is outdated for this environment class. The repo now has direct evidence that the canary can fail before ambient distribution prerequisites are ready. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs]

## Assumptions Log

All material claims in this research were verified from the codebase, runtime probes, or official docs. No user confirmation is required for hidden assumptions at planning time. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-RESEARCH.md] [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html]

## Open Questions (RESOLVED)

1. **Should Phase 11 stop at bounded skip, or also adopt `:peer` alternative control as extra hardening?**
   - Resolution: Phase 11 should stop at truthful skip semantics for unsupported environments and defer `:peer` alternative control (`connection: :standard_io`) to a follow-on hardening phase if it is still wanted later. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]
   - Rationale: the locked scope is to make the current proof lane honest, bounded, and rerunnable without widening runtime guarantees. Explicit skip semantics are the narrowest change that closes the current `:nodistribution` gap while keeping the DB-backed contention suite as the closure-grade proof. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
   - Deferred option: `:peer.start_link(%{connection: :standard_io})` remains technically viable and locally verified, but it requires extra bootstrap and assertion refactoring that is beyond the minimum Phase 11 fix. [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html] [VERIFIED: elixir -e 'case :peer.start_link(%{name: :peer.random_name(), connection: :standard_io}) do ... end'] [VERIFIED: mix run -e '... :peer.call(peer, :code, :add_paths, [:code.get_path()]) ...']

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | all test and artifact work | ✓ | `1.19.5` | — |
| Erlang/OTP | `Node.start/2`, `:peer`, distributed probes | ✓ | `28` | — |
| `:peer` (`stdlib`) | peer-node canary | ✓ | `7.3` | explicit bounded skip if not exercised |
| PostgreSQL | real-Repo contention proof | ✓ | `14.17` client/server binaries present | none for closure-grade proof |
| `epmd` command | current `Node.start/2`-based canary path | ✓ | local command present | bounded skip, or future `:peer` alternative-control hardening |

**Missing dependencies with no fallback:**

- None for planning. [VERIFIED: elixir --version] [VERIFIED: psql --version]

**Missing dependencies with fallback:**

- No binary is missing, but ambient `epmd` readiness is not stable enough to treat the current canary as unconditionally rerunnable; the required fallback is an explicit skip path. [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: command -v epmd && epmd -names]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit `1.19.5`. [VERIFIED: test/test_helper.exs] [VERIFIED: elixir --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/parapet/automation/executor_concurrency_test.exs test/parapet/automation/executor_cluster_smoke_test.exs test/mix/tasks/parapet.doctor_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `SCALE-02` | One executor wins and one loses as a typed no-op through the real Repo-backed claim contract. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/parapet/automation/executor_concurrency_test.exs` | ✅ [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] |
| `SCALE-02` | Narrow peer-node corroboration of the same winner/loser contract when environment supports it. [VERIFIED: .planning/REQUIREMENTS.md] | smoke | `mix test test/parapet/automation/executor_cluster_smoke_test.exs` | ✅ [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs] |
| certainty boundary | Doctor remains advisory and explicit about non-proof status. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] | unit/integration | `mix test test/mix/tasks/parapet.doctor_test.exs` | ✅ [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/automation/executor_concurrency_test.exs test/parapet/automation/executor_cluster_smoke_test.exs test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: mix test test/parapet/automation/executor_concurrency_test.exs test/mix/tasks/parapet.doctor_test.exs] [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs]
- **Per wave merge:** `mix test` [VERIFIED: test/test_helper.exs]
- **Phase gate:** The targeted proof lane must show the contention suite passing, the peer canary either passing or explicitly skipped for a documented reason, and the rewritten verification artifacts matching that behavior. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]

### Wave 0 Gaps

- [ ] Add a reusable helper for peer/distribution readiness so the canary does not hard-match on `Node.start/2`. [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs]
- [ ] Extend the cluster smoke test assertions to distinguish `pass` from `skipped because environment contract unavailable` in a machine-readable way for future verification artifacts. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
- [ ] Rewrite `.planning/v0.9-phases/5/VERIFICATION.md` and `.planning/v0.9-phases/5/05-VALIDATION.md` so they point to the contention suite as closure-grade proof and the peer lane as conditional corroboration. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/5/05-VALIDATION.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth ownership changes are in scope. [VERIFIED: AGENTS.md] |
| V3 Session Management | no | No session surface is involved. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] |
| V4 Access Control | no | No access-control behavior changes are in scope. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] |
| V5 Input Validation | no | Phase 11 is test/proof hardening rather than request validation work. [VERIFIED: .planning/ROADMAP.md] |
| V6 Cryptography | yes | OTP docs warn that unsecured distributed nodes expose the cluster; Phase 11 should keep any distributed startup confined to test-only proof lanes and must not widen runtime guarantees. [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html] [CITED: https://www.erlang.org/doc/system/distributed.html] [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsecured distributed node startup in a broader runtime path | Elevation of Privilege / Information Disclosure | Keep distributed startup in test-only proof code, do not move it into product runtime or doctor, and preserve the existing advisory certainty boundary. [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| False-positive proof claims from environment-sensitive tests | Tampering | Require verification wording to reflect whether the peer lane passed or skipped in the current environment class. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] |
| Duplicate mitigation effects under contention | Tampering | Keep `ActionClaim` uniqueness and real-Repo contention tests as the primary control. [VERIFIED: lib/parapet/automation/claim_service.ex] [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] |

## Sources

### Primary (HIGH confidence)

- `test/parapet/automation/executor_cluster_smoke_test.exs` - current hard-failing `Node.start/2` seam and current peer-canary structure. [VERIFIED: test/parapet/automation/executor_cluster_smoke_test.exs]
- `test/parapet/automation/executor_concurrency_test.exs` - DB-first closure-grade contention proof. [VERIFIED: test/parapet/automation/executor_concurrency_test.exs]
- `lib/parapet/automation/executor.ex` and `lib/parapet/automation/claim_service.ex` - runtime seam and durable claim contract. [VERIFIED: lib/parapet/automation/executor.ex] [VERIFIED: lib/parapet/automation/claim_service.ex]
- `lib/mix/tasks/parapet.doctor.ex` and `test/mix/tasks/parapet.doctor_test.exs` - advisory-only certainty boundary. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs]
- `.planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md` - locked decisions and scope. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md]
- `.planning/v0.9-MILESTONE-AUDIT.md` - exact rerunnability gap and audit language. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
- `https://hexdocs.pm/elixir/Node.html` - dynamic distributed-node startup contract. [CITED: https://hexdocs.pm/elixir/Node.html]
- `https://www.erlang.org/doc/apps/stdlib/peer.html` - peer-node control options and alternative connection support. [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html]
- `https://www.erlang.org/doc/apps/erts/erl_cmd.html` - distributed startup, `epmd`, and `-start_epmd` behavior. [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html]
- `https://hexdocs.pm/ex_unit/ExUnit.html` - official skip semantics. [CITED: https://hexdocs.pm/ex_unit/ExUnit.html]

### Secondary (MEDIUM confidence)

- `https://www.erlang.org/docs/17/man/epmd` - `epmd` daemon role and automatic-start behavior. This is an older official page, but it matches the current `erl` command documentation and the local runtime behavior observed here. [CITED: https://www.erlang.org/docs/17/man/epmd]

### Tertiary (LOW confidence)

- None. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-RESEARCH.md]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and roles were verified from local runtime, `mix.exs`, `mix.lock`, and official docs. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: elixir --version] [CITED: https://www.erlang.org/doc/apps/stdlib/peer.html]
- Architecture: HIGH - the proof hierarchy and scope are locked in `11-CONTEXT.md`, and the repo’s current tests/code confirm the ownership seams. [VERIFIED: .planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md] [VERIFIED: test/parapet/automation/executor_concurrency_test.exs] [VERIFIED: lib/parapet/automation/claim_service.ex]
- Pitfalls: HIGH - they were reproduced locally or directly anchored in current proof artifacts and official OTP docs. [VERIFIED: mix test test/parapet/automation/executor_cluster_smoke_test.exs] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] [CITED: https://www.erlang.org/doc/apps/erts/erl_cmd.html]

**Research date:** 2026-05-22
**Valid until:** 2026-06-21
