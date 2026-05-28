# Phase 29: Stability + Adopter Onboarding - Research

**Researched:** 2026-05-28
**Domain:** Elixir library stability graduation, Igniter code generation, ExDoc wiring, Mix task introspection
**Confidence:** HIGH (all claims verified against live code; design fully pre-locked in 29-CONTEXT.md)

> **Scope note:** Design is DONE (18 locked decisions D-01..D-18 in 29-CONTEXT.md). This document
> ONLY verifies the specific cited file:line claims hold in the live codebase, adds pitfalls, and
> provides the Validation Architecture section. It does not re-derive the design.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Graduate Recovery by flipping TWO anchors only — moduledoc admonition + stability.md table row move.
- D-02: 4 @callbacks FROZEN verbatim — no signature edits.
- D-03: Callback-freeze prose added to moduledoc/stability.md; no new code.
- D-04: verify.public_api needs NO edits — regex auto-reclassifies on moduledoc flip.
- D-05: CHANGELOG.md is Release-Please-owned — no hand edits.
- D-06: Migration warning delivered via commit body/footer + Deprecation/Compatibility Register in stability.md.
- D-07: gen.recovery is flag-based Igniter task using igniter/1 (not deprecated igniter/2); positional: [:name].
- D-08: EEx template priv/templates/parapet.gen.recovery/recovery.ex.eex via Igniter.copy_template/5 on_exists: :skip.
- D-09: Module path via Igniter.Project.Module.proper_location/3 OR explicit gen.runbooks.ex lib_dir derivation (plan-phase picks).
- D-10: Test stub via Igniter.create_new_file/4 or copy_template/5 with on_exists: :skip.
- D-11: check_recovery registered in @static_checks; dispatch clause in doctor.ex.
- D-12: Three signals — capability count (zero=:warn), unregistered-capability-in-runbook (:warn), per-module health (:warn).
- D-13: check_recovery is separate from check_runbooks — do NOT extend check_runbooks.
- D-14: recovery-actions.md follows slo-authoring-guide.md structure.
- D-15: Four worked examples = four capability-backed playbooks only.
- D-16: ExDoc wiring = add to extras + groups_for_extras ONLY (no files: edit needed).
- D-17: Cross-links in getting-started.md:94-99 and operator-ui.md:179-208.
- D-18: Code surfaces (D-01..D-13) land BEFORE recovery-actions.md.

### Claude's Discretion
- Exact prose of recovery.ex moduledoc (must carry verbatim Stable admonition).
- Exact wording of stability.md Stable-row description and compatibility-register note.
- Whether D-09 uses proper_location/3 or explicit lib_dir derivation.
- Whether D-10 test stub is raw (create_new_file/4) or EEx (copy_template/5).
- check_recovery status thresholds beyond D-12 defaults and message wording.
- Section ordering and worked-example depth in recovery-actions.md.

### Deferred Ideas (OUT OF SCOPE)
- 6th allowlist atom or 5th callback.
- Per-capability cooldown/breaker scope (v1.2).
- Adapter-provided built-in capabilities (v1.2/v1.3).
- MCP read-only Preview surface (v1.3+).
- mix parapet.gen.slo (v1.2).
- Interactive generator UX (permanently out).
- Doctor auto-fix/scaffolding.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-07 | Graduate Parapet.Recovery to Stable; CHANGELOG migration notes for additive return variants | D-01..D-06 verified — moduledoc admonition at :16-20 confirmed, stability.md row at :49 confirmed |
| ADOP-01 | mix parapet.gen.recovery <NAME> Igniter scaffold task | D-07..D-10 verified — Igniter 0.7.9 positional API confirmed, copy_template/5 + create_new_file/4 confirmed |
| ADOP-02 | mix parapet.doctor recovery adoption signal | D-11..D-13 verified — @static_checks at :22 confirmed, dispatch pattern at :89-94 confirmed, introspection primitives confirmed |
| ADOP-03 | docs/recovery-actions.md adopter guide, ExDoc-wired, cross-linked | D-14..D-17 verified — extras at :59-80 confirmed, groups_for_extras at :84-92 confirmed, cross-link insertion points confirmed |
</phase_requirements>

---

## Summary

