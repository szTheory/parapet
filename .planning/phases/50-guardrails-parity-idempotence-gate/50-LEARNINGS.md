---
phase: 50
phase_name: "guardrails-parity-idempotence-gate"
project: "Parapet"
generated: "2026-06-28"
counts:
  decisions: 9
  lessons: 5
  patterns: 7
  surprises: 5
missing_artifacts:
  - "UAT.md"
---

# Phase 50 Learnings: guardrails-parity-idempotence-gate

## Decisions

### D-03: Fix the EEx comment defect with `<%%#`, never by stripping comments
At `operator_components.ex.eex` lines 1428/1442 the generator used `<%#-` — an EEx **build-time** comment that renders to an empty string — so a fresh `mix parapet.gen.ui` silently dropped the two D-07/D-08 WCAG-1.4.1 rationale comments present in the demo mirror. Fixed by switching to `<%%#` (an EEx escape that renders the literal `<%# … %>` into output) so generation reproduces the mirror byte-for-byte.

**Rationale:** GUARD-03 exists to catch exactly this drift; the parity test had to pass for the *right* reason (template reproduces mirror), not by deleting the divergent comments. The plan explicitly forbade resolving drift by stripping comments and provided a `<%!-- … --%>` modernization fallback if the chosen syntax warned.
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### GUARD-03: Normalize both sides through `Code.format_string!/1`, reject AST-compare
The parity test normalizes generated output and the committed mirror through `Code.format_string!/1` before asserting equality, rather than comparing parsed ASTs via `Code.string_to_quoted`.

**Rationale:** AST-compare discards comments and would have masked the D-03 bug entirely. Formatting both sides (rather than trusting the mirror to already be canonically formatted) is also robust across formatter versions.
**Source:** 50-01-PLAN.md (T-50-02), 50-01-SUMMARY.md

### GUARD-04: Fail-closed palette gate sourced live from tokens.css + 5 documented exceptions
The off-palette-hex gate parses the allowlist live from `brandbook/tokens/tokens.css` at test time, asserts `MapSet.size(allowlist) >= 31` (fail-closed), and permits exactly 5 named exceptions declared as a module attribute, each sourced from the audit-matrix rationale (no bare inline literals).

**Rationale:** A broken or empty parse must fail the gate explicitly rather than silently admit any hex (T-50-01). Sourcing exceptions only from the documented audit-matrix section prevents a silent palette backdoor (T-50-03).
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### GUARD-05: Tolerant regex for the easing curve, not a literal string match
Motion easing is asserted via `~r/cubic-bezier\(\s*0?\.2\s*,\s*0\s*,\s*0\s*,\s*1\s*\)/` rather than a literal string.

**Rationale:** The template writes `cubic-bezier(.2, 0, 0, 1)` while tokens.css writes `cubic-bezier(0.2, 0, 0, 1)` — a literal match would fail on the leading-zero/whitespace disagreement. The test also locks BOTH `--motion-fast: 0ms` and `--motion-base: 0ms` under prefers-reduced-motion (the prior test only covered `--motion-fast`).
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### D-13: Extract a shared `OperatorUIPaths` helper as the single source of truth for template↔mirror paths
Created `Parapet.TestSupport.OperatorUIPaths` (plain module, `@moduledoc false`, no `use`) exposing `component_paths/0`, `live_template_paths/0`, `detail_template_paths/0`, consumed by all three new test files.

**Rationale:** The six template↔mirror file paths were duplicated across test files; centralizing them prevents drift and keeps the new gates DRY.
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### D-14: One shared bash array drives both capture and `--manifest`, with a DB-free placeholder route
The 15 duplicated `capture …` call sites were refactored into a single `CAPTURES` array (`name|size|path|theme`). A `--manifest` mode iterates the same array to emit the baseline table, exiting before any Chrome/curl/`DETAIL_ID` DB resolution. Detail routes store `:detail_id` literally; capture mode substitutes the resolved id (`path="${path/:detail_id/$DETAIL_ID}"`).

**Rationale:** Making the script the single source of truth structurally eliminates the Phase-49 stale-count drift risk — capture and manifest can no longer diverge. The placeholder keeps `--manifest` runnable with no infra.
**Source:** 50-02-PLAN.md, 50-02-SUMMARY.md

### D-17: Put the manifest-drift CI check in the Postgres-free quality/lint job
The "Operator UI manifest drift" step runs `diff <(… --manifest) <(sed -n '/^| name /,/^Total: /p' operator-ui-baseline.md)` in the no-DB lint job, not the Postgres-backed test job.

