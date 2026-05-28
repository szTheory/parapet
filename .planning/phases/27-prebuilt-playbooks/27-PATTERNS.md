# Phase 27: Prebuilt Playbooks - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 5 (2 CREATE, 3 MODIFY)
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` | template | request-response | `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` | exact |
| `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` | template | request-response | `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` | exact |
| `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex` | template | request-response | `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex` (guidance-only framing) | exact |
| `lib/mix/tasks/parapet.gen.runbooks.ex` | mix task | batch | `lib/mix/tasks/parapet.gen.runbooks.ex` lines 32–109 (existing `copy_template` chain) | self-analog |
| `test/mix/tasks/parapet.gen.runbooks_test.exs` | test | request-response | `test/mix/tasks/parapet.gen.runbooks_test.exs` lines 44–99 (existing assertion blocks) | self-analog |

---

## Pattern Assignments

### `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` (template, CREATE)

**Analog:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex`

**Module header pattern** (stalled_executor.ex.eex lines 1–5):
```elixir
defmodule <%= inspect(@module_prefix) %>.StalledExecutor do
  use Parapet.Runbook

  title("Stalled Executor Recovery")
  description("Guidance and recovery actions for background jobs stuck in an executing state.")
```

Delta: replace `StalledExecutor` with `DeployTiedIncident`; update title/description text.

**Step 1 — investigate (stalled_executor.ex.eex lines 7–15):**
```elixir
step(:investigate_logs,
  label: "Check Worker Logs",
  description: "Verify if the worker process crashed without reporting, or if it is currently deadlocked.",
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "...",
  warning: "..."    # optional on investigate step; carry if risk exists
)
```

Delta: rename step id (e.g., `:investigate_deployment`); update label/description/guidance text for feature-flag deployment context.

**Step 2 — mitigate / capability step (stalled_executor.ex.eex lines 17–26):**
```elixir
step(:retry_item,
  label: "Retry Item",
  description: "Force the async item to be retried.",
  type: :mitigation,
  kind: :capability,
  capability: :retry_async_item,
  target_kind: :async_item,
  requires_preview: true,
  warning: "Retrying without identifying the root cause may reproduce the deadlock. Confirm the underlying resource or lock contention is resolved before proceeding."
)
```

Delta: rename step id (e.g., `:revert_flag`); set `capability: :revert_feature_flag`; set `target_kind: :feature_flag`; update label/description/warning text. Include wiring pointer to Rulestead in `guidance:` or `warning:` (D-08).

**Step 3 — verify (stalled_executor.ex.eex lines 28–36):**
```elixir
step(:verify_recovery,
  label: "Verify Recovery",
  description: "Confirm the item completed successfully after the retry.",
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "..."
)
```

Delta: update description/guidance text for post-revert health check context. No `capability:`, no `warning:` required (matches existing verify step shape).

---

### `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` (template, CREATE)

