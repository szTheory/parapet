# Phase 57: Test Suite Baseline - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 57-test-suite-baseline
**Mode:** assumptions + 3-fork advisor research
**Areas analyzed:** stale-string red, atom-count flake, sleep classification, startup barrier, assert_eventually helper, annotation convention

## Assumptions Presented (gsd-assumptions-analyzer)

### TEST-01 — stale-string red
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Delete `docs_phase_33_test.exs:102` (`"make up-auto"`); line 101 already asserts `"make up"`; only red | Confident | repo-wide grep `up-auto` = 1 hit (that line); README has no `up-auto` target |

### TEST-02 — RecoveryActionTest atom-leak flake
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Remove atom_count delta block (132–153); retain `String.to_existing_atom` guard (130, sibling 173) | Confident | `async: true` at line 2; guard comment "load-bearing assertion" at 127–129; CR-01 regression guard |

### TEST-03/04 — sleep census & classification
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 3 spurious (exemplar 23/41/59), 1 startup-race (cluster_smoke 80), 6 intentional holds across 5 files | Confident (classification) / Likely (5=files not call-sites) | telemetry.execute synchronous; cluster_smoke has local+heredoc twin (22 & 110); holds fire after `send`, self-documented at confirm 75–76; claim_service uses 50ms not 75ms |

### TEST-04 barrier + TEST-05 helper placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| per-file `@concurrency_hold_ms`; barrier polls `whereis` inside heredoc; helper in ConcurrencyCase `using` | Likely (barrier mechanism) | concurrency_case.ex is a CaseTemplate with `import only:`; heredoc runs on peer; alt = message barrier |

**Needs external research:** none flagged by analyzer.

## Deep Research — 3 Decision Forks (gsd-advisor-researcher ×3, parallel)

The user requested each open fork be deep-researched (pros/cons/tradeoffs, idiomatic Elixir/Ecto/ExUnit,
prior-art lessons, DX lens) rather than accepted as-is. Three researchers ran in parallel; results are
mutually coherent (shared "three primitives, one grammar" vocabulary).

### Fork A — `assert_eventually` helper (TEST-05)
- **Recommendation:** plain `def assert_eventually(fun, opts \\ [])` on `ConcurrencyCase`, added to `import only:`;
  no dep, no macro, no `until` alias. `:timeout` 1_000ms, `:interval` 25ms constant, `:message`.
- **Load-bearing semantics:** re-raise the last `ExUnit.AssertionError` verbatim on timeout (never a generic
  "timed out"); catch only `ExUnit.AssertionError`; return truthy value on success.
- **Prior art:** rejects `AssertEventually` hex dep and Peter Ullrich block-macro (both hide the real assertion
  behind a generic timeout message — the #1 footgun). Scopes retry like Awaitility / testing-library `waitFor`.

### Fork B — startup barrier (TEST-04, cluster_smoke ~80)
- **Recommendation:** replace `Process.sleep(200)` with a bounded poll until `SELECT 1` succeeds (readiness =
  a completing query), NOT `whereis` and NOT cross-node message ack. Node-local inside the heredoc.
- **Key finding:** `Repo.start_link` returns `{:ok,pid}` before DBConnection connects (lazy/async pool), so
  `whereis != nil` / `:sys.get_state` are true with zero live connections — a `whereis` poll would trade a
  time-race for a registration-race. (db_connection #215; Ecto SQL Sandbox docs.)
- **Bounded:** 5_000ms deadline, ~25ms backoff, `raise` on expiry with repo + peer `node()` + DB-env/reachability hints.
- **Coherence caveat:** barrier retries on DBConnection errors; `assert_eventually` retries only on AssertionError
  → not directly interchangeable. Default to inline self-referential poll.

### Fork C — intentional-hold annotation (TEST-04)
- **Recommendation:** per-file `@concurrency_hold_ms` (75ms; 50ms in claim_service) — NOT a shared constant
  (durations differ, false DRY, can't reach the heredoc). `Process.sleep(@concurrency_hold_ms)` at call sites.
- **Comment convention:** two-line `INTENTIONAL HOLD:` marker — line 1 why (widen the race), line 2 "NOT a lazy
  wait — do not replace with assert_eventually/the start-barrier." Greppable lead token.
- **Heredoc twin (~110):** literal `Process.sleep(75)` + `INTENTIONAL HOLD:` comment inside the string; do not
  interpolate the attribute (runs on a fresh peer node). Caller note: two copies must stay in sync.
- **Optional lint:** cheap CI grep guard first (require `INTENTIONAL HOLD:` before every `test/` sleep);
  promote to a custom `Credo.Check.Warning.SleepInTest` later if it earns its keep. → deferred (D-17).

## Corrections Made

No corrections in the assumption sense — the user opted to deep-research the three "Likely" forks rather than
accept the analyzer's defaults. Research **confirmed** per-file `@concurrency_hold_ms` and the ConcurrencyCase
placement, and **improved** two calls:
- **Barrier mechanism:** analyzer proposed a `whereis` poll → research corrected this to a `SELECT 1`
  readiness poll (whereis is not readiness; DBConnection connects lazily). [D-07]
- **Helper failure behavior:** research added the "re-raise the real assertion, catch only AssertionError"
  semantics that make the helper honest. [D-14]

## External Research

- AssertEventually — https://assert-eventually.hexdocs.pm/AssertEventually.html
- Async testing with eventually (Peter Ullrich) — https://peterullrich.com/async-testing-with-eventually
- ex_assert_eventually — https://github.com/rslota/ex_assert_eventually
- ExUnit.Assertions — https://hexdocs.pm/ex_unit/ExUnit.Assertions.html
- Ecto.Adapters.SQL.Sandbox — https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
- DBConnection — https://hexdocs.pm/db_connection/DBConnection.html
- db_connection #215 (lazy connection pooling) — https://github.com/elixir-ecto/db_connection/issues/215
