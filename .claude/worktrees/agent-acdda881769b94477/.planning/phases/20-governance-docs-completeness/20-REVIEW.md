---
phase: 20-governance-docs-completeness
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - CONTRIBUTING.md
  - README.md
  - SECURITY.md
  - docs/integrations/chimeway.md
  - docs/integrations/mailglass.md
  - docs/integrations/rindle.md
  - docs/integrations/scoria.md
  - docs/slo-authoring-guide.md
  - docs/slo-reference.md
  - mix.exs
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-05-25
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Ten documentation and configuration files were reviewed. One critical issue was found: the SECURITY.md supported-versions table claims `1.x` is the supported line, but the library is currently at `0.10.0` — a pre-1.0 release. This directly misleads security reporters and adopters checking support status.

Five warnings cover: a wrong version pin in the README install snippet, planning-phase terminology leaking into public docs, an incomplete tag list in the Mailglass integration guide, a missing troubleshooting section in the Rindle guide, and a security risk in the `String.to_atom/1` normalization behavior that is documented but not flagged as a concern.

Three info items cover: a nonexistent file glob in `mix.exs` package configuration, the `Parapet.SLO.define/2` legacy API being presented as the primary example in `README.md`, and the SLO Authoring Guide being absent from the README "Learn The Flows" section.

---

## Critical Issues

### CR-01: SECURITY.md supported-versions table is wrong for the current release

**File:** `SECURITY.md:24-25`
**Issue:** The supported-versions table lists `1.x (latest)` as supported and `< 1.0` as unsupported. The actual published version is `0.10.0` (confirmed in `mix.exs:5`). README.md explicitly states "Pre-1.0 minor releases may include breaking changes." An adopter at `0.10.0` who consults the SECURITY policy to determine whether their version receives security fixes is told their version is unsupported, even though `0.10.0` is the latest release. A security researcher deciding whether a vulnerability is in-scope would also receive incorrect guidance.

**Fix:** Update the table to reflect the current pre-1.0 release line, and add a note clarifying that `0.x` is the active release series until `1.0` ships:

```markdown
## Supported Versions

The latest released version is the supported line. Security fixes are applied to the current release only.

| Version | Supported |
|---------|-----------|
| 0.x (latest) | Yes |
| older 0.x    | No  |

Once `1.0` ships, only the latest released minor will receive security fixes.
```

---

## Warnings

### WR-01: README.md install snippet pins wrong version

**File:** `README.md:42`
**Issue:** The installation example instructs adopters to add `{:parapet, "~> 0.1.0"}`. The actual version in `mix.exs` is `0.10.0`. The `~> 0.1.0` constraint resolves only `0.1.x`, so any adopter who copies this snippet gets a stale version and never pulls `0.10.0` — they would see `0.1.x` resolved or a resolution error depending on what's published.

**Fix:**
```elixir
def deps do
  [
    {:parapet, "~> 0.10"}
  ]
end
```

### WR-02: "Phase 5" planning terminology exposed in public-facing docs

**File:** `docs/slo-reference.md:6`, `docs/slo-reference.md:10`, `docs/slo-reference.md:85`
**Issue:** The SLO Reference document — which is published to HexDocs as part of the official documentation (`mix.exs:65`) — uses the internal implementation phase label "Phase 5" three times. This is development-process language that means nothing to library adopters and creates confusion about what "Phase 5" refers to in user-facing documentation.

Line 6: "Provider-owned Phase 5 slice specs for built-in async and delivery reliability."
Line 10: "## Phase 5 Provider Registration"
Line 85: "Phase 5 also keeps retry noise and freshness failures separate."

**Fix:** Replace each occurrence with terminology meaningful to adopters:

- Line 6: "Provider-owned slice specs for built-in async and delivery reliability."
- Line 10: "## Provider Registration"
- Line 85: "The provider-based system also keeps retry noise and freshness failures separate."

### WR-03: Mailglass webhook_ingest tag list omits `delay_bucket`

**File:** `docs/integrations/mailglass.md:16`
**Issue:** The "What it unlocks" section lists `parapet_delivery_webhook_ingest` as tagged by `failure_class, fault_plane`. However, the troubleshooting section at line 54 explicitly states that `latency_ms` from Mailglass webhook metadata is mapped to a `delay_bucket` tag on the emitted event. This means `delay_bucket` is a real tag on `webhook_ingest` events that is absent from the tag list. An operator writing a PromQL query against `webhook_ingest` with `delay_bucket` filtering would have no documentation support for doing so.

**Fix:**
```markdown
- `parapet_delivery_webhook_ingest` — webhook exception events, tagged by `failure_class`, `fault_plane`, `delay_bucket`
```

### WR-04: Rindle integration guide missing "Metrics are not appearing" troubleshooting entry

