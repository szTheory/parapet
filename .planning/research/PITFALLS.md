# Pitfalls Research

**Domain:** Adopter-funnel + SLO guidance + recovery depth on an existing Elixir/Phoenix OSS SRE library (Parapet v0.10)
**Researched:** 2026-05-23
**Confidence:** HIGH (all pitfalls grounded in direct codebase audit + verified ecosystem patterns)

---

## Critical Pitfalls

### Pitfall 1: Demo Deps Leaking Into the Published Hex Package

**What goes wrong:**
Demo or example app dependencies (Phoenix, Ecto, Faker, etc.) are added to the top-level
`mix.exs` `deps/0` rather than isolated to the demo app's own `mix.exs`. This pollutes
the published package's dependency tree and can force transitive dep conflicts on every
Parapet adopter.

**Why it happens:**
The demo app needs `phoenix`, `phoenix_live_view`, `ecto_sql`, `postgrex`, and `oban` to
run. A developer working on the demo wires these into the top-level `mix.exs` for
convenience (they can `mix deps.get` once), not realizing the `deps/0` list is also what
Hex publishes as the package manifest.

**How to avoid:**
The `demo/` directory must contain its own isolated `mix.exs`. The demo app declares
`{:parapet, path: "../../"}` for the local path reference and all its own dependencies
independently. The top-level Parapet `mix.exs` never touches demo deps.

Separately: do not add `demo/` or `example*/` to the `files:` whitelist in `mix.exs`.
Current whitelist is `~w(lib priv .formatter.exs mix.exs README* docs)` — demo is
excluded by default and must stay that way. The only `files:` change needed for v0.10 is
adding `CHANGELOG*` (not `demo/`).

Verification: run `mix hex.build --unpack` locally and inspect the unpacked tarball
contents. If any file under `demo/` appears, the whitelist is wrong.

**Warning signs:**
- A developer runs `mix deps.get` at the repo root and new Phoenix/Faker packages appear
  in the top-level `mix.lock`
- `mix hex.build --dry-run` output lists files under `demo/`
- CI `mix deps.get` starts pulling Phoenix as a non-optional dep

**Phase to address:**
Demo Harness phase (Pillar A). Add `mix hex.build --dry-run | grep demo` as a CI check
that must produce zero matches before the demo is merged.

---

### Pitfall 2: Demo Drifts to a Stale Hex Snapshot Instead of the Live Lib

**What goes wrong:**
The demo app's `mix.exs` switches from `{:parapet, path: "../../"}` to
`{:parapet, "~> 0.1"}` (a published Hex version) either accidentally or as a convenience
move. The demo then exercises Hex-published code, not the current branch. Breaking changes
in the library are invisible until someone notices the demo is running stale behavior.

**Why it happens:**
`path:` references require the demo to compile from source on every `mix deps.get`. A
developer who just wants to run the demo without touching the library switches to a
published version for speed. This is easy to miss in review.

**How to avoid:**
Lock `{:parapet, path: "../../"}` in `demo/app/mix.exs` and enforce it in CI with a
check that grep-asserts `path:` is present in that file. Add a comment above the dep:
`# MUST remain a path reference — never switch to published Hex version`.

CI should compile and run `mix parapet.doctor` inside `demo/app/` as part of the CI
matrix so any breakage in the live lib immediately breaks the demo job.

**Warning signs:**
- `demo/app/mix.lock` contains a `:parapet` entry with a hex hash rather than a path ref
- `demo/app/mix.exs` lists `{:parapet, "~> 0.1"}`
- CI demo job passes even when a breaking change is introduced to `lib/`

**Phase to address:**
Demo Harness phase (Pillar A). The CI job that runs the demo must be added in the same
phase the demo is created — not retrofitted later.

---

### Pitfall 3: Getting-Started Guide That Assumes Prometheus/PromQL Expertise

**What goes wrong:**
The getting-started guide explains SLO configuration in terms of PromQL internals
(recording rules, `rate()` windows, burn multipliers) rather than in terms of what the
adopter wants to accomplish (monitor login failures, alert when checkout is degraded).
An adopter who is not a Prometheus expert hits PromQL in step 2 and abandons.

