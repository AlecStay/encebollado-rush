extends Node

const CONFIG_PATH := "user://settings.cfg"

var music_volume := 0.8
var sfx_volume   := 1.0
var fullscreen   := false
var difficulty   := 1  # 0=Fácil  1=Normal  2=Difícil

func _ready() -> void:
	load_settings()
	apply_fullscreen()

func apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen \
			else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func get_music_db() -> float:
	return -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)

func get_sfx_db() -> float:
	return -80.0 if sfx_volume <= 0.0 else linear_to_db(sfx_volume)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio",    "music_volume", music_volume)
	cfg.set_value("audio",    "sfx_volume",   sfx_volume)
	cfg.set_value("display",  "fullscreen",   fullscreen)
	cfg.set_value("gameplay", "difficulty",   difficulty)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	music_volume = cfg.get_value("audio",    "music_volume", 0.8)
	sfx_volume   = cfg.get_value("audio",    "sfx_volume",   1.0)
	fullscreen   = cfg.get_value("display",  "fullscreen",   false)
	difficulty   = cfg.get_value("gameplay", "difficulty",   1)
