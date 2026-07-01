# Phase 55: Demo App & Upgrade Docs - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-01
**Phase:** 55-demo-app-upgrade-docs
**Mode:** assumptions + deep-research decision forks
**Areas analyzed:** Smoke lane assertion (SAFE-03), upgrade-1.x.md structure (DOC-01),
deployment/README/migration-v1 wiring (DOC-02), demo app config posture

## Assumptions Presented

### Smoke lane assertion (SAFE-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add assertions to existing `operator_smoke_test.exs` (`@moduletag :smoke`), zero CI change | Confident | `operator_smoke_test.exs:1-4`; `ci.yml:167` |
| Six-table check via `information_schema.tables` filtered by `Evidence.schema_prefix()`, through `DemoApp.Repo` | Confident | `lib/parapet/evidence.ex:41-43`; sandbox `config/test.exs:8` |
| Round-trip asserts `get_meta(record,:prefix) == schema_prefix()` on `create_incident/1`, inline-seeded | Likely → Confirmed A1 | `operator_smoke_test.exs:57-68`; `prefix_propagation_test.exs:77,138` |
| Compile-out-clean already covered by library `lint` job; no demo step | Likely → Overridden to B2 | `ci.yml:42-44` |

### docs/upgrade-1.x.md structure (DOC-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Track A/B copy sourced verbatim from Phase-54 (gen.schema.move + doctor remediation) | Confident | `54-CONTEXT.md` D-04/D-06/D-08/D-17 |
| Order: reassurance → "action required" → Track A → Track B → GRANTs → recompile-order → rollback → FAQ | Confident | DOC-01 req; ROADMAP SC2; `54-CONTEXT.md` D-18 |
| Register in `mix.exs` extras + Guides group | Confident | `mix.exs:62-108`; `ci.yml:48` |

### deployment.md + README + migration-v1.md wiring (DOC-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| deployment.md net-new schema subsection; README note near Installation | Likely → Confirmed | grep found no schema section; `README.md:43-62` |
| migration-v1.md routing (inline Step-6 pointer vs dedicated step) | Likely → Resolved to C2-refined | `migration-v1.md` Step 1-6; `54-CONTEXT.md` D-05/D-17/D-18 |
| Pointer is a route, not duplicated content — migration-v1.md stays canonical hub | Confident | ROADMAP SC3; `54-CONTEXT.md` D-05 |

### Demo app config posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Demo already runs default `parapet` prefix (no explicit config) = real-host proof | Confident | `config/config.exs` omits `schema_prefix`; `lib/parapet/spine/schema.ex:81` |
| Six tables exist across the 3 committed demo migrations; no new migration | Confident | `20260525000000` (5) + `20260525000002` (action_claims) |

## Corrections Made

Three genuine forks were sent to dedicated deep-research subagents (idiomatic-Elixir /
test-correctness / DX / least-surprise / peer-library lenses) at the user's request, to
one-shot a coherent recommendation set.

### FORK A — SAFE-03 round-trip assertion style
- **Original assumption:** Likely — leg-agnostic `== schema_prefix()` on `create_incident`.
- **Resolution:** A1 confirmed decisively. The library's own proof
  (`prefix_propagation_test.exs:77` asserts against the compiled mirror, `:138` expects `nil`
  on the nil leg) is direct precedent. A2's hardcoded `"parapet"` goes red-but-correct on the
  `public` CI leg and encodes a "default-on only" claim D-17/D-18 forbid.
- **Reason:** Consistency with the existing house idiom + truthfulness under the dual-prefix matrix.

### FORK B — compile-out-clean home
- **Original assumption:** Likely — rely on the library `lint` job; no demo step (B1).
- **Resolution:** Overridden to **B2** — add a demo-scoped
  `mix compile --no-optional-deps --warnings-as-errors` in the existing `demo` job.
- **Reason:** The demo is a separate mix project with its own dep graph / app-env / protocol
  consolidation; the library compile cannot observe how parapet recompiles inside the demo's
  dep set. Canonical "example app catches a real-host break the lib compile missed" footgun.
  B1 leaves SAFE-03's "real host compile-out-clean" claim unproven. Cost: seconds on cached
  `_build`; keep it inside the `demo` job so `release_gate` `needs` is unchanged.

### FORK C — migration-v1.md routing
- **Original options:** C1 (inline pointer folded into existing Step 6) vs C2 (new dedicated step).
- **Resolution:** **C2-refined** — dedicated **early Step 3 "Choose your schema location
  (v1.7+)"** (renumber 3-6 → 4-7), reassure→instruct inline, route to upgrade-1.x.md for
  mechanics.
- **Reason:** C1 is exactly the D-17 "buried pointer" failure mode — a bullet among six
  deploy-validation items is skimmed past by the do-nothing upgrader who most needs it. The
  schema-default flip is the one *behavioral* break in the 1.x line, a peer of "update the
  dependency," not a checklist tick (mirrors Oban/ash version-specific upgrade sections).
  Mechanics stay single-sourced in upgrade-1.x.md to bound drift.

### Cross-cutting coherence constraint (all forks)
Single-source Track A/B mechanics in `upgrade-1.x.md`; migration-v1.md Step 3, deployment.md
subsection, and README note carry only the decision + one Track-A config line + a route.
Register upgrade-1.x.md in `mix.exs` extras + Guides. Centralize the canonical D-18 "action
required" sentence in upgrade-1.x.md; quote/route elsewhere.

## External Research

No web/library external research was required — all three forks resolved from repo evidence
(the library's own prefix tests, CI structure, Phase-54 locked decisions) plus known
Elixir-ecosystem upgrade-doc conventions (Oban/ash/Ecto version-specific upgrade sections).
