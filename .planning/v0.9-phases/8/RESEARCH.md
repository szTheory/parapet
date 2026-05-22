# Phase 8: Close Day-1 Install and Doctor Verification - Research

**Researched:** 2026-05-21 [VERIFIED: system date]  
**Domain:** Closure-grade verification and narrow traceability reconciliation for the existing Phase 4 install, doctor, and docs-handoff flow [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Verification artifact shape
- **D-01:** Phase 8 should produce a dedicated `.planning/v0.9-phases/4/VERIFICATION.md` as the canonical closure artifact for the underlying Phase 4 implementation.
- **D-02:** The verification artifact should stay thin and executable-first, following the repo's stronger proof pattern: Goal Achievement, Observable Truths, Behavioral Spot-Checks, Plan Output Check, Requirements Coverage, Human Verification Required, and Gaps Summary.
- **D-03:** Summaries and validation files remain supporting inputs and historical execution records; they should not be promoted into the primary closure artifact.

### Proof standard
- **D-04:** The default proof stack for Phase 8 should be layered: targeted installer and doctor tests, doc-contract checks, and one fresh Phoenix host smoke lane that exercises the public Day-1 path.
- **D-05:** Repo-internal task tests alone are not sufficient to claim public Day-1 closure, because they prove task contracts but not the adopter-facing install invocation and handoff.
- **D-06:** The fresh-host smoke lane should prove `mix parapet.install` -> generated host-owned artifacts/config -> `mix parapet.doctor` -> docs handoff consistency, while explicitly stopping short of third-party observability runtime claims.
- **D-07:** `mix parapet.doctor cluster` may be included only as an honesty/reporting check for runtime-mode behavior in a non-cluster host; it is not the primary proof of multi-node safety.

### End-to-end boundary
- **D-08:** For Phase 8, “end-to-end” means a fresh Phoenix host can adopt Parapet through the paved-road install command, reach the documented doctor follow-up, and find docs that describe that shipped contract accurately.
- **D-09:** End-to-end for this phase explicitly excludes Prometheus/Grafana runtime setup, external provider integrations, and actual cluster correctness proof, because those are outside the install-surface boundary Parapet owns here.
- **D-10:** Phase 5 remains the real proof surface for multi-node contention and effectively-once automation semantics; Phase 8 only needs to verify that Day-1 doctor surfaces that posture honestly.

### AC-01 interpretation and public DX posture
- **D-11:** `AC-01` should be treated as stale wording and corrected during closure rather than forcing the installer to include operator UI by default.
- **D-12:** The cohesive public contract is: `mix parapet.install` installs the core Day-1 path by default, and the optional operator UI remains an explicit opt-in when LiveView is present.
- **D-13:** The recommended corrected wording for `AC-01` is: “A developer can run `mix parapet.install` and get the spine and default Prometheus artifacts in one guided flow, with the optional operator UI offered explicitly when LiveView is present.”
- **D-14:** Phase 8 must preserve the host-owned auth boundary for operator UI; it should not reinterpret “guided flow” as permission to auto-own router auth or silently widen the default support surface.

### Reconciliation scope
- **D-15:** After proof lands, Phase 8 should reconcile only the directly covered traceability surfaces: the new Phase 4 `VERIFICATION.md`, any stale Phase 4 validation wording, the `DX-01.a`, `DX-01.b`, and `AC-01` rows in `.planning/REQUIREMENTS.md`, and the Phase 8 closure line in `.planning/ROADMAP.md`.
- **D-16:** Broader milestone-wide synchronization across `STATE.md`, milestone audit artifacts, and remaining cross-phase tracker drift stays Phase 9 work unless Phase 8 proof directly changes one of those files' facts.

### Maintainer workflow preference
- **D-17:** Downstream planning and execution agents should shift low-impact DX decisions left when product posture is already locked by prior context, code, and docs.
- **D-18:** Low-impact decisions that should be auto-resolved by default include flag naming, prompt wording, summary copy, doc phrasing, and “core vs explicit extra” wording once those surfaces are already constrained by product posture.
- **D-19:** Agents should escalate only when a choice materially changes default install contents, auth ownership, dependency policy, public CLI/API contract, support surface, or operator semantics.

### the agent's Discretion
- Exact wording inside the Phase 4 `VERIFICATION.md`, as long as executable proof remains primary and the report stays concise.
- Exact shape of the doc-contract checks and smoke-host assertions, as long as they prove the shipped install, doctor, and docs handoff contract honestly.
- Exact wording changes in `REQUIREMENTS.md` and `ROADMAP.md`, provided they reconcile stale wording to the locked Day-1 product posture without widening scope.

### Deferred Ideas (OUT OF SCOPE)

- Broader milestone-wide synchronization across `.planning/STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, and other cross-phase trackers after Phases 6-8 land.
- Any expansion of public proof beyond the library-owned install/doctor/docs boundary into Prometheus/Grafana/provider runtime infrastructure.
- Reifying the left-shift preference into a repo-level agent instruction surface such as `AGENTS.md` as a separate focused follow-on task.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01.a | System provides `mix parapet.install` as a unified, interactive starting point that sequentially runs necessary sub-generators. [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing installer task tests as the repo proof core, then add a fresh Phoenix host smoke capture proving the public command creates spine artifacts, endpoint/config wiring, Prometheus files, and the install summary that points maintainers at `mix parapet.doctor`. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: README.md] |
| DX-01.b | System's `mix parapet.doctor` checks for correct multi-node configuration (e.g., verifying Oban uniqueness settings for escalations). [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing doctor task tests as the primary proof lane, and treat `mix parapet.doctor cluster` in a fresh host as an honesty spot-check only because Phase 5 owns the real multi-node proof. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] |
| AC-01 | A developer can run `mix parapet.install` and get the spine, UI, and default Prometheus artifacts in one guided flow. [VERIFIED: .planning/REQUIREMENTS.md] | Correct the wording to match the shipped contract before marking it verified: core install by default, optional UI only when explicitly requested and when LiveView is present. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md] |
</phase_requirements>

## Summary

Phase 8 is a proof-and-reconciliation phase, not a feature phase. The implementation work already exists: `mix parapet.install` composes the spine and Prometheus generators, writes host-owned wiring, and emits a summary that points maintainers at `mix parapet.doctor`; `mix parapet.doctor` already exposes severity-aware static checks plus `cluster` runtime mode; README and `docs/operator-ui.md` already describe the default-versus-optional posture consistently. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md]

The audit gap is narrower than implementation: there is no Phase 4 `VERIFICATION.md`, `DX-01.a`, `DX-01.b`, and `AC-01` remain pending, and the acceptance wording still overclaims UI-by-default even though the shipped docs and code keep UI explicit. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md]

The strongest closure posture is layered proof. Keep repo-internal task tests as the primary automated evidence, add doc-contract grep checks as the truthfulness layer, and require one fresh Phoenix host smoke capture as a planner-owned proof task recorded in `.planning/v0.9-phases/4/VERIFICATION.md` rather than as a normal merge-gated ExUnit file. That fresh-host lane is necessary to close the public Day-1 claim honestly, but it should remain a manual verification requirement because it exercises an adopter environment, not just library internals. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] [VERIFIED: scripts/setup_sandbox.sh] [VERIFIED: mix archive]

**Primary recommendation:** Plan Phase 8 in two slices: first create `.planning/v0.9-phases/4/VERIFICATION.md` from targeted reruns plus one fresh-host smoke transcript, then reconcile only `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`, `.planning/REQUIREMENTS.md`, and the Phase 8 row in `.planning/ROADMAP.md`. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public Day-1 installer proof | Build / Tooling | Host app codebase | `mix parapet.install` is a Mix/Igniter surface that writes host-owned files into an adopter repo rather than runtime state inside Parapet itself. [VERIFIED: lib/mix/tasks/parapet.install.ex] |
| Doctor contract proof | Build / Tooling | API / Backend | `mix parapet.doctor` is a CLI/static-analysis surface with optional runtime reporting, and Phase 8 only needs to prove its honesty at install time. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] |
| Optional operator UI posture | Build / Tooling | Frontend Server (SSR) | The installer may compose UI generation, but the generated UI remains host-owned and must be mounted inside host-authenticated router scopes. [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md] |
| Proof artifact reconciliation | Repository / Planning Artifacts | — | The remaining phase gap is traceability drift, not missing runtime ownership. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `1.19.5` local runtime. [VERIFIED: mix --version] | Runs the install, doctor, and test proof surfaces. | All required proof commands for this phase are `mix` commands. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] |
| ExUnit | bundled with Elixir `1.19.5`. [VERIFIED: mix --version] | Primary automated proof framework for install and doctor contracts. | Existing Phase 4 validation already targets ExUnit-based task tests. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] |
| Igniter | project locked `0.7.9`; current Hex release `0.8.0` published 2026-05-09. [VERIFIED: mix.lock] [VERIFIED: mix hex.info igniter] | Powers installer composition and in-memory generator testing. | Existing install proof already depends on `Igniter.Test` and task composition behavior. [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: lib/mix/tasks/parapet.install.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phx_new` archive | installed `1.8.7`. [VERIFIED: mix archive] | Creates the disposable Phoenix host used for the closure smoke lane. | Use only for the fresh-host proof task; do not convert this into a regular repo test dependency. [VERIFIED: scripts/setup_sandbox.sh] |
| `jason` | project locked `1.4.5`. [VERIFIED: mix.lock] | Keeps CI/machine-readable doctor output stable. | Use when proving `--ci` output and doctor status JSON. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] |
| `sourceror` | project locked `1.12.0`. [VERIFIED: mix.lock] | Supports doctor router/operator-UI static analysis. | Relevant when proving the install-to-doctor handoff and operator UI auth posture. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fresh-host smoke as a planner-owned manual proof task | Fresh-host smoke as a new ExUnit/integration suite inside this repo | That would broaden Phase 8 into harness engineering and create a heavier merge gate than the locked closure scope requires. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] |
| Narrow reconciliation after proof | Broad milestone tracker sync | Phase 8 explicitly defers `STATE.md` and milestone-audit harmonization to Phase 9. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Current tool and package versions for this phase were verified with `mix --version`, `mix archive`, and `mix hex.info igniter` during this session. [VERIFIED: mix --version] [VERIFIED: mix archive] [VERIFIED: mix hex.info igniter]

