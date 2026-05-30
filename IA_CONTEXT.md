# Contexto para IA - Encebollado Rush (Cambios y Arquitectura)

Este archivo sirve como referencia estructurada para que cualquier Modelo de Inteligencia Artificial (IA) o desarrollador entienda rápidamente las modificaciones y mejoras implementadas en este repositorio en comparación con la versión original de **Encebollado Rush** (https://github.com/AlecStay/encebollado-rush).

---

## 📊 Tabla Comparativa: Repositorio Original vs. Estado Actual

| Característica | Repositorio Original (AlecStay) | Estado Actual (Con tus Cambios) |
| :--- | :--- | :--- |
| **Jugabilidad Base** | Coger comida (encebollado/ceviche) para ganar 100 pts. Evitar tiburones/botes. | Sin límite de victoria directa por puntos. Dificultad infinita y progresiva. Guardado automático de puntajes. |
| **Pantallas / Escenas** | Únicamente Menú Principal (`MainMenu`) y Nivel de Juego (`main`). | **Añadidas 3 escenas nuevas:** Selección de Nivel (`LevelSelect`), Tabla de Puntajes (`HighScore`), y Configuración (`Settings`). |
| **Movimiento del Jugador** | Sprite plano que cambia de parpadeo al recibir golpe (animación simple). | **Sprite direccional de 8 vías** (`player_e`, `player_nw`, etc.). El sprite cambia dinámicamente según la dirección del movimiento. |
| **Dificultad** | Fija. Velocidad de scroll constante. | **Ajustes de dificultad** (Fácil, Normal, Difícil) con multiplicadores de spawn y velocidad. **Dificultad progresiva** (+15% de velocidad cada 2 minutos). |
| **Estética y Temas** | Un único fondo de mar y arena fijo. | **Transición dinámica de mapas** (Amanecer, Tarde, Atardecer, Noche) con degradado/Tweening de colores de agua, arena, iluminación y ciclo sol/luna. |
| **Eventos de Juego** | Comida estándar y popup de foto de manta. | **Nivel Bonus Temporal** (15 segundos de spawn frenético de comida al recoger un ingrediente dorado especial, sin peligros activos). |
| **Fondo / Decoración** | Vacío (solo color plano de agua). | **Decoraciones flotantes** con scroll parallax lento (burbujas, espuma, estrellas de mar, palmeras). |
| **Persistencia** | No existía persistencia de datos ni configuraciones. | **Autoloads y persistencia en archivos localizados:** Sonidos, volumen, pantalla completa, dificultad y top 10 puntajes (JSON). |

---

## 🛠️ Arquitectura de Singletons (Autoloads)
Se añadieron 3 scripts globales (Autoloads) en `project.godot` para la persistencia del estado:

1. **`GameState` (`scripts/game_state.gd`)**:
   - Almacena el nivel de inicio seleccionado (`current_level`).
   - Define el array constante de niveles `LEVELS` con parámetros estéticos (modulación del agua, arena, luz ambiental `CanvasModulate`, posición del sol/luna e indicador de noche).
2. **`SettingsManager` (`scripts/settings_manager.gd`)**:
   - Administra configuraciones persistentes (Volumen de música [0-1], Volumen de SFX [0-1], Pantalla completa [bool], y Dificultad [0, 1, 2]).
   - Guarda/carga datos localmente en `user://settings.cfg`.
3. **`HighScoreManager` (`scripts/high_score_manager.gd`)**:
   - Gestiona el historial de puntajes en formato JSON en `user://highscores.json`.
   - Limita el historial al Top 10 mejores partidas, ordenándolas de mayor a menor y registrando la fecha y si la partida fue ganada o perdida.

---

## 💻 Detalles Técnicos de Implementación

### 1. Movimiento y Animación de 8 Direcciones (`scripts/player.gd`)
* **Lógica**: En `_physics_process`, se captura la dirección del movimiento del jugador (`move_dir`). Si el jugador se mueve, se llama a `_set_facing(dir)`.
* **Cálculo de octantes**: El ángulo del vector se clasifica en uno de los 8 octantes del círculo trigonométrico (E, SE, S, SW, W, NW, N, NE).
* **Texturas**: Se asigna el `Texture2D` correspondiente (`tex_n`, `tex_ne`, etc.) cargado en el editor al nodo `Sprite2D` (`$Body`), reemplazando la animación manual.

### 2. Transición y Ciclo de Mapas (`scripts/main.gd`)
* **Activación**: Al rebasar múltiplos de `500 puntos` (`MAP_SCORE_STEP`), la función `_check_map_transition()` calcula el nuevo mapa a cargar.
* **Transición Visual**: Para evitar cambios bruscos, se crea un `Tween` en paralelo que desvanece suavemente (`MAP_FADE_TIME = 1.0s`):
  - La modulación del color del agua (`_water.modulate`).
  - La modulación del color de la arena (`_sand.modulate`).
  - El color ambiental del juego (`_canvas_modulate.color`).
  - La posición física y sprite del sol/luna (`_sun`).

### 3. Nivel Bonus (`scripts/main.gd`)
* **Disparador**: Al recoger el ingrediente especial "dorado" (`res://templates/golden.tscn`), se llama a `_enter_bonus_level()`.
* **Mecánica**:
  - Detiene temporalmente los temporizadores normales de peligros y comida.
  - Elimina los peligros existentes en pantalla.
  - Muestra un cartel en pantalla con la cuenta atrás (`¡NIVEL BONUS! XXs`).
  - Activa un temporizador frenético (`FreneticTimer`) que genera comida a alta velocidad (`0.12 - 0.28` segundos de spawn).
  - Al terminar el contador (15s), limpia los objetos bonus restantes y reanuda el bucle normal.

### 4. Dificultad Progresiva y Ajustes
* **Configuración Inicial**: La dificultad elegida (Fácil/Normal/Difícil) escala los tiempos de spawn de peligros y comida, además de la velocidad de caída inicial.
* **Escalado Progresivo**: Un timer de dificultad (`DifficultyTimer`) aumenta la velocidad del mapa por un factor de `1.15` (+15%) cada 120 segundos, ofreciendo un reto infinito.

### 5. Sistema de Decoraciones (`scripts/decoration.gd`)
* **Spawneo**: El juego genera aleatoriamente burbujas, espuma de mar, estrellas de mar y palmeras en la parte superior de la pantalla.
* **Movimiento**: Se desplazan hacia abajo con un factor de velocidad reducido (`DECOR_SCROLL_FACTOR = 0.6`) respecto a la velocidad de la corriente del juego, creando un efecto de profundidad/paralaje 2D simple.

---

## 📂 Estructura de Directorios Actualizada

```text
Encebollado_Rush/
├── project.godot
├── icon.svg
├── CAMBIOS.md               # Contexto general histórico de la sesión anterior
├── IA_CONTEXT.md            # Este archivo (Detalle técnico de cambios avanzados)
├── scenes/
│   ├── main.tscn            # Escena del gameplay principal
│   ├── MainMenu.tscn        # Menú principal conectado a las nuevas escenas
│   ├── LevelSelect.tscn     # NUEVO: Pantalla de selección de nivel y dificultad
│   ├── HighScore.tscn       # NUEVO: Pantalla de récord de puntajes
│   └── Settings.tscn        # NUEVO: Menú de opciones de audio y pantalla completa
├── scripts/
│   ├── main.gd              # Gameplay, dificultad, bonus, transición y decoraciones
│   ├── main_menu.gd         # Lógica de navegación del menú principal
│   ├── player.gd            # Movimiento de 8 direcciones y parpadeo de daño
│   ├── spawnable.gd         # Script común para botes, comida, etc.
│   ├── decoration.gd        # NUEVO: Control de movimiento y limpieza de decoraciones de fondo
│   ├── game_state.gd        # NUEVO (Autoload): Estado global del nivel y temas visuales
│   ├── settings_manager.gd  # NUEVO (Autoload): Gestión e interfaz de guardado de ajustes
│   ├── settings.gd          # NUEVO: Enlace de la interfaz gráfica de configuración
│   ├── high_score_manager.gd# NUEVO (Autoload): Serialización JSON de los puntajes
│   └── high_score.gd        # NUEVO: Dibujado dinámico de la tabla de récords
├── sprites/
│   ├── player_idle.svg
│   ├── player_swim.svg
│   ├── ... (8 SVGs originales)
│   ├── golden.svg           # NUEVO: Sprite del ingrediente dorado
│   ├── sun.svg / moon.svg   # NUEVO: Sol y Luna vectoriales para el ciclo de mapas
│   ├── player_n.png etc.    # NUEVO: Texturas del jugador para las 8 direcciones
│   └── ..._new.png          # NUEVO: Arte final para comida, peligros y fondos
└── templates/
    ├── player.tscn
    ├── ... (templates originales)
    ├── golden.tscn          # NUEVO: Template del ingrediente de nivel bonus
    ├── rock.tscn            # NUEVO: Template de peligro (roca)
    ├── trash.tscn           # NUEVO: Template de peligro (basura)
    ├── cola.tscn            # NUEVO: Comida (Gaseosa)
    ├── corviche.tscn        # NUEVO: Comida (Corviche)
    └── decor_...tscn        # NUEVO: Templates para decoraciones de fondo
```