Phase 29 closes the v1.1 milestone by graduating `Parapet.Recovery` to Stable, shipping an
Igniter generator for host-app recovery modules, adding a doctor adoption signal, and writing
the adopter guide with ExDoc wiring. All 18 implementation decisions are pre-locked in
29-CONTEXT.md and verified correct against the live codebase.

The codebase is fully ready: the moduledoc admonition, the 4 frozen callbacks, the doctor
harness contract, the Igniter 0.7.9 positional API, and the ExDoc extras/groups wiring points
are all exactly as CONTEXT.md described. Three small drift/nuance findings are flagged below;
none are blockers.

**Primary recommendation:** Execute the locked plan. Code surfaces first (D-18 wave), then
docs. No research gaps remain.

---

## Verification Results

### STAB-07 — recovery.ex and stability.md anchors

**`lib/parapet/recovery.ex:16-20` — Experimental admonition (the flip target)**
CONFIRMED. Lines 16-20 read exactly:
```
> #### Experimental {: .warning}
>
> This module is **experimental** in v1.x. Its API may change in a minor release with a
> single-version notice in CHANGELOG.md. See
> [Stability & Deprecation Policy](stability.html) for details.
```
The target Stable callout string (`> #### Stable {: .info}`) is documented at
`docs/stability.md:10-13`. [VERIFIED: live file read]

**`lib/parapet/recovery.ex:30,38,47,56` — 4 frozen @callbacks**
CONFIRMED. Exact signatures at those lines:
- `:30` — `@callback id() :: atom()`
- `:38` — `@callback label() :: String.t()`
- `:47` — `@callback preview(incident :: any(), step :: any()) :: {:ok, map()} | {:error, term()}`
- `:56` — `@callback execute(incident :: any(), target_refs :: any()) :: {:ok, map()} | {:error, term()}`
[VERIFIED: live file read]

**`lib/parapet/recovery.ex:59-63` — `__using__/1` macro**
CONFIRMED. Lines 58-63:
```elixir
@doc false
defmacro __using__(_opts) do
  quote do
    @behaviour Parapet.Recovery
  end
end
```
Injects ONLY `@behaviour Parapet.Recovery` — no extra attrs. [VERIFIED: live file read]

**`lib/parapet/recovery.ex:87-106` — `attach/1` returning `{:ok, registered_ids}`**
CONFIRMED. `def attach(modules)` starts at line 87; returns `{:ok, registered}` at line 105.
[VERIFIED: live file read]

**`docs/stability.md:10-13` — Tier-callout strings**
CONFIRMED. The table at lines 10-13 defines both strings:
- Stable: `> #### Stable {: .info}`
- Experimental: `> #### Experimental {: .warning}`
[VERIFIED: live file read]

**`docs/stability.md:24-38` — Stable Modules table (destination)**
CONFIRMED. Table spans lines 24-38 (13 Stable entries). `Parapet.Recovery` is NOT currently
in this table — insertion is the required change. [VERIFIED: live file read]

**`docs/stability.md:49` — Parapet.Recovery Experimental row (source)**
CONFIRMED. Line 49 reads: `| \`Parapet.Recovery\` | Host-app-facing recovery action behaviour + activation function |`
It is in the Experimental table. The row MOVES out; it is not duplicated. [VERIFIED: live file read]

**`docs/stability.md:144` — Outcome-vocabulary-freeze doctrine**
CONFIRMED. Line 144: `- Changing the atoms in an outcome vocabulary (e.g., \`:delivered\` → \`:sent\`)`
under the "Breaking" section. The migration note (D-06) is a concrete instance of this rule.
[VERIFIED: live file read]

**`docs/stability.md:190-198` — Deprecation/Compatibility Register**
CONFIRMED. The register table header is at line 195, with the `Parapet.SLO.define/2`
deprecation entry at line 197. The additive-variant note (D-06) adds a second row here.
[VERIFIED: live file read]

**`lib/mix/tasks/verify.public_api.ex:104-114` — `detect_tier_from_text/1` regex classifier**
CONFIRMED. Lines 103-114:
```elixir
def detect_tier_from_text(text) do
  cond do
    Regex.match?(~r/####\s+Stable\s*\{:\s*\.info\}/, text) -> :stable
    Regex.match?(~r/####\s+Experimental\s*\{:\s*\.warning\}/, text) -> :experimental
    true -> :unclassified
  end
end
```
Flipping the admonition to `> #### Stable {: .info}` will auto-reclassify. No task edits
needed. [VERIFIED: live file read]

