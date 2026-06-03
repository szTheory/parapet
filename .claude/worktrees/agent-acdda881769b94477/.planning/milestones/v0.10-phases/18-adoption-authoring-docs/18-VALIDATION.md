---
phase: 18
slug: adoption-authoring-docs
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a **docs-only** phase — there is no new runtime code to unit-test. Validation
> is `mix docs` build integrity + an anti-drift grep suite that asserts every code symbol,
> config key, and behavior named in the docs actually exists in the live source.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExDoc build + Mix tasks + anti-drift grep suite (no new ExUnit tests) |
| **Config file** | `mix.exs` (`docs/0` extras), `test/test_helper.exs` (existing) |
| **Quick run command** | `mix docs --warnings-as-errors` |
| **Full suite command** | `mix test && mix verify.public_api && mix docs --warnings-as-errors` |
| **Estimated runtime** | ~30 seconds (docs build dominates) |

---

## Sampling Rate

- **After every doc committed:** Run `mix docs --warnings-as-errors` (catches broken cross-links to other extras immediately)
- **After every plan wave:** Run the full anti-drift grep suite (8 checks below)
- **Before `/gsd:verify-work`:** `mix test && mix verify.public_api && mix docs --warnings-as-errors` must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. Each authoring task maps to the doc-build +
> anti-drift checks below; the planner/Nyquist auditor fills concrete `{N}-NN-NN` rows.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | ADOPT-05 | T-18-01-* | compile-time integration contract | compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 18-01-02 | 01 | 1 | ADOPT-05 | T-18-01-* | Rulestead activates without raising | test | `mix test test/parapet/integrations/integration_behaviour_test.exs test/parapet/integrations/rulestead_test.exs` | ✅ | ⬜ pending |
| 18-01-03 | 01 | 1 | ADOPT-05 | T-18-01-* | CHANGELOG renders | docs-build | `mix verify.public_api` | ✅ | ⬜ pending |
| 18-02-01 | 02 | 1 | ADOPT-03 | T-18-02-* | N/A (docs) | grep + docs-build | getting-started anti-drift greps; `mix docs --warnings-as-errors` (W3) | ✅ | ⬜ pending |
| 18-02-02 | 02 | 1 | ADOPT-04 | T-18-02-* | N/A (docs) | grep | troubleshooting five-seed greps | ✅ | ⬜ pending |
| 18-03-01 | 03 | 1 | SLO-03 | T-18-03-* | N/A (docs) | grep | decision-tree litmus + WebSaaS slice greps | ✅ | ⬜ pending |
| 18-03-02 | 03 | 1 | SLO-04 | T-18-03-* | N/A (docs) | grep | min_total_rate 0.01 + six-window greps | ✅ | ⬜ pending |
| 18-04-01 | 04 | 2 | ADOPT-05 | T-18-04-* | N/A (docs) | grep | sigra/accrue activation + no-"SLO slice" greps | ✅ | ⬜ pending |
| 18-04-02 | 04 | 2 | ADOPT-05 | T-18-04-* | N/A (docs) | grep | rulestead/threadline activation + OQ-3 greps | ✅ | ⬜ pending |
| 18-05-01 | 05 | 3 | ADOPT-03/04/05, SLO-03/04 | T-18-05-01 | N/A (docs) | grep | extras-registration count == 7 | ✅ | ⬜ pending |
| 18-05-02 | 05 | 3 | ADOPT-03/04/05, SLO-03/04 | T-18-05-01 | N/A (docs) | docs-build + test | `mix docs --warnings-as-errors`; `mix test`; `mix verify.public_api` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement → Validation Map (from RESEARCH.md)