**Why it happens:**
The library author knows PromQL. The generated artifacts are PromQL. It is natural to
explain the system using the concepts closest to the implementation rather than the
concepts closest to the adopter's job to be done.

**How to avoid:**
The getting-started guide must end when the adopter has seen something work, not when
all features are explained. The guide structure must be:
1. Install Parapet (one command)
2. Run `mix parapet.doctor` (one command, see green output)
3. Activate a starter pack with one config line (`Parapet.SLO.StarterPack.WebSaaS`)
4. Generate Prometheus artifacts (one command, files appear)
5. "You now have a working SLO for login and request health"

PromQL internals belong in `docs/slo-reference.md`, not in the getting-started guide.
The guide must never contain a raw PromQL expression.

Review signal: ask a Phoenix developer with no Prometheus background to follow the guide
and note where they pause or search for terms. Every pause is a rewrite candidate.

**Warning signs:**
- Guide mentions `rate()`, `histogram_quantile()`, `vector()`, or window math in the
  first three sections
- Guide tells the adopter to edit generated PromQL rather than to run a generator
- Guide includes a note like "refer to the Prometheus documentation for alerting rules"
  before the adopter has seen a working SLO

**Phase to address:**
Getting-Started Guide phase (Pillar A). Apply the AppSignal principle: the guide ends
when data appears, not when the API is fully explained.

---

### Pitfall 4: SLO Starter Packs That Bake In High-Cardinality Labels

**What goes wrong:**
A `Parapet.SLO.Pack.*` module passes labels sourced from per-request data (user IDs,
trace IDs, request paths, job argument hashes) into `SliceSpec.new/1`. This violates the
compile-time label ceiling (max 10 labels/metric, enforced by `Parapet.Metrics.Validator`)
and the project's hard constraint on low-cardinality telemetry. In practice, TSDB
cardinality explodes when labels contain high-cardinality values.

**Why it happens:**
A starter pack author wants to provide "rich" out-of-the-box slices. Adding
`user_id`, `route`, or `job_worker` as labels seems helpful. The cardinality
violation may not be caught immediately if tests use small datasets — it surfaces only
under real load.

**How to avoid:**
All `SliceSpec.new/1` calls in `Parapet.SLO.Pack.*` modules must use only the
low-cardinality label set that existing built-in providers use:
`:integration` (already in `group_labels` default), `:queue` for Oban,
`:provider` for delivery. No per-request identifiers.

Add a `mix parapet.doctor cardinality` check (already exists from v0.9) to the CI
pipeline for the starter pack modules specifically. Write an ExUnit test for each
starter pack that calls `SliceSpec.new/1` and asserts `length(labels) <= 5` and
that no label key contains `id`, `trace`, `path`, or `user`.

**Warning signs:**
- A starter pack module passes `:labels` with keys like `:user_id`, `:request_id`,
  `:worker_module`, or `:oban_job_args`
- `mix parapet.doctor cardinality` reports warnings for a pack module
- A pack's `group_labels:` list has more than 3 entries

**Phase to address:**
SLO Starter Packs phase (Pillar C). Add an ExUnit assertion for cardinality compliance
as a success criterion for each pack module.

---

### Pitfall 5: Starter Packs With One-Size-Fits-All Thresholds That Contradict Low-Traffic Safety

**What goes wrong:**
`Parapet.SLO.StarterPack.WebSaaS` registers HTTP and login SLOs with the same multi-burn-rate
alert thresholds that work for a 1,000 req/min service. For a low-traffic SaaS (50 logins/day),
a single failed login fires a 1,000× burn-rate alert and pages the on-call engineer at 2 AM.
The adopter concludes Parapet's alerting is broken and disables it.

**Why it happens:**
Multi-burn-rate alerting is the correct pattern for high-traffic services. The Google SRE
Workbook documents it as best practice. Starter pack authors apply it uniformly without
acknowledging the denominator problem on low-traffic apps.

**How to avoid:**
`SliceSpec` already has a `min_total_rate` field (default 0.01 per second). Starter pack
modules must set a meaningful `min_total_rate` per slice (not 0.0) and document in the
module `@moduledoc` what traffic volume the pack's thresholds assume.