---

### ADOP-01 — Igniter task skeleton and vendored API

**`lib/mix/tasks/parapet.gen.runbooks.ex:5-15` — Igniter task skeleton**
CONFIRMED. Uses `use Igniter.Mix.Task`, `@example`, `@shortdoc`, `def info/2` returning
`%Igniter.Mix.Task.Info{}`, `def igniter(igniter)`. The gen.recovery task directly mirrors
this pattern, adding only `positional: [:name]`. [VERIFIED: live file read]

**`lib/mix/tasks/parapet.gen.runbooks.ex:18-24` — base_name/module_prefix/lib_dir derivation**
CONFIRMED:
```elixir
web_module = Igniter.Libs.Phoenix.web_module(igniter)
app_name = Igniter.Project.Application.app_name(igniter)
base_name = web_module |> inspect() |> String.trim_trailing("Web")
runbook_module_prefix = Module.concat([base_name, "Parapet", "Runbooks"])
lib_dir = Path.join(["lib", "#{app_name}", "parapet", "runbooks"])
```
gen.recovery substitutes "Recovery" for "Runbooks" and adds the NAME segment.
[VERIFIED: live file read]

**`lib/mix/tasks/parapet.gen.runbooks.ex:33-43` — `Igniter.copy_template/5` idiom**
CONFIRMED. Call signature: `Igniter.copy_template(igniter, source_path, dest_path, assigns, on_exists: :skip)`. [VERIFIED: live file read]

**Igniter 0.7.9 positional arg API**
CONFIRMED against `deps/igniter/lib/mix/task/info.ex`:
- `positional:` field accepts a list of atoms (bare atom = required, `:optional false` default)
- Line 14 of that file documents `positional` field; line 14 of `args.ex` shows `defstruct positional: %{}, ...`
- Read via `igniter.args.positional.name` (map access, not keyword list)
[VERIFIED: live vendored source]

**`igniter/1` vs `igniter/2`**
CONFIRMED. `deps/igniter/lib/mix/task.ex` line 35: `@doc deprecated: "Use igniter/1 instead"` on the `igniter/2` callback. Line 157: warning emitted if both are defined. Use `igniter/1` only. [VERIFIED: live vendored source]

**`Igniter.copy_template/5` and `create_new_file/4`**
CONFIRMED. `deps/igniter/lib/igniter.ex`:
- `copy_template/5` at line 835 (renders EEx, calls `create_new_file`)
- `create_new_file/4` at line 868 (primitive; accepts `on_exists:` opt)
- Old `create_new_file/3` at line 812 is `@deprecated` — use 4-arg form
[VERIFIED: live vendored source]

---

### ADOP-02 — doctor.ex harness and introspection primitives

**`lib/mix/tasks/parapet.doctor.ex:22` — `@static_checks`**
CONFIRMED. Line 22:
```elixir
@static_checks ~w(runbooks router operator_ui endpoint cardinality cluster_static)
```
"recovery" is NOT in this list — it must be added. [VERIFIED: live file read]

**DRIFT NOTE — `parse_requested_checks/1` guard (line 67)**
The guard at line 67 reads: `unsupported = Enum.reject(checks, &(&1 in @static_checks))`.
This means adding "recovery" to `@static_checks` automatically enables `mix parapet.doctor
recovery` as a valid selective check argument. No separate guard edit is needed. This is
consistent with D-11 — but CONTEXT.md did not call it out explicitly. The planner should
include it as an automatic consequence of the `@static_checks` append.

**`lib/mix/tasks/parapet.doctor.ex:89-94` — dispatch clauses**
CONFIRMED. Pattern:
```elixir
defp run_static_check("runbooks"), do: check_runbooks()
defp run_static_check("router"), do: check_router()
...
defp run_static_check("cluster_static"), do: check_cluster_static()
```
Add `defp run_static_check("recovery"), do: check_recovery()` after line 94. [VERIFIED: live file read]

**`lib/mix/tasks/parapet.doctor.ex:96-115` — existing `check_runbooks`**
CONFIRMED. `check_runbooks` (lines 96-115) only checks that `slo.runbook` string is non-nil/non-empty. It does NOT load runbook modules. `check_recovery` is a genuinely separate concern (D-13). [VERIFIED: live file read]

