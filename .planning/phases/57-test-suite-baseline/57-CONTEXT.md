# Phase 57: Test Suite Baseline - Context

**Gathered:** 2026-07-02 (assumptions mode + 3-fork advisor research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make a bare `mix test` (default env, default `parapet` prefix) exit green *honestly*: fix the
two pre-existing red tests directly, and correctly classify every `Process.sleep` call site in
the suite — spurious sleeps removed, deliberate race-widening holds annotated, and the one
startup-race sleep replaced with a real synchronous barrier. Scope is the **test suite only**:
no `lib/` behavior, public API, telemetry contract, or host-ownership changes (v1.8 is
DX/pipeline only, per STATE.md). This phase makes the "CI is the enforcement backstop" claim
rest on a green suite rather than a suite with known reds.
</domain>

<decisions>
## Implementation Decisions

### TEST-01 — Stale-string red (`DocsPhase33Test`)
- **D-01:** Fix `test/parapet/docs_phase_33_test.exs:102` — it asserts `readme =~ "make up-auto"`, a
  target that does not exist (`examples/demo_app/README.md` has no `up-auto`; repo-wide grep returns
  exactly one hit — that assertion line). **Delete line 102** rather than rewrite it to `"make up"`,
  because line 101 already asserts `"make up"` (rewriting would produce a redundant duplicate).
- **D-02:** This is confirmed the *only* stale-string red — no other doc-drift assertion in the file
  is failing (the other `make up-*` targets it checks still exist). Do not broaden the edit.

### TEST-02 — `Telemetry.RecoveryActionTest` atom-count flake
- **D-03:** Remove **only** the `atom_count` before/after delta block at
  `test/parapet/telemetry/recovery_action_test.exs:132–153` (the warm-up pass, the two
  `:erlang.system_info(:atom_count)` reads, and the `assert after_count == before_count` guard).
  Under `async: true` a concurrent test can intern an atom between the two reads → spurious delta.
- **D-04:** **Retain** the load-bearing `assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end`
  guard at line 130 (and its independent sibling copy at line 173). This is the CR-01 atom-table-exhaustion
  regression guard and is not concurrency-sensitive. Do NOT touch line 130 or 173.

### TEST-03 — Spurious sleeps (`exemplar_telemetry_test.exs`)
- **D-05:** Remove the three `Process.sleep(10)` calls at `test/parapet/metrics/exemplar_telemetry_test.exs:23, 41, 59`.
  They follow `:telemetry.execute/3`, which dispatches **synchronously** — the store is already populated when
  `execute` returns, so the waits are dead time. No barrier or helper replaces them; just delete.

### TEST-04 — Sleep-site classification (the count reconciliation)
- **D-06:** The suite has **10 `Process.sleep` sites**, classified as: **3 spurious** (D-05, removed),
  **1 startup-race** (D-07/D-08, → barrier), and **6 intentional-hold call sites across 5 test files**
  (D-09, annotated). The requirement's "five intentional sleeps" counts *files*, not *call sites* —
  `executor_cluster_smoke_test.exs` holds **two** copies of the same race-widening sleep (a local
  `defmodule` runbook at ~line 22 and a remote heredoc-string twin at ~line 110). **All six call sites
  must be annotated**; the "5" is not a budget. Missing the heredoc twin at ~line 110 would leave one
  bare unclassified sleep and falsify the "honest green suite" claim.

### TEST-04 — Startup-race barrier (`executor_cluster_smoke_test.exs` ~line 80)
- **D-07:** Replace `Process.sleep(200)` (which waits for a peer-node `ConcurrencyRepo.start_link` to
  finish booting) with a **bounded readiness poll that waits until a trivial `SELECT 1` query
  succeeds** — NOT a `whereis` poll and NOT a cross-node message ack. Rationale: `Ecto.Repo.start_link`
  returns `{:ok, pid}` as soon as the *supervisor* boots, but DBConnection connects **lazily/async**;
  `Process.whereis != nil` (and `:sys.get_state`) are true while zero DB connections exist. A completing
  query is the only honest readiness signal — polling `whereis` would trade a time-race for a
  registration-race. The barrier stays **node-local inside the eval'd heredoc** (the block already runs
  on the peer), so no cross-node `send`/`receive` is needed.