The SLO authoring guide must have a dedicated "Low-Traffic and Low-Volume Services"
section explaining the denominator guard pattern, the synthetic probe fallback, and when
to use extended windows. This section must reference `min_total_rate` in `SliceSpec`
by name so adopters know the escape hatch exists in code, not just in PromQL.

Do not lower the SLO objective (e.g., 90% instead of 99.9%) to silence noisy alerts —
name this anti-pattern explicitly in the guide and explain why it destroys production
signal.

**Warning signs:**
- A pack sets `min_total_rate: 0` or `min_total_rate: nil` on any slice
- The starter pack `@moduledoc` says nothing about minimum traffic assumptions
- An adopter with staging traffic levels reports constant alert flapping after adding the
  pack

**Phase to address:**
SLO Starter Packs phase (Pillar C) for the `min_total_rate` configuration; SLO Authoring
Guide phase (Pillar C) for the low-traffic guidance section. Both must ship together.

---

### Pitfall 6: Runbook Templates That Bypass the Claim/CircuitBreaker/ToolAudit Seams

**What goes wrong:**
A new or enriched runbook template step uses `auto_execute: true` but its
`execute_mitigation/2` callback calls the host application's repo or a third-party API
directly, bypassing `ClaimService.claim_action/1` and `CircuitBreaker.gate/4`. This
means: no idempotency key, no flap protection, no `ToolAudit` record, no
`TimelineEntry`, and no `ActionClaim` in the database. The Operator UI will not show
"System-Executed" styling for the step, and the audit trail is broken.

**Why it happens:**
Template authors see `execute_mitigation/2` as a callback to implement and focus on the
business logic (requeue the job, pause the queue). The claim/breaker/audit plumbing
is a separate module (`Parapet.Automation.ClaimService`) that must be explicitly called.
Templates currently show no example of this call — they stub `execute_mitigation` as
`{:error, :not_implemented}` — so a template author implementing the callback for the
first time has no reference to follow.

**How to avoid:**
Every template that declares any step with `auto_execute: true` must include a commented
reference implementation of `execute_mitigation/2` that calls `ClaimService.claim_action/1`
with the correct keyword arguments (`incident_id:`, `action_kind:`, `action_key:`,
`idempotency_key:`). The comment should explicitly state: "Do not bypass ClaimService —
it provides idempotency, circuit-breaker protection, and audit logging."

Add an ExUnit test for each template's expected behavior: generate the module from the
template and assert that `execute_mitigation/2` either raises a compile-time error if
bypass is detected, or returns `{:error, :not_implemented}` when the host has not wired
it up (so auto-execution safely no-ops rather than silently succeeds with a partial write).

**Warning signs:**
- A template's `execute_mitigation/2` calls `MyApp.Repo` or `Oban.cancel_job/2` directly
  without first calling `ClaimService.claim_action/1`
- A step with `auto_execute: true` fires but no `ToolAudit` record exists afterward
- The Operator UI shows "Human-Executed" styling on a system-triggered step

**Phase to address:**
Recovery Depth (Runbook Templates) phase (Pillar B). Add ClaimService reference
implementation to every auto-execute-capable template as a success criterion.

---

### Pitfall 7: Runbook Steps That Are Non-Idempotent or Unsafe Under Retry

**What goes wrong:**
A `requeue_dead_letter` or `retry_async_item` step in a template is designed for a single
item but the operator runs it multiple times in quick succession (or it fires automatically
more than once due to an Oban retry). The same job is requeued N times and the downstream
system receives N duplicate executions.

**Why it happens:**
The current `dead_letter.ex.eex` has a `requeue_item` step with `requires_preview: true`
but no idempotency mechanism beyond what `ClaimService` provides for auto-executed steps.
Operator-executed steps do not go through `ClaimService` — they go through
`Parapet.Operator.execute_runbook_step/3` with an `ActionPayload`. If `idempotency_key`
in the payload is not set or reuses a stale key, duplicate executions can succeed.

**How to avoid:**
Template steps that perform mutating actions must document in their `guidance:` field:
"This action is idempotent only if the host's `execute_mitigation/2` implementation
checks for existing state before acting (e.g., verify the job is still in `:discarded`
state before requeuing)."

