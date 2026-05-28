# Phase 29: Stability + Adopter Onboarding - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.1 "shipped ≠ adopted" gap (the v0.10 LEARN-22-C lesson) for the recovery-action surface — the FINAL phase of milestone v1.1 Actionable Recovery. Covers four requirements:

- **STAB-07** — Graduate `Parapet.Recovery` from Experimental → **Stable** tier (moduledoc admonition + `docs/stability.md` table) and ship CHANGELOG migration notes for the additive `confirm_runbook_step/4` return variants.
- **ADOP-01** — `mix parapet.gen.recovery <NAME>` Igniter task that scaffolds a host-app recovery module (4 callbacks + docstring + test stub). Flag-based, NOT interactive.
- **ADOP-02** — `mix parapet.doctor` recovery-action adoption signal (attached-capability count, unregistered-capability-in-runbook warnings, per-capability host-module/callback check).
- **ADOP-03** — `docs/recovery-actions.md` adopter guide (capability authoring, Preview/Confirm UX, error semantics, four worked examples), cross-linked from `operator-ui.md` + `getting-started.md`.

**Governing pattern:** code lands before the docs that name it (the v0.10 Phase 18 "code surfaces land before docs" decision). The graduated module, the generator, and the doctor check exist before `recovery-actions.md` references them.

**Out of scope (deferred — see `<deferred>`):** per-capability cooldown/breaker scope (v1.2); MCP read-only Preview surface (v1.3+); adapter-provided capabilities (Rulestead → `:revert_feature_flag` as built-in, v1.2/v1.3); `mix parapet.gen.slo` (v1.2); any change to the 4-callback shape or the 5-atom allowlist (both frozen by this phase, not extended).
</domain>

<decisions>
## Implementation Decisions

### Stability Graduation (STAB-07)

- **D-01:** Graduate `Parapet.Recovery` by flipping exactly TWO anchors — nothing else:
  1. The `@moduledoc` admonition in `lib/parapet/recovery.ex:16-20`: `> #### Experimental {: .warning}` → `> #### Stable {: .info}` (use the verbatim Stable callout string documented at `docs/stability.md:10-13`).
  2. The `Parapet.Recovery` row in `docs/stability.md`: move it OUT of the Experimental Modules table (currently line `:49`) and INTO the Stable Modules table (block at `:24-38`), inserted in the table's existing ordering.
- **D-02:** The 4 `@callback` shapes are FROZEN verbatim — NO signature edits: `id() :: atom()`, `label() :: String.t()`, `preview(incident, step) :: {:ok, map()} | {:error, term()}`, `execute(incident, target_refs) :: {:ok, map()} | {:error, term()}` (`recovery.ex:30,38,47,56`). The `__using__/1` macro stays injecting ONLY `@behaviour Parapet.Recovery` (`recovery.ex:59-63`). Stability graduation freezes the EXISTING surface; it does not add or change callbacks. Adding a required callback later would be breaking under the 1.x promise.
- **D-03:** Add adopter-facing callback-freeze language (the four callbacks are now part of the Stable contract) to the moduledoc and/or the `docs/stability.md` Stable row description — as prose, NOT as new code. No new module attributes, no `@deprecated`, no runtime guards.
- **D-04:** `mix verify.public_api` needs NO edits. Its regex classifier (`verify.public_api.ex:104-114`) auto-reclassifies the module the moment the moduledoc admonition flips to the Stable callout. The `docs/stability.md` table is the human-readable mirror of that machine classification — both must move together (D-01) or the "table mirrors classification" invariant breaks silently (verify stays green while the doc lies).

### CHANGELOG Migration Notes (STAB-07)

- **D-05:** Do NOT hand-edit `CHANGELOG.md`. It is Release-Please-owned with a header-only stub (`CHANGELOG.md:1-13`); every entry is auto-generated from commit SHAs (`CHANGELOG.md:15-40`), and human history is explicitly redirected to `docs/HISTORY.md`. A hand-added `## Unreleased` section would be clobbered or duplicated on the next Release-Please run.
- **D-06:** Deliver the additive-variant migration warning two ways:
  1. As the Conventional-Commit body/footer on the Phase 29 feat commit (Release Please renders commit bodies into the generated release entry).
  2. Mirrored into the existing Deprecation/Compatibility Register table in `docs/stability.md:190-198` — the doctrinal home for compatibility notes.
  Content: adopters who pattern-match `Parapet.Operator.confirm_runbook_step/4` must handle the additive `{:short_circuited, reason}` and `{:conflicted, claim_id}` variants; these are additive and will NOT be removed in 1.x. The "changing outcome-vocabulary atoms is breaking" doctrine already lives at `docs/stability.md:144` — this note is its concrete instance.

