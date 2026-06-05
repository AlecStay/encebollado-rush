# Jocay Surf Rush — HUD Design Brief

> Context document for redesigning the in-game HUD. Pairs with `docs/hud_mockups.html`.

## Pitch
Fast, casual one-thumb arcade surf game. You surf down an endless coastline,
dodging hazards and grabbing food/treasure — a celebration of Manta, Ecuador
("Jocay / Manta Centenaria" theme). UI is in **Spanish**.

## Canvas / Tech constraints
- Godot 4.6, 2D, **landscape**, mobile-first (touch), pixel-art.
- Base resolution **480×270 px** (16:9), **nearest-neighbor** filtering — crisp pixels,
  no blur. Design HUD art low-res / pixel-friendly, with chunky outlines.
- Stretch = `expand`: the HUD **must be anchor-based** and survive taller/wider phone
  ratios (19.5:9, 20:9, tablets). Use **edge clusters**, not fixed coordinates.

## Controls & touch ergonomics
- **Move = drag anywhere** on screen; the surfer follows the finger. The whole center
  is a touch surface, so the HUD must **not block it**: only action buttons are tappable,
  all readouts pass touches through (non-interactive).
- **Dodge / "Salto"**: spin-dodge, 2 charges, ~3s cooldown each → **bottom corner** (thumb).
- **Pause** → **top corner**.

## The HUD must show (live state)
| Element | Detail |
|---|---|
| **Health** | bar 0–100% (one hit = −25%; 4 hits = lose a life) |
| **Lives** | integer, starts at 3 |
| **Score** ("Puntos") | integer, climbs fast |
| **Spondylus progress** | collected / needed (e.g. 7/20) — the **level objective** (10/20/30/40 by level) |
| **Dodge** | charges x/2 + a refilling cooldown gauge |
| **Combo** | "Esquive Perfecto" perfect-dodge multiplier (x0.1 → x1.0), juicy/shaky, fades out |
| **Bonus banner + countdown** | "¡NIVEL BONUS!" with a ~15s timer (Spondylus rush) |
| **Status banner** (center) | "¡NIVEL COMPLETADO!" / "GAME OVER" |
| **Pause menu** | Resume, Music/SFX sliders, Back to menu |
| **Game over** | Retry, Main menu |
| **Buffs** *(nice-to-have, weak today)* | Ceviche (score x2, 10s), Emerald (speed+shield, 15s), Cola (slow-mo), Corviche (screen-clear bomb), Encebollado (heal) — could become icon + timer pips |

## Current layout (what you're replacing)
- **Top-left stack**: health bar, "Vidas: 3", "Puntos: 0", "Spondylus: 0/20".
- **Top-right**: pause "II".
- **Bottom-right**: "Salto 2/2" button + cooldown bar above it.
- **Bottom-left**: combo text (transient).
- **Center**: bonus/status banners + a manta "photo" reward popup.

## Theme & palette (keep consistent)
- Ecuadorian Pacific coast; sacred **Spondylus** shell = currency; **Umiña** (emerald
  goddess) night level. Four level moods the HUD sits over: warm dawn → bright reef →
  orange sunset → **deep-blue night**. HUD must read over **both bright and dark** scenes
  (rely on outlines/shadows).
- Level names: *Las Costas de Jocay*, *El Arrecife Spondylus*, *La Ruta de los Navegantes*,
  *El Santuario de Umiña*.

### Style tokens
| Token | Value |
|---|---|
| Cream (text) | `#E8E8D1` |
| Gold (accent / highlight) | `#FFD900` |
| Orange (action / warning) | `#FF6B36` |
| Dark navy (outline / shadow) | `#1A1A2E` |
| Font | small pixel font, 2–3px dark outline |

- Character **skins** vary (human, shrimp-man, stingray-man…) — the HUD is character-independent.

## Design goals
Glanceable during fast play · thumb-friendly corners · minimal center clutter ·
legible over bright & night backgrounds · scales across phone aspect ratios.
