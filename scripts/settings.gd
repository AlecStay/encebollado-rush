extends Control

const _COLOR_NORMAL  := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER   := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT  := Color(1.00, 0.42, 0.21)
const _COLOR_SHADOW  := Color(0.10, 0.10, 0.18)
const _COLOR_SECTION := Color(1.00, 0.85, 0.00)

@onready var _music_slider:  HSlider     = $SettingsBox/MusicRow/MusicSlider
@onready var _music_pct:     Label       = $SettingsBox/MusicRow/MusicPct
@onready var _sfx_slider:    HSlider     = $SettingsBox/SfxRow/SfxSlider
@onready var _sfx_pct:       Label       = $SettingsBox/SfxRow/SfxPct
@onready var _fs_check:      CheckButton = $SettingsBox/FullscreenRow/FsCheck
@onready var _btn_facil:     Button      = $SettingsBox/DiffRow/BtnFacil
@onready var _btn_normal:    Button      = $SettingsBox/DiffRow/BtnNormal
@onready var _btn_dificil:   Button      = $SettingsBox/DiffRow/BtnDificil
@onready var _btn_volver:    Button      = $BtnVolver
@onready var _box:           VBoxContainer = $SettingsBox

var _diff_buttons: Array[Button] = []

func _ready() -> void:
	_diff_buttons = [_btn_facil, _btn_normal, _btn_dificil]
	_load_into_ui()
	_apply_theme()
	_connect_signals()
	call_deferred("_slide_in")

# ── Load persisted values ────────────────────────────────────────────────────

func _load_into_ui() -> void:
	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value   = SettingsManager.sfx_volume
	_fs_check.button_pressed = SettingsManager.fullscreen
	_update_music_pct(SettingsManager.music_volume)
	_update_sfx_pct(SettingsManager.sfx_volume)
	_highlight_difficulty(SettingsManager.difficulty)

# ── Theme ────────────────────────────────────────────────────────────────────

func _apply_theme() -> void:
	# Shared slider style
	var slider_theme := _build_slider_theme()

	for row: HBoxContainer in [
		$SettingsBox/MusicRow,
		$SettingsBox/SfxRow,
	]:
		var slider: HSlider = null
		for c in row.get_children():
			if c is HSlider:
				slider = c
		if slider:
			slider.theme = slider_theme

	# Section labels — gold
	for lbl: Label in [
		$SettingsBox/AudioLabel,
		$SettingsBox/DisplayLabel,
		$SettingsBox/DiffLabel,
	]:
		lbl.add_theme_color_override("font_color", _COLOR_SECTION)
		lbl.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_font_size_override("font_size", 11)

	# All plain labels — cream
	for lbl: Label in [
		$SettingsBox/MusicRow/MusicLabel,
		$SettingsBox/SfxRow/SfxLabel,
		$SettingsBox/FullscreenRow/FsLabel,
		_music_pct, _sfx_pct,
	]:
		lbl.add_theme_color_override("font_color", _COLOR_NORMAL)
		lbl.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_font_size_override("font_size", 11)

	# CheckButton
	_style_check_button(_fs_check)

	# Difficulty buttons (styled by highlight)
	_highlight_difficulty(SettingsManager.difficulty)

	# Volver button
	_style_flat_button(_btn_volver)

	# Title
	$Title.add_theme_color_override("font_color", _COLOR_NORMAL)
	$Title.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
	$Title.add_theme_constant_override("outline_size", 3)
	$Title.add_theme_font_size_override("font_size", 14)

func _build_slider_theme() -> Theme:
	var t := Theme.new()
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = _COLOR_HOVER
	grabber.corner_radius_top_left     = 6
	grabber.corner_radius_top_right    = 6
	grabber.corner_radius_bottom_left  = 6
	grabber.corner_radius_bottom_right = 6
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.3, 0.3, 0.3)
	track.corner_radius_top_left     = 3
	track.corner_radius_top_right    = 3
	track.corner_radius_bottom_left  = 3
	track.corner_radius_bottom_right = 3
	t.set_stylebox("grabber_area", "HSlider", track)
	t.set_stylebox("grabber_area_highlight", "HSlider", track)
	t.set_stylebox("slider", "HSlider", track)
	return t

