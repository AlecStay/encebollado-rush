# 🦴 HANDOFF — ENCEBOLLADO RUSH 🦴
# CAVEMAN BRAIN DUMP. READ THIS. KNOW EVERYTHING. NO EXCUSES.

---

## 🧠 QUÉ DIABLOS ES ESTO

Juego **Godot 4.6** GDScript puro. Vista top-down 480×270 horizontal. Buzo nada en el mar. Playa arriba, agua abajo. TODO scrollea hacia abajo (el mundo se mueve, el buzo no avanza solo).

**OBJETIVO:** Sobrevivir con 3 vidas. Acumular puntos infinitamente. NO HAY VICTORIA — solo muerte y highscores.

**CONTROLES:** WASD/flechas o mouse/touch (click-drag). Móvil-friendly.

---

## 🗺️ MAPA DEL PROYECTO — DÓNDE VIVE CADA COSA

```
Encebollado_Rush/
├── project.godot          ← CONFIG RAÍZ. Main scene = MainMenu.tscn. 3 autoloads.
├── CAMBIOS.md             ← Historia de sesión anterior (sprites, templates)
├── IA_CONTEXT.md          ← Contexto técnico detallado de features avanzadas
├── handoff.md             ← ESTE ARCHIVO. TU BIBLIA.
│
├── scenes/                ← LAS 5 ESCENAS DEL JUEGO
│   ├── MainMenu.tscn      → main_menu.gd     (menú con botones animados slide-in)
│   ├── LevelSelect.tscn   → level_select.gd   (elegir mapa + dificultad)
│   ├── Settings.tscn       → settings.gd       (volumen, fullscreen, dificultad)
│   ├── HighScore.tscn     → high_score.gd     (top 10 puntajes desde JSON)
│   └── main.tscn          → main.gd           (EL GAMEPLAY. EL GORDO. EL JEFE.)
│
├── scripts/               ← TODA LA LÓGICA
│   ├── main.gd             ← 381 LÍNEAS. Spawn, colisión, bonus, dificultad, mapas, audio, UI
│   ├── player.gd           ← 157 líneas. Movimiento 8 dirs, invulnerabilidad, blink
│   ├── spawnable.gd        ← 31 líneas. Base para toda comida/peligro. Signal "touched"
│   ├── decoration.gd       ← 17 líneas. Parallax scroll de decoraciones
│   ├── game_state.gd       ← AUTOLOAD. Nivel actual + array LEVELS (4 temas visuales)
│   ├── settings_manager.gd ← AUTOLOAD. Volumen, fullscreen, dificultad. Persiste user://settings.cfg
│   ├── high_score_manager.gd ← AUTOLOAD. Top 10 scores en user://highscores.json
│   ├── main_menu.gd        ← Navegación menú, slide-in, hover cursor
│   ├── level_select.gd     ← Selección de mapa (4) + dificultad (3), highlight dinámico
│   ├── settings.gd          ← UI de settings: sliders, checkbutton, dificultad botones
│   └── high_score.gd       ← Dibuja tabla de scores dinámicamente
│
├── templates/             ← PREFABS (PackedScene) — 16 escenas
│   ├── player.tscn         ← CharacterBody2D + Sprite2D con 8 texturas direccionales
│   ├── boat.tscn           ← Peligro. 0 pts.
│   ├── shark.tscn          ← Peligro. 0 pts.
│   ├── rock.tscn           ← Peligro. 0 pts.
│   ├── trash.tscn          ← Peligro. 0 pts.
│   ├── encebollado.tscn    ← Bonus. 10 pts.
│   ├── ceviche.tscn        ← Bonus. 15 pts.
│   ├── cola.tscn           ← Bonus. (comida)
│   ├── corviche.tscn       ← Bonus. (comida)
│   ├── fish.tscn           ← Bonus. 10 pts.
│   ├── photo.tscn          ← Bonus manta. 25 pts. Abre popup.
│   ├── golden.tscn         ← ESPECIAL. Trigger de nivel bonus. 8% chance.
│   ├── decor_bubbles.tscn  ← Decoración parallax
│   ├── decor_foam.tscn     ← Decoración parallax
│   ├── decor_starfish.tscn ← Decoración parallax
│   └── decor_palm.tscn     ← Decoración parallax
│
├── sprites/               ← 35 archivos de arte (SVG originales + PNG nuevos)
│   ├── player_n/ne/e/se/s/sw/w/nw.png ← 8 texturas direccionales del buzo
│   ├── player_idle.svg, player_swim.svg ← Originales
│   ├── *_new.png           ← Arte final para cada spawnable y decoración
│   ├── sun.svg, moon.svg   ← Ciclo día/noche
│   ├── water_tile.svg, sand_tile.svg ← Tiles de fondo
│   ├── mainmenu.png        ← Fondo del menú principal (7MB!)
│   └── char_menu.png       ← Personaje del menú
│
├── images/                ← Assets adicionales
├── music/                 ← Audio del juego
└── .godot/                ← Cache de Godot (NO TOCAR)
```

