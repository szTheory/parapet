# Phase 18: Adoption & Authoring Docs — Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 8 (7 new Markdown docs + 1 mix.exs edit)
**Analogs found:** 7 / 7 (mix.exs is an edit, no analog needed beyond itself)

---

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `docs/getting-started.md` | guide (sequential tutorial) | request-response (install → run commands → output) | `docs/operator-ui.md` | role-match (prerequisites + command sequence + next-steps) |
| `docs/troubleshooting.md` | reference (Q&A) | request-response | `docs/slo-reference.md` | role-match (short sections, code fences, factual tone) |
| `docs/slo-authoring-guide.md` | guide (conceptual + decision) | transform (slicing decisions → SLO shape) | `docs/adopter-flows.md` | exact (prose-led conceptual framing, enumerated jobs/decisions, no inline code emphasis) |
| `docs/integrations/sigra.md` | integration guide | request-response | `docs/operator-ui.md` | exact (Prerequisites → Installation/Activation → config → doctor/troubleshooting shape) |
| `docs/integrations/accrue.md` | integration guide | request-response | `docs/operator-ui.md` | exact |
| `docs/integrations/rulestead.md` | integration guide | request-response | `docs/operator-ui.md` | exact |
| `docs/integrations/threadline.md` | integration guide | request-response | `docs/operator-ui.md` | exact |
| `mix.exs` | config (ExDoc registration) | — | `mix.exs` itself (lines 58-66) | exact (append entries to existing `extras:` list) |

---

## Pattern Assignments

### `docs/getting-started.md` (sequential tutorial)

**Analog:** `docs/operator-ui.md`

**Why this analog:** `operator-ui.md` is the only existing doc that opens with a one-sentence purpose statement, then has a `## Prerequisites` section, then presents a sequential command-driven setup flow with `bash` and `elixir` fences, and ends with a next-steps pointer. `getting-started.md` must follow the same shape.

**Opening pattern** (`operator-ui.md` lines 1-6):
```markdown
# Parapet Operator UI Guide

The Parapet Operator UI is an optional, generated LiveView workbench that sits inside your host application. Rather than offering another dashboard with raw telemetry, it provides a strictly controlled surface for initiating actionable mitigations when an SLO is burning, with an immutable audit trail for every action.
```
Copy pattern: one-sentence H1, two-sentence orienting paragraph, no sub-heading until `## Prerequisites`.

**Prerequisites section** (`operator-ui.md` lines 9-13):
```markdown
## Prerequisites

- Phoenix and LiveView installed in your host app
- Parapet installed and configured (`mix parapet.install`)
- A router with an existing authenticated pipeline or `live_session`
```
Copy pattern: bullet list, backtick inline code for task/module names, no prose between the heading and the list.

**Command sequence pattern** (`operator-ui.md` lines 15-28):
```markdown
## Installation

The UI remains optional. If you want the installer to compose it for you, use:

```bash
mix parapet.install --with-ui
```

If you prefer to keep the core install path but explicitly suppress the UI branch in automation, use:

```bash
mix parapet.install --skip-ui
```
```
Copy pattern: one-sentence lead-in prose, then `bash` fence, then one-sentence elaboration, then next step. For `getting-started.md` the cold-start steps (D-04) must follow this exact cadence:
1. Add dep → `elixir` fence for `mix.exs` deps block
2. `mix deps.get && mix parapet.install` → `bash` fence
3. Add providers config → `elixir` fence for `config/config.exs`
4. `mix parapet.gen.prometheus` → `bash` fence, then name all three output files
5. `mix parapet.doctor` → `bash` fence

**Elixir config fence style** (`slo-reference.md` lines 12-21):
```elixir
config :parapet,
  providers: [
    Parapet.SLO.MailglassDelivery,
    Parapet.SLO.ChimewayDelivery,
    Parapet.SLO.RindleAsync
  ]
```
Copy pattern: `elixir` fence (not `ex` or `config`), two-space indent, trailing comma on each line.

**Doctor / security cross-check pattern** (`operator-ui.md` lines 63-79):
```markdown
## Security and Verification

The Parapet Doctor includes a dedicated check to verify that your operator UI is securely mounted.

Run the doctor task to ensure the UI is not exposed publicly:

```bash
mix parapet.doctor
```

If the doctor detects that `OperatorLive` or `OperatorDetailLive` are mounted outside of an authenticated scope, it reports a `warn` finding (`Unsecured operator UI LiveView found`).

Local doctor runs fail only on `error`, while CI can treat warnings as blocking:

```bash
mix parapet.doctor --ci
```
```
Copy pattern (for the "Validate your setup" section of getting-started): the `--ci` vs local threshold distinction is explained exactly like this, with two separate `bash` fences. The new doc must match this exact directional framing — `--ci` is the *stricter* gate.

