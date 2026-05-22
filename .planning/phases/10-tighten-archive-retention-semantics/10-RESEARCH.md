# Phase 10: Tighten Archive Retention Semantics - Research

**Researched:** 2026-05-22 [VERIFIED: .planning/ROADMAP.md]
**Domain:** Archive-retention contract repair across the evidence archiver, archive entrypoints, operator active-queue semantics, and closure-proof artifacts. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: lib/parapet/operator.ex]
**Confidence:** HIGH. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: test/parapet/evidence/archiver_test.exs] [VERIFIED: test/mix/tasks/parapet.archive_test.exs]

## User Constraints

### Locked Scope
- Bring archival behavior back into line with the milestone contract so active work never gets pruned. [VERIFIED: .planning/ROADMAP.md]
- Address `SCALE-01.b` and `AC-02`. [VERIFIED: .planning/REQUIREMENTS.md]
- Investigate these concrete surfaces before planning: `lib/parapet/evidence/archiver.ex`, `lib/mix/tasks/parapet.archive.ex`, `test/parapet/evidence/archiver_test.exs`, `test/mix/tasks/parapet.archive_test.exs`, `lib/parapet/operator.ex`, `docs/operator-ui.md`, and Phase 2, 7, 9, plus active v0.9 audit/verification artifacts that constrain archive semantics. [VERIFIED: user request]
- Focus the phase on: the exact contract mismatch, the minimum code/doc/test changes to restore the contract, the proof surfaces that must be rerun or updated, and the risks around operator queue semantics, evidence truthfulness, and backward-compatible CLI behavior. [VERIFIED: user request]

### Repo Planning Posture
- Use a recommendation-first, codebase-first posture and auto-decide low-impact details in the artifact rather than asking routine questions. [VERIFIED: AGENTS.md]
- Escalate only if the plan would change public CLI/API contract, dependency/support surface, runtime behavior, safety guarantees, operator semantics, durable evidence truth model, irreversible schema/maintenance burden, or two medium-impact concerns at once. [VERIFIED: AGENTS.md]

### Out of Scope
- Broad redesign of archive storage format, scheduling model, queue UX, or milestone-wide cleanup beyond the direct archive-retention proof chain. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: user request]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `SCALE-01.b` | System provides a `Parapet.Evidence.Archiver` module and `mix parapet.archive` task to safely soft-delete or export resolved incidents older than a configurable window. [VERIFIED: .planning/REQUIREMENTS.md] | The current archiver/task exist, but they archive `investigating` incidents too; the plan should narrow the archive filter to resolved-only behavior and re-verify the existing execution surfaces. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| `AC-02` | Running `mix parapet.archive --days 90` successfully moves/clears old evidence without violating foreign key constraints. [VERIFIED: .planning/REQUIREMENTS.md] | The current CLI flow and optional Oban worker already reuse the same archiver path, so the plan should preserve the entrypoints and FK-safe delete path while correcting the retained states and updating closure proof. [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: lib/parapet/evidence/archive_worker.ex] [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] |
</phase_requirements>

## Summary

Phase 10 is a contract-repair phase, not a new archival feature phase. The milestone contract says archival is for resolved incidents older than the retention window, but the shipped implementation archives every incident where `state != "open"`. That includes `investigating`, which the Operator boundary and operator UI docs both treat as active work. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: docs/operator-ui.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

The smallest credible fix is to keep the existing execution surfaces and storage model intact, but narrow the retention predicate from a negated `open` check to an explicit resolved-only allowlist. The current CLI flags, JSONL export behavior, chunked stream, preload shape, delete path, and optional Oban scheduling path can all remain. The main work is therefore not breadth; it is making the state contract explicit in code, tests, and proof artifacts so future closure claims stay truthful and rerunnable. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: lib/parapet/evidence/archive_worker.ex] [VERIFIED: test/parapet/evidence/archiver_test.exs] [VERIFIED: test/mix/tasks/parapet.archive_test.exs] [VERIFIED: test/parapet/evidence/archive_worker_test.exs]

The current milestone audit already pinpoints the defect and names the contradictory proof surfaces. That means the planner should not spend Phase 10 rediscovering the problem. It should split the work into: code/test contract repair, then proof-traceability repair for Phase 2 and the active milestone artifacts that currently overstate `SCALE-01.b` and `AC-02`. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md]