**`lib/mix/tasks/parapet.doctor.ex:427-467` — JSON/human output split**
CONFIRMED. `print_results/3` at line 427 handles `--ci` (JSON via Jason) and human-readable
with color by `:status` atom (`:info`, `:warn`, `:error`, `:skip`). The `%{status:, messages:}`
contract slots in with zero harness changes. [VERIFIED: live file read]

**`lib/parapet/capabilities.ex:52-56` — `capabilities(:recovery)`**
CONFIRMED:
```elixir
def capabilities(:recovery) do
  Agent.get(__MODULE__, fn state -> state.recovery |> Map.values() end)
end
```
Returns a list of capability maps. The count is `length(capabilities(:recovery))`. [VERIFIED: live file read]

**`lib/parapet/capabilities.ex:62-66` — `get_recovery/1`**
CONFIRMED:
```elixir
def get_recovery(id) do
  Agent.get(__MODULE__, fn state -> Map.get(state.recovery, id) end)
end
```
Returns `nil` if unregistered — the cross-check sentinel. [VERIFIED: live file read]

**`lib/parapet/runbook.ex:85-100` — `__runbook_schema__/0`**
CONFIRMED. Generated by `__before_compile__` at lines 85-100:
```elixir
def __runbook_schema__() do
  %{module: to_string(__MODULE__), title: ..., description: ..., steps: ...}
end
```
`steps` is a list of step maps; each step carries a `:capability` key (from the `step` macro).
[VERIFIED: live file read]

**`lib/parapet/spine/alert_processor.ex:116-128` — SLO-string → runbook-module discovery**
CONFIRMED. `build_runbook_data/2` at lines 116-130:
```elixir
slo = Enum.find(Parapet.SLO.all(), fn s -> to_string(s.name) == alertname end)
case slo do
  %{runbook: runbook} when not is_nil(runbook) ->
    module = get_runbook_module(runbook)
    if module && Code.ensure_loaded?(module) &&
         function_exported?(module, :__runbook_schema__, 0) do
      apply(module, :__runbook_schema__, [])
      ...
    end
  _ -> ...
end
```
The `check_recovery` implementation iterates ALL SLOs (not filtered by alertname) and applies
the same `Code.ensure_loaded?` + `function_exported?` guards before calling `__runbook_schema__/0`.
URL strings that fail `get_runbook_module/1` parse return `nil` and fall through safely.
[VERIFIED: live file read]

---

### ADOP-03 — mix.exs ExDoc wiring and cross-link insertion points

**`mix.exs:43` — `files:` docs glob**
CONFIRMED. Line 43: `~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* LICENSE* docs)`.
The `docs` entry ships the entire `docs/` directory to Hex. No `files:` edit needed (D-16).
[VERIFIED: live file read]

**`mix.exs:59-80` — `extras` list**
CONFIRMED. 18 entries listed. `docs/recovery-actions.md` is NOT present — it must be added.
[VERIFIED: live file read]

**`mix.exs:84-92` — `groups_for_extras: Guides`**
CONFIRMED. Lines 84-92: the `Guides` group currently contains `docs/adopter-flows.md`,
`docs/operator-ui.md`, `docs/slo-authoring-guide.md`, `docs/troubleshooting.md`,
`docs/release-policy.md`, `docs/HISTORY.md`, `CHANGELOG.md`. `docs/recovery-actions.md`
must be added to BOTH `extras` and this `Guides` list. [VERIFIED: live file read]

**`mix.exs:109` — igniter dep pin**
CONFIRMED. Line 109: `{:igniter, "~> 0.7.9"}`. [VERIFIED: live file read]

**`docs/getting-started.md:94-99` — "Next steps" cross-link insertion point**
CONFIRMED. Lines 94-99 are the "## Next steps" section with 4 existing bullets. A 5th bullet
linking to `docs/recovery-actions.md` inserts naturally here. [VERIFIED: live file read]

**`docs/operator-ui.md:179-208` — Preview-First Recovery cross-link target**
CONFIRMED. Lines 179-208 are the "## Phase 7 Preview-First Recovery" section describing
Safe Recovery Principles, Recovery Flow, and Named Capabilities. The adopter guide references
this section (D-14); a sentence pointing back to `recovery-actions.md` goes at the end of
this block or after the Named Capabilities subsection (line 208). [VERIFIED: live file read]