**What is UNIQUE to `getting-started.md`:**
- The login-slice data caveat (D-06): "The login-journey slice needs `parapet_journey_login_count` — if you have not wired Sigra (or another emitter), the slice has no data. The `min_total_rate` guard prevents false-positive alerts, but no data is not the same as green."
- The "zero raw PromQL" promise (D-05): state explicitly that the adopter writes no PromQL.
- Cross-link to `docs/adopter-flows.md` for conceptual depth, `docs/slo-authoring-guide.md` for custom SLO authoring, and `docs/integrations/sigra.md` for the login-slice prereq.
- Must NOT show `config :parapet, :slos, [...]` (legacy path) anywhere.
- Note all three output files from `mix parapet.gen.prometheus`: `recording_rules.yml`, `alerts.yml`, `rules.yml`.

---

### `docs/troubleshooting.md` (Q&A reference)

**Analog:** `docs/slo-reference.md`

**Why this analog:** `slo-reference.md` is the clearest example of the short-section factual style: each `##` heading introduces a concept or question, one or two sentences of prose precede the code fence, and the section ends without a summary. `telemetry.md` is also a strong reference for the definition-list style (`**Measurements:**`, `**Metadata:**`). For troubleshooting, `slo-reference.md`'s pattern of "prose sentence, then code fence, then one-line explanation" is the right rhythm.

**Section shape pattern** (`slo-reference.md` lines 47-59):
```markdown
## Generated Artifacts

Run:

```bash
mix parapet.gen.prometheus
```

This task reads active providers only and writes:

- `priv/parapet/prometheus/recording_rules.yml`
- `priv/parapet/prometheus/alerts.yml`
- `priv/parapet/prometheus/rules.yml`

`rules.yml` is the compatibility aggregate. The split `recording_rules.yml` and `alerts.yml` files are the preferred host-owned path.
```
Copy pattern for each troubleshooting Q&A: `##` heading phrased as a symptom (e.g., "## Prometheus target is blank"), one-sentence diagnosis prose, optional `bash` code fence, then one-sentence resolution.

**Inline code style** (`slo-reference.md` lines 27-43):
```markdown
- `Parapet.SLO.MailglassDelivery`
  - `mailglass_submit_acceptance`
  - `mailglass_confirmed_delivery`
```
Copy pattern: module names and metric names always in backtick inline code.

**What is UNIQUE to `troubleshooting.md` — the five seeds (D-15):**

1. **`## Prometheus target is blank`** — links to `check_endpoint` (Parapet.Plug.Metrics absence → `warn`) and `check_router` (`/metrics` route). Show `mix parapet.doctor` output. Mention all three files from `mix parapet.gen.prometheus`.
2. **`## The doctor reports a warning but I am not sure if CI will fail`** — explain the `@severity_order` model: `info=0, warn=1, error=2`. Show both forms:
   ```bash
   mix parapet.doctor           # fails only on :error
   mix parapet.doctor --ci      # fails on :warn OR :error (stricter)
   ```
   State direction clearly: `--ci` is stricter, not looser.
3. **`## Oban metrics are missing after install`** — explain `Code.ensure_loaded?(Oban)` compile-out in `lib/parapet/metrics/oban.ex` and `optional: true` in `mix.exs`. Resolution: add `{:oban, ">= 0.0.0"}` to your deps.
4. **`## Concurrent nodes could execute the same escalation twice`** — `cluster_static` doctor check emits ERROR when escalation worker is missing `unique:`. Show the doctor command and the error message text.
5. **`## Fly.io: my deploy hook is not firing`** — scope to the Parapet side: `rel/hooks/post_start.sh`, `$RELEASE_VERSION`, and the `Parapet.Deploy.mark/1` RPC call. Link out to Fly.io docs for scrape config / firewall (per OQ-2).

---

### `docs/slo-authoring-guide.md` (conceptual guide + decision tree)

**Analog:** `docs/adopter-flows.md`

