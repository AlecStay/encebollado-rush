# Cambios al proyecto

## De qué trata el juego

Mini-juego en **Godot 4.6** (vista 480×270, pensado para móvil/horizontal). El jugador es un buzo que nada hacia adelante mientras el mundo se desplaza hacia abajo. La playa (arena) está arriba y el mar abajo.

**Objetivo:** llegar a **100 puntos** sin perder las **3 vidas**.

**Mecánicas:**
- **Bonos** (suman puntos): encebollado (10), ceviche (15), foto de manta (25), pescado (10).
- **Peligros** (quitan vida): bote y tiburón.
- Al recibir daño, el buzo queda invulnerable ~1 s y parpadea.
- La foto de manta abre un popup mostrando la imagen 2 segundos.
- Al ganar/perder se muestra mensaje y se reinicia tocando la pantalla / clic / Enter.

**Controles:** WASD / flechas, o tocar/arrastrar con el ratón / pantalla táctil.

---

## Qué se cambió en esta sesión

Antes los gráficos eran **rectángulos de colores planos** (placeholders) y todo estaba en un solo `spawnable.gd` genérico. Ahora hay sprites reales y cada tipo de objeto tiene su propia escena.

### Nuevas carpetas

```
sprites/      ← arte SVG (Godot lo importa como Texture2D)
  player_idle.svg, player_swim.svg
  boat.svg, shark.svg
  encebollado.svg, ceviche.svg, manta.svg, fish.svg
  water_tile.svg, sand_tile.svg

templates/    ← escenas-prefab, una por tipo
  player.tscn         (CharacterBody2D + AnimatedSprite2D con animación "swim" 2 frames a 4 fps)
  boat.tscn           (peligro, 0 pts)
  shark.tscn          (peligro, 0 pts)
  encebollado.tscn    (bono, 10 pts)
  ceviche.tscn        (bono, 15 pts)
  photo.tscn          (bono manta, 25 pts)
  fish.tscn           (bono, 10 pts)
```

Todos los templates de spawnables comparten el mismo script ([scripts/spawnable.gd](scripts/spawnable.gd)). La textura, el `kind`, `is_hazard` y `points` quedan fijados dentro del `.tscn`.

### Cambios en código

- **[scripts/spawnable.gd](scripts/spawnable.gd)** — Se quitaron los exports `color` y `size` y el código que mutaba el `Polygon2D`. Ahora cada template trae su `Sprite2D` con la textura ya puesta. El cull (cuándo eliminar el objeto al salir por abajo) se calcula desde el alto de la textura.
- **[scripts/player.gd](scripts/player.gd)** — El parpadeo de invulnerabilidad ya no usa `visible = not visible` (cortaba la animación). Ahora usa `modulate.a` para hacer fade, así el sprite sigue animándose mientras parpadea.
- **[scripts/main.gd](scripts/main.gd)** — Se reemplazaron los diccionarios `_hazard_defs` / `_bonus_defs` con dos `Array[PackedScene]` que preload-ean cada template. La función de spawn ya no asigna color/size: solo instancia, posiciona y conecta la señal `touched`.

### Cambios en escenas

- **[scenes/main.tscn](scenes/main.tscn)** — El `Player` apunta a `res://templates/player.tscn`. El fondo (`Water`, `Sand`) ya no son `Polygon2D` de color plano; son `TextureRect` con `stretch_mode = TILE` usando los tiles de agua y arena.

### Archivos eliminados

- `node_2d.tscn` (escena vacía suelta en la raíz)
- `char/` (carpeta con un `new_script.gd` plantilla sin usar)
- `scenes/player.tscn` y `scenes/spawnable.tscn` (reemplazados por los de `templates/`)

---

## Cómo correrlo

1. Abrir el proyecto en **Godot 4.6** (carpeta raíz: `hackaton/`). La primera vez Godot reimporta los SVGs (regenera `.godot/imported/`).
2. F5 para correr la escena principal (`scenes/main.tscn`, ya configurada en `project.godot`).
3. Si algún recurso aparece roto: *Project → Tools → Find broken dependencies* y luego *Project → Reload Current Project*.

## Para añadir un nuevo tipo de spawnable

1. Crear el SVG en `sprites/`.
2. Duplicar uno de los `templates/<algo>.tscn` y cambiar la textura, el `kind`, `is_hazard` y `points`.
3. Añadir `preload("res://templates/nuevo.tscn")` al array `_hazard_scenes` o `_bonus_scenes` en [scripts/main.gd](scripts/main.gd).

## Estructura final del repo

```
hackaton/
├── project.godot
├── icon.svg
├── CAMBIOS.md           ← este archivo
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd
│   ├── player.gd
│   └── spawnable.gd
├── sprites/             (10 SVGs)
└── templates/           (7 escenas)
```