**Rationale:** `--manifest` needs no Chrome, DB, or server, so the gate adds negligible CI cost and requires no new services (T-50-05 accepted by design). Byte-stable `^| name`/`^Total:` anchors make local and CI extraction identical.
**Source:** 50-02-PLAN.md, 50-02-SUMMARY.md

### D-18/D-19: The milestone audit is a thin evidence-binding doc, coherent-by-reference
`v1.6-MILESTONE-AUDIT.md` binds every requirement row to a re-runnable command or a `file:line` — no bare "see phase N" — and references `operator-audit-matrix.md` as the single idempotence ledger rather than duplicating it.

**Rationale:** An audit claim that does not resolve to a re-runnable artifact gives false assurance (T-50-06). Coherence-by-reference keeps the matrix as the one ledger.
**Source:** 50-03-PLAN.md, 50-03-SUMMARY.md

### D-21: Do NOT add `telemetry_stable.json` this milestone — defer to backlog
The deferred stable-telemetry manifest was recorded as `tech_debt`/backlog in the audit frontmatter, not as a gap.

**Rationale:** It is out of v1.6 UI-brand scope; the operator UI is host-owned markup that adds no telemetry events, so the existing `telemetry_contract_test.exs` is sufficient non-regression proof for this milestone.
**Source:** 50-03-PLAN.md, 50-03-SUMMARY.md

---

## Lessons

### `mix verify.public_api` surfaced a pre-existing stability-tier gap during the audit
Running the public-API gate for the audit (plan 03) exited 1: `Parapet.Evidence.Archiver.Summary` and `Parapet.Evidence.Archiver.Failure` nested modules had `@moduledoc` strings with no `> #### Experimental {: .warning}` tier declaration. This was a latent gap from the archiver feature, not introduced by Phase 50.

**Context:** Auto-fixed under Rule 1 (added the Experimental tier to both nested modules, refreshed the stable manifest). The audit pass doubled as a drift sweep that caught an unrelated regression. Running a milestone-wide verification gate is itself a discovery mechanism, not just a confirmation step.
**Source:** 50-03-SUMMARY.md

### The stable manifest had silently missed a phase-48 public function
Refreshing `priv/parapet/public_api_stable.json` also picked up `Parapet.Operator.fetch_incident_detail/1`, added back in phase 48 but never committed to the stable manifest.

**Context:** A public function can drift out of the recorded manifest for multiple phases if the gate isn't re-run with `--write` at each addition. The milestone audit was the first time it was reconciled.
**Source:** 50-03-SUMMARY.md

### A comment-stripping "fix" would have masked the very bug GUARD-03 exists to catch
The naive way to make the parity test green was to delete the divergent WCAG comments from the mirror. That would have passed the test while erasing accessibility rationale and defeating the gate's purpose.

**Context:** The plan pre-empted this by mandating `Code.format_string!` normalization (comment-preserving) and explicitly rejecting AST-compare. When a test and a "fix" can both go green, the normalization strategy is what decides whether the test is meaningful.
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### There is no pre-font baseline tarball to subtract for the package-size delta
The font delta could only be reported honestly as a reproducible pair: absolute woff2 total (53,428 bytes / 52.2 KB across 5 files, machine-checked under the 153,600-byte ceiling) plus the post-v1.6 `mix hex.build` Package size (262 KB), with an explicit note that no pre-font release exists to diff against.

**Context:** When a clean "before" measurement doesn't exist, report the honest reproducible pair and label it, rather than fabricating a delta.
**Source:** 50-03-PLAN.md, 50-03-SUMMARY.md

### When PATTERNS.md and a plan's must_haves disagree, must_haves win
The PATTERNS.md sketch showed a 4-column manifest header (`name | route | viewport | theme`) while the plan's `must_haves` and the `operator-ui-baseline.md` structure both specified a 5th `scenario` column. The 5-column format was used.

**Context:** PATTERNS.md is an advisory sketch; the plan frontmatter `must_haves` are authoritative. Keeping script output and committed baseline consistent is what matters for the diff gate.
**Source:** 50-02-SUMMARY.md

---

## Patterns

### Igniter.Test real-generator invocation for byte-parity testing
Drive the actual generator with `igniter = test_project(app_name: :demo_app) |> Ui.igniter()`, then read content via `Rewrite.source!(igniter.rewrite, path) |> Rewrite.Source.get(:content)`. This exercises the real `copy_template` pipeline with real `@web_module`/`@repo_module` assigns.

**When to use:** Any time you need to assert that a code generator's output matches a committed mirror — invoke the real transform, don't reconstruct it.
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### Fail-closed allowlist gate
Parse the allowlist live from a source file, then `assert MapSet.size(allowlist) >= N` before scanning. A broken/empty parse fails the gate explicitly instead of admitting everything.