**Why this analog:** `adopter-flows.md` is the canonical example of the "prose-led, jobs-to-be-done" voice in this codebase. It uses enumerated `###` sub-sections under `##` section headings, opens each sub-section with a framing sentence, and uses nested bullets for "Trigger / What you are trying to do / Parapet path / What done looks like / Concrete example." The SLO authoring guide needs the same voice for its decision tree and low-traffic sections.

**Opening and framing voice** (`adopter-flows.md` lines 1-13):
```markdown
# Parapet Adopter Flows

Parapet is easiest to understand if you stop thinking of it as a metrics library and start thinking of it as a reliability operating loop for a Phoenix SaaS.

The promise is simple:

You should be able to install Parapet, point it at the journeys that matter, and answer three uncomfortable questions quickly:
```
Copy pattern: no sub-heading for the intro — just prose. The authoring guide's intro should set the framing for journey slicing before the first `##`.

**Enumerated decision section pattern** (`adopter-flows.md` lines 44-56):
```markdown
### 1. Know if a critical user journey is healthy

**Trigger:** You have a SaaS and want to know whether login, checkout, onboarding, job completion, or provider-mediated delivery is actually working for users.

**What you are trying to do:** Replace vague system health with user-visible reliability.

**Parapet path:** Install the library, define SLOs, generate Prometheus rules, and watch burn-rate style signals for the journey you care about.

**What "done" looks like:** You can say "checkout success is healthy" or "login is burning error budget" instead of "CPU looks fine but support is yelling."

**Concrete example:** Your homepage is up, database is fine, and workers are alive. But a broken auth callback causes login to fail for 4% of real users. Parapet wants that to show up as a journey problem, not as a scavenger hunt across five dashboards.
```
Copy pattern for the journey-slicing decision tree: use bold `**Litmus:**` / `**Good examples:**` / `**Bad examples:**` / `**Real anchor:**` labels instead of Mermaid (per CONTEXT.md discretion: default to nested bullet tree). This mirrors the `**Trigger:**` / `**Parapet path:**` rhythm exactly.

**Short-section factual style** (`adopter-flows.md` lines 205-215, "What Parapet Is Not"):
```markdown
## What Parapet Is Not

Parapet is deliberately not trying to be several other products.

- It is not an APM backend, log store, or trace store.
- It is not hosted observability SaaS.
```
Copy pattern for the "Anti-patterns" or "Lower-the-objective is the wrong move" section: bullet list under a `##` heading, plain sentence structure, no code fences needed unless showing a config snippet.

**`elixir` fence for slice config** (`slo-reference.md` lines 13-21): reuse for showing `min_total_rate` override:
```elixir
config :parapet,
  providers: [Parapet.SLO.StarterPack.WebSaaS]
```
And for showing the guard expression rendered by the generator:
```
parapet:web_saas_login_journey:error_ratio:5m > 0.0144 and parapet:web_saas_login_journey:total_rate:5m > 0.01
```
Note: use a plain (no language tag) fence for rendered PromQL/Prometheus expressions — the existing `slo-reference.md` does not fence them at all; a plain fence is the closest safe choice.

**What is UNIQUE to `slo-authoring-guide.md`:**
- The decision tree (D-14) — spine litmus: "Does this failure directly prevent a user task? → journey SLO." Anchor to the three real WebSaaS slices: `web_saas_http_availability`, `web_saas_login_journey`, `web_saas_oban_job_success`.
- The "Low-Traffic and Low-Volume Services" `##` section (D-12/D-13): must quote the guard shape verbatim, name `min_total_rate: 0.01` as the default, list the six windows `["5m", "30m", "1h", "2h", "6h", "3d"]`, and describe the multipliers (14.4×/page, 6.0×/ticket, 1.0×/warning).
- Name `Parapet.Metrics.Probe` as the synthetic-probe fallback.
- Name "lower-the-objective to silence noise" explicitly as the anti-pattern.
- Cross-link to `docs/slo-reference.md` for the full provider/slice catalog — do NOT duplicate the slice list.

---

### `docs/integrations/sigra.md`, `accrue.md`, `rulestead.md`, `threadline.md` (integration guides)

**Analog:** `docs/operator-ui.md`

**Why this analog:** `operator-ui.md` is the only existing doc that follows the exact structural template required by D-11: Prerequisites → what the feature does → activation commands → config → troubleshooting. Its section headings map directly to the required integration guide shape.

**Shared structural template (D-11) — all four guides must follow this exactly:**

