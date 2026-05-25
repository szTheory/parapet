# Phase 20: Governance & Docs Completeness - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the repository's trust artifacts and documentation gaps so `~> 1.0` is
credible to a stranger: the OSS governance triad (`CONTRIBUTING.md`,
`SECURITY.md`, `CODE_OF_CONDUCT.md`), a README semver commitment + version
matrix, the four previously missing integration guides (Chimeway, Mailglass,
Rindle, Scoria), the Provider-as-bundle pattern documented in the SLO authoring
guide, and hexdocs navigation polished to four clear groups. Scope is **writing
and wiring** the missing artifacts — NOT adding new runtime features or new
integrations.

Covers requirements: GOV-01, GOV-02, GOV-03, GOV-04, GOV-05, DOCS-01,
DOCS-02, DOCS-03, DOCS-04, DOCS-05, DOCS-06.
</domain>

<decisions>
## Implementation Decisions

### SECURITY.md Disclosure Channel (GOV-02)
- **D-01:** Use **GitHub Private Vulnerability Reporting** (not a security@
  email). URL to ship in `SECURITY.md`:
  `https://github.com/szTheory/parapet/security/advisories/new`. Enable
  private reporting in repo Settings → Code security and analysis before
  merging. No email address needed — one-click CVE via GitHub CNA, integrates
  with GitHub Advisory DB, zero mailbox maintenance.

### Version Support Matrix (GOV-04)
- **D-02:** README matrix: **Elixir 1.19+, OTP 26–28, Postgres 14+**. Include
  a parenthetical noting that CI validates on Elixir 1.19 / OTP 27 / PG 14.
  Rationale: Elixir's own published compatibility table lists OTP 26–28 for
  1.19; PG 14 is the oldest non-EOL version and aligns with Oban's stated
  floor. Artificially claiming only OTP 27 would be misleading, not conservative.

### HexDocs Groups Structure (DOCS-06)
- **D-03:** Four `groups_for_extras` sections:
  - **Getting Started:** `README.md`, `docs/getting-started.md`
  - **Guides:** `docs/adopter-flows.md`, `docs/operator-ui.md`,
    `docs/slo-authoring-guide.md`, `docs/troubleshooting.md`,
    `docs/HISTORY.md`, `CHANGELOG.md`
  - **Integration Guides:** `docs/integrations/*.md` (all 8 guides — 4
    existing + 4 new)
  - **Reference:** `docs/stability.md`, `docs/telemetry.md`,
    `docs/slo-reference.md`
- **D-04:** Set `main: "getting-started"` in `mix.exs` docs config (replaces
  the current `main: "readme"` or default). Gets getting-started as the
  hexdocs landing page per DOCS-06.

### Governance Docs Content (GOV-01, GOV-02, GOV-03)
- **D-05:** `CODE_OF_CONDUCT.md` → Contributor Covenant v2.1 (de facto
  standard, no ambiguity).
- **D-06:** `CONTRIBUTING.md` scope: local proof commands (`mix test`,
  `mix credo`, `mix dialyzer`), Conventional Commits + `mix format`
  expectations, and the PR flow. No interactive setup wizard — library not
  app, dev setup is Elixir + Postgres.
- **D-07:** All three governance docs go in the repo root. Add them explicitly
  to `mix.exs` `files:` whitelist:
  `files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING*
  SECURITY* CODE_OF_CONDUCT* LICENSE* docs)`.

### Integration Guides (DOCS-01 through DOCS-04)
- **D-08:** All four new guides (Chimeway, Mailglass, Rindle, Scoria) follow
  the `docs/integrations/sigra.md` template shape exactly:
  prerequisites → what it unlocks → activation line → config keys →
  troubleshooting. Content sourced from the existing integration module
  docstrings and `Parapet.attach/1` conventions.
- **D-09:** File locations: `docs/integrations/chimeway.md`,
  `docs/integrations/mailglass.md`, `docs/integrations/rindle.md`,
  `docs/integrations/scoria.md`. Add all four to `mix.exs` `extras:`.

### Provider-as-Bundle Pattern (DOCS-05)
- **D-10:** Add a new section to `docs/slo-authoring-guide.md` (not a
  separate file) documenting the Provider-as-bundle pattern: a
  `Parapet.SLO.Provider` returning multiple slices is the bundle abstraction.
  Reference `Parapet.SLO.StarterPack.DeliverySaaS` as the concrete example.
  Cross-link from `docs/slo-reference.md`.

