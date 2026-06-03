# Phase 4: Unified Install Path (DX) - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a flawless Day-1 Parapet install path for Phoenix adopters by turning `mix parapet.install` into the clear, unified entrypoint for core setup, while extending `mix parapet.doctor` to catch meaningful multi-node safety risks. This phase covers installer orchestration, prompt/flag behavior, optional integration enablement, and doctor severity posture. It does not add new runtime reliability capabilities beyond what is necessary to make installation and safety validation coherent.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product posture
- `.planning/ROADMAP.md` — Phase 4 scope and milestone intent
- `.planning/REQUIREMENTS.md` — active DX and multi-node requirements
- `.planning/PROJECT.md` — host-owned posture, telemetry/API discipline, optional dependency constraints
- `.planning/STATE.md` — current milestone position and explicit Phase 4 focus
- `.planning/config.json` — current research-first workflow preference

### Existing install and doctor surfaces
- `README.md` — public install contract and Day-1 narrative that Phase 4 must tighten
- `docs/operator-ui.md` — UI generation and host-owned auth boundary
- `docs/slo-reference.md` — provider/adapter separation relevant to optional integration wiring

### Local research and guiding product philosophy
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned installer posture, doctor-first DX, optional dep discipline
- `prompts/parapet-brand-identity-deep-research.md` — calm, evidence-first, least-surprise product direction
- `prompts/parapet-integration-opportunities.md` — integration tiering and ecosystem posture for Mailglass/Chimeway and related adapters
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — reliability-layer positioning, generated paved-road lessons, alerting/operational discipline
- `prompts/elixir-telemetry-space-deep-research.md` — ecosystem lessons on generated host-owned observability glue vs backend magic

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/parapet.install.ex`: existing install entrypoint already wires instrumenter setup and deploy hooks; should become the orchestrator rather than be replaced.
- `lib/mix/tasks/parapet.gen.spine.ex`: core evidence-spine generator that naturally belongs first in the unified install order.
- `lib/mix/tasks/parapet.gen.prometheus.ex`: existing artifact generator for Prometheus rules; should be composed automatically as part of the paved road.
- `lib/mix/tasks/parapet.gen.ui.ex`: host-owned UI generator already preserves auth ownership; Phase 4 should gate it rather than absorb it into opaque install magic.
- `lib/mix/tasks/parapet.doctor.ex`: existing doctor task already has sub-check structure and exit-code behavior; it is the right seam for multi-node extensions.
- `lib/parapet/integrations/mailglass.ex` and `lib/parapet/integrations/chimeway.ex`: existing optional integration seams to preserve behind explicit enablement.

### Established Patterns
- Generated code is inspectable and host-owned; Parapet should scaffold and guide, not silently own runtime policy.
- Optional dependencies must compile out cleanly when absent.
- Doctor and diagnostics are already part of the public product story and should remain evidence-backed rather than theatrical.
- Core install surfaces should compose smaller generators rather than duplicate their logic.

### Integration Points
- Installer orchestration and flags in `lib/mix/tasks/parapet.install.ex`
- Core generator composition through `lib/mix/tasks/parapet.gen.spine.ex`, `lib/mix/tasks/parapet.gen.prometheus.ex`, and `lib/mix/tasks/parapet.gen.ui.ex`
- Optional adapter enablement through generated `Parapet.attach/1` and `config :parapet, providers: [...]`
- Multi-node safety checks in `lib/mix/tasks/parapet.doctor.ex` and associated tests/docs

</code_context>

<specifics>
## Specific Ideas

- The maintainer explicitly wants one-shot, coherent recommendations that reduce future decision burden and shift routine choices left.
- Recommendations should stay coherent with Parapet’s calm, protective, evidence-first brand and with Phoenix-style host ownership.
- Great developer ergonomics matter as much as technical correctness for this phase: short install path, predictable reruns, explicit summaries, and no hidden widening of the support surface.
- Research from `prompts/` should be treated as active guidance, not background reading.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 4 boundary.

</deferred>

---

*Phase: 04-unified-install-path-dx*
*Context gathered: 2026-05-20*
