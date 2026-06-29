# Phase 50: Guardrails, Parity & Idempotence Gate - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/parapet/operator_ui_parity_test.exs` | test | transform (render+compare) | `test/mix/tasks/parapet.gen.ui_test.exs` + `parapet.gen.recovery_test.exs` | exact (Igniter.Test idiom + operator assertions) |
| `test/parapet/operator_ui_palette_gate_test.exs` | test | transform (grep+allowlist) | `test/parapet/operator_ui_contrast_test.exs` | role-match (same path attrs, file-read loop) |
| `test/parapet/operator_ui_motion_test.exs` | test | transform (grep assertions) | `test/parapet/operator_ui_contrast_test.exs` lines 118–125, 232–233 | exact (existing motion assertions to extract) |
| `test/support/operator_ui_paths.ex` | utility | N/A | `test/support/concurrency_repo.ex` + `concurrency_case.ex` (namespace/module shape) | role-match (`Parapet.TestSupport.*`) |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` (D-03 fix) | template | N/A | itself (lines 1428, 1442) + mirror lines 1428, 1442 | N/A — targeted edit; mirror is the reference |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` (D-03 fix) | generated file | N/A | itself (lines 1428, 1442) — mirror of template | N/A — targeted edit |
| `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` (D-14 refactor) | script | batch | itself (lines 47–88) | N/A — refactor of existing structure |
| `examples/demo_app/scripts/operator-ui-baseline.md` | doc/manifest | N/A | `.planning/milestones/v1.5-MILESTONE-AUDIT.md` (bash-verification block) | house-style match |
| `.planning/milestones/v1.6-MILESTONE-AUDIT.md` | doc/audit | N/A | `.planning/milestones/v1.5-MILESTONE-AUDIT.md` + `v1.4-MILESTONE-AUDIT.md` | exact house style |

---

## Pattern Assignments

### `test/parapet/operator_ui_parity_test.exs` (test, transform)

**Analogs:** `test/mix/tasks/parapet.gen.ui_test.exs` (Igniter invocation + rewrite read); `test/mix/tasks/parapet.gen.recovery_test.exs` (simpler idiom)

**Module + import pattern** (from `parapet.gen.ui_test.exs` lines 1–6, `parapet.gen.recovery_test.exs` lines 1–5):
```elixir
defmodule Parapet.OperatorUIParityTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Ui
end
```

**Generator invocation + source extraction idiom** (`parapet.gen.ui_test.exs` lines 9–30, `parapet.gen.recovery_test.exs` lines 14–32):
```elixir
# Invoke the real generator against a test project with demo_app assigns
igniter =
  test_project(app_name: :demo_app)
  |> Ui.igniter()

# Extract generated content for a specific output path
operator_components_source =
  Rewrite.source!(igniter.rewrite, "lib/demo_app_web/live/parapet/operator_components.ex")
  |> Rewrite.Source.get(:content)
```

**Private helper to DRY up source extraction** (`parapet.gen.ui_test.exs` lines 296–300):
```elixir
defp generated_source(igniter, path) do
  igniter.rewrite
  |> Rewrite.source!(path)
  |> Rewrite.Source.get(:content)
end
```

**Core parity pattern** — NEW for this test; no direct analog exists but the D-02 decision specifies:
```elixir
# For each of the three template↔mirror pairs:
#   generated_path  = path within igniter.rewrite (what the generator emits)
#   mirror_path     = "examples/demo_app/lib/demo_app_web/live/parapet/…"
try do
  normalized_generated = Code.format_string!(generated_content)
  normalized_mirror    = Code.format_string!(File.read!(mirror_path))
  assert normalized_generated == normalized_mirror,
    """
    Parity failure: #{pair_name}
    First divergent line #{first_diff_line(normalized_generated, normalized_mirror)}
    Remediate: mix parapet.gen.ui into examples/demo_app, then mix format.
    """
rescue
  e in SyntaxError ->
    flunk("Parity failure (parse error) in #{pair_name}: #{Exception.message(e)}")
end
```

**Three pairs to cover** (D-04; paths from `parapet.gen.ui_test.exs` lines 15–22 and `operator_ui_contrast_test.exs` `@component_paths`/`@live_template_paths`/`@detail_template_paths`):
```
generated path (within igniter.rewrite)                              mirror path
lib/demo_app_web/live/parapet/operator_components.ex     ↔  examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
lib/demo_app_web/live/parapet/operator_live.ex           ↔  examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
lib/demo_app_web/live/parapet/operator_detail_live.ex    ↔  examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
```

