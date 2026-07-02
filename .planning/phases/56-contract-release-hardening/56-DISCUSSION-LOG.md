# Phase 56: Contract & Release Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 56-contract-release-hardening
**Mode:** assumptions
**Areas analyzed:** SAFE-04 CHANGELOG framing (crux), SAFE-01 verify.public_api, SAFE-02 telemetry contract + Ecto `:source`, milestone done-criteria gating

## Assumptions Presented

### A. SAFE-04 — CHANGELOG framing (the crux)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Literal "No action required for existing installs" is factually false; must not be written verbatim. A do-nothing recompiling adopter breaks. | Confident (mechanism) | `lib/parapet/spine/schema.ex:81` (`compile_env(..,"parapet")`); `docs/upgrade-1.x.md:13,15,20-24,182-185,226-229`; `55-CONTEXT.md:84-90` (D-07); Phase-54 D-18; UPG-05 (`REQUIREMENTS.md:40`) = new-installs-only |
| Resolution is a wording strategy (narrow banner + surface Track A + link upgrade doc), not a mechanism change. | Likely | Two viable framings presented as alternatives |

### B. SAFE-01 — verify.public_api
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No new prod/task code; re-assert green with zero `--write`, pin as done-criterion. Prefix attribute not exported; only export `schema_prefix/0` already Stable+manifested. | Confident | `ci.yml:56`; `lib/parapet/spine/schema.ex:86,95`; `evidence.ex:41`; `priv/parapet/public_api_stable.json:46`; manifest last touched Phase 52, 53-55 added zero exports |

### C. SAFE-02 — telemetry contract + Ecto `:source`
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| "No schema event" + contract green = re-assert (35 families pinned with length assert). | Confident | `test/telemetry_contract_test.exs:212-216` |
| Ecto `:source` = bare-table-name invariance is UNPROVEN by any test — NEW behavioral assertion required. | Confident (unpinned), Likely (location) | `telemetry_contract_test.exs:168` pins key only; `lib/parapet/metrics/ecto.ex:79`; `test/parapet/metrics/ecto_test.exs:32,61,70` uses only synthetic sources |

### D. Milestone done-criteria gating
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Record 3 checks in 56-VERIFICATION/UAT; backstop = existing CI + ExUnit. No new gate task, no `mix ci` alias (deferred v1.8/CI-01). | Likely | Prior 55-* VERIFICATION/VALIDATION/UAT artifacts; `ci.yml:56`; roadmap `:184`; memory "Automate UAT into CI" |

## Corrections Made

### A. SAFE-04 — CHANGELOG framing
- **Original assumption:** Resolution likely = "narrow the banner to new installs + surface Track A + link the upgrade doc" (analyzer's Alternative 1: two-part banner, recommended).
- **User selection:** **Two-part banner** — confirmed the recommended reconciliation. Headline reassurance true for everyone ("No data is migrated automatically — your evidence tables never move unless you choose") + distinct "Existing adopters: one action required to stay on `public`" line with Track-A snippet and link to `docs/upgrade-1.x.md`.
- **Reason:** Satisfies SAFE-04's spirit (additive/semver-minor/reassuring) while honoring the shipped upgrade doc's "action required" letter (Phase-54 D-18 / Phase-55 D-07).

Areas B, C, D confirmed as-is (no correction).

## External Research
None — internal contract/release phase; all mechanisms, manifests, fixtures, and the CHANGELOG house format are present and unambiguous in the repo.