Add a precondition step (type: `:manual`, kind: `:guidance`) before every mutating step
that instructs the operator to verify the item is still in the expected state. This is
not just good UX — it is a safety gate that catches races between operator actions and
system auto-execution.

**Warning signs:**
- A template's mutating step has no preceding guidance step verifying preconditions
- The `guidance:` text on a requeue step says nothing about checking current item state
- An operator reports "I ran the runbook twice and the job appears twice in the queue"

**Phase to address:**
Recovery Depth (Runbook Templates) phase (Pillar B). Each deepened template must include
a state-verification precondition step before every mutating step.

---

### Pitfall 8: `auto_execute: true` Without `auto_execute_on:` Alignment

**What goes wrong:**
A template step declares `auto_execute: true` but the `Parapet.Automation.Executor`
Oban job is only enqueued when a runbook is mapped to an alert name via
`auto_execute_on:` in the runbook mapping configuration. If that mapping is not present
or is mis-typed, the auto-execution silently never fires. Operators believe automated
mitigation is active when it is not.

**Why it happens:**
The `auto_execute` step option and the `auto_execute_on:` runbook-level mapping are
separate configuration surfaces. A template author sets `auto_execute: true` on a step
without realizing the runbook also needs to be registered with an alert name trigger in
the host application's Parapet config.

Compounding this: `auto_execute_on:` does not appear in the `Parapet.Runbook` DSL module
(it is a v0.8 concept that lives in runbook registration/mapping config, not in the DSL
macro itself). Templates have no compile-time way to enforce it.

**How to avoid:**
Every template that uses `auto_execute: true` must include a prominent `@moduledoc`
section titled "Auto-Execution Setup" that explicitly states: "For automated execution
to fire, this runbook must be registered in your Parapet config with
`auto_execute_on: \"your_alert_name\"`." Include the exact config snippet.

Add `mix parapet.doctor` check guidance: if a runbook step has `auto_execute: true` but
no `auto_execute_on:` mapping exists in the Parapet config, the doctor check should emit
a warning (not an error — the adopter may intentionally leave it manual-only).

**Warning signs:**
- A runbook has `auto_execute: true` steps but no `auto_execute_on:` appears in the
  application config
- `mix parapet.doctor` emits no warning about unmapped auto-execute steps
- After an alert fires, no `ToolAudit` records appear for automated execution

**Phase to address:**
Recovery Depth (Runbook Templates) phase (Pillar B). Add the "Auto-Execution Setup"
section to every auto-execute-capable template as a non-negotiable template content
requirement.

---

### Pitfall 9: Docs Claiming Behavior the DSL Cannot Express

**What goes wrong:**
The SLO authoring guide or runbook template docs reference step options (`warning:`,
`preconditions:`, `annotation:`) that do not exist in the `Parapet.Runbook` DSL.
An adopter copies an example from the guide, compiles their runbook, gets no error
(Elixir passes unknown keyword arguments through silently in many macro contexts),
and then discovers their "warning" text never appears in the Operator UI.

**Why it happens:**
Research into FEATURES.md (this milestone) described enriched templates using
`warning: "..."` annotations and `preconditions:` steps — but the actual
`Parapet.Runbook.step/2` macro (verified by direct read of `lib/parapet/runbook.ex`)
only stores: `id`, `label`, `description`, `type`, `kind`, `capability`,
`target_kind`, `requires_preview`, `preview_only`, `auto_execute`, and `guidance`.
There is no `warning:` key in the macro. Using it in a template would compile silently
but the field would be discarded.

**How to avoid:**
Before writing any template that uses a step option, verify that option exists in the
`Parapet.Runbook.step/2` macro definition. If `warning:` annotations are needed (they
are — the FEATURES.md envisioned them as a safety pattern), add `warning:` to the step
macro schema as part of the Recovery Depth phase. Do not document behavior that is not
yet in code.

The `verify.public_api` alias (`mix docs --warnings-as-errors`) will catch `@doc` that
references nonexistent options in the module API, but it will not catch template
`.ex.eex` files that use nonexistent keyword args. Add an explicit compile test:
generate each template into a temp module and assert `__runbook_schema__()` contains
the expected keys, including any new ones added for v0.10.