**Analog:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` (same 3-step shape as deploy_tied_incident — see excerpts above)

**Module header delta:** `CardinalityBlowout`; title/description for cardinality context.

**Step 1 — investigate delta:** rename step id (e.g., `:investigate_cardinality`); guidance text for high-cardinality metric detection.

**Step 2 — mitigate / capability step deltas vs stalled_executor.ex.eex lines 17–26:**
- `capability: :disable_metric_label`
- `target_kind: :metric_label`
- Step id e.g., `:disable_label`
- Label/description/warning for metric label disablement context
- Wiring pointer to `mix parapet.doctor cardinality` / `Parapet.Metrics.Validator` in `guidance:` or `warning:` (D-08)

**Step 3 — verify delta:** guidance text for confirming cardinality reduction in APM/dashboards.

---

### `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex` (template, MODIFY)

**Analog (framing reference):** `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex` — shows the guidance-only "no safe automated mitigation" framing. `retry_storm.ex.eex` line 14 warning:
```
"Do not apply retry-accelerating mitigations during a storm — executing retries on storming items will worsen worker exhaustion and extend the incident."
```

**Current step 2 warning to harden** (`suppression_drift.ex.eex` line 24):
```elixir
warning: "Clearing a suppression may immediately trigger escalation for the affected incident — ensure on-call is aware and ready to respond before proceeding."
```

**Required delta (D-04):** Extend this warning to explain the guidance-only architectural rationale. The current text covers on-call readiness but does NOT explain why automated clearing is unsafe. Add the following substance (exact prose is discretionary):
- Automated bulk clearing can mass-trigger escalations simultaneously across all previously-suppressed incidents
- Automated logic cannot detect incorrect suppressions (those that should remain active), risking re-suppression immediately after clearing
- Safe path is operator review of each suppression window before action

No structural changes to the file — harden line 24 `warning:` value inline. Do NOT add a fourth step (Pitfall 2 in RESEARCH.md).

Current step 1 warning (`suppression_drift.ex.eex` line 14) is adequate as-is; touch only if you want to add a brief note that this is a guidance-only runbook because no automated mitigation is safe.

---

### `lib/mix/tasks/parapet.gen.runbooks.ex` (mix task, MODIFY)

**Analog:** `lib/mix/tasks/parapet.gen.runbooks.ex` lines 99–109 (the last `copy_template` call before `Igniter.add_notice`):
```elixir
|> Igniter.copy_template(
  Path.join([
    :code.priv_dir(:parapet),
    "templates",
    "parapet.gen.runbooks",
    "partial_backlog_drain.ex.eex"
  ]),
  Path.join([lib_dir, "partial_backlog_drain.ex"]),
  assigns,
  on_exists: :skip
)
|> Igniter.add_notice("""
Parapet runbooks generated at `#{lib_dir}`.
You can customize the copy and thresholds to fit your domain.
""")
```

**Required delta:** Insert two new `copy_template` calls between line 109 and `Igniter.add_notice`. Append at line 109, after the `partial_backlog_drain` call:

```elixir
|> Igniter.copy_template(
  Path.join([
    :code.priv_dir(:parapet),
    "templates",
    "parapet.gen.runbooks",
    "deploy_tied_incident.ex.eex"
  ]),
  Path.join([lib_dir, "deploy_tied_incident.ex"]),
  assigns,
  on_exists: :skip
)
|> Igniter.copy_template(
  Path.join([
    :code.priv_dir(:parapet),
    "templates",
    "parapet.gen.runbooks",
    "cardinality_blowout.ex.eex"
  ]),
  Path.join([lib_dir, "cardinality_blowout.ex"]),
  assigns,
  on_exists: :skip
)
```

No other changes to this file. The `assigns` and `lib_dir` bindings (lines 24–30) are already correct and require no modification.

---

### `test/mix/tasks/parapet.gen.runbooks_test.exs` (test, MODIFY)

**Analog:** `test/mix/tasks/parapet.gen.runbooks_test.exs` lines 44–59 (the `stalled_executor` and `dead_letter` capability-template assertion blocks — same pattern to extend for the two new capability templates):

```elixir
stalled_executor_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/stalled_executor.ex")
  |> Rewrite.Source.get(:content)

assert stalled_executor_source =~ "defmodule Test.Parapet.Runbooks.StalledExecutor do"
assert stalled_executor_source =~ "use Parapet.Runbook"
assert stalled_executor_source =~ "capability: :retry_async_item"
assert stalled_executor_source =~ "warning:"

dead_letter_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/dead_letter.ex")
  |> Rewrite.Source.get(:content)

assert dead_letter_source =~ "defmodule Test.Parapet.Runbooks.DeadLetter do"
assert dead_letter_source =~ "capability: :requeue_dead_letter"
assert dead_letter_source =~ "warning:"
```

**File-presence assertion analog** (`test/mix/tasks/parapet.gen.runbooks_test.exs` lines 15–42 — the `Enum.any?` block pattern):
```elixir
assert Enum.any?(
         files,
         &String.contains?(&1, "lib/test/parapet/runbooks/stalled_executor.ex")
       )
```

**Required delta — two additions, both inside the single existing `test "creates fixed runbook files..."` block:**

1. Append two file-presence assertions in the `Enum.any?` block (after line 42):
```elixir
assert Enum.any?(
         files,
         &String.contains?(&1, "lib/test/parapet/runbooks/deploy_tied_incident.ex")
       )

assert Enum.any?(
         files,
         &String.contains?(&1, "lib/test/parapet/runbooks/cardinality_blowout.ex")
       )
```

2. Append two content-assertion blocks after line 99 (after `partial_backlog_drain` block, before `end`):
```elixir
deploy_tied_incident_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/deploy_tied_incident.ex")
  |> Rewrite.Source.get(:content)

assert deploy_tied_incident_source =~ "defmodule Test.Parapet.Runbooks.DeployTiedIncident do"
assert deploy_tied_incident_source =~ "capability: :revert_feature_flag"
assert deploy_tied_incident_source =~ "warning:"

cardinality_blowout_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/cardinality_blowout.ex")
  |> Rewrite.Source.get(:content)