## Architecture Patterns

### System Architecture Diagram

```text
repo proof inputs
    |
    +--> test/mix/tasks/parapet.install_test.exs
    +--> test/mix/tasks/parapet.doctor_test.exs
    +--> README.md
    +--> docs/operator-ui.md
    |
    v
Phase 8 proof bundle
    |
    +--> targeted mix tests
    |      - install contract
    |      - doctor contract
    |
    +--> doc-contract checks
    |      - README Day-1 command
    |      - doctor follow-up
    |      - optional UI posture
    |
    +--> fresh Phoenix host smoke lane
           - mix phx.new
           - add local parapet dep
           - mix deps.get
           - mix parapet.install
           - inspect generated host-owned files
           - mix parapet.doctor
           - optional mix parapet.doctor cluster
           - compare results to README/docs
    |
    v
.planning/v0.9-phases/4/VERIFICATION.md
    |
    +--> Phase 4 validation wording
    +--> REQUIREMENTS.md DX-01.a DX-01.b AC-01
    +--> ROADMAP.md Phase 8 closure line
```

This matches the locked proof posture: executable-first, layered, and bounded to install/doctor/docs truth rather than runtime observability infrastructure. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]

### Recommended Project Structure
```text
.planning/
├── v0.9-phases/4/
│   └── VERIFICATION.md          # new canonical closure artifact [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]
├── phases/04-unified-install-path-dx/
│   └── 04-VALIDATION.md         # wording reconciliation only if stale [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md]
├── REQUIREMENTS.md              # flip DX-01.a, DX-01.b, AC-01 only after proof exists [VERIFIED: .planning/REQUIREMENTS.md]
└── ROADMAP.md                   # update only the Phase 8 closure line [VERIFIED: .planning/ROADMAP.md]
```

