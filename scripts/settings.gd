extends Control

@onready var _music_slider: HSlider = $MusicSlider
@onready var _sfx_slider: HSlider   = $SfxSlider
@onready var _btn_volver: Button    = $BtnVolver

var _sfx_test_player: AudioStreamPlayer
var _sfx_samples: Array[AudioStream] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	MusicManager.play_menu()
	_rng.randomize()
	_setup_sfx_test()

	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value   = SettingsManager.sfx_volume
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	_style_back_button(_btn_volver)
	_btn_volver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _setup_sfx_test() -> void:
	_sfx_test_player = AudioStreamPlayer.new()
	add_child(_sfx_test_player)
	for p in [
		"res://music/sfx_buff.wav", "res://music/sfx_coin.wav",
		"res://music/sfx_jump.wav", "res://music/sfx_bomb.wav",
		"res://music/sfx_boss1.wav", "res://music/sfx_boss_spiral.wav",
	]:
		if ResourceLoader.exists(p):
			_sfx_samples.append(load(p))

func _on_music_changed(v: float) -> void:
	SettingsManager.music_volume = v
	MusicManager.set_volume_db(SettingsManager.get_music_db())
	SettingsManager.save_settings()

func _on_sfx_changed(v: float) -> void:
	SettingsManager.sfx_volume = v
	SettingsManager.save_settings()
	# test audible: un SFX random cada vez que se mueve la barra
	if _sfx_samples.is_empty():
		return
	_sfx_test_player.stream    = _sfx_samples[_rng.randi_range(0, _sfx_samples.size() - 1)]
	_sfx_test_player.volume_db = SettingsManager.get_sfx_db()
	_sfx_test_player.play()

# Hotspot invisible sobre el arte "VOLVER" del fondo (mismo patrón que la tienda).
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