**Warning signs:**
- A template `.ex.eex` file uses keyword options not listed in `Parapet.Runbook.step/2`
  macro definition
- An adopter reports that `warning:` text from a template never appears in the UI
- A guide example includes a code block that cannot be copy-pasted and compiled without error

**Phase to address:**
Recovery Depth (Runbook Templates) phase (Pillar B) — must extend the DSL to support
`warning:` before writing templates that use it, or use `guidance:` for all warning text
until the DSL is extended. This is the single most important sequencing constraint
for the runbook templates work.

---

### Pitfall 10: CHANGELOG.md Edited by Hand, Conflicting With Release Please

**What goes wrong:**
A developer adds "v0.10 highlights" manually to `CHANGELOG.md` before the first
Release Please PR merges. When Release Please runs, it regenerates its section header
at the top of the file, producing a duplicate entry or a merge conflict that stalls the
CI release workflow.

**Why it happens:**
The repo has no `CHANGELOG.md` yet. It is tempting to create a minimal one manually
("here is what shipped in v0.1–v0.9") before Release Please takes over. If that stub
goes beyond a bare header, Release Please's next PR will conflict with it.

**How to avoid:**
Create at most a header-only `CHANGELOG.md` stub (`# Changelog\n`) and commit it.
All content below the header is Release Please's territory. If a retroactive summary
of v0.1–v0.9 is desired for adopters, put it in a separate `docs/history.md` file
that is excluded from Release Please management.

Release Please owns: everything in `CHANGELOG.md` below the top-level header.
Humans own: Conventional Commit messages (which determine what Release Please generates).

**Warning signs:**
- `CHANGELOG.md` has a hand-authored section with a date that is not a Release Please
  PR date
- The Release Please PR shows a merge conflict in `CHANGELOG.md`
- CI release workflow fails on a push to `main` after a manual CHANGELOG edit

**Phase to address:**
Hex Metadata and CHANGELOG phase (Pillar A). Must land before any other docs work that
references the CHANGELOG, to establish the ownership contract clearly.

---

### Pitfall 11: Per-Integration Guides That Claim Non-Compile-Out-Clean Optional Deps

**What goes wrong:**
A per-integration guide (e.g., Sigra, Accrue, Rulestead, Threadline) instructs adopters
to configure an integration without documenting that the sibling library must be in
their `deps` list as an optional dep that compiles out when absent. An adopter without
Sigra installed adds `Parapet.attach(adapters: [Parapet.Integrations.Sigra])` per the
guide, gets a `UndefinedFunctionError` or a Credo compile warning, and concludes the
library is broken.

**Why it happens:**
Guide authors focus on the happy path (adopter has the sibling library installed) and
omit the "if you don't have this library" path. The compile-out-clean mechanism via
`Code.ensure_loaded?` is an implementation detail that adopters need to know about when
reading integration guides.

**How to avoid:**
Every per-integration guide must start with a "Prerequisites" section that explicitly
states: "This integration requires `{:sigra, ">= x.y"}` in your `mix.exs` deps.
Without it, Parapet will compile cleanly but this integration will not activate."
Include the exact `mix.exs` dep line to add.

Add a test that verifies the compile-out behavior: in a test environment that does not
configure the optional dep, assert that `Parapet.Integrations.Sigra` is not defined or
that `Parapet.attach(adapters: [Parapet.Integrations.Sigra])` returns a
`{:skipped, :dep_not_loaded}` result rather than raising.

**Warning signs:**
- An integration guide does not mention the optional dep by name in a "Prerequisites"
  section
- The guide's "Enable in Parapet" section is the first section (no prerequisites stated)
- CI does not have a test matrix entry that compiles Parapet without the optional dep

**Phase to address:**
Per-Integration Guides phase (Pillar A). Add prerequisites section as a non-negotiable
template for every integration guide.

---

### Pitfall 12: Demo That Has No CI Green Check

**What goes wrong:**
The demo app (`demo/app/`) compiles and `mix parapet.doctor` passes at the time it is
written. Six weeks later, a breaking change in Parapet's public API silently breaks the
demo, but no CI job runs the demo, so nobody notices until an adopter reports it.