**Failure-message DX requirement** (D-05): name the failing pair, show first divergent line number, append exact remediation string `"Regenerate: mix parapet.gen.ui into examples/demo_app, then mix format."`.

---

### `test/parapet/operator_ui_palette_gate_test.exs` (test, transform)

**Analog:** `test/parapet/operator_ui_contrast_test.exs`

**Module header + path attribute pattern** (`operator_ui_contrast_test.exs` lines 1–7, 237–245):
```elixir
defmodule Parapet.OperatorUIPaletteGateTest do
  use ExUnit.Case, async: true

  @component_paths [
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex",
    "priv/templates/parapet.gen.ui/operator_components.ex.eex"
  ]

  @live_template_paths [
    "priv/templates/parapet.gen.ui/operator_live.ex.eex",
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
  ]

  @detail_template_paths [
    "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
  ]
end
```

**File-read loop pattern** (`operator_ui_contrast_test.exs` lines 92–95):
```elixir
test "off-palette hex gate: no unlisted #rrggbb literals in operator templates" do
  for path <- @component_paths ++ @live_template_paths ++ @detail_template_paths do
    content = File.read!(path)
    # ... assertions
  end
end
```

**Allowlist parse pattern** (D-06; scan `brandbook/tokens/tokens.css` at test time):
```elixir
# Parse the ~31 #rrggbb hex literals from brandbook/tokens/tokens.css
tokens_css = File.read!("brandbook/tokens/tokens.css")
allowlist =
  Regex.scan(~r/#([0-9a-fA-F]{6})\b/, tokens_css, capture: :first)
  |> List.flatten()
  |> MapSet.new()

# Fail closed: guard parse so an empty/broken tokens.css fails explicitly
assert MapSet.size(allowlist) >= 31,
  "tokens.css hex parse returned only #{MapSet.size(allowlist)} tokens — expected ≥ 31"
```

**Exception set** (D-07; declared as a named module attribute, not bare literals):
```elixir
# Operator-specific exceptions — each has a rationale in
# brandbook/notes/operator-audit-matrix.md GUARD-04 exception section
@palette_exceptions MapSet.new([
  "#7FB4C6",   # dark --po-link (lightened Watch Blue for AA on dark surfaces)
  "#A8D0DE",   # dark link-hover / accent-strong
  "#1A5066",   # light link-hover / accent-strong (darkened Watch Blue)
  "#556B77",   # dark chip-neutral-border
  "#8C2E27"    # destructive-hover (darkened Incident Red)
])
```

**Scan + assert pattern** (D-06/D-09; 6-digit only):
```elixir
found_hexes = Regex.scan(~r/#[0-9a-fA-F]{6}/, content, capture: :first) |> List.flatten()
effective_allowlist = MapSet.union(allowlist, @palette_exceptions)

for hex <- found_hexes do
  assert MapSet.member?(effective_allowlist, String.upcase(hex)),
    "Off-palette hex #{hex} found in #{path} — add to tokens.css or GUARD-04 exception list"
end
```

---

### `test/parapet/operator_ui_motion_test.exs` (test, transform)

**Analog:** `test/parapet/operator_ui_contrast_test.exs` lines 118–125, 232–233

**Module header** (same convention):
```elixir
defmodule Parapet.OperatorUIMotionTest do
  use ExUnit.Case, async: true
end
```

**Path attributes** — reuse `@component_paths` pointing to both template and demo mirror (same as contrast test lines 4–7).

**Existing motion assertions to migrate/replicate** (`operator_ui_contrast_test.exs` lines 118–125, 232–233):
```elixir
# MOTION-01: motion tokens wired
assert content =~ "--motion-fast"
assert content =~ "--motion-base"
assert content =~ "--motion-ease"
# MOTION-01: motion zeroed under prefers-reduced-motion
assert content =~ "prefers-reduced-motion"
assert content =~ "--motion-fast: 0ms"
# MOTION-03: keyframe reveal
assert content =~ "@keyframes po-preview-reveal"
assert content =~ "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"
```