**File:** `docs/integrations/rindle.md:45` (Troubleshooting section)
**Issue:** The Chimeway, Mailglass, and Scoria integration guides all include a "Metrics are not appearing in Prometheus" troubleshooting entry that reminds operators to wire the `Telemetry.Metrics` reporter. The Rindle integration guide's Troubleshooting section contains only two entries — conflict error on startup and unexpected `pipeline_stage` values — with no entry for missing metrics. The async metric families (`parapet_async_stage`, `parapet_async_backlog`, `parapet_async_callback`) require the same reporter wiring, and the omission creates a gap that will cause adoption friction.

**Fix:** Add a "Metrics are not appearing in Prometheus" section to Rindle's Troubleshooting:

```markdown
### Metrics are not appearing in Prometheus

Confirm two things: (1) `Parapet.attach(adapters: [:rindle])` was called before the first Rindle event fired, and (2) your `Telemetry.Metrics` reporter includes metrics from the relevant `Parapet.Metrics.*` module. If the reporter is not wired, counters are defined but never scraped.
```

### WR-05: Rindle doc documents `String.to_atom/1` on external strings without a security caveat

**File:** `docs/integrations/rindle.md:53`
**Issue:** The troubleshooting entry explains that Parapet calls `String.to_atom/1` on the `pipeline_stage` string from Rindle job metadata. This is confirmed in `lib/parapet/integrations/rindle.ex:214`. Atoms in the Erlang VM are not garbage collected; exhausting the atom table crashes the node. If a Rindle job can be enqueued with an attacker-controlled `pipeline_stage` string value (e.g., via an API that creates jobs), each unique string creates a new atom. The documentation presents this normalization as a helpful feature without noting the risk.

The documentation should warn operators that `pipeline_stage` values in Rindle metadata should be constrained to a bounded, known set of atoms. The safer implementation would use `String.to_existing_atom/1` or an allowlist, but the current behavior is what is documented and shipped.

**Fix:** Add a warning to the troubleshooting entry:

```markdown
> **Warning:** Parapet calls `String.to_atom/1` on the normalized stage string. Atoms are not garbage collected in the Erlang VM. If `pipeline_stage` values in Rindle job metadata can be set by untrusted input (e.g., from an external API), an attacker can exhaust the atom table and crash your node. Constrain `pipeline_stage` to a bounded, known set of values in your Rindle job metadata.
```

---

## Info

### IN-01: `mix.exs` package files glob includes nonexistent `CODE_OF_CONDUCT*`

**File:** `mix.exs:42`
**Issue:** The package `files` list includes `CODE_OF_CONDUCT*` as a glob, but no `CODE_OF_CONDUCT.md` (or any file matching that pattern) exists in the repository root. The glob will simply match nothing at publish time, so the package will publish without error, but the inclusion is dead configuration that suggests a file was planned but never created.

**Fix:** Either create a `CODE_OF_CONDUCT.md` (if the project intends to have one) or remove the glob from the files list:

```elixir
files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* LICENSE* docs),
```

### IN-02: README primary SLO example uses the legacy `Parapet.SLO.define/2` API

**File:** `README.md:83-91`
**Issue:** The "Define your SLOs" section in the Operator Loop uses `Parapet.SLO.define/2`, which `docs/slo-reference.md` explicitly labels as the "Legacy" compatibility path and states "New async and delivery slices should be implemented as provider modules instead." The README is the first-contact document for adopters, and its primary example contradicts the guidance in the reference docs. New adopters will start with the deprecated pattern.

**Fix:** Update the "Define your SLOs" example to use the provider module pattern that `docs/slo-reference.md` calls the "blessed path," or at minimum add a note that `Parapet.SLO.define/2` is a legacy surface and link to the SLO Authoring Guide for the recommended approach.

### IN-03: SLO Authoring Guide is absent from README "Learn The Flows" section

**File:** `README.md:212-217`
**Issue:** The "Learn The Flows" section at the bottom of README links to Adopter Flows, Operator UI Guide, SLO Reference, and Telemetry Contract — but not to the SLO Authoring Guide (`docs/slo-authoring-guide.md`), which is a published HexDoc extra and covers how to write custom slices, the bundle pattern, and the denominator guard. The guide is cross-linked from `slo-reference.md` but is not discoverable from the README.

**Fix:** Add the SLO Authoring Guide to the "Learn The Flows" list:

```markdown
## Learn The Flows

- [Parapet Adopter Flows](docs/adopter-flows.md)
- [Operator UI Guide](docs/operator-ui.md)
- [SLO Authoring Guide](docs/slo-authoring-guide.md)
- [SLO Reference](docs/slo-reference.md)
- [Telemetry Contract](docs/telemetry.md)
```

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
