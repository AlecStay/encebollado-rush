from PIL import Image
from pathlib import Path

src = Path(r"C:\Users\ASUS\Encebollado_Rush\images\sprites_in_game.png")
out = Path(r"C:\Users\ASUS\Encebollado_Rush\sprites")
out.mkdir(exist_ok=True)

img = Image.open(src).convert("RGBA")
W, H = img.size
px = img.load()

# Row bands derived from earlier auto-detection
BANDS = {
    "player_row1": (60, 123),   # N, NE, E, SE
    "player_row2": (168, 230),  # S, SW, W, NW
    "bonus":       (285, 345),  # ENCEBOLLADO, CEVICHE, COLA, CORVICHE
    "hazard":      (402, 454),  # TIBURON, BALSA, ROCA, BASURA
    "decor":       (499, 534),  # BURBUJAS, ESPUMA, EXTRA, PALMERA
}

def is_content_pixel(r, g, b, a):
    if a < 32: return False
    if r > 240 and g > 240 and b > 240: return False
    return True

def detect_columns(y0, y1, n_cols=4, pad=4):
    """Find bounding box of each of n_cols columns in band y0..y1."""
    col_density = [0] * W
    for y in range(y0, y1):
        for x in range(W):
            r, g, b, a = px[x, y]
            if is_content_pixel(r, g, b, a):
                col_density[x] += 1
    avg = sum(col_density) / W
    thr = max(2, int(avg * 0.4))
    bands = []
    in_b = False
    start = 0
    for x, c in enumerate(col_density):
        if c > thr and not in_b:
            in_b = True; start = x
        elif c <= thr and in_b:
            in_b = False
            if x - start > 8:
                bands.append([start, x])
    if in_b:
        bands.append([start, W])
    # If we got more than n_cols (sub-sprite gaps), merge closest pairs
    while len(bands) > n_cols:
        gaps = [(bands[i+1][0] - bands[i][1], i) for i in range(len(bands)-1)]
        gaps.sort()
        _, i = gaps[0]
        bands[i][1] = bands[i+1][1]
        del bands[i+1]
    return [tuple(b) for b in bands]

def crop_cell(name, y0, y1, x0, x1, pad=2):
    # Trim transparent/white padding to tightest content bounding box
    min_x, min_y, max_x, max_y = W, H, 0, 0
    found = False
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b, a = px[x, y]
            if is_content_pixel(r, g, b, a):
                found = True
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if x > max_x: max_x = x
                if y > max_y: max_y = y
    if not found:
        print(f"  WARN: empty cell {name}")
        return
    # Add padding
    min_x = max(x0, min_x - pad)
    min_y = max(y0, min_y - pad)
    max_x = min(x1, max_x + pad + 1)
    max_y = min(y1, max_y + pad + 1)
    crop = img.crop((min_x, min_y, max_x, max_y))
    crop.save(out / f"{name}.png")
    print(f"  {name}.png  ({max_x-min_x}x{max_y-min_y})")

ROW_LABELS = {
    "player_row1": ["player_n", "player_ne", "player_e", "player_se"],
    "player_row2": ["player_s", "player_sw", "player_w", "player_nw"],
    "bonus":       ["encebollado_new", "ceviche_new", "cola_new", "corviche_new"],
    "hazard":      ["shark_new", "boat_new", "rock_new", "trash_new"],
    "decor":       ["bubbles_new", "foam_new", "starfish_new", "palm_new"],
}

print(f"Image {W}x{H}")
for band_key, (y0, y1) in BANDS.items():
    cols = detect_columns(y0, y1, n_cols=4)
    labels = ROW_LABELS[band_key]
    print(f"\n{band_key}  y={y0}..{y1}  cols={cols}")
    for i, (x0, x1) in enumerate(cols):
        if i >= len(labels): break
        crop_cell(labels[i], y0, y1, x0, x1)