---

## ⚡ LOS 3 AUTOLOADS — EL ESTADO GLOBAL

### 1. `GameState` (scripts/game_state.gd)
```gdscript
var current_level := 0   # índice del nivel seleccionado (0-3)
const LEVELS: Array = [  # 4 temas: Amanecer, Tarde, Atardecer, Anochecer
  { name, water_modulate, sand_modulate, ambient, sun_x, sun_y, is_night }
]
```
**REGLA CAVEMAN:** `GameState.current_level` = qué mapa se usa al iniciar. Se cambia en LevelSelect.

### 2. `SettingsManager` (scripts/settings_manager.gd)
```gdscript
var music_volume := 0.8   # 0.0 - 1.0
var sfx_volume := 1.0     # 0.0 - 1.0
var fullscreen := false
var difficulty := 1       # 0=Fácil, 1=Normal, 2=Difícil
# Persiste en: user://settings.cfg
# Funciones: get_music_db(), get_sfx_db(), save_settings(), load_settings(), apply_fullscreen()
```

### 3. `HighScoreManager` (scripts/high_score_manager.gd)
```gdscript
# Persiste en: user://highscores.json
# Top 10. Cada entrada: { score: int, won: bool, date: string }
# save_score(score, won) — ordena desc, recorta a 10
# get_scores() → Array
```

---

## 🎮 GAMEPLAY LOOP (main.gd) — EL CEREBRO

### Spawning
- `_hazard_scenes` = [boat, shark, rock, trash] → spawn random con timer aleatorio
- `_bonus_scenes` = [encebollado, ceviche, cola, corviche] → spawn random con timer
- `_golden_scene` = golden.tscn → 8% chance en cada spawn de bonus
- `_decor_scenes` = [bubbles, foam, starfish, palm] → parallax a 60% velocidad
- Todos los spawnables usan `spawnable.gd` base → señal `touched` al tocar player

### Colisión (_on_spawnable_touched)
- **Peligro:** Si no es invulnerable → daño (25% HP). HP=0 → pierde vida. Vidas=0 → GAME OVER
- **Bonus:** Suma puntos. Si es "photo" → popup 2s. Checkea transición de mapa.
- **Golden:** Entra nivel bonus (15s de comida frenética, sin peligros)

### Dificultad
- **Fácil:** Peligros spawn 1.5x más lento, bonus 0.65x más rápido, velocidad 0.8x
- **Normal:** Sin modificadores
- **Difícil:** Peligros spawn 0.6x más rápido, bonus 1.25x más lento, velocidad 1.3x
- **Progresiva:** Cada 120s la velocidad sube x1.15 (infinito)

### Transición de Mapas
- Cada 500 puntos → cambia tema visual (Amanecer→Tarde→Atardecer→Noche→loop)
- Tween suave de 1s: agua, arena, ambient light, posición sol/luna

### Nivel Bonus
- Golden pickup → para peligros, limpia pantalla, spawn frenético de comida (0.12-0.28s)
- Dura 15s con countdown visible. Al terminar, reanuda gameplay normal.

---

## 🏊 PLAYER (player.gd) — EL BUZO

- **CharacterBody2D** en grupo "player"
- **Movimiento:** WASD/flechas o mouse/touch drag. Velocidad 220.
- **8 direcciones:** Calcula ángulo → 8 octantes → asigna textura (tex_n, tex_ne, etc.)
- **Invulnerabilidad:** Parpadeo con modulate.a (0.35/1.0 cada 0.1s). Dura 1s post-daño.
- **Clamp:** Se mantiene dentro del viewport con margen de 20px.

---

## 🐟 SPAWNABLE (spawnable.gd) — LA BASE DE TODO

```gdscript
signal touched(spawnable: Area2D)
@export var kind := ""        # "golden", "photo", etc
@export var is_hazard := true
@export var points := 10
@export var scroll_speed := 120.0
```
- Area2D. Se mueve hacia abajo a scroll_speed.
- Se auto-elimina al salir por abajo del viewport.
- Emite `touched` al colisionar con body en grupo "player".
- Cada template (.tscn) fija kind/is_hazard/points/textura en el editor.

---

## 🎨 SISTEMA DE TEMAS — PALETA DE COLORES

| Tema | Agua | Arena | Ambient | Sol/Luna |
|------|------|-------|---------|----------|
| Amanecer | (0.78, 0.88, 1.00) | (1.00, 0.80, 0.58) | (1.00, 0.85, 0.70) | Sol x=80 y=22 |
| Tarde | (1.00, 1.00, 1.00) | (1.00, 0.96, 0.80) | (1.00, 1.00, 0.97) | Sol x=240 y=12 |
| Atardecer | (1.00, 0.68, 0.44) | (1.00, 0.58, 0.35) | (1.00, 0.72, 0.50) | Sol x=400 y=24 |
| Anochecer | (0.18, 0.24, 0.55) | (0.32, 0.35, 0.50) | (0.45, 0.50, 0.75) | Luna x=390 y=16 |

