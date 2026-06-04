# Phase 39: Adoption Proof - Research

**Researched:** 2026-06-04
**Domain:** Elixir/Phoenix documentation, generated UI adoption guidance, archive maintenance supportability
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Archive Maintenance Guidance
- **D-01:** Document the existing archive/export/prune behavior, not new archive runtime semantics.
- **D-02:** README and docs should cover `mix parapet.archive`, the default `priv/parapet/archive.jsonl` path, `--days`, `--path`, JSONL artifact plus manifest, structured success JSON, and failure messages with `stage`, `run_id`, counts, and paths.
- **D-03:** Keep the archive boundary explicit: Parapet archive maintenance is operational evidence export/prune for Parapet-owned records, not host backup/restore, object-store retention, or external provider data preservation.
- **D-04:** Document the resolved-retention limitation inherited from Phase 37: current retention means resolved incidents created before cutoff via `inserted_at < cutoff`, not incidents resolved before cutoff via a `resolved_at` field.

### Scoped Operator UI Mounting Guidance
- **D-05:** Deepen README and adoption-facing docs around default `/parapet` and scoped `/ops/parapet` Phoenix router examples.
- **D-06:** Preserve the Phase 38 model in all copy: generated Operator UI routes are host-owned, host apps own authentication and authorization, and scoped support does not require a generator flag, Parapet router abstraction, stable public API change, or dependency change.
- **D-07:** Explain that generated local links derive from the generated `operator_base_path` helper, so the same generated host-owned files can work at `/parapet` or nested mounts such as `/ops/parapet`.

### Troubleshooting Coverage
- **D-08:** Expand `docs/troubleshooting.md` and cross-link from README/operator UI docs for likely first archive failures: write, manifest, publish, delete-stage failures, missing `:parapet, :repo`, invalid retention/path usage, and safe rerun expectations after a failed archive.
- **D-09:** Add scoped UI mounting troubleshooting for stale generated UI files after route-scope support, scoped mounts that omit authenticated pipeline/live session protection, and broken local links caused by mounting only some Operator UI routes under a nested scope.
- **D-10:** Prefer a short gotchas block in `docs/operator-ui.md` plus fuller recovery steps in `docs/troubleshooting.md`, unless planning finds a cleaner existing docs location.

### Quality Risk Closeout
- **D-11:** Add a dated closeout addendum or explicit cross-reference to `.planning/QUALITY-EVALUATION.md` rather than rewriting the original audit narrative.
- **D-12:** The closeout should connect the original top risks to completed evidence: archive durability closed by Phase 37, scoped route compatibility closed by Phase 38, and adoption/supportability docs closed by Phase 39.
- **D-13:** If planning prefers a milestone close artifact instead of editing `.planning/QUALITY-EVALUATION.md`, it must link back to the quality evaluation and make future milestone planning able to distinguish closed risks from still-open risks.

### the agent's Discretion
- Exact README section placement, provided the first-contact path remains concise and points to fuller docs.
- Exact troubleshooting headings and example output snippets, provided they name real archive failure fields and real scoped UI mount paths.
- Whether quality closeout is a new section in `.planning/QUALITY-EVALUATION.md` or a milestone close artifact cross-linked from it.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Rich archive export formats beyond the current Parapet-owned evidence model remain future work.
- `resolved_at` retention semantics remain deferred to a later schema/migration phase if the product wants them.
- DB-backed archive run tables, object-store archive sinks, and archive status UI remain future explicit phases.
- Multi-tenant/operator-per-org UI semantics remain out of scope.
- Parapet-owned router modules, global route-helper replacement, auth policy changes, and generator route flags remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | README and docs explain archive maintenance in practical production terms: when to run it, what it preserves, what failure looks like, and how to recover. | Use `mix parapet.archive`, `Parapet.Evidence.Archiver.Summary`, `Parapet.Evidence.Archiver.Failure`, and Phase 37 verification as the factual base. [VERIFIED: codebase grep] |
| ADOPT-02 | README and generated UI docs explain default and scoped Operator UI mounting with copy-pasteable Phoenix router examples and known gotchas. | Reuse existing default `/parapet` and scoped `/ops/parapet` router examples, generated `operator_base_path` guidance, and Phase 38 route guards. [VERIFIED: codebase grep] |
| ADOPT-03 | The quality-evaluation artifact is updated or cross-referenced at milestone close so future milestone planning can see which top risks were actually closed. | Add a dated closeout trail linking Phase 37 archive durability, Phase 38 scoped routes, and Phase 39 adoption docs without rewriting the original audit. [VERIFIED: .planning/QUALITY-EVALUATION.md] |
</phase_requirements>