**Primary recommendation:** Change archive eligibility to resolved-only in `Parapet.Evidence.Archiver`, preserve the existing `mix parapet.archive` and `ArchiveWorker` interfaces, add regression tests that prove old `investigating` incidents stay active, then rewrite Phase 2 closure evidence so `SCALE-01.b` and `AC-02` are backed by rerunnable proof instead of contradicted by it. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: lib/parapet/evidence/archive_worker.ex] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Archive eligibility policy | API / Backend [VERIFIED: reasoning over phase scope] | Database / Storage [VERIFIED: reasoning over phase scope] | The retention state filter lives in `Parapet.Evidence.Archiver.archive_query/2`; the database only executes the chosen query. [VERIFIED: lib/parapet/evidence/archiver.ex] |
| CLI archival entrypoint | API / Backend [VERIFIED: reasoning over phase scope] | Browser / Client [VERIFIED: reasoning over phase scope] — | `mix parapet.archive` parses flags and delegates to the archiver; there is no client-tier behavior here. [VERIFIED: lib/mix/tasks/parapet.archive.ex] |
| Active queue preservation | API / Backend [VERIFIED: reasoning over phase scope] | Frontend Server (SSR) [VERIFIED: reasoning over phase scope] | `Parapet.Operator.list_incident_queue/1` defines active queue semantics consumed by generated LiveView UI. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: docs/operator-ui.md] |
| Closure-proof correction | API / Backend [VERIFIED: reasoning over phase scope] | — | The relevant proof surfaces are planning artifacts and targeted tests, not a runtime subsystem. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` | Locked `3.13.6`; latest stable `3.14.0` published 2026-05-19. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] | Query construction and repo transaction/stream behavior for archive selection and deletion. [VERIFIED: lib/parapet/evidence/archiver.ex] | The archiver already depends on `Repo.stream/2`, `Repo.transaction/1`, and query composition. The planner should repair the predicate in-place, not replace the data layer. [VERIFIED: lib/parapet/evidence/archiver.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| `ecto_sql` | Locked `3.13.5`; latest stable `3.14.0` published 2026-05-19. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] | SQL-adapter behavior for streaming archive rows and enforcing FK-safe deletes. [VERIFIED: lib/parapet/evidence/archiver.ex] | SQL adapters enumerate streams inside transactions and support `:max_rows`, which matches the current bounded archive implementation. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| `jason` | Locked `1.4.5`; latest stable `1.4.5` published 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info jason] | JSONL serialization for archived incidents. [VERIFIED: lib/parapet/evidence/archiver.ex] | The storage format is already JSONL and should stay unchanged in this phase. [VERIFIED: lib/parapet/evidence/archiver.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | Locked `2.22.1`; latest stable `2.22.1` published 2026-04-30. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] | Optional scheduled archival via `Parapet.Evidence.ArchiveWorker`. [VERIFIED: lib/parapet/evidence/archive_worker.ex] | Use only to keep the optional scheduling surface consistent with the corrected archiver; Phase 10 should not add new worker semantics. [VERIFIED: lib/parapet/evidence/archive_worker.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| `phoenix_live_view` | Locked `1.1.30`; latest stable `1.1.30` published 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] | Not part of archival execution, but part of the active-queue contract that archival must not violate. [VERIFIED: docs/operator-ui.md] | Use its existing proof/docs only to confirm `investigating` remains active and off-limits to archival. [VERIFIED: docs/operator-ui.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit resolved-only predicate [VERIFIED: recommendation synthesis] | Keep `state != "open"` [VERIFIED: lib/parapet/evidence/archiver.ex] | Rejected because it contradicts the milestone contract and active-queue semantics by pruning `investigating` incidents. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| Preserve `--days` and `--path` CLI [VERIFIED: lib/mix/tasks/parapet.archive.ex] | Add new state-selection flags [ASSUMED] | Likely unnecessary scope expansion for a contract-restoration phase, and it would move the phase closer to a public CLI change that `AGENTS.md` says to escalate. [VERIFIED: AGENTS.md] |
| Preserve JSONL export + hard delete [VERIFIED: lib/parapet/evidence/archiver.ex] | Introduce soft delete or a new cold-storage engine [VERIFIED: .planning/v0.9-phases/2/RESEARCH.md] | Out of scope and wider than the roadmap goal, which is semantics correction rather than a storage redesign. [VERIFIED: .planning/ROADMAP.md] |

**Installation:**
```bash
# No new dependencies required for Phase 10.
```

## Architecture Patterns

### System Architecture Diagram

```text
mix parapet.archive / ArchiveWorker
  -> parse retention days + path
      -> Parapet.Evidence.Archiver.archive/3
          -> build archive eligibility query
              -> select only retention-eligible incidents
                  -> preload timeline_entries -> tool_audits
                      -> append JSONL to disk
                      -> delete archived incident ids
                          -> DB cascades timeline/tool-audit cleanup

