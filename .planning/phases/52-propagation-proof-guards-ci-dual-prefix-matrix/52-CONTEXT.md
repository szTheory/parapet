# Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix - Context

**Gathered:** 2026-06-30 (assumptions mode + parallel deep research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the compile-time `@schema_prefix` (landed in Phase 51) propagates across **every** read/write
path with **zero call-site changes**, make runtime `prefix:`/prefix-dropping writes **impossible to
reintroduce** via a static guard, and validate **both** the `parapet` and `public` (unprefixed) legs
honestly in CI. Requirements: **PROP-01, PROP-02, PROP-03, TEST-03**.

Scope expands beyond "pure proof" to **proof + seal**: the four advisory warnings from the Phase 51
code review (`51-REVIEW.md` → WR-01..04) are folded in here because they are the runtime/normalization
seams that Phase 53's generators will clone — they must be single-sourced, guarded, and identifier-safe
*before* a generator copies them. This entails small production edits to `lib/parapet/spine/schema.ex`
and `lib/parapet/evidence.ex` (user-confirmed 2026-06-30).

**Out of scope (defer):** the migration generators / library migrations themselves (Phase 53), the
upgrade-move task + doctor (Phase 54), demo/docs (Phase 55), contract/release framing (Phase 56). The
telemetry contract and public API stay **frozen** — the prefix remains an internal DB detail; `mix
verify.public_api` and the telemetry contract test staying green is a hard constraint.
</domain>

<decisions>
## Implementation Decisions

### A. PROP-02 — Static guard (negative proof)
- **D-01:** Implement as a line-filtered **regex ExUnit fitness function** at
  `test/parapet/schema_prefix_guard_test.exs` (`async: true`). Decisively chosen over a custom Credo
  check or Sourceror/AST: matches Parapet's two existing guards, ships zero new deps, stays out of the
  Hex tarball, and permits a long multi-line **teaching** failure message (a Credo `IssueMeta`
  one-liner cannot). Model on `test/parapet/operator_ui_palette_gate_test.exs:54-64` (structured
  message) and `test/parapet/operator_ui_compile_out_test.exs:57-64` (the `Path.wildcard |> File.read!`
  shape).
- **D-02:** Scope the scan to `lib/parapet/**/*.ex` only — this **excludes `lib/mix/tasks/`**, where the
  migration generators legitimately emit `create table(:parapet_*)`, `references(:parapet_*,
  on_delete: :delete_all)`, and `CREATE SCHEMA parapet`. This single scoping choice removes the largest
  false-positive class.
- **D-03:** Match the forbidden **shape**, not the forbidden **word**. Required regex fingerprints:
  (a) `(insert_all|update_all|delete_all)\s*\(\s*["~]` — a string/sigil-literal table immediately after
  the paren (so `insert_all(ActionClaim, …)` and `on_delete: :delete_all` never match); (b) a bare
  `prefix:` repo option with negative lookbehinds excluding `schema_prefix:`/`module_prefix`/`_prefix:`;
  (c) `search_path`; (d) `parapet_` inside a raw-SQL string / `fragment(` near a SQL verb. Strip trailing
  comments and skip `schema_prefix:`/`_prefix:` lines before matching.
- **D-04:** The guard must be **green from day one** (research verified zero offenders in current `lib/`).
- **D-05:** Failure message must teach the *why* (the read/write precedence split-brain: writes prefer
  the repo `prefix:` opt, reads prefer `from`/`@schema_prefix`, so a runtime `prefix:` can land reads
  and writes in different schemas) **and** the *fix*, with a per-offender `file:line / pattern / code /
  fix` block.

### B. PROP-01 + PROP-03 — Propagation tests (positive proof)
- **D-06:** One co-located test file `test/parapet/spine/prefix_propagation_test.exs`, run under the
  existing concurrency sandbox harness (`ConcurrencyCase`) for the behavioral round-trip legs.
- **D-07:** **The one justified production edit in this phase:** extract `lib/parapet/mcp/server.ex`'s
  inlined `get_incident_timeline` join into a `@doc false` pure query builder (e.g.
  `timeline_for_correlation_query/1`) and have `execute_tool/2` call it — mirroring the already-extracted
  `Parapet.Automation.CircuitBreaker.execution_count_query/3`. This pins the **real** call site.
  Rebuild-in-test is **rejected** (the test would stay green while the real site regresses — fatal to
  the "rides the real site" thesis). No public API / telemetry / call-site-semantics change: the
  identical `Ecto.Query` still flows into `repo.all`.
- **D-08:** Per-site assertion mechanism, dictated by the verified fact that
  `Ecto.Adapters.SQL.to_sql/3` supports `:all`/`:update_all`/`:delete_all` but **NOT `:insert_all`**:
  - Two spine↔spine joins (`mcp/server.ex` builder, `circuit_breaker.ex` `execution_count_query/3`):
    `to_sql(:all, repo, query)` → assert the qualified `"parapet"."parapet_…"` identifier appears on
    **both** the FROM and the JOIN.
  - `claim_service` `insert_all(ActionClaim, …)` (`claim_service.ex:111`) and `evidence.ex` `Ecto.Multi`:
    assert `__schema__(:prefix)` on the schema **plus** a sandbox round-trip asserting
    `Ecto.get_meta(struct, :prefix) == @prefix` on the returned struct(s). (`get_meta` reflects the
    prefix materialized on the actual write path — the load-bearing proof where `to_sql` can't reach.)
- **D-09:** Leg-aware: bind `@prefix Parapet.Spine.Schema.__prefix__()` at module top. Gate the negative
  "no bare `parapet_incidents`" assertion behind `if @prefix` (under the `public` leg the bare name is
  correct). The six-schema `__schema__(:prefix)` **equality** assertion runs unconditionally and passes
  on both legs (all `"parapet"` or all `nil`).
- **D-10:** Assert on the **stable qualified-identifier token** (`"parapet"."parapet_…"`), never
  whole-SQL-string equality and never alias/placeholder text (those break on Ecto patch releases).

### C. TEST-03 — CI dual-prefix matrix (honest both-legs proof)
- **D-11:** Add `schema_prefix` as a **pruned second axis** to the existing `test:` job via
  `matrix.include`: `parapet` × all supported OTP versions + `public` × the **primary OTP only**
  (net **+1 CI cell**, 3→4 — best honesty-per-CI-minute for the solo budget). `lint` and `demo` jobs
  stay single-leg.
- **D-12:** Inject `env: PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}` and run **`mix compile
  --force`** before `mix test`. **Reconciled cross-agent point:** the lever is `mix compile --force`
  (whole project) — this repo *is* the library under test, so the `compile_env` sites are first-party
  `_build` artifacts; `mix deps.compile parapet --force` is the *host-app* lever and would no-op here.
- **D-13:** **Namespace the `_build` cache key and `restore-keys` by `${{ matrix.schema_prefix }}`**
  (load-bearing — today's key varies only on os/elixir/otp/mix.lock). Keep the `deps` cache **shared**
  (prefix-independent). Add `fail-fast: false` so a `public`-leg failure doesn't cancel `parapet` legs.
- **D-14:** Belt-and-suspenders against the false-green (where the `public` leg silently restores and
  reuses the `parapet`-compiled `_build`): add a ~10-line in-suite guard
  `test/parapet/spine/compiled_prefix_leg_test.exs` asserting `Parapet.Spine.Schema.__prefix__()` equals
  the normalized `PARAPET_SCHEMA_PREFIX` for the leg. Defense layers: cache-key namespace (primary) +
  `--force` (secondary) + in-suite guard (tertiary) + Elixir's `compile_env` boot-check (free). Do **not**
  pass `--no-validate-compile-env`.

### D. WR-01..04 — Seal the four Phase-51 leaks (ALL in Phase 52; user-confirmed)
- **D-15 (WR-01):** Extract a single shared `Parapet.Spine.Schema.normalize/1`; the macro/`__prefix__/0`,
  `Evidence.schema_prefix/0`, and the test bootstrap all call it. `config/config.exs` **keeps its
  deliberate pre-compile copy** — `Code.require_file` of app modules into config is **rejected** as
  fragile/magic (config is evaluated before `:parapet` is compiled). The "agreement test"
  (`schema_test.exs:91-128`) is rewritten to drive **real production code** (`normalize/1` +
  `Evidence.schema_prefix/0`), deleting both hand-copied test mirrors. Planning note: resolve the
  compile-time chicken-and-egg by keeping `@raw_prefix Application.compile_env(...)` frozen and computing
  `__prefix__/0` as `normalize(@raw_prefix)` (don't call `normalize/1` from a module attribute of the
  module still compiling). Also folds in IN-01: `normalize/1` maps atoms via `Atom.to_string/1` so
  `:public` collapses like `"public"`.
- **D-16 (WR-02):** **Keep** the `unset env → "parapet"` vs `explicit nil/""/"public" → unprefixed`
  asymmetry — it is the idiomatic "absence = default, explicit nil = off" contract. The defect is only
  that it's untested/undocumented: pin with two explicit tests (unset→`parapet`; explicit `nil`→`nil`)
  and one consistent doc sentence at all three sites (`config.exs`, `schema.ex` moduledoc,
  `Evidence.schema_prefix/0` docstring).
- **D-17 (WR-03):** `Evidence.schema_prefix/0` **delegates** to `Parapet.Spine.Schema.__prefix__()`,
  killing the runtime/compile split-brain by construction. Invert the `evidence_test.exs:201-231` tests
  that currently assert the helper *changes* with `Application.put_env` — they assert the bug; replace
  with a test proving the helper is frozen to the compiled value and ignores runtime `put_env`. No
  legitimate runtime-read use case exists for Phase 53/54 generators (they must report the prefix the
  schemas were actually compiled with). This is the runtime-side complement to the PROP-02 ban guard.
- **D-18 (WR-04):** Own a `safe_ident!/1` allowlist validator (`^[a-z_][a-z0-9_]*$` + 63-byte limit) on
  `Parapet.Spine.Schema`, folded into `normalize/1` so every resolution path is guarded. Ecto's
  `quote_name` is private, so Parapet must own validation. **Allowlist over escaping** (closes
  case-folding, length, and reserved-word footguns at once; lowercase-only sidesteps `"Parapet"`≠`Parapet`).
  `test/support/concurrency_bootstrap.ex` raw-DDL interpolation becomes safe by construction (keep the
  double-quotes as belt-and-suspenders); Phase 53's generator inherits the safe template via `__prefix__/0`.

### Intra-phase ordering
- **D-19:** WR-01 lands the `normalize/1` + `safe_ident!/1` site first → WR-04 folds into `normalize/1`
  → WR-03 delegation lands **with** the WR-01 agreement-test rewrite (it makes the agreement assertion
  tautological + a regression tripwire) → WR-02 (tests+docs) rides along. The four are one fix
  ("exactly one trustworthy prefix source") at four sites, not four independent changes.

### Claude's Discretion
- Exact regex literals, file-internal helper names, and message wording for the guard (D-01..05).
- Whether the in-suite leg guard (D-14) and six-schema equality (D-09) co-locate in one file or two.
- Exact OTP version chosen as "primary" for the `public` leg (follow whatever the current matrix
  treats as primary).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/V1.7-SCHEMA-ISOLATION.md` — milestone design intent (compile-time `@schema_prefix`
  only; runtime `prefix:` banned; verification gates).
- `.planning/phases/51-prefix-core-test-seam/51-REVIEW.md` — source of WR-01..04 (full finding text + fix
  sketches).
- `.planning/ROADMAP.md` (Phase 52 detail, lines ~72-84) — the four success criteria.
- `.planning/REQUIREMENTS.md` — PROP-01, PROP-02, PROP-03, TEST-03 acceptance text.
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — house style (no opaque magic; scripts run in
  the existing test lane; don't ship repo junk to Hex).
- `prompts/prior-art/rulestead-release-engineering-and-ci.md` — sibling CI/cache-key house style.

External API references confirmed during research:
- Ecto — Multi-tenancy with query prefixes (precedence: from/join > `@schema_prefix` > repo `:prefix`).
- `Ecto.Adapters.SQL.to_sql/3` — supports `:all`/`:update_all`/`:delete_all`, NOT `:insert_all`.
- `Ecto.get_meta(struct, :prefix)` — the sanctioned way to verify a struct's resolved prefix.
- `Application.compile_env` — boot-time drift check (a free backstop, not the primary safeguard).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Static-guard pattern: `test/parapet/operator_ui_palette_gate_test.exs:54-64` (structured message via
  `Regex.scan` + remediation pointer) and `test/parapet/operator_ui_compile_out_test.exs:57-64`
  (`Path.wildcard("lib/parapet/**/*.ex") |> File.read!`).
- `lib/parapet/automation/circuit_breaker.ex` — `execution_count_query/3` is **already** a pure
  query-builder returning an `Ecto.Query` (the template for the `mcp/server.ex` extraction); reachable by
  `to_sql` with zero refactor.
- `test/support/concurrency_bootstrap.ex` — runs the suite under the prefix today; `q/1` already emits
  leg-aware (prefixed vs bare) identifiers; reads `PARAPET_SCHEMA_PREFIX` via `Application.compile_env`.
- `test/parapet/spine/schema_test.exs:11-35` — existing six-schema prefix test (to be extended to a
  cross-leg equality assertion); `:91-128` — the agreement test + the two test-local mirrors to delete.
- `.github/workflows/ci.yml` — `test:` job matrix (~lines 66-68) + `actions/cache` for `_build`
  (~lines 100-103) to extend.

### Established Patterns
- Compile-time prefix resolution: `lib/parapet/spine/schema.ex:34` (`Application.compile_env`),
  `:40-44` (`__prefix__/0` normalizer); `config/config.exs:20-28` (the deliberate config-time copy);
  `lib/parapet/evidence.ex:42-48` (the runtime mirror to be made authoritative via delegation).
- Real call sites to prove: `lib/parapet/mcp/server.ex:36-42` (inlined join → extract),
  `lib/parapet/automation/circuit_breaker.ex:44-61` (join builder), `lib/parapet/automation/claim_service.ex:111`
  (`insert_all`), `lib/parapet/evidence.ex:81-90,157-187` (two `Ecto.Multi`).

### Integration Points
- The guard, propagation tests, and in-suite leg guard all run in the existing `mix test` lane → free
  on every CI matrix cell; no separate lint/CI wiring.
- WR-03 delegation must agree with the PROP-02 ban guard (no runtime `prefix:`) — land together so they
  cross-check.
- The CI matrix (`parapet` vs `public`) exercises both legs of `normalize/1` end-to-end, turning the
  WR-01 unit agreement into a real propagation proof.
</code_context>

<specifics>
## Specific Ideas

- Guard failure message should read as a *tutor*, not a gate — explain the precedence split-brain at the
  moment of violation, with a per-offender `fix:` line (Parapet's "host-owned, inspectable, no magic"
  ethos).
- Ecosystem footgun to avoid (Oban inverse case): Oban does NOT namespace `_build` by prefix because its
  prefix is runtime; Parapet's is `compile_env`, so it MUST namespace — copying Oban's reflex causes the
  exact false-green.
- Triplex/`apartment` lesson: tenant/prefix names interpolated into SQL without an allowlist is a
  CVE-class pattern — `safe_ident!/1` is the deliberate correction (allowlist > blocklist > escaping).
</specifics>

<deferred>
## Deferred Ideas

- Permitting operator-chosen mixed-case schema prefixes — a deliberate Phase 53+ extension; lock the
  simple lowercase-only safe set now (D-18).
- The migration generators, library migrations, `--schema`/`--no-create-schema` hatch, and shared
  resolver consumed by `gen.spine`/`gen.archive_indexes`/`install` — Phase 53 (they *consume* the sealed
  seam from this phase).
- `mix parapet.gen.schema.move` upgrade task + `parapet.doctor` config↔compiled drift check — Phase 54
  (the doctor is the *detection* backstop; D-17 eliminates the divergence source here).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
