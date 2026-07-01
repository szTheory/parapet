---
phase: 54
slug: upgrade-path-doctor
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-01
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `54-RESEARCH.md` § Validation Architecture (each of UPG-01..05 + DOCTOR-01 mapped to a concrete artifact + assertion layer).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in), Elixir 1.19 / OTP 26-28 |
| **Config file** | `test/test_helper.exs` (boots `ConcurrencyRepo` Sandbox `:manual`, runs `ConcurrencyBootstrap.bootstrap!/0`; no `mix test` exclusion of `:unboxed`) |
| **Quick run command** | `mix test test/parapet/upgrade_never_forces_move_test.exs test/parapet/gen_schema_move_golden_test.exs` |
| **Full suite command** | `mix test` (runs the active compiled prefix; `:unboxed` included) |
| **Estimated runtime** | quick ~1s (DB-less) · full ~30-60s |

---

## Sampling Rate

- **After every task commit:** Run the DB-less fitness/golden tests (`upgrade_never_forces_move`, `gen_schema_move_golden`) — sub-second.
- **After every plan wave:** Run `mix test` in the active leg (includes `:unboxed` round-trip against the throwaway DB).
- **Before `/gsd-verify-work`:** Full suite green under BOTH CI legs (`PARAPET_SCHEMA_PREFIX=parapet` and `=''`). UPG-01's live-write assertion only fires on the nil leg — that leg MUST be green.
- **Max feedback latency:** ~1s (quick) · ~60s (full)

---

## Per-Requirement Verification Map

> Task IDs are assigned by the planner; this map fixes the requirement → artifact → assertion-layer contract every task must satisfy.

| Requirement | Behavior | Test Type | Layer / What to Assert | Automated Command | File Exists |
|-------------|----------|-----------|------------------------|-------------------|-------------|
| DOCTOR-01 | Drift → `:error` (exit 1 under `--ci`); missing schema → `:error`; repo down → `:skip` | unit | `check_schema/0` / `run(["schema","--ci"])` with `put_env` variants; assert `%{status:, messages:}` + exit code | `mix test test/parapet/doctor_schema_check_test.exs` | ❌ W0 |
| UPG-01 | `schema_prefix: nil` emits bare unqualified SQL + green round-trip | integration | (a) `to_sql(:all,…)` `refute =~ "parapet".`; (b) `get_meta(rec,:prefix)==nil` + read-back | `PARAPET_SCHEMA_PREFIX='' mix test test/parapet/spine/prefix_propagation_test.exs` | ⚠️ extend |
| UPG-02 | Migration = `after_begin` lock_timeout + `CREATE SCHEMA` (default) + six `SET SCHEMA` (one txn); `down` restores, no `DROP SCHEMA` | golden (DB-less) + up/down round-trip (DB) | golden: snapshot source (six explicit lines, `after_begin`, no `@disable_ddl_transaction`, no `DROP SCHEMA`); round-trip: catalog membership | `mix test test/parapet/gen_schema_move_golden_test.exs` + round-trip file | ❌ W0 |
| UPG-03 | Missing table → migrate-time abort (nothing moves); inbound FK/view → NOTICE; second gen → refuse | migrate-time round-trip (abort leg) + generator unit (`on_exists`) | (a) drop fixture table, run migrator, assert raise + tables unmoved; (b) run generator twice, assert `{:error,…}` | round-trip file (abort case) + `mix test test/parapet/gen_schema_move_test.exs` | ❌ W0 |
| UPG-04 | public → up → parapet (FK cascade + partial index intact) → down → public (schema empty, not dropped) | up-down round-trip (DB, `:unboxed`) | `pg_class`+`pg_namespace` membership; FK cascade *behavior* (delete parent, assert child gone); `pg_get_expr(indpred,…)`; post-down schema exists but empty | `mix test test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` | ❌ W0 |
| UPG-05 | Installer/generators never reference the move task; `resolve_prefix(nil,nil)=={:ok,"parapet"}` | regex fitness (DB-less) + unit | scan source for banned `parapet.(gen.)?schema.move` → assert `offenders==[]`; assert default-prefix literal | `mix test test/parapet/upgrade_never_forces_move_test.exs` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/parapet/doctor_schema_check_test.exs` — DOCTOR-01 (drift/missing/skip + `--ci` exit code)
- [ ] `test/parapet/gen_schema_move_test.exs` — UPG-03 second-move refusal (`on_exists`) + nil-leg zero-diff
- [ ] `test/parapet/gen_schema_move_golden_test.exs` — UPG-02 migration-body shape (DB-less snapshot of committed fixture)
- [ ] `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` — UPG-04 up/down round-trip + UPG-03 abort leg (`:unboxed`, throwaway DB `parapet_schema_move_roundtrip_test`)
- [ ] `test/parapet/upgrade_never_forces_move_test.exs` — UPG-05 fitness fn + `resolve_prefix(nil,nil)` pin
- [ ] `priv/repo/migrations/<ts>_move_parapet_spine_to_schema.exs` — committed fixture (shared by golden + round-trip tests)
- [ ] Extend `test/parapet/spine/prefix_propagation_test.exs` — add `describe "UPG-01 Track A"` (nil-leg guarded)
- [ ] Framework install: **none** — ExUnit + PostgreSQL test service already present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification. The dual-prefix CI matrix (Phase 52) supplies the recompile-per-leg coverage; UPG-01's nil-leg live-write assertion runs automatically on the `PARAPET_SCHEMA_PREFIX=''` leg.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
