# Phase 6: Verify Cardinality Protection - Research

**Researched:** 2026-05-21 [VERIFIED: system date]
**Domain:** Phase-close verification and planning-artifact reconciliation for TSDB cardinality protection [VERIFIED: .planning/ROADMAP.md]
**Confidence:** HIGH [VERIFIED: codebase grep, mix compile, mix test]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Verification artifact shape
- **D-01:** Phase 6 should produce a hybrid verification report: executable reruns are the primary proof surface, and short narrative sections exist only to explain why those reruns prove the claim.
- **D-02:** The verification report should be organized around observable truths and maintainer-relevant claims, not around Phase 1 task order or plan bookkeeping.
- **D-03:** The report should use a mixed structure: observable truths first, followed by compact requirement and plan-output crosswalks so audit traceability stays explicit without turning the artifact into a checklist dump.

### Proof scope and commands
- **D-04:** The closure-grade proof set for Phase 6 should center on `mix compile --force --warnings-as-errors`, `mix test test/parapet/metrics/validator_test.exs`, and `mix test test/mix/tasks/parapet.doctor_test.exs`.
- **D-05:** `mix parapet.doctor cardinality` should be treated as an advisory spot-check in this workspace, not as the primary proof, because the current project state can legitimately return `skip` when no SLOs are configured.
- **D-06:** Phase 6 should explicitly distinguish proof of implementation existence from proof of current behavior: source inspection proves the guardrails exist, while targeted reruns prove they still behave correctly.

### Closure and reconciliation boundaries
- **D-07:** Phase 6 should add a dedicated Phase 1 `VERIFICATION.md` that matches the repo's stronger v0.9 verification posture rather than relying on the older summary/UAT artifacts alone.
- **D-08:** Phase 6 should reconcile the directly covered requirement state for `PERF-01.a` and `PERF-01.b` in `.planning/REQUIREMENTS.md` once the verification artifact is written.
- **D-09:** Phase 6 should update the local Phase 1 validation/proof wording where it is now misleading or stale, including mismatches around doctor exit-code semantics and current workspace behavior.
- **D-10:** Phase 6 should not attempt milestone-wide artifact synchronization across `ROADMAP.md`, `STATE.md`, and future audit outputs unless the new proof directly changes those files' truth; broad milestone reconciliation remains Phase 9 work.

### Elixir/Phoenix proof posture and DX
- **D-11:** The verification style should stay idiomatic to Elixir/Phoenix OSS: rerunnable `mix` commands, precise file citations, and concise claim-to-evidence mapping rather than prose-heavy attestation.
- **D-12:** Great maintainer DX for this phase means future contributors can quickly answer "what exactly was proven, by which commands, and what remains out of scope?" without rereading Phase 1 implementation summaries.
- **D-13:** The report should preserve Parapet's brand and product posture from `prompts/`: calm, evidence-first, low-noise, explicit about uncertainty, and never overstating what the current workspace invocation proves.

### Maintainer workflow preference
- **D-14:** For this repo, later planning and verification agents should default to recommendation-first synthesis and decide low-impact proof/documentation details themselves.
- **D-15:** Agents should escalate only when a choice materially changes public API, install surface, runtime behavior, safety guarantees, irreversible maintenance burden, or overall project posture.
- **D-16:** The least-surprise long-term way to encode that preference is a checked-in repo instruction surface such as `AGENTS.md`, optionally mirrored by a short human-facing note in contributor docs; this is adjacent follow-on work, not core Phase 6 scope.

### Claude's Discretion
- Exact wording and section ordering inside the Phase 1 `VERIFICATION.md`, as long as executable proof remains primary and the report stays concise.
- Exact division between "observable truths", "behavioral spot-checks", and "requirements coverage", as long as the resulting artifact is easy to audit and matches the repo's Phase 2/5 verification posture.
- Whether to keep Phase 1's older summary/UAT files unchanged or add small clarifying corrections, provided the final proof surface stays honest about exit codes, skip behavior, and current provider/SLO posture.

