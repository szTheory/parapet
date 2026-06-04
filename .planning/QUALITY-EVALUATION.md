# Parapet Software Quality Evaluation

Date: 2026-06-04
Branch audited: `repo-hygiene/ui-docker-polish`
Head context: PR #29 at `3c0ca10` plus this quality pass

## 1. Executive Summary

**Weakest dimension:** Reliability, resilience, and durable evidence truth model
**Score:** 2
**Why weakest:** Parapet's core promise is evidence operators can trust. The audit found paths where durable evidence can drift from runtime truth: archive writes are not durably coupled to deletes, failed automation executions previously left claims live, and alert ingestion reported batch success even when per-alert persistence failed.
**If ignored:** Operators can lose trust in Parapet exactly where it claims to be strongest: incident evidence, recovery state, and webhook-to-incident truth.

**Second-weakest dimension:** Host-app compatibility and generated UI integration
**Score:** 2
**Why:** Generated UI code still assumes literal `/parapet` paths while docs recommend mounting under authenticated host scopes such as `/admin`.

**Third-weakest dimension:** Adoption-path truth
**Score:** 2
**Why:** README first-contact docs still emphasize older manual/raw-PromQL SLO setup while current Day-1 docs point at starter packs and zero raw PromQL.

**Overall quality read:** adoption-ready but not trust-polished.

**Blunt diagnosis:** Parapet has a serious foundation, but the next highest-impact work is making its trust promises impossible to accidentally violate.

## 2. Dimension Ranking Table