- **D-08:** The barrier is **bounded (5_000 ms deadline, ~25 ms backoff) and `raise`s on expiry** with a
  DX-grade message naming the repo, the peer `node()`, and the two real culprits (DB env vars / DB
  reachability). Never fall through silently. Poll `SELECT 1` via `Ecto.Adapters.SQL.Sandbox.unboxed_run`
  (matching how the downstream script at ~line 140 talks to the repo). Because the eval'd string can't
  define named functions, use a self-referential anonymous fn (`ready?.(ready?)`), OR — if the
  `assert_eventually` helper (D-10) is made reachable on the peer via code paths — call it with the
  `SELECT 1` probe as predicate. **Caveat (coherence):** the barrier must retry on `DBConnection`/query
  errors, whereas `assert_eventually` (D-11) deliberately retries **only** on `ExUnit.AssertionError`.
  They are therefore NOT interchangeable — if reusing the helper here, the probe predicate must convert a
  "not yet connected" into a falsy return (not a raised DB error), or the barrier stays its own inline poll.
  Default to the **inline self-contained poll** unless the helper cleanly expresses the probe.

### TEST-04 — Intentional-hold annotation
- **D-09:** Annotate each of the 6 intentional-hold call sites with a **per-file** `@concurrency_hold_ms`
  module attribute (NOT a shared constant) and replace the bare literal with
  `Process.sleep(@concurrency_hold_ms)`. Per-file wins because the durations are already deliberately
  different (75 ms in four files; **50 ms** in `claim_service_test.exs`) and each hold means something
  local ("widen *this* race window") — a shared constant would be false DRY, couple unrelated values, and
  hide the number behind an import. Sites: `executor_cluster_smoke_test.exs` (local copy ~22),
  `escalation/worker_concurrency_test.exs:17`, `automation/executor_concurrency_test.exs:22`,
  `automation/claim_service_test.exs:49` (50 ms), `operator/confirm_concurrency_test.exs:77`.
- **D-10:** Precede each attribute with a two-line comment using the greppable lead token
  **`INTENTIONAL HOLD:`** — line 1 states *why* (keep the winner mid-`<verb>` so the loser's claim insert
  races the unique constraint), line 2 states *what it is not* (`NOT a lazy wait — do not replace with
  assert_eventually/the start-barrier`). The second line is the load-bearing DX signal that separates a
  deliberate hold from the async-wait vocabulary this phase introduces. Model on the existing
  `confirm_concurrency_test.exs:75–76` exemplar. Fill `<verb>` per site (`execute`, `escalate`, `gate`, `mitigate`).
- **D-11:** **Heredoc-string twin** (`executor_cluster_smoke_test.exs` ~line 110): keep a **literal**
  `Process.sleep(75)` with the same `INTENTIONAL HOLD:` comment *inside the heredoc*, plus a one-line
  caller-side note that the local runbook copy and this eval'd twin are deliberate duplicates that must
  stay in sync. Do **not** interpolate `#{@concurrency_hold_ms}` — the peer copy runs in a fresh node
  process where the attribute doesn't exist and must stay self-contained and greppable as its own site.

### TEST-05 — `assert_eventually/2` helper
- **D-12:** Add a plain function `assert_eventually(fun, opts \\ [])` (NOT a macro, NOT a new dep) as a
  `def` on `Parapet.TestSupport.ConcurrencyCase` (`test/support/concurrency_case.ex`), and add it to the
  existing `import ... only: [...]` list in that CaseTemplate's `using` block. Rationale: every in-scope
  genuinely-async test already `use`s `ConcurrencyCase`; a `def` matches the existing `allow/2` /
  `unboxed_run/1` idiom exactly, adds no dependency (~15 LOC), and has no hidden global state. Reject the
  `AssertEventually` hex dep and the block-macro variant. Reject an `until` alias — stay inside ExUnit's
  `assert_*` family for least surprise. If a plain-`ExUnit.Case` need appears later, lift-and-shift the
  `def` verbatim into a shared `Parapet.TestSupport.Eventually` module.
