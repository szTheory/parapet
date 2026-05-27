---
phase: 22-release-readiness-1-0-cut
authored: "2026-05-27"
status: lessons-captured
graduation_candidates:
  - LEARN-22-A → v1.2 supply-chain hardening (make release_gate enforce, not warn)
  - LEARN-22-C → GSD process default (write LEARNINGS at phase close)
---

# Phase 22 Learnings: Release Readiness for v1.0 Cut

Captures lessons from the v1.0 cut + post-cut maintenance window (Phases 19–22 + the 2026-05-27 cleanup session). These are strategic lessons, not execution recaps — see `22-*-SUMMARY.md` files for execution records.

## LEARN-22-A: `release_gate` is nominally required but actually bypassable

**Observation.** Every direct push to `main` during the 2026-05-27 cleanup window emitted:

```
Bypassed rule violations for refs/heads/main:
- Required status check "release_gate" is expected.
```

The branch protection rule names `release_gate` as a required check, but admin role can push regardless. This means:
- The protection is an audit trail, not a gate.
- Docs/test-config regressions slip through. Concrete cost: commit `c2a1ee8` introduced a README link to `docs/release-policy.md` without adding the file to `mix.exs` `extras`, breaking `mix docs --warnings-as-errors`. `release_gate` would have caught this; the bypass let it land. PR #3 then surfaced the regression and we had to push a follow-up fix (`1883664`) and re-run CI.
- The "quiet stable line" policy commits ironically demonstrate why the bypass undermines the policy.

**Implication.** Graduate to a v1.2 supply-chain hardening requirement: branch protection must block on `release_gate` for everyone, or the policy is on the honor system.

## LEARN-22-B: Release Please + Hex auto-publish is production-grade as designed

**Observation.** The `v0.10.0` → `v1.0.0` cuts went through Release Please PRs cleanly, with Hex publishing automated and HexDocs propagation handled. The one-time HexDocs propagation lag during `v1.0.0` was a real signal that needed a one-off `release-as: 1.0.0` pin, and the post-cut cleanup correctly removed it.

**Implication.** Don't re-engineer the release pipeline for v1.1. Treat the Release Please + Hex automation as a stable contract; v1.2 supply-chain hardening should reinforce it (SHA-pinned actions, Dependabot) rather than replace it.

## LEARN-22-C: Phase SUMMARYs ≠ LEARNINGS

**Observation.** Before this file existed, parapet had 18+ phase SUMMARY files across phases 19–22 but **zero** dedicated LEARNINGS files. SUMMARYs are execution records (what got built, in what order, with what tasks). They are not strategic lessons (what we learned about the *project* that should change future decisions).

**Implication.** Graduate to a GSD process default: write a LEARNINGS file at phase close alongside the SUMMARY, even if it's three bullets. The "no LEARNINGS exist" gap forced the 2026-05-27 strategic assessment to re-derive insights from research docs + code that should have been captured at phase boundaries. Future sessions need access to those lessons without re-deriving them.

## LEARN-22-D: Quiet-line policy needs a real taxonomy, not just a vibe

**Observation.** The 2026-05-26 quiet-stable-line policy commits established "no active milestone; default answer is nothing to do." But the 2026-05-27 cleanup session showed three different push-shapes happening that the policy doesn't explicitly distinguish:

1. **Docs/planning maintenance** — direct push to main (today's actual behavior, OK per the policy).
2. **Real feature work** — went through PR #3 (`feat(demo_app)`).
3. **Hygiene/test fixes** — went direct to main (`test(mcp)`), which is borderline — a `test:` commit isn't a `feat:` so probably OK, but a `fix:` would have been ambiguous.

**Implication.** The next codification of the policy (CONTRIBUTING.md + PR template + maybe `docs/release-policy.md`) should spell out the conventional-commit taxonomy explicitly:
- `docs:` / `chore:` / `ci:` / `test:` (no behavior change) → direct OK
- `feat:` / `fix:` / `perf:` / `refactor:` (any behavior or API change) → PR required, CI must be green
- The taxonomy doubles as the Release Please trigger surface.

## LEARN-22-E: v1.0 froze the contract; the v1.1 question is "execute, not detect"

**Observation.** Stepping back from the cut artifacts: the v0.1 → v1.0 arc was *detection*-focused — telemetry, SLOs, incidents, runbooks (as docs), notification, audit. The operator UI surfaces all of it. The v1.0 freeze locked the contract for that detection layer. But the user-flow loop closes at *action*, not at *display*, and the operator UI today still hands off action to other tools (Grafana, Notion, custom dashboards).

**Implication.** v1.1 = Actionable Recovery is the right next milestone *because* the v1.0 arc completed the detection contract. v1.1 doesn't need to extend detection; it needs to wire the action loop the operator UI already implies. See `.planning/NEXT-STEP-ASSESSMENT.md` for the scoped recommendation.