**Why it happens:**
Demo apps are often treated as documentation artifacts rather than code artifacts. They
are written, committed, and forgotten. CI checks the library test suite but not the demo.

**How to avoid:**
The demo CI job must be added in the same PR that creates the demo, not retrofitted.
The job should: `cd demo/app && mix deps.get && mix compile --warnings-as-errors
&& mix parapet.doctor`. It does not need to run the full Docker Compose stack —
just compile-and-doctor is sufficient to catch API regressions.

The CI matrix should have a distinct job named `demo` with a stable job ID so its
green/red status is visible on the PR checks list.

**Warning signs:**
- The CI workflow YAML has no job that references `demo/app`
- A PR that changes a Parapet public function signature passes CI with green checks
- The demo's `mix.lock` has not been updated in weeks despite deps changing

**Phase to address:**
Demo Harness phase (Pillar A). CI job is a required deliverable alongside the demo app —
not a follow-up task.

---

### Pitfall 13: `verify.public_api` Not Extended to Cover New Docs and SLO Pack Modules

**What goes wrong:**
The existing `verify.public_api` alias runs `mix docs --warnings-as-errors`, which
catches undocumented public functions in `lib/`. New `Parapet.SLO.Pack.*` modules
shipped without `@moduledoc` or with incomplete `@doc` pass `mix compile` cleanly but
fail the docstring completeness gate silently because `verify.public_api` is not run
in the same CI job as the new modules.

**Why it happens:**
The `verify.public_api` alias is already in `mix.exs` and CI. But if a developer adds
a new public module and does not run `mix docs --warnings-as-errors` locally, the gap
is only caught when CI runs `verify.public_api` — which is only visible if the developer
checks that specific job's output rather than just "CI is green."

**How to avoid:**
No change to the alias is needed — it already catches undocumented public functions.
The prevention is procedural: every new `Parapet.SLO.Pack.*` module and every new
public runbook template module must have `@moduledoc` with:
- What app type this pack targets
- What SLO slices it registers
- What traffic volume assumptions it makes
- How to register it

Add a `mix credo --strict` rule (already in CI) that enforces `@moduledoc` presence on
all public modules. Credo's `Credo.Check.Readability.ModuleDoc` check is enabled by
default with `--strict`.

**Warning signs:**
- A new `Parapet.SLO.Pack.*` module has `@moduledoc false`
- `mix docs --warnings-as-errors` emits warnings after adding a new pack module
- Hexdocs for the new module shows no description

