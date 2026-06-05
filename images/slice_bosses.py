"""Boss sheet slicer — ROLE pass.

Extracts the mapped rows (idle / attack / hurt / projectiles) from each boss sheet into
transparent, game-sized frames under sprites/bosses/<boss>/<role>_<i>.png, and writes a
verification montage images/_boss_<boss>.png. Row mapping was derived from the detection
montages (_boss_detect_<boss>.png).
"""
from PIL import Image, ImageDraw
from pathlib import Path

PROJ = Path(r"C:\Users\ASUS\Jocay Surf Rush")
IMG  = PROJ / "images"
OUT  = PROJ / "sprites" / "bosses"

TARGET_BOSS_H = 104   # on-screen height of a boss frame (px)
TARGET_PROJ_H = 13    # on-screen height of a projectile (px)

# boss -> { regions:[(x0f,x1f)], role:(region_letter, row_index, cell_slice|None) }
ROLE_MAP = {
    "boss1": {"regions": [(0.0, 1.0)],
              "idle": ("A", 0, None), "attack": ("A", 2, None),
              "hurt": ("A", 3, None), "proj": ("A", 4, None)},
    "boss2": {"regions": [(0.0, 1.0)],
              "idle": ("A", 0, None), "attack": ("A", 2, None),
              "hurt": ("A", 3, None), "proj": ("A", 4, None)},
    "boss3": {"regions": [(0.0, 0.5), (0.5, 1.0)],
              "idle": ("A", 0, None), "attack": ("A", 2, None),
              "hurt": ("B", 2, 0.22), "proj": ("B", 3, None)},
}
ROLES = ["idle", "attack", "hurt", "proj"]


def is_content(px):
    r, g, b, a = px
    if a < 40:
        return False
    mn, mx = min(r, g, b), max(r, g, b)
    return not (mn >= 140 and (mx - mn) <= 50)


def row_bands(px, x0, x1, H, min_h, thr_frac):
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


def col_bands(px, y0, y1, x0, x1, min_w, thr_frac):
    thr = max(2, int((y1 - y0) * thr_frac))
    bands, inb, s = [], False, 0
    for x in range(x0, x1):
        c = sum(1 for y in range(y0, y1) if is_content(px[x, y]))
        if c > thr and not inb:
            inb, s = True, x
        elif c <= thr and inb:
            inb = False
            if x - s >= min_w:
                bands.append((s, x))
    if inb and (x1 - s) >= min_w:
        bands.append((s, x1))
    return bands


def cutout(img, px, x0, y0, x1, y1, pad=2):
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


def scaled(im, factor):
    return im.resize((max(1, round(im.size[0] * factor)), max(1, round(im.size[1] * factor))), Image.LANCZOS)


for boss, cfg in ROLE_MAP.items():
    img = Image.open(IMG / f"Boss{boss[-1]}.png").convert("RGBA")
    W, H = img.size
    px = img.load()
    # detect rows per region (same params as the detection pass)
    bands_by_reg = {}
    for ri, (xf0, xf1) in enumerate(cfg["regions"]):
        x0, x1 = int(W * xf0), int(W * xf1)
        bands = row_bands(px, x0, x1, H, min_h=int(H * 0.035), thr_frac=0.04)
        tall = [b for b in bands if (b[1] - b[0]) >= int(H * 0.045)]
        bands_by_reg[chr(ord("A") + ri)] = (x0, x1, tall)

    raw = {}   # role -> [cutouts]
    for role in ROLES:
        reg, idx, top_trim = cfg[role]
        x0, x1, tall = bands_by_reg[reg]
        y0, y1 = tall[idx]
        y0 += int((y1 - y0) * (top_trim or 0.0))   # optional top trim to drop label text
        cols = col_bands(px, y0, y1, x0, x1, min_w=int(W * 0.015), thr_frac=0.05)
        cells = [c for c in (cutout(img, px, cx0, y0, cx1, y1) for (cx0, cx1) in cols) if c]
        if role == "proj":
            # keep round-ish blobs only (drop thin pattern lines / tiny dots), cap to 5
            cells = [c for c in cells if min(c.size) >= 18 and 0.45 <= c.size[0] / c.size[1] <= 2.2][:5]
        raw[role] = cells

    # uniform boss scale from idle height; each projectile scaled to its own target height
    f_boss = TARGET_BOSS_H / max((c.size[1] for c in raw["idle"]), default=TARGET_BOSS_H)

    (OUT / boss).mkdir(parents=True, exist_ok=True)
    final = {}
    for role in ROLES:
        final[role] = []
        for i, c in enumerate(raw[role]):
            s = scaled(c, TARGET_PROJ_H / c.size[1] if role == "proj" else f_boss)
            s.save(OUT / boss / f"{role}_{i}.png")
            final[role].append(s)
        print(f"{boss} {role}: {len(final[role])} frames "
              f"({'x'.join(map(str, final[role][0].size)) if final[role] else '-'})")

    # verification montage: one row per role
    cell = max((max(s.size) for r in ROLES for s in final[r]), default=64) + 8
    cols_n = max(len(final[r]) for r in ROLES)
    mont = Image.new("RGBA", (140 + cell * cols_n, cell * len(ROLES)), (32, 34, 48, 255))
    draw = ImageDraw.Draw(mont)
    for ridx, role in enumerate(ROLES):
        draw.text((6, ridx * cell + cell // 2 - 4), role, fill=(255, 217, 0, 255))
        for cidx, s in enumerate(final[role]):
            mont.alpha_composite(s, (140 + cidx * cell + (cell - s.size[0]) // 2,
                                     ridx * cell + (cell - s.size[1]) // 2))
    mont.save(IMG / f"_boss_{boss}.png")
    print(f"   -> _boss_{boss}.png")
