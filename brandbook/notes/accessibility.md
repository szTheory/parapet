# Accessibility — WCAG AA Contrast Matrix

**Scope:** every text-on-surface token pairing in the Parapet palette, plus the focus ring and key non-text/UI pairings. Targets per WCAG 2.1 AA (source doc §7.1 L479, §22 L1654):

- **Normal text:** ≥ 4.5:1
- **Large text** (≥ 24px, or ≥ 18.66px bold): ≥ 3:1
- **UI components / graphics / focus indicators:** ≥ 3:1

Ratios are computed (sRGB relative luminance, WCAG formula) — not estimated. Reproduce with `python3 brandbook/notes/contrast.py` (committed alongside this file).

---

## Text on surface — all pass AA ✓

| Ratio | Verdict | Foreground → Background | Role |
|---:|---|---|---|
| 16.31 | AA | Parapet Black `#101820` → Limestone `#F8F4EC` | body text / main bg |
| 13.91 | AA | Parapet Black `#101820` → Mortar `#EAE2D4` | text on cards |
| 11.70 | AA | Parapet Black `#101820` → Stone `#D8D0C3` | text on stone fills |
| 17.89 | AA | Parapet Black `#101820` → white `#FFFFFF` | docs text |
| 16.31 | AA | Limestone `#F8F4EC` → Parapet Black `#101820` | inverse / hero |
| 14.57 | AA | Limestone `#F8F4EC` → Deep Slate `#18232B` | admin shell text |
| 12.42 | AA | Mortar `#EAE2D4` → Deep Slate `#18232B` | code-block text (§7.5 L544) |
| 10.45 | AA | Stone `#D8D0C3` → Deep Slate `#18232B` | muted text on dark |
| 5.40 | AA | Watch Blue `#256C82` → Limestone `#F8F4EC` | links |
| 5.92 | AA | Watch Blue `#256C82` → white `#FFFFFF` | links on white |
| 4.60 | AA | Watch Blue `#256C82` → Mortar `#EAE2D4` | links on cards *(thin margin — see note 1)* |
| 4.58 | AA | Beacon Amber `#B45309` → Limestone `#F8F4EC` | warning on light *(thin margin)* |
| 5.02 | AA | Beacon Amber `#B45309` → white `#FFFFFF` | warning on white |
| 5.02 | AA | Beacon Amber Light `#D97706` → Deep Slate `#18232B` | warning on dark |
| 4.96 | AA | Budget Moss `#567236` → Limestone `#F8F4EC` | success |
| 5.45 | AA | Budget Moss `#567236` → white `#FFFFFF` | success on white |
| 5.44 | AA | Incident Red `#B13A32` → Limestone `#F8F4EC` | burn |
| 5.96 | AA | Incident Red `#B13A32` → white `#FFFFFF` | burn on white |
| 4.72 | AA | Trace Violet `#6D5BD0` → Limestone `#F8F4EC` | AI accent |
| 5.18 | AA | Trace Violet `#6D5BD0` → white `#FFFFFF` | AI accent on white |

### Status color sets (text → background) — all pass AA ✓
| Ratio | Verdict | Pair | Status |
|---:|---|---|---|
| 6.69 | AA | `#3F5E28` → `#EFF6E8` | Healthy |
| 6.18 | AA | `#92400E` → `#F8EFD7` | Watch |
| 6.16 | AA | `#9F2D2D` → `#FCE8E2` | Burning |
| 7.47 | AA | `#7F1D1D` → `#F8D7D4` | Exhausted |
| 10.10 | AA | `#2E3A42` → `#ECEFF1` | Unknown |
| 6.50 | AA | `#4F46A5` → `#ECEBFF` | AI Assist |

**Result:** 100% of text pairings meet WCAG AA. The palette is sound for the brand book and product UI as specified — no recoloring needed.

---

## Non-text / UI components (need 3:1)

| Ratio | Verdict | Pair |
|---:|---|---|
| 5.40 | PASS | Focus ring Watch Blue `#256C82` vs Limestone `#F8F4EC` |
| 5.92 | PASS | Focus ring Watch Blue `#256C82` vs white `#FFFFFF` |
| **2.70** | **FAIL** | **Focus ring Watch Blue `#256C82` vs Deep Slate `#18232B`** |
| 1.61 | (decorative) | `--border-light` ≈ `#C9C2B4` vs Limestone `#F8F4EC` |

---

## Findings & rules

**Finding 1 — Focus ring fails on dark surfaces (actionable).**
The source doc's recommended focus ring (`outline: 2px solid #256C82`, §22.2 L1665) measures **2.70:1 against Deep Slate `#18232B`** — below the 3:1 minimum for focus indicators. On the admin shell (Deep Slate) and any dark surface, Watch Blue is **not** a sufficient focus indicator.
→ **Rule:** use a **light focus ring on dark surfaces** — `outline: 2px solid #F8F4EC` (Limestone, 14.57:1 on Deep Slate) or a lightened blue. Keep `#256C82` only on light surfaces. This is encoded as `--focus-ring` (light) and `--focus-ring-on-dark` in `tokens.css` (Phase 42).

**Finding 2 — Thin-margin pairs (use at body size or larger, avoid for tiny text).**
`Watch Blue → Mortar` (4.60), `Beacon Amber → Limestone` (4.58), and `Trace Violet → Limestone` (4.72) clear AA but with little headroom. Keep them at Body (16px) or larger; do **not** use these specific pairs for Caption (12px) where AA is most fragile. Prefer Watch Blue on Limestone/white for links; reserve `Beacon Amber #B45309` for light backgrounds and switch to `Beacon Amber Light #D97706` only on dark (§7.6 L570).

**Finding 3 — Borders are intentionally decorative, not load-bearing.**
`--border-light` (~1.6:1) is below 3:1 by design (§9.4 "rely more on borders than heavy shadows," low-contrast hairlines). This is acceptable **only because** component boundaries are never communicated by the border alone — surfaces also differ in fill (Mortar/Stone vs Limestone) and use labels/spacing. Do not use a hairline border as the *sole* indicator of an interactive boundary.

**Finding 4 — Never color alone (carry forward to every component).**
Per §22.1 (L1652) every status must pair color with a **word label + icon** (Healthy / Watch / Burning / Exhausted / Unknown). The brand book's component examples (Phase 43) must demonstrate this — a colored chip with text, not a bare colored dot.

---

## Logo implication (feeds Phase 41 acceptance)

The favicon/logomark must be legible at 16px and survive **single-ink monochrome** — i.e. identity cannot depend on color contrast between two brand colors that may collapse when printed one-color. Phase 41's gallery proves each direction in mono + at 16px before selection.

---

*Computed 2026-06-23 for v1.5 (Phase 40, BRAND-02). Method: WCAG 2.1 relative-luminance contrast; see `brandbook/notes/contrast.py`.*
