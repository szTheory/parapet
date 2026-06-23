# Parapet Brand Reference (distilled)

**Source of truth:** [`prompts/parapet-brand-identity-deep-research.md`](../../prompts/parapet-brand-identity-deep-research.md) (1,874 lines).
This file distills the **load-bearing** values needed to build the brand book and logo system. Every value is copied verbatim with a line citation — **nothing here is re-derived or invented**. When in doubt, the source doc wins.

> Citations use `§N` for the source section and `L#` for line numbers in the source doc.

---

## 1. What Parapet is (positioning) — §1–2, §18

- **Category:** open-source **Phoenix reliability layer / SRE toolkit** — *not* an observability backend, APM, monitoring tool, or security/compliance platform. (§2.5 L59–77, §18.2 L1463–1472)
- **One-line positioning:** "Parapet is the Phoenix reliability layer that turns telemetry into SLOs, evidence, and calm operational action." (§2.1 L41)
- **Brand thesis:** "A Phoenix SaaS can briefly hurt users, but not silently, not confusingly, and not without leaving evidence, a mitigation path, and a learning loop." (§2.4 L55)
- **Metaphor:** a parapet = a **protective low wall at an edge** that gives operators sightlines and prevents silent harm — **not "fortress software."** "A parapet protects without getting in the way." (§1 L16)
- **Differentiating phrase:** "Parapet is not where telemetry goes to be stored. It is where telemetry becomes operational evidence." (§18.4 L1493)

**Should feel** (L18–24): calm, precise, protective · Phoenix-native, developer-respectful · evidence-first, not dashboard-first · operationally mature without enterprise bloat · open-source, practical, humane.
**Should NOT feel** (L26–33): militaristic · medieval/castle-themed · generic SaaS observability · noisy/neon/"war room" theatrical · like an APM vendor · like a security/compliance/risk platform.

**Archetype:** primary **The Guardian**, secondary **The Field Engineer** — "a field engineer standing at the edge of the roof with a clipboard, a level, and a calm voice." (§4.2 L183–186)

---

## 2. Visual concept — §6.1

Built from four ideas (L364–369): **edge · sightline · masonry · signal.**
Look like (L371–381): roofline at dawn · cut stone · measured diagrams · thin gridlines · annotated thresholds · amber beacons · quiet slate panels · runbook pages · incident timelines.
Do **not** look like (L383–390): a castle game · a cybersecurity shield brand · a Grafana clone · a neon terminal · a dark-mode crypto dashboard · a medieval fantasy product.

---

## 3. Logo directions — §6.2–6.3

Must work as (L394–401): GitHub avatar · Hex package icon · favicon · docs header mark · LiveDashboard/admin icon · monochrome stamp.

**Four named symbol directions** (L405–419):
1. **Stepped parapet mark** — a horizontal roofline with two or three rectangular rises; negative space implies protected openings / signal windows. (L405–407)
2. **P-as-parapet monogram** — a geometric **P** where the bowl or stem contains a stepped edge; good for package avatars. (L409–411)
3. **Edge and sightline** — a low wall at the bottom with a single line/horizon above it; emphasizes *seeing over the edge* rather than hiding behind a fortress. (L413–415)
4. **Signal slot** — a rectangular cut/notch in a wall shape with a small signal line passing through it; ties to telemetry and evidence. (L417–419)

> "A small stepped wall is good. A castle is too much." (L438)

**AVOID logo directions** (L421–436): full castles · turrets · swords · shields as the main symbol · eyes · radar circles · generic heartbeat lines · flame icons · skulls · sirens · mascots · medieval type.

**Wordmark qualities** (§6.3 L454–461): sturdy · slightly condensed or neutral · **not** rounded-cute · **not** aggressively geometric · **not** serif-only · **no** faux-medieval letterforms. Written brand is **Parapet** (Title Case); lowercase `parapet` only for package/CLI/URL/code. (§3.1 L85–93)

---

## 4. Color system — §7, §23 (verbatim)