### gen.recovery Igniter Task (ADOP-01)

- **D-07:** `mix parapet.gen.recovery <NAME>` is a flag-based (non-interactive) Igniter task mirroring `parapet.gen.runbooks.ex` — `use Igniter.Mix.Task` + `info/2` + `igniter/1`. Igniter 0.7.9 specifics, VERIFIED against vendored `deps/igniter/` source:
  - **Required positional arg:** declare `positional: [:name]` in the `%Igniter.Mix.Task.Info{}` struct (`deps/igniter/.../info.ex:68-74`; a bare atom = required; missing arg raises `ArgumentError` via `task.ex:344-376`).
  - **Read the value:** `igniter.args.positional.name` inside `igniter/1` (args parsed into the `Args` struct before `igniter/1` runs; `args.ex:14`). Use the `igniter/1` arity — `igniter/2` is deprecated and warns.
- **D-08:** Source-file scaffold: NEW EEx template `priv/templates/parapet.gen.recovery/recovery.ex.eex` rendered via `Igniter.copy_template/5` with `on_exists: :skip`, following the assigns convention (`module_prefix`, `app_name`) and template-header shape (`<%= inspect(@module_prefix) %>`) proven at `gen.runbooks.ex:33-43` and `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex:1`. The rendered module emits `use Parapet.Recovery` + the four callbacks + a docstring template — matching the fixture at `test/parapet/recovery_test.exs:5-11`.
- **D-09:** Module name + path derivation: build the module alias as `<BaseName>.Parapet.Recovery.<NameCamelized>` and resolve the file path with `Igniter.Project.Module.proper_location(igniter, mod, :source_folder)` (handles `lib/<app>/...` + underscoring), OR reuse the explicit `base_name`/`module_prefix`/`lib_dir` derivation from `gen.runbooks.ex:18-24`. Plan-phase picks one; both are idiomatic. Same camelize/underscore treatment for the NAME applies to the test file.
- **D-10:** Test stub: create `test/<app>/parapet/recovery/<name>_test.exs` via `Igniter.create_new_file/4` with `on_exists: :skip` (`deps/igniter/.../igniter.ex:867`), OR via `Igniter.copy_template/5` if the stub is itself an EEx template. The stub mirrors the `Igniter.Test` assertion pattern used at `test/mix/tasks/parapet.gen.runbooks_test.exs`. No dedicated Igniter test-file helper exists; `create_new_file/4`/`copy_template/5` is the primitive.

### Doctor Adoption Signal (ADOP-02)

- **D-11:** Add a `check_recovery` static check to `lib/mix/tasks/parapet.doctor.ex`: register it in the `@static_checks` list (`doctor.ex:22`) and add a `run_static_check("recovery")` dispatch clause (`doctor.ex:89-94`), returning the standard `%{status: :ok | :warn | :error, messages: [...]}` map consumed by the existing JSON/human output split (`doctor.ex:427-467`).
- **D-12:** Three signals inside `check_recovery`:
  1. **Attached-capability count** — read from `Parapet.Capabilities.capabilities(:recovery)` (`capabilities.ex:52-56`). Informational; zero attached capabilities is `:warn` (adoption signal), not `:error`.
  2. **Runbook step references unregistered capability** — there is NO global runbook registry. Discover host runbooks via SLO indirection: iterate `Parapet.SLO.all()`, resolve each `slo.runbook` string to a module, call `__runbook_schema__/0`, extract each `step.capability`, and cross-check against `Parapet.Capabilities.get_recovery/1`. This reuses the exact static-discovery pattern at `alert_processor.ex:116-128` (mirrored at `operator.ex:673-684`). An `slo.runbook` value that is a URL (not a module name) is tolerated as a SKIP, never an error. A referenced-but-unregistered capability is `:warn`.
  3. **Per-capability host-module health** — for each registered capability, `Code.ensure_loaded?/1` the host module and `function_exported?/2`-check the 4 expected callbacks. Missing module or callback is `:warn`.
- **D-13:** The existing `check_runbooks` (`doctor.ex:96-115`) only validates the runbook-URL string is non-empty — it does NOT load runbook modules. `check_recovery`'s module-loading cross-check is genuinely new behavior built on the alert_processor discovery pattern, NOT an extension of `check_runbooks`. Keep them separate.

### Adopter Guide + ExDoc Wiring (ADOP-03)

