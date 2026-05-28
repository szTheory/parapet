# Phase 25 — Deferred Items

Items discovered during plan execution that are **out of scope** per the GSD scope boundary (only auto-fix issues directly caused by the current task's changes). Pre-existing warnings or failures in unrelated files are logged here, not fixed.

## From Plan 25-02 execution (2026-05-27)

### Pre-existing demo_app compile warnings (NOT caused by plan 25-02)

Running `cd examples/demo_app && mix compile --warnings-as-errors` produces three pre-existing warnings unrelated to this plan's edits:

1. **`Parapet.Escalation.Worker.new/1` is undefined** — emitted from `lib/parapet/evidence.ex:76` in the parapet library itself. The `Parapet.Escalation.Worker` module conditionally exists when Oban is loaded; the demo_app build apparently doesn't load Oban as a transitive dep. Pre-existing across the base commit (`cac868a`). Not introduced by 25-01 or 25-02.

2. **`Phoenix.LiveReloader.call/2` is undefined** — emitted from `examples/demo_app/lib/demo_app_web/endpoint.ex:1`. The endpoint declares `if code_reloading?` blocks that reference `Phoenix.LiveReloader`, but `phoenix_live_reload` is not a declared dependency in `examples/demo_app/mix.exs`. Pre-existing.

3. **`Phoenix.LiveReloader.init/1` is undefined** — same root cause as (2).

**Impact on plan 25-02 verification:** The plan's automated verify command (`cd examples/demo_app && mix compile --warnings-as-errors 2>&1 | tee /tmp/p25-02-t1.log; ! grep -q 'warning' /tmp/p25-02-t1.log`) returns a false-negative due to these pre-existing warnings. Verified that NONE of the warnings reference `operator_detail_live.ex` or `operator_components.ex` (the files this plan touches) — my edits introduce zero new warnings.

**Disposition:** Log and defer. Pre-existing demo_app dep hygiene is out of scope for Phase 25. Should be addressed as a small dep-cleanup task (add `{:phoenix_live_reload, "~> 1.5", only: :dev}` to `examples/demo_app/mix.exs` and either depend on Oban transitively or wrap the `Escalation.Worker.new/1` reference at the call-site in a `Code.ensure_loaded?` guard).

**RESEARCH.md Pitfall 3 prediction**: "Demo App Not in `mix test` Default Path" warned about exactly this — the demo_app is a separate Mix project not exercised by the library's CI. These warnings haven't surfaced in CI because no automated build runs `cd examples/demo_app && mix compile --warnings-as-errors`.