| Rank | Dimension | Score | Confidence | Evidence | Practical consequence | Highest-leverage fix | Priority |
|---:|---|---:|---|---|---|---|---|
| 1 | Reliability, resilience, fault tolerance | 2 | High | `lib/parapet/evidence/archiver.ex`, `lib/parapet/automation/executor.ex`, `lib/parapet/spine/alert_processor.ex` | Evidence and recovery state can lie under failure | Couple archive/delete truth; release failed claims; report per-alert failures | must fix before public adoption |
| 2 | Host-app compatibility | 2 | High | `priv/templates/parapet.gen.ui/*`, `docs/operator-ui.md` | Adopters can mount under auth and get broken nav/redirects | Add generated route/base-path seam | must fix before public adoption |
| 3 | Adoption ease | 2 | High | `README.md`, `docs/getting-started.md`, `docs/slo-reference.md` | New users follow harder legacy path first | Rewrite README around starter packs and current install flow | before Hex release |
| 4 | Backward compatibility/API stability enforcement | 2 | High | `docs/stability.md`, `lib/mix/tasks/verify.public_api.ex` | Stable signatures could drift while CI passed | Committed stable API manifest in CI | before more 1.x releases |
| 5 | Documentation information architecture | 3 | High | README repo-only demo links, docs relative links, integration docs | HexDocs/GitHub readers can hit broken or confusing paths | Link checker plus HexDocs-safe links | before Hex release |
| 6 | Public API design and DX | 3 | Medium | `Parapet.attach/1`, `docs/migration-v1.md`, `lib/parapet/slo/registry.ex` | Unknown attach opts can silently do nothing | Fix docs now; warn on unknown opts later | before Hex release |
| 7 | Data model/database hygiene | 3 | High | generated spine migrations vs schema timestamps | Host migration/schema type drift | Explicit `timestamps(type: :utc_datetime_usec)` | before Hex release |
| 8 | UI/UX quality | 3 | Medium | generated direct action buttons, preview panel, UI tests | Operators may hesitate on one-click mutations | Confirm/pending pattern for high-impact actions | before 1.0 polish equivalent |
| 9 | Accessibility | 3 | Medium | generated flash/live updates, preview panel semantics | Keyboard/screen-reader users can miss state changes | Live regions and focus management | before broad adoption |
| 10 | SRE/observability readiness | 3 | Medium | telemetry docs strong, unattended job telemetry thin | Failures require DB spelunking | Add bounded telemetry for archive/claims/escalation | before 1.0 polish equivalent |
| 11 | CI/CD automation | 4 | High | matrix CI, docs warnings, Credo, Dialyzer, demo smoke | Strong, with supply-chain and release-gate enforcement gaps | Add `mix hex.audit`; verify release SHA gate | should fix before routine unattended publish |
| 12 | Release/versioning/upgrades | 4 | Medium | release policy, Release Please, maintainer docs | Good, but docs disagree on review model | Align release docs and branch protection | should fix before next release-process change |
| 13 | Testing/QA | 4 | High | 525 root tests, demo tests, focused UI tests | Strong, but UI behavior and failure injection gaps remain | Add browser lane and failure-injection tests | should fix before broad adoption |
| 14 | Security/abuse resistance | 4 | Medium | auth docs, doctor warning, action payload audit checks | Good host-owned posture; UI mount path risk remains | Route/auth regression tests | must fix where tied to UI path |
| 15 | Performance/resource efficiency | 4 | Medium | queue paging tests, 50k advisory lane | Good for main UI list path | Keep advisory benchmark; avoid default CI bloat | nice later |
| 16 | Data lifecycle/privacy | 3 | Medium | archiver, system event pruner, audit docs | Retention exists but archive durability needs hardening | Archive manifest/staging semantics | must fix before public adoption |
| 17 | Dependency health/supply chain | 4 | Medium | optional deps, pinned Actions, Dependabot | Good, missing audit lane | Add `mix hex.audit` | should fix soon |
| 18 | Ecosystem fit/interoperability | 4 | Medium | Phoenix/Ecto/Oban/Telemetry conventions | Generally idiomatic | Fix generated route-base behavior | should fix |
| 19 | Portability/deployment compatibility | 4 | Medium | deployment guide, demo Compose, optional deps | Good; cluster/runtime proof is selective | Add production checklist for unattended jobs | nice later |
| 20 | Configuration quality/defaults | 4 | Medium | `mix parapet.install`, doctor, config docs | Good, one bad migration doc path | Fix provider config docs | before Hex release |
| 21 | Extensibility/customization | 3 | Medium | behaviours, generated host-owned UI, inline style/script | Strong behaviours; UI customization brittle | Token contract and optional JS hook | before broad UI adoption |
| 22 | Design-system coherence | 4 | Medium | v1.3 UI polish, semantic tokens, tests | Good after PR #29 | Continue with CSP/host-token cleanup | nice later |
| 23 | Product clarity/problem fit | 4 | Medium | `.planning/PROJECT.md`, README, adopter flows | Strong concept; README flow drift weakens it | Align README with product wedge | before Hex release |
| 24 | Functional suitability/core correctness | 3 | Medium | broad tests, found runtime failure gaps | Good happy path; failure paths need hardening | P0 trust fixes | must fix targeted gaps |
| 25 | Maintainability/evolvability | 4 | Medium | clear modules, stability docs, tests | Good, with generated UI complexity | Avoid broad refactors; add seams only where needed | nice later |
| 26 | Architecture/boundaries | 4 | Medium | public/internal split, behaviours, optional deps | Boring and serviceable | Keep evidence/runtime/UI boundaries explicit | nice later |
| 27 | Troubleshooting/supportability | 3 | High | troubleshooting guide, doctor, integration warnings | Good docs, but reporter wiring scattered | One reporter-wiring guide | before broad adoption |
| 28 | Contributor experience | 4 | Medium | CONTRIBUTING, CI, local commands | Good enough | Add failing-focused command map | nice later |
| 29 | Maintainer experience/support burden | 3 | Medium | release docs, planning state drift | Strong, but stale planning can mislead agents | Clean `.planning/PROJECT.md` historical blocks | nice later |
| 30 | OSS polish/trust signals | 4 | High | license, security, CI badge, HexDocs, changelog | Strong for a small OSS lib | Fix first-contact docs and links | before Hex release |
| 31 | Legal/licensing/compliance | 5 | Medium | MIT license, no obvious asset issue | Low adoption risk | Keep dependency licenses visible if adding deps | not worth doing yet |
| 32 | Safety defaults/failure behavior | 3 | High | action preview design, claim service, archive gap | Strong intent; failure gaps found | Harden P0 failure paths | must fix targeted gaps |
| 33 | Examples/demos/sample apps | 4 | High | runnable demo, seeded scenarios, Compose | Strong, missing screenshots/expected output | Add screenshots and first-screen proof | before broad adoption |
| 34 | Internationalization/localization | N/A | High | operator/admin OSS tool, English-only acceptable | Not a real blocker now | Do nothing | not worth doing yet |
| 35 | Intangible coherence/taste | 4 | Medium | clear wedge, evidence-first UI, host-owned model | Coherent, but trust gaps feel sharp | Prioritize trust repairs over new features | should guide roadmap |
| 36 | Product-specific: generated-code quality | 2 | High | generated UI paths/styles/scripts/tests | Generated code is adopter-owned and must be boring | Route seam, CSP/theming cleanup, behavior tests | must fix before broad UI adoption |
| 37 | Product-specific: telemetry contract enforceability | 3 | High | stability promise, telemetry tests | Good, but stable API gate was shallow | Manifest + telemetry family checks | before more 1.x releases |

## 3. Top 5 Weakness Deep Dives

### 1. Reliability and Durable Evidence Truth

**Observed:** The archive path writes JSONL and then deletes rows without a durable manifest/staging handshake; the automation executor did not release claims after failed execution; alert batch processing returned `:ok` regardless of per-alert transaction failures.