```markdown
# Parapet + <Integration Name>

<One-sentence description: what the integration is and what Parapet surfaces with it.>

## Prerequisites

- `<integration_lib>` installed in your host app (optional dep — Parapet detects it via `Code.ensure_loaded?`)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

<Honest per-integration description — see unique notes below for each.>

## Activation

```elixir
<see per-guide activation line below>
```

## Config keys

<List of config keys, if any.>

## Troubleshooting

### <Symptom 1>

<One-sentence diagnosis. Resolution.>

### <Symptom 2>

<One-sentence diagnosis. Resolution.>
```

**Prerequisites section style** (`operator-ui.md` lines 9-13):
```markdown
## Prerequisites

- Phoenix and LiveView installed in your host app
- Parapet installed and configured (`mix parapet.install`)
- A router with an existing authenticated pipeline or `live_session`
```

**Activation block style** (`operator-ui.md` lines 15-26):
```markdown
## Installation

The UI remains optional. If you want the installer to compose it for you, use:

```bash
mix parapet.install --with-ui
```
```
For integration guides, this section is named `## Activation` and uses an `elixir` fence (not `bash`).

**Troubleshooting sub-section style** (`operator-ui.md` lines 63-85):
```markdown
## Security and Verification

...

```bash
mix parapet.doctor --ci
```

For live cluster facts around the same install, use:

```bash
mix parapet.doctor cluster
```
```
Copy pattern: each troubleshooting answer is a `###` sub-heading phrased as a symptom, then one-sentence resolution, then optional code fence.

---

#### `docs/integrations/sigra.md` — what is UNIQUE

**What it unlocks** (honest, D-09):
Sigra login and signup events become Parapet journey metrics (`parapet_journey_login_count`, `parapet_journey_signup_count`). The `web_saas_login_journey` slice in `Parapet.SLO.StarterPack.WebSaaS` relies on `parapet_journey_login_count` — without Sigra (or another emitter), that slice has no data.

**Activation line** (works — Sigra exposes `setup/0` at `integrations/sigra.ex:12`):
```elixir
Parapet.attach(adapters: [:sigra])
```

**Cross-link:** → `docs/getting-started.md` for the full cold-start sequence, → `docs/slo-reference.md` for the WebSaaS provider registration.

---

#### `docs/integrations/accrue.md` — what is UNIQUE

**What it unlocks** (honest, D-09):
Accrue billing events become Parapet journey metrics (`parapet.journey.billing.checkout.count`, `parapet.journey.billing.webhook.duration`). There is no pre-built SLO slice for Accrue — these metrics are the foundation for a custom slice you author in `docs/slo-authoring-guide.md`.

**Activation line** (works — Accrue exposes `setup/0` at `integrations/accrue.ex:12`):
```elixir
Parapet.attach(adapters: [:accrue])
```

---

#### `docs/integrations/rulestead.md` — what is UNIQUE

**What it unlocks** (honest, D-09):
Rulestead ruleset-published events become the `parapet_rulestead_flag_change_total` counter. To surface this metric in Prometheus, include `Parapet.Metrics.Rulestead.metrics()` in your host app's `Telemetry.Metrics` reporter config — the integration module wires the event handler but does not call the reporter setup automatically (OQ-3 gap).

**Activation line — UNIFORM, same as the other three (D-16 SUPERSEDES D-07):**
```elixir
Parapet.attach(adapters: [:rulestead])
```
After plan 18-01 adds `def setup, do: attach()` to `rulestead.ex` plus the `Parapet.Integration` behaviour, this uniform line WORKS. Do NOT write `Parapet.Integrations.Rulestead.attach()`, and do NOT frame the uniform line as a crash — the historical "raises UndefinedFunctionError" framing is superseded. Anti-drift check 2: `Parapet.attach(adapters: [:rulestead])` must appear ONLY as the valid uniform line (present in rulestead.md), never as a documented crash; `Parapet.Integrations.Rulestead.attach()` must NOT appear in any doc.

---

#### `docs/integrations/threadline.md` — what is UNIQUE

**What it unlocks** (honest, D-08):
Audit evidence interoperability — not SLO slices and not Prometheus metrics. Inbound: `[:threadline, :audit, :event]` events are logged as `Parapet.Evidence` audit records (always active). Outbound: `[:parapet, :audit, :created]` events are forwarded to `Threadline.log_audit/1` if the host app has the Threadline library loaded (`Code.ensure_loaded?(Threadline)` guard).

