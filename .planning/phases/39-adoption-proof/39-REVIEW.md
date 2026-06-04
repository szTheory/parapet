---
phase: 39-adoption-proof
reviewed: 2026-06-04T21:38:39Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - README.md
  - docs/operator-ui.md
  - docs/troubleshooting.md
  - test/parapet/adoption_docs_test.exs
findings:
  critical: 0
  warning: 5
  info: 0
  total: 5
status: issues_found
---

# Phase 39: Code Review Report

**Reviewed:** 2026-06-04T21:38:39Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the adoption-facing README, Operator UI guide, troubleshooting guide, and adoption docs test. No Critical/BLOCKER security or data-loss issues were found, but the submitted docs contain broken source links and one misleading generator contract. The test coverage also depends on mutable planning state, which makes the docs proof brittle.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Troubleshooting guide uses broken relative links

**Classification:** WARNING
**File:** `docs/troubleshooting.md:3`
**Issue:** The troubleshooting guide links to `[Parapet Getting Started](docs/getting-started.md)` while already living in `docs/`, so the rendered GitHub/source path resolves to `docs/docs/getting-started.md`. The same defect appears at line 5 for `[Parapet Operator UI Guide](docs/operator-ui.md)`, which resolves to `docs/docs/operator-ui.md`. Both targets are broken for adopters browsing the source docs.
**Fix:** Use doc-local relative links:

```markdown
This guide answers common obstacles you may hit after following [Parapet Getting Started](getting-started.md).

For UI-specific doctor checks, see [Parapet Operator UI Guide](operator-ui.md).
```

### WR-02: Recovery Actions link points at a non-existent source file

**Classification:** WARNING
**File:** `docs/operator-ui.md:254`
**Issue:** The guide links to `recovery-actions.html`, but the repository source file is `docs/recovery-actions.md`. In the source docs and GitHub view this points to a missing file, so adopters cannot follow the guide from the Operator UI doc.
**Fix:** Link to the markdown source, or use an absolute HexDocs URL if the intended target is generated documentation:

```markdown
See the [Recovery Actions Guide](recovery-actions.md) for step-by-step authoring instructions.
```

### WR-03: README misstates the Prometheus generator output

**Classification:** WARNING
**File:** `README.md:162`
**Issue:** The README says `mix parapet.gen.prometheus` generates "a `.yml` file", but the actual task writes three files under `priv/parapet/prometheus/`: `recording_rules.yml`, `alerts.yml`, and `rules.yml`. The troubleshooting guide and other docs describe the three-file contract, so the README sends new adopters down the wrong deployment path.
**Fix:** Replace the singular-file sentence with the actual contract:

```markdown
This writes `recording_rules.yml`, `alerts.yml`, and the compatibility aggregate
`rules.yml` under `priv/parapet/prometheus/`.
```

### WR-04: Adoption docs test depends on planning artifacts

**Classification:** WARNING
**File:** `test/parapet/adoption_docs_test.exs:7`
**Issue:** The test reads `.planning/QUALITY-EVALUATION.md` and asserts milestone closeout phrases at lines 120-138. `.planning` artifacts are workflow state, not adoption docs, and they are excluded from review/source scopes elsewhere in this workflow. Cleanup, archival, packaging, or routine planning edits can fail the adoption docs test even when README/docs content is still correct.
**Fix:** Move the closeout claim into a stable reviewed doc if it is part of the product adoption surface, or remove this assertion from the docs test:

```elixir
# Prefer stable docs only:
@readme Path.expand("../../README.md", __DIR__)
@operator_ui Path.expand("../../docs/operator-ui.md", __DIR__)
@troubleshooting Path.expand("../../docs/troubleshooting.md", __DIR__)
```

### WR-05: Adoption docs tests do not cover the broken links they are meant to guard

**Classification:** WARNING
**File:** `test/parapet/adoption_docs_test.exs:94`
**Issue:** The scoped mounting test checks for broad phrases across `operator-ui.md` and `troubleshooting.md`, but it never validates markdown link targets. As a result, the broken links in `docs/troubleshooting.md` and `docs/operator-ui.md` pass this proof lane. This is a test reliability gap for the stated adoption/docs/proof phase.
**Fix:** Add a small markdown-link assertion for local links in the reviewed docs, resolving relative paths from each document directory and rejecting missing targets:

```elixir
for path <- [@readme, @operator_ui, @troubleshooting],
    {_label, target} <- local_markdown_links(File.read!(path)),
    not String.starts_with?(target, "#") do
  resolved = Path.expand(target, Path.dirname(path))
  assert File.exists?(resolved), "#{path} links to missing target #{target}"
end
```

---

_Reviewed: 2026-06-04T21:38:39Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