assert cardinality_blowout_source =~ "defmodule Test.Parapet.Runbooks.CardinalityBlowout do"
assert cardinality_blowout_source =~ "capability: :disable_metric_label"
assert cardinality_blowout_source =~ "warning:"
```

Do NOT create a second `test` block — all assertions live in the single existing test (Pitfall 3 in RESEARCH.md).

---

## Shared Patterns

### EEx module header
**Source:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` lines 1–2
**Apply to:** Both new capability templates
```elixir
defmodule <%= inspect(@module_prefix) %>.<Suffix> do
  use Parapet.Runbook
```

### Capability step shape (mitigate step)
**Source:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` lines 17–26
**Apply to:** Both new capability templates
```elixir
step(:retry_item,
  label: "...",
  description: "...",
  type: :mitigation,
  kind: :capability,
  capability: :retry_async_item,   # replace with :revert_feature_flag / :disable_metric_label
  target_kind: :async_item,        # replace with :feature_flag / :metric_label
  requires_preview: true,
  warning: "..."
)
```
Key invariants: `type: :mitigation`, `kind: :capability`, `requires_preview: true`, `warning:` present, NO `preview_only:` on this step.

### Guidance step shape (investigate / verify steps)
**Source:** `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` lines 7–15 and 28–36
**Apply to:** Both new capability templates (steps 1 and 3)
```elixir
step(:investigate_logs,
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "...",
  # warning: optional on step 1, absent on step 3
)
```
Key invariants: `type: :manual`, `kind: :guidance`, `preview_only: true`, NO `capability:` key.

### Guidance-only step shape (all steps in guidance-only templates)
**Source:** `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex` lines 7–15
**Apply to:** `suppression_drift.ex.eex` (all steps must remain this shape)
```elixir
step(:assess_storm,
  type: :manual,
  kind: :guidance,
  preview_only: true,
  guidance: "...",
  warning: "..."
)
```
Key invariant: NO `capability:` key anywhere in the file. `kind: :guidance` on every step.

### `Igniter.copy_template` call shape
**Source:** `lib/mix/tasks/parapet.gen.runbooks.ex` lines 33–43
**Apply to:** Two new calls appended in the generator
```elixir
|> Igniter.copy_template(
  Path.join([
    :code.priv_dir(:parapet),
    "templates",
    "parapet.gen.runbooks",
    "<file>.ex.eex"
  ]),
  Path.join([lib_dir, "<file>.ex"]),
  assigns,
  on_exists: :skip
)
```

### Test assertion block shape (capability template)
**Source:** `test/mix/tasks/parapet.gen.runbooks_test.exs` lines 44–51
**Apply to:** Two new content-assertion blocks in the test
```elixir
<name>_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/<file>.ex")
  |> Rewrite.Source.get(:content)

assert <name>_source =~ "defmodule Test.Parapet.Runbooks.<Suffix> do"
assert <name>_source =~ "capability: :<atom>"
assert <name>_source =~ "warning:"
```

---

## No Analog Found

None — all five files have close analogs in the codebase.

---

## Metadata

**Analog search scope:** `priv/templates/parapet.gen.runbooks/`, `lib/mix/tasks/`, `test/mix/tasks/`
**Files scanned:** 6 (4 template analogs + 1 generator task + 1 test file)
**Pattern extraction date:** 2026-05-28

---

## PATTERN MAPPING COMPLETE

**Phase:** 27 - Prebuilt Playbooks
**Files classified:** 5
**Analogs found:** 5 / 5

### Coverage
- Files with exact analog: 5
- Files with role-match analog: 0
- Files with no analog: 0

### Key Patterns Identified
- All capability templates use exact 3-step shape: investigate (`:manual`/`:guidance`/`preview_only: true`) → mitigate (`:mitigation`/`:capability`/`requires_preview: true`) → verify (`:manual`/`:guidance`/`preview_only: true`). Primary analog: `stalled_executor.ex.eex`.
- Generator is a flat `Igniter.copy_template` pipe chain; two new calls append between the last existing template call (line 109) and `Igniter.add_notice` (line 110). No logic or binding changes needed.
- Test is a single `test` block; new assertions append two `Enum.any?` file-presence checks and two `Rewrite.source!` content-assertion blocks, all inside the existing block boundary.
- `suppression_drift.ex.eex` step 2 `warning:` (line 24) needs inline text extension only — no structural changes, no new steps.

### File Created
`/Users/jon/projects/parapet/.planning/phases/27-prebuilt-playbooks/27-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files.
