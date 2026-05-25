# V1.0 Release Readiness: The 1.0 Bar for Parapet

**Topic:** What is the credible 1.0 bar for an OSS Elixir reliability library, and what release-readiness work does Parapet still need?
**Researched:** 2026-05-25
**Confidence:** HIGH (ecosystem patterns), MEDIUM (cross-language analogues), HIGH (Release Please mechanics)

---

## 1. Decision Question

Parapet has shipped v0.10 with strong OSS discipline, rich features, and seven adoption guides. The next milestone is v1.0 with a stated theme of "API freeze and release readiness" using freeze depth = "stability tiers + deprecation policy." The question is: what does a credible 1.0 require for an Elixir SRE library, and what specific work does Parapet still need to cut it?

---

## 2. The 1.0 Readiness Checklist

### Semver & Stability Commitment

| Item | Status | Gap |
|------|--------|-----|
| `@version` in `mix.exs` as single source of truth | DONE (v0.10.0) | None |
| Explicit written semver commitment: post-1.0 breaking changes require major bump | MISSING | Write `docs/stability.md` or section in README |
| Stability tiers documented (public vs internal) | MISSING | Annotate `@moduledoc false` on internal modules; enumerate the public surface explicitly |
| Deprecation policy documented (minimum 1-minor-version before removal) | MISSING | Write the policy; no current `CONTRIBUTING.md` or stability doc exists |
| `@deprecated` attribute wired on any deprecated call paths | N/A (no deprecations yet) | Will become relevant at 1.1+ |
| `elixir: "~> 1.19"` requirement declared correctly | DONE | None |
| Elixir/OTP support matrix stated | MISSING | The `mix.exs` elixir constraint is set; no support matrix in README/docs |
| Version pin `~> 1.0` works correctly for adopters (vs `~> 0.10`) | Will be automatic after publish | None, automatic |

### OSS Root Document Completeness

| Doc | Status | Gap |
|------|--------|-----|
| `README.md` | DONE (badges, install, features) | Missing: explicit 1.0 semver commitment, Elixir/OTP support matrix |
| `CHANGELOG.md` (Release-Please-owned) | DONE | Release-Please will append 1.0 entry automatically |
| `docs/HISTORY.md` (retroactive v0.1-v0.9) | DONE | None |
| `LICENSE` | DONE (MIT) | None |
| `CONTRIBUTING.md` | MISSING | Must be created; the engineering DNA doc requires it |
| `SECURITY.md` | MISSING | Must be created; the engineering DNA doc requires it |
| `CODE_OF_CONDUCT.md` | MISSING | Should be created for 1.0 credibility |
| Maintainer runbook / `MAINTAINING.md` | MISSING | Internal doc; less urgent than the above three |
| `AGENTS.md` | Present (planning tooling context) | Should be excluded from Hex files whitelist if not already |

Current `files:` whitelist in `mix.exs`: `~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs)` — this will include `docs/` which is correct. But `CONTRIBUTING.md` and `SECURITY.md` would also need to be added when created.

### Hexdocs Polish

| Item | Status | Gap |
|------|--------|-----|
| `main:` set (currently `"readme"`) | DONE | Consider switching to `"getting-started"` for 1.0 — matches the guide structure |
| `extras:` includes guides and CHANGELOG | DONE (14 extras) | Missing guides for Chimeway, Mailglass, Rindle, Scoria integrations (see below) |
| `groups_for_extras:` — all guides under "Guides" bucket | PARTIAL — only one group `Guides: ~r/docs\//` | Subgroup: differentiate "Getting Started", "Integration Guides", "Reference" for navigability |
| `groups_for_modules:` | MISSING | Internal modules should be grouped away from public surface |
| Logo (`logo:` in `docs:`) | MISSING | Nice-to-have for 1.0; PNG/JPEG 64x64 |
| `source_ref: "v#{@version}"` | DONE | None |
| `skip_undefined_reference_warnings_on:` | DONE (`["CHANGELOG.md"]`) | None |
| CHANGELOG linked in HexDocs sidebar | DONE (in extras) | None |
| `links:` in `package:` pointing to GitHub/HexDocs/Issues/Changelog | DONE | None |

### Integration Guide Coverage

Four of eight adapters lack documentation guides:

| Integration | Guide Status |
|-------------|-------------|
| Sigra | DONE (`docs/integrations/sigra.md`) |
| Accrue | DONE (`docs/integrations/accrue.md`) |
| Rulestead | DONE (`docs/integrations/rulestead.md`) |
| Threadline | DONE (`docs/integrations/threadline.md`) |
| Chimeway | MISSING |
| Mailglass | MISSING |
| Rindle | MISSING |
| Scoria | MISSING |

