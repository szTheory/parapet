# Phase 15: Packaging Credibility Gate - Context

**Gathered:** 2026-05-23 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Parapet *read* as a credible, maintained Hex package to a stranger evaluating it — by
populating hex.pm package metadata and establishing a Release-Please-owned `CHANGELOG.md`.
This is the low-cost credibility gate that unblocks all downstream adoption work (Phases 16–18).

**In scope:** `mix.exs` package metadata (links/description/source_url/docs block), a root
`CHANGELOG.md` stub owned by Release Please, retroactive v0.1–v0.9 milestone history as a
shipped doc, `files:` whitelist update, and a Release Please version-strategy fix so the first
release publishes as a deliberate `0.10.0` (not an accidental `1.0.0`).

**Out of scope:** Running `mix hex.publish` (no automation exists; manual, later). New runtime
deps, Ecto schemas, or Oban queues (whole-milestone constraint). Any SLO/runbook/docs content
(Phases 16–18).
</domain>

<decisions>
## Implementation Decisions

### hex.pm Package Metadata (ADOPT-01)
- **D-01:** Add a `@source_url "https://github.com/szTheory/parapet"` module attribute to `mix.exs`
  and reference it everywhere a GitHub URL is needed (mirrors the convention in `deps/ecto/mix.exs`
  and `deps/req/mix.exs`).
- **D-02:** Add a top-level `:description` (one sentence). Default copy to use unless planning
  refines it: *"An opinionated SRE reliability layer for Phoenix/Elixir SaaS — turn existing
  telemetry into user-journey SLOs, deploy correlation, incident evidence, and operator-grade
  runbooks."*
- **D-03:** Add a top-level `source_url: @source_url`.
- **D-04:** Populate `links:` with the three keys the success criterion names — **GitHub**
  (`@source_url`), **HexDocs** (`https://hexdocs.pm/parapet`), **Issues** (`#{@source_url}/issues`)
  — plus a **Changelog** link. The Changelog link resolves on HexDocs only if the changelog is an
  ex_doc extra (see D-05); if the `docs:` extras block is not added, point Changelog at the GitHub
  blob (`#{@source_url}/blob/main/CHANGELOG.md`) instead so it never 404s.