The guide MUST NOT contain an "unlocks SLO slices" or "unlocks metrics" section. The anti-drift check for `grep -l "SLO slice" docs/integrations/threadline.md` must return 0.

**Activation line** (works — Threadline exposes `setup/0` at `integrations/threadline.ex:12`):
```elixir
Parapet.attach(adapters: [:threadline])
```

---

### `mix.exs` — `extras:` registration edit

**No analog needed — edit the existing file.**

**Exact current `extras:` block** (`mix.exs` lines 58-66):
```elixir
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/HISTORY.md",
        "docs/adopter-flows.md",
        "docs/operator-ui.md",
        "docs/slo-reference.md",
        "docs/telemetry.md"
      ],
```

**Exact `groups_for_extras:` block** (`mix.exs` lines 68-70):
```elixir
      groups_for_extras: [
        Guides: ~r/docs\//
      ]
```

**What the planner adds:** Append the seven new file paths to the `extras:` list, after `"docs/telemetry.md"` and before the closing `]`. The regex `~r/docs\//` already matches `docs/integrations/*.md` — no `groups_for_extras` change is needed.

**New entries to append (in reading order):**
```elixir
        "docs/getting-started.md",
        "docs/troubleshooting.md",
        "docs/slo-authoring-guide.md",
        "docs/integrations/sigra.md",
        "docs/integrations/accrue.md",
        "docs/integrations/rulestead.md",
        "docs/integrations/threadline.md"
```

**Edit landing point:** Insert after line 65 (`"docs/telemetry.md"`), before line 66 (`]`). The planner should treat this as a single targeted line-range replacement of lines 58-66 with the expanded list.

**Indentation pattern:** Four leading spaces (to align with the existing entries at column 8, inside `defp docs do` → `[` → `extras: [`).

---

## Shared Patterns

### Voice and heading style
**Source:** `docs/adopter-flows.md` (canonical voice reference, D-03)

Apply to: ALL seven new docs.

Rules extracted from the live source:
- H1: `# Parapet <Title>` — article-style title, not imperative
- `##` headings: sentence-case (e.g., `## What it unlocks`, `## Low-traffic and low-volume services`) — NOT title-case
- `###` headings: sentence-case sub-sections
- Second-person prose: "You should be able to...", "If you have...", "Run this command..."
- No emojis anywhere
- No bold inline emphasis for decoration — bold used only for the `**Label:**` pattern in jobs-to-be-done lists
- Short paragraphs (2-4 sentences max before a code fence or bullet list)

### Code fence conventions
**Source:** `docs/slo-reference.md` lines 13-21 (`elixir` fence) and lines 48-51 (`bash` fence)

Apply to: ALL seven new docs.

```markdown
```elixir
config :parapet,
  providers: [Parapet.SLO.StarterPack.WebSaaS]
```

```bash
mix parapet.gen.prometheus
```
```

Rules:
- `elixir` for Elixir/config code — never `ex`, `exs`, or unlabeled
- `bash` for shell commands — never `sh` or `shell`
- Plain fence (no language tag) only for rendered Prometheus expressions / YAML output
- Inline backtick code for module names, metric names, config keys, file paths, and task names

### Cross-linking convention
**Source:** `README.md` line 57

```markdown
If you want the shortest explanation of what Parapet is trying to help an adopter do, read [Parapet Adopter Flows](docs/adopter-flows.md).
```

Apply to: all cross-references in the seven new docs.

Rules:
- Link text is the doc's H1 title (or a descriptive phrase)
- Link target is the relative path from the repo root (e.g., `docs/slo-reference.md`, `docs/integrations/sigra.md`)
- ExDoc resolves these as relative extras links; `mix docs --warnings-as-errors` will catch broken paths

### Prerequisites section
**Source:** `docs/operator-ui.md` lines 9-13

Apply to: `getting-started.md` and all four integration guides.

Pattern: `## Prerequisites` heading, dash-list with backtick inline code for task/lib names, no prose between heading and list.

---

## No Analog Found

All seven new Markdown files have a usable analog in the existing `docs/` tree. No file requires falling back to RESEARCH.md patterns exclusively — though RESEARCH.md `Code Examples` section provides the verified code snippets (integration activation lines, guard expression shape, deploy hook) that must be copied verbatim into the new docs.

---

## Metadata

**Analog search scope:** `docs/` directory (5 existing docs + README.md), `mix.exs`
**Files scanned:** 7 existing docs/config files
**Pattern extraction date:** 2026-05-24