### Deferred Ideas (OUT OF SCOPE)
- Add a repo-level `AGENTS.md` plus a small contributor-doc mirror so recommendation-first, low-escalation agent behavior becomes explicit across future phases.
- Broader milestone artifact synchronization across `ROADMAP.md`, `STATE.md`, and subsequent milestone audits after Phases 6-8 land.
- Modernize the doctor-cardinality tests away from deprecated `Parapet.SLO.define/2` if that becomes necessary for future maintainability; it is not required to close the current verification gap honestly.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PERF-01.a | System provides a `mix parapet.doctor cardinality` sub-command to statically analyze metrics configurations and flag unsafe label patterns. [VERIFIED: .planning/REQUIREMENTS.md] | Prove command existence from `Mix.Tasks.Parapet.Doctor`, prove behavior from `test/mix/tasks/parapet.doctor_test.exs`, and treat live workspace invocation as advisory only because zero configured SLOs yields `skip`. [VERIFIED: lib/mix/tasks/parapet.doctor.ex, test/mix/tasks/parapet.doctor_test.exs, mix parapet.doctor cardinality] |
| PERF-01.b | System strictly limits the number of labels per metric at compile-time to prevent accidental TSDB explosion. [VERIFIED: .planning/REQUIREMENTS.md] | Prove implementation from `Parapet.Metrics.Validator` plus built-in metric modules using it, and prove current behavior from compile + targeted validator tests. [VERIFIED: lib/parapet/metrics/validator.ex, lib/parapet/metrics/*.ex, mix compile, mix test] |
</phase_requirements>

## Summary

Phase 6 is a closure phase, not a feature phase. The codebase already contains both Phase 1 guardrails: compile-time metric validation through `Parapet.Metrics.Validator` and SLO query inspection through `mix parapet.doctor cardinality`. The audit gap is that this existing functionality is only summarized, not closure-proven in the stronger v0.9 verification format. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md, lib/parapet/metrics/validator.ex, lib/mix/tasks/parapet.doctor.ex]

The strongest proof shape is the same hybrid pattern already used successfully in Phase 2 and Phase 5: a compact `VERIFICATION.md` built around observable truths, targeted reruns, and a requirement crosswalk. For this phase, source inspection proves implementation existence, while fresh reruns prove current behavior. Those are different claims and should stay separate in the artifact. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md, .planning/v0.9-phases/5/VERIFICATION.md, mix compile, mix test]

The narrowness rule matters. Phase 6 should reconcile only the proof surfaces directly tied to `PERF-01.a` and `PERF-01.b`: add Phase 1 `VERIFICATION.md`, update Phase 1 validation wording where stale, update `REQUIREMENTS.md` once the proof exists, and correct any older artifact text that would otherwise overclaim current workspace behavior. Broader milestone synchronization remains Phase 9. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-phases/6/06-CONTEXT.md, .planning/v0.9-MILESTONE-AUDIT.md]

**Primary recommendation:** Use two execution plans: one to create Phase 1 closure-grade verification evidence, and one to reconcile only the directly affected planning artifacts. [VERIFIED: codebase inspection, .planning/v0.9-phases/6/06-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Compile-time metric label enforcement proof | API / Backend | Database / Storage | The guard lives in Elixir compile-time code and is proven by compile + unit tests, not by persisted state. [VERIFIED: lib/parapet/metrics/validator.ex, test/parapet/metrics/validator_test.exs] |
| SLO cardinality doctor proof | API / Backend | Repository / Planning Artifacts | The command implementation is backend Mix code; the closure artifact explains its current proof boundary. [VERIFIED: lib/mix/tasks/parapet.doctor.ex, test/mix/tasks/parapet.doctor_test.exs] |
| Requirement and validation reconciliation | Repository / Planning Artifacts | — | The remaining gap is documentation truthfulness and requirement state, not runtime ownership. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md, .planning/REQUIREMENTS.md, .planning/v0.9-phases/1/VALIDATION.md] |

## Recommended Proof Posture

### Proof of Implementation Existence

| Claim | Evidence | Why it matters |
|---|---|---|
| Compile-time validation exists. | `Parapet.Metrics.Validator` installs `@after_compile`, inspects `metrics/0`, raises `CompileError` when `length(metric.tags) > @max_labels`, and calls `Parapet.Internal.LabelPolicy.assert_safe!/1`. [VERIFIED: lib/parapet/metrics/validator.ex:6-23] | This proves the guardrail is implemented, not just planned. |
| The unsafe-label policy exists in one shared source of truth. | `LabelPolicy.assert_safe!/1` rejects labels ending in `id`, beginning with `raw_`, or containing `token` or `path`. [VERIFIED: lib/parapet/internal/label_policy.ex:6-17,49-54] | This is the policy both the validator and doctor depend on. |
| The doctor subcommand exists and dispatches `cardinality` as a supported static check. | `@static_checks` includes `cardinality`, `run_static_check/1` routes it to `check_cardinality/0`, and local/error/probe exit semantics are documented in the module. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:9-23,41-50,89-94] | This proves Phase 1 shipped a callable public surface. |
| Built-in metrics are wired into the validator. | Nine built-in metric modules include `use Parapet.Metrics.Validator`. [VERIFIED: rg "use Parapet.Metrics.Validator" lib/parapet/metrics/*.ex] | This proves the compile-time guard is applied across the built-in metric surface, not only in a standalone helper. |

### Proof of Current Behavior

| Claim | Command | Current result |
|---|---|---|
| Built-in metrics still compile under the guard. | `mix compile --force --warnings-as-errors` [VERIFIED: recommended command] | Passed in this session. [VERIFIED: mix compile] |
| Validator success and failure modes still behave as intended. | `mix test test/parapet/metrics/validator_test.exs` [VERIFIED: recommended command] | Passed: 3 tests, 0 failures. [VERIFIED: mix test] |
| Doctor cardinality check still distinguishes safe vs unsafe SLO queries. | `mix test test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: recommended command] | Passed: 10 tests, 0 failures. [VERIFIED: mix test] |
| A plain workspace invocation can legitimately produce no behavioral proof. | `mix parapet.doctor cardinality` [VERIFIED: recommended command] | Returned `skip` with “No SLOs defined”. [VERIFIED: mix parapet.doctor cardinality] |

### Exact Command Set To Center Verification On

Run these in this order to avoid build-lock noise and to keep the proof hierarchy explicit. [VERIFIED: mix compile/test lock contention observed during research]

```bash
mix compile --force --warnings-as-errors
mix test test/parapet/metrics/validator_test.exs
mix test test/mix/tasks/parapet.doctor_test.exs
mix parapet.doctor cardinality
```

Interpretation rules for the verification report: [VERIFIED: lib/mix/tasks/parapet.doctor.ex, mix parapet.doctor cardinality]
- The first three commands are primary closure proof. [VERIFIED: mix compile, mix test]
- The fourth command is a spot-check of current workspace posture, not requirement closure by itself. [VERIFIED: mix parapet.doctor cardinality]
- A `skip` result on the fourth command is honest and expected when `Parapet.SLO.all()` is empty. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:234-240, lib/parapet/slo.ex:70-79, mix parapet.doctor cardinality]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---|---|---|
| Elixir | `~> 1.19` project target. [VERIFIED: mix.exs:8] | Compile-time behavior and Mix task execution. [VERIFIED: mix.exs] | Phase 6 proof is entirely `mix`-driven. [VERIFIED: codebase inspection] |
| ExUnit | bundled with Elixir. [ASSUMED] | Targeted proof reruns for validator and doctor behavior. [VERIFIED: test/parapet/metrics/validator_test.exs, test/mix/tasks/parapet.doctor_test.exs] | Existing proof surface already lives here. [VERIFIED: codebase inspection] |
| `Mix.Tasks.Parapet.Doctor` | repo code. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] | Public static-analysis surface for `PERF-01.a`. [VERIFIED: .planning/REQUIREMENTS.md] | This is the user-facing command the requirement names. [VERIFIED: .planning/REQUIREMENTS.md] |
| `Parapet.Metrics.Validator` | repo code. [VERIFIED: lib/parapet/metrics/validator.ex] | Compile-time guard for `PERF-01.b`. [VERIFIED: .planning/REQUIREMENTS.md] | This is the runtime-independent proof surface for bounded built-in metrics. [VERIFIED: lib/parapet/metrics/validator.ex] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---|---|---|---|
| `telemetry_metrics` | `1.1.0`. [VERIFIED: mix deps] | Supplies metric structs with `tags` used by the validator tests. [VERIFIED: test/parapet/metrics/validator_test.exs] | Needed for compile-time validator coverage. [VERIFIED: test/parapet/metrics/validator_test.exs] |
| Sourceror | `1.12.0`. [VERIFIED: mix deps] | Used by other doctor checks, not by `cardinality`. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:117-216,234-287] | Mention only to avoid overstating `cardinality` complexity. [VERIFIED: code inspection] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Targeted compile + targeted tests | Full `mix test` suite | Broader but noisier; Phase 6 needs narrow closure evidence for two requirements, not milestone-wide reruns. [VERIFIED: phase scope in .planning/ROADMAP.md] |
| Test-backed proof as primary | Plain `mix parapet.doctor cardinality` as primary | Unsafe because the current workspace can return `skip`, which proves command posture but not configured-SLO analysis behavior. [VERIFIED: mix parapet.doctor cardinality, lib/mix/tasks/parapet.doctor.ex:234-240] |

## Architecture Patterns

### System Architecture Diagram

```text
Requirement claim
  -> implementation existence proof
     -> validator source
     -> label policy source
     -> doctor source
  -> current behavior proof
     -> mix compile
     -> validator tests
     -> doctor tests
  -> spot-check current workspace
     -> mix parapet.doctor cardinality
        -> if no SLOs: skip
        -> if SLOs exist: safe or unsafe result
  -> reconciliation
     -> Phase 1 VERIFICATION.md
     -> Phase 1 VALIDATION.md wording
     -> REQUIREMENTS.md statuses
     -> optional Phase 1 summary/UAT honesty fixes
```

### Recommended Project Structure

```text
.planning/
├── v0.9-phases/1/VERIFICATION.md   # new closure-grade proof artifact [VERIFIED: .planning/ROADMAP.md]
├── v0.9-phases/1/VALIDATION.md     # reconcile wording to the new proof boundary [VERIFIED: .planning/v0.9-phases/1/VALIDATION.md]
├── REQUIREMENTS.md                 # mark PERF-01.a and PERF-01.b once verification exists [VERIFIED: .planning/REQUIREMENTS.md]
└── phases/01-cardinality-protection/
    ├── 01-01-SUMMARY.md            # only if honesty correction is required [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md]
    └── 01-UAT.md                   # only if exit-code semantics remain misleading [VERIFIED: .planning/phases/01-cardinality-protection/01-UAT.md]
```

### Pattern 1: Separate Existence Proof From Behavior Proof

**What:** The verification report should first cite implementation anchors, then show reruns that prove those anchors still behave correctly. [VERIFIED: codebase inspection, Phase 2/5 verification artifacts]
**When to use:** Always, because the audit gap is “missing closure-grade verification” rather than “unknown implementation.” [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**Example:**

```markdown
| Truth | Evidence |
|---|---|
| `mix parapet.doctor cardinality` exists as a static check. | `lib/mix/tasks/parapet.doctor.ex:22,93,234-287` |
| Safe and unsafe cardinality cases still behave correctly. | `mix test test/mix/tasks/parapet.doctor_test.exs` |
```

### Pattern 2: Treat Live Doctor Output As Posture, Not Sole Proof

**What:** Report the live workspace `skip` result honestly and explain why targeted tests remain the closure lane. [VERIFIED: mix parapet.doctor cardinality, .planning/v0.9-phases/6/06-CONTEXT.md]
**When to use:** When a doctor command depends on optional app configuration that may be empty in the current workspace. [VERIFIED: lib/parapet/slo.ex:70-79, lib/mix/tasks/parapet.doctor.ex:234-240]
**Example:**

```markdown
`mix parapet.doctor cardinality` returned `skip` in this workspace because no SLOs are configured.
That confirms the command exists and its skip semantics are working, but it does not replace the targeted doctor tests as the requirement-closing proof.
```

### Anti-Patterns to Avoid

- **Overclaiming from `skip`:** Do not say the current workspace “validated cardinality successfully” when the actual output is `skip`. [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md, mix parapet.doctor cardinality]
- **Conflating exit code `1` with execution failure:** `error` findings halt with code `1`; code `2` is reserved for doctor execution failure or runtime probe failure. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:15-18,41-50]
- **Using full-milestone artifact cleanup as scope creep:** Phase 6 should not absorb ROADMAP/STATE synchronization beyond directly affected proof files. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-phases/6/06-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Proof of compile-time safety | A synthetic benchmark or ad hoc script | `mix compile --force --warnings-as-errors` plus `validator_test.exs` [VERIFIED: mix compile, test/parapet/metrics/validator_test.exs] | The validator is compile-time code; compile + focused tests are the direct proof surface. [VERIFIED: lib/parapet/metrics/validator.ex] |
| Proof of doctor behavior | Manual shell transcripts only | `doctor_test.exs` plus a live workspace spot-check [VERIFIED: test/mix/tasks/parapet.doctor_test.exs, mix parapet.doctor cardinality] | Tests cover safe and unsafe SLO cases that the current workspace does not instantiate. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs:143-168] |
| Artifact reconciliation | Milestone-wide state rewrite | Direct updates to Phase 1 proof artifacts and `REQUIREMENTS.md` only [VERIFIED: .planning/v0.9-phases/6/06-CONTEXT.md] | Keeps Phase 6 narrow and leaves Phase 9 intact. [VERIFIED: .planning/ROADMAP.md] |

**Key insight:** Phase 6 is strongest when it proves existing code through the smallest truthful rerun surface, then updates only the planning artifacts whose claims become directly falsifiable. [VERIFIED: codebase inspection, .planning/v0.9-MILESTONE-AUDIT.md]

## Required Artifact Updates For Scope Closure

| Artifact | Update | Why |
|---|---|---|
| `.planning/v0.9-phases/1/VERIFICATION.md` | Create a new closure-grade verification report using the Phase 2/5 structure. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-MILESTONE-AUDIT.md] | This is the missing artifact the audit explicitly calls out. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| `.planning/v0.9-phases/1/VALIDATION.md` | Reword from generic “covered” to explicit alignment with the new verification artifact and actual commands. [VERIFIED: .planning/v0.9-phases/1/VALIDATION.md] | Current wording is too thin for milestone-close proof. [VERIFIED: audit context + file inspection] |
| `.planning/REQUIREMENTS.md` | Mark `PERF-01.a` and `PERF-01.b` complete only after the verification artifact exists. [VERIFIED: .planning/REQUIREMENTS.md, .planning/v0.9-phases/6/06-CONTEXT.md] | Requirement traceability is currently orphaned. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| `.planning/phases/01-cardinality-protection/01-UAT.md` | Correct the stale claim that unsafe doctor findings should exit with code `2`; they exit with code `1`. [VERIFIED: .planning/phases/01-cardinality-protection/01-UAT.md, lib/mix/tasks/parapet.doctor.ex:15-18,41-50, test/mix/tasks/parapet.doctor_test.exs:163] | Leaving it unchanged creates a direct contradiction with shipped behavior. |
| `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md` | Correct or soften the claim that the current system configuration is validated successfully by `mix parapet.doctor cardinality`. [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md, mix parapet.doctor cardinality] | In this workspace the command currently returns `skip`, not a safe-config success result. |

## Exact Reconciliation Boundaries

- In scope: Phase 1 `VERIFICATION.md`, Phase 1 `VALIDATION.md`, `PERF-01.a` and `PERF-01.b` requirement state, and any older Phase 1 wording that would otherwise be demonstrably misleading. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-phases/6/06-CONTEXT.md]
- Out of scope: milestone-wide `STATE.md` / `ROADMAP.md` synchronization, Phase 3 or Phase 4 verification gaps, and modernization of deprecated SLO test setup. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-phases/6/06-CONTEXT.md]
- Boundary test: if a file does not change the truth of Phase 1 proof or `PERF-01.*` traceability, it belongs to Phase 9 or later. [VERIFIED: scope synthesis from roadmap + context]

## Common Pitfalls

### Pitfall 1: Proof of Existence Masquerading As Proof of Current Behavior

**What goes wrong:** A report cites the validator and doctor source files and declares the requirements closed without rerunning the targeted proof lanes. [VERIFIED: audit gap type in .planning/v0.9-MILESTONE-AUDIT.md]
**Why it happens:** The implementation already exists, so summary artifacts feel “close enough.” [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md]
**How to avoid:** Require both source citations and fresh reruns in `VERIFICATION.md`. [VERIFIED: Phase 2/5 verification posture]
**Warning signs:** The artifact contains only file citations or only prose copied from summaries. [VERIFIED: planning artifact comparison]

### Pitfall 2: Overclaiming From A `skip` Doctor Result

**What goes wrong:** A live `mix parapet.doctor cardinality` run is treated as a green behavioral proof even though there are no configured SLOs. [VERIFIED: mix parapet.doctor cardinality]
**Why it happens:** The command returns exit code `0`, which is easy to misread as “feature fully verified.” [VERIFIED: lib/mix/tasks/parapet.doctor.ex:41-46,234-240]
**How to avoid:** Record `skip` as workspace posture only and lean on targeted tests for safe/unsafe SLO coverage. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs:143-168]
**Warning signs:** Wording like “validates current configuration successfully” without mentioning zero SLOs. [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md]

### Pitfall 3: Exit-Code Drift In Older Artifacts

**What goes wrong:** UAT or summaries describe fatal findings as exit code `2`. [VERIFIED: .planning/phases/01-cardinality-protection/01-UAT.md]
**Why it happens:** Doctor semantics evolved, but older artifacts were not reconciled. [VERIFIED: comparison of UAT vs current code/tests]
**How to avoid:** Reconcile older Phase 1 wording during this phase, but only where it changes Phase 1 truthfulness. [VERIFIED: .planning/v0.9-phases/6/06-CONTEXT.md]
**Warning signs:** Documentation says “fatal” or “probe failure” when the check is actually a standard `error` finding. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:15-18,259-263]

## Code Examples

### Closure-Grade Verification Lane

```bash
# Source: repo proof posture synthesized from Phase 2/5 verification and current reruns
mix compile --force --warnings-as-errors
mix test test/parapet/metrics/validator_test.exs
mix test test/mix/tasks/parapet.doctor_test.exs
mix parapet.doctor cardinality
```

### Implementation Anchors To Cite

```text
lib/parapet/metrics/validator.ex:6-23
lib/parapet/internal/label_policy.ex:6-17
lib/mix/tasks/parapet.doctor.ex:22-23
lib/mix/tasks/parapet.doctor.ex:234-287
test/parapet/metrics/validator_test.exs:7-51
test/mix/tasks/parapet.doctor_test.exs:143-168
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Summary/UAT-only attestation for Phase 1. [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md, .planning/phases/01-cardinality-protection/01-UAT.md] | Dedicated `VERIFICATION.md` with reruns and traceability, matching Phases 2 and 5. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md, .planning/v0.9-phases/5/VERIFICATION.md] | v0.9 verification posture by 2026-05-20 and 2026-05-21. [VERIFIED: verification file headers] | Phase 1 can be audited consistently with the rest of the milestone. [VERIFIED: milestone audit needs] |
| “Current config validates successfully” wording. [VERIFIED: .planning/phases/01-cardinality-protection/01-01-SUMMARY.md] | “Current workspace may legitimately `skip`; behavior proof comes from targeted tests.” [VERIFIED: mix parapet.doctor cardinality, test/mix/tasks/parapet.doctor_test.exs] | Current as of 2026-05-21. [VERIFIED: command rerun date] | Prevents overstating the live workspace guarantee. |

**Deprecated/outdated:**
- `Parapet.SLO.define/2` is deprecated in code but still used by doctor tests. That is acceptable for Phase 6 proof closure and should not be expanded into refactor scope here. [VERIFIED: lib/parapet/slo.ex:28-67, mix test warning output, .planning/v0.9-phases/6/06-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | ExUnit is bundled with Elixir in this environment. [ASSUMED] | Standard Stack | Low; Phase 6 still uses existing `mix test` commands either way. |

## Open Questions (RESOLVED)

1. **Should Phase 6 edit the older Phase 1 summary and UAT files, or only add caveats in the new verification report?**
   - Resolution: Edit the older Phase 1 summary and UAT files directly. This is required by D-09 because both files contain concrete contradictions about current doctor semantics or current workspace behavior, and leaving them unchanged would preserve stale local proof wording. [VERIFIED: .planning/v0.9-phases/6/06-CONTEXT.md, .planning/phases/01-cardinality-protection/01-UAT.md, .planning/phases/01-cardinality-protection/01-01-SUMMARY.md, mix parapet.doctor cardinality]
   - Scope boundary: Keep the edits narrow to those contradictions only; broader milestone artifact synchronization still belongs to Phase 9 per D-10. [VERIFIED: .planning/v0.9-phases/6/06-CONTEXT.md, .planning/ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `mix` / Elixir toolchain | All proof commands | ✓ [VERIFIED: mix compile, mix test] | Elixir target `~> 1.19`. [VERIFIED: mix.exs:8] | — |
| Test database connectivity | `mix test` targeted proof lanes | ✓ [VERIFIED: mix test created tables and passed] | Repo-backed test env, exact DB server version not checked. [VERIFIED: mix test output, ASSUMED for server version] | None for these tests. |

**Missing dependencies with no fallback:**
- None found during research. [VERIFIED: mix compile, mix test]

**Missing dependencies with fallback:**
- None found during research. [VERIFIED: mix compile, mix test]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit in a Mix project. [VERIFIED: test files, mix.exs] |
| Config file | none detected; project uses standard Mix/ExUnit layout. [VERIFIED: repo file scan] |
| Quick run command | `mix test test/parapet/metrics/validator_test.exs test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: repo test paths] |
| Full suite command | `mix test` [VERIFIED: Mix convention, repo layout, ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| PERF-01.a | Doctor command handles safe and unsafe SLO label cases. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs:143-168] | unit / command behavior | `mix test test/mix/tasks/parapet.doctor_test.exs` | ✅ [VERIFIED: file exists] |
| PERF-01.b | Compile-time validator accepts safe metrics and rejects over-tagged or unsafe-tagged metrics. [VERIFIED: test/parapet/metrics/validator_test.exs:7-51] | unit / compile-time | `mix test test/parapet/metrics/validator_test.exs` | ✅ [VERIFIED: file exists] |
| PERF-01.b | Built-in metric modules still compile with the validator applied. [VERIFIED: lib/parapet/metrics/*.ex] | compile gate | `mix compile --force --warnings-as-errors` | ✅ [VERIFIED: command passed] |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/metrics/validator_test.exs test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: recommended command]
- **Per wave merge:** `mix compile --force --warnings-as-errors && mix test test/parapet/metrics/validator_test.exs test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: recommended proof posture]
- **Phase gate:** Add `mix parapet.doctor cardinality` output to the report as a spot-check, but do not use it as the sole closing proof. [VERIFIED: mix parapet.doctor cardinality]

### Wave 0 Gaps

- None in executable proof surfaces; the gap is missing closure-grade documentation and stale wording reconciliation. [VERIFIED: mix compile, mix test, .planning/v0.9-MILESTONE-AUDIT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no [VERIFIED: phase scope] | — |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | no [VERIFIED: phase scope] | — |
| V5 Input Validation | yes [VERIFIED: threat model in .planning/v0.9-phases/1/PLAN.md] | `Parapet.Internal.LabelPolicy.assert_safe!/1` plus compile-time validator and doctor parsing. [VERIFIED: lib/parapet/internal/label_policy.ex, lib/parapet/metrics/validator.ex, lib/mix/tasks/parapet.doctor.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | — |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| High-cardinality metric labels explode TSDB series count. [VERIFIED: .planning/REQUIREMENTS.md, .planning/v0.9-phases/1/PLAN.md] | Denial of Service | Compile-time tag-count cap plus unsafe-label rejection. [VERIFIED: lib/parapet/metrics/validator.ex, lib/parapet/internal/label_policy.ex] |
| Unsafe labels leak into SLO PromQL groupings or selectors. [VERIFIED: .planning/v0.9-phases/1/PLAN.md] | Denial of Service | `mix parapet.doctor cardinality` extracts labels and rejects unsafe ones through the shared policy. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:234-287, lib/parapet/internal/label_policy.ex] |

## Suggested Plan Decomposition

**Recommended number of execution plans:** 2. [VERIFIED: research synthesis against scope]

1. **Plan A — Produce Phase 1 `VERIFICATION.md`.** Create the closure-grade report, rerun the exact command set, and capture the implementation-vs-behavior distinction with precise citations. [VERIFIED: .planning/v0.9-phases/6/06-CONTEXT.md, mix compile, mix test]
2. **Plan B — Reconcile direct proof artifacts.** Update Phase 1 `VALIDATION.md`, mark `PERF-01.a` and `PERF-01.b` in `REQUIREMENTS.md`, and correct only the stale Phase 1 summary/UAT wording that would otherwise contradict the new report. [VERIFIED: .planning/REQUIREMENTS.md, .planning/v0.9-phases/1/VALIDATION.md, .planning/phases/01-cardinality-protection/01-UAT.md, .planning/phases/01-cardinality-protection/01-01-SUMMARY.md]

Why two and not one: one plan would mix evidence production with artifact cleanup and make review noisier; three plans would fragment a narrow closure task and invite Phase 9 scope bleed. [VERIFIED: scope synthesis from roadmap + audit + context]

## Risks / Non-Goals / Honesty Constraints

- Do not claim that current workspace output proves configured-SLO safety; it currently proves only command existence plus correct `skip` semantics. [VERIFIED: mix parapet.doctor cardinality]
- Do not describe unsafe doctor findings as exit code `2`; the current contract uses code `1` for thresholded findings and `2` for execution/probe failures. [VERIFIED: lib/mix/tasks/parapet.doctor.ex:15-18,41-50, test/mix/tasks/parapet.doctor_test.exs:163,205]
- Do not mark broader milestone documents complete from this phase alone unless the changed files become directly true as a result. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-phases/6/06-CONTEXT.md]
- Do not expand this phase into provider migration work just because `Parapet.SLO.define/2` is deprecated in tests. [VERIFIED: lib/parapet/slo.ex:28-29, mix test warning output, .planning/v0.9-phases/6/06-CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md` - active Phase 6 scope and milestone boundary. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - `PERF-01.a` / `PERF-01.b` wording and current unchecked state. [VERIFIED: codebase grep]
- `.planning/v0.9-MILESTONE-AUDIT.md` - audit diagnosis and closure gap. [VERIFIED: codebase grep]
- `.planning/v0.9-phases/6/06-CONTEXT.md` - locked decisions and scope boundaries. [VERIFIED: codebase grep]
- `lib/parapet/metrics/validator.ex` - compile-time enforcement implementation. [VERIFIED: codebase grep]
- `lib/parapet/internal/label_policy.ex` - shared unsafe-label policy. [VERIFIED: codebase grep]
- `lib/mix/tasks/parapet.doctor.ex` - command contract, check routing, skip/error semantics. [VERIFIED: codebase grep]
- `test/parapet/metrics/validator_test.exs` - validator behavioral proof surface. [VERIFIED: codebase grep]
- `test/mix/tasks/parapet.doctor_test.exs` - doctor behavioral proof surface. [VERIFIED: codebase grep]
- `mix compile --force --warnings-as-errors` - current compile proof. [VERIFIED: command rerun]
- `mix test test/parapet/metrics/validator_test.exs` - current validator proof. [VERIFIED: command rerun]
- `mix test test/mix/tasks/parapet.doctor_test.exs` - current doctor proof. [VERIFIED: command rerun]
- `mix parapet.doctor cardinality` - current workspace posture proof. [VERIFIED: command rerun]

### Secondary (MEDIUM confidence)

- `.planning/v0.9-phases/2/VERIFICATION.md` - strong verification-structure analog. [VERIFIED: codebase grep]
- `.planning/v0.9-phases/5/VERIFICATION.md` - strong verification-structure analog and doctor-proof boundary analog. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- None. [VERIFIED: research inventory]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools and proof surfaces were verified from the codebase and rerun locally except the generic ExUnit bundling note. [VERIFIED: mix.exs, mix deps, mix compile, mix test]
- Architecture: HIGH - the phase boundary and reconciliation scope are explicit in the roadmap, audit, and Phase 6 context. [VERIFIED: .planning/ROADMAP.md, .planning/v0.9-MILESTONE-AUDIT.md, .planning/v0.9-phases/6/06-CONTEXT.md]
- Pitfalls: HIGH - each pitfall is backed by an observed contradiction or current command result. [VERIFIED: UAT, summary, doctor code, command reruns]

**Research date:** 2026-05-21 [VERIFIED: system date]
**Valid until:** 2026-06-20 for planning scope; rerun commands before implementation if workspace config changes. [VERIFIED: research synthesis]

## RESEARCH COMPLETE