---

### Test fixture pattern

**`test/parapet/recovery_test.exs:5-11` — 4-callback fixture shape**
CONFIRMED. The fixture modules at lines 5-11 define:
```elixir
defmodule Parapet.RecoveryTest.FixtureRetryAsync do
  use Parapet.Recovery
  def id, do: :retry_async_item
  def label, do: "Retry Async (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end
```
The EEx template for gen.recovery must emit this exact shape (with `@name_camelized` for the
module name, and user-facing docstrings as placeholders). [VERIFIED: live file read]

**`test/mix/tasks/parapet.gen.runbooks_test.exs` — Igniter.Test assertion pattern**
CONFIRMED. Pattern: `test_project(app_name: :test) |> Task.igniter()` then check
`Rewrite.sources(igniter.rewrite)` paths and `Rewrite.source!(igniter.rewrite, path)` content
with `=~` assertions. The gen.recovery test mirrors this exactly with a single named output
file rather than a fixed catalog. [VERIFIED: live file read]

---

## Pitfalls

### Pitfall 1: ExDoc extras/groups must BOTH be updated (silent failure)

**What goes wrong:** Adding `docs/recovery-actions.md` to `extras` only ships the file to Hex
but HexDocs renders nothing. Adding to `groups_for_extras` alone causes ExDoc to error
("unknown extra"). Neither step is sufficient alone.

**Why it happens:** ExDoc has a two-step registration: `extras` makes the file known to the
build; `groups_for_extras` places it in the sidebar. Omitting `extras` means HexDocs silently
ignores the file. The build remains green.

**How to avoid:** D-16 is explicit — add to BOTH lists in the same commit. Verification task:
after the PR merges, confirm `https://hexdocs.pm/parapet/recovery-actions.html` resolves (or
verify locally with `mix docs` and check the generated `doc/` directory contains the file with
sidebar entry).

**Warning signs:** `mix docs` succeeds but the generated `doc/index.html` Guides sidebar does
not list "Recovery Actions".

---

### Pitfall 2: Stability three-way invariant must move together

**What goes wrong:** Flipping the moduledoc admonition without moving the `docs/stability.md`
row causes `mix verify.public_api` to classify Recovery as Stable (green gate) while the human
doc still shows it as Experimental. Or vice versa — moving the row without flipping the admonition
causes the doc to lie in the other direction.

**Why it happens:** The classifier reads only the moduledoc; the stability.md table is manually
maintained. They are independent.

**How to avoid:** D-04 + D-01 must land in the SAME commit. Verification: after the commit,
run `mix verify.public_api` and check that Recovery appears in the Stable column, then open
`docs/stability.md` and confirm Recovery is in the Stable table only.

**Warning signs:** `mix verify.public_api` output disagrees with `docs/stability.md` on
Recovery's tier.

---

### Pitfall 3: CHANGELOG hand-edit clobbered by Release Please

**What goes wrong:** Manually adding a `## Unreleased` section to `CHANGELOG.md` gets
clobbered or duplicated on the next Release Please run, producing a malformed changelog.

**Why it happens:** Release Please owns `CHANGELOG.md` entirely — it parses, rewrites, and
re-emits the file on each release PR.

**How to avoid:** D-05/D-06 are explicit — the migration warning travels via the conventional
commit body/footer on the Phase 29 feat commit (Release Please renders commit bodies into the
generated release entry) AND as a new row in `docs/stability.md:190-198` Deprecation Register.
Never touch `CHANGELOG.md` directly.

**Warning signs:** Any file diff targeting `CHANGELOG.md` in a non-Release-Please PR.

---

### Pitfall 4: check_recovery must tolerate URL runbooks and missing host modules

**What goes wrong:** `check_recovery`'s unregistered-capability signal iterates
`Parapet.SLO.all()` and resolves each `slo.runbook` string as a module. Some hosts set
`runbook:` to a URL string (e.g., `"https://wiki.example.com/runbook"`). Calling
`String.to_atom/1` or `Module.concat/1` on a URL string and then `Code.ensure_loaded?/1`
on the result either crashes or returns a misleading error.

**Why it happens:** The `slo.runbook` field is typed as `String.t()` and accepts both
module-name strings (e.g., `"MyApp.Parapet.Runbooks.StalledExecutor"`) and URLs.