---

## 🧭 NAVEGACIÓN ENTRE ESCENAS

```
MainMenu
  ├── "Un Jugador" → LevelSelect → main (gameplay)
  ├── "Multijugador" → HighScore (reutilizado, botón mal nombrado)
  ├── "Tienda" → print() (NO IMPLEMENTADO)
  ├── "Configuración" → Settings
  └── "Apariencia" → print() (NO IMPLEMENTADO)

main (gameplay)
  ├── "Reintentar" → reload_current_scene()
  └── "Menú Principal" → MainMenu

Settings → "Volver" → MainMenu (auto-save)
HighScore → "Volver" → MainMenu
LevelSelect → "Volver" → MainMenu
LevelSelect → "¡JUGAR!" → main
```

---

## 🎨 UI THEME PATTERN — TODAS LAS PANTALLAS USAN ESTO

```gdscript
const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)  # Crema
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)  # Dorado
const _COLOR_ACCENT := Color(1.00, 0.42, 0.21)  # Naranja
const _COLOR_SHADOW := Color(0.10, 0.10, 0.18)  # Azul oscuro
```
- Todos los botones: StyleBoxEmpty + colores por código
- Outline de 2-3px con _COLOR_SHADOW
- Animación slide-in desde la izquierda (tween offset_left/right + modulate:a)
- Font sizes: títulos 13-14, contenido 10-11

---

## 📐 CONSTANTES IMPORTANTES (main.gd)

| Constante | Valor | Qué hace |
|-----------|-------|----------|
| DAMAGE_FRACTION | 0.25 | 25% de HP por golpe (4 golpes = vida) |
| INVULNERABLE_TIME | 1.0s | Tiempo de i-frames |
| GOLDEN_CHANCE | 0.08 | 8% probabilidad de golden en spawn bonus |
| BONUS_DURATION | 15.0s | Duración del nivel bonus |
| FRENETIC_MIN/MAX | 0.12/0.28s | Spawn rate durante bonus |
| MAP_SCORE_STEP | 500 | Puntos para cambiar tema |
| DIFFICULTY_PERIOD | 120.0s | Cada cuánto sube la dificultad |
| DIFFICULTY_FACTOR | 1.15 | Multiplicador de velocidad progresivo |
| DECOR_SCROLL_FACTOR | 0.6 | Parallax de decoraciones (60% velocidad) |

---

## ⚠️ COSAS ROTAS / INCOMPLETAS / TRAMPAS

1. **"Multijugador" lleva a HighScore** — El botón está mal mapeado (main_menu.gd línea 73)
2. **"Tienda" y "Apariencia" son print()** — No implementados
3. **No hay condición de victoria** — Solo muerte. `_end_game()` siempre pasa `won=false`
4. **mainmenu.png pesa 7MB** — Optimizar o comprimir
5. **El path de Godot en .vscode/settings.json tiene usuario "ASUS"** — Puede que no coincida con la máquina actual
6. **No hay música/SFX incluidos** — Los @export de audio en main.gd probablemente están vacíos en el editor
7. **graphify_chunk01.py** — Script Python para algo de grafos. No es parte del juego.
8. **Jolt Physics habilitado** — Raro para un juego 2D, pero no molesta

---

## 🔧 CÓMO AGREGAR COSAS

### Nuevo tipo de comida/peligro:
1. Crear sprite en `sprites/`
2. Duplicar template existente en `templates/`, cambiar textura + kind + is_hazard + points
3. Agregar `preload("res://templates/nuevo.tscn")` a `_hazard_scenes` o `_bonus_scenes` en main.gd

### Nueva escena/pantalla:
1. Crear .tscn en `scenes/`
2. Crear .gd en `scripts/`
3. Usar el patrón de UI theme (colores, StyleBoxEmpty, slide-in tween)
4. Navegar con `get_tree().change_scene_to_file("res://scenes/NuevaEscena.tscn")`

### Nuevo autoload:
1. Crear script en `scripts/`
2. Agregar en project.godot → [autoload] sección

---

## 🔑 REGLAS DE ORO PARA LA IA

1. **NUNCA toques .godot/** — Es cache autogenerado
2. **Los .tscn son delicados** — Edítalos con conocimiento de formato Godot o preferiblemente desde el editor
3. **Respeta los 3 autoloads** — Son singletons, accesibles globalmente: GameState, SettingsManager, HighScoreManager
4. **spawnable.gd es la base** — NO crees scripts separados para cada comida/peligro
5. **El viewport es 480×270** — TODO debe caber ahí. stretch_mode = canvas_items
6. **GDScript, no C#** — Este proyecto es 100% GDScript
7. **Godot 4.6 + Forward Plus** — No uses APIs de Godot 3.x ni Compatibility renderer

---

*Último update: 2 junio 2026 — Sesión de inicialización de memoria*