**When to use:** Any test that derives an allowlist from a parsed artifact — guard the parse so tampering or breakage fails closed, never open.
**Source:** 50-01-PLAN.md (T-50-01), 50-01-SUMMARY.md

### Tolerant regex for CSS/value comparisons across formatters
Match semantically-equivalent values (`(.2,…)` vs `(0.2,…)`, variable whitespace) with a tolerant regex rather than a literal string.

**When to use:** When the same value is authored in two places with cosmetic differences (leading zeros, whitespace) but must be asserted equivalent.
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### Shared bash array as single source of truth for capture + manifest
Encode each capture as one array element (`name|size|path|theme`); both the capture loop and the `--manifest` emitter iterate the same array. Mode-specific data (a DB-resolved id) is substituted only in the relevant mode.

**When to use:** Whenever two outputs must stay in lockstep (e.g. an artifact and its manifest of that artifact) — drive both from one list so they cannot drift.
**Source:** 50-02-PLAN.md, 50-02-SUMMARY.md

### `--manifest` mode: a DB-free, CI-enforceable snapshot of a side-effectful script
Add a flag that short-circuits before all infra (Chrome, server, DB, network) and emits a byte-stable Markdown table (no timestamps, no resolved ids). Commit it and diff in CI.

**When to use:** When you want CI to enforce the *shape/coverage* of an expensive side-effectful process without running the process itself.
**Source:** 50-02-PLAN.md, 50-02-SUMMARY.md

### Byte-stable anchors for `sed`-extractable committed blocks
Delimit a verbatim committed block with stable line anchors (`^| name `…`^Total: `) and keep the sentinel un-bolded so a single `sed -n '/^| name /,/^Total: /p'` extraction matches identically in local verify and CI.

**When to use:** Any committed-output-vs-live-output diff gate — pick anchors that survive Markdown rendering and use the exact same extraction everywhere.
**Source:** 50-02-PLAN.md, 50-02-SUMMARY.md

### Evidence-binding audit: every claim resolves to a command or file:line
Build the milestone audit as a per-requirement table where each Evidence cell is a runnable `mix test …`/`grep -n …` command or a `file:line`, with real pasted output in a Verification Commands block — coherent-by-reference with the existing ledger, never duplicating it.

**When to use:** Closing a milestone — make every assurance independently re-runnable and falsifiable instead of a hand-wave.
**Source:** 50-03-PLAN.md, 50-03-SUMMARY.md

---

## Surprises

### A "one-liner" EEx comment was silently producing empty output
`<%#-` looked like a harmless comment but is a build-time construct that renders to nothing, so the generated component had been missing its WCAG rationale comments — a defect invisible until a byte-parity test forced the comparison.

**Impact:** Confirmed the value of byte-parity (not AST) testing; the one-character distinction between `<%#-` and `<%%#` was the entire bug.
**Source:** 50-01-PLAN.md, 50-01-SUMMARY.md

### The public-API gate failed on a latent, out-of-scope defect
`mix verify.public_api` exited 1 the first time it was run for the audit — not because of any Phase-50 change, but because of two archiver nested modules missing tier declarations carried over from an earlier feature.

**Impact:** Added an unplanned Rule 1 auto-fix (archiver tiers + stable-manifest refresh) to a documentation-only plan; the audit incidentally hardened an unrelated subsystem.
**Source:** 50-03-SUMMARY.md

### A phase-48 public function had never reached the stable manifest
`Parapet.Operator.fetch_incident_detail/1` was only recorded into `public_api_stable.json` during this milestone's manifest refresh.

**Impact:** Revealed that the public-API manifest can lag real additions across phases unless `--write` is run at each change; the audit reconciled it.
**Source:** 50-03-SUMMARY.md

### PATTERNS.md and the plan disagreed on the manifest's column count
The patterns sketch showed 4 columns; the must_haves required 5 (`scenario`). Caught at execution and resolved toward must_haves.

**Impact:** Minor, but a reminder that the patterns file is advisory; the divergence was reconciled so the diff gate stays green.
**Source:** 50-02-SUMMARY.md

### The whole phase landed extremely fast
Plan 01 took ~3 minutes and plan 02 ~114 seconds despite producing four new test files, a shared helper, a script refactor, a committed baseline, and a CI step.

**Impact:** The heavy up-front decision work (D-01…D-23 in the plans) made execution near-mechanical — most of the cost had already been paid in planning.
**Source:** 50-01-SUMMARY.md, 50-02-SUMMARY.md