func _style_check_button(btn: CheckButton) -> void:
	var t := Theme.new()
	var empty := StyleBoxEmpty.new()
	for s: String in ["normal","hover","pressed","focus","disabled"]:
		t.set_stylebox(s, "CheckButton", empty)
	t.set_color("font_color",         "CheckButton", _COLOR_NORMAL)
	t.set_color("font_hover_color",   "CheckButton", _COLOR_HOVER)
	t.set_color("font_pressed_color", "CheckButton", _COLOR_ACCENT)
	t.set_font_size("font_size",      "CheckButton", 11)
	btn.theme = t

func _style_flat_button(btn: Button) -> void:
	var t := Theme.new()
	var empty := StyleBoxEmpty.new()
	for s: String in ["normal","hover","pressed","focus","disabled"]:
		t.set_stylebox(s, "Button", empty)
	t.set_color("font_color",         "Button", _COLOR_NORMAL)
	t.set_color("font_hover_color",   "Button", _COLOR_HOVER)
	t.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	t.set_constant("outline_size",    "Button", 2)
	t.set_color("font_outline_color", "Button", _COLOR_SHADOW)
	t.set_font_size("font_size",      "Button", 12)
	btn.theme = t

func _highlight_difficulty(idx: int) -> void:
	var labels := ["FÁCIL", "NORMAL", "DIFÍCIL"]
	var colors := [Color(0.2, 0.7, 0.3), Color(1.0, 0.85, 0.0), Color(0.9, 0.25, 0.15)]

	for i: int in range(_diff_buttons.size()):
		var btn: Button = _diff_buttons[i]
		var active: bool = (i == idx)
		var t := Theme.new()
		var box := StyleBoxFlat.new()
		box.bg_color = colors[i] if active else Color(0.15, 0.15, 0.25)
		box.corner_radius_top_left     = 4
		box.corner_radius_top_right    = 4
		box.corner_radius_bottom_left  = 4
		box.corner_radius_bottom_right = 4
		box.content_margin_left   = 8.0
		box.content_margin_right  = 8.0
		box.content_margin_top    = 4.0
		box.content_margin_bottom = 4.0
		var hover := box.duplicate() as StyleBoxFlat
		hover.bg_color = colors[i].lightened(0.2) if active else Color(0.25, 0.25, 0.4)
		for s: String in ["normal","focus","disabled"]:
			t.set_stylebox(s, "Button", box)
		t.set_stylebox("hover",   "Button", hover)
		t.set_stylebox("pressed", "Button", hover)
		var txt_color := Color(0.1, 0.1, 0.1) if active else _COLOR_NORMAL
		t.set_color("font_color",         "Button", txt_color)
		t.set_color("font_hover_color",   "Button", txt_color)
		t.set_color("font_pressed_color", "Button", txt_color)
		t.set_constant("outline_size",    "Button", 1)
		t.set_color("font_outline_color", "Button", _COLOR_SHADOW)
		t.set_font_size("font_size",      "Button", 10)
		btn.theme = t

# ── Signals ──────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fs_check.toggled.connect(_on_fullscreen_toggled)
	_btn_facil.pressed.connect(func() -> void:   _set_difficulty(0))
	_btn_normal.pressed.connect(func() -> void:  _set_difficulty(1))
	_btn_dificil.pressed.connect(func() -> void: _set_difficulty(2))
	_btn_volver.pressed.connect(func() -> void:
		SettingsManager.save_settings()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func _on_music_changed(value: float) -> void:
	SettingsManager.music_volume = value
	_update_music_pct(value)

func _on_sfx_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	_update_sfx_pct(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.fullscreen = pressed
	SettingsManager.apply_fullscreen()

func _set_difficulty(idx: int) -> void:
	SettingsManager.difficulty = idx
	_highlight_difficulty(idx)

func _update_music_pct(v: float) -> void:
	_music_pct.text = "%d%%" % int(v * 100)

func _update_sfx_pct(v: float) -> void:
	_sfx_pct.text = "%d%%" % int(v * 100)

# ── Animation ────────────────────────────────────────────────────────────────

func _slide_in() -> void:
	var orig_left  := _box.offset_left
	var orig_right := _box.offset_right
	_box.offset_left  = orig_left  - 200.0
	_box.offset_right = orig_right - 200.0
	_box.modulate.a   = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(_box, "offset_left",  orig_left,  0.35)
	tw.tween_property(_box, "offset_right", orig_right, 0.35)
	tw.tween_property(_box, "modulate:a",   1.0,        0.25)
