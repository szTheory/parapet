# v1.0 "Stable Release" — Research Synthesis & Scope Recommendation

**Synthesized:** 2026-05-25
**Inputs:** `V1-STABILITY-FREEZE.md`, `V1-RELEASE-READINESS.md`, `V1-DEMO-APP.md`, `V1-SLO-WIZARD-BUNDLES.md`
**Decision posture:** decisive recommendation, coherent across all four forks, chunked for GSD execution.

---

## TL;DR

v1.0 is a **credibility/commitment milestone, not a feature milestone** (the Oban 1.0 model: cleanup + a written stability promise, not a feature vehicle). Its defining act is freezing the public API + telemetry contract with **three stability tiers + a written deprecation policy**, proven concrete by a **runnable demo app** that exercises the frozen surface. Everything else is the release-readiness scaffolding that lets a stranger trust `~> 1.0`.

**In scope (v1.0):** stability freeze · OSS governance docs · doc completeness (4 missing integration guides) · DEMO-01 demo app · proportionate verification gate + the Release-Please 1.0 cut.

**Deferred:** SLO-W1 wizard → **v1.1** (as a *flag-based* Igniter task, not an interactive wizard) · multi-version Elixir/OTP CI matrix → v1.1 · logo/favicon, `MAINTAINING.md`, SHA-pinned actions, demo Docker Compose → post-1.0.

**Dropped:** SLO-B1 formal Bundle abstraction — the `Parapet.SLO.Provider` pattern already *is* the bundle; document it instead.

---

## The one resolved tension: demo in v1.0 vs v1.1