**Why it matters:** Parapet sells evidence, not just dashboards. If evidence can be duplicated, lost, or silently skipped, adoption trust drops quickly.

**Evidence:** `lib/parapet/evidence/archiver.ex`, `lib/parapet/automation/executor.ex`, `lib/parapet/spine/alert_processor.ex`.

**First fixes:** Release failed claims immediately, return per-alert batch failures, and design a durable archive manifest/staging flow before expanding archive use.

**Do not over-fix:** Do not build a full backup system. The host app owns database backups; Parapet only needs its archive/delete semantics to be honest.

### 2. Host-App Compatibility

**Observed:** Docs recommend authenticated scoped mounting, but generated UI links use literal `/parapet`.

**Why it matters:** A Phoenix library must behave like a respectful guest. Broken links inside an authenticated admin scope are adoption poison.

**Evidence:** `docs/operator-ui.md`, `priv/templates/parapet.gen.ui/router_snippet.ex.eex`, generated `operator_live`, `operator_detail_live`, and `operator_components` templates.

**First fixes:** Generate a base path or route helper seam and prove `/admin/parapet` works.

**Do not over-fix:** Do not invent a routing framework. Keep the generated code inspectable and host-owned.

### 3. Adoption-Path Truth

**Observed:** README still puts raw PromQL and `Parapet.SLO.define/2` in the main operator loop even though getting-started now says starter packs are the Day-1 path.

**Why it matters:** New adopters should hit the paved road first. Legacy setup should not be the first thing they copy.

**Evidence:** `README.md`, `docs/getting-started.md`, `docs/slo-reference.md`, `docs/migration-v1.md`.

**First fixes:** Rewrite README around `mix parapet.install`, provider config, `mix parapet.gen.prometheus`, and `mix parapet.doctor`.

**Do not over-fix:** Do not delete the manual path. Move it into advanced/reference docs.

### 4. Stable API Enforcement

**Observed:** Stability docs promise stable module/callback/function safety, but the old CI check only validated docs and tier labels.

**Why it matters:** A stable 1.x line needs machine-checked promises, especially for OSS users who upgrade without knowing the internals.

**Evidence:** `docs/stability.md`, `lib/mix/tasks/verify.public_api.ex`.

**First fixes:** Commit a stable manifest for exported functions, macros, callbacks, struct keys, and telemetry families where practical.

**Do not over-fix:** Do not freeze every experimental module. The tier system exists to avoid that.

### 5. Generated UI Action Safety and Accessibility

**Observed:** Several high-impact controls are direct click handlers with limited pending/confirmation semantics; preview state lacks full dialog/focus/live-region treatment.

**Why it matters:** Operators under incident pressure need the UI to prevent accidental destructive actions and announce state changes clearly.

**Evidence:** generated `operator_components.ex.eex`, `operator_live.ex.eex`, `operator_detail_live.ex.eex`, UI tests.

**First fixes:** Add shared confirm/pending UI for high-impact actions and live-region/focus primitives.

**Do not over-fix:** The IA is already good. Do not redesign the workbench before fixing the interaction safety gaps.

## 4. Adoption Friction Audit

| Step | Friction | Missing/confusing | Highest-leverage fix |
|---|---|---|---|
| README landing | Medium | Strong value prop, but flow starts with legacy SLO definition | Put starter-pack flow first |
| Understand problem | Low | Product wedge is clear | Keep concise |
| Decide applicability | Medium | Alternatives/when-not-to-use could be sharper | Add "use/do not use" block |
| Install | Low | `mix parapet.install` exists | Keep one command |
| Configure | Medium | Provider config docs drifted | Use `config :parapet, providers:` consistently |
| Migrations | Medium | Timestamp type drift in generator | Explicit timestamp type |
| Routes/supervision | High for UI | Scoped mount can break generated paths | Route-base seam |
| First useful example | Low | Demo is runnable | Add screenshots/expected output |
| Debug first error | Medium | Troubleshooting good; reporter wiring scattered | One reporter wiring guide |
| Realistic app | Medium | Optional deps compile out, but docs are scattered | Central integration checklist |
| Customizing | Medium | UI theming/CSP brittle | Token/JS hook docs |
| Upgrading | Medium | Stability docs strong; migration doc had bad call | Fix docs and API manifest |

## 5. Production Readiness / SRE Audit