Parapet.Operator.list_incident_queue/1
  -> active queue states = open + investigating
      -> generated operator UI / docs / proof lane

Phase 10 contract
  -> archive eligibility must exclude all active queue states
      -> tests + verification artifacts prove investigating remains active
```

### Recommended Project Structure
```text
lib/
├── parapet/evidence/archiver.ex        # Archive eligibility, chunking, JSONL export, delete path
├── parapet/evidence/archive_worker.ex  # Optional Oban wrapper around the same archiver
├── mix/tasks/parapet.archive.ex        # Public CLI entrypoint
└── parapet/operator.ex                 # Canonical active-queue semantics to preserve
test/
├── parapet/evidence/archiver_test.exs
├── parapet/evidence/archive_worker_test.exs
└── mix/tasks/parapet.archive_test.exs
.planning/
└── v0.9-phases/2/VERIFICATION.md       # Phase 2 proof surface that Phase 10 must correct
```

### Pattern 1: Positive State Allowlist for Destructive Retention
**What:** Use an explicit allowlist such as `state == "resolved"` for archive eligibility instead of a negative test like `state != "open"`. [VERIFIED: recommendation synthesis]
**When to use:** Any retention path that deletes durable incident rows. [VERIFIED: lib/parapet/evidence/archiver.ex]
**Example:**
```elixir
# Source: repo code pattern + milestone contract
from(incident in queryable,
  where: incident.state == "resolved",
  where: incident.inserted_at < ^cutoff
)
```
Source: the current implementation already centralizes eligibility in `archive_query/2`, so the fix belongs there. [VERIFIED: lib/parapet/evidence/archiver.ex]

### Pattern 2: Shared Execution Core, Multiple Entry Surfaces
**What:** Keep `Mix.Tasks.Parapet.Archive` and `Parapet.Evidence.ArchiveWorker` as thin wrappers over `Parapet.Evidence.Archiver.archive/3`. [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: lib/parapet/evidence/archive_worker.ex]
**When to use:** Preserve backward-compatible CLI and job entrypoints while changing retention semantics in one place. [VERIFIED: recommendation synthesis]
**Example:**
```elixir
# Source: repo code
repo = Application.fetch_env!(:parapet, :repo)
Parapet.Evidence.Archiver.archive(repo, path, days)
```

### Pattern 3: Proof-First Reconciliation
**What:** Update Phase 2 verification and requirement-tracking only after the corrected tests prove resolved-only archival behavior. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**When to use:** Any phase that fixes a behavior contradiction already called out by the milestone audit. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

### Anti-Patterns to Avoid
- **Negative active-state filter:** `state != "open"` is too broad because it silently treats `investigating` as archiveable. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
- **Docs-only fix:** Updating roadmap or verification prose without changing the retention predicate and regression tests would keep the proof chain false. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
- **New public CLI semantics:** Adding flags or changing success output would widen the phase into a public-contract change that is not needed to close `SCALE-01.b` or `AC-02`. [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: AGENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Active-vs-archivable state policy | A second implicit state model in tests/docs [VERIFIED: recommendation synthesis] | The explicit archive allowlist in `archive_query/2` plus the existing operator active-state contract. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/parapet/operator.ex] | The bug came from letting archive semantics drift away from the operator queue contract. Reuse the existing active-state truth and make the destructive path narrower. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| Archive scheduling behavior | Separate retention code in the worker or task [VERIFIED: recommendation synthesis] | Continue delegating both entrypoints to `Parapet.Evidence.Archiver.archive/3`. [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: lib/parapet/evidence/archive_worker.ex] | One predicate owner keeps CLI, worker, and tests aligned. [VERIFIED: recommendation synthesis] |
| Closure proof | New narrative summaries as evidence [VERIFIED: recommendation synthesis] | Targeted tests plus corrected `VERIFICATION.md` and requirement rows. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | Phase 9 already established verification artifacts as the canonical closure surfaces. [VERIFIED: .planning/v0.9-phases/9/RESEARCH.md] |

**Key insight:** This phase is mostly about preventing destructive retention from inventing a different notion of "inactive" than the operator queue already uses. The safest implementation is therefore narrower logic, not broader machinery. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/parapet/operator.ex]

## Common Pitfalls

### Pitfall 1: Fixing only the archiver unit test
**What goes wrong:** `archiver_test.exs` stops archiving `investigating`, but the CLI and optional worker proof surfaces still only prove "something was archived", not that active incidents were preserved. [VERIFIED: test/parapet/evidence/archiver_test.exs] [VERIFIED: test/mix/tasks/parapet.archive_test.exs] [VERIFIED: test/parapet/evidence/archive_worker_test.exs]
**Why it happens:** The task/worker tests currently use only resolved fixtures, so they do not guard against semantic drift. [VERIFIED: test/mix/tasks/parapet.archive_test.exs] [VERIFIED: test/parapet/evidence/archive_worker_test.exs]
**How to avoid:** Add `investigating` fixtures to the task and worker tests and assert they remain in the repo after archival. [VERIFIED: recommendation synthesis]
**Warning signs:** The tests pass even if the archive predicate regresses back to `!= "open"` because the fixtures never include active old `investigating` rows. [VERIFIED: recommendation synthesis]

### Pitfall 2: Repairing code but leaving false proof artifacts
**What goes wrong:** Runtime behavior becomes correct, but `.planning/v0.9-phases/2/VERIFICATION.md` and top-level requirement state still describe the old broader semantics as verified. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**Why it happens:** Phase 2 verification currently says "old non-open incidents" were proven safe, and the requirement rows remain marked verified even though the audit overturned that claim. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**How to avoid:** Treat proof-artifact correction as a first-class Phase 10 deliverable, not a follow-up. [VERIFIED: .planning/ROADMAP.md]
**Warning signs:** `REQUIREMENTS.md` still says `SCALE-01.b` and `AC-02` are verified while the audit still documents them as unsatisfied. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

### Pitfall 3: Accidental CLI contract drift
**What goes wrong:** A semantics-only fix also changes flags, output shape, default path, or success behavior, widening the phase into a public CLI change. [VERIFIED: lib/mix/tasks/parapet.archive.ex]
**Why it happens:** It is tempting to add state flags or richer reporting while touching the task anyway. [ASSUMED]
**How to avoid:** Keep the current `--days`, `--path`, and JSON success output stable unless the user explicitly expands scope. [VERIFIED: lib/mix/tasks/parapet.archive.ex]
**Warning signs:** Planner tasks start mentioning new options, changed shell output, or migration of cron invocations. [VERIFIED: AGENTS.md]

## Code Examples

Verified patterns from repo and official sources:

### Resolved-Only Archive Predicate
```elixir
# Source: lib/parapet/evidence/archiver.ex (recommended narrowed form)
defp archive_query(queryable, cutoff) do
  from(
    incident in queryable,
    where: incident.state == "resolved",
    where: incident.inserted_at < ^cutoff
  )
