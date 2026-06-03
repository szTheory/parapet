# Phase 20: Governance & Docs Completeness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 20-governance-docs-completeness
**Areas discussed:** SECURITY.md disclosure channel, Version support matrix scope, HexDocs extras classification

---

## SECURITY.md Disclosure Channel

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub Private Vulnerability Reporting | Enable in repo Settings; ship `github.com/szTheory/parapet/security/advisories/new` URL; one-click CVE via GitHub CNA; no email needed | ✓ |
| security@ contact email | Traditional email contact; requires maintaining a mailbox; no CVE workflow | |

**User's choice:** GitHub Private Vulnerability Reporting
**Notes:** Advisor research confirmed this is the clear fit for a single-maintainer OSS Hex library with no existing security@ email. No follow-up questions needed.

---

## Version Support Matrix Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Floor + range (Elixir 1.19+, OTP 26–28, PG 14+) | Matches Elixir's published compatibility table for 1.19; PG 14 aligns with Oban's floor; parenthetical notes CI runs 1.19/OTP 27/PG 14 | ✓ |
| CI-exact (Elixir 1.19, OTP 27, PG 14 only) | Strictly CI-verified; narrower claim; may look artificially restricted | |

**User's choice:** Floor + range (Elixir 1.19+, OTP 26–28, PG 14+)
**Notes:** Elixir 1.19 officially supports OTP 26–28 per Elixir's own compatibility matrix. Stating only OTP 27 would be misleading, not conservative.

---

## HexDocs Extras Classification

| Option | Description | Selected |
|--------|-------------|----------|
| stability.md + telemetry.md → Reference group | Enumeration-style normative content; aligns with Phoenix/LiveView/Nx; slo-reference.md also in Reference | ✓ |
| stability.md + telemetry.md → Guides group | Single regex covers everything; simpler but blurs procedural vs. normative content | |

**User's choice:** Reference group
**Notes:** Proposed full grouping: Getting Started (README + getting-started) / Guides (adopter-flows, operator-ui, slo-authoring-guide, troubleshooting, HISTORY, CHANGELOG) / Integration Guides (all 8) / Reference (stability, telemetry, slo-reference).

---

## Claude's Discretion

- Exact wording of SECURITY.md responsible disclosure template
- Exact wording of README 1.0 semver commitment paragraph
- Per-integration guide content (derived from module docstrings)
- Whether HISTORY.md and CHANGELOG.md appear in Guides or listed separately

## Deferred Ideas

None — discussion stayed within phase scope.