| Step | Works | Missing/risky | Risk reducer |
|---|---|---|---|
| Deploy | Deployment guide and doctor exist | Release workflow publish relies on external gate truth | Verify release SHA gate before publish |
| Safe config | Doctor and docs help | Unknown attach opts can be ignored | Warn on unknown opts later |
| Observe normal behavior | Telemetry contract is strong | Unattended job telemetry thin | Claim/archive/escalation telemetry |
| Detect failures | CI and doctor strong | Archive/automation failures not alertable enough | Bounded telemetry events |
| Debug failures | Timeline/audit model strong | Failed batch ingestion was hidden | Return structured failures |
| Recover bad state | Claim service has retryable release | Executor missed release call | Call `mark_failed/3` |
| Scale/load | Queue paging and advisory bench | Archive durability under failure unknown | Failure-injection archive tests |
| Retries/timeouts | Oban uniqueness and claims | Failure claim lifecycle was incomplete | Retry tests |
| Data growth | Archiver/pruner exists | Archive truth model needs hardening | Manifest/staging archive design |
| Upgrade safely | Stability docs | API gate too shallow | Stable manifest |

## 6. UI/UX/Design-System Audit

The UI is useful enough to ship as an optional generated workbench, and v1.3 made the IA substantially more coherent. The top-level lanes are right: response, actions, history, detail, timeline, and action rail.

It is not yet polished enough to be considered frictionless inside arbitrary host apps.

Top UI fixes:

1. Remove hardcoded `/parapet` assumptions from generated navigation and redirects.
2. Add confirmation/pending states for high-impact incident and escalation actions.
3. Add live-region and focus behavior for preview/action outcomes.
4. Reduce inline style/script/CSP friction with a token contract and optional JS hook.
5. Add one browser behavior lane for scoped mount, keyboard flow, theme smoke, and action pending state.

## 7. Maintainer Friction Audit

| Step | Friction | Risk | Highest-leverage fix |
|---|---|---|---|
| Setup repo | Low | CONTRIBUTING is clear | Keep commands current |
| Run tests | Low | Suite is broad | Add focused failure lanes |
| Understand architecture | Medium | Many shipped milestones in PROJECT.md | Clean stale planning blocks |
| Small change | Low | Tests are readable | Keep narrow seams |
| Feature change | Medium | Stability tiers constrain changes | Manifest makes impact explicit |
| Debug user report | Medium | Good docs, but scattered reporter wiring | Centralize common support paths |
| Review PR | Medium | Large generated UI diffs are hard | Add behavior tests over string tests |
| Cut release | Medium | Docs mismatch review/auto-merge model | Align release docs |
| Support old versions | Medium | Migration docs matter | Keep upgrade guide tested |
| Dependencies | Low | Dependabot exists | Add `mix hex.audit` |

## 8. GSD Sanity Check

**Overkill right now:** full enterprise governance, localization, SBOM/license automation beyond basic audit, a heavy browser suite on every matrix cell, a new routing abstraction framework.

**Not optional:** durable evidence truth, generated route correctness, stable API enforcement, migration/schema consistency, docs that do not tell users to do something that silently does nothing.

**Accept rough edges:** generated UI can remain host-owned and inspectable; optional integrations can remain explicit; advisory performance lanes can stay out of default CI.

**Rough edges that damage trust:** silent attach/provider no-ops, silent webhook persistence failures, archive/delete ambiguity, broken scoped UI mounting, one-click high-impact actions without enough state feedback.

## 9. Top 10 Concrete Changes

| Rank | Area | Dimension | Why it matters | Impact | Effort | Risk reduction | Timing | Good looks like |
|---:|---|---|---|---|---|---|---|---|
| 1 | `Parapet.Automation.Executor` | Reliability | Failed execution must not leave live claims | High | Low | High | before showing to strangers | Failure calls `mark_failed/3`; retry test passes |
| 2 | `Parapet.Spine.AlertProcessor` | Reliability | Webhooks must not report false success | High | Medium | High | before showing to strangers | Batch returns structured failures |
| 3 | Archive flow | Durable evidence | Archive/delete truth must be provable | High | High | High | before broad adoption | Manifest/staging/failure tests |
| 4 | Generated UI routes | Host-app compatibility | Scoped authenticated mounting must work | High | Medium | High | before broad UI adoption | `/admin/parapet` proof passes |
| 5 | README first flow | Adoption | Users should copy current paved road | High | Low | Medium | before Hex release | Starter-pack flow is first |
| 6 | API manifest | Upgrade trust | Stable promises need CI enforcement | High | Medium | High | before more 1.x releases | Manifest drift fails CI |
| 7 | Migration timestamp type | DB hygiene | Generated DB must match schemas | Medium | Low | Medium | before Hex release | Generator test asserts timestamp type |
| 8 | Provider migration docs | Upgrade trust | Upgrade guide must not silently no-op | High | Low | High | before Hex release | Uses `config :parapet, providers:` |
| 9 | Supply-chain audit | CI/CD | Retired packages should fail CI | Medium | Low | Medium | soon | `mix hex.audit` runs in CI |
| 10 | UI action pending/confirm | Operator UX | Operators need safe action feedback | Medium | Medium | Medium | before broad adoption | High-impact actions have confirm/pending behavior |