### Pattern 1: Verification Artifact as Proof Index
**What:** Create a thin `VERIFICATION.md` that cites exact commands, exact observed outcomes, and exact source anchors instead of re-summarizing Phase 4 implementation prose. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md]  
**When to use:** Always for this phase, because the missing object is proof, not implementation. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]  
**Example:**
```markdown
| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Installer contract | `mix test test/mix/tasks/parapet.install_test.exs` | 3 tests, 0 failures | ✓ PASS |
| Doctor contract | `mix test test/mix/tasks/parapet.doctor_test.exs` | 10 tests, 0 failures | ✓ PASS |
```

### Pattern 2: Repo Proof Plus Adopter Smoke
**What:** Keep repo tests as the automated core, then add one disposable-host smoke lane to prove the public Day-1 path the repo claims in README and requirements. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: scripts/setup_sandbox.sh]  
**When to use:** For `DX-01.a` and `AC-01`, because internal task tests alone do not prove adopter-facing invocation. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]  
**Example:**
```bash
mix phx.new /tmp/parapet_phase8_smoke --database sqlite3 --no-mailer --install
cd /tmp/parapet_phase8_smoke
# add {:parapet, path: "/path/to/parapet", override: true}
mix deps.get
mix parapet.install
mix parapet.doctor
```

