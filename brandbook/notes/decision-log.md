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

**Date:** _pending — Phase 41 user-selection gate (LOGO-04)._
**Status:** OPEN. Phase 42 is blocked until this records a chosen direction.

> To be filled when the user picks from `logo-options.html`: chosen direction (A/B/C/D or blend), rationale, and any tweak instructions (color/weight/spacing).

---

*Maintained for v1.5 Brand Book & Logo System.*
