# Phase 19: API & Telemetry Freeze - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-25
**Phase:** 19-api-telemetry-freeze
**Mode:** assumptions
**Areas analyzed:** Tier detection mechanism; verify.public_api alias wiring; Telemetry contract scope; Parameterized names & file placement; @doc since: enforcement & effort scale

## Assumptions Presented

### Tier detection mechanism
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Detect tier by parsing the ExDoc `{: .info}`/`{: .warning}` callout from each module's `@moduledoc` via `Code.fetch_docs/1`; callout-in-moduledoc is the single source of truth (no `@stability` attr, no registry) | Likely | lib/mix/tasks/verify.public_api.ex:48-55 (already calls Code.fetch_docs/1); V1-STABILITY-FREEZE.md:291,306; zero existing callouts (greenfield) |

### verify.public_api alias wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The `mix.exs` alias `"verify.public_api": ["docs --warnings-as-errors"]` shadows the real task — `mix verify.public_api` runs `mix docs`, so the tier logic is dead code at the CLI. STAB-04 requires rewiring the alias. | Confident | mix.exs:102 alias vs lib/mix/tasks/verify.public_api.ex:33-37; research (:414,535) missed the shadowing |

### Telemetry contract scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Freeze the full ~25-family `[:parapet, …]` surface (6 async/delivery + ~19 more: journey/scoria/operator/probe/ecto/http/oban/audit/deploy/rulestead), not just the 6 documented ones; raw ecto/http/oban passthroughs are public contract | Confident | docs/telemetry.md:17-120 documents only 6 families; lib/parapet/telemetry/async_delivery.ex:50-96 is the only contract module |

### Parameterized names & file placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Pin dynamic families via resolved `AsyncDelivery.event_families/0` list; policy file at `docs/stability.md` (overriding research's `stability-policy.md`); add to `extras:`; add stability header to docs/telemetry.md | Confident | async_delivery.ex:131-135 (guard-bound family); async_delivery_test.exs:6-15; STAB-02/ROADMAP.md:74; mix.exs:42 (files), :58-73 (extras) |

### @doc since: enforcement & effort scale
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `@doc since: "1.0.0"` is documentation-only (not gate-enforced); gate enforces module-level tier only; ~69 modules to classify, ~245 functions; unclassified namespaces Spine.*/Capabilities/StarterPacks need explicit tiers | Likely | task + research operate at module granularity; STAB-04 mandates only module tier; @deprecated already on SLO.define/2 (STAB-06 done) |

## Corrections Made

No corrections — all assumptions confirmed via "Yes, proceed" (assumptions confirmed as locked decisions D-01…D-14).

## External Research

None performed — the analyzer flagged no external-research gaps; the canonical research doc
(`.planning/research/V1-STABILITY-FREEZE.md`) plus the codebase fully covered the phase.

## Notes
- Session was resumed after a prior terminal crash during this same discuss-phase run;
  no artifacts had been written pre-crash, so analysis ran fresh.