**New assertions for this test** (D-10/D-11; both additions):
```elixir
# D-10: brand easing curve — whitespace/leading-zero-tolerant regex (NOT a literal string)
# Template uses cubic-bezier(.2, 0, 0, 1); tokens.css uses cubic-bezier(0.2, 0, 0, 1)
assert content =~ ~r/cubic-bezier\(\s*0?\.2\s*,\s*0\s*,\s*0\s*,\s*1\s*\)/

# D-11: BOTH motion tokens must be zeroed under reduced-motion block
assert content =~ "--motion-fast: 0ms"
assert content =~ "--motion-base: 0ms"
# (These are at operator_components.ex.eex lines 468–469)
```

**Existing refute** (`operator_ui_contrast_test.exs` line 143):
```elixir
# MOTION-02: no transition-all
refute content =~ "transition-all"
assert content =~ "duration-[--motion-fast]"
```

---

### `test/support/operator_ui_paths.ex` (utility, N/A)

**Analog:** `test/support/concurrency_repo.ex` (module shape) + `test/support/concurrency_case.ex` (namespace pattern)

**Module structure** (`concurrency_repo.ex` lines 1–3, `concurrency_case.ex` lines 1–2):
```elixir
defmodule Parapet.TestSupport.OperatorUIPaths do
  @moduledoc false
end
```

**Path constants pattern** — modeled on `operator_ui_contrast_test.exs` module attributes (lines 4–7, 237–245) but promoted to shared functions:
```elixir
def component_paths do
  [
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex",
    "priv/templates/parapet.gen.ui/operator_components.ex.eex"
  ]
end

def live_template_paths do
  [
    "priv/templates/parapet.gen.ui/operator_live.ex.eex",
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
  ]
end

def detail_template_paths do
  [
    "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
    "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
  ]
end
```

**No `use ExUnit.CaseTemplate`** — this is a plain module (not a test case template), analogous to `concurrency_repo.ex` which is just a plain module in `test/support/`.

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (D-03 fix)

**The defect** (lines 1428 and 1442): `<%#- D-07 … %>` and `<%#- D-08 … %>` are EEx build-time comments that render to the empty string, so the generated file is missing the comments the committed mirror has.

**Template lines 1428 and 1442 (current — defective):**
```eex
<%#- D-07: risk chip — color + icon + label, never color alone (WCAG 1.4.1) %>
...
<%#- D-08: single status chip — audit outcome derived honestly from state, color via state_color (no redundant raw-state pill) %>
```

**Mirror lines 1428 and 1442 (reference — what must be reproduced):**
```elixir
<%# D-07: risk chip — color + icon + label, never color alone (WCAG 1.4.1) %>
...
<%# D-08: single status chip — audit outcome derived honestly from state, color via state_color (no redundant raw-state pill) %>
```

**Fix pattern** (D-03): replace `<%#-` (EEx build-time comment, renders to empty) with `<%%#` (EEx escape, renders to `<%#`), OR if the Elixir version in use warns that `<%#` is deprecated, use `<%!-- … --%>` in both template and mirror. The goal is that `Mix.Tasks.Parapet.Gen.Ui.igniter(test_project(app_name: :demo_app))` produces content containing the same comment text as the mirror.

**Escaped EEx comment syntax:**
```
<%%# D-07: risk chip — color + icon + label, never color alone (WCAG 1.4.1) %>
```
This emits `<%# D-07: … %>` in the generated file, matching the mirror exactly.

---

### `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` (D-14 refactor)

**Current capture list** (lines 69–88, the 15 `capture …` calls to refactor into a shared list):
```bash
capture "operator-response-desktop" "1440,1100" "/parapet" "light"
capture "operator-actions-desktop"  "1440,1100" "/parapet/actions" "light"
capture "operator-history-desktop"  "1440,1100" "/parapet/history" "light"
capture "operator-detail-desktop"   "1440,1100" "/parapet/incidents/$DETAIL_ID" "light"
capture "operator-response-dark-desktop" "1440,1100" "/parapet" "dark"
capture "operator-detail-dark-desktop"   "1440,1100" "/parapet/incidents/$DETAIL_ID" "dark"

capture "operator-response-mobile"      "390,844" "/parapet" "light"
capture "operator-actions-mobile"       "390,844" "/parapet/actions" "light"
capture "operator-history-mobile"       "390,844" "/parapet/history" "light"
capture "operator-detail-mobile"        "390,844" "/parapet/incidents/$DETAIL_ID" "light"
capture "operator-response-dark-mobile" "390,844" "/parapet" "dark"

capture "gallery-desktop-light" "1440,5200" "/parapet/_gallery" "light"
capture "gallery-desktop-dark"  "1440,5200" "/parapet/_gallery" "dark"
capture "gallery-mobile-light"  "414,7600"  "/parapet/_gallery" "light"
capture "gallery-mobile-dark"   "414,7600"  "/parapet/_gallery" "dark"
```

