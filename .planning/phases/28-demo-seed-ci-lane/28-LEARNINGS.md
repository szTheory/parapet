---
phase: 28-demo-seed-ci-lane
created: 2026-05-28
type: learnings
---

# Phase 28 — Learnings

Strategic lessons from wiring the recovery loop into the demo and contract-testing it. (Execution record lives in the `*-SUMMARY.md` files; this captures what's worth remembering.)

## 1. The operator UI renders runbook steps from inline `"steps"`, not from the `"module"` — a real integration trap

`WorkbenchContract.derive/3` builds the displayed `runbook_steps` from `runbook_data["steps"]` (inline), while Preview/Confirm **execution** resolves `runbook_data["module"]` (`extract_module/1`). They are independent keys.

A capability-backed incident seeded with **only** `"module"`:
- works for the headless `Parapet.Operator.preview_runbook_step/3` + `confirm_runbook_step/4` API, but
- renders **no runbook step and no Preview button** in the operator LiveView — the browser flow is silently broken.

The Phase 28 CONTEXT (D-03) framed `"module"` as *replacing* inline `"steps"`. In reality a capability-backed incident needs **both**: `"steps"` for the UI render, `"module"` for execution, with matching step ids. The seed and tests now carry both.

**Latent core gap / follow-up:** `derive/3` should optionally derive display steps from the compiled module when `"module"` is present, so adopters define a runbook **once** (the module) instead of duplicating it inline. Today the demo (the reference adopters copy) models duplication. Worth a core enhancement or a Phase 29 docs note. Out of scope here (Phase 28 froze core).

## 2. Automating the UAT into CI caught a defect headless tests missed

The browser Preview→Confirm click-through was first closed as a HUMAN-UAT item. Per the standing "automate the world / 0 human UAT" directive, it was rewritten as a `Phoenix.LiveViewTest` `:smoke` scenario (no Wallaby/browser — real mount + `handle_event` + DOM + DB assertions). Doing so **surfaced lesson #1**: the four headless API scenarios all passed while the actual browser flow had no button to click. A UI-level test belongs in the contract suite, not a human checklist — it shifts the catch from human-UAT time to execution time.

## 3. Worktree isolation is the wrong default for this Elixir repo

`examples/demo_app/deps` and `_build` are gitignored, so a fresh `git worktree` checkout lacks them — parallel executors would refetch/recompile all Hex deps and still need local Postgres. Execute-phase ran **sequentially on the main tree** instead (reusing the existing env). For Elixir/mix projects with gitignored build artifacts, prefer `workflow.use_worktrees=false` or sequential execution.

## 4. `Parapet.Capabilities` is started by the parent `:parapet` OTP app

D-09 assumed the demo had to add `Parapet.Capabilities` to its own supervision tree. It doesn't — the `:parapet` dependency app starts the named singleton, and adding it again crashes boot with `{:already_started, _}`. Only the boot-time `Parapet.Recovery.attach([...])` call is needed (after `Supervisor.start_link/2`); OTP boots dependency apps before the app that declares them, so the ordering invariant holds for free.

## 5. Phoenix LiveView 1.1 requires `lazy_html` as a test dep

`Phoenix.LiveViewTest` DOM parsing needs `{:lazy_html, ">= 0.1.0", only: :test}` in 1.1.x. Without it, `live/2` raises at runtime. Add it before writing LiveView tests.
