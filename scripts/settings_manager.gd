extends Node

const CONFIG_PATH := "user://settings.cfg"

var music_volume := 0.8
var sfx_volume   := 1.0
var unlocked_levels := 1
var intro_seen := false

var ancestral_energy := 0
var unlocked_boards: Array = ["standard"]
var equipped_board := "standard"

# Cosmetic skins (visual only — independent of the Shop's gameplay "boards").
# Bought with Energía Ancestral, the same currency the Shop uses for boards.
var equipped_skin := "default"
var unlocked_skins: Array = ["default"]
const SKIN_ORDER: Array = ["default", "gamba", "ray", "silla"]
const SKINS := {
	"default": { "name": "Clásico", "path": "",                          "preview": "res://sprites/player_s.png",       "price": 0 },
	"gamba":   { "name": "Gamba",   "path": "res://sprites/skins/gamba/", "preview": "res://sprites/skins/gamba/s.png", "price": 3000 },
	"ray":     { "name": "Ray",     "path": "res://sprites/skins/ray/",   "preview": "res://sprites/skins/ray/s.png",   "price": 6000 },
	"silla":   { "name": "Silla",   "path": "res://sprites/skins/silla/", "preview": "res://sprites/skins/silla/s.png", "price": 10000 },
}

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
	cfg.set_value("story",    "intro_seen", intro_seen)
	cfg.set_value("economy",  "ancestral_energy", ancestral_energy)
	cfg.set_value("economy",  "unlocked_boards", unlocked_boards)
	cfg.set_value("economy",  "equipped_board", equipped_board)
	cfg.set_value("appearance", "equipped_skin", equipped_skin)
	cfg.set_value("appearance", "unlocked_skins", unlocked_skins)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	music_volume = cfg.get_value("audio",    "music_volume", 0.8)
	sfx_volume   = cfg.get_value("audio",    "sfx_volume",   1.0)
	unlocked_levels = cfg.get_value("gameplay", "unlocked_levels", 1)
	intro_seen      = cfg.get_value("story",    "intro_seen", false)
	ancestral_energy = cfg.get_value("economy", "ancestral_energy", 0)
	unlocked_boards = cfg.get_value("economy", "unlocked_boards", ["standard"])
	equipped_board = cfg.get_value("economy", "equipped_board", "standard")
	equipped_skin = cfg.get_value("appearance", "equipped_skin", "default")
	unlocked_skins = cfg.get_value("appearance", "unlocked_skins", ["default"])
	if not (equipped_skin in unlocked_skins):
		equipped_skin = "default"

func unlock_level(level_idx: int) -> void:
	var new_unlocked = level_idx + 1
	if new_unlocked > unlocked_levels:
		unlocked_levels = new_unlocked
		save_settings()
