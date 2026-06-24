# Decision Log — v1.5 Brand Book & Logo System

Running record of brand/logo decisions for this milestone. Newest entries appended.

---

## D-001 — The existing logo/favicon are off-brand (anti-criteria)

**Date:** 2026-06-23 (Phase 40, BRAND-03)
**Status:** Confirmed — these assets are replaced in Phase 43.

The only marks currently shipping are [`docs/assets/parapet-logo.svg`](../../docs/assets/parapet-logo.svg) (wired into HexDocs via `mix.exs` `logo:`) and [`docs/assets/favicon.svg`](../../docs/assets/favicon.svg) (`favicon:`). Audited against the brand research doc, they violate the brand on **five** counts. These become explicit **anti-criteria** the new system must not repeat:

| # | Defect in current asset | Brand rule it breaks | Source |
|---|---|---|---|
| A1 | **Rectangular background "cage"** — `<rect ... rx="8"/>` / `rx="12"` filled `#0f172a` behind the mark | Mark must be background-free; "Do NOT force the logomark into a rectangular background." | User constraint; §6.2 (transparent stamp use) |
| A2 | **Off-palette colors** — `#0f172a` (Tailwind slate-900) bg, `#38bdf8` (Tailwind sky-400) stroke, `#94a3b8`, `#f8fafc` | None of these are Parapet tokens. Palette is "warm stone + deep slate + measured signal," not Tailwind sky-on-navy. | §7.2 L483–495; §7.1 L471 |
| A3 | **Wrong typeface** — wordmark set in `Arial, Helvetica, sans-serif` | Wordmark must be IBM Plex Sans, "sturdy, slightly condensed or neutral… no faux letterforms." | §8.1 L581; §6.3 L454–461 |
| A4 | **Detached lockup** — icon sits far left of plain text, no shared geometry | Mark + type must read as one unit, not "a random icon to the left of plain text." | User constraint; §6.2 |
| A5 | **Neon/dark-dashboard feel** — bright sky-blue strokes on near-black | Must not "look like a neon terminal / dark-mode crypto dashboard." | §6.1 L383–390 |

**Why it matters:** the off-brand mark is the *first* visual a HexDocs/GitHub visitor sees. It currently advertises a generic dark-SaaS aesthetic that contradicts the calm, warm-stone, architectural brand. Fixing it is the single highest-leverage brand act in this milestone.

---

## D-002 — Frozen logo acceptance checklist

**Date:** 2026-06-23 (Phase 40, BRAND-03)
**Status:** Frozen. Every Phase 41 direction is judged against this; the winner must pass all of it.

A logo direction is **acceptable** only if:

- [ ] **Transparent** — no background fill; no full-viewBox `<rect>`. Backgrounds appear only as gallery preview swatches, never inside the asset. *(fixes A1)*
- [ ] **Palette-locked** — every color is a Parapet token (`research.md` §4). No Tailwind/off-palette hex. *(fixes A2)*
- [ ] **On-brand type** — any wordmark is IBM Plex Sans, converted to **outlined paths** (font-independent), sturdy/neutral, not rounded-cute, not faux-medieval. *(fixes A3)*
- [ ] **Unified mark + type** — mark and wordmark share one viewBox + baseline and a bridging element (base rule / sightline); gap ≤ ½ mark-width. Not "icon far from text." *(fixes A4)*
- [ ] **Calm, architectural, not neon** — reads as cut stone / roofline / sightline, never a glowing dashboard. *(fixes A5)*
- [ ] **No primary subtitle** — the primary lockup carries no tagline/slogan. A tagline lives only in a separate optional lockup. *(user constraint)*
- [ ] **≥1 fully-integrated typemark** in the option set — the parapet motif worked *into* the wordmark itself, not beside it. *(user constraint)*
- [ ] **On-metaphor, off the AVOID list** — grounded in stepped-wall / P-monogram / edge+sightline / signal-slot; never castle, turret, sword, shield, eye, radar, heartbeat, flame, skull, siren, mascot, medieval. *(§6.2 L421–436)*
- [ ] **Survives reduction** — legible as a 16px favicon and in single-ink **monochrome** (identity not dependent on multi-color contrast). *(§6.2 L394–401; `accessibility.md` Finding/logo implication)*
- [ ] **Repo-lean** — hand-authored, optimized SVG, ≤ ~8 KB, no editor cruft/metadata bloat.

---

## D-003 — Logo direction selection

**Date:** 2026-06-24 (Phase 41, LOGO-04) · **Status:** LOCKED. Gate cleared; Phase 42 unblocked.

**Chosen:** a **stacked emblem** — a **corbelled parapet tower** mark above the wordmark **PARAPET** set in **Space Grotesk** (600, tight caps), with a single **Watch Blue `#256C82`** arrow-slit/loophole as the only accent. The tower's *projecting crenellated top* is a literal parapet (and reads as a chess rook); it works **standalone** as the avatar/favicon and **stacked** as the full lockup.

**How we got here (6 rounds — see `logo-options.html`, `logo-round-2..6.html`):**
1. Round 1 (A/B/C/D, icon-beside-text) — rejected: not integrated.
2. Round 2 (carved-crenellation wordmark) — picked "Rook P lead".
3. Round 3 (9 rook-P variants) — rejected: hand-built rectangle letters read as crude "8-bit/Atari" graphics; R confused with A; too samey. **Lesson: don't hand-build letterforms.**
4. Round 4 (real OFL typefaces, 6 fresh directions) — user liked the **rook tower** concept; font/lockup/sizing still off.
5. Round 5 (refined corbelled tower × font/layout/sizing) — user picked the **stacked emblem**.
6. Round 6 (deep stacked-emblem tournament) — user locked **S2: Space Grotesk tight caps.**

**Type/asset strategy:** Space Grotesk is OFL (shippable). The wordmark is **outlined to paths** (via fonttools from the woff2) so every asset is **font-independent** — no font binary committed, renders identically in HexDocs. Deviates from the research doc's IBM Plex Sans for the logo per the user's explicit permission to change fonts; IBM Plex Sans/Mono/Serif remain the **UI/docs/code** typefaces in the brand book.

**Final asset set (`brandbook/assets/`):** `parapet-logo.svg` (primary stacked) · `parapet-inverse.svg` · `parapet-mono.svg` · `parapet-horizontal.svg` (+ `-inverse`) · `parapet-mark.svg` (+ `-inverse`) · `favicon.svg`. All transparent, palette-locked, no background cage, no subtitle on the primary. Colors: Parapet Black `#101820` ink, Watch Blue `#256C82` loophole; inverse uses Limestone `#F8F4EC` ink.

**Acceptance checklist (D-002):** all pass — transparent ✓ palette-locked ✓ on-brand type (outlined, font-independent) ✓ unified mark+type (stacked, shared axis) ✓ calm/architectural ✓ no primary subtitle ✓ integrated/own typemark ✓ on-metaphor (parapet/rook, off the AVOID list*) ✓ survives mono + 16px favicon ✓ repo-lean (≤1.8 KB each) ✓.

> *The research doc cautions against castles/turrets; the user explicitly steered toward the rook/tower and approved it. Kept restrained (a single low tower, not a fortress) to stay calm.

---

*Maintained for v1.5 Brand Book & Logo System.*
