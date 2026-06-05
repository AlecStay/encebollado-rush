"""Generate per-level pixel-art background maps for the gameplay.

Reuses the hand-pixel water style (base colour + depth gradient + wave streaks + sparkles)
and a themed sky + horizon-silhouette band, with palettes sampled from each boss so the
backgrounds match the bosses. Output: sprites/maps/level0..3.png (640x270) + a preview montage.
"""
import math
import random
from PIL import Image, ImageDraw
from pathlib import Path

PROJ = Path(r"C:\Users\ASUS\Jocay Surf Rush")
OUT  = PROJ / "sprites" / "maps"
IMG  = PROJ / "images"
W, H = 640, 270
HZ   = 60          # waterline y (sky/scenery above, water below)


def lerp(a, b, t):
    return (int(a[0] + (b[0] - a[0]) * t), int(a[1] + (b[1] - a[1]) * t), int(a[2] + (b[2] - a[2]) * t))


def vgrad(d, top, bot, y0, y1):
    for y in range(y0, y1):
        d.line([(0, y), (W, y)], fill=lerp(top, bot, (y - y0) / max(1, y1 - y0 - 1)))


def water(d, base, rng):
    light = lerp(base, (255, 255, 255), 0.22)
    dark  = lerp(base, (0, 0, 0), 0.32)
    spark = lerp(base, (255, 255, 255), 0.7)
    for y in range(HZ, H):                                  # lighter at horizon -> darker deep
        d.line([(0, y), (W, y)], fill=lerp(light, dark, ((y - HZ) / (H - HZ)) * 0.9))
    for _ in range(150):                                     # wave streaks
        x = rng.randint(0, W - 14); y = rng.randint(HZ + 2, H - 2); wl = rng.randint(3, 13)
        d.line([(x, y), (x + wl, y)], fill=(lerp(light, spark, 0.5) if rng.random() < 0.4 else light))
    for _ in range(90):                                      # sparkles
        d.point((rng.randint(0, W - 1), rng.randint(HZ + 2, H - 1)), fill=spark)
    d.line([(0, HZ), (W, HZ)], fill=lerp(base, (255, 255, 255), 0.45))   # horizon glow


def beach(d, y, sand):
    d.rectangle([0, y, W, HZ], fill=sand)
    for _ in range(120):
        x = random.randint(0, W - 1); yy = random.randint(y, HZ - 1)
        d.point((x, yy), fill=lerp(sand, (255, 255, 255), 0.4) if random.random() < 0.5
                else lerp(sand, (0, 0, 0), 0.25))


def palm(d, x, gy, h, trunk, frond):
    for i in range(h):
        tx = x + int(math.sin(i / h * 1.1) * h * 0.13)
        d.line([(tx, gy - i), (tx + 2, gy - i)], fill=trunk)
    tx = x + int(math.sin(1.1) * h * 0.13); top = (tx, gy - h)
    for ang in (-165, -130, -95, -60, -25, -200):
        a = math.radians(ang)
        fx = top[0] + int(math.cos(a) * h * 0.75); fy = top[1] + int(math.sin(a) * h * 0.55)
        d.line([top, (fx, fy)], fill=frond, width=2)
        d.line([(fx, fy), (fx, fy + 4)], fill=frond)
    d.ellipse([top[0] - 2, top[1] - 1, top[0] + 1, top[1] + 2], fill=(92, 60, 38))


def hump(d, cx, base_y, rw, rh, col):
    d.ellipse([cx - rw, base_y - rh, cx + rw, base_y + rh], fill=col)


