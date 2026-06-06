extends Control
## Cutscene de diálogo: una imagen por escena, varias líneas que avanzan con tap/click.
## Reutilizable: intro (escena propia) y final (overlay instanciado en main.gd).

signal finished

@export var story_id := "intro"      # "intro" | "ending"
@export var next_scene := ""         # si != "" cambia de escena al terminar
@export var pause_during := false    # overlay sobre el juego en pausa

const INTRO := [
	{ "image": "res://images/escena dialogo 1.png", "lines": [
		"Una tarde cualquiera en la playa. Las olas rompían suaves, el clima estaba perfecto para cerrar el día en el agua.",
		"Pero algo en la arena me hizo frenar.",
		"Era un pedazo de piedra negra, pesada, tallada con formas súper antiguas. Parecía el fragmento de una de esas sillas manteñas en U.",
	]},
	{ "image": "res://images/escena dialogo 2.png", "lines": [
		"Sin pensarlo mucho, la toqué. Estaba helada.",
		"En un segundo, el ruido del mar y del viento desapareció por completo.",
		"Todo se volvió negro. Sentí que me caía al vacío, paralizado. Un trance del que no me podía soltar.",
	]},
	{ "image": "res://images/escena dialogo 3.png", "lines": [
		"Aparecí de la nada en un cuarto oscuro, lleno de neblina pesada.",
		"Frente a mí había cuatro tronos gigantes de piedra.",
		"En ellos estaban sentados cuatro caciques. Llevaban máscaras de jaguar y sus ojos brillaban como antorchas.",
		"No movieron la boca en ningún momento, pero sus voces empezaron a retumbar directamente dentro de mi cabeza.",
	]},
	{ "image": "res://images/escena dialogo 4.png", "lines": [
		"—Jocay está despertando, Cholo.",
		"—Las aguas reclaman su tributo. Si dejas que la ola muera, tu mente se ahogará con ella.",
		"—Corre la estela de los dioses, recoge la moneda roja del océano...",
		"—Y encuentra la Esmeralda de Umiña... o despierta en el fondo del mar.",
	]},
	{ "image": "res://images/escena dialogo 5.png", "lines": [
		"Abrí los ojos de golpe, jalando aire como si me estuviera ahogando.",
		"Ya no estaba en la arena. Estaba de pie sobre mi tabla, yendo a toda velocidad en medio de una ola gigante.",
		"Mis ojos me ardían como la sangre.",
		"Y ahí, flotando frente a mi cara y brillando sobre el agua, apareció una especie de visión... una interfaz mística.",
		"No había vuelta atrás. La carrera había empezado.",
	]},
]

const ENDING := [
	{ "image": "res://images/escena final.png", "lines": [
		"—Has domado la estela, Cholo. Jocay vuelve a dormir en paz.",
		"La voz de los caciques hizo eco por última vez y desperté de golpe, tragando arena.",
		"Estaba de vuelta en la orilla. Ya era de noche y el mar estaba en silencio.",
		"Todo el cuerpo me pesaba. ¿Me había caído de la tabla? ¿Todo fue un sueño?",
		"Abrí mi puño despacio, casi con miedo de mirar.",
		"El pedazo de piedra negra había desaparecido. En su lugar, tenía una pequeña esmeralda verde y brillante. Aún estaba tibia.",
		"Miré hacia las olas oscuras y sonreí. Ya sabía lo que había allá abajo.",
	]},
]

@onready var _bg: TextureRect = $Bg
@onready var _narration: Label = $TextPanel/Narration

var _pages: Array = []
var _pi := 0
var _li := 0
var _finished := false

func _ready() -> void:
	_pages = ENDING if story_id == "ending" else INTRO
	if pause_during:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
	_render()

func _input(event: InputEvent) -> void:
	var tap := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	var click := event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if tap or click:
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	if _finished:
		return
	_li += 1
	if _li >= int((_pages[_pi].lines as Array).size()):
		_pi += 1
		_li = 0
		if _pi >= _pages.size():
			_finish()
			return
	_render()

func _render() -> void:
	var page: Dictionary = _pages[_pi]
	var tex_path: String = page.image
	if _bg and ResourceLoader.exists(tex_path):
		_bg.texture = load(tex_path)
	if _narration:
		_narration.text = page.lines[_li]

func _finish() -> void:
	_finished = true
	set_process_input(false)   # corta taps residuales antes del queue_free/cambio diferido
	finished.emit()
	if story_id == "intro":
		SettingsManager.intro_seen = true
		SettingsManager.save_settings()
	get_tree().paused = false
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
	else:
		queue_free()