### Pattern 3: Doc-Contract Checks Before Traceability Flips
**What:** Verify README and `docs/operator-ui.md` still describe the shipped contract before flipping requirement rows to verified. [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md]  
**When to use:** Before updating `REQUIREMENTS.md` and `ROADMAP.md`. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]  
**Example:**
```bash
rg -n 'mix parapet\.install|mix parapet\.doctor|--with-ui|--skip-ui' README.md docs/operator-ui.md
```

### Anti-Patterns to Avoid
- **Treating fresh-host smoke as a normal merge gate:** the smoke lane is required for closure evidence, but it should remain a manual verification step recorded in `VERIFICATION.md`, not a new always-on test harness. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]
- **Correcting AC-01 by widening the product surface:** the fix is wording reconciliation, not making operator UI default. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: README.md]
- **Updating `STATE.md` or milestone audit files in Phase 8:** those are explicitly deferred to Phase 9 unless proof changes their facts directly. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]

## Required Proof Surfaces

| Surface | Required Evidence | Why it closes the gap |
|---------|-------------------|-----------------------|
| Installer composition and summary | `mix test test/mix/tasks/parapet.install_test.exs` plus citations to `lib/mix/tasks/parapet.install.ex`. [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: lib/mix/tasks/parapet.install.ex] | Proves the public command composes the core paved road, keeps extras explicit, and points maintainers at doctor. [VERIFIED: README.md] |
| Doctor severity, threshold, JSON, and cluster posture | `mix test test/mix/tasks/parapet.doctor_test.exs` plus citations to `lib/mix/tasks/parapet.doctor.ex`. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] | Proves `DX-01.b` without pretending doctor is the Phase 5 proof surface. [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] |
| Public docs handoff | `rg -n 'mix parapet\\.install|mix parapet\\.doctor|--with-ui|--skip-ui|cluster' README.md docs/operator-ui.md`. [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md] | Proves docs match shipped install and doctor behavior before traceability is flipped. |
| Fresh-host adoption | One disposable Phoenix host transcript proving `mix parapet.install` then `mix parapet.doctor` works in a new app. [VERIFIED: scripts/setup_sandbox.sh] [VERIFIED: mix archive] | This is the missing adopter-facing proof the audit and Phase 8 context call for. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fresh-host proof | A new bespoke integration framework or browser E2E stack | A disposable Phoenix host created with `phx_new` plus a captured shell transcript. [VERIFIED: mix archive] [VERIFIED: scripts/setup_sandbox.sh] | The phase needs honest adopter proof, not a new permanent harness. |
| Install/doctor contract proof | Prose-only summary assertions | Existing focused ExUnit task suites. [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] | These already cover the stable internal contracts and passed in this session. [VERIFIED: mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs] |
| AC-01 reconciliation | Feature expansion to include UI by default | Requirement wording correction only. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] | The shipped README/docs already encode optional UI posture. [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md] |