**How to avoid:** Mirror the `alert_processor.ex:116-128` guard exactly: `get_runbook_module/1`
returns `nil` for URL strings; the `if module && Code.ensure_loaded?(module)` guard then
short-circuits. URL-valued SLOs must produce a SKIP, not a warning or error. The same
`Code.ensure_loaded?/1` + `function_exported?/2` pattern applies for per-capability health
checks.

**Warning signs:** `check_recovery` returning `:error` for a host that only has URL runbooks
(false positive that blocks `--ci`).

---

### Pitfall 5: Doctor adoption signals must be :warn, never :error

**What goes wrong:** Classifying zero-capability-count or an unregistered capability reference
as `:error` causes `mix parapet.doctor --ci` to exit 1 on a fresh install (before the adopter
has wired any capabilities). This makes the doctor a hostile gate, not a helpful nudge.

**Why it happens:** The default `--ci` threshold is `:warn` (line 54: `defp parse_threshold(nil, true), do: :warn`), meaning `:warn` findings DO fail CI by default. So signals that should be nudges must be `:warn` rather than `:info` to be visible, but never `:error` to avoid false CI failures.

**CORRECTION — CI threshold clarification:** Reading `doctor.ex:54` directly: `parse_threshold(nil, true)` returns `:warn`. The `findings_exit_code/2` function gates on findings whose severity meets or exceeds the threshold. This means `:warn` findings WILL fail CI under `--ci`. Therefore the "zero capabilities = :warn" approach from D-12 WILL cause `mix parapet.doctor --ci` to exit 1 on a fresh install with no capabilities registered.

**Resolution (from CONTEXT.md specifics):** The stated invariant is "a fresh install with zero capabilities still passes `mix parapet.doctor --ci`'s error gate." This is consistent only if zero-capability-count emits `:info` (not `:warn`) or if `:skip` is used when no capabilities are registered (mirroring `check_runbooks` which returns `:skip` when no SLOs are defined). The planner must resolve this: map zero-capabilities to `:skip` or `:info`, not `:warn`, to avoid the CI false-positive. The `:warn` signal should fire only when capabilities ARE registered but something is wrong (e.g., an unregistered capability referenced in a runbook step).

**Warning signs:** `mix parapet.doctor --ci` exits 1 on a clean demo app install.

---

### Pitfall 6: gen.recovery positional arg must be required, not optional

**What goes wrong:** If `positional: [:name]` is declared as `positional: [name: [optional: true]]`,
the task runs silently with `igniter.args.positional.name` being `nil`, producing a scaffolded
file with a nil module name.

**Why it happens:** Igniter `Info` positional args default to `optional: false` when declared
as a bare atom — but the default can be overridden accidentally.

**How to avoid:** Use the bare atom form `positional: [:name]` as in D-07. Igniter raises
`ArgumentError` automatically if the user omits the arg (verified at `task.ex:360-362`).
Do not wrap it in a keyword list unless `:rest` is also needed.

---

## Validation Architecture

### Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test --only unit` |
| Full suite command | `mix test` |
| Igniter-specific | `import Igniter.Test` in generator tests |

---

### STAB-07: Stability Graduation

**Observable signal:** `mix verify.public_api` classifies `Parapet.Recovery` as `:stable`;
`docs/stability.md` Stable table contains the Recovery row and Experimental table does not.

**Tests:**

| Req | Behavior | Test Type | Command | File |
|-----|----------|-----------|---------|------|
| STAB-07 | verify.public_api classifies Recovery as :stable after moduledoc flip | Unit (task invocation) | `mix test test/mix/tasks/verify_public_api_test.exs` | Existing — add a new test case |
| STAB-07 | detect_tier_from_text/1 returns :stable for the Stable admonition string | Unit | `mix test test/mix/tasks/verify_public_api_test.exs` | Existing (function is public @doc false) |
| STAB-07 | stability.md Stable table contains Recovery row | Manual / doc review | `grep "Parapet.Recovery" docs/stability.md` | N/A — grep assertion in CI or Wave gate |

**Acceptance criteria for planner:**
- `mix verify.public_api` exits 0 and output contains `Parapet.Recovery` in the stable section.
- `grep "Parapet.Recovery" docs/stability.md` matches ONLY within the Stable table block.
- `docs/stability.md` Deprecation Register contains the additive-variant note for `confirm_runbook_step/4`.