## Summary

Phase 39 should be planned as a documentation/proof phase, not a runtime implementation phase. The archive runtime already exposes the adoption facts docs need: `mix parapet.archive`, default path `priv/parapet/archive.jsonl`, `--days`, `--path`, JSONL plus sidecar manifest, structured success JSON, and structured failure context with stage/run/path/count fields. [VERIFIED: codebase grep] The scoped UI route work also already exists: generated router guidance and `docs/operator-ui.md` show default `/parapet` and scoped `/ops/parapet` mounts, and generated links derive from `operator_base_path`. [VERIFIED: codebase grep]

The planner should focus on making those existing truths discoverable to strangers: concise README entry points, fuller operator/troubleshooting docs, and a dated quality closeout trail. [VERIFIED: 39-CONTEXT.md] Avoid runtime code changes unless an existing docs guard needs a tiny assertion update after wording changes. [VERIFIED: 39-CONTEXT.md]

**Primary recommendation:** Plan three narrow documentation tasks: archive maintenance adoption copy, scoped UI mounting gotchas/cross-links, and quality-risk closeout with focused docs tests only where existing guards already cover the touched surfaces. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Use a recommendation-first, codebase-first planning and execution posture. [VERIFIED: AGENTS.md]
- Treat `workflow.discuss_mode = "assumptions"` as the repo default interactive posture. [VERIFIED: AGENTS.md]
- Auto-decide low-impact implementation details and state assumptions in artifacts instead of asking routine questions. [VERIFIED: AGENTS.md]
- Escalate only for public CLI/API, default install contents, auth ownership, dependency/support surface, runtime behavior, safety guarantees, operator semantics, durable evidence truth model, irreversible schema/maintenance burden, or two medium-impact concerns moving at once. [VERIFIED: AGENTS.md]
- Do not widen product scope, milestone status claims, or runtime guarantees from AGENTS.md alone. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Archive maintenance docs | Documentation / Maintainer docs | Mix task surface | The implementation already lives in `Parapet.Evidence.Archiver` and `mix parapet.archive`; Phase 39 explains existing behavior. [VERIFIED: codebase grep] |
| Scoped Operator UI mounting docs | Documentation / Generated host code | Phoenix router / LiveView | Generated files and host router scopes own route behavior; docs must describe host-owned mounting, not create Parapet-owned router code. [VERIFIED: codebase grep] [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html] |
| Troubleshooting first errors | Documentation / Support guide | CLI and generated UI tests | `docs/troubleshooting.md` already uses a Q&A support style and should absorb first-failure recovery notes. [VERIFIED: codebase grep] |
| Quality risk closeout | Planning artifact | Phase summaries | `.planning/QUALITY-EVALUATION.md` is the original risk source; Phase summaries provide completed evidence. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Markdown docs in README/docs | Repo-local | Adoption and troubleshooting guidance | README, ExDoc extras, and docs guides are already shipped and grouped by `mix.exs`. [VERIFIED: codebase grep] |
| ExUnit docs/proof guards | Elixir 1.19.5 / Mix 1.19.5 local | Pin documentation-sensitive route/archive claims where useful | Existing tests already assert operator UI docs and generated route guidance. [VERIFIED: codebase grep] |
| Phoenix Router examples | Phoenix docs current page shows v1.8.7 | Copy-paste router scope examples for host apps | Phoenix Router scopes and `pipe_through` are the native way to route through pipelines. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html] |
| Phoenix LiveView navigation model | LiveView docs current page shows v1.1.31 | Explain why all route emitters must use generated scoped paths | LiveView documents client `patch`/`navigate` and server `push_patch`/`push_navigate` as the relevant navigation surfaces. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `Mix.Tasks.Parapet.Archive` | Repo-local | Copy-paste archive CLI entry point | Use in README and troubleshooting examples. [VERIFIED: codebase grep] |
| `.planning/QUALITY-EVALUATION.md` | 2026-06-04 artifact | Risk closeout ledger | Add dated addendum or cross-reference for ADOPT-03. [VERIFIED: codebase grep] |
| `mix format --check-formatted` / `mix test` | Mix 1.19.5 local | Verification | Use after docs/test edits. [VERIFIED: local command] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Updating `.planning/QUALITY-EVALUATION.md` | New milestone close artifact cross-linked from it | Context allows either; direct addendum is simpler and preserves the audit snapshot if appended rather than rewritten. [VERIFIED: 39-CONTEXT.md] |
| Adding docs tests for every README sentence | Manual docs review only | Existing project pattern uses focused string guards for sensitive docs; over-testing prose causes brittle churn. [VERIFIED: codebase grep] |