### Claude's Discretion
- Exact wording of the `SECURITY.md` disclosure template (standard
  community language around triage timelines and responsible disclosure).
- Exact wording of the README 1.0 semver commitment paragraph.
- Per-integration config keys and troubleshooting content — derive from the
  integration modules' docstrings and any relevant existing test/fixture data.
- Whether `docs/HISTORY.md` and `CHANGELOG.md` appear in Guides or are listed
  separately — default to including them in Guides for discoverability.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Governance & Structure
- `mix.exs` — `extras:`, `groups_for_extras:`, `files:` whitelist (~lines 42, 58–80); all three require updates for GOV-05 and DOCS-06.
- `docs/integrations/sigra.md` — the integration guide template shape (prerequisites → what it unlocks → activation → config keys → troubleshooting). Every new guide must match this structure.
- `.planning/REQUIREMENTS.md` — GOV-01…GOV-05, DOCS-01…DOCS-06 requirements with exact acceptance criteria.
- `.planning/research/V1-SUMMARY.md` — v1.0 milestone context, scope decisions, and what was deferred.

### Integration Modules (content source for guides)
- `lib/parapet/integrations/chimeway.ex` — source for DOCS-01 guide content.
- `lib/parapet/integrations/mailglass.ex` — source for DOCS-02 guide content.
- `lib/parapet/integrations/rindle.ex` — source for DOCS-03 guide content.
- `lib/parapet/integrations/scoria.ex` — source for DOCS-04 guide content.

### Docs to Update
- `docs/slo-authoring-guide.md` — add Provider-as-bundle section (DOCS-05).
- `docs/slo-reference.md` — add cross-link to Provider-as-bundle section.
- `README.md` — add 1.0 semver commitment + Elixir/OTP/Postgres matrix (GOV-04).

### Phase 19 Artifacts (cross-reference)
- `docs/stability.md` — created in Phase 19; integration guides may cross-link it.
- `docs/telemetry.md` — frozen telemetry contract; relevant for Scoria guide.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docs/integrations/sigra.md` — complete template for all 4 new integration guides; copy structure verbatim, substitute integration-specific content.
- `lib/parapet/integrations/*.ex` — integration modules contain docstrings and telemetry event lists that are the primary content source for the guides.
- `mix.exs` `extras:` and `groups_for_extras:` — extend in place; no new infrastructure needed.

### Established Patterns
- Governance docs at repo root (not under `docs/`). `files:` whitelist uses glob patterns (`CONTRIBUTING*`, `SECURITY*`, `CODE_OF_CONDUCT*`).
- Integration guide shape: sigra.md is the golden template — prerequisites, "What it unlocks" with bullet metrics, `Parapet.attach(adapters: [:name])` activation, config keys table, troubleshooting Q&A.
- `Parapet.SLO.StarterPack.DeliverySaaS` is the canonical Provider-as-bundle example (returns multiple slices including Chimeway + Mailglass slices).

### Integration Points
- `mix.exs` is the single place to wire: `extras:` (add 4 guides + governance docs?), `groups_for_extras:` (split into 4 groups), `files:` (add governance doc globs), `main:` (switch to `"getting-started"`).
- Getting-started guide already exists at `docs/getting-started.md` — no content change needed, just wire as hexdocs landing.
- `files:` whitelist currently: `~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs)`. Governance docs are at root — need explicit glob entries.
</code_context>

<specifics>
## Specific Ideas

- **GitHub PVR URL** — `https://github.com/szTheory/parapet/security/advisories/new` — this exact URL ships in `SECURITY.md`. Maintainer must enable private reporting in GitHub repo settings before merge.
- **Version matrix note** — parenthetical: "CI validates on Elixir 1.19 / OTP 27 / PG 14." Do not claim broader OTP range is CI-tested — be honest about the gap.
- **Reference group ordering** — in `groups_for_extras`, place Reference after Integration Guides so the nav reads: Getting Started → Guides → Integration Guides → Reference (matches increasing specificity).
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>

---

*Phase: 20-governance-docs-completeness*
*Context gathered: 2026-05-25*