**Phase to address:**
SLO Starter Packs phase (Pillar C). Treat `mix verify.public_api` green as a required
exit criterion for the phase.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using `guidance:` for warning text instead of adding `warning:` to the DSL | Ships faster; no DSL change needed | Warning text is visually indistinguishable from guidance in the Operator UI; operators miss safety warnings | Acceptable only as temporary measure if DSL extension is planned for the same phase |
| Starter pack with hardcoded 99.9% thresholds and no `min_total_rate` documentation | Simplest possible pack API | Alert flapping on low-traffic apps; adopters lose trust in Parapet alerting | Never — document traffic assumptions in every pack |
| Per-integration guide without a "Troubleshooting" section | Faster to write | Support burden on maintainer; adopters abandon on first error | Never for integrations with compile-out-clean behavior; those always need troubleshooting |
| Demo without a CI job | Demo ships faster | Demo rots silently; becomes a trust-destroyer when adopters find it broken | Never — CI job must ship with the demo |
| Hand-editing CHANGELOG.md for a retroactive v0.1–v0.9 summary | Good history for adopters | Conflicts with Release Please automation | Acceptable only if history goes in `docs/history.md`, not in `CHANGELOG.md` |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Sigra (auth) | Attaching the integration without Sigra in `deps` list; get runtime error | Document `{:sigra, ">= x.y", optional: true}` in prerequisites; test compile-out path |
| Accrue (billing) | Defining a checkout SLO with `user_id` as a label for per-user error tracking | Use only `integration: :accrue` as group label; track per-user errors in ToolAudit evidence, not metrics |
| Rulestead (flags) | Assuming flag-change correlation fires automatically without `Parapet.attach(adapters: [Parapet.Integrations.Rulestead])` | Integration guide must show the exact `attach` call and Rulestead event subscription setup |
| Threadline (audit) | Believing Threadline compliance sync is real-time; expecting SLO data in Threadline | The integration is "conceptual interoperability" — guide must be honest about what is actually wired vs aspirational |
| Docker Compose demo | Pinning `prom/prometheus:latest` in `docker-compose.yml` | Pin to `v3.x` minor version; `latest` breaks silently on upstream image changes |
| Oban (background jobs) | Using `auto_execute: true` on a step without verifying Oban is in the host's dep list | The Executor is wrapped in `if Code.ensure_loaded?(Oban.Worker)` — document that auto-execution requires Oban as a non-optional dep |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Starter pack registers too many SLO slices for a small app | Every Prometheus scrape returns a large metric payload; Parapet config startup is slow | Each starter pack should register ≤ 5 slices; document how to selectively disable slices | Noticeable at > 20 active SLO slices with per-slice recording rules |
| Demo app with seeded load generator that fills Postgres | `mix parapet.doctor` passes but Postgres grows unboundedly during demo | Add `mix parapet.archive` cron to demo app config; document archiver setup in demo README | Demo running overnight fills disk |
| Runbook template that performs N+1 DB queries in `execute_mitigation/2` | Each operator runbook execution is slow; Operator UI appears frozen | Template reference impl should use a single scoped query with `LIMIT` | Any runbook with more than one `repo.all()` call without a bound |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Template `execute_mitigation/2` skipping ClaimService and calling host repo directly | No audit trail; no idempotency; race conditions in multi-node deployments | Every auto-execute template must call `ClaimService.claim_action/1`; add template compile test |
| Starter pack guide showing `{:parapet, path: "../../"}` as a production dep example | Adopter accidentally ships a path dep to production | Getting-started guide must clearly distinguish demo path dep from production Hex dep with explicit callout |
| Demo app with `config/dev.exs` secrets committed | Credentials leak via public repo | Demo app must use `config/dev.exs.example` with placeholder values; `.gitignore` must exclude `config/dev.exs` in `demo/app/` |
| Per-integration guide instructing adopters to skip `Code.ensure_loaded?` guard for "simplicity" | Compile-time crash when optional dep is absent | Never suggest bypassing the compile-out guard; always document the optional dep correctly |

---

## "Looks Done But Isn't" Checklist

