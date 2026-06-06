extends Node
## Debug cheats (keyboard). Active ONLY in debug builds — excluded from release exports.
##   Ctrl+C : +1,000,000 Energía Ancestral (wallet)
##   Alt+Q  : unlock all levels
##   Alt+W  : complete the current level instantly (gameplay only)
##   Alt+E  : play the intro cutscene (ignores intro_seen / unlocks)
##   Alt+R  : play the ending cutscene (gameplay only)
## Flip ENABLED to false to turn them off without removing the autoload.

const ENABLED := true
const TOAST_TIME := 1.6

var _active := false
var _toast: Label
var _toast_left := 0.0

func _ready() -> void:
	_active = ENABLED and OS.is_debug_build()
	if not _active:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep working while the game is paused
	_build_toast()

func _build_toast() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128                         # above the gameplay HUD
	add_child(layer)
	_toast = Label.new()
	_toast.anchor_right  = 1.0
	_toast.offset_top    = 8.0
	_toast.offset_bottom = 30.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_toast.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.18))
	_toast.add_theme_constant_override("outline_size", 4)
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.visible = false
	layer.add_child(_toast)

func _process(delta: float) -> void:
	if _toast and _toast.visible:
		_toast_left -= delta
		if _toast_left <= 0.0:
			_toast.visible = false

func _input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if k.keycode == KEY_C and k.ctrl_pressed:
		SettingsManager.ancestral_energy += 1_000_000
		SettingsManager.save_settings()
		_notify("+1.000.000  Energía Ancestral")
		_refresh()
	elif k.keycode == KEY_Q and k.alt_pressed:
		SettingsManager.unlocked_levels = GameState.LEVELS.size()
		SettingsManager.save_settings()
		_notify("Todos los niveles desbloqueados")
		_refresh()
	elif k.keycode == KEY_W and k.alt_pressed:
		var scene := get_tree().current_scene
		if scene and scene.has_method("debug_complete_level"):
			scene.debug_complete_level()
			_notify("Nivel completado")
		else:
			_notify("Alt+W: solo en gameplay")
	elif k.keycode == KEY_E and k.alt_pressed:
		_notify("Intro (debug)")
		get_tree().change_scene_to_file("res://scenes/Story.tscn")
	elif k.keycode == KEY_R and k.alt_pressed:
		var scene := get_tree().current_scene
		if scene and scene.has_method("debug_play_ending"):
			scene.debug_play_ending()
			_notify("Escena final (debug)")
		else:
			_notify("Alt+R: solo en gameplay")

func _refresh() -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("debug_refresh"):
		scene.debug_refresh()

func _notify(msg: String) -> void:
	print("[DEBUG] ", msg)
	if _toast:
		_toast.text = msg
		_toast.visible = true
		_toast_left = TOAST_TIME