end
```

### Transaction-Bound Streaming
```elixir
# Source: repo pattern + Ecto docs
repo.transaction(fn ->
  Incident
  |> archive_query(cutoff)
  |> repo.stream(max_rows: chunk_size())
  |> Stream.chunk_every(chunk_size())
  |> Enum.each(fn incidents ->
    # write JSONL and delete ids
  end)
end)
```
Ecto SQL adapters can enumerate streams only inside a transaction, and `:max_rows` defaults to `500`, so the current Parapet pattern of explicitly bounding `max_rows` is the right shape to preserve. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

### Oban Worker Delegation
```elixir
# Source: lib/parapet/evidence/archive_worker.ex
@impl Oban.Worker
def perform(%Oban.Job{args: args}) do
  repo = Application.fetch_env!(:parapet, :repo)
  days = Map.get(args, "days", @default_days)
  path = Map.get(args, "path", @default_path)

  Parapet.Evidence.Archiver.archive(repo, path, days)
end
```
Oban documents that `perform/1` receives an `Oban.Job` and that `args` always have string keys, which matches the current worker implementation and should remain unchanged. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Archive "all non-open incidents". [VERIFIED: lib/parapet/evidence/archiver.ex] | Archive resolved incidents only. [VERIFIED: .planning/REQUIREMENTS.md] | The contradiction was surfaced by the 2026-05-22 milestone audit and formalized as Phase 10 in the roadmap the same day. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/ROADMAP.md] | Restores alignment between retention and active queue semantics so active `investigating` work is not pruned. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: docs/operator-ui.md] |

**Deprecated/outdated:**
- Treating Phase 2 verification's "old non-open incidents" claim as the current truth is outdated because the active milestone audit now marks `SCALE-01.b` and `AC-02` unsatisfied for that exact reason. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

## Open Questions (RESOLVED)

1. **Should the retention cutoff remain based on `inserted_at`, or should it move to `updated_at`?**
   - What we know: the current implementation archives by `inserted_at`, and neither the roadmap nor requirements explicitly override that field choice. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
   - What's unclear: "older than a configurable window" could plausibly mean "not updated recently" in some operator mental models. [ASSUMED]
   - Resolution: keep `inserted_at` for Phase 10. The current defect is state eligibility, not time semantics, and broadening to `updated_at` would be a separate contract change outside the locked scope for this phase. If maintainers want "inactive since last update", treat that as follow-on work. [VERIFIED: AGENTS.md] [VERIFIED: recommendation synthesis]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix task/tests and archive code execution. [VERIFIED: mix.exs] | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Targeted archive proof reruns. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL client/runtime | Existing test harness bootstraps Ecto/Postgres storage in `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | No full-suite fallback; the fake-repo targeted archive tests still rely on the existing test helper setup. [VERIFIED: test/test_helper.exs] |

