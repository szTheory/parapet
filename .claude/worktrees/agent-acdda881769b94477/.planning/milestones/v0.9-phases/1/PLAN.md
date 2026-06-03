---
phase: 01-cardinality-protection
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [lib/parapet/metrics/validator.ex, test/parapet/metrics/validator_test.exs, lib/parapet/metrics/accrue.ex, lib/parapet/metrics/async_delivery.ex, lib/parapet/metrics/ecto.ex, lib/parapet/metrics/http.ex, lib/parapet/metrics/oban.ex, lib/parapet/metrics/probe.ex, lib/parapet/metrics/rulestead.ex, lib/parapet/metrics/scoria.ex, lib/parapet/metrics/sigra.ex, lib/mix/tasks/parapet.doctor.ex, test/mix/tasks/parapet.doctor_test.exs]
autonomous: true
requirements: [PERF-01]

must_haves:
  truths:
    - "Unsafe or high cardinality labels cause compilation errors in metrics."
    - "mix parapet.doctor cardinality warns on unsafe labels in SLO configurations."
    - "Built-in metrics successfully compile under the new cardinality limit."
  artifacts:
    - path: "lib/parapet/metrics/validator.ex"
      provides: "Compile-time validation hook"
      contains: "@after_compile"
    - path: "lib/mix/tasks/parapet.doctor.ex"
      provides: "Doctor task extension for cardinality"
      contains: "cardinality"
  key_links:
    - from: "lib/parapet/metrics/http.ex"
      to: "lib/parapet/metrics/validator.ex"
      via: "use Parapet.Metrics.Validator"
    - from: "lib/mix/tasks/parapet.doctor.ex"
      to: "lib/parapet/internal/label_policy.ex"
      via: "Parapet.Internal.LabelPolicy.assert_safe!"
---

<objective>
Proactively prevent observability's most common failure mode (TSDB Cardinality Protection) by enforcing limits at compile-time for metrics and providing static analysis tooling for dynamic configurations.

Purpose: Protect TSDBs (e.g. Prometheus) from unbound label cardinality which leads to massive bills or OOMs.
Output: Compile-time label protection and enhanced `parapet.doctor` mix task.
</objective>

<context>
@.planning/v0.9-phases/1/1-PATTERNS.md
@.planning/v0.9-phases/1/1-RESEARCH.md
@lib/parapet/internal/label_policy.ex
</context>

<tasks>

<task type="tdd" tdd="true">
  <name>Task 1: Compile-Time Metrics Validator</name>
  <files>lib/parapet/metrics/validator.ex, test/parapet/metrics/validator_test.exs</files>
  <behavior>
    - Test 1: Given a module with metrics exceeding `@max_labels`, `@after_compile` raises a `CompileError`.
    - Test 2: Given a module with unsafe labels (e.g., `user_id`), it raises via `LabelPolicy`.
    - Test 3: Given valid metrics, compilation succeeds silently.
  </behavior>
  <action>Create `Parapet.Metrics.Validator` as a macro that uses `@after_compile` to invoke `apply(env.module, :metrics, [])`. Validate each metric's `tags` length against `@max_labels` (default 10). Call `Parapet.Internal.LabelPolicy.assert_safe!(metric.tags)`. Note: Deviates from PATTERNS.md `builder.ex` in favor of RESEARCH.md Pattern 1 to utilize `@after_compile` hooks without wrapping `Telemetry.Metrics`.</action>
  <verify>
    <automated>mix test test/parapet/metrics/validator_test.exs</automated>
  </verify>
  <done>Tests pass and Validator correctly intercepts module compilation.</done>
</task>

<task type="auto">
  <name>Task 2: Enforce limits on built-in metrics</name>
  <files>lib/parapet/metrics/accrue.ex, lib/parapet/metrics/async_delivery.ex, lib/parapet/metrics/ecto.ex, lib/parapet/metrics/http.ex, lib/parapet/metrics/oban.ex, lib/parapet/metrics/probe.ex, lib/parapet/metrics/rulestead.ex, lib/parapet/metrics/scoria.ex, lib/parapet/metrics/sigra.ex</files>
  <action>Add `use Parapet.Metrics.Validator` to the 9 metric definition modules in `lib/parapet/metrics/` that expose a `metrics/0` function (e.g. `http.ex`, `oban.ex`, `async_delivery.ex`). Ensure no modules exceed the limits. This creates the key link from `lib/parapet/metrics/http.ex` (and others) to `lib/parapet/metrics/validator.ex` as defined in must_haves. Follows the metric definition pattern from PATTERNS.md analog `lib/parapet/metrics/http.ex`. Because RESEARCH.md confirmed the largest current metric has 7 labels, no refactoring of the actual metrics should be needed.</action>
  <verify>
    <automated>mix compile --force --warnings-as-errors</automated>
  </verify>
  <done>All metrics modules compile successfully with the Validator enabled.</done>
</task>

<task type="auto">
  <name>Task 3: Doctor Cardinality Check</name>
  <files>lib/mix/tasks/parapet.doctor.ex, test/mix/tasks/parapet.doctor_test.exs</files>
  <action>Modify `Mix.Tasks.Parapet.Doctor` to support `mix parapet.doctor cardinality`. 
Parse SLOs/slice specs via regex (extract labels from `by (...)` and `{...}` in PromQL strings). Implement the extraction logic detailed in `1-RESEARCH.md` Pattern 2 and Code Examples. Reference the task parsing and AST static analysis patterns from the analog `lib/mix/tasks/parapet.doctor.ex` in PATTERNS.md. Pass extracted labels to `Parapet.Internal.LabelPolicy.assert_safe!/1` (Shared Pattern Validation). Add corresponding tests.</action>
  <verify>
    <automated>mix test test/mix/tasks/parapet.doctor_test.exs</automated>
  </verify>
  <done>Doctor correctly identifies cardinality violations in PromQL queries and reports them.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Configuration -> TSDB | Unvalidated metric tags can DOS the external Prometheus DB |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-01-01   | Denial of Service | `Parapet.Metrics` | mitigate | Cap maximum labels per metric to 10 at compile time |
| T-01-02   | Denial of Service | `Parapet.SLO` | mitigate | Parse PromQL strings in `parapet.doctor` and block known high-cardinality label patterns |
</threat_model>

<verification>
- `mix compile --force` passes.
- `mix test` passes.
- `mix parapet.doctor cardinality` runs successfully and reports `ok` on existing safe configs.
</verification>

<success_criteria>
TSDB protection is mathematically bounded at compile time for internal metrics and verifiable via static analysis for custom configurations.
</success_criteria>

<output>
After completion, create `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md`
</output>