- **D-05:** Add a `docs:` block to `mix.exs` with `source_url: @source_url`,
  `source_ref: "v#{@version}"`, and `extras:` including `CHANGELOG.md`, `README.md`, and the
  existing `docs/*.md` files — so HexDocs renders the changelog and guides. (Matches the reference
  deps' pattern; cheap and makes the HexDocs Changelog link valid.)

### CHANGELOG Ownership & Retroactive History (ADOPT-02)
- **D-06:** Release Please **owns** the `CHANGELOG.md` body. Already proven: the
  `origin/release-please--branches--main` PR branch contains a fully generated `CHANGELOG.md`.
  Humans commit at most a **header-only stub** to `main` — `# Changelog` plus the standard
  release-please preamble comment — never any hand-written `## <version>` sections.
- **D-07:** Retroactive **v0.1–v0.9 history lives OUTSIDE the changelog body** in a shipped
  `docs/HISTORY.md`, sourced from `.planning/MILESTONES.md`. Frame it as **milestone history**,
  not hex-version history (milestone names ≠ hex versions — package was at `0.1.0`). The
  header-only `CHANGELOG.md` stub links to `docs/HISTORY.md` (e.g., "Releases before 1.0 —
  see the milestone history in HISTORY.md") so the changelog "covers" v0.1–v0.9 without the
  body ever conflicting with Release Please generation.
- **D-08:** Add `CHANGELOG*` to the Hex `files:` whitelist (`mix.exs:12`, currently
  `~w(lib priv .formatter.exs mix.exs README* docs)`). `docs/` is already whitelisted, so
  `docs/HISTORY.md` ships with no further whitelist change.

### Version Strategy (locks first published version)
- **D-09:** **Pin pre-1.0 bumping.** Add a `release-please-config.json` with
  `bump-minor-pre-major: true` and `bump-patch-for-minor-pre-major: true`, and seed a
  `.release-please-manifest.json` so the **first release publishes as `0.10.0`** (aligned to the
  current milestone), keeping `v1.0` reserved for the deferred API/telemetry freeze.
  - **Why:** Commit `8268889` carries a `BREAKING CHANGE:` footer (an early telemetry-docs stub),
    which makes Release Please compute a **major bump to `1.0.0`** (seen on the stale release PR,
    dated 2026-05-12). That directly contradicts `MILESTONE-ARC.md`, which reserves v1.0 for the
    API freeze. Pinning pre-1.0 behavior neutralizes the accidental footer without rewriting history.
  - **Planning note:** Confirm the exact manifest seed value during planning so the computed next
    version lands on `0.10.0` (pre-1.0, a breaking change bumps the minor; feat bumps the patch).
    Wire `--config-file` / `--manifest-file` into `.github/workflows/release-please.yml` if the
    defaults don't pick them up. Update the `version:` in `mix.exs` to align.

### Publish Scope
- **D-10:** Phase 15 prepares repo state only — it does **not** run `mix hex.publish`. No publish
  automation exists; publishing is a manual step taken later (realistically after the Phase 18 docs
  land). Do not merge the Release Please release PR as part of this phase.

### Claude's Discretion
- Exact wording of the `:description` (D-02) and the HISTORY.md narrative tone — refine during
  planning/execution; the proposed sentence is a sane default.
- Whether the Changelog link points at HexDocs (`changelog.html`) or the GitHub blob — driven by
  whether the `docs:` extras block (D-05) is added; default to HexDocs since D-05 adds it.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `mix.exs` — the file to modify (package block at lines 11-15; `verify.public_api` alias at line 54; no `docs:` block today)
- `.github/workflows/release-please.yml` — current Release Please config (`release-type: elixir`, no config/manifest args)
- `.planning/MILESTONES.md` — source material for the retroactive v0.1–v0.9 `docs/HISTORY.md`
- `.planning/MILESTONE-ARC.md` — rationale that v1.0 = API/telemetry freeze (deferred); drives the version-strategy decision
- `origin/release-please--branches--main` (git ref) — the existing Release-Please-owned `CHANGELOG.md` and `version: "1.0.0"` bump; proves current generation behavior
- `deps/ecto/mix.exs`, `deps/req/mix.exs` — canonical Elixir/Hex `@source_url` / `links` / `docs` / `extras` patterns to mirror
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Release Please is already wired and proven** — `.github/workflows/release-please.yml` runs
  on push to `main`; the `origin/release-please--branches--main` branch shows it already generates
  a complete root `CHANGELOG.md` grouped under `### Features`. The phase tunes it, not bootstraps it.
- **`docs/` already ships** via the `files:` whitelist (holds `adopter-flows.md`, `operator-ui.md`,
  `slo-reference.md`, `telemetry.md`) — `docs/HISTORY.md` ships for free.
- **`.planning/MILESTONES.md`** has dated, per-milestone accomplishment lists for v0.1–v0.9 — the
  ready-made source for retroactive history.
- **Reference dep mix.exs files** (`deps/ecto`, `deps/req`) provide the exact metadata idiom to copy.

### Established Patterns
- Conventional Commits + Release Please is the OSS release discipline (PROJECT.md constraint:
  "stable CI job ids, `mix verify.*` proof surfaces, `files:` whitelist on Hex publish").
- `verify.public_api` alias = `docs --warnings-as-errors` (`mix.exs:54`) — adding a `docs:` block
  with `extras:` must keep this green (broken/undefined doc references will fail CI).

### Integration Points
- `mix.exs` `package:` and (new) `docs:` blocks — the metadata surface.
- `.github/workflows/release-please.yml` — may need `--config-file` / `--manifest-file` args once
  `release-please-config.json` + `.release-please-manifest.json` are added.
- `CHANGELOG.md` (root, new) ↔ `docs/HISTORY.md` (new) ↔ README cross-links.

### Watch-outs
- **Accidental `1.0.0`:** the `BREAKING CHANGE:` footer in commit `8268889` is what drives the
  major bump — the version-strategy config (D-09) exists to neutralize it. Verify the computed
  next version is `0.10.0` before any release PR is merged.
- Git tags `v0.1`, `v0.2`, `v0.4`, `v0.9` exist but are **GSD planning milestone tags**, not
  semver release tags — they are not valid semver and Release Please ignores them. Don't treat
  them as prior hex releases.
- No release has ever been published to hex (no semver tags, no publish automation) — ADOPT-01's
  "stranger on hex.pm" is the *target* state this phase prepares, not a live page yet.
</code_context>

<specifics>
## Specific Ideas

- Mirror `deps/ecto/mix.exs` / `deps/req/mix.exs` metadata structure exactly (`@source_url`
  attribute, top-level `description`/`source_url`, `package.links`, `docs.source_ref`/`extras`).
- Proposed `:description` sentence (D-02) — adopter-confirmed as the default to use.
- First published version locked to `0.10.0` to match the milestone numbering.
</specifics>

<deferred>
## Deferred Ideas

- **Actual `mix hex.publish`** — out of this phase (no automation; manual, post-Phase-18).
- **Reconciling/removing the GSD planning tags** (`v0.1`…`v0.9`) vs future semver release tags —
  not required for credibility; revisit only if it confuses release tooling.
- **Hosted CHANGELOG / release subscription** — explicitly out of scope per REQUIREMENTS.md.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 15.
</deferred>