### Core palette (§7.2 L483–495)
| Token | Hex | Role |
|---|---|---|
| Parapet Black | `#101820` | Primary dark — headers, dark surfaces, primary text on light |
| Deep Slate | `#18232B` | Secondary dark — admin shell, nav, dark cards |
| Wall Slate | `#2E3A42` | Structural neutral — borders on dark, secondary panels |
| Stone | `#D8D0C3` | Warm neutral — dividers, diagrams, disabled fills |
| Mortar | `#EAE2D4` | Soft surface — cards, doc callouts, diagrams |
| Limestone | `#F8F4EC` | Main light background — docs, marketing, empty states |
| Watch Blue | `#256C82` | Calm signal — links, selected states, info panels |
| Beacon Amber | `#B45309` | Warning on light |
| Beacon Amber Light | `#D97706` | Warning on dark |
| Budget Moss | `#567236` | Healthy budget text, success badges |
| Incident Red | `#B13A32` | Critical SLO burn, destructive states |
| Trace Violet | `#6D5BD0` | AI / correlation / "assistive" layer |

### Status colors (§7.4 L523–529)
| Status | Text | Background | Border |
|---|---|---|---|
| Healthy | `#3F5E28` | `#EFF6E8` | `#B6C99A` |
| Watch | `#92400E` | `#F8EFD7` | `#E3B66E` |
| Burning | `#9F2D2D` | `#FCE8E2` | `#E3A19A` |
| Exhausted | `#7F1D1D` | `#F8D7D4` | `#C87670` |
| Unknown | `#2E3A42` | `#ECEFF1` | `#CBD2D8` |
| AI Assist | `#4F46A5` | `#ECEBFF` | `#B9B5F6` |

### Color rules (§7.6 L556–571)
- **Do:** red only for real user harm / destructive / fast-burn; amber for watch/caution; blue for nav/links/selected/calm insight; violet **only** for AI/trace (keep it an assistive layer, never core identity); moss for budget health; warm neutrals to feel less clinical.
- **Don't:** red for ordinary validation errors; multicolor every chart; rainbow dashboards; amber text on light bg unless using the darker amber token.

### Background rules (§7.5 L533–552)
- Marketing: Limestone bg · hero contrast block Parapet Black/Deep Slate · dividers Mortar/Stone · accent Watch Blue or Beacon Amber.
- Docs: Limestone or white bg · Parapet Black text · **code blocks = Deep Slate bg with Mortar text** · callouts = Mortar bg with status-colored left border.
- Admin: Deep Slate shell · Limestone/white content · operational panels white/Mortar · critical evidence = restrained Incident Red accents, **never full-page red.**

---

## 5. Typography — §8

- **Sans (UI/docs):** IBM Plex Sans — "more distinctive field-manual/editorial feel than the more common Inter-based SaaS look." (§8.2 L601)
- **Mono (code/metrics/IDs):** IBM Plex Mono.
- **Serif (optional editorial accent):** IBM Plex Serif.
- **All open-source** — no licensing concern. (§8.1 L591)

**Stacks (verbatim, §8.2 L603–605):**
```css
--font-sans: "IBM Plex Sans", Inter, ui-sans-serif, system-ui, sans-serif;
--font-mono: "IBM Plex Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace;
--font-serif: "IBM Plex Serif", Georgia, serif;
```

**Type scale (§8.3 L609–619):**
| Token | Size | Line height | Weight | Usage |
|---|---|---|---|---|
| Display | 56px | 1.00 | 500 | Homepage hero only |
| H1 | 40px | 1.08 | 500 | Page titles |
| H2 | 30px | 1.16 | 500 | Major sections |
| H3 | 22px | 1.25 | 500 | Cards, docs sections |
| Body | 16px | 1.60 | 400 | Main reading |
| Body Small | 14px | 1.50 | 400 | UI copy, table text |
| Caption | 12px | 1.40 | 500 | Labels, metadata |
| Code | 13px | 1.55 | 400 | Inline/log/code |
| Metric Large | 36px | 1.00 | 500 | SLO card numbers |
| Metric Small | 20px | 1.10 | 500 | Table metrics |

Use mono for: deploy SHAs, route names, metric names, labels, timestamps, incident IDs, CLI, SLO specs, generated rules. (§8.5 L639–649)
Headlines = "engineering statements, not ads." (§8.4 L623)

---

## 6. Layout tokens — §9, §23 (verbatim)

**Spacing — 8px grid (§9.2 L678–685):** `--space-1:4px` `-2:8px` `-3:12px` `-4:16px` `-5:24px` `-6:32px` `-7:48px` `-8:64px`.
**Radius (§9.3 L691–695):** `--radius-xs:4px` `-sm:6px` `-md:10px` `-lg:14px` `-xl:20px`. Rules (L699–703): cards 10px · buttons 8px · badges 999px pill (compact status only) · modals 14px · avoid bubbly 24px+ on core components.
**Borders > shadows (§9.4 L707–719):**
```css
--border-light: 1px solid rgba(16, 24, 32, 0.12);
--border-dark:  1px solid rgba(248, 244, 236, 0.16);
--shadow-card:    0 1px 2px rgba(16, 24, 32, 0.06);
--shadow-popover: 0 12px 32px rgba(16, 24, 32, 0.16);
```
"Avoid glossy SaaS shadows and dramatic floating cards." (L719)