def build(level):
    rng = random.Random(level * 7 + 3)
    random.seed(level * 11 + 1)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)

    if level == 0:        # Costas de Jocay — amanecer
        vgrad(d, (255, 214, 168), (188, 214, 232), 0, HZ + 4)
        for cx in range(-20, W + 60, 150):                  # distant green hills
            hump(d, cx, HZ - 4, 95, 34, (78, 120, 78))
        beach(d, HZ - 12, (219, 184, 114))
        water(d, (36, 120, 176), rng)
        for x in (70, 250, 520):                            # palms on the coast
            palm(d, x, HZ - 8, rng.randint(34, 44), (96, 64, 40), (44, 96, 58))

    elif level == 1:      # Arrecife Spondylus — brillante
        vgrad(d, (150, 226, 236), (196, 242, 230), 0, HZ + 4)
        for cx in range(-10, W + 40, 120):
            hump(d, cx, HZ - 6, 70, 22, (120, 205, 200))
        water(d, (31, 156, 192), rng)
        corals = [(224, 112, 58), (224, 138, 160), (96, 196, 178), (210, 86, 47)]
        for _ in range(26):                                 # coral + Spondylus shells along the reef
            x = rng.randint(6, W - 6); y = rng.randint(HZ + 4, HZ + 30)
            c = corals[rng.randint(0, len(corals) - 1)]
            for b in range(rng.randint(2, 4)):
                bx = x + b * 3 - 3
                d.line([(bx, y), (bx, y - rng.randint(4, 9))], fill=c)

    elif level == 2:      # Ruta de los Navegantes — atardecer
        vgrad(d, (255, 152, 72), (150, 60, 86), 0, HZ + 4)
        d.ellipse([W - 150, 8, W - 92, 66], fill=(255, 224, 150))   # sun glow on horizon
        for cx in (60, 300, 560):                            # island silhouettes
            hump(d, cx, HZ - 2, rng.randint(48, 80), rng.randint(16, 26), (70, 44, 60))
        water(d, (196, 112, 76), rng)
        for sx in (150, 420):                                # rafts with sails
            d.rectangle([sx, HZ + 10, sx + 16, HZ + 13], fill=(74, 50, 40))
            d.polygon([(sx + 8, HZ + 10), (sx + 8, HZ - 2), (sx + 18, HZ + 9)], fill=(236, 210, 170))

    else:                 # Santuario de Umiña — noche
        vgrad(d, (10, 14, 44), (34, 18, 66), 0, HZ + 4)
        for _ in range(110):                                 # stars
            d.point((rng.randint(0, W - 1), rng.randint(0, HZ - 6)),
                    fill=lerp((180, 190, 240), (255, 255, 255), rng.random()))
        for cx in range(-10, W + 40, 130):                   # dark shore
            hump(d, cx, HZ - 2, 80, 18, (22, 22, 44))
        # ancestral monolith
        mx = W // 2
        d.polygon([(mx - 16, HZ + 2), (mx + 16, HZ + 2), (mx + 11, HZ - 52), (mx - 11, HZ - 52)], fill=(58, 58, 72))
        d.polygon([(mx - 11, HZ - 52), (mx - 11, HZ - 64), (mx - 4, HZ - 56), (mx + 4, HZ - 64),
                   (mx + 11, HZ - 56), (mx + 11, HZ - 52)], fill=(58, 58, 72))
        d.line([(mx - 8, HZ - 30), (mx + 8, HZ - 30)], fill=(60, 200, 150))    # emerald glow
        d.line([(mx - 6, HZ - 22), (mx + 6, HZ - 22)], fill=(60, 200, 150))
        water(d, (24, 32, 80), rng)

    return img


maps = []
OUT.mkdir(parents=True, exist_ok=True)
for lv in range(4):
    m = build(lv)
    m.save(OUT / f"level{lv}.png")
    maps.append(m)
    print(f"level{lv}.png  {m.size}")

# 2x2 montage for verification
mont = Image.new("RGBA", (W * 2 + 12, H * 2 + 12), (24, 26, 36, 255))
for i, m in enumerate(maps):
    mont.alpha_composite(m, (4 + (i % 2) * (W + 4), 4 + (i // 2) * (H + 4)))
mont.save(IMG / "_maps_preview.png")
print("-> _maps_preview.png")