**Missing dependencies with no fallback:**
- None found in this environment. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None found in this environment. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with repo-backed test helper. [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs -x` [VERIFIED: recommendation synthesis] |
| Full suite command | `mix test` [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `SCALE-01.b` | Only resolved incidents older than retention are exported and deleted; old `investigating` incidents remain. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration | `mix test test/parapet/evidence/archiver_test.exs -x` | ✅ [VERIFIED: test/parapet/evidence/archiver_test.exs] |
| `AC-02` | `mix parapet.archive --days 90` preserves the current CLI while safely leaving active work untouched. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs -x` | ✅ [VERIFIED: test/mix/tasks/parapet.archive_test.exs] [VERIFIED: test/parapet/evidence/archive_worker_test.exs] |
| Phase 10 proof closure | Top-level audit and Phase 2 verification stop claiming the contradicted semantics. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | doc assertion | `rg -n "resolved incidents|investigating|SCALE-01.b|AC-02" .planning/v0.9-phases/2/VERIFICATION.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/v0.9-MILESTONE-AUDIT.md` | ✅ [VERIFIED: listed files] |

### Sampling Rate
- **Per task commit:** rerun the targeted archive tests touched by that task. [VERIFIED: recommendation synthesis]
- **Per wave merge:** rerun `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs`. [VERIFIED: recommendation synthesis]
- **Phase gate:** targeted archive tests green plus proof/doc assertions reconciled before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md]

### Wave 0 Gaps
- [ ] Extend `test/parapet/evidence/archiver_test.exs` so the happy-path assertion becomes "archives resolved incidents older than retention" and explicitly proves old `investigating` remains. [VERIFIED: test/parapet/evidence/archiver_test.exs]
- [ ] Extend `test/mix/tasks/parapet.archive_test.exs` with an old `investigating` fixture and an assertion that it remains after `Archive.run/1`. [VERIFIED: test/mix/tasks/parapet.archive_test.exs]
- [ ] Extend `test/parapet/evidence/archive_worker_test.exs` with the same regression coverage so the scheduled path cannot drift from the CLI path. [VERIFIED: test/parapet/evidence/archive_worker_test.exs]
- [ ] Rewrite `.planning/v0.9-phases/2/VERIFICATION.md` and the active requirement state so they match the corrected semantics and rerun commands. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: reasoning over phase scope] | — |
| V3 Session Management | no [VERIFIED: reasoning over phase scope] | — |
| V4 Access Control | no [VERIFIED: reasoning over phase scope] | — |
| V5 Input Validation | yes [VERIFIED: lib/mix/tasks/parapet.archive.ex] | Keep `OptionParser`-validated `--days`/`--path` handling stable and avoid adding new unverified CLI inputs in this phase. [VERIFIED: lib/mix/tasks/parapet.archive.ex] |
| V6 Cryptography | no [VERIFIED: reasoning over phase scope] | — |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Pruning active incidents because archive eligibility is broader than the active-work contract. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | Tampering | Use an explicit resolved-only predicate and regression tests that include old `investigating` fixtures across archiver, CLI, and worker paths. [VERIFIED: recommendation synthesis] |
| False closure evidence after runtime repair. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | Repudiation | Update verification artifacts and requirement rows only after rerunnable tests pass, preserving truthful proof hierarchy. [VERIFIED: .planning/v0.9-phases/9/RESEARCH.md] |
| Scope creep into public CLI behavior. [VERIFIED: AGENTS.md] | Denial of service | Preserve flags/output and fix only retention semantics unless the user explicitly approves a CLI contract change. [VERIFIED: lib/mix/tasks/parapet.archive.ex] [VERIFIED: AGENTS.md] |