**Key insight:** Phase 8 closes when one verifier can answer “what exactly was proven, by which commands, and what stayed intentionally out of scope?” from `.planning/v0.9-phases/4/VERIFICATION.md` plus three narrow traceability edits. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]

## Required Artifact Updates For Scope Closure

| Artifact | Update | Why |
|---------|--------|-----|
| `.planning/v0.9-phases/4/VERIFICATION.md` | Create as the canonical closure artifact. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] | This is the missing proof object the audit calls out. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` | Reword any still-planned/manual-only language so it references the new closure proof and makes the fresh-host lane explicit. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] | Validation currently names a manual sample-host check but not the final Phase 8 closure artifact. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] |
| `.planning/REQUIREMENTS.md` | Flip only `DX-01.a`, `DX-01.b`, and `AC-01`, and correct AC-01 wording before marking it verified. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] | These are the orphaned Phase 4 rows. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| `.planning/ROADMAP.md` | Update only the Phase 8 closure line after proof exists. [VERIFIED: .planning/ROADMAP.md] | Phase 8 owns its own closure signal, not full milestone synchronization. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] |

## Minimal Honest File Touch Set

| File | Likely Touch | Confidence |
|------|--------------|------------|
| `.planning/v0.9-phases/4/VERIFICATION.md` | New file. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] | HIGH |
| `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` | Wording update to point at closure evidence and fresh-host/manual posture. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] | HIGH |
| `.planning/REQUIREMENTS.md` | Mark `DX-01.a`, `DX-01.b`, and corrected `AC-01` verified. [VERIFIED: .planning/REQUIREMENTS.md] | HIGH |
| `.planning/ROADMAP.md` | Add Phase 8 closure wording. [VERIFIED: .planning/ROADMAP.md] | HIGH |
| `README.md` | No change expected unless smoke or grep reveals a mismatch. [VERIFIED: README.md] | HIGH |
| `docs/operator-ui.md` | No change expected unless smoke or grep reveals a mismatch. [VERIFIED: docs/operator-ui.md] | HIGH |
| `lib/mix/tasks/parapet.install.ex` | No change expected for a minimal closure plan. [VERIFIED: lib/mix/tasks/parapet.install.ex] | MEDIUM |
| `lib/mix/tasks/parapet.doctor.ex` | No change expected for a minimal closure plan. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] | MEDIUM |

## Common Pitfalls

### Pitfall 1: Treating Repo Tests As Public-Adoption Proof
**What goes wrong:** The phase closes from task tests alone and never proves a new Phoenix host can actually run the paved-road command sequence. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]  
**Why it happens:** Existing task tests already pass and feel close to end-to-end. [VERIFIED: mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs]  
**How to avoid:** Require one disposable-host smoke capture in `VERIFICATION.md`. [VERIFIED: scripts/setup_sandbox.sh]  
**Warning signs:** The artifact contains only `mix test` commands and no adopter-host evidence. [VERIFIED: scope synthesis]

### Pitfall 2: “Fixing” AC-01 By Expanding Default UI Scope
**What goes wrong:** The planner treats the stale wording as a product bug and tries to make UI default. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** `AC-01` still says “spine, UI, and default Prometheus artifacts.” [VERIFIED: .planning/REQUIREMENTS.md]  
**How to avoid:** Correct the wording to the already-shipped default-plus-optional contract. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: README.md]  
**Warning signs:** Any plan step that changes installer defaults or auto-owns router auth. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]

### Pitfall 3: Pulling Phase 9 Cleanup Into Phase 8
**What goes wrong:** `STATE.md` or milestone audit artifacts get updated as part of this phase. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]  
**Why it happens:** Those files currently disagree with roadmap and requirements. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]  
**How to avoid:** Restrict traceability edits to the four files listed above. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]  
**Warning signs:** Any plan item mentioning milestone-wide synchronization. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

Verified patterns from official repo sources:

### Installer Closure Core
```elixir
igniter
|> Igniter.compose_task("parapet.gen.spine", [])
|> write_instrumenter(instrumenter_module, adapters, with_sigra?)
|> Config.configure("config.exs", :parapet, [:instrumenter], instrumenter_module)
|> update_endpoint(endpoint_module, web_module)
|> update_deploy_hook()
|> Igniter.compose_task("parapet.gen.prometheus", [])
|> maybe_install_ui(with_ui?, skip_ui?, live_view_available?)
|> Igniter.add_notice(install_summary_notice(...))
```
// Source: [VERIFIED: lib/mix/tasks/parapet.install.ex]

### Doctor Threshold And Exit Semantics
```elixir
is_ci = Keyword.get(opts, :ci, false)
threshold = parse_threshold(opts[:threshold], is_ci)

