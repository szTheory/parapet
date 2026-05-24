# Phase 16: SLO Starter Packs & Low-Traffic Guardrails - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 16-slo-starter-packs-low-traffic-guardrails
**Mode:** assumptions
**Areas analyzed:** Pack structure & registration; HTTP selector / SliceSpec format (research flag); legacy-metric-name mismatch; DeliverySaaS conditional registration; low-traffic guard & low-cardinality compliance

## Assumptions Presented

### Pack Structure & One-Line Registration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `StarterPack.WebSaaS` is a new `@behaviour Parapet.SLO.Provider` with `slos/0` returning 3 SliceSpecs | Confident | slo.ex:71-77; mailglass_delivery.ex:6; chimeway_delivery.ex:6; rindle_async.ex:6 |
| One-line = add module to `config :parapet, providers: [...]` (NOT legacy `:slos` env) | Confident | slo.ex:71-77; http.ex:45-47 (legacy path); parapet.install.ex:71-74,147-164 |
| Pack defines fresh SliceSpecs; legacy SLO.HTTP/LoginJourney/Oban NOT reused | Likely | legacy default PromQL targets series not emitted in lib/ |

### HTTP Selector / SliceSpec Format (Research Flag)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No HTTP selector helper needed — `selector/2` is metric-agnostic | Confident | async_delivery.ex:108-130; generator.ex:156-159; resolvable.ex:49-51 |
| Match `status_class` ("2xx"/"3xx"), not `status_code` (a measurement) | Likely | plug/metrics.ex:23,28,39; metrics/http.ex:31,37 |

### Legacy-Metric-Name Mismatch
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Legacy SLO modules reference series the codebase does not emit; planning pins real names by code-read | Likely | no `parapet_journey_login_*` / `parapet_oban_job_*` emitter in lib/; real HTTP series in metrics/http.ex; real Oban series in metrics/oban.ex |

### DeliverySaaS Conditional Registration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Composes WebSaaS + delegates to MailglassDelivery.slos()/ChimewayDelivery.slos() | Likely | mailglass_delivery.ex:13-94; chimeway_delivery.ex:13-75 |
| Gated at runtime in `slos/0` via `Code.ensure_loaded?(Mailglass/Chimeway)` | Likely | threadline.ex:72; scoria.ex:185; parapet.ex:32; test/support stubs "compiler guards"; not in mix.exs deps:81-86 |
| Module always loadable/documented; no module-level compile guard | Confident | slo.ex:72 (runtime call); mix.exs:95 (docs --warnings-as-errors) |

### Low-Traffic Guard & Low-Cardinality Compliance
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Denominator guard already exists: SliceSpec.min_total_rate default 0.01, Generator-rendered | Confident | slice_spec.ex:27; generator.ex:103-107; generator_test.exs:37; mailglass_delivery.ex:71 |
| Low-cardinality is convention-only on slice matchers; pack self-disciplines (+ add assertion) | Likely | label_policy.ex:9-29,49-54; validator.ex:11-22; async_delivery.ex:134,145 (enforced only at metric-def time) |

## Corrections Made

No corrections — all assumptions confirmed. User selected "Yes, proceed" at the assumptions gate.

## External Research

None performed — the analyzer confirmed the phase is fully internal, including the research-flag
selector question. Two items remain for planning code-read (not external research): exact
Prometheus-formatted HTTP/Oban series names, and final choice of the DeliverySaaS gating signal.