| Req ID | Behavior | Validation Type | Automated Command |
|--------|----------|-----------------|-------------------|
| ADOPT-03 | `getting-started.md` renders on hexdocs, cross-links resolve | docs build | `mix docs --warnings-as-errors` |
| ADOPT-04 | `troubleshooting.md` renders; all 5 seed Q&A headings present | docs build + grep | `mix docs --warnings-as-errors` + heading grep |
| ADOPT-05 | All 4 integration guides render under the Guides group | docs build | `mix docs --warnings-as-errors` |
| SLO-03 | `slo-authoring-guide.md` decision tree + good/bad examples present | docs build + grep | heading grep |
| SLO-04 | Low-traffic section names `min_total_rate` (0.01) + correct windows | grep | anti-drift suite checks 4–5 |

---

## Anti-Drift Verification Suite (the core docs-phase gate)

The dominant risk is documentation drift — docs naming APIs/metrics/config that don't exist.
Run these after authoring (script in a Wave 0 helper or run manually):

```bash
# 1. All 7 new docs are registered in mix.exs extras:
grep -c "docs/getting-started\|docs/troubleshooting\|docs/slo-authoring-guide\|docs/integrations" mix.exs
# Expected: 7

# 2. Rulestead activation is the UNIFORM line, never framed as a crash (D-16 SUPERSEDES D-07):
grep -q "Parapet.attach(adapters: \[:rulestead\])" docs/integrations/rulestead.md   # present: the valid uniform line
grep -rn "Parapet.Integrations.Rulestead.attach()" docs/                            # Expected: 0 (no special-case form)
grep -rniE "rulestead.*(raises|UndefinedFunctionError)|(raises|UndefinedFunctionError).*rulestead" docs/   # Expected: 0 (no crash framing)

# 3. Getting-started uses providers:, never the legacy degraded :slos env (D-04):
grep -rn "config :parapet, :slos" docs/getting-started.md
# Expected: 0 results

# 4. Low-traffic guide names the actual min_total_rate default (D-12):
grep "min_total_rate" docs/slo-authoring-guide.md   # at least 1 match referencing 0.01

# 5. Low-traffic guide names the actual multi-burn windows (D-12):
grep -E '"5m".*"30m".*"1h".*"6h".*"3d"' docs/slo-authoring-guide.md   # 1 match

# 6. Accrue/Rulestead/Threadline guides do NOT claim "SLO slices" (D-08/D-09):
for f in docs/integrations/accrue.md docs/integrations/rulestead.md docs/integrations/threadline.md; do
  grep -l "SLO slice" "$f" && echo "DRIFT RISK in $f"
done
# Expected: 0 matches

# 7. ExDoc builds clean:
mix docs --warnings-as-errors   # exit 0

# 8. All 7 new files actually render:
ls doc/getting-started.html doc/troubleshooting.html doc/slo-authoring-guide.html \
   doc/integrations/sigra.html doc/integrations/accrue.html \
   doc/integrations/rulestead.html doc/integrations/threadline.html
```

---

## Wave 0 Requirements

- [ ] `docs/integrations/` directory must exist before the four guides are authored
- [ ] Anti-drift grep suite available (inline shell or a committed helper script) for the phase gate
- [ ] No new ExUnit test files — existing suite + `mix verify.public_api` cover the code surfaces; docs are validated via `mix docs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 30-minute cold-start achievable end-to-end | ADOPT-03 / AC-01 | Wall-clock adopter experience can't be auto-timed | Follow `docs/getting-started.md` verbatim on a clean project; confirm install → running SLO → generated alert with zero raw PromQL |
| Per-integration guide enables activation without reading source | ADOPT-05 / AC-04 | Subjective "can a stranger activate it" check | Read each guide cold; confirm Prerequisites → unlocks → corrected activation line → config keys → 2–3 troubleshooting answers |

---

## Validation Sign-Off

- [ ] Every authoring task maps to a doc-build or anti-drift check (or a Wave 0 dependency)
- [ ] Sampling continuity: no 3 consecutive tasks without an automated check
- [ ] Wave 0 covers the `docs/integrations/` directory + anti-drift suite
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter once the planner wires task IDs

**Approval:** planner-assigned (task IDs wired 2026-05-24)
