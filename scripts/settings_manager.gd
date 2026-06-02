extends Node

const CONFIG_PATH := "user://settings.cfg"

var music_volume := 0.8
var sfx_volume   := 1.0
var unlocked_levels := 1

var ancestral_energy := 0
var unlocked_boards: Array = ["standard"]
var equipped_board := "standard"

func _ready() -> void:
	load_settings()

func get_music_db() -> float:
	return -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)

func get_sfx_db() -> float:
	return -80.0 if sfx_volume <= 0.0 else linear_to_db(sfx_volume)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio",    "music_volume", music_volume)
	cfg.set_value("audio",    "sfx_volume",   sfx_volume)
	cfg.set_value("gameplay", "unlocked_levels", unlocked_levels)
	cfg.set_value("economy",  "ancestral_energy", ancestral_energy)
	cfg.set_value("economy",  "unlocked_boards", unlocked_boards)
	cfg.set_value("economy",  "equipped_board", equipped_board)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	music_volume = cfg.get_value("audio",    "music_volume", 0.8)
	sfx_volume   = cfg.get_value("audio",    "sfx_volume",   1.0)
	unlocked_levels = cfg.get_value("gameplay", "unlocked_levels", 1)
	ancestral_energy = cfg.get_value("economy", "ancestral_energy", 0)
	unlocked_boards = cfg.get_value("economy", "unlocked_boards", ["standard"])
	equipped_board = cfg.get_value("economy", "equipped_board", "standard")

func unlock_level(level_idx: int) -> void:
	var new_unlocked = level_idx + 1
	if new_unlocked > unlocked_levels:
		unlocked_levels = new_unlocked
		save_settings()