**Installation:** No external packages should be installed for this phase. [VERIFIED: 39-CONTEXT.md]

## Package Legitimacy Audit

No external packages are recommended or required. Package legitimacy gate is not applicable because Phase 39 should not add dependencies. [VERIFIED: 39-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| None | — | — | — | — | — | Approved: no install surface |

**Packages removed due to slopcheck [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```text
Stranger/adopter reads README
  -> Archive maintenance quick path
     -> docs/troubleshooting.md recovery detail
     -> existing mix parapet.archive CLI
        -> Summary JSON or Failure message fields

Stranger/adopter reads Operator UI guide
  -> Default /parapet or scoped /ops/parapet router snippet
     -> host-owned Phoenix scope + live_session auth
     -> generated LiveViews derive local links via operator_base_path
     -> troubleshooting covers stale generated files / partial mounts / missing auth

Maintainer reviews milestone risks
  -> .planning/QUALITY-EVALUATION.md addendum or linked close artifact
     -> Phase 37 archive proof
     -> Phase 38 scoped-route proof
     -> Phase 39 adoption docs proof
```

### Recommended Project Structure

```text
README.md                         # first-contact archive and scoped UI pointers
docs/operator-ui.md               # canonical generated UI mounting guide and gotchas
docs/troubleshooting.md           # fuller first-error recovery paths
.planning/QUALITY-EVALUATION.md   # dated risk closeout addendum or cross-link
test/parapet/*_test.exs           # focused docs guards only if existing assertions need coverage
```

### Pattern 1: README stays concise and links deeper

**What:** Add copy-pasteable archive and scoped UI examples without turning README into an operations manual. [VERIFIED: 39-CONTEXT.md]

**When to use:** Use README for commands, defaults, and links; use docs pages for edge cases and troubleshooting. [VERIFIED: 39-CONTEXT.md]

**Example:**

````markdown
Run archive maintenance with the default 90-day retention:

```bash
mix parapet.archive
mix parapet.archive --days 30
mix parapet.archive --path priv/parapet/archive.jsonl
```

See docs/troubleshooting.md for failure stages and safe reruns.
````

### Pattern 2: Host-owned scoped UI guidance

**What:** Keep router examples as host `scope` / `pipe_through` / `live_session` snippets and explain generated `operator_base_path`. [VERIFIED: codebase grep] [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html]

**When to use:** Use this for both README summary and `docs/operator-ui.md`; do not add generator flags or Parapet router modules. [VERIFIED: 39-CONTEXT.md]

**Example:**

```elixir
scope "/ops", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do
    live "/parapet", MyAppWeb.Parapet.OperatorLive, :index
    live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions
    live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history
    live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
    live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
  end
end
```

Source: `docs/operator-ui.md` and `priv/templates/parapet.gen.ui/router_snippet.ex.eex`. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Runtime edits in docs phase:** Phase 39 exists to explain Phase 37 and 38 behavior; runtime semantics are locked. [VERIFIED: 39-CONTEXT.md]
- **Implying Parapet owns backup/restore:** Archive maintenance is Parapet-owned evidence export/prune, not host backup, object storage, or provider data retention. [VERIFIED: codebase grep]
- **Implying Parapet owns UI auth:** LiveView docs require authentication/authorization checks for LiveViews, and Parapet docs already say host apps own auth. [CITED: https://hexdocs.pm/phoenix_live_view/0.19.3/Phoenix.LiveView.Router.html] [VERIFIED: codebase grep]
- **Testing prose too broadly:** Existing tests pin sensitive route guidance; planner should add focused docs assertions only for claims that protect requirements. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Archive scheduling/runtime semantics | New archiver behavior, DB run table, object-store sink, restore workflow | Existing `mix parapet.archive` and `Parapet.Evidence.Archiver` docs | Phase boundary forbids runtime expansion and Phase 37 already closed archive durability. [VERIFIED: 39-CONTEXT.md] |
| Scoped UI routing | Parapet router abstraction, generator flag, stable route API | Existing generated host-owned router snippets and `operator_base_path` helper | Phase 38 closed scoped mounting without dependency/API/auth expansion. [VERIFIED: codebase grep] |
| Auth guidance | Custom Parapet auth policy | Host app pipeline and LiveView `on_mount` examples | Phoenix LiveView docs require LiveView auth/authorization; Parapet does not own host auth. [CITED: https://hexdocs.pm/phoenix_live_view/0.19.3/Phoenix.LiveView.Router.html] |
| Quality truth model | Rewrite original audit conclusions | Dated addendum or linked closeout artifact | The planner needs closed-vs-open risk traceability without erasing the original diagnosis. [VERIFIED: 39-CONTEXT.md] |

**Key insight:** The adoption risk is no longer missing runtime capability; it is that strangers cannot yet see the already-built archive and route guarantees quickly enough. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Archive docs accidentally promise backup/restore

**What goes wrong:** Docs suggest the JSONL archive preserves all production data or external provider records. [VERIFIED: 39-CONTEXT.md]
**Why it happens:** The command name sounds like backup infrastructure. [ASSUMED]
**How to avoid:** State the archive preserves Parapet-owned incident evidence bundles only and host backups remain host-owned. [VERIFIED: codebase grep]
**Warning signs:** Wording mentions restore, object stores, Prometheus/Grafana state, or external provider preservation as Parapet responsibilities. [VERIFIED: 39-CONTEXT.md]

### Pitfall 2: Retention copy implies `resolved_at`

**What goes wrong:** Docs say "resolved more than N days ago" even though the implementation uses resolved incidents where `inserted_at < cutoff`. [VERIFIED: codebase grep]
**Why it happens:** Humans naturally think retention starts at resolution time. [ASSUMED]
**How to avoid:** Use the exact limitation: "resolved incidents created before the cutoff." [VERIFIED: codebase grep]
**Warning signs:** Any mention of `resolved_at` as an implemented field. [VERIFIED: 39-CONTEXT.md]

### Pitfall 3: Scoped UI docs show only some routes under `/ops`

**What goes wrong:** Local links break when the host mounts only part of the generated route map under a nested scope. [VERIFIED: 39-CONTEXT.md]
**Why it happens:** Generated UI navigation expects all local Operator UI routes to share the same base path. [VERIFIED: codebase grep]
**How to avoid:** Copy the complete route map for default and scoped examples. [VERIFIED: codebase grep]
**Warning signs:** `/ops/parapet` index exists but actions/history/detail routes remain outside that scope. [VERIFIED: 39-CONTEXT.md]

### Pitfall 4: Stale generated UI files after Phase 38

**What goes wrong:** An adopter generated UI before scoped route support and still has literal route emitters. [VERIFIED: 39-CONTEXT.md]
**Why it happens:** Generated files are host-owned after generation and do not auto-update. [VERIFIED: codebase grep]
**How to avoid:** Troubleshooting should tell users to regenerate or manually port `operator_base_path` helpers into existing generated files. [VERIFIED: 39-CONTEXT.md]
**Warning signs:** Source contains direct local `href="/parapet"` / `push_navigate(to: "/parapet...")` emitters in generated host files. [VERIFIED: codebase grep]

### Pitfall 5: Quality closeout overclaims

**What goes wrong:** Closeout says all quality issues are fixed instead of the named v1.4 top risks. [VERIFIED: .planning/QUALITY-EVALUATION.md]
**Why it happens:** The quality evaluation contains many ranked issues, not only v1.4 scope. [VERIFIED: codebase grep]
**How to avoid:** Link exact closed risks to Phase 37, 38, and 39 evidence, and leave unrelated future items open. [VERIFIED: 39-CONTEXT.md]
**Warning signs:** Broad language such as "quality evaluation complete" without risk-by-risk evidence. [ASSUMED]

## Code Examples

### Archive success output shape to document

```json
{
  "status": "ok",
  "run_id": "archive-...",
  "path": "priv/parapet/archive.jsonl",
  "manifest_path": "priv/parapet/archive.jsonl.archive-....manifest.json",
  "retention_days": 90,
  "selected_count": 1,
  "archived_count": 1,
  "deleted_count": 1,
  "skipped_count": 0,
  "bytes_written": 1234,
  "checksum": "..."
}
```

Source: `lib/mix/tasks/parapet.archive.ex` and `test/mix/tasks/parapet.archive_test.exs`. [VERIFIED: codebase grep]

### Archive failure fields to document

```text
Archive failed stage=delete_records path=... run_id=... selected=1 archived=1 deleted=0 manifest_path=... reason=...
```

Source: `Mix.Tasks.Parapet.Archive.failure_message/1` and CLI failure test. [VERIFIED: codebase grep] `Mix.raise/1` is the standard Mix error surface for a formatted error with default exit status 1. [CITED: https://hexdocs.pm/mix/Mix.html]

### Scoped route snippet

Use the full scoped example from `docs/operator-ui.md` / `router_snippet.ex.eex`; do not invent a partial route map. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Archive path could be read as ambiguous append/delete behavior | Staged verified JSONL artifact plus manifest and structured summary/failure | Phase 37, completed 2026-06-04 | Docs can describe durable evidence export/prune without adding runtime behavior. [VERIFIED: 37-03-SUMMARY.md] |
| Generated UI assumed literal `/parapet` local links | Generated local links derive from `operator_base_path` and support `/ops/parapet` | Phase 38, completed 2026-06-04 | Docs can show both default and scoped mounts while preserving host ownership. [VERIFIED: 38-03-SUMMARY.md] |
| Quality evaluation listed top adoption risks as open | Phase 39 should add closeout evidence | Phase 39 planning | Future planning can distinguish closed v1.4 risks from deferred risks. [VERIFIED: 39-CONTEXT.md] |

**Deprecated/outdated:**
- Treating `/parapet` literals as valid generated route emitters under scoped mounts is outdated for Phase 38+ generated UI. [VERIFIED: codebase grep]
- Treating archive maintenance as a backup/restore system is out of scope for v1.4. [VERIFIED: 39-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The command name can lead users to assume backup semantics. | Common Pitfalls | Low; docs still explicitly prevent backup overclaim. |
| A2 | Humans naturally read retention as time since resolution. | Common Pitfalls | Medium; reinforces need for precise retention wording. |
| A3 | Broad closeout language is a likely maintainer pitfall. | Common Pitfalls | Low; planner can avoid it with exact evidence links. |

## Open Questions

1. **Quality closeout location**
   - What we know: CONTEXT permits either a `.planning/QUALITY-EVALUATION.md` addendum or a linked milestone close artifact. [VERIFIED: 39-CONTEXT.md]
   - What's unclear: Which location the planner will prefer for artifact hygiene. [VERIFIED: 39-CONTEXT.md]
   - Recommendation: Append a dated closeout section to `.planning/QUALITY-EVALUATION.md` because it is the original risk source and avoids forcing readers to chase a second artifact. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Docs tests / compile verification | yes | 1.19.5 on OTP 28 | None needed. [VERIFIED: local command] |
| Mix | Docs tests / archive task evidence | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| ripgrep | Research and possible static verification | yes | 15.1.0 | `grep` if needed. [VERIFIED: local command] |
| Context7 CLI | Library docs lookup | no | — | Official HexDocs via web search was used. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none. [VERIFIED: local command]

**Missing dependencies with fallback:** Context7 CLI missing; official HexDocs pages were used instead. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Mix 1.19.5 [VERIFIED: local command] |
| Config file | No dedicated test config file found during research; tests are standard `test/**/*_test.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix test` [VERIFIED: 37-03-SUMMARY.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ADOPT-01 | Archive docs name CLI commands, JSONL/manifest, success/failure fields, retention limitation, and safe rerun guidance. | docs guard / manual docs review | `mix test test/mix/tasks/parapet.archive_test.exs` plus any new focused docs assertion | Partial: archive CLI tests exist; docs guard may need Wave 0. [VERIFIED: codebase grep] |
| ADOPT-02 | README/operator UI docs show default and `/ops/parapet` route examples and host-owned auth/router gotchas. | docs guard | `mix test test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` | Existing. [VERIFIED: codebase grep] |
| ADOPT-03 | Quality evaluation or close artifact records closed top risks. | artifact review / optional text guard | Manual review; optional focused assertion only if planner adds one | Artifact exists; no current test guard. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the focused docs guard relevant to touched files. [VERIFIED: codebase grep]
- **Per wave merge:** `mix format --check-formatted && mix test test/mix/tasks/parapet.archive_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`. [VERIFIED: local command]
- **Phase gate:** `mix format --check-formatted && mix compile --warnings-as-errors && mix test`. [VERIFIED: 37-03-SUMMARY.md]

### Wave 0 Gaps

- [ ] Add a focused docs assertion for archive adoption copy if planner wants automated ADOPT-01 proof beyond manual review. Candidate file: `test/parapet/adoption_docs_test.exs`. [VERIFIED: codebase grep]
- [ ] Add a focused artifact assertion for ADOPT-03 only if the project wants planning-artifact tests; otherwise verify manually because `.planning` files are not product runtime. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes for UI docs | State host app owns auth and use protected Phoenix `scope`/`live_session` examples. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/0.19.3/Phoenix.LiveView.Router.html] |
| V3 Session Management | yes for UI docs | Keep LiveViews inside host-controlled browser pipeline/live session; do not define Parapet sessions. [VERIFIED: codebase grep] |
| V4 Access Control | yes for UI docs | Warn against mounting Operator UI routes outside authenticated/authorized host scopes. [VERIFIED: codebase grep] |
| V5 Input Validation | no runtime change | Existing docs phase should not add new input handling; CLI invalid retention remains existing `ArgumentError`. [VERIFIED: codebase grep] |
| V6 Cryptography | no runtime change | Archive checksum already uses SHA-256; Phase 39 only documents checksum field. [VERIFIED: codebase grep] |

### Known Threat Patterns for Phase 39

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs lead users to mount Operator UI without auth | Elevation of privilege | Keep auth warning and protected examples in README/operator UI/troubleshooting. [VERIFIED: codebase grep] |
| Docs imply archive equals backup | Information disclosure / Repudiation | Explicitly scope archive to Parapet-owned evidence export/prune and host-owned backups. [VERIFIED: 39-CONTEXT.md] |
| Failure guidance hides delete-stage distinction | Repudiation | Document stage-aware recovery and safe rerun expectations. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project planning posture and escalation boundaries. [VERIFIED: codebase grep]
- `.planning/phases/39-adoption-proof/39-CONTEXT.md` - locked decisions, discretion, deferred ideas. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - ADOPT-01 through ADOPT-03. [VERIFIED: codebase grep]
- `.planning/STATE.md` - current milestone and phase position. [VERIFIED: codebase grep]
- `.planning/QUALITY-EVALUATION.md` - original top risks and closeout target. [VERIFIED: codebase grep]
- `.planning/phases/37-archive-durability/37-03-SUMMARY.md` - archive proof completion. [VERIFIED: codebase grep]
- `.planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md` - scoped route proof completion. [VERIFIED: codebase grep]
- `lib/parapet/evidence/archiver.ex`, `lib/mix/tasks/parapet.archive.ex`, `lib/parapet/evidence/archive_worker.ex` - archive runtime facts. [VERIFIED: codebase grep]
- `docs/operator-ui.md`, `docs/troubleshooting.md`, `README.md`, `priv/templates/parapet.gen.ui/router_snippet.ex.eex` - adoption docs surfaces. [VERIFIED: codebase grep]
- `test/mix/tasks/parapet.archive_test.exs`, `test/parapet/operator_ui_integration_test.exs`, `test/parapet/operator_ui_compile_out_test.exs` - existing proof guards. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Phoenix Router docs - scopes and pipelines. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html]
- Phoenix LiveView navigation docs - `patch`, `navigate`, `push_patch`, `push_navigate`. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- Phoenix LiveView Router docs - LiveView auth/authorization and `on_mount` examples. [CITED: https://hexdocs.pm/phoenix_live_view/0.19.3/Phoenix.LiveView.Router.html]
- Mix docs - custom task conventions and `Mix.raise/1`. [CITED: https://hexdocs.pm/mix/Mix.Task.html] [CITED: https://hexdocs.pm/mix/Mix.html]

### Tertiary (LOW confidence)

- None used for recommendations.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new stack; all recommended surfaces are existing repo docs/tests and official HexDocs references. [VERIFIED: codebase grep]
- Architecture: HIGH - phase boundary and ownership model are locked by CONTEXT and prior phase summaries. [VERIFIED: 39-CONTEXT.md]
- Pitfalls: MEDIUM - most pitfalls are directly sourced from CONTEXT/code; user-misreading risks are tagged as assumptions. [VERIFIED: codebase grep]

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for repo-local docs planning; re-check HexDocs if Phoenix/LiveView examples become implementation-sensitive. [ASSUMED]
