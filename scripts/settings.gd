extends Control

const _COLOR_HOVER := Color(1.00, 0.85, 0.00)
const _COLOR_TRACK := Color(0.05, 0.05, 0.12)

@onready var _music_slider: HSlider = $MusicSlider
@onready var _sfx_slider:   HSlider = $SfxSlider
@onready var _btn_volver:   Button  = $BtnVolver

func _ready() -> void:
	var slider_theme := _build_slider_theme()
	_music_slider.theme = slider_theme
	_sfx_slider.theme   = slider_theme

	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value   = SettingsManager.sfx_volume

	_music_slider.value_changed.connect(func(v: float) -> void:
		SettingsManager.music_volume = v)
	_sfx_slider.value_changed.connect(func(v: float) -> void:
		SettingsManager.sfx_volume = v)
	_style_back_button(_btn_volver)
	_btn_volver.pressed.connect(func() -> void:
		SettingsManager.save_settings()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

	call_deferred("_fade_in")

# Invisible hotspot over the baked "VOLVER" art: no default gray hover box,
# just a soft gold glow on hover so the button still gives feedback.
func _style_back_button(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.85, 0.0, 0.22)
	hover.set_corner_radius_all(6)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(1.0, 0.85, 0.0, 0.34)
	pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _build_slider_theme() -> Theme:
	var t := Theme.new()
	var track := StyleBoxFlat.new()
	track.bg_color = _COLOR_TRACK
	track.set_corner_radius_all(4)
	track.content_margin_top = 5.0
	track.content_margin_bottom = 5.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = _COLOR_HOVER
	fill.set_corner_radius_all(4)
	fill.content_margin_top = 5.0
	fill.content_margin_bottom = 5.0
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	return t

func _fade_in() -> void:
	for s: HSlider in [_music_slider, _sfx_slider]:
		s.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 1.0, 0.3)
