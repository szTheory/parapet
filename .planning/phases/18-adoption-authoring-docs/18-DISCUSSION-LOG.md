# Phase 18: Adoption & Authoring Docs - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 18-adoption-authoring-docs
**Mode:** assumptions
**Areas analyzed:** Doc Set Structure & Registration; Getting-Started Path Accuracy; Per-Integration Guides & Threadline Honesty; SLO-Authoring Low-Traffic Guidance & Troubleshooting Accuracy

## Assumptions Presented

### Doc Set Structure / Placement / Registration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| All 8 new files must be added explicitly to `extras:` (ExDoc doesn't glob); `~r/docs\//` group already matches `docs/integrations/`; `files:` already ships `docs` dir | Confident | mix.exs:42,58-66,69 |
| New docs cross-link to (not replace) adopter-flows.md / slo-reference.md; getting-started is a command sequence, slo-authoring links to the slice catalog | Confident | adopter-flows.md (conceptual), slo-reference.md:11-43 |
| Mirror established voice: prose-led, sentence-case headings, elixir/bash fences, no emojis | Confident | adopter-flows.md, slo-reference.md:14-21,49-51 |

### Getting-Started Path Accuracy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Real sequence: dep → `mix parapet.install` → `config :parapet, providers: [WebSaaS]` → `mix parapet.gen.prometheus` (→ alerts.yml) → `mix parapet.doctor`; use `providers:` NOT legacy `:slos` | Confident | web_saas.ex:7, slo-reference.md:14-21, parapet.gen.prometheus.ex:21-33 |
| Zero raw PromQL — Generator owns all PromQL | Confident | web_saas.ex:67-108, generator.ex:138-159 |
| WebSaaS HTTP/Oban slices work from plug/Oban telemetry alone; login slice needs Sigra (or a `[:parapet,:journey,:login]` emitter) for real data | Likely | web_saas.ex:85, sigra.ex:14,40-51, http.ex:29, oban.ex:45 |

### Per-Integration Guides + Threadline Honesty + attach API
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Parapet.attach(adapters: [...])` works for Sigra/Accrue/Threadline (have `setup/0`) but CRASHES for Rulestead (only `attach/0`); Rulestead guide must show `Parapet.Integrations.Rulestead.attach()` | Confident | parapet.ex:30-34, rulestead.ex:12, rulestead_test.exs:21 |
| Threadline is partially wired (inbound wired; outbound guarded by Code.ensure_loaded?); NO Threadline SLO slice/metrics module — guide must not claim SLO slices | Confident | threadline.ex:31-45,59-69,71-79; no slo/threadline*.ex or metrics/threadline*.ex |
| Accrue has metrics but no SLO slice module — Accrue guide surfaces metrics, not pre-built slices | Likely | metrics/accrue.ex present, no slo/accrue*.ex |
| Scope is the four named integrations; Chimeway/Mailglass/Rindle/Scoria already covered in slo-reference.md | Likely | slo-reference.md:27-42, ROADMAP.md:22 |

### SLO-Authoring Low-Traffic Guidance + Troubleshooting Accuracy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Low-traffic section must describe the EXACT guard `<ratio> > <threshold> and <total_rate> > <min_total_rate>`, default 0.01, windows ["5m","30m","1h","2h","6h","3d"], multipliers 14.4/6.0/1.0 | Confident | slice_spec.ex:27, generator.ex:10,103-106,196-199 |
| Synthetic probes are real (Parapet.Metrics.Probe) and citable as fallback; name "lower-the-objective" anti-pattern | Confident | probe.ex:38-70 |
| All 5 troubleshooting seeds map to real surfaces (doctor severity info=0/warn=1/error=2, `--ci` flips to :warn; Oban optional compile-out; cluster_static uniqueness ERROR; endpoint/router checks; Fly deploy hook) | Confident | doctor.ex:23,54-57,137-142,226-230,305-313; oban.ex:1; mix.exs:84; install.ex:282-295 |

## Corrections Made

No corrections — the user reviewed all assumptions and selected "Yes, proceed." All assumptions
were confirmed as locked decisions, including the Rulestead-attach correction (D-07) and the
Threadline/Accrue no-SLO-slices framing (D-08/D-09).

## Notes

- Two open questions were carried into CONTEXT.md for planning (not user corrections): OQ-1
  (Rulestead activation — doc-only fix vs. a one-line `setup/0` delegate) and OQ-2 (Fly.io
  troubleshooting boundary — link out for platform-internal scrape config).

## External Research

None — the codebase fully grounded every doc claim. The only external boundary is Fly.io's own
Prometheus scrape configuration, scoped out of authoritative assertion (OQ-2).
