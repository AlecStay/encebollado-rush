# Resumen Completo y Guía para Diseño (Walkthrough)

¡El juego ya cuenta con todas sus mecánicas principales, tienda, progresión y sistema de combos! Todo está funcionando en el código. Esta es la guía para el equipo de diseño sobre lo que falta por decorar e implementar visualmente:

## 1. Economía (Energía Ancestral)
Se ha configurado la economía global. Ahora, cada vez que terminas una partida (ya sea ganando un nivel o perdiendo todas tus vidas), **tus puntos finales se suman permanentemente a tu Energía Ancestral**. Este progreso se guarda automáticamente para que nunca pierdas tu dinero al cerrar el juego.

## 2. Nueva Cinemática de Introducción (Estilo Hotline Miami)
Se requiere añadir una secuencia introductoria de historia que se muestre **sólo la primera vez que juegas** y antes de entrar al Nivel 1. Debe tener cuadros de diálogo de estilo *Hotline Miami* (con los rostros de los personajes y texto escribiéndose). 

**La Historia (Lore):**
> El protagonista es un surfista local de Manta que un día encuentra un fragmento de piedra extraña tallada en la playa (un trozo de una Silla en U). Al tocarla, entra en un trance del que no puede escapar.
>
> Aparece en una habitación oscura llena de neblina. Sentados en cuatro sillas de piedra gigantes, hay cuatro caciques con máscaras de jaguar y ojos brillantes que le hablan telepáticamente:
> 
> *"Jocay está despertando, Cholo. Las aguas reclaman su tributo. Si dejas que la ola muera, tu mente se ahogará con ella. Corre la estela de los dioses, recoge la moneda roja del océano y encuentra la Esmeralda de Umiña... o despierta en el fondo del mar."*
>
> El protagonista despierta de golpe, de pie sobre su tabla en medio de una ola gigante con los ojos inyectados en sangre y una interfaz mística flotando en su visión.

**Tarea de Diseño / Programación visual:** 
- Crear una nueva escena (ej. `IntroCinematic.tscn`) que tenga un fondo oscuro.
- Dibujar los retratos de los Caciques y del Protagonista para los diálogos.
- Una vez termine el diálogo, hacer una transición rápida al `LevelSelect.tscn` o directamente cargar el Nivel 1.

He creado la interfaz `Shop.tscn`, a la que puedes acceder desde el botón **"TIENDA DE ITEMS"** en el menú principal.
- Arriba a la derecha verás tu contador de Energía Ancestral.
- Verás una lista con todas las tablas.

## 3. Feedback Visual de Combos y Salto
- **Salto/Voltereta:** Ahora hay un botón abajo a la derecha. Cuando el jugador lo presiona, el personaje es invulnerable por 1 segundo, da un giro y si un objeto pasa rozándolo, hace un "Esquive Perfecto".
- **Tarea de Diseño:** El botón de salto (`BtnDodge` en `main.tscn`) necesita un icono chulo (quizás una flecha en giro o un símbolo de viento). 
- El texto del combo ahora tiembla de manera frenética en la pantalla. Puedes ajustar los colores y la fuente en el `ComboLabel` (`main.tscn`) para que se vea más místico/sangriento dependiendo de lo alto que sea el multiplicador.

## 4. Sprites de Objetos Faltantes y Auras
- Se necesitan reemplazar las imágenes temporales por:
  - **Spondylus:** Moneda roja del océano.
  - **Esmeralda de Umiña:** El objeto que da la súper invulnerabilidad de 15s.
  - **Obstáculos:** Asegurarse de tener todas las variantes (rocas, barcos, tiburones) integradas.
- **Auras de Colores (IMPORTANTE):** Para ayudar al jugador a identificar rápidamente qué es bueno y qué es malo cuando la pantalla va muy rápido, los objetos deben tener auras o brillos de distintos colores (ya sea mediante un Shader, partículas o un `WorldEnvironment` Glow). Por ejemplo:
  - Aura **Verde/Dorada** para los bufos positivos (Ceviche, Esmeralda, Estrella).
  - Aura **Roja/Oscura** para los obstáculos mortales (Barcos, Tiburones).
  - Aura **Brillante/Púrpura** para la Energía Ancestral y Spondylus.
  - Si tienes un Combo x0.5, tendrás un **50% de probabilidad** de ganar **2 Spondylus** en lugar de 1 cada vez que recojas uno.
  - Si logras llevar tu combo al máximo (x1.0), **tendrás un 100% de probabilidad** de ganar siempre el doble de Spondylus.
- ¡Ojo! Si te choca algún obstáculo mientras NO estás dando la voltereta, recibirás daño normal y **tu racha de combo caerá a 0**.

## 5. Rediseño Total del HUD (Móvil)
- **Tarea de Diseño:** Actualmente la interfaz de usuario en el mapa (HUD) usa los botones grises y barras de progreso por defecto de Godot. Se requiere rediseñar toda la interfaz para que luzca muy atractiva y moderna en dispositivos móviles:
  - **Barra de Vida:** Crear texturas dinámicas (quizás una barra con líquido rojo o corazones estilizados).
  - **Botón de Salto y Pausa:** Diseñar botones táctiles con relieve, íconos y texturas adaptadas a móvil (estilo joystick/botones virtuales semitransparentes).
  - **Contadores (Monedas y Puntos):** Añadir paneles decorados (ej. pergaminos o maderas talladas) detrás de los textos de Spondylus y Puntos para que resalten sobre la acción.

## 6. Tareas Técnicas (Cambio de Monedas)
> [!NOTE]
> **Nota para el desarrollador/diseñador:** La moneda principal de la tienda (los puntos acumulados) ha sido renombrada en el código y en la UI. Ahora se llama **"Energía Ancestral"** (en código `ancestral_energy`). Los **Spondylus** se mantienen exclusivamente como el objetivo recolectable dentro del nivel para poder avanzar al siguiente mapa. No necesitas modificar variables, pero tenlo en cuenta al diseñar los íconos de la tienda.