case run_checks(mode, requested_checks) do
  {:ok, results} ->
    exit_code = findings_exit_code(results, threshold)
    print_results(results, exit_code, is_ci)
    if exit_code > 0, do: halt(exit_code)
```
// Source: [VERIFIED: lib/mix/tasks/parapet.doctor.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Summary-only Phase 4 completion claims. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-01-SUMMARY.md] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-02-SUMMARY.md] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-03-SUMMARY.md] | Dedicated closure-grade `VERIFICATION.md` as the milestone-close standard. [VERIFIED: .planning/v0.9-phases/2/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] | By 2026-05-21 in v0.9 closure phases. [VERIFIED: verification file headers] | Phase 8 should follow the newer proof posture instead of relying on summaries. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| Acceptance wording implying default UI. [VERIFIED: .planning/REQUIREMENTS.md] | Public docs and code keep UI explicit and opt-in. [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md] [VERIFIED: lib/mix/tasks/parapet.install.ex] | Already shipped before 2026-05-21. [VERIFIED: file inspection] | Phase 8 should reconcile wording, not behavior. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] |

**Deprecated/outdated:**
- `AC-01` wording that implies UI is part of the default guided flow. [VERIFIED: .planning/REQUIREMENTS.md] That is outdated relative to the shipped contract and should be corrected before verification. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]

## Assumptions Log

All claims in this research were verified in this session or derived directly from checked-in project artifacts. No `[ASSUMED]` claims remain.

## Open Questions (RESOLVED)

1. **Should the fresh-host smoke lane reuse `scripts/setup_sandbox.sh` or stay as inline commands in `VERIFICATION.md`?**
   - Resolution: keep the canonical smoke proof as inline commands recorded in `.planning/v0.9-phases/4/VERIFICATION.md`, while allowing `scripts/setup_sandbox.sh` to remain an optional execution scaffold if it already matches the Day-1 proof path cleanly. [VERIFIED: .planning/v0.9-phases/8/08-01-PLAN.md] [VERIFIED: scripts/setup_sandbox.sh]
   - Why: this preserves a readable, self-contained closure artifact and avoids unnecessary Phase 8 script churn while still reusing the existing disposable-host precedent where helpful. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: .planning/v0.9-phases/8/PATTERNS.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All automated proof commands | ✓ | `1.19.5` [VERIFIED: mix --version] | — |
| `phx_new` archive | Fresh-host smoke lane | ✓ | `1.8.7` [VERIFIED: mix archive] | Manual host repo setup, but worse DX and lower proof repeatability. [VERIFIED: scripts/setup_sandbox.sh] |
| `rg` | Fast doc-contract checks | ✓ [VERIFIED: repo commands using `rg` succeeded in this session] | version not checked | `grep -n` |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment probes]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` on Elixir `1.19.5`. [VERIFIED: mix --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] |
| Quick run command | `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: executed in this session] |
| Full suite command | `mix test` [VERIFIED: .planning/phases/04-unified-install-path-dx/04-VALIDATION.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01.a | Installer composes the paved road, keeps extras explicit, and emits doctor follow-up. [VERIFIED: test/mix/tasks/parapet.install_test.exs] | unit | `mix test test/mix/tasks/parapet.install_test.exs` | ✅ |
| DX-01.a | README and operator docs match the shipped Day-1 command path. [VERIFIED: README.md] [VERIFIED: docs/operator-ui.md] | doc-check | `rg -n 'mix parapet\\.install|mix parapet\\.doctor|--with-ui|--skip-ui' README.md docs/operator-ui.md` | ✅ |
| DX-01.b | Doctor threshold, JSON, cluster-static, and runtime-mode honesty remain correct. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] | unit | `mix test test/mix/tasks/parapet.doctor_test.exs` | ✅ |
| AC-01 | A fresh Phoenix host can follow the Day-1 path and observe the documented contract, with UI still optional. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] | manual smoke | `mix phx.new ... && mix deps.get && mix parapet.install && mix parapet.doctor` | ❌ manual capture in `VERIFICATION.md` |

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** targeted tests green plus fresh-host smoke captured before `/gsd-verify-work`

### Wave 0 Gaps
- None for repo-internal automated proof; existing task tests already cover installer and doctor contracts. [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs]
- The fresh-host lane is a manual closure requirement, not a missing ExUnit harness. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep generated operator UI mounted only inside host-authenticated `scope` / `live_session`; verify with doctor and docs. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] |
| V3 Session Management | no | Host app session design is outside Phase 8 scope. [VERIFIED: docs/operator-ui.md] |
| V4 Access Control | yes | Preserve host-owned auth boundary; never auto-own router auth from `mix parapet.install`. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: README.md] |
| V5 Input Validation | yes | Use explicit Mix flags, threshold parsing, and controlled doctor check names. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| V6 Cryptography | no | No new crypto surface is part of this verification-only phase. [VERIFIED: phase scope synthesis] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated operator UI mount | Elevation of Privilege | Doctor `operator_ui` check plus docs that require authenticated `live_session` mounting. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: docs/operator-ui.md] |
| Misleading acceptance wording causing unsafe default-surface assumptions | Tampering | Correct `AC-01` to the shipped default-plus-optional contract before marking it verified. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] |
| Overstated cluster guarantees from install-time doctor output | Repudiation | Keep `cluster` mode as honesty/reporting only and cite Phase 5 as the real multi-node proof surface. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: .planning/v0.9-phases/5/VERIFICATION.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/v0.9-phases/8/08-CONTEXT.md` - locked scope, proof posture, reconciliation boundary
- `.planning/REQUIREMENTS.md` - `DX-01.a`, `DX-01.b`, `AC-01` wording and current pending state
- `.planning/ROADMAP.md` - Phase 8 closure scope and direct requirement targets
- `.planning/v0.9-MILESTONE-AUDIT.md` - orphaned-proof diagnosis and artifact drift
- `lib/mix/tasks/parapet.install.ex` - shipped Day-1 installer contract
- `lib/mix/tasks/parapet.doctor.ex` - shipped doctor semantics and `cluster` mode
- `test/mix/tasks/parapet.install_test.exs` - installer contract proof surface
- `test/mix/tasks/parapet.doctor_test.exs` - doctor contract proof surface
- `README.md` - public Day-1 install and doctor narrative
- `docs/operator-ui.md` - optional UI posture and auth boundary
- `scripts/setup_sandbox.sh` - existing disposable Phoenix host precedent
- `mix --version` - local Elixir/Mix runtime verification
- `mix archive` - local `phx_new` availability verification
- `mix hex.info igniter` - current Igniter release verification
- `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs` - current task-test behavior verification

### Secondary (MEDIUM confidence)
- `.planning/v0.9-phases/2/VERIFICATION.md` - verification artifact structure analog
- `.planning/v0.9-phases/3/VERIFICATION.md` - closure-phase proof pattern analog
- `.planning/v0.9-phases/5/VERIFICATION.md` - doctor-honesty and manual-boundary analog
- `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` - existing validation contract and manual-only note

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended tools and libraries were verified from the local environment, `mix.lock`, or Hex info output. [VERIFIED: mix --version] [VERIFIED: mix archive] [VERIFIED: mix.lock] [VERIFIED: mix hex.info igniter]
- Architecture: HIGH - the phase boundary and responsibility split are locked in `08-CONTEXT.md` and reflected in code/docs. [VERIFIED: .planning/v0.9-phases/8/08-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
- Pitfalls: HIGH - each pitfall is tied directly to the milestone audit, stale requirement wording, or the shipped docs/code boundary. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: README.md]

**Research date:** 2026-05-21  
**Valid until:** 2026-06-20