---

### ADOP-01: gen.recovery Igniter Task

**Observable signal:** Running the task on a test project creates the expected source file and
test stub at the correct paths with the correct module header and 4 callback stubs.

**Tests:**

| Req | Behavior | Test Type | Command | File |
|-----|----------|-----------|---------|------|
| ADOP-01 | Creates lib/<app>/parapet/recovery/<name>.ex with use Parapet.Recovery + 4 callbacks | Unit (Igniter.Test) | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | New — Wave 0 gap |
| ADOP-01 | Creates test/<app>/parapet/recovery/<name>_test.exs stub | Unit (Igniter.Test) | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | New — Wave 0 gap |
| ADOP-01 | Missing positional arg raises ArgumentError | Unit | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | New — Wave 0 gap |
| ADOP-01 | Existing file not overwritten (on_exists: :skip) | Unit (Igniter.Test) | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | New — Wave 0 gap |

**Acceptance criteria for planner:**
- `test_project(app_name: :test) |> Gen.Recovery.igniter(...)` — `Rewrite.sources` contains path `"lib/test/parapet/recovery/<name>.ex"`.
- Source content `=~ "use Parapet.Recovery"` and `=~ "def id"` and `=~ "def label"` and `=~ "def preview"` and `=~ "def execute"`.
- Test stub path `"test/test/parapet/recovery/<name>_test.exs"` present in sources.
- Task with no NAME arg raises before `igniter/1` is called (Igniter enforces this).

**Pattern reference:** Mirror `test/mix/tasks/parapet.gen.runbooks_test.exs` exactly:
`test_project |> Task.igniter() |> Rewrite.sources(igniter.rewrite) |> Enum.map(&path) |> assert contains`.

---

### ADOP-02: doctor check_recovery

**Observable signal:** `mix parapet.doctor` output includes a `recovery:` check entry; status
reflects the three D-12 signal conditions; `mix parapet.doctor --ci` exits 0 on a fresh
install with zero capabilities.

**Tests:**

| Req | Behavior | Test Type | Command | File |
|-----|----------|-----------|---------|------|
| ADOP-02 | Zero capabilities → :skip or :info (not :warn); doctor --ci exits 0 | Unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | Existing — add case |
| ADOP-02 | N capabilities registered → :ok with count message | Unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | Existing — add case |
| ADOP-02 | SLO runbook step references unregistered capability → :warn | Unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | Existing — add case |
| ADOP-02 | SLO runbook is URL string → SKIP (no error, no warn) | Unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | Existing — add case |
| ADOP-02 | Registered capability host module missing (Code.ensure_loaded? false) → :warn | Unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | Existing — add case |
| ADOP-02 | Registered capability host module missing callback → :warn | Unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | Existing — add case |

**Acceptance criteria for planner:**
- `check_recovery()` returns `%{status: :skip | :info, messages: [...]}` when `capabilities(:recovery)` is empty.
- With N registered capabilities and all healthy: `%{status: :ok, messages: ["N recovery capabilities registered and healthy."]}` (or similar).
- With unregistered capability in runbook: `%{status: :warn, messages: [...]}` containing the capability atom name.
- With URL runbook: same result as if that SLO had no runbook — no error or spurious warn.
- `mix parapet.doctor --ci` exit code 0 on fresh install (no capabilities).

---

### ADOP-03: Adopter Guide + ExDoc Wiring

**Observable signal:** `mix docs` succeeds; `doc/recovery-actions.md.html` (or equivalent)
is present in `doc/` output; Guides sidebar entry for "Recovery Actions" exists; cross-links
in getting-started.md and operator-ui.md are valid (no broken-reference warnings from ExDoc).

**Tests:**

| Req | Behavior | Test Type | Command | File |
|-----|----------|-----------|---------|------|
| ADOP-03 | mix docs builds without error | Integration (doc build) | `mix docs 2>&1 \| grep -i error` | N/A |
| ADOP-03 | recovery-actions.md rendered in doc/ output | Integration | `ls doc/recovery-actions.html` | N/A |
| ADOP-03 | No undefined reference warnings for cross-links | Integration | `mix docs 2>&1 \| grep -i "undefined\|broken"` | N/A |
| ADOP-03 | extras list contains recovery-actions.md | Unit / config review | `grep "recovery-actions" mix.exs` | mix.exs |
| ADOP-03 | groups_for_extras Guides contains recovery-actions.md | Unit / config review | `grep "recovery-actions" mix.exs` | mix.exs |