The release-readiness agent instinctively deferred the demo to keep v1.0 lean; the demo-app agent (and the maintainer's selection) put it in v1.0. **Resolution: v1.0.** Rationale that breaks the tie:

1. The demo is a **contract test for the freeze** — any drift in the public surface breaks the demo's CI gate. Building it *during* the freeze milestone makes the freeze real rather than aspirational.
2. The engineering DNA explicitly calls for "example hosts" and "golden installer" evidence once the install surface stabilizes — which is exactly now.
3. It makes the <30-min getting-started guide *runnable*, closing the v0.10 deferral's open question ("do docs alone reduce onboarding friction?") with a live artifact.
4. Cost is low (~5–7h) and self-contained (no dependency on the other v1.0 work).

---

## Scope by workstream

### A. Stability Freeze (the defining commitment) — `STAB`
- **Three tiers:** Stable / Experimental / Internal, signaled in-module via ExDoc callout boxes (`> #### Stable {: .info}` / `> #### Experimental {: .warning}`) — no separate registry to drift. `Parapet.Internal.*` + `@moduledoc false` stays as-is for Internal.
  - *Stable at 1.0:* `Parapet.attach/1`, `Parapet.Integration`, `Parapet.SLO.Provider`/`SliceSpec`/`StarterPack.*`, `Parapet.Runbook`, `Parapet.Escalation.Policy`, `Parapet.Notifier`, `Parapet.Evidence`, `Parapet.Operator`, `Parapet.Deploy`, and all documented `[:parapet, …]` telemetry events.
  - *Experimental at 1.0:* `Parapet.MCP.*`, `Parapet.Automation.*`, `Parapet.Metrics.*`, `Parapet.Probe.*`, `Parapet.Evidence.Archiver`/`Retrospective`, individual `Parapet.Integrations.*` modules (the `Integration` *behaviour* is Stable; the per-adapter internals are not).
- `@doc since: "1.0.0"` on Stable public functions.
- **`docs/stability.md`** (unifies both researchers' proposed docs): tier table · explicit public-surface enumeration · what-counts-as-breaking (incl. telemetry event/measurement/metadata renames) · what's-additive · deprecation cycle (soft `@doc deprecated:` → hard `@deprecated` ≥1 minor → removal at major) · telemetry additive-only rules · "never add a configurable `:event_prefix`" (Oban's yanked-release lesson).
- **Extend `mix verify.public_api`** to detect tier from moduledoc and **fail on any unclassified public module** → tier annotation becomes mandatory for every future surface.
- **`test/telemetry_contract_test.exs`** — assert `Parapet.Telemetry.AsyncDelivery.event_families/0` + measurement/metadata key sets + outcome atom vocabularies against fixtures (Rulestead's pattern). Drift = CI failure, not a silent prod dashboard break.
- Hard-deprecate `Parapet.SLO.define/2` (already soft-deprecated; `Parapet.SLO.Provider` alternative shipped v0.6+).
- `mix.exs` docs: `groups_for_modules` (Public API vs Internals), stability header on `docs/telemetry.md`.

### B. OSS Governance Docs — `GOV`
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` (DNA mandates all three) + add to `files:` whitelist.
- README: explicit 1.0 semver commitment statement + Elixir/OTP/Postgres support matrix.

### C. Documentation Completeness — `DOCS`
- Four missing integration guides — **Chimeway, Mailglass, Rindle, Scoria** (Sigra guide is the template: prerequisites · what it unlocks · uniform activation line · config keys · troubleshooting). These shipped SLIs since v0.7 but have no activation guide — the clearest adopter-trust gap.
- Document the **Provider-as-bundle** pattern in the SLO authoring guide (closes SLO-B1 conceptually at zero cost).
- hexdocs polish: `groups_for_extras` subgroups (Getting Started / Guides / Integration Guides / Reference); switch `main:` to `getting-started`.

### D. DEMO-01 Runnable Demo App — `DEMO`
- Full child Phoenix app at `examples/demo_app/`, path dep `{:parapet, path: "../.."}` (PromEx pattern — the only shape satisfying Postgres + installer-exercise + CI-green simultaneously; `dev.exs`/PhoenixPlayground ruled out — no Ecto/Postgres).
- Committed generator output (`parapet_instrumenter.ex`, spine migrations) = what a real host app looks like post-install.
- `priv/repo/seeds.exs`: 3 incidents (open/investigating/resolved) + timeline entries + 1 tool audit + 1 runbook (with a `warning:` step) + WebSaaS SLO state. Plain Ecto inserts, no faker.
- `mix setup && mix phx.server` → populated Operator UI at `/parapet` in ~2 min.
- Smoke test (`GET /parapet → 200`, incident count > 0) + **`demo` CI job wired into `release_gate` (required, never `continue-on-error`)** + Dependabot entry for `examples/demo_app` + getting-started "Next steps" link. Verify Hex exclusion via `mix hex.build --dry-run`.

### E. Release Readiness & 1.0 Cut — `REL`
- CI hardening (lint job): `compile --warnings-as-errors`, `compile --no-optional-deps --warnings-as-errors`, `docs --warnings-as-errors`.
- Hex publish step in `release-please.yml` (Rulestead pattern: `release_created` gate → `hex.publish --dry-run` → `hex.publish --yes` → post-publish verify).
- **Proportionate verification gate** (matches chosen freeze depth — NOT a full hardening pass): `verify.public_api` + `test` + `credo --strict` + `dialyzer` + no-optional-deps compile + one manual cold-start walkthrough. ~30–45 min. No security audit, no perf benchmark, no multi-OTP matrix.
- **Release-Please 1.0 cut sequencing:** merge pending 0.10.0 PR → remove `release-as:"0.10.0"` pin → land all v1.0 work as conventional commits → add `release-as:"1.0.0"` → merge the 1.0.0 PR → immediately remove the pin **and** `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` (pre-1.0-only flags) → verify `hexdocs.pm/parapet/1.0.0/`.

---

## Recommended phase chunking (coarse; continues numbering from Phase 18)

| Phase | Name | Workstream | Why this order |
|-------|------|-----------|----------------|
| **19** | **API & Telemetry Freeze** | A (STAB) | Defining commitment; everything downstream references the frozen surface. |
| **20** | **Governance & Docs Completeness** | B + C (GOV, DOCS) | The trust artifacts + the 4 missing guides the demo & adopters reference. |
| **21** | **Runnable Demo App (DEMO-01)** | D (DEMO) | Crystallizes the frozen surface; acts as its CI contract test; makes the guide runnable. |
| **22** | **Release Readiness & 1.0 Cut** | E (REL) | Gates on everything above; performs the actual graduation to 1.0.0. |

4 coarse phases, sequential, ~6–8 focused days total. Each maps 1:1 to a workstream and to a clean requirement group.

---

## Deferred / dropped (explicit, with reasons)

| Item | Disposition | Reason |
|------|-------------|--------|
| SLO-W1 wizard | **v1.1**, flag-based Igniter task | Interactive form is non-idiomatic (Igniter has no prompt API); marginal value over the 15-line SliceSpec template; deferral is purely additive (host-owned output, zero frozen lib surface). |
| SLO-B1 bundles | **Dropped**; documented as Provider pattern | `Provider` returning many slices already is the bundle; a `use Parapet.SLO.Bundle` macro saves ~5 lines and would freeze a premature abstraction whose right shape depends on future Grafana grouping. |
| Multi-version Elixir/OTP CI matrix | v1.1 | Maturity signal, not a 1.0 blocker; add when an adopter base exists. |
| Logo/favicon, `MAINTAINING.md`, SHA-pinned actions, demo Docker Compose | post-1.0 | Aesthetic/internal/nice-to-have; not trust-bearing for 1.0. |
| Full security/perf re-audit | not in 1.0 | Maintainer chose "tiers + deprecation policy", not "full hardening pass". |
