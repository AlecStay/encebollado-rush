# 🦴 HANDOFF — JOCAY RUSH (Encebollado Rush) 🦴
# BRAIN DUMP PARA NUEVA SESIÓN. LEER ESTO. SABER TODO.

> Última actualización: **5 jun 2026**. Reemplaza el estado viejo. El proyecto cambió mucho:
> audio nuevo, fuente nueva, historia/cutscenes, tienda y apariencia funcionando, jefes
> con ataques variados, niveles temáticos, spawns desde la orilla, etc.

---

## 🧠 QUÉ ES
Juego **Godot 4.6**, **GDScript puro**, renderer **GL Compatibility** (NO Forward+). Top-down
**480×270**, **horizontal bloqueado** (no rota a vertical). Buzo/surfista nada en el mar; la
playa/orilla está arriba (~y=60), el mar abajo, todo scrollea hacia abajo.

**Loop:** elegir nivel → sobrevivir esquivando peligros, comer comida (puntos/buffos), recoger
**spondylus** (monedas) hasta la meta → pelear al jefe → al ganarlo te **quedas en el nivel**
sumando puntos hasta que salgas. 3 vidas. Score = "Energía Ancestral" (moneda de tienda).

---

## ⚙️ CONFIG (project.godot)
- Main scene: `MainMenu.tscn`.
- Display: viewport 480×270, `stretch=canvas_items`/`aspect=expand`, `orientation=landscape`.
- Fuente global: `res://fonts/upheaval.ttf` (pixel; import sin antialias). Estilo UI: **texto blanco
  + contorno negro grueso** (en `themes/hud_theme.tres` y los themes por código).
- **5 autoloads:** `HighScoreManager`, `GameState`, `SettingsManager`, `MusicManager`, `DebugCommands`.
- MCP de Godot (`addons/funplay_mcp`) instalado; server HTTP en `127.0.0.1:8765`. Para usarlo desde
  Claude Code: abrir Godot + start del dock funplay + reiniciar Claude Code (ya está en `~/.claude.json`).

---

## 🗂️ ESCENAS (scenes/)
| Escena | Script | Qué es |
|--------|--------|--------|
| MainMenu.tscn | main_menu.gd | Menú; música vía MusicManager (persistente) |
| LevelSelect.tscn | level_select.gd | Elegir nivel (fondo `images/levels_menu.png`). Dispara la intro si `not intro_seen` |
| Settings.tscn | settings.gd | Volumen música/SFX (slider SFX reproduce SFX random de prueba). Botón Volver |
| HighScore.tscn | high_score.gd | Tabla de puntajes |
| Shop.tscn | shop.gd | Tienda de "boards" (buffs gameplay) con Energía Ancestral |
| Appearance.tscn | appearance.gd | Skins cosméticas (fondo `images/apariencias_menu.png`). Equipar/comprar |
| Story.tscn | story.gd | **Cutscene reutilizable** (intro y final), avanza con tap/click |
| Boss.tscn | boss.gd | Jefe bullet-hell |
| BossProjectile.tscn | boss_projectile.gd | "Bolita" del jefe |
| main.tscn | main.gd | **EL GAMEPLAY** |

---

## ⚡ AUTOLOADS
- **GameState** (`game_state.gd`): `current_level` (0-3) + `LEVELS` (4 temas: agua/arena/ambient/sol).
- **SettingsManager** (`settings_manager.gd`): `music_volume`, `sfx_volume`, `unlocked_levels`,
  `intro_seen`, `ancestral_energy`, `unlocked_boards`/`equipped_board`, `equipped_skin`/`unlocked_skins`/`SKINS`.
  Persiste `user://settings.cfg`. Funciones: `get_music_db/get_sfx_db`, `save/load_settings`, `unlock_level`.
- **MusicManager** (`music_manager.gd`): dueño de la música, **persiste entre escenas**. `play(stream)`
  no reinicia si ya suena lo mismo (loop por `finished→replay`). `play_menu()` lo llaman TODAS las
  escenas de menú → la música del menú sigue de largo. `set_volume_db`, `stop`.
- **HighScoreManager** (`high_score_manager.gd`): top scores en `user://highscores.json`. `save_score(map, score, coins)`.
- **DebugCommands** (`debug_commands.gd`, solo debug build).

---

## 🎵 AUDIO (carpeta music/, nombres ASCII)
- SFX (en `main.gd`, pool de 4 players): `sfx_coin` (spondylus), `sfx_buff` (buffos/emerald/golden/comida),
  `sfx_bomb` (corviche), `sfx_damage` (daño), `sfx_jump` (salto/dodge).
- SFX jefe (en `boss.gd`): `sfx_boss1..4` (ataques normales, random) y `sfx_boss_spiral` (espiral/mixto).
- Música (índice por nivel 0-3): `mus_level1..4`, `mus_boss1..4`, `mus_menu`. Loop. `mus_boss4`/`sfx_boss4`
  cableados pero sin usar (no hay jefe 4 todavía).

---

## 🎮 GAMEPLAY (main.gd)
- **Spawns desde la orilla:** peligros/comida/decoración nacen en `SHORE_Y=60` y bajan (no caen del cielo).
  Player **clamp** `y>=SHORE_Y` (player.gd) → no sale del mar.
- **Spawnables:** `_hazard_scenes` (boat/shark/rock/trash), `_bonus_scenes` (encebollado/ceviche/cola/corviche),
  `golden` (nivel bonus), `emerald` (buff), `spondylus` (monedas). Base = `spawnable.gd` (señal `touched`).