All four missing integrations have shipped SLI/SLO surfaces, runbook templates, and are referenced in the SLO reference doc. They have no adopter-facing activation guide. This is a clear 1.0 gap for a library claiming adopter readiness.

### CI and Release Mechanics

| Item | Status | Gap |
|------|--------|-----|
| Conventional Commits enforced via PR title lint | MISSING (no `pr-title.yml` workflow) | Add `amannn/action-semantic-pull-request` |
| `compile --warnings-as-errors` in CI | MISSING — CI runs `mix test` but no `--warnings-as-errors` compile step | Add to lint job |
| `mix docs --warnings-as-errors` in CI | MISSING | Add `verify.public_api` to CI as a lint step |
| Hex `dry-run` before publish | MISSING (release-please workflow has no publish step) | Add publish step to `release-please.yml` |
| Post-publish parity check | MISSING | Consider adding `verify.release_parity` (already have `verify.public_api` alias) |
| Dialyzer in CI | DONE | None |
| Credo in CI | DONE | None |
| SHA-pinned CI actions | MISSING (using `actions/checkout@v4`, `erlef/setup-beam@v1` without SHA pinning) | Not a blocker for 1.0 but signals maturity |
| Elixir/OTP matrix (multiple versions) | MISSING (CI tests only `1.19.0`/`27.2`) | 1.0 should test at least 2 OTP versions |
| `release-as: "0.10.0"` pin removal | PENDING — pin must stay until v0.10.0 release PR merges | Remove immediately after 0.10.0 tag |

### Release-Please Mechanics for 1.0 Cut

| Step | Status | Notes |
|------|--------|-------|
| v0.10.0 release PR merged and tagged | PENDING | The `release-as: "0.10.0"` pin is still active in config |
| Manifest updated to `"0.10.0"` | Will be done by Release Please after 0.10.0 merges | |
| Remove `release-as` pin from config | After 0.10.0 tag | Required or RP reuses the same version |
| Add `release-as: "1.0.0"` to config for the 1.0 PR | At v1.0 milestone | This overrides conventional-commit-based version calculation |
| Merge the Release Please "1.0.0" release PR | At v1.0 release time | RP auto-creates it |
| Remove `release-as: "1.0.0"` pin from config | Immediately after 1.0.0 merges | Otherwise next RP run proposes 1.0.0 again |
| Remove `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` from config | At or after 1.0.0 | These settings are irrelevant post-1.0 and should be removed to make the config self-documenting |
| Publish to Hex.pm | Triggered by release PR merge | Add publish step to `release-please.yml` if not present |
| Verify HexDocs resolved at `https://hexdocs.pm/parapet/1.0.0/` | Post-publish | Manual check |

---

## 3. What's Idiomatic in the Elixir OSS Ecosystem

**The 1.0 signal is a social contract.** From the official Elixir library guidelines: "Pre-1.0 libraries using Semantic Versioning provide no guarantees about what might change from one version to the next." Cutting 1.0 means: breaking changes require a major bump, and adopters can pin `~> 1.0` without fear of arbitrary breakage.

**Idiomatic 1.0 for Elixir libraries:**
- Public surface is enumerated explicitly (even just via `@doc false` on internals and a written list in a guide)
- CHANGELOG has a clean entry describing what 1.0 means (not just a list of features)
- HexDocs are organized with `groups_for_extras` and `groups_for_modules` — the sidebar should feel curated, not dumped
- `mix docs --warnings-as-errors` passes in CI — broken doc references are treated as bugs
- A `CONTRIBUTING.md` exists so contributors know what the rules are
- The README states the supported Elixir/OTP versions
- The deprecation policy is written down, not assumed