- [ ] **Starter pack modules:** Have `@moduledoc` with traffic assumption documentation — verify with `mix docs --warnings-as-errors`
- [ ] **Runbook templates:** Have precondition guidance steps before every mutating step — verify by reading each generated module's `__runbook_schema__()`
- [ ] **Demo app:** Has a CI job in `.github/workflows/ci.yml` that runs `mix compile --warnings-as-errors && mix parapet.doctor` — verify by checking job names in CI YAML
- [ ] **CHANGELOG.md:** Is owned by Release Please (content below header was not hand-edited) — verify by checking git blame on any content line
- [ ] **files: whitelist:** Does not include `demo/` — verify with `mix hex.build --dry-run | grep demo`
- [ ] **Per-integration guides:** Each has a "Prerequisites" section listing the optional dep — verify by reading each guide's first section
- [ ] **Getting-started guide:** Contains zero raw PromQL expressions — verify by grep for `rate(`, `histogram_quantile`, `vector(`
- [ ] **SLO starter packs:** Each slice has a non-zero `min_total_rate` — verify by reading each `SliceSpec.new/1` call in the pack modules
- [ ] **Auto-execute templates:** Each has an "Auto-Execution Setup" `@moduledoc` section — verify by reading the generated module documentation
- [ ] **DSL alignment:** No template uses step options not in `Parapet.Runbook.step/2` macro — verify by reading macro definition against every template keyword

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Demo deps leaked into published package | HIGH | Yank the published version; move deps to demo's own mix.exs; re-publish; update adopters |
| Demo drifted to stale Hex snapshot | LOW | Switch back to `path: "../../"` in demo mix.exs; add CI check; no package re-publish needed |
| Docs reference nonexistent DSL options | MEDIUM | Add the missing option to the DSL; re-render hexdocs; no breaking change if the option is additive |
| CHANGELOG.md hand-edit conflict | LOW | Delete conflicting lines; let Release Please regenerate; no adopter impact if caught before publish |
| Starter pack high-cardinality labels | HIGH (if shipped) | Yank and re-publish with corrected labels; existing adopters get TSDB data migration headache |
| Runbook bypassing ClaimService | MEDIUM | Add ClaimService call to the template; regenerate runbook in host apps; existing ToolAudit gaps are historical |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Demo deps leaking into published package | Demo Harness (Pillar A) | `mix hex.build --dry-run \| grep demo` returns zero matches |
| Demo drifting to stale Hex snapshot | Demo Harness (Pillar A) | CI demo job compiles against `path: "../../"` and fails on library API break |
| Getting-started assumes PromQL expertise | Getting-Started Guide (Pillar A) | Guide contains zero PromQL expressions; reviewed by a non-Prometheus developer |
| Starter packs with high-cardinality labels | SLO Starter Packs (Pillar C) | ExUnit asserts label keys contain no `id/trace/path/user`; `mix parapet.doctor cardinality` green |
| Starter packs flapping on low-traffic apps | SLO Starter Packs (Pillar C) | Every slice has `min_total_rate > 0`; authoring guide has denominator guard section |
| Runbook templates bypassing ClaimService | Recovery Depth Templates (Pillar B) | Each auto-execute template has ClaimService reference impl; compile test verifies schema |
| Non-idempotent runbook steps | Recovery Depth Templates (Pillar B) | Every mutating step has a preceding state-verification guidance step |
| `auto_execute` without `auto_execute_on:` mapping | Recovery Depth Templates (Pillar B) | Every auto-execute template has "Auto-Execution Setup" `@moduledoc` section |
| Docs claiming nonexistent DSL options (`warning:`) | Recovery Depth Templates (Pillar B) | DSL extension lands before templates that use the new options; compile test verifies schema |
| CHANGELOG.md hand-edit conflict | Hex Metadata + CHANGELOG (Pillar A) | `git blame CHANGELOG.md` shows only Release Please commits below header |
| Per-integration guides hiding optional-dep behavior | Per-Integration Guides (Pillar A) | Every guide has "Prerequisites" section listing exact dep; compile-out test in CI |
| Demo without CI green check | Demo Harness (Pillar A) | CI YAML has `demo` job with stable ID that fails on library API regression |
| `verify.public_api` not covering new modules | SLO Starter Packs (Pillar C) | `mix verify.public_api` (docs --warnings-as-errors) green after adding pack modules |

---

## Sources

- Direct codebase audit: `lib/parapet/runbook.ex`, `lib/parapet/automation/circuit_breaker.ex`,
  `lib/parapet/automation/claim_service.ex`, `lib/parapet/automation/executor.ex`,
  `lib/parapet/slo/slice_spec.ex`, `lib/parapet/slo/provider.ex`,
  `priv/templates/parapet.gen.runbooks/*.ex.eex`, `mix.exs`, `.github/workflows/ci.yml`
  (HIGH confidence — direct source read)
- Google SRE Workbook, "Alerting on SLOs": https://sre.google/workbook/alerting-on-slos/
  (HIGH confidence — authoritative reference for multi-burn-rate + low-traffic denominator problem)
- Hex.pm publish docs: https://hex.pm/docs/publish (HIGH confidence — `files:` whitelist behavior)
- Release Please Elixir: https://elixirschool.com/blog/managing-releases-with-release-please
  (HIGH confidence — CHANGELOG ownership model)
- PromEx example_applications pattern: https://github.com/akoutmos/prom_ex
  (MEDIUM confidence — `path:` reference in demo dep as verified pattern)
- AppSignal getting-started guide: https://blog.appsignal.com/2024/09/17/a-complete-guide-to-phoenix-for-elixir-monitoring-with-appsignal.html
  (MEDIUM confidence — "guide ends when data appears" principle)

---

*Pitfalls research for: Parapet v0.10 Adopter Success — Phoenix/Elixir OSS SRE library*
*Researched: 2026-05-23*
