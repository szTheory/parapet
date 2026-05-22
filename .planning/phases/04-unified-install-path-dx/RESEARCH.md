# Phase 4: Unified Install Path (DX) - Research

**Researched:** 2026-05-20
**Domain:** Elixir Mix task DX, Igniter generator orchestration, and multi-node doctor diagnostics [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Install flow coverage and order
- **D-01:** `mix parapet.install` becomes the public orchestrator for the Day-1 paved road rather than a thin wrapper over scattered manual steps.
- **D-02:** The encoded default order is: preflight detection, `mix parapet.gen.spine`, base `mix parapet.install` wiring, `mix parapet.gen.prometheus`, then gated extras.
- **D-03:** Core reliability surfaces should install automatically in the correct order; posture-changing surfaces should stay explicit.
- **D-04:** `mix parapet.gen.ui` should be offered only after core install, only when Phoenix LiveView is present, and must not auto-own router auth decisions.
- **D-05:** Optional integrations should run last, after the core install contract is established.
- **D-06:** The installer should end with a concise summary of generated files, skipped/selected extras, required host-owned follow-up, and `mix parapet.doctor` as the next verification step.

### Prompting and automation model
- **D-07:** The installer uses a hybrid model biased strongly toward deterministic defaults, not a chatty wizard.
- **D-08:** Every meaningful prompt must have an explicit non-interactive flag equivalent so docs, CI, and `mix igniter.install ... --yes` flows stay reproducible.
- **D-09:** Routine decisions should be shifted left into defaults; uncommon decisions should move to follow-up tasks; only materially impactful branches should prompt the maintainer.
- **D-10:** Default install should usually complete with zero prompts or at most one to two high-impact prompts.
- **D-11:** The installer should support preview-style trust surfaces such as explicit end-of-run summaries and, if practical, `--dry-run` style inspection rather than hidden magic.

### Optional integration handling
- **D-12:** Mailglass, Chimeway, and similar integrations remain strict opt-ins even when their dependencies are detected.
- **D-13:** Dependency or config detection is a convenience signal for prompting, not permission to auto-enable an integration.
- **D-14:** Non-interactive flags such as `--with-mailglass` and `--with-chimeway` should be the deterministic contract for automation.
- **D-15:** If an integration is enabled, generated changes should stay host-owned and explicit: wire `Parapet.attach(adapters: [...])` and the matching `config :parapet, providers: [...]` entries, rather than inventing a second activation path.
- **D-16:** The installer must not auto-add optional dependencies to `mix.exs`.
- **D-17:** Compile-out cleanliness is a proof surface for this phase: optional integration paths must continue to pass cleanly when deps are absent.

### Multi-node doctor posture
- **D-18:** `mix parapet.doctor` should adopt a mixed-severity model with at least `info`, `warn`, `error`, and `skip` semantics.
- **D-19:** Local default behavior should fail only on `error`; `--ci` should raise the fail threshold to include `warn` unless explicitly overridden.
- **D-20:** Exit codes should distinguish findings from doctor execution failure: `0` for no findings at threshold, `1` for findings at or above threshold, `2` for doctor/probe failure.
- **D-21:** Static doctor checks should remain honest about uncertainty and must not imply they can prove distributed correctness.
- **D-22:** Add an explicit runtime-oriented doctor mode for cluster-sensitive checks so Parapet can report live facts without pretending a static pass is enough.
- **D-23:** Multi-node findings should separate hard contradictions from plausible risk: missing required Oban/escalation setup is an error; ambiguity or non-provable safety gaps are warnings.

### Maintainer workflow preference
- **D-24:** For Parapet planning and implementation discussions, prefer research-backed recommendations and recommended defaults over asking the maintainer to decide low-impact details.
- **D-25:** Escalate choices back to the maintainer only when they materially change product posture, public API/DX, operator semantics, or architectural direction.

### the agent's Discretion
- Exact flag names and prompt copy, as long as the installer remains deterministic and least-surprise.
- Exact preflight checks and summary formatting.
- Exact severity labels and JSON/human doctor output shape, provided the threshold semantics remain coherent.
- Exact split between `mix parapet.install` internals and helper modules/tasks, as long as the public contract stays simple.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within the Phase 4 boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | System provides `mix parapet.install` as a unified, interactive starting point that sequentially runs necessary sub-generators. | Use Igniter task composition as the public orchestrator, declare composed tasks in `Igniter.Mix.Task.Info`, keep defaults non-chatty, and end with a summary notice plus `mix parapet.doctor` follow-up. [VERIFIED: lib/mix/tasks/parapet.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.html] |
| DX-01 | System's `mix parapet.doctor` checks for correct multi-node configuration (e.g., verifying Oban uniqueness settings for escalations). | Add severity-aware doctor checks, inspect Oban worker compile-time options, distinguish static risk from runtime fact, and reserve exit code `2` for doctor execution/probe failure. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: lib/parapet/escalation/worker.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
</phase_requirements>

## Summary

`mix parapet.install` should stay the single public entrypoint, but it needs to become a real orchestrator instead of a narrow endpoint patcher. The current task only creates the instrumenter module, configures `:instrumenter`, patches the endpoint with `Parapet.Plug.Metrics`, optionally composes `parapet.gen.scoria`, and updates `rel/hooks/post_start.sh`; it does not currently compose `parapet.gen.spine`, `parapet.gen.prometheus`, or `parapet.gen.ui`. [VERIFIED: lib/mix/tasks/parapet.install.ex] The README already tells adopters to run `mix parapet.install` and claims it wires Parapet in and creates a default SLO file, so Phase 4 should treat installer behavior plus docs alignment as one contract. [VERIFIED: README.md]

The current Igniter and Oban surfaces strongly suggest a specific implementation shape. Igniter composition is designed for exactly this kind of orchestration, and its docs require composed tasks to be declared in `Igniter.Mix.Task.Info` via `:composes`; Igniter also already provides global `--dry-run` and `--yes` behavior plus `add_notice/2` for end-of-run summaries. [VERIFIED: deps/igniter/lib/igniter.ex] [VERIFIED: deps/igniter/lib/mix/task/info.ex] [CITED: https://hexdocs.pm/igniter/Igniter.html] [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] For the doctor side, Oban’s official docs are explicit that uniqueness only affects insertion and has no bearing on concurrent execution, so Parapet’s static doctor must check for missing or weak uniqueness settings without overstating what those checks prove. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

**Primary recommendation:** Implement Phase 4 as `mix parapet.install` orchestration over existing generators plus a severity-aware `mix parapet.doctor` registry that adds one static multi-node check and one explicit runtime cluster mode. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Unified installer orchestration | Build / Tooling | Host app codebase | This behavior runs entirely in Mix/Igniter and writes host-owned files rather than runtime state. [VERIFIED: lib/mix/tasks/parapet.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.html] |
| Spine generation | Build / Tooling | Database / Storage | The generator emits migrations and config for the host repo, but the decision logic belongs in the install pipeline. [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] |
| Prometheus artifact generation | Build / Tooling | CDN / Static | The task writes static YAML artifacts to `priv/parapet/prometheus/*`, so install should compose it rather than duplicate it. [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex] [VERIFIED: docs/slo-reference.md] |
| Operator UI gating | Build / Tooling | Frontend Server (SSR) | The install task should decide whether to offer UI generation, but the generated output is Phoenix LiveView code mounted inside host-authenticated router scopes. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: docs/operator-ui.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Optional integration enablement | Build / Tooling | API / Backend | The installer should wire explicit adapter/provider config only when the maintainer opts in; runtime integration still lives in backend config and telemetry setup. [VERIFIED: lib/parapet/integrations/mailglass.ex] [VERIFIED: lib/parapet/integrations/chimeway.ex] [VERIFIED: docs/slo-reference.md] |
| Static doctor safety checks | Build / Tooling | API / Backend | Existing doctor behavior is source/config analysis, not runtime probing, and should remain the place for honest preflight safety checks. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| Runtime cluster doctor mode | API / Backend | Build / Tooling | Live cluster-sensitive checks must execute against loaded application state and worker config, with Mix only acting as the operator entrypoint. [VERIFIED: lib/parapet/escalation/worker.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `igniter` | Project locked `0.7.9`; current Hex release `0.8.0` published 2026-05-09. [VERIFIED: mix.lock] [VERIFIED: mix hex.info igniter] | Compose installer sub-tasks, reuse global `--dry-run`/`--yes`, and emit end-of-run notices. | This phase is squarely in Igniter’s documented composition model; replacing it with ad hoc `Mix.Task.run/2` would lose dry-run behavior, shared arg parsing, and generator-native UX. [VERIFIED: lib/mix/tasks/parapet.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.html] |
| `oban` | Project locked `2.22.1`; current Hex release `2.22.1` published 2026-04-30. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] | Define the static multi-node proof surface for escalations and any runtime doctor probe. | Oban is already the package boundary for Parapet escalation workers, and its official uniqueness semantics define what doctor can and cannot assert. [VERIFIED: lib/parapet/escalation/worker.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| `sourceror` | Project locked `1.12.0`; current Hex release `1.12.0` published 2026-03-06. [VERIFIED: mix.lock] [VERIFIED: mix hex.info sourceror] | Parse router AST for doctor checks without booting a full host app. | The existing doctor already uses Sourceror for router/operator-UI checks, so Phase 4 should extend that registry rather than swap parsing strategies. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_live_view` | Project locked `1.1.30`; current stable Hex release `1.1.30` published 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] | Gate `mix parapet.gen.ui` and preserve host-owned auth boundaries. | Only when the host project already uses LiveView and the maintainer explicitly opts into generated UI. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: docs/operator-ui.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| `jason` | Project locked `1.4.5`. [VERIFIED: mix.lock] | Keep machine-readable doctor output stable. | Use for JSON doctor output and any runtime mode payloads; the current task already conditionally emits JSON when Jason is loaded. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Igniter composition in `mix parapet.install` | Plain `Mix.Task.run/2` orchestration | Plain Mix would be simpler to call, but it would discard Igniter-native composition, flag propagation, dry-run semantics, and notice surfaces that already fit this phase. [VERIFIED: lib/mix/tasks/parapet.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.html] |
| Source-only doctor | Full runtime-only cluster doctor | Runtime-only checks would miss safe static guidance and would make local Day-1 validation dependent on booting optional runtime subsystems; the locked phase posture explicitly needs both honest static checks and an explicit runtime mode. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Current upstream package versions were verified with `mix hex.info igniter`, `mix hex.info oban`, `mix hex.info phoenix_live_view`, and `mix hex.info sourceror` during this session. [VERIFIED: mix hex.info igniter] [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info sourceror]

## Architecture Patterns

### System Architecture Diagram

```text
maintainer / CI
    |
    v
mix parapet.install [public entrypoint]
    |
    +--> preflight detection
    |      - Phoenix endpoint present?
    |      - LiveView present?
    |      - optional deps present? (signal only)
    |      - existing generated files/config?
    |
    +--> compose parapet.gen.spine
    |
    +--> apply base install wiring
    |      - instrumenter module
    |      - config :parapet, :instrumenter
    |      - endpoint metrics plug
    |      - deploy hook
    |
    +--> compose parapet.gen.prometheus
    |
    +--> decision point: offer parapet.gen.ui?
    |      - only if LiveView present
    |      - never auto-mount auth/router ownership
    |
    +--> decision point: enable optional integrations?
    |      - Mailglass / Chimeway via explicit flags or one prompt
    |      - write host-owned adapter/provider config only
    |
    +--> summary notice
           - generated files
           - skipped/selected extras
           - required host follow-up
           - next step: mix parapet.doctor

mix parapet.doctor
    |
    +--> static checks
    |      - runbooks / router / operator_ui / endpoint / cardinality
    |      - new: escalation multi-node config
    |
    +--> optional runtime mode
    |      - live Oban/escalation facts
    |
    +--> aggregate severities
           - local threshold: error
           - CI threshold: warn
           - exit 0/1/2
```

This diagram matches the locked install order and the existing seams in the codebase. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex] [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex]

### Recommended Project Structure
```text
lib/
├── mix/tasks/
│   ├── parapet.install.ex          # public orchestrator
│   └── parapet.doctor.ex           # public doctor entrypoint + threshold/output handling
├── parapet/install/
│   ├── preflight.ex                # detection and prompt/flag resolution
│   ├── integrations.ex             # explicit opt-in adapter/provider wiring
│   └── summary.ex                  # end-of-run notices and follow-up text
└── parapet/doctor/
    ├── result.ex                   # normalized check result shape
    ├── threshold.ex                # severity ordering and exit-code mapping
    ├── static_checks.ex            # router/endpoint/cardinality/escalation checks
    └── runtime_checks.ex           # explicit cluster-sensitive mode
```

This split preserves simple public task names while moving branching logic out of the Mix task modules. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex]

### Pattern 1: Thin Public Orchestrator Over Existing Generators
**What:** Keep `mix parapet.install` as the single public task and compose existing sub-generators in the locked order instead of duplicating their logic. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex] [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex]
**When to use:** For every core install step that already exists as a tested generator. [VERIFIED: test/mix/tasks/parapet.gen.spine_test.exs] [VERIFIED: test/mix/tasks/parapet.install_test.exs]
**Example:**
```elixir
def info(_argv, _parent) do
  %Igniter.Mix.Task.Info{
    composes: ["parapet.gen.spine", "parapet.gen.prometheus", "parapet.gen.ui"],
    schema: [with_ui: :boolean]
  }
end

def igniter(igniter) do
  igniter
  |> Igniter.compose_task("parapet.gen.spine")
  |> base_install_wiring()
  |> Igniter.compose_task("parapet.gen.prometheus")
end
```
// Source: Igniter composition contract. [CITED: https://hexdocs.pm/igniter/Igniter.html]

### Pattern 2: One Prompt Maximum for Extras, Flags for Everything
**What:** Detect optional capabilities first, then convert them into explicit booleans before any generator runs. Use flags as the contract and prompts only as a convenience when no flag was provided. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [VERIFIED: deps/igniter/lib/igniter/util/io.ex]
**When to use:** UI generation and optional integration enablement. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: lib/parapet/integrations/mailglass.ex] [VERIFIED: lib/parapet/integrations/chimeway.ex]
**Example:**
```elixir
ui_choice =
  cond do
    igniter.args.options[:with_ui] -> true
    igniter.args.options[:skip_ui] -> false
    not live_view_present? -> false
    igniter.args.options[:yes] -> false
    true -> Igniter.Util.IO.yes?("Generate the optional Parapet LiveView workbench?")
  end
```
// Source: Igniter global `--yes` support plus `Igniter.Util.IO.yes?/1`. [VERIFIED: deps/igniter/lib/mix/task/info.ex] [VERIFIED: deps/igniter/lib/igniter/util/io.ex]

### Pattern 3: Summary-First Install UX
**What:** Collect decisions and skipped items during orchestration, then present them in one concise end-of-run notice instead of interleaving noisy status text through the install flow. [CITED: https://hexdocs.pm/igniter/Igniter.html] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
**When to use:** Always; this is how the phase delivers “preview-style trust surfaces” without turning into a wizard. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
**Example:**
```elixir
Igniter.add_notice(igniter, """
Parapet installed.

- Core: spine + base wiring + Prometheus artifacts
- UI: skipped (LiveView not detected)
- Integrations: mailglass selected, chimeway skipped
- Next: mix parapet.doctor
""")
```
// Source: `Igniter.add_notice/2` displays notices after the task finishes. [CITED: https://hexdocs.pm/igniter/Igniter.html]

### Pattern 4: Severity Registry for Doctor Checks
**What:** Normalize every doctor check into a shared shape such as `%{status, messages, metadata}` and move threshold/output handling to one aggregator. [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
**When to use:** Adding multi-node checks and runtime mode, because the current task hard-codes only `:fatal` and `:warn` and treats `--ci` as output-format selection. [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
**Example:**
```elixir
%{
  id: :escalation_oban,
  status: :warn,
  messages: ["Escalation worker has no unique period configured"],
  metadata: %{static: true}
}
```
// Source: existing doctor result shape plus locked Phase 4 severity semantics. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]

### Anti-Patterns to Avoid
- **Re-implementing sub-generator logic inside `parapet.install`:** Existing generator behavior is already separated and partially tested; duplication will create order drift and test duplication. [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex] [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex]
- **Prompting inside nested generators:** The locked UX requires defaults and reproducible flags; prompts inside sub-generators break `--yes` automation and create surprise branches. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [VERIFIED: deps/igniter/lib/mix/task/info.ex]
- **Auto-owning router auth for the UI:** Project docs and LiveView security guidance both require host-owned auth plus `live_session`/`on_mount` checks. [VERIFIED: docs/operator-ui.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- **Treating Oban uniqueness as proof of distributed safety:** Oban’s docs explicitly say uniqueness only affects insertion and not concurrent execution. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Install orchestration | A custom task runner that manually shells out to multiple Mix tasks | `Igniter.compose_task/4` with declared `:composes` metadata | Igniter already solves arg propagation, dry-run behavior, and generator composition. [CITED: https://hexdocs.pm/igniter/Igniter.html] |
| Prompt plumbing | Custom `IO.gets/1` branching | Igniter global flags plus `Igniter.Util.IO.yes?/1` or `select/3` | This keeps `--yes` and deterministic non-interactive runs coherent. [VERIFIED: deps/igniter/lib/mix/task/info.ex] [VERIFIED: deps/igniter/lib/igniter/util/io.ex] |
| Optional integration activation | A second hidden activation path | Explicit `Parapet.attach(adapters: [...])` and `config :parapet, providers: [...]` edits | The project already documents adapter/provider separation and wants host-owned explicit wiring. [VERIFIED: docs/slo-reference.md] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] |
| Multi-node duplicate prevention | A bespoke distributed lock or “doctor says safe” claim | Oban worker `:unique` config plus honest warning text and a separate runtime mode | Oban owns enqueue-time uniqueness; Parapet should inspect it, not reinvent it or overclaim beyond it. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Router auth generation | Parapet-managed auth pipeline | Host-owned LiveView mounting guidance and doctor verification | The docs explicitly say Parapet does not provide its own authentication system. [VERIFIED: docs/operator-ui.md] |

**Key insight:** Phase 4 is mostly about composing and constraining existing seams, not adding new runtime magic. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: prompts/parapet-engineering-dna-from-sibling-libs.md]

## Common Pitfalls

### Pitfall 1: README Contract Drift
**What goes wrong:** The public docs promise more Day-1 behavior than the installer currently performs. [VERIFIED: README.md] [VERIFIED: lib/mix/tasks/parapet.install.ex]
**Why it happens:** `README.md` tells users that `mix parapet.install` wires Parapet in and creates a default SLO file, but the current task only handles instrumenter/config/endpoint/deploy-hook wiring. [VERIFIED: README.md] [VERIFIED: lib/mix/tasks/parapet.install.ex]
**How to avoid:** Treat docs updates as part of the install contract and verify the post-install summary against README language. [VERIFIED: README.md]
**Warning signs:** Install tests pass but README screenshots or copy still imply UI/spine/prometheus work that the task does not actually compose. [VERIFIED: test/mix/tasks/parapet.install_test.exs]

### Pitfall 2: Flag Drift Across Composed Tasks
**What goes wrong:** Flags accepted by the public install task are rejected or silently ignored when passed through to composed tasks. [CITED: https://hexdocs.pm/igniter/Igniter.html]
**Why it happens:** Igniter requires composed tasks to be declared in `:composes`, and the parent task must include any relevant option schema for nested flags. [VERIFIED: deps/igniter/lib/igniter.ex] [VERIFIED: deps/igniter/lib/mix/task/info.ex] [CITED: https://hexdocs.pm/igniter/Igniter.html]
**How to avoid:** Keep one public schema on `mix parapet.install`, resolve prompts into booleans once, and pass only normalized flags to sub-generators. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
**Warning signs:** `mix parapet.install --with-ui --dry-run` behaves differently from `mix igniter.install parapet --yes --with-ui --dry-run`. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html]

### Pitfall 3: UI Auth Ownership Leakage
**What goes wrong:** The installer starts deciding router auth or mounting the operator UI automatically. [VERIFIED: docs/operator-ui.md]
**Why it happens:** It is tempting to turn `gen.ui` into a turnkey route injector, but both project docs and LiveView guidance require host-owned auth checks in both plug and mount paths. [VERIFIED: docs/operator-ui.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
**How to avoid:** Gate UI generation on LiveView presence, scaffold files only, and emit router guidance as a notice or summary follow-up. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex]
**Warning signs:** Any Phase 4 patch that adds `pipe_through`, auth modules, or `live_session` ownership to host routers without explicit maintainer action. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex]

### Pitfall 4: Overconfident Multi-Node Doctor Checks
**What goes wrong:** Doctor reports “cluster safe” based only on source inspection. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
**Why it happens:** Oban uniqueness is easy to inspect statically, but official docs state uniqueness only applies on insert and not to concurrent execution. [CITED: https://hexdocs.pm/oban/unique_jobs.html]
**How to avoid:** Reserve `error` for hard contradictions like missing Oban/escalation setup or missing uniqueness period, use `warn` for non-provable safety gaps, and add an explicit runtime mode for live facts. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
**Warning signs:** Doctor output uses certainty words like “guaranteed,” “safe,” or “proved” without any live probe. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]

### Pitfall 5: Reinforcing Deprecated Legacy SLO Setup
**What goes wrong:** New installer or doctor examples lock Parapet harder into deprecated `Parapet.SLO.define/2` flows. [VERIFIED: docs/slo-reference.md] [VERIFIED: mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs]
**Why it happens:** Existing doctor tests still use legacy SLO definitions and emit deprecation warnings under `mix test`. [VERIFIED: mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs]
**How to avoid:** Keep backward-compatible doctor checks, but make install-time optional integration wiring target provider registration rather than runtime `:slos` mutation. [VERIFIED: docs/slo-reference.md]
**Warning signs:** New Phase 4 docs tell maintainers to add built-in integrations by mutating `Application.put_env(:parapet, :slos, ...)`. [VERIFIED: docs/slo-reference.md]

## Code Examples

Verified patterns from official sources:

### Composed Igniter Task With Explicit Metadata
```elixir
def info(_argv, _parent) do
  %Igniter.Mix.Task.Info{
    composes: ["parapet.gen.spine", "parapet.gen.prometheus"],
    schema: [with_ui: :boolean]
  }
end
```
// Source: Igniter requires composed tasks to be declared in `:composes`. [CITED: https://hexdocs.pm/igniter/Igniter.html]

### Oban Worker Uniqueness Shape
```elixir
defmodule MyApp.Worker do
  use Oban.Worker, unique: [period: 30]
end
```
// Source: Oban worker uniqueness is configured on `use Oban.Worker`; `period` should be explicit. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/oban/unique_jobs.html]

### LiveView Auth Boundary
```elixir
scope "/admin" do
  pipe_through [:authenticate_admin]

  live_session :admin, on_mount: MyAppWeb.AdminLiveAuth do
    live "/parapet", Parapet.OperatorLive.Index, :index
  end
end
```
// Source: LiveViews should be protected in both the plug pipeline and on mount. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Thin `parapet.install` that only patches endpoint/config/deploy hook | Public install orchestrator that composes existing generators in a locked order and ends with a summary | Needed now for Phase 4 scope dated 2026-05-20. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] | Planning should treat install orchestration, docs, and tests as one deliverable. [VERIFIED: README.md] |
| Binary `:fatal` / `:warn` doctor model with `--ci` meaning JSON output | Mixed severity (`info` / `warn` / `error` / `skip`) plus threshold-aware exit codes and a separate runtime mode | Needed now for locked decisions D-18 through D-23. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] | The plan should separate result normalization from rendering and exit behavior. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| Raw unique state lists in Oban workers | Named unique state groups such as `:incomplete`, `:scheduled`, `:successful`, and `:all` | Oban v2.20 introduced the named groups. [CITED: https://hexdocs.pm/oban/v2-20.html] | If Phase 4 adds or audits uniqueness settings, prefer named groups over long explicit state lists. [CITED: https://hexdocs.pm/oban/v2-20.html] |

**Deprecated/outdated:**
- Using `Parapet.SLO.define/2` as the blessed path for new built-in install wiring is outdated; the current SLO reference says built-ins should be registered through provider modules in config. [VERIFIED: docs/slo-reference.md]
- Treating `--ci` as “JSON mode” is outdated for this phase because the locked decision repurposes `--ci` as a stricter fail threshold. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited — no user confirmation needed.

## Open Questions (RESOLVED)

1. **Runtime doctor command shape**
   - Resolution: Keep the existing `mix parapet.doctor [checks...]` mental model and add one explicit sub-check name: `cluster`.
   - Chosen contract: `mix parapet.doctor cluster` for the runtime-oriented cluster posture check, with output formatting and threshold behavior staying orthogonal flags rather than being encoded in the check name. [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
   - Why: This preserves the current "named checks" CLI shape, stays discoverable beside `runbooks`, `router`, and `cardinality`, and avoids inventing a second mode system for one Phase 4 feature. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]

2. **Installer prompt shape**
   - Resolution: Use zero prompts by default where safe; if interaction is needed, prefer one summary prompt only when both optional UI and at least one optional integration are available. Otherwise use one targeted yes/no prompt or no prompt at all.
   - Chosen contract: flags remain the deterministic primary API (`--with-ui`, `--skip-ui`, `--with-mailglass`, `--with-chimeway`), and any interactive prompting is a thin convenience layer over those resolved booleans. [VERIFIED: deps/igniter/lib/igniter/util/io.ex]
   - Why: This satisfies D-07 through D-10 by minimizing chatter while still allowing one high-signal prompt when the maintainer would otherwise need to answer multiple related branch questions. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` bundled with Elixir `1.19.5`. [VERIFIED: elixir --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs`. [VERIFIED: mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs] |
| Full suite command | `mix test`. [VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | Unified install chains spine, base wiring, Prometheus, and gated UI/integration extras in the locked order. | unit | `mix test test/mix/tasks/parapet.install_test.exs -x` | ✅ [VERIFIED: test/mix/tasks/parapet.install_test.exs] |
| DX-01 | Doctor reports multi-node configuration findings with threshold-aware exit codes and explicit runtime mode separation. | unit | `mix test test/mix/tasks/parapet.doctor_test.exs -x` | ✅ [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs` [VERIFIED: mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs]
- **Per wave merge:** `mix test` [VERIFIED: .github/workflows/ci.yml]
- **Phase gate:** Full suite green before `/gsd-verify-work`, consistent with the existing CI lane that runs `mix test` on every push and pull request. [VERIFIED: .github/workflows/ci.yml]

### Wave 0 Gaps
- [ ] `test/mix/tasks/parapet.install_test.exs` — add coverage for composition order, `--dry-run`, `--yes`, UI gating, optional integration flags, and end-of-run summary notices for DX-01. [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
- [ ] `test/mix/tasks/parapet.doctor_test.exs` — add coverage for `info` / `warn` / `error` / `skip` normalization, threshold overrides, exit code matrix `0/1/2`, Oban uniqueness findings, and explicit runtime-mode behavior for DX-01. [VERIFIED: test/mix/tasks/parapet.doctor_test.exs] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
- [ ] Add one compile-out proof case showing Mailglass/Chimeway install paths stay clean when optional deps are absent. [VERIFIED: lib/parapet/integrations/mailglass.ex] [VERIFIED: lib/parapet/integrations/chimeway.ex] [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep operator UI mounting host-authored and verify authenticated scope guidance rather than generating a Parapet auth system. [VERIFIED: docs/operator-ui.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V3 Session Management | yes | Require LiveView mount-time checks alongside plug pipeline checks for generated UI routes. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V4 Access Control | yes | Doctor should continue flagging unsecured `live_dashboard`, `/metrics`, and operator UI routes. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| V5 Input Validation | yes | Use `Igniter.Mix.Task.Info` schemas and explicit flag resolution instead of ad hoc argv parsing. [VERIFIED: deps/igniter/lib/mix/task/info.ex] |
| V6 Cryptography | no | This phase does not introduce new crypto primitives or key handling. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Generated operator UI mounted without host auth | Elevation of Privilege | Keep auth host-owned, emit router guidance only, and retain doctor warnings for unauthenticated scopes or live sessions. [VERIFIED: docs/operator-ui.md] [VERIFIED: lib/mix/tasks/parapet.doctor.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Public `/metrics` or `live_dashboard` routes | Information Disclosure | Continue AST-based router checks and keep warnings visible in both human and machine-readable output. [VERIFIED: lib/mix/tasks/parapet.doctor.ex] |
| Hidden optional integration enablement | Tampering | Require explicit flags or explicit prompt acceptance before writing adapter/provider config. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [VERIFIED: docs/slo-reference.md] |
| Misstated cluster guarantees from static analysis | Repudiation | Separate static findings from runtime facts and use conservative severity text. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` - locked decisions, phase posture, and discretion boundaries. [VERIFIED: .planning/phases/04-unified-install-path-dx/04-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - DX-01 scope and acceptance criteria. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md` - package/install constraints, optional dependency posture, and host-owned code policy. [VERIFIED: .planning/PROJECT.md]
- `README.md` - current public install contract and current drift. [VERIFIED: README.md]
- `docs/operator-ui.md` - host-owned auth and UI mounting boundary. [VERIFIED: docs/operator-ui.md]
- `docs/slo-reference.md` - adapter/provider separation and preferred provider registration path. [VERIFIED: docs/slo-reference.md]
- `lib/mix/tasks/parapet.install.ex` - current installer behavior. [VERIFIED: lib/mix/tasks/parapet.install.ex]
- `lib/mix/tasks/parapet.gen.spine.ex`, `lib/mix/tasks/parapet.gen.prometheus.ex`, `lib/mix/tasks/parapet.gen.ui.ex` - reusable generator seams. [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex] [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex]
- `lib/mix/tasks/parapet.doctor.ex` - current doctor result model, checks, and exit behavior. [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
- `lib/parapet/escalation/worker.ex` and `lib/parapet/automation/executor.ex` - current Oban worker posture for escalations and uniqueness comparison. [VERIFIED: lib/parapet/escalation/worker.ex] [VERIFIED: lib/parapet/automation/executor.ex]
- `test/mix/tasks/parapet.install_test.exs` and `test/mix/tasks/parapet.doctor_test.exs` - existing proof surfaces and gaps. [VERIFIED: test/mix/tasks/parapet.install_test.exs] [VERIFIED: test/mix/tasks/parapet.doctor_test.exs]
- `mix hex.info igniter`, `mix hex.info oban`, `mix hex.info phoenix_live_view`, `mix hex.info sourceror` - current Hex versions and publish dates. [VERIFIED: mix hex.info igniter] [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info sourceror]
- `https://hexdocs.pm/igniter/Igniter.html` - composition, notices, and file-update APIs. [CITED: https://hexdocs.pm/igniter/Igniter.html]
- `https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html` - documented `--dry-run`, `--yes`, and `--yes-to-deps` behavior. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html]
- `https://hexdocs.pm/oban/unique_jobs.html` - uniqueness semantics, required `period`, and concurrency caveat. [CITED: https://hexdocs.pm/oban/unique_jobs.html]
- `https://hexdocs.pm/oban/Oban.Worker.html` - worker `:unique` options and runtime override behavior. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- `https://hexdocs.pm/oban/v2-20.html` - named unique state groups in current Oban. [CITED: https://hexdocs.pm/oban/v2-20.html]
- `https://hexdocs.pm/phoenix_live_view/security-model.html` - plug plus mount auth model for LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

### Secondary (MEDIUM confidence)
- `prompts/parapet-engineering-dna-from-sibling-libs.md` - host-owned installer, doctor-first, and compile-out product philosophy. [VERIFIED: prompts/parapet-engineering-dna-from-sibling-libs.md]
- `prompts/parapet-brand-identity-deep-research.md` - calm, summary-first DX posture. [VERIFIED: prompts/parapet-brand-identity-deep-research.md]
- `prompts/parapet-integration-opportunities.md` - ecosystem posture for Mailglass and Chimeway as explicit integrations. [VERIFIED: prompts/parapet-integration-opportunities.md]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current versions were verified from Hex and the codebase already depends on the key libraries. [VERIFIED: mix hex.info igniter] [VERIFIED: mix hex.info oban] [VERIFIED: mix.lock]
- Architecture: HIGH - the existing code seams already match the recommended orchestrator and registry split. [VERIFIED: lib/mix/tasks/parapet.install.ex] [VERIFIED: lib/mix/tasks/parapet.doctor.ex]
- Pitfalls: HIGH - each pitfall is grounded in current code, docs, tests, or upstream official docs. [VERIFIED: README.md] [VERIFIED: lib/parapet/escalation/worker.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html]

**Research date:** 2026-05-20
**Valid until:** 2026-06-19 for package/version details; architecture guidance should remain stable longer unless Igniter or Oban interfaces change materially. [VERIFIED: mix hex.info igniter] [VERIFIED: mix hex.info oban]
