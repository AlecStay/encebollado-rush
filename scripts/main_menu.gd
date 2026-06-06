extends Control

const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT := Color(1.00, 0.42, 0.21)
const _COLOR_SHADOW := Color(0.10, 0.10, 0.18)

@onready var _menu_container: VBoxContainer = $MenuContainer
@onready var _cursor_icon: TextureRect       = $CursorIcon
@onready var _btn_single_player: Button      = $MenuContainer/BtnSinglePlayer
@onready var _btn_multiplayer: Button        = $MenuContainer/BtnMultiplayer
@onready var _btn_shop: Button               = $MenuContainer/BtnShop
@onready var _btn_settings: Button           = $MenuContainer/BtnSettings
@onready var _btn_appearance: Button         = $MenuContainer/BtnAppearance

func _ready() -> void:
	_apply_theme()
	_connect_buttons()
	MusicManager.play_menu()
	call_deferred("_play_slide_in")

func _apply_theme() -> void:
	var empty := StyleBoxEmpty.new()
	var theme := Theme.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "Button", empty)
	theme.set_color("font_color", "Button", Color(1, 1, 1))
	theme.set_color("font_hover_color", "Button", _COLOR_HOVER)
	theme.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	theme.set_color("font_focus_color", "Button", Color(1, 1, 1))
	theme.set_constant("outline_size", "Button", 6)
	theme.set_color("font_outline_color", "Button", Color(0, 0, 0))
	theme.set_font_size("font_size", "Button", 13)
	_menu_container.theme = theme

func _connect_buttons() -> void:
	for child in _menu_container.get_children():
		if child is Button:
			child.mouse_entered.connect(_on_btn_hover.bind(child))
			child.mouse_exited.connect(_on_btn_exit)
	_btn_single_player.pressed.connect(_on_single_player_pressed)
	_btn_multiplayer.pressed.connect(_on_multiplayer_pressed)
	_btn_shop.pressed.connect(_on_shop_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_appearance.pressed.connect(_on_appearance_pressed)

func _play_slide_in() -> void:
	var orig_left: float  = _menu_container.offset_left
	var orig_right: float = _menu_container.offset_right
	_menu_container.offset_left  = orig_left  - 220.0
	_menu_container.offset_right = orig_right - 220.0
	_menu_container.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(_menu_container, "offset_left",  orig_left,  0.35)
	tween.tween_property(_menu_container, "offset_right", orig_right, 0.35)
	tween.tween_property(_menu_container, "modulate:a",   1.0,        0.25)

func _on_btn_hover(btn: Button) -> void:
	_cursor_icon.visible = true
	_cursor_icon.size = Vector2(14.0, 14.0)
	_cursor_icon.global_position = Vector2(
		btn.global_position.x - 18.0,
		btn.global_position.y + (btn.size.y - 14.0) * 0.5
	)

func _on_btn_exit() -> void:
	_cursor_icon.visible = false

func _on_single_player_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/HighScore.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_appearance_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Appearance.tscn")
