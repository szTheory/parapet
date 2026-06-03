---
thread: slo-state-off-application-env
opened: "2026-05-27"
target_milestone: v1.2 (Authoring DX & Maturity) — candidate
status: open
priority: high (graduation candidate from 2026-05-27 grafana_test fix)
links:
  - lib/parapet/slo.ex
  - lib/parapet/slo/http.ex
  - lib/parapet/slo/oban.ex
  - lib/parapet/slo/login_journey.ex
  - lib/mix/tasks/parapet.gen.grafana.ex
  - test/mix/tasks/parapet.gen.grafana_test.exs
  - .planning/threads/release-gate-enforcement.md
---

# Thread: Move Parapet.SLO state off of Application env

## What we're investigating

`Parapet.SLO` currently uses **process-global `Application.put_env(:parapet, :slos, ...)`** as its SLO registry. `Parapet.SLO.all/0` reads from this global env, and `Parapet.SLO.{HTTP,Oban,LoginJourney}.register/0` write to it. This is racy under any concurrent access — multiple tests (or runtime callers) reading-modifying-writing the same Application env key collide.

This thread captures the architectural fix. v1.2 should refactor `Parapet.SLO` to use a non-global backing store.

## Why it matters

**Today's pain (the symptom):** `parapet.gen.grafana_test.exs:22` flaked during the v1.0.1 cut. Root cause: `Mix.Tasks.Parapet.Gen.Grafana.igniter/1` calls `SLO.HTTP.register/0` etc., which mutate Application env. Concurrent tests writing different SLOs to the same env caused the dashboard generation to read polluted state.

**Today's fix (the bandage):** `test/mix/tasks/parapet.gen.grafana_test.exs` was flipped to `async: false` with a `setup` block snapshotting/restoring env. See commit `fa26ac2` / PR #9. This works for the one observed test but:

- **Other tests are still vulnerable.** Any other test that reads or writes `:slos`/`:providers` env can flake or interfere. The user already saw `:legacy_only` SLO bleeding across cases.
- **The whole test suite has to be careful** about which cases can be `async: true`. That's a footgun for future contributors and slows CI.
- **Runtime behavior is also affected.** Two Phoenix apps running in the same VM (rare but possible in umbrella projects or test harnesses) would collide on the global env.
- **The `Parapet.SLO.define/2` deprecation doesn't eliminate this.** Even after `define/2` is removed in v2.0, the `register/0` calls inside the gen tasks still write to global env.

**The architectural cost:** parapet sells itself as "host-owned, embedded, no global magic." Global Application env state contradicts that posture for a core data structure.

## Specific design questions

### 1. What's the new backing store?

Candidates, in rough order of preference:

- **Explicit data passed through the call chain.** `Grafana.igniter/2` accepts an `:slos` option; defaults to the host app's configured providers (read once from the host app's config, not from Application env). Cleanest architecturally; ripples to every caller.
- **ETS table owned by the host application's supervision tree.** `Parapet.SLO.Registry` GenServer owns an ETS table; `register/1` and `all/0` go through it. Process-isolated; survives across calls; doesn't pollute global env. Pattern matches `Parapet.Operator.ClaimService` (already in lib/parapet/operator/).
- **`:persistent_term` keyed by namespace.** Fast reads, but global. Doesn't solve the multi-app collision case.
- **Process dictionary scoped to the calling process tree.** Works for tests via `setup` but breaks for any cross-process call. Reject — too brittle.

**Lean:** Option B (ETS via GenServer) for the registry; Option A (explicit `:slos`) for the gen tasks so they don't depend on the registry at all. The two can coexist: the registry exists for runtime, the gen tasks read it at the boundary and pass explicit data the rest of the way.

### 2. Migration path

The existing API is small:
- `Parapet.SLO.define/2` (already hard-deprecated; will be removed in v2.0)
- `Parapet.SLO.HTTP.register/0`, `SLO.Oban.register/0`, `SLO.LoginJourney.register/0`
- `Parapet.SLO.all/0`
- `Parapet.SLO.legacy/0`, `Parapet.SLO.provider_catalog/0`, `Parapet.SLO.provider_slos/0`

Migration:
- Implement `Parapet.SLO.Registry` GenServer + ETS backing.
- Keep the existing `register/0` / `all/0` API surface; reroute internals to the registry instead of `Application.put_env`.
- The deprecated `define/2` can either be removed (v2.0) or also rerouted (transitional).
- Update `Mix.Tasks.Parapet.Gen.Grafana` (and any other gen task that calls `register/0`) to use the registry.
- Add a supervision-tree entry for the registry so it starts with the parapet app.

### 3. Test hygiene cleanup

Once the registry exists:
- Reverse the `async: false` flip on `parapet.gen.grafana_test.exs` (the bandage from PR #9). The registry should be test-isolatable (e.g., `Parapet.SLO.Registry.checkout/1` per test) and the test can run `async: true` again.
- Audit other tests that touch `Application.put_env(:parapet, ...)`. The mcp_test.exs hygiene fix from earlier (`dbd4337`) is similar in spirit — both should ultimately use whatever isolated-state pattern the registry establishes.

### 4. Public-API impact

`Parapet.SLO.all/0` and `Parapet.SLO.HTTP.register/0` etc. are documented as Stable per `docs/stability.md`. Refactoring their internals is fine; the call signatures must stay identical, and they must continue to return the same data shape. v1.0 telemetry/API freeze isn't violated.

## Estimated scope

- **Effort:** 1–2 days for the registry + migration. Not a quick fix; it's a real architectural change.
- **Risk:** Low to moderate. The API surface stays identical, so callers don't change. The risk is in the migration glue (supervision tree, starting the registry early enough, transitional handling of `define/2`).
- **Sequencing:** Should land before or alongside SLO-W1 (`mix parapet.gen.slo` Igniter task). That task will be the first new public API that depends on the registry; doing this first means SLO-W1 inherits clean state.

## Out of scope

- Removing `Parapet.SLO.define/2` entirely — that's v2.0 work per the deprecation policy.
- Cross-app SLO sharing (multi-tenant). Out of scope per v1.2 plan.

## Next concrete step

When v1.2 opens, this thread is one of its planned phases. Probably the FIRST phase of v1.2, before SLO-W1, since SLO-W1 builds on top of the registry. Don't auto-open; wait for the user's v1.2 kickoff signal.