- **D-13:** **Signature/defaults:** `assert_eventually(fun, opts)` where `opts` = `:timeout` (default
  `1_000` ms), `:interval` (constant, default `25` ms — no backoff; sub-second waits don't need it),
  `:message` (optional prefix on the timeout failure).
- **D-14:** **Semantics (load-bearing):** re-invoke `fun` on the interval until it returns truthy OR stops
  raising `ExUnit.AssertionError`; on success **return the truthy value** (for binding). On timeout,
  **re-raise the last captured `ExUnit.AssertionError` verbatim** (with its stacktrace) so the operator
  sees the *real* assertion diff — never a generic "timed out" message. If `fun` only ever returned falsy
  (never raised), raise an `ExUnit.AssertionError` showing the last inspected value + elapsed budget.
  **Catch only `ExUnit.AssertionError`** — a `MatchError`/`DBConnection` crash in `fun` is a real bug and
  must fail loud, not be retried. This "re-raise the real assertion" behavior is the deliberate fix for
  the #1 footgun in the prior art (the hex lib and the popular blog pattern both surface a blanket
  "failed to receive a truthy result", hiding the diff).
- **D-15:** **Sandbox contract (documented, not enforced):** poll from the test process (which owns the
  sandbox connection); a spawned poller needs `allow/2` — mirror the existing `unboxed_run/1` + `allow/2`
  discipline. `assert_eventually` is only for the *no-message* DB/state-projection settle cases;
  `assert_receive` remains the idiom for message-passing waits.

### Vocabulary coherence (the through-line across TEST-04/05)
- **D-16:** Three distinct primitives, one grammar — every surviving `Process.sleep` in `test/` must be
  one of these or carry the `INTENTIONAL HOLD:` marker:
  1. **Synchronous start-barrier** (D-07/08) — "don't proceed until the resource is truly usable."
  2. **`@concurrency_hold_ms` + `INTENTIONAL HOLD:`** (D-09/10/11) — "how wide the in-SUT race window is."
  3. **`assert_eventually/2`** (D-12–15) — "wait for the projected outcome to settle."

### Claude's Discretion
- Exact wording of the `INTENTIONAL HOLD:` comment bodies (keep the two-line shape + greppable token).
- Whether the barrier (D-08) uses the inline self-referential fn or the helper-with-predicate form —
  default inline unless the helper cleanly expresses the DB-error-tolerant probe (see D-08 caveat).
- Precise `assert_eventually` implementation details (stacktrace threading from the `rescue`).