**Acceptance criteria for planner:**
- `mix docs` exits 0 with no `[undefined]` or broken-reference warnings on `recovery-actions.md`.
- `doc/recovery-actions.html` exists after `mix docs`.
- `grep "recovery-actions" mix.exs` matches in BOTH the `extras` list and the `Guides` group.
- `grep "recovery-actions" docs/getting-started.md` and `grep "recovery-actions" docs/operator-ui.md` both match.

---

### Sampling Rate

- **Per task commit (Wave 1 — code surfaces):** `mix test test/mix/tasks/parapet.gen.recovery_test.exs test/mix/tasks/parapet_doctor_test.exs test/mix/tasks/verify_public_api_test.exs`
- **Per wave merge (Wave 2 — docs + ExDoc wiring):** `mix test && mix docs`
- **Phase gate:** Full suite green (`mix test`) + `mix docs` clean + `mix verify.public_api` shows Recovery as Stable before marking phase complete.

### Wave 0 Gaps (test files that must exist before implementation)

- [ ] `test/mix/tasks/parapet.gen.recovery_test.exs` — new file; Igniter.Test assertions for ADOP-01
- [ ] New test cases in `test/mix/tasks/parapet_doctor_test.exs` — check_recovery signal cases for ADOP-02
- [ ] New test case in `test/mix/tasks/verify_public_api_test.exs` — Stable reclassification for STAB-07

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Zero-capabilities should emit :skip or :info (not :warn) to avoid CI false-positive. CONTEXT.md says zero-capabilities is :warn but also says doctor --ci passes on fresh install. These are contradictory given that --ci threshold is :warn (line 54). Resolution proposed: use :skip when Capabilities Agent has zero recovery entries. | Pitfall 5 / ADOP-02 | If :warn is used, fresh installs fail CI — hostile gate for new adopters. |

**All other claims in this research were verified against live code or vendored deps.** The
single ambiguity (A1) is a status-level choice within Claude's Discretion (per CONTEXT.md).

---

## Sources

### Primary (HIGH confidence — verified against live code)
- `lib/parapet/recovery.ex` — moduledoc admonition, 4 callbacks, __using__/1, attach/1
- `docs/stability.md` — tier-callout strings, Stable table, Experimental row :49, outcome-vocab doctrine :144, Deprecation Register :190-198
- `lib/mix/tasks/verify.public_api.ex:104-114` — detect_tier_from_text/1 regex
- `lib/mix/tasks/parapet.gen.runbooks.ex` — Igniter skeleton, lib_dir derivation, copy_template/5 idiom
- `lib/mix/tasks/parapet.doctor.ex` — @static_checks, dispatch clauses, check_runbooks, JSON/human output split
- `lib/parapet/capabilities.ex:52-66` — capabilities(:recovery), get_recovery/1
- `lib/parapet/runbook.ex:85-100` — __runbook_schema__/0
- `lib/parapet/spine/alert_processor.ex:116-128` — SLO-string → runbook-module discovery pattern
- `test/parapet/recovery_test.exs:5-11` — 4-callback fixture shape
- `test/mix/tasks/parapet.gen.runbooks_test.exs` — Igniter.Test assertion pattern
- `mix.exs:43,59-80,84-92,109` — files glob, extras, groups_for_extras, igniter pin
- `docs/getting-started.md:94-99` — Next steps insertion point
- `docs/operator-ui.md:179-208` — Preview-First Recovery cross-link target
- `deps/igniter/lib/mix/task/info.ex` — positional arg schema
- `deps/igniter/lib/mix/task/args.ex:14` — Args struct (positional is a map)
- `deps/igniter/lib/mix/task.ex` — igniter/2 deprecated, positional enforcement
- `deps/igniter/lib/igniter.ex` — copy_template/5 at :835, create_new_file/4 at :868

---

## RESEARCH COMPLETE

All four deliverables verified. No blocking gaps. One discretion-level ambiguity (A1: zero-capability
status level) flagged for planner resolution. Ready for PLAN.md.
