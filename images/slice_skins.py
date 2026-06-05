"""Slice the new character skin sheets into 8 transparent directional sprites.

Each sheet has a top "8 DIRECTIONS" block (2 rows x 4 cols: N NE E SE / S SW W NW)
followed by a duplicate "DIRECTIONAL MOVEMENT" block. We use the top block only.
Backgrounds are baked-in opaque (white / gray checkerboard / pale blueprint) so we
key them out to transparency using a "light & desaturated" rule.

Outputs: sprites/skins/<skin>/<dir>.png  +  images/_preview_<skin>.png (verification).
"""
from PIL import Image
from pathlib import Path

PROJ = Path(r"C:\Users\ASUS\Jocay Surf Rush")
IMG  = PROJ / "images"
OUT  = PROJ / "sprites" / "skins"

# name -> (file, x-inset fraction to skip decorative side borders)
SKINS = {
    "silla": ("Skin_Silla.png", 0.07),
    "gamba": ("Skin_Gamba.png", 0.00),
    "ray":   ("Skin_Ray.png",   0.00),
}
DIRS = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]  # row1 then row2
TARGET_S_HEIGHT = 36  # final on-screen height of the south-facing sprite (px)


def is_content(px):
    r, g, b, a = px
    if a < 40:
        return False
    mn, mx = min(r, g, b), max(r, g, b)
    return not (mn >= 140 and (mx - mn) <= 50)  # light & gray => background


def row_bands(px, W, H, x0, x1, min_h, thr_frac):
    thr = max(3, int((x1 - x0) * thr_frac))
    bands, inb, s = [], False, 0
    for y in range(H):
        c = sum(1 for x in range(x0, x1) if is_content(px[x, y]))
        if c > thr and not inb:
            inb, s = True, y
        elif c <= thr and inb:
            inb = False
            if y - s >= min_h:
                bands.append((s, y))
    if inb and (H - s) >= min_h:
        bands.append((s, H))
    return bands


def col_bands(px, y0, y1, x0, x1, n, min_w, thr_frac):
    thr = max(2, int((y1 - y0) * thr_frac))
    bands, inb, s = [], False, 0
    for x in range(x0, x1):
        c = sum(1 for y in range(y0, y1) if is_content(px[x, y]))
        if c > thr and not inb:
            inb, s = True, x
        elif c <= thr and inb:
            inb = False
            if x - s >= min_w:
                bands.append([s, x])
    if inb and (x1 - s) >= min_w:
        bands.append([s, x1])
    while len(bands) > n:                       # merge across smallest gaps
        gaps = sorted((bands[i + 1][0] - bands[i][1], i) for i in range(len(bands) - 1))
        i = gaps[0][1]
        bands[i][1] = bands[i + 1][1]
        del bands[i + 1]
    if len(bands) != n:                         # fallback: equal quarters
        bands = [[x0 + k * (x1 - x0) // n, x0 + (k + 1) * (x1 - x0) // n] for k in range(n)]
    return [tuple(b) for b in bands]


def cutout(px, x0, y0, x1, y1, pad):
    """Tight bbox of content, returned as a transparent-bg RGBA cutout."""
    mnx, mny, mxx, mxy, found = x1, y1, x0, y0, False
    for y in range(y0, y1):
        for x in range(x0, x1):
            if is_content(px[x, y]):
                found = True
                mnx, mny, mxx, mxy = min(mnx, x), min(mny, y), max(mxx, x), max(mxy, y)
    if not found:
        return None
    mnx, mny = max(x0, mnx - pad), max(y0, mny - pad)
    mxx, mxy = min(x1, mxx + pad + 1), min(y1, mxy + pad + 1)
    out = Image.new("RGBA", (mxx - mnx, mxy - mny), (0, 0, 0, 0))
    opx = out.load()
    for y in range(mny, mxy):
        for x in range(mnx, mxx):
            p = px[x, y]
            if is_content(p):
                opx[x - mnx, y - mny] = p
    return out


for skin, (fname, inset_frac) in SKINS.items():
    img = Image.open(IMG / fname).convert("RGBA")
    W, H = img.size
    px = img.load()
    xs, xe = int(W * inset_frac), W - int(W * inset_frac)
    rbands = row_bands(px, W, H, xs, xe, min_h=int(H * 0.05), thr_frac=0.05)
    tall = [b for b in rbands if (b[1] - b[0]) >= int(H * 0.08)]
    print(f"{skin} {W}x{H}  sprite-rows={tall[:4]}")
    raw = []
    (OUT / skin).mkdir(parents=True, exist_ok=True)
    for ri, (y0, y1) in enumerate(tall[:2]):             # top block, 2 sprite rows
        cols = col_bands(px, y0, y1, xs, xe, n=4, min_w=int(W * 0.05), thr_frac=0.06)
        for ci, (cx0, cx1) in enumerate(cols):
            d = DIRS[ri * 4 + ci]
            cut = cutout(px, cx0, y0, cx1, y1, pad=2)
            if cut is None:
                print(f"   {d}: EMPTY")
                continue
            raw.append((d, cut))
    # uniform downscale (LANCZOS) so 's' is TARGET_S_HEIGHT tall, proportions preserved
    s_h = next((c.size[1] for d, c in raw if d == "s"), None) or max(c.size[1] for _, c in raw)
    factor = TARGET_S_HEIGHT / s_h
    sprites = []
    for d, c in raw:
        small = c.resize((max(1, round(c.size[0] * factor)),
                          max(1, round(c.size[1] * factor))), Image.LANCZOS)
        small.save(OUT / skin / f"{d}.png")
        sprites.append((d, small))
        print(f"   {d}: {small.size}")
    if sprites:
        cell = max(max(c.size) for _, c in sprites) + 8
        mont = Image.new("RGBA", (cell * 4, cell * 2), (40, 40, 50, 255))
        for i, (d, c) in enumerate(sprites):
            mont.alpha_composite(c, ((i % 4) * cell + (cell - c.size[0]) // 2,
                                     (i // 4) * cell + (cell - c.size[1]) // 2))
        mont.save(IMG / f"_preview_{skin}.png")
        print(f"   preview -> _preview_{skin}.png")