**Refactor target** (D-14): extract to a bash array where each element encodes `name|size|path|theme`, then a single dispatch loop replaces the 15 duplicated `capture` calls. The `--manifest` mode iterates the same array and prints a Markdown table instead of invoking Chrome.

**`--manifest` dispatch pattern** (D-14/D-15/D-17):
```bash
# At top of script, parse --manifest flag
MANIFEST_MODE=false
[[ "${1:-}" == "--manifest" ]] && MANIFEST_MODE=true

# Shared capture list (bash array — one entry per screenshot)
CAPTURES=(
  "operator-response-desktop|1440,1100|/parapet|light"
  "operator-actions-desktop|1440,1100|/parapet/actions|light"
  # … all 15 entries …
  "gallery-mobile-dark|414,7600|/parapet/_gallery|dark"
)

if $MANIFEST_MODE; then
  echo "| name | route | viewport | theme |"
  echo "|---|---|---|---|"
  for entry in "${CAPTURES[@]}"; do
    IFS='|' read -r name size path theme <<< "$entry"
    echo "| $name | $path | ${size/,/×} | $theme |"
  done
  echo ""
  echo "Total: ${#CAPTURES[@]} captures"
  exit 0
fi

# Normal mode: require Chrome + server, then iterate same list
for entry in "${CAPTURES[@]}"; do
  IFS='|' read -r name size path theme <<< "$entry"
  capture "$name" "$size" "$path" "$theme"
done
```

**Existing `capture()` function** (lines 47–67) — keep as-is; only the call-site block changes.

**Guard** (D-14): `--manifest` mode exits before Chrome/server checks so it needs no DB, no server, no Chrome (cheap CI-enforceable).

---

### `examples/demo_app/scripts/operator-ui-baseline.md` (doc/manifest)

**Analog:** `v1.5-MILESTONE-AUDIT.md` Verification Commands block (lines 106–136) — same "bash-runnable + human-readable evidence" pattern.

**Structure** (D-15/D-16):
```markdown
# Operator UI Screenshot Baseline

Generated by `capture_operator_ui_screenshots.sh --manifest`.
**Total: 15 captures.**

| name | route | viewport | theme | scenario |
|---|---|---|---|---|
| operator-response-desktop | /parapet | 1440×1100 | light | stress |
| … | … | … | … | … |

## Re-run & compare

1. Seed: `cd examples/demo_app && PARAPET_DEMO_SCENARIO=stress mix run priv/repo/seeds.exs`
2. Start: `mix phx.server`
3. Capture: `bash examples/demo_app/scripts/capture_operator_ui_screenshots.sh <out_dir>`
   (PNGs land in `<out_dir>/` — **never commit PNGs**)
4. Compare: for each row above, verify PNG exists, has correct viewport/theme,
   and eyeball layout matches expectations.
5. Update baseline: re-run `--manifest` and commit the regenerated `.md` only.

## CI manifest-drift check

`bash examples/demo_app/scripts/capture_operator_ui_screenshots.sh --manifest | diff - examples/demo_app/scripts/operator-ui-baseline.md`
```

---

### `.planning/milestones/v1.6-MILESTONE-AUDIT.md` (doc/audit)

**Analog:** `.planning/milestones/v1.5-MILESTONE-AUDIT.md` (complete read above) + `v1.4-MILESTONE-AUDIT.md` (lines 1–80 read above)

**YAML frontmatter** (v1.5 lines 1–21):
```yaml
---
milestone: v1.6
milestone_name: Operator UI Brand & Design-System Audit
audited: 2026-06-28T…Z
status: passed
scores:
  requirements: N/N
  phases: 7/7
  integration: N/N
  flows: N/N
gaps:
  requirements: []
  integration: []
  flows: []
tech_debt: []
nyquist:
  compliant_phases: [44, 45, 46, 47, 48, 49, 50]
  partial_phases: []
  missing_phases: []
  overall: compliant
---
```

**Section order** (v1.5 structure, extended for v1.6 additions per D-18):
```
# Milestone v1.6 Audit: Operator UI Brand & Design-System Audit

**Status:** passed
**Audited:** YYYY-MM-DD
**Scope:** Phases 44–50

## Summary
## Requirements Coverage
## Phase Verification
## Non-Regression Proofs
## Idempotence Proof
## Font Package-Size Delta
## Verification Commands
## Result
```

