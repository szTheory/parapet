#!/usr/bin/env python3
"""
Parapet logo generator — single source of truth for the logo assets.

The shipped SVGs in ../assets/ are hand-checked outputs of this script. It:
  1. fetches Space Grotesk 600 (OFL) — we DO NOT commit the font binary
  2. outlines the wordmark + tagline to paths (font-independent assets)
  3. draws the corbelled parapet tower mark
  4. emits every lockup variant, transparent + palette-locked

Run:  python3 logo-build.py     (needs network for the font + `pip install fonttools brotli`)

Identity: stacked emblem — corbelled parapet tower above PARAPET (Space Grotesk
tight caps), Watch Blue loophole accent. Locked in decision-log.md D-003 (round 6, S2).
"""
import os, urllib.request, tempfile
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONT_URL = "https://cdn.jsdelivr.net/npm/@fontsource/space-grotesk@5/files/space-grotesk-latin-600-normal.woff2"
ASSETS = os.path.join(os.path.dirname(__file__), "..", "assets")

BLACK = "#101820"   # Parapet Black — ink
LIME  = "#F8F4EC"   # Limestone — ink on dark
BLUE  = "#256C82"   # Watch Blue — loophole accent

# Corbelled parapet tower (native units: x7..33 w26, y9..56 h47). Loophole rect x18-22 y31-46.
TOWER = ("M13 56 V24 H27 V56 Z M7 24 V16 H33 V24 Z "
         "M7 16 V10 H12 V16 Z M16 16 V10 H24 V16 Z M28 16 V10 H33 V16 Z")
LOOP_HOLE = " M18 31 H22 V46 H18 Z"   # appended (evenodd) for the mono cut


def load_font():
    path = os.path.join(tempfile.gettempdir(), "space-grotesk-600.woff2")
    if not os.path.exists(path):
        urllib.request.urlretrieve(FONT_URL, path)
    return TTFont(path)


def outline(font, text, ls_ratio):
    """Return (svg path 'd' in font units, baseline y=0, y-up; advance width)."""
    cap = getattr(font['OS/2'], 'sCapHeight', 0) or 700
    cmap, gs, hmtx = font.getBestCmap(), font.getGlyphSet(), font['hmtx']
    ls, x, pen = ls_ratio * cap, 0.0, SVGPathPen(font.getGlyphSet())
    for ch in text:
        g = cmap[ord(ch)]
        gs[g].draw(TransformPen(pen, (1, 0, 0, 1, x, 0)))
        x += hmtx[g][0] + ls
    return pen.getCommands(), (x - ls), cap


def tower_g(ink, mono, tx, ty, sc):
    t = f'translate({tx:.3f},{ty:.3f}) scale({sc:.5f})'
    if mono:
        return f'<g transform="{t}"><path fill-rule="evenodd" fill="{ink}" d="{TOWER + LOOP_HOLE}"/></g>'
    return (f'<g transform="{t}"><path fill="{ink}" d="{TOWER}"/>'
            f'<rect x="18" y="31" width="4" height="15" fill="{BLUE}"/></g>')


def svg(vb_w, vb_h, body, label="Parapet"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vb_w} {vb_h}" '
            f'width="{vb_w}" height="{vb_h}" role="img" aria-label="{label}">{body}</svg>\n')


def main():
    f = load_font()
    WORD, ADV, CAP = outline(f, "PARAPET", 0.065)
    TAG, TADV, _ = outline(f, "RELIABILITY FOR PHOENIX", 0.18)

    def word_g(d, x, base, s):
        return f'<g transform="translate({x:.3f},{base:.3f}) scale({s:.5f},{-s:.5f})"><path fill="INK" d="{d}"/></g>'

    def stacked(ink, mono=False, cap_px=26.0):
        s = cap_px / CAP; adv = ADV * s; W = round(adv + 16, 1); cx = W / 2
        tsc = (2.0 * cap_px) / 47.0; tx = cx - 20 * tsc; ty = 8 - 9 * tsc
        base = (8 - 9 * tsc + 56 * tsc) + 14.0 + cap_px; H = round(base + 6, 1)
        body = tower_g(ink, mono, tx, ty, tsc) + word_g(WORD, cx - adv / 2, base, s).replace("INK", ink)
        return svg(W, H, body)

    def horizontal(ink, mono=False, cap_px=30.0):
        s = cap_px / CAP; adv = ADV * s; tsc = cap_px * 1.55 / 47.0; tw = 26 * tsc
        cy = cap_px * 1.55 / 2 + 8; tx = 8 - 7 * tsc; ty = cy - 32.5 * tsc
        xt = 8 + tw + cap_px * 0.55; base = cy + cap_px * 0.5
        W = round(xt + adv + 8, 1); H = round(cap_px * 1.55 + 16, 1)
        body = tower_g(ink, mono, tx, ty, tsc) + word_g(WORD, xt, base, s).replace("INK", ink)
        return svg(W, H, body)

    def mark(ink, mono=False):
        body = (f'<path fill-rule="evenodd" fill="{ink}" d="{TOWER + LOOP_HOLE}"/>' if mono
                else f'<path fill="{ink}" d="{TOWER}"/><rect x="18" y="31" width="4" height="15" fill="{BLUE}"/>')
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="4 6 32 52" width="32" height="52" '
                f'role="img" aria-label="Parapet">{body}</svg>\n')

    def tagline():
        s = 26.0 / CAP; adv = ADV * s; tsc = 52.0 / 47.0; ts = 9.0 / CAP; tadv = TADV * ts
        base = (8 - 9 * tsc + 56 * tsc) + 14.0 + 26.0; ruleY = base + 18; tagBase = ruleY + 16
        W = round(max(adv, tadv) + 24, 1); H = round(tagBase + 5, 1); cx = W / 2; half = max(adv, tadv) * 0.25
        body = (tower_g(BLACK, False, cx - 20 * tsc, 8 - 9 * tsc, tsc)
                + word_g(WORD, cx - adv / 2, base, s).replace("INK", BLACK)
                + f'<line x1="{cx-half:.1f}" y1="{ruleY:.1f}" x2="{cx+half:.1f}" y2="{ruleY:.1f}" stroke="{BLUE}" stroke-width="1.5" stroke-linecap="round"/>'
                + word_g(TAG, cx - tadv / 2, tagBase, ts).replace("INK", BLACK))
        return svg(W, H, body, "Parapet — reliability for Phoenix")

    files = {
        "parapet-logo.svg": stacked(BLACK), "parapet-inverse.svg": stacked(LIME),
        "parapet-mono.svg": stacked(BLACK, mono=True),
        "parapet-horizontal.svg": horizontal(BLACK), "parapet-horizontal-inverse.svg": horizontal(LIME),
        "parapet-mark.svg": mark(BLACK), "parapet-mark-inverse.svg": mark(LIME),
        "favicon.svg": mark(BLACK), "parapet-tagline.svg": tagline(),
    }
    for fn, s in files.items():
        open(os.path.join(ASSETS, fn), "w").write(s)
        print(f"{len(s):5d}  {fn}")


if __name__ == "__main__":
    main()
