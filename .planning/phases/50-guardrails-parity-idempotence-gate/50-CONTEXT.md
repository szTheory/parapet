# Phase 50: Guardrails, parity & idempotence gate - Context

**Gathered:** 2026-06-28 (assumptions mode + advisor research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Final phase of the **v1.6 Operator UI Brand & Design-System Audit** milestone. Scope is
**forward-only regression guardrails + the milestone audit** over the operator UI built in phases
44–49. No new UI, no markup re-skinning, no new product capability — this phase only adds tests,
one capture-script mode, one committed manifest, and one audit document that *prove* the prior work
holds and cannot silently regress.

Requirements in scope: **GUARD-03, GUARD-04, GUARD-05, GUARD-06, GUARD-07**.

The one in-scope *source* edit allowed is fixing a generator-template defect that GUARD-03 exists to
catch (see D-03). Everything else is additive test/doc/tooling.
</domain>

<decisions>
## Implementation Decisions

### A. GUARD-03 — template↔demo byte-parity test

- **D-01:** Drive the parity test through the repo's **own `Igniter.Test` generator-invocation
  idiom**, not `EEx.eval_file`. Per the established pattern in `parapet.gen.spine_test.exs` /
  `parapet.gen.recovery_test.exs`: `import Igniter.Test` → `test_project(app_name: :demo_app)` →
  `Mix.Tasks.Parapet.Gen.Ui.igniter(...)` → read each generated file's content from
  `igniter.rewrite` (`Rewrite.Source.get(..., :content)`). This is *faithful* (runs the real
  Igniter `copy_template` pipeline with real `web_module: DemoAppWeb` / `repo_module: DemoApp.Repo`
  assigns) yet stays in-process and fast — strictly better than `EEx.eval_file` (less faithful) or
  a temp-dir mix task (slower) for a solo OSS lib.
- **D-02:** **Normalize both sides through `Code.format_string!/1` and assert equality**, inside a
  `try/rescue` so a render that won't even parse is reported as an explicit, named parity failure
  (not a raw stack trace). Normalize **both** the freshly-generated content **and**
  `File.read!(mirror)` — do not assume the committed mirror is already canonically formatted across
  formatter versions. **REJECT AST-compare** (`Code.string_to_quoted`): it discards comments, so it
  would mark the D-03 comment bug as *passing* — the single most important constraint here. The
  transform interpolates **both** `@web_module` AND `@repo_module` (the earlier "only @web_module
  differs" note was incomplete; `@repo_module` differs 4× in operator_live, 6× in
  operator_detail_live); `@app_name` is passed but never interpolated into these three templates.
- **D-03:** **Fix the generator-template defect; do NOT normalize comments away.**
  `operator_components.ex.eex:1428` and `:1442` use build-time EEx comments `<%#- D-07 … %>` /
  `<%#- D-08 … %>` that render to the empty string, so a fresh `mix parapet.gen.ui` produces an
  `operator_components.ex` **missing** the two D-07/D-08 WCAG-1.4.1 rationale comments the committed
  mirror has — genuine generator↔demo drift shipped to every adopter. Fix the **template** so it
  reproduces the mirror: escape to a runtime comment that emits exactly what the mirror contains
  (`<%%# D-07 … %>` → emits `<%# … %>`, matching the mirror with minimal churn). *Planner note:* if
  the Elixir version in use warns that `<%#` is deprecated in favor of `<%!-- … --%>`, modernize
  **both** template and mirror to `<%!-- … --%>` instead — either way the template must reproduce
  the mirror for the right reason, never by stripping comments in the test.
- **D-04:** Cover **all three** template↔mirror pairs (`operator_components`, `operator_live`,
  `operator_detail_live`). After D-03's fix, all three are byte-equal under `Code.format_string!`
  normalization (operator_live and operator_detail_live already are; operator_components becomes so
  once the comment fix lands).
- **D-05:** **Failure-message DX:** on mismatch, name the failing pair, show the first divergent
  line + line number (diff-as-message), and end with the exact remediation —
  *"Regenerate: `mix parapet.gen.ui` into examples/demo_app, then `mix format`."* On the
  parse-failure path, surface the offending EEx line.

### B. GUARD-04 — off-palette-hex allowlist gate

- **D-06:** **Fail-closed allowlist, sourced live from `brandbook/tokens/tokens.css`** (parse the
  ~31 token `#rrggbb` literals at test time — single source of truth, so palette edits propagate to
  the gate with zero test edits), **plus** a small set of documented operator-specific exceptions.
  Guard the parse with `assert MapSet.size(allowlist) >= 31` so a broken/empty parse fails closed
  rather than silently passing an empty allowlist. This is the Elixir-native equivalent of
  stylelint `declaration-property-value-allowed-list`. Scan all three `.eex` templates for every
  `#[0-9a-fA-F]{6}` literal; fail on any not in `allowlist ∪ exceptions`.
- **D-07:** **Exception set = 5 operator-specific hexes**, declared in **one documented home**, not
  as bare inline literals (inline = silent backdoor): `#7FB4C6` (dark `--po-link`), `#A8D0DE`
  (dark link-hover / accent-strong), `#1A5066` (light link-hover / accent-strong — darkened Watch
  Blue), `#556B77` (dark chip-neutral-border), `#8C2E27` (destructive-hover — darkened Incident
  Red). Only `#7FB4C6`/`#A8D0DE` are documented today; this phase must add a one-line rationale +
  contrast note for `#1A5066`, `#556B77`, `#8C2E27` to the **GUARD-04 exception section of
  `brandbook/notes/operator-audit-matrix.md`** before the gate ships. The gate reads its exception
  set from that single committed declaration.
- **D-08:** **The hex-allowlist gate AUGMENTS, does not replace, the existing class denylist.** The
  current `refute content =~ "bg-indigo-600"` checks in `operator_ui_contrast_test.exs` guard
  off-palette Tailwind utility *classes*; the new gate guards off-palette *hex literals* in CSS —
  **different surfaces**, both needed. Keep both.
- **D-09:** **Scan `#rrggbb` (6-digit) only** — verified the three templates contain zero 3-digit
  hex, zero hsl, zero named colors, and every `rgba()` is the neutral `16,24,32` (`#101820`)
  shadow/border family. Widening to rgb/hsl/named adds only false-positive surface. Do not
  over-engineer.

### C. GUARD-05 — motion / reduced-motion assertion

- **D-10:** Assert the brand easing curve via a **whitespace/leading-zero-tolerant regex**, NOT a
  literal string. Verified the literal would be brittle: the template uses `cubic-bezier(.2, 0, 0,
  1)` while `tokens.css` uses `cubic-bezier(0.2, 0, 0, 1)` — they already disagree on formatting.
  Use e.g. `~r/cubic-bezier\(\s*0?\.2\s*,\s*0\s*,\s*0\s*,\s*1\s*\)/`.
- **D-11:** Assert **both** `--motion-fast: 0ms` **and** `--motion-base: 0ms` are zeroed inside the
  `@media (prefers-reduced-motion: reduce)` block. Verified both are present
  (`operator_components.ex.eex:468-469`), so the assertion is safe — it locks in what exists today
  against future regression. (Existing test only asserts `--motion-fast: 0ms`.)

### D. Test organization (coherent across GUARD-03/04/05)

- **D-12:** **File-per-concern**, matching the repo's established `operator_ui_*` convention
  (`operator_ui_fonts/compile_out/demo_contract/integration_test.exs` are each a flat
  `Parapet.OperatorUI*Test`, `async: true`). Add three new files under `test/parapet/`:
  - `operator_ui_parity_test.exs` (GUARD-03) — render + `Code.format_string!` + compare machinery,
    isolated from the a11y file.
  - `operator_ui_palette_gate_test.exs` (GUARD-04) — the hex-allowlist scan.
  - `operator_ui_motion_test.exs` (GUARD-05) — the easing + reduced-motion assertions.
  A "contrast" file holding parity/palette/motion would violate least-surprise.
- **D-13:** **Extract a shared path helper** `test/support/operator_ui_paths.ex`
  (`Parapet.TestSupport.OperatorUIPaths` with `component_paths/0`, `live_template_paths/0`,
  `detail_template_paths/0`). `test/support` is already on `elixirc_paths(:test)` and
  `Parapet.TestSupport.*` is an established namespace (`ConcurrencyCase`/`ConcurrencyRepo`). The
  template/mirror path strings are already duplicated 30+ times across `operator_ui_contrast` and
  `operator_ui_integration`; this is real (not speculative) de-duplication and gives one edit-point
  for a future fourth pair. New files consume it; retrofitting the existing files is encouraged but
  planner-discretion (low-risk, string-only).

### E. GUARD-06 — baseline manifest + re-run/compare procedure

- **D-14:** **Add a `--manifest` mode to `capture_operator_ui_screenshots.sh`** that emits the
  manifest from the **same capture list** that drives the screenshots — refactor the 15 `capture …`
  lines (`:69-88`) to iterate one shared list (bash array / dispatch). The script becomes the single
  source of truth, structurally eliminating the stale-count drift Phase-49 D-09 worried about. Under
  `--manifest` the script prints the table instead of invoking Chrome (so it needs no DB, no server,
  no Chrome).
- **D-15:** **Committed artifact = one Markdown file** `examples/demo_app/scripts/operator-ui-baseline.md`
  (next to the script that emits it). Rows carry `name | route | viewport (WxH) | theme | scenario`
  plus an expected total-count line (15 captures). **No PNGs, no content hashes** (hashing would
  require Chrome + seeded Postgres and would be flaky over dynamic stress data — repo stays
  raster-free per D-09). Markdown over JSON/YAML because the primary consumer is a human auditor.
- **D-16:** The **`## Re-run & compare` procedure lives in the same file** (one file = manifest +
  procedure, can't get separated): env setup + `PARAPET_DEMO_SCENARIO=stress` seed → start demo app
  → run `capture_operator_ui_screenshots.sh <out>` (PNGs land in tmp, never committed) → compare
  each PNG against the manifest rows (all present, correct viewport/theme, eyeball layout) → when to
  update the baseline (re-run `--manifest`, commit regenerated `.md`, never commit PNGs).
- **D-17:** **Add one cheap CI-enforceable check** (nearly free, needs no Chrome/DB/server): a step
  that runs `capture_operator_ui_screenshots.sh --manifest` and `diff`s it against the committed
  `operator-ui-baseline.md`, failing on drift. This makes "manifest matches the script" an enforced
  gate while the pixel comparison stays a human procedure. (Reject committed PNG baselines and
  cloud-baseline services — both reintroduce exactly what Parapet avoids: rasters in git / a
  headless-Chrome-on-seeded-Postgres CI pipeline.)

### F. GUARD-07 — `v1.6-MILESTONE-AUDIT.md`

- **D-18:** Write `.planning/milestones/v1.6-MILESTONE-AUDIT.md` in the established **v1.4/v1.5
  house style** (YAML frontmatter with scores/gaps/nyquist → Summary → Requirements Coverage table
  → Phase Verification → **Non-Regression Proofs** → **Idempotence Proof** → **Font Package-Size
  Delta** → Verification Commands block with pasted output → Result). Principle: **every claim
  resolves to an artifact someone can re-run** — a command, a manifest diff, or a file:line. The
  audit is a thin *evidence-binding* doc over existing gates, not new tooling.
- **D-19:** **Per-requirement evidence table** columns: `Requirement | Phase | Claim | Evidence
  (command or file:line) | Status` — one row per TOKEN/FONT/COMP/NAV/DATA/GROUP/FLOW/COPY/A11Y/
  MOTION/GALLERY/FIXTURE/GUARD id. **Coherent with `operator-audit-matrix.md` by reference, not
  duplication**: the audit table proves *requirement* coverage and links to the component×state
  ledger for per-cell `verified` status; the matrix stays the single idempotence source of truth.
- **D-20:** **Three non-regression proofs, each bound to its strongest existing evidence:**
  - **public-API** → `mix verify.public_api` exit 0 against committed
    `priv/parapet/public_api_stable.json` (manifest-diff drift gate — gold standard).
  - **host-ownership** → existing compile-out / integration tests
    (`operator_ui_compile_out_test.exs`, `operator_ui_integration_test.exs`) + the three
    `on_exists: :skip` call sites in `parapet.gen.ui.ex:43,54,65` + the host-ownership grep-proofs
    already in `operator-audit-matrix.md` (router-level authz, synchronous mount, no Parapet-owned
    JS/dep added).
  - **telemetry** → `mix test test/telemetry_contract_test.exs` proving the frozen telemetry-family
    contract (the operator UI is host-owned markup and adds **no** telemetry events).
- **D-21:** **Do NOT add a `telemetry_stable.json` manifest this phase.** Although the
  engineering-DNA "treat telemetry as public API" rule makes a stable telemetry manifest the right
  *long-term* move (and `telemetry_contract_test.exs` itself flags WR-01 as the durable fix), a new
  runtime drift-gate is **out of the v1.6 UI-brand milestone boundary**; the existing family-count +
  metadata contract test is sufficient to prove no regression for *this* milestone. Record the
  stable telemetry manifest as a backlog/follow-up item (see Deferred Ideas).
- **D-22:** **Idempotence / forward-only proof**, framed like Terraform `plan` / Ecto-generator
  no-op: cite `mix parapet.gen.ui --dry-run` producing **zero file changes** on an already-installed
  host (`--dry-run` is honored — `parapet.gen.ui.ex:74` + Igniter `super/1`); the three
  `on_exists: :skip` sites (forward-only — generated host markup never overwritten/destructively
  edited); and the ledger semantics in `operator-audit-matrix.md` where cells only advance
  `todo→done→verified` and re-runs revisit only non-`verified`/regressed cells.
- **D-23:** **Font package-size delta** — fonts were *added* this milestone, so there is no
  pre-font baseline to subtract. Report the **honest reproducible pair**: (a) absolute woff2 total
  ≈ **52.2 KB across 5 files** (machine-checked under the 150 KB ceiling by
  `operator_ui_fonts_test.exs`), labeled "added this milestone"; and (b) a tarball-level delta from
  **`mix hex.build`** `Package size` (pre-v1.6 vs post — the publish-payload number adopters
  actually download, since `priv/static/parapet/fonts/` ships in the tarball). Use `mix hex.build`,
  not `hex.publish --dry-run`.

### Claude's Discretion
- Exact regex/parse mechanics for harvesting the 31 token hexes from `tokens.css` (any robust
  `#rrggbb` scan that yields ≥31 and stays in sync with the file).
- Whether to retrofit the existing `operator_ui_contrast`/`operator_ui_integration` files to consume
  the new `OperatorUIPaths` helper now or leave them (D-13) — both acceptable; low-risk either way.
- Exact bash structure of the shared capture list / `--manifest` dispatch (D-14), provided capture
  and manifest emission iterate the same list.
- Exact column order / frontmatter detail of the audit doc within the v1.4/v1.5 house style.
- Whether GUARD-05's pre-existing motion assertions in `operator_ui_contrast_test.exs` are migrated
  into the new `operator_ui_motion_test.exs` as a cohesion pass or left in place (string-grep, no
  risk).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — GUARD-03..07 acceptance criteria (lines 120-124)
- `.planning/ROADMAP.md` — Phase 50 success criteria
- `brandbook/tokens/tokens.css` — the ~31-hex palette allowlist source of truth (GUARD-04, D-06)
- `brandbook/notes/operator-audit-matrix.md` — idempotence ledger + GUARD-04 exception home
  (D-07); host-ownership grep-proofs (D-20)
- `priv/templates/parapet.gen.ui/{operator_components,operator_live,operator_detail_live}.ex.eex` —
  the three templates scanned/compared
- `examples/demo_app/lib/demo_app_web/live/parapet/{operator_components,operator_live,operator_detail_live}.ex` —
  the three demo mirrors
- `lib/mix/tasks/parapet.gen.ui.ex` — the generator transform (assigns; `on_exists: :skip` at
  43/54/65; `--dry-run` at 74) — GUARD-03/07
- `test/parapet/operator_ui_contrast_test.exs` — existing grep-gate apparatus + path attrs to mirror
- `test/mix/tasks/parapet.gen.spine_test.exs`, `…/parapet.gen.recovery_test.exs` —
  `Igniter.Test` invocation idiom for GUARD-03 (D-01)
- `test/parapet/operator_ui_fonts_test.exs` — 150 KB woff2 ceiling gate (D-23)
- `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` — capture list to refactor (D-14)
- `lib/mix/tasks/verify.public_api.ex` + `priv/parapet/public_api_stable.json` — public-API drift
  gate (D-20)
- `test/telemetry_contract_test.exs` — telemetry-family contract (D-20/D-21)
- `.planning/milestones/v1.5-MILESTONE-AUDIT.md` (+ v1.4) — audit house style + bash-verification
  precedent (D-18)
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — "scripts-first / locally reproducible",
  "host-owned generated code", "don't hide tests in obscure lanes", "treat telemetry as public API"
- `prompts/sre-best-practices-solo-founder-deep-research.md` — solo-maintainer ergonomics (GUARD-06)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Igniter.Test` generator-invocation idiom already used by `parapet.gen.spine_test.exs` /
  `parapet.gen.recovery_test.exs` — GUARD-03 reuses it verbatim.
- `mix verify.public_api` + `public_api_stable.json` — the manifest-diff drift-gate pattern;
  GUARD-07 cites it and GUARD-04's allowlist mirrors its fail-closed philosophy.
- `operator_ui_fonts_test.exs` already enforces the woff2 ≤150 KB ceiling (actual ≈52.2 KB).
- `telemetry_contract_test.exs` already freezes the telemetry-family contract.
- `test/support/` (on `elixirc_paths(:test)`) with `Parapet.TestSupport.*` namespace — home for the
  new `OperatorUIPaths` helper.
- `capture_operator_ui_screenshots.sh` already enumerates the 15 captures (6 desktop + 5 mobile + 4
  gallery) and runs against `PARAPET_DEMO_SCENARIO=stress`.

### Established Patterns
- `operator_ui_*` test files are file-per-concern, flat `Parapet.OperatorUI*Test`, `async: true`,
  reading `priv/templates/...` + `examples/demo_app/...` via `File.read!` relative to project root.
- Generated host files are `on_exists: :skip` (host-owned, forward-only).
- Repo is deliberately raster-free / repo-lean; verification is bash-script + documented procedure,
  not committed images or cloud services.

### Integration Points
- New tests slot into `test/parapet/` and run under the existing `mix test` CI lane.
- The `--manifest` mode and its CI diff-check slot into existing CI without new infra (no Chrome/DB).
- The audit doc joins `.planning/milestones/`.
- The one source edit (D-03 comment fix) touches `operator_components.ex.eex` (+ its mirror) and is
  validated by the new GUARD-03 parity test.
</code_context>

<specifics>
## Specific Ideas

- GUARD-03 must catch the D-03 comment bug *for the right reason* (template reproduces mirror), not
  paper over it — this is the load-bearing principle and the reason AST-compare is rejected.
- GUARD-04 allowlist is **fail-closed** and **single-sourced from `tokens.css`**; exceptions are
  legitimate only when documented in the audit matrix.
- GUARD-06 manifest is **script-generated** (single source of truth) with a **cheap CI diff-check**,
  keeping the repo raster-free while still enforceable.
- GUARD-07 binds every regression claim to a re-runnable command/manifest/file:line.
</specifics>

<deferred>
## Deferred Ideas

- **Stable telemetry manifest** (`telemetry_stable.json` + drift gate analogous to
  `public_api_stable.json`) — the durable fix `telemetry_contract_test.exs` flags as WR-01. Right
  long-term move per engineering-DNA "treat telemetry as public API", but out of the v1.6 UI-brand
  milestone boundary (D-21). Backlog for a future telemetry/contract-hardening phase.
- **Committed perceptual-hash / pixel-diff visual-regression gate** (Chromatic/Percy/reg-suit
  style) — rejected for v1.6 (needs cloud service or headless-Chrome-on-seeded-Postgres CI, both
  contrary to repo-lean/zero-infra DX). Revisit only if the project adopts a CI browser pipeline.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