**Requirements Coverage table columns** (D-19):
```markdown
| Requirement | Phase | Claim | Evidence (command or file:line) | Status |
```
One row per TOKEN/FONT/COMP/NAV/DATA/GROUP/FLOW/COPY/A11Y/MOTION/GALLERY/FIXTURE/GUARD id.

**Non-Regression Proofs section** (D-20 — three proofs):
- public-API: `mix verify.public_api` exit 0 against `priv/parapet/public_api_stable.json`
- host-ownership: `operator_ui_compile_out_test.exs` + `operator_ui_integration_test.exs` + `parapet.gen.ui.ex:43,54,65` `on_exists: :skip` grep
- telemetry: `mix test test/telemetry_contract_test.exs` exit 0

**Idempotence Proof section** (D-22):
- `mix parapet.gen.ui --dry-run` → zero file changes (cite `parapet.gen.ui.ex:74` + Igniter `super/1`)
- three `on_exists: :skip` sites = forward-only, host markup never overwritten
- audit-matrix ledger cells advance `todo→done→verified` only

**Font Package-Size Delta section** (D-23):
- absolute: ≈52.2 KB across 5 woff2 files (machine-checked by `operator_ui_fonts_test.exs`)
- tarball delta: `mix hex.build` `Package size` pre-v1.6 vs post (the publish-payload number)

**Verification Commands block style** (v1.5 lines 106–136): fenced bash block with comment headings, expected output as `# Expected: …` inline, then a pasted-output block with actual results.

---

## Shared Patterns

### `async: true` + flat module name
**Source:** All `operator_ui_*` test files (`operator_ui_contrast_test.exs` line 2, `operator_ui_fonts_test.exs` line 2)
**Apply to:** All three new test files

```elixir
use ExUnit.Case, async: true
```

Module names follow the flat `Parapet.OperatorUI*Test` convention (no nesting).

### Path attribute convention (no `File.cwd!`)
**Source:** `operator_ui_contrast_test.exs` lines 4–7, `operator_ui_fonts_test.exs` line 4
**Apply to:** `operator_ui_palette_gate_test.exs`, `operator_ui_motion_test.exs`

Paths are relative strings used directly in `File.read!` — the test runner's cwd is the project root. No `Path.join(File.cwd!(), …)` anywhere in the existing tests.

```elixir
@component_paths [
  "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex",
  "priv/templates/parapet.gen.ui/operator_components.ex.eex"
]
# …
content = File.read!(path)
```

### `Parapet.TestSupport.*` namespace in `test/support/`
**Source:** `test/support/concurrency_case.ex` line 1, `test/support/concurrency_repo.ex` line 1
**Apply to:** `test/support/operator_ui_paths.ex`

```elixir
defmodule Parapet.TestSupport.OperatorUIPaths do
  @moduledoc false
  # plain module, no use/behaviour
end
```

### Igniter.Test invocation idiom
**Source:** `test/mix/tasks/parapet.gen.ui_test.exs` lines 1–12, `parapet.gen.recovery_test.exs` lines 1–10
**Apply to:** `operator_ui_parity_test.exs`

```elixir
import Igniter.Test
alias Mix.Tasks.Parapet.Gen.Ui

igniter =
  test_project(app_name: :demo_app)
  |> Ui.igniter()

content =
  Rewrite.source!(igniter.rewrite, "lib/demo_app_web/live/parapet/operator_components.ex")
  |> Rewrite.Source.get(:content)
```

### Audit doc: every claim resolves to a re-runnable artifact
**Source:** `v1.5-MILESTONE-AUDIT.md` lines 106–136 (Verification Commands), `v1.4-MILESTONE-AUDIT.md` lines 48–62 (Coverage table with Verification Evidence column)
**Apply to:** `v1.6-MILESTONE-AUDIT.md`

Every row in the Requirements Coverage table must have a `Evidence (command or file:line)` cell that is literally runnable or a `file:line` reference. No evidence cells that say "see phase N summary" without also citing a concrete artifact.

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Metadata

**Analog search scope:** `test/parapet/`, `test/mix/tasks/`, `test/support/`, `examples/demo_app/scripts/`, `.planning/milestones/`, `priv/templates/parapet.gen.ui/`
**Files scanned:** 12 source files read
**Pattern extraction date:** 2026-06-28