- **D-14:** `docs/recovery-actions.md` follows the structure of `docs/slo-authoring-guide.md` (decision-frame → authoring → patterns → what-not-to-do; headings at `slo-authoring-guide.md:1,9,39,57,137`). It explains capability authoring, the Preview/Confirm UX, and the error semantics (`:short_circuited`, `:conflicted`, `:recovery_failed`). It REFERENCES — does not re-derive — the Preview/Confirm UX already documented at `operator-ui.md:179-208`.
- **D-15:** Four worked examples map 1:1 to the capability-backed playbooks shipped in Phase 27: stalled async (`:retry_async_item`), dead-letter drain (`:requeue_dead_letter`), deploy-tied incident (`:revert_feature_flag`), cardinality blowout (`:disable_metric_label`). (The two guidance-only playbooks — retry storm, suppression drift — are NOT worked examples here; they have no capability to author.)
- **D-16:** ExDoc wiring is the ONLY `mix.exs` change — NO `files:` edit. The `docs` glob in `files:` (`mix.exs:43`) already ships any `docs/*.md` to Hex. Add `docs/recovery-actions.md` to BOTH the `extras` list (`mix.exs:59-80`) AND the `groups_for_extras: Guides` group (`mix.exs:84-92`); omitting `extras` ships it to Hex but renders nothing in HexDocs (silently broken — build stays green).
- **D-17:** Cross-links: add a bullet to the "Next steps" list in `docs/getting-started.md:94-99` and a reference in the Preview-First Recovery section of `docs/operator-ui.md:179-208`.

### Sequencing

- **D-18:** Within the phase, the code surfaces (D-01..D-13: graduated module, gen task + template, doctor check) land BEFORE `docs/recovery-actions.md` (D-14..D-17), so the guide never references uncompilable or nonexistent surfaces. This is the v0.10 Phase 18 "code lands before docs" pattern. Plan-phase decides wave/PR grouping; the single-coherent-PR posture used across v1.1 phases is the default unless the planner finds a reason to split.

### Claude's Discretion

- Exact prose of the new/updated `recovery.ex` moduledoc (must carry the verbatim Stable admonition per D-01; rest can mirror `Parapet.Integration` style).
- Exact wording of the `docs/stability.md` Stable-row description and the compatibility-register note (must name the additive variants and the no-removal-in-1.x promise per D-06).
- Whether D-09 uses `Igniter.Project.Module.proper_location/3` or the explicit `gen.runbooks.ex` lib_dir derivation; whether D-10's test stub is raw (`create_new_file/4`) or EEx (`copy_template/5`).
- Exact `check_recovery` status thresholds beyond the D-12 defaults (informational vs warn boundaries) and message wording.
- Section ordering and worked-example depth in `recovery-actions.md` (must hit the D-14/D-15 content).

### Folded Todos