### Folded Todos
None — `todo.match-phase 57` returned zero matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — TEST-01 … TEST-05 acceptance criteria (lines 17–21).
- `.planning/ROADMAP.md` — Phase 57 "Test Suite Baseline" success criteria (Phase Details section).
- `test/support/concurrency_case.ex` — the `ExUnit.CaseTemplate` where `assert_eventually/2` is added (D-12).
- `test/support/concurrency_repo.ex` — `database_config/0` + Sandbox pool; defines the barrier's readiness contract (D-07).
- `test/support/concurrency_bootstrap.ex` — existing concurrency support idioms to match in style.
- Test files edited: `test/parapet/docs_phase_33_test.exs`, `test/parapet/telemetry/recovery_action_test.exs`,
  `test/parapet/metrics/exemplar_telemetry_test.exs`, `test/parapet/automation/executor_cluster_smoke_test.exs`,
  `test/parapet/escalation/worker_concurrency_test.exs`, `test/parapet/automation/executor_concurrency_test.exs`,
  `test/parapet/automation/claim_service_test.exs`, `test/parapet/operator/confirm_concurrency_test.exs`.
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — DX/engineering-DNA (minimal deps, no hidden global state).
- `.credo.exs` — `files.included: ["lib/", "test/"]`, so a future `Process.sleep` Credo check would apply to tests (D-17).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.TestSupport.ConcurrencyCase` (`test/support/concurrency_case.ex`) — an `ExUnit.CaseTemplate`
  with a `using do quote do import ... only: [...] end end` block and `def` helpers (`allow/2`,
  `unboxed_run/1`). Direct insertion point for `assert_eventually/2`; every in-scope async test uses it.
- `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` + `allow/2` — the established pattern for DB access in these
  tests; the barrier's `SELECT 1` probe reuses `unboxed_run`.
- `confirm_concurrency_test.exs:75–76` — existing self-documented intentional-hold comment; the
  `INTENTIONAL HOLD:` convention (D-10) generalizes it across all sites.

### Established Patterns
- In-scope concurrency tests are `async: false`, DB-backed via `ConcurrencyRepo`, and use bounded
  `assert_receive {:ready, _}, 1_000` message barriers already (e.g. cluster_smoke ~152–153) — the loud,
  bounded-failure idiom the new barrier and helper both match.
- Deliberate `Process.sleep(75|50)` holds live *inside the system-under-test* (mitigation `gate`/`execute`
  callbacks) to keep a claim/unique-constraint race observable — they are NOT waits and must stay.

### Integration Points
- `assert_eventually/2` → one `def` + one entry in the `import only:` list in `concurrency_case.ex`; call
  sites adopt it incrementally for post-barrier settle-checks (nothing forces a rewrite).
- Startup barrier → replaces the `Process.sleep(200)` inside the `repo_keeper` heredoc
  (`executor_cluster_smoke_test.exs` ~lines 64–83); readiness contract from `concurrency_repo.ex`.
- Peer-node eval boundary (`Code.eval_string` / `:erpc`) — the heredoc twin sleep (D-11) and the barrier
  (D-07/08) both live inside the eval'd string and cannot reference caller-side module attributes.
</code_context>

<specifics>
## Specific Ideas

- **Prior-art footgun to avoid (D-14):** both the `assert_eventually` hex lib and the widely-copied Peter
  Ullrich blog pattern surface a generic "failed to receive a truthy result" on timeout, hiding the real
  assertion diff. Our helper re-raises the last real `ExUnit.AssertionError` instead. Also: catch only
  `ExUnit.AssertionError` (Awaitility / testing-library `waitFor` both scope what they retry on).
- **Readiness footgun to avoid (D-07):** `Repo.start_link` `{:ok, pid}` and `Process.whereis` are true
  before DBConnection has connected (lazy/async pool). Only a completing query proves readiness. See
  db_connection issue #215, `Ecto.Adapters.SQL.Sandbox` docs.
- **`start_supervised!` is the synchronous gold standard** but can't cross `:erpc` into the spawned keeper,
  so D-07 reconstructs its "don't proceed until truly usable" guarantee via a `SELECT 1` probe.
</specifics>

<deferred>
## Deferred Ideas

- **D-17 (optional lint, low priority):** enforce the `INTENTIONAL HOLD:` convention so a future bare
  `Process.sleep` in `test/` gets flagged. Ship the cheap version first — a one-line CI **grep guard**
  requiring every `test/` `Process.sleep` to be preceded by an `INTENTIONAL HOLD:` comment. If it earns
  its keep, promote to a small custom `Credo.Check.Warning.SleepInTest` (Credo already runs over `test/`
  per `.credo.exs`). Planner may fold the grep guard into this phase if cheap, else defer to Phase 58/59
  (Local DX / CI hardening).

### Reviewed Todos (not folded)
None — no todos matched Phase 57.
</deferred>