**What the community does NOT require:**
- A CNCF-style maturity checklist or formal spec compliance
- Full hardening re-audit (that's a 2.0 or post-1.0 concern)
- Perfect hexdocs styling (logo, favicon) — those are nice, not required
- A security audit — `SECURITY.md` covers the disclosure policy, not an audit

---

## 4. Lessons From Comparable Libraries

### Oban Pro 1.0 (Elixir)
**Right:** The 1.0 release was purely deprecation cleanup and a namespace rename. Zero new features. The blog post made this explicit: "contains no features or bug fixes, purely some deprecation cleanup." The commit to API stability was credible because the surface had been stable for several pre-1.0 minors, and all breaking changes were pre-announced.
**Lesson:** Don't use 1.0 as a feature vehicle. Use it as a cleanup commit and a signal of intent. Oban's surface was already stable at 0.14; 1.0 just removed the deprecation cruft.

### Broadway 1.0 (Elixir, Dashbit)
**Right:** 1.0 included a new LiveDashboard plugin but was preceded by months of feature stabilization. The announcement named every feature that had shipped in the run-up.
**Lesson:** The 1.0 announcement should list what the stable surface IS, not just what is new. Adopters need to know what they can rely on.

### Ash Framework (Elixir)
**Right:** Ash went to 2.0 as their first "stable" signal (1.x was alpha in practice). They were honest about it.
**Footgun:** Shipping 1.x that isn't actually stable erodes trust badly. The community consensus is: if you're not confident in API stability, stay in 0.x. Parapet should NOT cut 1.0 until it is actually ready to make the semver promise.
**Lesson:** If the API surface has been stable and proven by adopters, cut 1.0. If it needs more adoption validation, do a 0.11 first.

### Sentry Elixir (9.x → major versions)
**Right:** Every major version ships an explicit `docs/upgrade-X-x.md` guide that names every removed module, every config rename, and every migration code example. These guides are in the HexDocs sidebar.
**Right:** Sentry was explicit that certain modules were "private API" that they reserved the right to change.
**Lesson:** Even if you have no breaking changes in 1.0, ship a `docs/upgrade-1-0.md` (or `docs/stability.md`) that lists the public surface and states what is internal. This is the trust artifact.

### Elixir's Own Deprecation Policy (HIGH confidence)
**What they codified:** Alternatives must exist for at least three minor versions before hard-deprecation warnings are emitted. Removal only happens in major versions.
**Lesson for Parapet:** The deprecation policy to write for 1.0 can be simpler — "an alternative must exist for at least one minor release before a feature is removed in a major release" — since Parapet is a library, not a programming language. But it must be written.

### OpenTelemetry SDK GA Criteria (cross-language, MEDIUM confidence)
**What they required:** Rigorous testing before a signal is called stable. Once stable: API backward-incompatible changes require major version increments. Previous major API versions supported for minimum 3 years. Deprecated code abides by the same support guarantees as stable code.
**Lesson:** The OTel model is too heavyweight for a solo-maintained OSS library. But the core principle is identical: say what is stable, say what is not, and don't break things you've said are stable.

### Prometheus Java Client 1.0
**Footgun:** The 1.0 was a breaking change (native histograms, new registry API). They shipped a bridge module for the old API but migration was still painful.
**Lesson:** For Parapet, which has no meaningful 0.x adopter base yet, this risk is low. But it reinforces: cut 1.0 when the API design is done, not when you have features to ship.

---

## 5. DX/UX & Adopter-Trust Considerations

**The "can a stranger trust pinning `~> 1.0`?" test.** An adopter evaluating Parapet at 1.0 will ask:
1. Is the installation path stable? (Yes — `mix parapet.install` is well-defined)
2. If I upgrade from 1.0 to 1.1, will my SLO definitions break? (Must be YES: they won't)
3. What is public API vs internal? (Currently unclear — no `@moduledoc false` audit documented)
4. What is the supported Elixir/OTP range? (Not stated in README)
5. How do I report a security issue? (No `SECURITY.md`)
6. How do I contribute? (No `CONTRIBUTING.md`)
7. What happens when I upgrade to 2.0 eventually? (No deprecation policy written)

Items 4-7 are the gap. Items 1-3 are mostly answered. The trust signal is the missing OSS root docs, not the features.

**The Chimeway/Mailglass/Rindle/Scoria gap.** These four integrations are documented in the SLO reference but have no adopter-facing activation guide. An adopter who configures Mailglass SLOs will hit the SLO reference and the telemetry doc but find no "how to enable Mailglass monitoring in 5 minutes" guide. This is a clear adopter-trust gap for integrations that shipped in v0.7 and are now one-year-old features at 1.0.

**`main: "readme"` vs `main: "getting-started"`.** This is a minor but visible signal. Libraries that have a proper getting-started guide should set it as the hexdocs landing page. `"readme"` is a 0.x convention. Switching to `"getting-started"` at 1.0 signals that the documentation is organized for adopters, not maintainers.

---

## 6. Recommendation

### Specific Docs/Guides to Write for v1.0

**Must-write (blocks credible 1.0):**

1. `CONTRIBUTING.md` — How to submit PRs, how to run tests locally (`mix test`, `mix credo`, `mix dialyzer`), code style (conventional commits, link to `.formatter.exs`), and what happens with PRs. 1-2 pages. The engineering DNA doc mandates this.

2. `SECURITY.md` — Vulnerability disclosure process. Standard GitHub advisory format. 1 page. The engineering DNA doc mandates this.

3. `CODE_OF_CONDUCT.md` — Contributor Covenant or equivalent. 1 page. Standard for 1.0 OSS libraries.

4. `docs/stability.md` — The stability contract. Contents: (a) what is public API (list the top-level modules explicitly: `Parapet`, `Parapet.SLO`, `Parapet.Integration`, `Parapet.Runbook`, `Parapet.Notifier`, `Parapet.Escalation`, `Parapet.Evidence`, mix tasks, telemetry event schema); (b) what is internal (`Parapet.Internal.*`, anything `@moduledoc false`); (c) the semver promise: breaking changes in public API require a major version bump; (d) the deprecation policy: any function/module deprecated in `N.x` will not be removed until `N+1.0`, and will emit `@deprecated` warnings for at least one minor release before removal; (e) the telemetry-as-API commitment (already in `docs/telemetry.md` — reference it here).

5. **Four missing integration guides:** `docs/integrations/chimeway.md`, `docs/integrations/mailglass.md`, `docs/integrations/rindle.md`, `docs/integrations/scoria.md`. These follow the existing pattern: prerequisites, what it unlocks, activation line, config keys, troubleshooting. The Sigra guide is the template. ~300-400 lines total across all four.

**Should-write (improves 1.0 quality but not a blocker):**

6. Add Elixir/OTP support matrix to `README.md`. One table: supported Elixir versions, OTP versions, Postgres versions. No prose needed.

7. Refine `groups_for_extras` in `mix.exs` to create sub-groups: `"Getting Started"` (readme, getting-started, troubleshooting, adopter-flows), `"Guides"` (slo-authoring, slo-reference, telemetry, operator-ui), `"Integration Guides"` (all four integration subdocs), `"Reference"` (CHANGELOG, HISTORY).

8. Add `groups_for_modules` in `mix.exs` to separate `"Public API"` from `"Internals"`. This requires auditing which modules should be `@moduledoc false`.

**Defer (post-1.0):**
- Logo/favicon in hexdocs (aesthetic, not trust signal)
- `MAINTAINING.md` (internal doc, not user-facing)
- `docs/upgrade-1-0.md` (not needed if there are no breaking changes from 0.10 to 1.0)
- Demo app (already deferred to DEMO-01)

### Proportionate Verification Gate

The maintainer chose "stability tiers + deprecation policy" freeze depth, not "full hardening pass." A proportionate verification gate for 1.0 is:

**Run before cutting the 1.0 release PR:**
1. `mix verify.public_api` (already exists as alias for `mix docs --warnings-as-errors`) — confirms all public modules have documentation and no broken refs
2. `mix test --warnings-as-errors` — baseline green suite
3. `mix credo --strict` — static analysis clean
4. `mix dialyzer` — type correctness clean
5. `mix compile --no-optional-deps --warnings-as-errors` — confirms clean compile without optional deps (Oban, OpenTelemetry, Sigra absent)
6. Manual: cold-install walkthrough from the getting-started guide on a fresh Phoenix app (the non-blocking UAT already tracked from v0.10; now it becomes a release gate)
7. Manual: confirm HexDocs resolve at the new version URL after publish

This is a 30-45 minute gate total. It is NOT: a security audit, a perf benchmark run, or a fresh-host Postgres deployment test. Those belong in a post-1.0 hardening pass if the community grows.

**Do NOT add to CI before 1.0** (avoid gold-plating the verification ceremony):
- Installer golden-diff tests for all 8 integrations
- Multi-version Elixir/OTP matrix (add this at 1.1, not a blocker)
- Playwright E2E (deferred DEMO-01)

### Exact "Cut 1.0" Mechanics/Sequencing

**Step 1: Merge the pending 0.10.0 release PR**
The `release-as: "0.10.0"` pin in `release-please-config.json` is intentionally retained until the v0.10.0 release PR merges and tags `v0.10.0`. Do this first. Release Please will update `.release-please-manifest.json` from `"0.9.0"` to `"0.10.0"` automatically.

**Step 2: Remove the `release-as` pin from config**
After the 0.10.0 release PR merges and the tag is created, immediately remove `"release-as": "0.10.0"` from `release-please-config.json`. If you skip this, Release Please will propose 0.10.0 again on the next run.

**Step 3: Land all v1.0 prep work as conventional commits on main**
All the docs, guides, CI improvements, and stability annotations should land as ordinary commits on `main` with conventional commit messages (`docs:`, `feat:`, `ci:`, etc.). Release Please will accumulate these into the pending release PR.

**Step 4: Pin `release-as: "1.0.0"` in config**
Before Release Please would naturally cut the release (which would be 0.11.0 given `bump-minor-pre-major`), add `"release-as": "1.0.0"` to the `.` package entry in `release-please-config.json`. Commit this. Release Please will propose `1.0.0` as the next version, overriding the conventional-commit calculation.

**Step 5: Let Release Please create the 1.0.0 release PR**
On the next push to `main` (or via `workflow_dispatch`), Release Please creates a PR proposing `1.0.0` with a generated CHANGELOG entry. Review and merge it. This triggers the `v1.0.0` git tag.

**Step 6: Immediately remove `release-as: "1.0.0"` after merge**
Critical: if you leave the pin, Release Please will propose 1.0.0 again on the next cycle. Remove the `"release-as"` key from config immediately after the tag is created. Also remove `"bump-minor-pre-major"` and `"bump-patch-for-minor-pre-major"` — these settings only apply pre-1.0 and are misleading if left in the config after graduation.

**Step 7: Add Hex publish step to `release-please.yml`**
Currently the `release-please.yml` workflow does not publish to Hex.pm after a release is created. The rulestead pattern is the model: add a `publish-hex` job conditioned on `release_created == 'true'` that runs `mix hex.publish --dry-run` followed by `mix hex.publish --yes`, then verifies the publish. This is load-bearing — without it, cuts to Hex.pm are manual.

**Step 8: Verify post-publish**
Check that `https://hexdocs.pm/parapet/1.0.0/` resolves. Run `mix verify.public_api` one more time against the tagged code.

**Post-1.0 config state:**
```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true,
      "package-name": "parapet"
    }
  }
}
```

---

## 7. Coherence With Parapet's Vision & Other v1.0 Decisions

The freeze depth chosen ("stability tiers + deprecation policy") is exactly right for Parapet's stage. The library's core value proposition — a paved road for Phoenix SRE teams — depends on adopters trusting that `~> 1.0` is safe to pin. That trust comes from:

1. The semver promise being written, not just implied
2. The integration surface being complete enough that adopters don't need to go off-piste to activate core features (the four missing guides are the gap here)
3. The OSS governance docs (CONTRIBUTING, SECURITY, CODE_OF_CONDUCT) signaling that the project is maintained with intention

The "stability tiers" framing is specifically coherent with the existing architecture: Parapet already separates public-surface modules from internal modules in practice (the `Parapet.Internal.*` namespace exists), and the telemetry doc already treats the telemetry schema as a versioned public API. v1.0 makes this explicit.

The API freeze decision (locking the `Parapet.SLO` DSL and integration attach surface) should be stated in `docs/stability.md` as part of the public API enumeration. It does not require new code — just documentation of what is already true.

---

## 8. Milestone Fit (v1.0 vs v1.1) + Effort + Phase Chunking

### What is v1.0 vs v1.1

**v1.0 (must-do):**
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` (1 phase, ~1 day)
- `docs/stability.md` — public surface enumeration + semver promise + deprecation policy (1 phase, ~1 day)
- Four missing integration guides: Chimeway, Mailglass, Rindle, Scoria (1 phase, ~2 days)
- `groups_for_modules` and `groups_for_extras` refinement in `mix.exs` (1 phase, ~half day)
- Release Please mechanics: 0.10.0 cut → remove pin → accumulate → add 1.0.0 pin → cut (continuous, not a phase — it's a workflow, not code work)
- Add Hex publish step to `release-please.yml` (1 phase with CI improvements, ~1 day)
- CI: add `compile --warnings-as-errors`, `docs --warnings-as-errors`, `compile --no-optional-deps` to lint job (same CI phase)

**v1.1 (defer):**
- Demo app (DEMO-01)
- `mix parapet.gen.slo` wizard (SLO-W1)
- Cross-integration SLO bundles (SLO-B1)
- Multi-version Elixir/OTP test matrix (add to CI after 1.0 when adopter base exists)
- `MAINTAINING.md` internal doc
- Logo/favicon

### Rough Effort

| Work | Effort | Notes |
|------|--------|-------|
| OSS root docs (CONTRIBUTING, SECURITY, CODE_OF_CONDUCT) | ~1 day | Boilerplate-heavy; draft against sibling libraries |
| `docs/stability.md` | ~1 day | Requires module audit; the public surface enumeration is the work |
| Four integration guides (Chimeway, Mailglass, Rindle, Scoria) | ~2 days | 300-400 lines each; follow Sigra template |
| `mix.exs` docs polish (groups_for_extras, groups_for_modules) | ~0.5 day | Config + verify in ExDoc output |
| CI improvements (compile flags, docs gate) | ~0.5 day | Low-risk changes |
| Release Please Hex publish step | ~0.5 day | Proven pattern from rulestead |
| Verification gate + cold-start UAT | ~0.5 day | Manual walkthrough |

**Total: ~6 days of focused work.** Appropriate for a milestone of this scope.

### Suggested GSD Phase Chunking

**Phase 1: OSS Governance Docs** (CONTRIB-01)
- Ship `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`
- Add to `files:` whitelist in `mix.exs`
- Add Elixir/OTP support matrix to README

**Phase 2: Stability Contract** (STAB-01)
- Audit all `lib/` modules — apply `@moduledoc false` to internal modules
- Write `docs/stability.md` (public surface list, semver promise, deprecation policy)
- Add `docs/stability.md` to `extras:` in `mix.exs`
- Add `groups_for_modules` and refine `groups_for_extras` in docs config

**Phase 3: Integration Guide Completion** (GUIDE-01)
- Write four missing integration guides: Chimeway, Mailglass, Rindle, Scoria
- Add all four to `extras:` and integration group in docs config
- Verify `mix verify.public_api` passes cleanly with all new pages

**Phase 4: CI Hardening + Release Mechanics** (RELMECH-01)
- Add `compile --warnings-as-errors`, `compile --no-optional-deps --warnings-as-errors`, `docs --warnings-as-errors` to CI lint job
- Add Hex publish step to `release-please.yml` (rulestead pattern)
- Sequence the 0.10.0 → 1.0.0 Release Please pin dance
- Run proportionate verification gate
- Cut 1.0.0

---

## 9. Sources

- [Elixir Library Guidelines — hexdocs.pm/elixir/library-guidelines.html](https://hexdocs.pm/elixir/library-guidelines.html) — HIGH confidence, official
- [Elixir Compatibility and Deprecations — hexdocs.pm/elixir/compatibility-and-deprecations.html](https://hexdocs.pm/elixir/compatibility-and-deprecations.html) — HIGH confidence, official; "3 minor versions before hard-deprecation" rule
- [Elixir Writing Documentation — hexdocs.pm/elixir/writing-documentation.html](https://hexdocs.pm/elixir/writing-documentation.html) — HIGH confidence, official; `@deprecated`, `:since`, `@doc false` patterns
- [OpenTelemetry Versioning and Stability Spec](https://opentelemetry.io/docs/specs/otel/versioning-and-stability/) — MEDIUM confidence; cross-language GA criteria, deprecation duration policy
- [Google OSS Breaking Change Policy](https://opensource.google/documentation/policies/library-breaking-change) — MEDIUM confidence; major version requirement for breaking changes, 12-month support window
- [Release Please manifest-releaser docs](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — HIGH confidence, official; `release-as` sequencing, critical "remove after merge" note
- [Oban Pro 1.0 changelog / release notes](https://oban.pro/docs/pro/1.0.0/changelog.html) — MEDIUM confidence; no features, only deprecation cleanup, the right model
- [Broadway 1.0 released blog — dashbit.co](https://dashbit.co/blog/broadway-1-0-released-with-a-new-dashboard) — cited but 404'd; reconstructed from secondary sources; LOW confidence on specifics
- [Ash Framework 2.0 release — ash-hq.org](https://ash-hq.org/blog/ash-framework-2-0-release) — MEDIUM confidence; simultaneous ecosystem package 1.0s, honesty about prior alpha state
- [Sentry Elixir upgrade-9-x guide](https://hexdocs.pm/sentry/upgrade-9-x.html) — HIGH confidence; explicit private-API removals, migration examples model
- [Rulestead release engineering & CI doc](../prompts/prior-art/rulestead-release-engineering-and-ci.md) — HIGH confidence, internal prior art; publish step, post-publish verify pattern
- [Parapet engineering DNA doc](../prompts/parapet-engineering-dna-from-sibling-libs.md) — HIGH confidence, internal; mandates CONTRIBUTING, SECURITY, CODE_OF_CONDUCT in root doc set