## Sources

### Primary (HIGH confidence)
- [`.planning/REQUIREMENTS.md`](../../REQUIREMENTS.md) - Phase requirements and acceptance contract.
- [`.planning/ROADMAP.md`](../../ROADMAP.md) - Phase 10 goal and gap-closure scope.
- [`.planning/v0.9-MILESTONE-AUDIT.md`](../../v0.9-MILESTONE-AUDIT.md) - Exact contradiction and broken-flow evidence.
- [`lib/parapet/evidence/archiver.ex`](/Users/jon/projects/parapet/lib/parapet/evidence/archiver.ex:1) - Current archive predicate, chunking, JSONL, and delete path.
- [`lib/mix/tasks/parapet.archive.ex`](/Users/jon/projects/parapet/lib/mix/tasks/parapet.archive.ex:1) - Public archive CLI contract.
- [`lib/parapet/evidence/archive_worker.ex`](/Users/jon/projects/parapet/lib/parapet/evidence/archive_worker.ex:1) - Optional scheduled archive entrypoint.
- [`lib/parapet/operator.ex`](/Users/jon/projects/parapet/lib/parapet/operator.ex:14) - Active queue semantics.
- [`docs/operator-ui.md`](/Users/jon/projects/parapet/docs/operator-ui.md:87) - Active-only queue and proof-lane semantics.
- [`test/parapet/evidence/archiver_test.exs`](/Users/jon/projects/parapet/test/parapet/evidence/archiver_test.exs:1) - Current regression that locks the wrong semantics.
- [`test/mix/tasks/parapet.archive_test.exs`](/Users/jon/projects/parapet/test/mix/tasks/parapet.archive_test.exs:1) - Current CLI coverage.
- [`test/parapet/evidence/archive_worker_test.exs`](/Users/jon/projects/parapet/test/parapet/evidence/archive_worker_test.exs:1) - Current worker coverage.
- [Ecto.Repo docs](https://hexdocs.pm/ecto/Ecto.Repo.html) - Stream/transaction and `:max_rows` behavior.
- [Oban.Worker docs](https://hexdocs.pm/oban/Oban.Worker.html) - Worker defaults and JSON-string-keyed args.

### Secondary (MEDIUM confidence)
- [`.planning/v0.9-phases/2/VERIFICATION.md`](../../v0.9-phases/2/VERIFICATION.md) - Current but now contradicted closure artifact for Phase 2.
- [`.planning/v0.9-phases/2/RESEARCH.md`](../../v0.9-phases/2/RESEARCH.md) - Original archive design intent and out-of-scope storage alternatives.
- [`.planning/v0.9-phases/9/RESEARCH.md`](../../v0.9-phases/9/RESEARCH.md) - Canonical proof-hierarchy guidance for reconciling phase truth surfaces.

### Tertiary (LOW confidence)
- None. All material claims in this research were verified in-session or cited to official docs. [VERIFIED: research review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The phase uses already-shipped dependencies and official docs confirm the relevant Ecto/Oban behaviors. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info jason] [VERIFIED: mix hex.info oban] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- Architecture: HIGH - The defect and the minimal repair surface are explicit in the current code, tests, docs, and milestone audit. [VERIFIED: lib/parapet/evidence/archiver.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: docs/operator-ui.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
- Pitfalls: HIGH - The current tests and verification artifact already demonstrate exactly how semantic drift happened and where it must be prevented. [VERIFIED: test/parapet/evidence/archiver_test.exs] [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md]

**Research date:** 2026-05-22 [VERIFIED: system date]
**Valid until:** 2026-06-21 for repo-local implementation details; rerun sooner if Phase 10 changes the archive contract or public CLI. [VERIFIED: recommendation synthesis]