- **Daño:** 25% HP por golpe, i-frames 1s. Al recibir daño: **parpadeo + flash rojo sutil full-screen** (`_play_hit_flash`).
- **Dificultad creciente por nivel:** intervalos de hazard ×0.75/nivel, `_hazard_count()` spawnea más
  objetos en mapas altos (1/1/2/3). Además rampa temporal cada 120s.
- **Completar nivel:** al llegar a la meta de spondylus (`_get_coins_to_pass`: 10/20/30/40) → si el mapa
  tiene jefe `_start_boss`, si no `_complete_level()`. **`_complete_level` NO avanza de mapa**: marca
  `_level_passed`, guarda score, desbloquea el siguiente nivel, muestra "¡NIVEL COMPLETADO!" y te quedas
  en el MISMO nivel/música sumando puntos (dejan de salir spondylus, el jefe no reaparece). Sales por pausa→menú.
- **Nivel bonus (golden):** 15s de comida frenética.
- **Temas de nivel:** `_apply_level_theme` aplica `LEVELS[idx].ambient` al CanvasModulate + efecto de
  **inundación/marea** (`_play_flood`) en la transición. Olas sutiles con shader (`_setup_waves`). Fondos
  reales = `sprites/maps/level0-3.png`.

---

## 👑 JEFES (boss.gd)
- `BOSS_DATA` = boss1/boss2/boss3 (name/hp/speed/period). `BOSS_MAPS = {0:boss1, 2:boss2, 3:boss3}`.
  **El nivel 2 (map 1) NO tiene jefe** y **no existe boss4** (faltan data+sprites).
- **HP del jefe baja SOLO con perfect-dodge:** esquivar (botón Salto) justo cuando un proyectil te alcanza
  (`main.gd._on_boss_projectile_hit` con `is_dodging` → `take_damage(DODGE_DMG=10)`, +combo, +devuelve salto).
  Saltar sin proyectil NO hace daño. NO hay drenaje por tiempo.
- **Ataques variados por jefe y fase** (`ATTACKS` dict, 3 fases por vida): primitivas `_ring/_spiral/
  _double_spiral/_aimed/_rain/_wall_gap`. boss1 aprendible, boss2 anillos/espirales de 5, boss3 denso.
- **Escala por nivel:** `start(id, cont, player, level)` → ×hp, ×speed, ÷period.
- Para añadir **boss4**: entrada en `BOSS_DATA` + `ATTACKS`, frames en `sprites/bosses/boss4/{idle,attack,hurt,proj}_N.png`,
  y agregarlo a `BOSS_MAPS`. Música/SFX ya listos.

---

## 📖 HISTORIA (story.gd / Story.tscn)
- Cutscene reutilizable: páginas `{image, lines[]}`, una línea por **tap/click**, luego siguiente imagen.
  Datos: `INTRO` (5 escenas, `images/escena dialogo 1..5.png`) y `ENDING` (`images/escena final.png`, 7 líneas).
- Exports: `story_id` ("intro"|"ending"), `next_scene` (cambia de escena al terminar), `pause_during` (overlay).
- **Intro:** primera partida (`not intro_seen`). `level_select.gd` carga `Story.tscn` (preconfigurada
  intro→main.tscn); al terminar marca `intro_seen`. El nivel no empieza hasta terminar los diálogos.
- **Final:** al derrotar al jefe del **último nivel** (map 3), `main.gd._on_boss_defeated` instancia
  Story.tscn como overlay en `$HUD` (`pause_during=true`); al cerrar se sigue jugando el nivel.

---

## 🐞 DEBUG (debug_commands.gd, solo debug build)
- **Ctrl+C** +1.000.000 Energía Ancestral · **Alt+Q** desbloquea todos los niveles · **Alt+W** completa
  nivel/va al jefe · **Alt+E** ver intro (ignora intro_seen) · **Alt+R** ver escena final (en gameplay).

---

## ⚠️ PENDIENTES / TRAMPAS
1. **Sin jefe en nivel 2 (map 1)** y **sin boss4** → faltan data/sprites (ver sección JEFES).
2. `MAP_SCORE_STEP` (const en main.gd) quedó **sin uso** (antes cambiaba mapa por puntaje).
3. Warnings menores: variable `h` sin uso en `_spawn_scene`/`_spawn_decoration` (inofensivo).
4. `SHORE_Y=60` está duplicado como const en `main.gd` y `player.gd` (ajustable si algún mapa no calza).
5. MCP funplay no se usa en una sesión sin reiniciar Claude Code + Godot abierto.
6. Tras editar scripts, **cerrar y reabrir Godot** (no solo Play) para recargar autoloads/escenas.

---

## 🔑 REGLAS DE ORO
1. NO tocar `.godot/` (cache).
2. `.tscn`/`.tres` son texto pero delicados; respetar formato Godot 4.
3. Respetar autoloads (singletons globales).
4. `spawnable.gd` es la base de comida/peligros; NO scripts separados por item.
5. Viewport 480×270, horizontal. GDScript, Godot 4.6, GL Compatibility.
6. Memoria del proyecto en `~/.claude/projects/.../memory/` (índice `MEMORY.md`).

*Sesión previa: menú apariencia + sistema de historia (intro/final). Antes: audio nuevo, fuente upheaval,
música global, fix daño jefe, no-avance de nivel, spawns orilla, olas, temas de nivel.*
