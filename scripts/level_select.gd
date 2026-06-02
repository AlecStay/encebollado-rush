extends Control

const _COLOR_NORMAL      := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER       := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT      := Color(1.00, 0.42, 0.21)
const _COLOR_SHADOW      := Color(0.10, 0.10, 0.18)
var _selected_level := 0

@onready var _btn_amanecer:  Button       = $LevelList/BtnAmanecer
@onready var _btn_tarde:     Button       = $LevelList/BtnTarde
@onready var _btn_atardecer: Button       = $LevelList/BtnAtardecer
@onready var _btn_anochecer: Button       = $LevelList/BtnAnochecer
@onready var _btn_jugar:     Button       = $BtnJugar
@onready var _btn_volver:    Button       = $BtnVolver
@onready var _level_list:    VBoxContainer = $LevelList

func _ready() -> void:
	_apply_base_theme()
	_connect_buttons()
	_update_unlocked_levels()
	_selected_level = min(GameState.current_level, SettingsManager.unlocked_levels - 1)
	_highlight_level(_selected_level)
	call_deferred("_play_slide_in")

func _apply_base_theme() -> void:
	var empty := StyleBoxEmpty.new()
	var theme := Theme.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "Button", empty)
	theme.set_color("font_color",         "Button", _COLOR_NORMAL)
	theme.set_color("font_hover_color",   "Button", _COLOR_HOVER)
	theme.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	theme.set_color("font_focus_color",   "Button", _COLOR_HOVER)
	theme.set_constant("outline_size",    "Button", 2)
	theme.set_color("font_outline_color", "Button", _COLOR_SHADOW)
	theme.set_font_size("font_size",      "Button", 11)
	_level_list.theme = theme

func _connect_buttons() -> void:
	_btn_amanecer.pressed.connect(func(): _select_level(0))
	_btn_tarde.pressed.connect(func(): _select_level(1))
	_btn_atardecer.pressed.connect(func(): _select_level(2))
	_btn_anochecer.pressed.connect(func(): _select_level(3))
	_btn_jugar.pressed.connect(_on_jugar_pressed)
	_btn_volver.pressed.connect(_on_volver_pressed)

func _select_level(idx: int) -> void:
	if idx >= SettingsManager.unlocked_levels:
		return
	_selected_level = idx
	_highlight_level(idx)

func _update_unlocked_levels() -> void:
	var btns := [_btn_amanecer, _btn_tarde, _btn_atardecer, _btn_anochecer]
	for i in btns.size():
		if i >= SettingsManager.unlocked_levels:
			btns[i].disabled = true
			btns[i].text = GameState.LEVELS[i].name + " (Bloqueado)"
			btns[i].add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
		else:
			btns[i].disabled = false
			btns[i].text = GameState.LEVELS[i].name

func _highlight_level(idx: int) -> void:
	var btns := [_btn_amanecer, _btn_tarde, _btn_atardecer, _btn_anochecer]
	for i in btns.size():
		var box := StyleBoxFlat.new()
		if i == idx:
			box.bg_color              = Color(1.0, 0.85, 0.0, 0.18)
			box.border_color          = Color(1.0, 0.85, 0.0, 0.85)
			box.border_width_left     = 2; box.border_width_right  = 2
			box.border_width_top      = 2; box.border_width_bottom = 2
			box.corner_radius_top_left    = 3; box.corner_radius_top_right   = 3
			box.corner_radius_bottom_left = 3; box.corner_radius_bottom_right = 3
		else:
			box.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		btns[i].add_theme_stylebox_override("normal",  box)
		btns[i].add_theme_stylebox_override("hover",   box)
		btns[i].add_theme_stylebox_override("pressed", box)

func _play_slide_in() -> void:
	var orig_left  := _level_list.offset_left
	var orig_right := _level_list.offset_right
	_level_list.offset_left  = orig_left  - 220.0
	_level_list.offset_right = orig_right - 220.0
	_level_list.modulate.a   = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(_level_list, "offset_left",  orig_left,  0.35)
	tween.tween_property(_level_list, "offset_right", orig_right, 0.35)
	tween.tween_property(_level_list, "modulate:a",   1.0,        0.25)

func _on_jugar_pressed() -> void:
	GameState.current_level    = _selected_level
	SettingsManager.save_settings()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