---

## 7. Iconography & imagery — §11

- Line icons, **1.5–2px stroke**, squared-off (not harsh) corners, simple silhouettes, **no filled emoji-style icons.** (§11.4 L953–959)
- Illustration: thin-line architectural drawings, simple block forms, cutaway diagrams, warm paper backgrounds, subtle grid overlays, minimal color accents — "engineering documentation with taste, not startup cartoons." (§11.2 L928–937)
- Imagery: rooflines, low protective walls, architectural sections, masonry diagrams, survey marks, annotated plans, dawn/dusk skylines, signal lights. (§11.1 L912–924)
- Avoid (icons): sirens · skulls · flames · shields everywhere · medieval weapons · castle towers · eyeballs · robot mascots. (§11.4 L973–982)

---

## 8. Voice & microcopy — §5, §13 (the parts the brand book renders)

**Sounds** (§5.1 L230–238): calm · direct · specific · technically literate · humane · lightly opinionated · evidence-backed.
**Does NOT sound** (L240–248): panicked · salesy · cute · macho · mystical · blameful · enterprise-generic.

**Voice formula for operational messages (§5.5 L342–348):**
`[User-facing symptom] → [Measured evidence] → [Likely correlation] → [Safe next action] → [Where to inspect].`

**Preferred vocabulary (§5.4 L294–312):** evidence · journey · guardrail · budget · burn rate · sightline · signal · calm · surface · correlate · classify · mitigate · learn · runbook · timeline · wide event · doctor check.
**Avoid as brand flavor (L326–338):** war room · battle-tested · mission control · panic · chaos monkey · magic · autopilot · black box · total visibility · **single pane of glass** · military-grade.

**Microcopy exemplars to render in the book:**
- *Empty state* (§13.1 L1098–1099): "No journeys protected yet. Define one user journey to create its SLO, dashboard panel, and runbook."
- *Good button labels* (§13.3 L1136–1143): Open runbook · View evidence · Mark as investigating · Attach deploy · Generate rules · Run doctor.
- *Avoid button labels* (L1147–1152): Fix it · Resolve everything · Autopilot · Magic analyze · Panic · Kill process.
- *Error pattern* (§13.5 L1174–1176): `[What happened] → [Why it matters] → [How to fix it]`.

**Taglines (§3.4):** primary "A protective edge for Phoenix reliability." (L140); homepage hero "See user harm before it becomes chaos." (L144). **Do NOT use** (L158–164): "The ultimate observability platform" · "AI-powered incident response" · "Military-grade reliability" · "Your command center for production" · "Stop outages forever."

---

## 9. Accessibility rules — §22 (drives `accessibility.md`)

- Never rely on color alone for status; pair with labels + icons. (L1652–1653)
- Maintain **WCAG AA** contrast for text (4.5:1 normal, 3:1 large; 3:1 for UI components/graphics). (§7.1 L479; §22 L1654)
- Visible `:focus-visible` state — recommended `outline: 2px solid #256C82; outline-offset: 2px;` (§22.2 L1665–1668). *(See `accessibility.md` — this ring fails 3:1 on Deep Slate and needs a light variant on dark surfaces.)*
- Status labels are words, not colors: Healthy / Watch / Burning / Exhausted / Unknown. (§22.3 L1674–1678)
- Respect reduced-motion; motion should orient/confirm/reveal, never dramatize. (§21 L1614–1644)

---

## 10. Brand guardrails — §25 (the "ship test")

**Always** (L1794–1803): lead with user journeys · prefer SLOs over alert piles · show evidence before recommendations · keep AI clearly labeled · inspectable artifacts · keep the interface calm.
**Never** (L1807–1816): claim to prevent all incidents · hide generated rules · use medieval/fantasy theming · use red as decoration · use "single pane of glass" · sound like enterprise compliance software.

---

*Distilled 2026-06-23 for the v1.5 Brand Book & Logo System milestone (Phase 40, BRAND-01). No values invented; all cited to the source doc.*
