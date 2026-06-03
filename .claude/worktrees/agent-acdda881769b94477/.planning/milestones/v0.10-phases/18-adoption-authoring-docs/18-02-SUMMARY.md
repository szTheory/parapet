---
phase: 18-adoption-authoring-docs
plan: "02"
subsystem: docs
tags: [documentation, getting-started, troubleshooting, adopt-03, adopt-04]
dependency_graph:
  requires: [18-01]
  provides: [docs/getting-started.md, docs/troubleshooting.md]
  affects: [docs/]
tech_stack:
  added: []
  patterns: [operator-ui.md cadence, slo-reference.md Q&A rhythm]
key_files:
  created:
    - docs/getting-started.md
    - docs/troubleshooting.md
  modified: []
decisions:
  - "Doctor --ci is the stricter gate (exits 1 on :warn or :error); local default fails only on :error"
  - "mix parapet.install does NOT auto-add WebSaaS provider — explicit manual config step documented"
  - "Login-slice data caveat explicit: parapet_journey_login_count must be emitted (Sigra or custom)"
  - "All three gen.prometheus output files named: recording_rules.yml, alerts.yml, rules.yml"
  - "Fly.io troubleshooting scoped to Parapet side only; links out for scrape/firewall"
metrics:
  duration_min: 25
  completed_date: "2026-05-24"
  tasks_completed: 2
  files_created: 2
---

# Phase 18 Plan 02: Getting Started and Troubleshooting Summary

Two adoption-critical Markdown docs authored with zero documentation drift: a cold-start tutorial from install to first generated Prometheus alert with no raw PromQL, and a five-seed Q&A troubleshooting reference anchored to live source behavior.

## What Was Built

### docs/getting-started.md (ADOPT-03 / AC-01)

A cold-start tutorial following the `operator-ui.md` cadence: one-sentence H1, orienting paragraph, Prerequisites bullet list, five sequential steps each with a one-sentence lead-in and fenced code.

Covers the exact cold-start sequence (D-04):
1. Add `:parapet` dep + `mix deps.get`
2. `mix parapet.install` — scaffolds instrumenter, endpoint plug, deploy hook; does NOT activate SLOs
3. `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]` — manual one-line activation; zero raw PromQL
4. `mix parapet.gen.prometheus` — all three output files named (`recording_rules.yml`, `alerts.yml`, `rules.yml`)
5. `mix parapet.doctor` / `mix parapet.doctor --ci` — local vs CI threshold explained correctly

Includes the login-slice data caveat (D-06): `parapet_journey_login_count` requires Sigra or another emitter; `min_total_rate` guard prevents false alerts but "no data is not green." Ends with a "Next steps" section cross-linking `adopter-flows.md`, `slo-authoring-guide.md`, and `docs/integrations/sigra.md`.

No legacy `:slos` path mentioned. No emojis. 98 lines.

### docs/troubleshooting.md (ADOPT-04)

A five-section Q&A reference following the `slo-reference.md` rhythm: `##` heading phrased as a symptom, one-sentence diagnosis, optional bash fence, one-sentence resolution.

Five seeds with verified live-code behavior (D-15):

1. **Prometheus target is blank** — `endpoint` check warns on missing `Parapet.Plug.Metrics`; `router` check looks for `/metrics`; confirms three gen.prometheus output files must be loaded
2. **Doctor warn-vs-error / CI uncertainty** — severity model `info=0/warn=1/error=2`; `--ci` is the stricter gate (exits 1 on `:warn` or `:error`); both bash forms shown
3. **Oban metrics missing** — `if Code.ensure_loaded?(Oban)` compile-out guard; `optional: true` in mix.exs; resolution: add `{:oban, ">= 0.0.0"}`
4. **Concurrent nodes execute escalation twice** — `cluster_static` check emits `:error` with exact message text; resolution: add `unique:` to escalation worker
5. **Fly.io deploy hook not firing** — scoped to Parapet's `rel/hooks/post_start.sh` with `$RELEASE_VERSION` and `Parapet.Deploy.mark/1`; links out to `https://fly.io/docs/` for scrape/firewall (OQ-2 boundary honored)

No emojis. 92 lines.

## Decisions Made

- `mix parapet.doctor --ci` is the **stricter** gate (threshold `:warn`, exits 1 on warn or error); the local default is `:error` (exits 1 on error only). Verified against `parse_threshold/2` at `doctor.ex:54-55`.
- `mix parapet.install` scaffolds instrumenter, endpoint plug, and deploy hook — it does NOT add `providers:` config. The manual config step is made explicit in getting-started.
- Login slice caveat is stated honestly: no data is not green, `min_total_rate` guard prevents flapping.
- Fly.io troubleshooting answer is scoped to Parapet's deploy hook side; links out rather than asserting Fly-internal scrape config (OQ-2 resolved).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both documents describe real, verified behavior. No placeholder text or wired-but-empty sections.

## Threat Flags

None — both files are read-only Markdown with no input handling, auth, or execution surface. The `/metrics` exposure note is present in troubleshooting (tied to the `endpoint` doctor check), and the legacy `:slos` path is never shown in getting-started.

## Self-Check: PASSED

Files created:
- docs/getting-started.md: FOUND (98 lines)
- docs/troubleshooting.md: FOUND (92 lines)

Commits:
- ff97b42: docs(18-02): author getting-started.md cold-start tutorial (ADOPT-03)
- c7aeffb: docs(18-02): author troubleshooting.md five-seed Q&A reference (ADOPT-04)

Anti-drift checks:
- `config :parapet, :slos` absent from getting-started: PASS
- All three gen.prometheus files named: PASS
- `--ci` direction correct + "stricter" present: PASS in both files
- Five troubleshooting seeds present (5 `##` sections): PASS
- Oban, --ci, unique, RELEASE_VERSION, Parapet.Plug.Metrics all present: PASS
- Fly.io links to https://fly.io/docs/: PASS
- No emojis in either file: PASS