None — no pending todos matched this phase (`todo.match-phase 29` returned 0).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — STAB-07, ADOP-01, ADOP-02, ADOP-03 (Adopter Onboarding + Stability sections); Phase 29 traceability row.
- `.planning/ROADMAP.md` — Phase 29 entry + "### Phase 29: Stability + Adopter Onboarding" details (Goal, 4 Success Criteria).
- `.planning/phases/24-recovery-behaviour-capability-allowlist/24-CONTEXT.md` — D-01..D-08 (the frozen 4-callback shape + `__using__/1` + `attach/1` returning `{:ok, registered_ids}` that ADOP-02 counts); D-15/D-16 (stability admonition mechanism); deferred items list naming Phase 29 as the home for STAB-07/ADOP-01/ADOP-02/ADOP-03.
- `.planning/research/SUMMARY.md` + `.planning/research/PITFALLS.md` — v1.1 research synthesis.
- `lib/parapet/recovery.ex` — `:16-20` Experimental admonition to flip to Stable (D-01); `:30,38,47,56` the 4 frozen `@callback`s (D-02); `:59-63` `__using__/1` (frozen); `:87-106` `attach/1` returning `{:ok, registered_ids}` (the doctor count source for ADOP-02).
- `docs/stability.md` — `:10-13` exact tier-callout strings; `:24-38` Stable Modules table (destination for the moved row); `:49` current `Parapet.Recovery` Experimental row (source); `:144` outcome-vocabulary-freeze doctrine; `:190-198` Deprecation/Compatibility Register (home for the additive-variant note, D-06).
- `lib/mix/tasks/verify.public_api.ex` — `:104-114` `detect_tier_from_text/1` regex classifier (auto-reclassifies on moduledoc flip; **do NOT edit**, D-04).
- `lib/mix/tasks/parapet.gen.runbooks.ex` — `:5-15` Igniter task skeleton; `:18-24` base_name/module_prefix/lib_dir derivation; `:33-43` `Igniter.copy_template/5` idiom (template for gen.recovery, D-07..D-09).
- `lib/mix/tasks/parapet.gen.ui.ex` — `:5-16,33-44` alternate Igniter skeleton + copy_template reference.
- `lib/mix/tasks/parapet.gen.scoria.ex` `:32-36` / `lib/mix/tasks/parapet.gen.prometheus.ex` `:21-30` — `Igniter.create_new_file` precedent (test-stub creation, D-10).
- `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — `:1` `<%= inspect(@module_prefix) %>` template-header convention (D-08).
- `lib/mix/tasks/parapet.doctor.ex` — `:22` `@static_checks` (register `check_recovery`); `:76-94` dispatch clauses (add `run_static_check("recovery")`); `:96-115` existing `check_runbooks` (do NOT extend — keep separate, D-13); `:427-467` JSON/human output split.
- `lib/parapet/capabilities.ex` — `:14-20` 5-atom allowlist (frozen); `:52-56` `capabilities(:recovery)` (count source); `:62-66` `get_recovery/1` (cross-check + per-capability introspection, D-12).
- `lib/parapet/runbook.ex` — `:46-63` `step` macro carrying `:capability`; `:85-100` `__runbook_schema__/0` (the introspection ADOP-02 reads).
- `lib/parapet/spine/alert_processor.ex` — `:116-128` SLO-string → runbook-module discovery pattern (the ONLY static discovery path for ADOP-02's unregistered-capability check, D-12).
- `lib/parapet/operator.ex` — `:673-684` same `__runbook_schema__/0` step→capability resolution at the confirm/preview seam.
- `test/parapet/recovery_test.exs` — `:5-11` 4-callback fixture shape the gen template + test stub must emit (D-08, D-10).
- `test/mix/tasks/parapet.gen.runbooks_test.exs` — `Igniter.Test` assertion pattern (Rewrite.sources / module-header `=~`) the gen.recovery test should mirror.
- `mix.exs` — `:43` `files:` docs glob (no edit needed, D-16); `:59-80` `extras`; `:84-92` `groups_for_extras: Guides`; `:109` igniter 0.7.9 dep pin.
- `docs/getting-started.md` — `:94-99` "Next steps" cross-link insertion point (D-17).
- `docs/operator-ui.md` — `:179-208` Preview-First Recovery section (cross-link + UX reference target, D-14/D-17).
- `docs/slo-authoring-guide.md` — `:1,9,39,57,137` structural template for the adopter guide (D-14).
- `CHANGELOG.md` — `:1-13` Release-Please header stub confirming auto-ownership (no hand edits, D-05).
- Vendored `deps/igniter/` (0.7.9) — `lib/igniter/mix/task/info.ex:68-74` (positional schema); `lib/igniter/mix/task.ex:344-376` (required-arg enforcement); `lib/igniter/mix/task/args.ex:14` (positional accessor); `lib/igniter.ex:828-838` (`copy_template/5`), `:867` (`create_new_file/4`); `lib/igniter/project/module.ex:25-43,144-174` (`create_module/4` / `proper_location/3`).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`lib/mix/tasks/parapet.gen.runbooks.ex`** is the direct template for `gen.recovery`: `use Igniter.Mix.Task`, `info/2`, `igniter/1`, base_name/module_prefix/lib_dir derivation, `Igniter.copy_template/5` with `on_exists: :skip`. Only net-new is the single positional arg (`positional: [:name]`) and a recovery EEx template.
- **`lib/parapet/recovery.ex`** already ships the exact surface to graduate — the moduledoc admonition flip + `docs/stability.md` row move IS the STAB-07 deliverable for the module half. No callback edits.
- **`lib/mix/tasks/parapet.doctor.ex`** has a fixed check contract (`%{status:, messages:}` maps registered in `@static_checks`, dispatched via `run_static_check/1`, rendered by a JSON/human output split). `check_recovery` slots in with zero changes to the harness.
- **`lib/parapet/spine/alert_processor.ex:116-128`** holds the SLO-string → runbook-module → `__runbook_schema__/0` discovery pattern — the load-bearing reuse for ADOP-02's unregistered-capability check, since no runbook registry exists.
- **`docs/slo-authoring-guide.md`** is the structural and tonal template for `recovery-actions.md`.
- **`test/mix/tasks/parapet.gen.runbooks_test.exs`** is the `Igniter.Test` assertion template for the new gen-task test.

### Established Patterns

- **Tier classification via moduledoc admonition** — `mix verify.public_api` regex-classifies every `Parapet.*` module by its `@moduledoc` callout; `docs/stability.md` is the human mirror. Graduation = flip both, edit no task code.
- **Igniter generators are flag-based, never interactive** — Igniter has no prompt API; `gen.recovery` matches the SLO-W1 idiom planned for v1.2.
- **EEx template + `copy_template/5` for host-owned scaffolds** — `module_prefix`/`app_name` assigns, `<%= inspect(@module_prefix) %>` header, `on_exists: :skip`.
- **Doctor checks return `%{status: :ok | :warn | :error, messages: [...]}`** and are aggregated/rendered by the existing harness — adoption signals are `:warn`, never `:error` (absence of adoption is a nudge, not a failure).
- **No runbook registry** — host runbooks are reachable only through `slo.runbook` module-name strings resolved at call time. Any static analysis of runbook steps must go through `Parapet.SLO.all()`.
- **Code lands before docs that name it** (v0.10 Phase 18 / PROJECT.md Key Decisions) — graduated module + gen task + doctor check precede `recovery-actions.md`.

### Integration Points

- `lib/parapet/recovery.ex` moduledoc ↔ `mix verify.public_api` classifier ↔ `docs/stability.md` table — the three-way stability invariant STAB-07 flips.
- `mix parapet.gen.recovery` → `priv/templates/parapet.gen.recovery/recovery.ex.eex` → host `lib/<app>/parapet/recovery/<name>.ex` (+ test stub) — one-way scaffold; no runtime coupling.
- `mix parapet.doctor` `check_recovery` → `Parapet.Capabilities.capabilities(:recovery)`/`get_recovery/1` (registry read) + `Parapet.SLO.all()` → `__runbook_schema__/0` (runbook discovery) + `Code.ensure_loaded?`/`function_exported?` (host-module health) — read-only introspection, no mutation.
- `docs/recovery-actions.md` → `mix.exs` ExDoc `extras` + `groups_for_extras` (render) and ← cross-links from `getting-started.md` + `operator-ui.md`.

### Constraints

- The 4-callback shape and the 5-atom allowlist are FROZEN by this phase (graduating to Stable), not extended. Adding a required callback or a new atom is a breaking change reserved for a future minor with notice.
- Zero new runtime/dev dependencies (v1.1 milestone constraint). Igniter is already a dep (`mix.exs:109`).
- `CHANGELOG.md` is Release-Please-owned — no hand edits.
- All optional-dep code paths must compile out cleanly (`Code.ensure_loaded?`).
</code_context>

<specifics>
## Specific Ideas

- The new generator task file is `lib/mix/tasks/parapet.gen.recovery.ex`; the new template is `priv/templates/parapet.gen.recovery/recovery.ex.eex`; the new generated test path is `test/<app>/parapet/recovery/<name>_test.exs`.
- The new adopter guide is `docs/recovery-actions.md`.
- The doctor check is `check_recovery` and registers the string `"recovery"` in `@static_checks`.
- The `Parapet.Recovery` stability row MOVES tables (Experimental → Stable) — it is not duplicated and not left behind.
- Adoption-absence signals are `:warn`, never `:error` — a fresh install with zero capabilities still passes `mix parapet.doctor --ci`'s error gate.
- Igniter 0.7.9 positional arg: `positional: [:name]` in the `Info` struct; read `igniter.args.positional.name`; use `igniter/1` (not the deprecated `igniter/2`).
- The four `recovery-actions.md` worked examples are the four capability-backed playbooks only; the two guidance-only playbooks are excluded (nothing to author).
</specifics>

<deferred>
## Deferred Ideas

- **Adding a 6th allowlist atom or a 5th `Parapet.Recovery` callback** — out of scope; this phase FREEZES the existing surface to Stable. Any extension is a future-minor breaking change with notice.
- **Per-capability cooldown / breaker scope** (vs the system-scoped breaker today) — v1.2 (`.planning/REQUIREMENTS.md` Future Requirements).
- **Adapter-provided built-in capabilities** (e.g., Rulestead → built-in `:revert_feature_flag` implementation) — v1.2/v1.3; v1.1 ships the atom + worked example only, host implements.
- **MCP read-only Preview surface for recovery actions** — v1.3+ (stability-tier mismatch until MCP graduates).
- **`mix parapet.gen.slo` flag-based Igniter task** — v1.2 (SLO-W1).
- **Interactive (prompt-driven) generator UX** — permanently out; Igniter has no prompt API and the project standardized on flag-based generators.
- **Doctor auto-fix / scaffolding from the doctor check** — out of scope; `check_recovery` reports, it does not mutate.

### Reviewed Todos (not folded)

None — no pending todos matched this phase.
</deferred>
