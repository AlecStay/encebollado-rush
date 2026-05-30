extends Node2D

@export var scroll_speed := 120.0
@export var hazard_spawn_min := 0.7
@export var hazard_spawn_max := 1.3
@export var bonus_spawn_min := 0.8
@export var bonus_spawn_max := 1.6
@export var photo_texture: Texture2D
@export var music_stream: AudioStream
@export var hit_sfx: AudioStream
@export var bonus_sfx: AudioStream

const DAMAGE_FRACTION   := 0.25
const INVULNERABLE_TIME := 1.0
const SPAWN_MARGIN      := 16.0
const GOLDEN_CHANCE     := 0.08
const BONUS_DURATION    := 15.0
const FRENETIC_MIN      := 0.12
const FRENETIC_MAX      := 0.28

const MAP_SCORE_STEP    := 500      # puntos para cambiar de mapa
const DIFFICULTY_PERIOD := 120.0    # segundos
const DIFFICULTY_FACTOR := 1.15     # +15% por periodo
const MAP_FADE_TIME     := 1.0

var _lives        := 3
var _health       := 1.0
var _score        := 0
var _state        := "playing"
var _bonus_active := false
var _current_map  := 0
var _rng          := RandomNumberGenerator.new()

var _hazard_scenes: Array[PackedScene] = [
	preload("res://templates/boat.tscn"),
	preload("res://templates/shark.tscn"),
	preload("res://templates/rock.tscn"),
	preload("res://templates/trash.tscn"),
]

var _bonus_scenes: Array[PackedScene] = [
	preload("res://templates/encebollado.tscn"),
	preload("res://templates/ceviche.tscn"),
	preload("res://templates/cola.tscn"),
	preload("res://templates/corviche.tscn"),
]

var _golden_scene: PackedScene = preload("res://templates/golden.tscn")

var _decor_scenes: Array[PackedScene] = [
	preload("res://templates/decor_bubbles.tscn"),
	preload("res://templates/decor_foam.tscn"),
	preload("res://templates/decor_starfish.tscn"),
	preload("res://templates/decor_palm.tscn"),
]

const DECOR_SPAWN_MIN := 1.0
const DECOR_SPAWN_MAX := 2.4
const DECOR_SCROLL_FACTOR := 0.6

@onready var _player              = $Player
@onready var _spawnables_root     = $Spawnables
@onready var _hazard_timer: Timer = $Spawner/HazardTimer
@onready var _bonus_timer: Timer  = $Spawner/BonusTimer
@onready var _frenetic_timer: Timer = $Spawner/FreneticTimer
@onready var _difficulty_timer: Timer = $Spawner/DifficultyTimer
@onready var _decor_timer: Timer      = $Spawner/DecorTimer
@onready var _decorations_root        = $Decorations
@onready var _health_bar: ProgressBar = $HUD/HealthBar
@onready var _lives_label: Label      = $HUD/LivesLabel
@onready var _score_label: Label      = $HUD/ScoreLabel
@onready var _state_label: Label      = $HUD/StateLabel
@onready var _bonus_label: Label      = $HUD/BonusLabel
@onready var _bonus_countdown: Timer  = $HUD/BonusCountdown
@onready var _photo_popup: Panel      = $HUD/PhotoPopup
@onready var _photo_rect: TextureRect = $HUD/PhotoPopup/PhotoRect
@onready var _photo_timer: Timer      = $HUD/PhotoPopup/HideTimer
@onready var _music_player: AudioStreamPlayer = $Audio/MusicPlayer
@onready var _sfx_player: AudioStreamPlayer   = $Audio/SfxPlayer
@onready var _btn_reintentar: Button     = $HUD/BtnReintentar
@onready var _btn_menu_principal: Button = $HUD/BtnMenuPrincipal
@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _sun: Sprite2D       = $Background/Sun
@onready var _water: TextureRect  = $Background/Water
@onready var _sand: TextureRect   = $Background/Sand

func _ready() -> void:
	_rng.randomize()
	_current_map = GameState.current_level
	_apply_level_theme(_current_map, true)
	_apply_difficulty()
	_update_ui()
	_setup_photo_popup()
	_start_music()
	_bonus_label.add_theme_font_size_override("font_size", 18)
	_bonus_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_bonus_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.18))
	_bonus_label.add_theme_constant_override("outline_size", 3)
	_hazard_timer.timeout.connect(_on_hazard_timer_timeout)
	_bonus_timer.timeout.connect(_on_bonus_timer_timeout)
	_photo_timer.timeout.connect(_on_photo_timer_timeout)
	_frenetic_timer.timeout.connect(_on_frenetic_timer_timeout)
	_bonus_countdown.timeout.connect(_on_bonus_countdown_timeout)
	_difficulty_timer.timeout.connect(_on_difficulty_timer_timeout)
	_difficulty_timer.wait_time = DIFFICULTY_PERIOD
	_difficulty_timer.start()
	_decor_timer.timeout.connect(_on_decor_timer_timeout)
	_schedule_hazard()
	_schedule_bonus()
	_schedule_decor()
	_btn_reintentar.pressed.connect(_on_reintentar_pressed)
	_btn_menu_principal.pressed.connect(_on_menu_principal_pressed)

func _apply_difficulty() -> void:
	match SettingsManager.difficulty:
		0:
			hazard_spawn_min *= 1.5
			hazard_spawn_max *= 1.7
			bonus_spawn_min  *= 0.65
			bonus_spawn_max  *= 0.75
			scroll_speed     *= 0.80
		2:
			hazard_spawn_min *= 0.60
			hazard_spawn_max *= 0.70
			bonus_spawn_min  *= 1.25
			bonus_spawn_max  *= 1.35
			scroll_speed     *= 1.30

func _apply_level_theme(idx: int, instant: bool) -> void:
	var lvl: Dictionary = GameState.LEVELS[idx]
	if lvl.is_night:
		_sun.texture = load("res://sprites/moon.svg")
	else:
		_sun.texture = load("res://sprites/sun.svg")
	_sun.scale = Vector2(2.0, 2.0)
	if instant:
		_water.modulate        = lvl.water_modulate
		_sand.modulate         = lvl.sand_modulate
		_canvas_modulate.color = lvl.ambient
		_sun.position          = Vector2(lvl.sun_x, lvl.sun_y)
		return
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_water, "modulate", lvl.water_modulate, MAP_FADE_TIME)
	tween.tween_property(_sand,  "modulate", lvl.sand_modulate,  MAP_FADE_TIME)
	tween.tween_property(_canvas_modulate, "color", lvl.ambient, MAP_FADE_TIME)
	tween.tween_property(_sun,   "position", Vector2(lvl.sun_x, lvl.sun_y), MAP_FADE_TIME)

func _process(_delta: float) -> void:
	if _bonus_active and not _bonus_countdown.is_stopped():
		_bonus_label.text = "¡NIVEL BONUS!  %ds" % int(ceil(_bonus_countdown.time_left))

# ── Spawning ─────────────────────────────────────────────────────────────────

func _on_hazard_timer_timeout() -> void:
	if _state != "playing" or _bonus_active:
		return
	_spawn_from(_hazard_scenes)
	_schedule_hazard()

func _on_bonus_timer_timeout() -> void:
	if _state != "playing" or _bonus_active:
		return
	if _rng.randf() < GOLDEN_CHANCE:
		_spawn_scene(_golden_scene)
	else:
		_spawn_from(_bonus_scenes)
	_schedule_bonus()

func _schedule_hazard() -> void:
	_hazard_timer.wait_time = _rng.randf_range(hazard_spawn_min, hazard_spawn_max)
	_hazard_timer.start()

func _schedule_bonus() -> void:
	_bonus_timer.wait_time = _rng.randf_range(bonus_spawn_min, bonus_spawn_max)
	_bonus_timer.start()

func _schedule_decor() -> void:
	_decor_timer.wait_time = _rng.randf_range(DECOR_SPAWN_MIN, DECOR_SPAWN_MAX)
	_decor_timer.start()

func _on_decor_timer_timeout() -> void:
	if _state == "playing":
		_spawn_decoration()
	_schedule_decor()

func _spawn_decoration() -> void:
	if _decor_scenes.is_empty():
		return
	var scene := _decor_scenes[_rng.randi_range(0, _decor_scenes.size() - 1)]
	var inst := scene.instantiate()
	inst.scroll_speed = scroll_speed * DECOR_SCROLL_FACTOR
	var sprite := inst.get_node("Sprite2D") as Sprite2D
	var w := 32.0
	var h := 32.0
	if sprite and sprite.texture:
		w = sprite.texture.get_width()  * sprite.scale.x
		h = sprite.texture.get_height() * sprite.scale.y
	inst.position = Vector2(_rand_x(w), -h)
	_decorations_root.add_child(inst)

func _spawn_from(scenes: Array[PackedScene]) -> void:
	if scenes.is_empty():
		return
	_spawn_scene(scenes[_rng.randi_range(0, scenes.size() - 1)])

func _spawn_scene(scene: PackedScene) -> void:
	var spawnable := scene.instantiate() as Area2D
	spawnable.scroll_speed = scroll_speed
	var sprite := spawnable.get_node("Sprite2D") as Sprite2D
	var w := 24.0
	var h := 24.0
	if sprite and sprite.texture:
		w = sprite.texture.get_width()
		h = sprite.texture.get_height()
	spawnable.position = Vector2(_rand_x(w), -h)
	_spawnables_root.add_child(spawnable)
	spawnable.touched.connect(_on_spawnable_touched)

func _rand_x(obj_width: float) -> float:
	var view := get_viewport_rect()
	return _rng.randf_range(SPAWN_MARGIN + obj_width * 0.5,
							view.size.x - SPAWN_MARGIN - obj_width * 0.5)

# ── Collision handling ───────────────────────────────────────────────────────

func _on_spawnable_touched(spawnable: Area2D) -> void:
	if _state != "playing":
		return

	if spawnable.kind == "golden":
		_play_sfx(bonus_sfx)
		_enter_bonus_level()
		return

	if spawnable.is_hazard:
		if _player.is_invulnerable():
			return
		_apply_damage()
		_score = max(0, _score - spawnable.points)
		_play_sfx(hit_sfx)
	else:
		var prev_score := _score
		_score += spawnable.points
		_play_sfx(bonus_sfx)
		if spawnable.kind == "photo":
			_show_photo_popup()
		_check_map_transition(prev_score, _score)
	_update_ui()

func _check_map_transition(prev: int, curr: int) -> void:
	var prev_step := prev / MAP_SCORE_STEP
	var curr_step := curr / MAP_SCORE_STEP
	if curr_step <= prev_step:
		return
	_current_map = (GameState.current_level + curr_step) % GameState.LEVELS.size()
	_apply_level_theme(_current_map, false)

func _apply_damage() -> void:
	_health = max(0.0, _health - DAMAGE_FRACTION)
	_player.start_invulnerable(INVULNERABLE_TIME)
	if _health > 0.0:
		return
	_lives -= 1
	if _lives <= 0:
		_lose_game()
		return
	_health = 1.0

# ── Bonus level ──────────────────────────────────────────────────────────────

func _enter_bonus_level() -> void:
	_bonus_active = true
	_hazard_timer.stop()
	_bonus_timer.stop()
	for node in get_tree().get_nodes_in_group("spawnable"):
		node.queue_free()
	_bonus_label.text = "¡NIVEL BONUS!  %ds" % int(BONUS_DURATION)
	_bonus_label.visible = true
	_bonus_countdown.start(BONUS_DURATION)
	_frenetic_timer.wait_time = FRENETIC_MIN
	_frenetic_timer.start()

func _on_frenetic_timer_timeout() -> void:
	if _state != "playing" or not _bonus_active:
		_frenetic_timer.stop()
		return
	_spawn_from(_bonus_scenes)
	_frenetic_timer.wait_time = _rng.randf_range(FRENETIC_MIN, FRENETIC_MAX)

func _on_bonus_countdown_timeout() -> void:
	_exit_bonus_level()

func _exit_bonus_level() -> void:
	_bonus_active = false
	_frenetic_timer.stop()
	_bonus_countdown.stop()
	_bonus_label.visible = false
	for node in get_tree().get_nodes_in_group("spawnable"):
		node.queue_free()
	if _state == "playing":
		_schedule_hazard()
		_schedule_bonus()

# ── Progressive difficulty ───────────────────────────────────────────────────

func _on_difficulty_timer_timeout() -> void:
	if _state != "playing":
		return
	scroll_speed *= DIFFICULTY_FACTOR

# ── Game state ───────────────────────────────────────────────────────────────

func _update_ui() -> void:
	_health_bar.value = _health
	_lives_label.text = "Vidas: %d" % _lives
	_score_label.text = "Puntos: %d" % _score

func _lose_game() -> void:
	_state = "lose"
	_end_game("GAME OVER")

func _end_game(message: String) -> void:
	_hazard_timer.stop()
	_bonus_timer.stop()
	_frenetic_timer.stop()
	_bonus_countdown.stop()
	_difficulty_timer.stop()
	_decor_timer.stop()
	_bonus_label.visible = false
	_player.set_input_enabled(false)
	for node in get_tree().get_nodes_in_group("spawnable"):
		node.queue_free()
	for child in _decorations_root.get_children():
		child.queue_free()
	HighScoreManager.save_score(_score, false)
	_state_label.text = message
	_state_label.visible = true
	_btn_reintentar.visible = true
	_btn_menu_principal.visible = true

# ── Photo popup ───────────────────────────────────────────────────────────────

func _setup_photo_popup() -> void:
	_photo_popup.visible = false
	if photo_texture:
		_photo_rect.texture = photo_texture
	else:
		_photo_rect.texture = preload("res://sprites/manta.svg")

func _show_photo_popup() -> void:
	_photo_popup.visible = true
	_photo_timer.one_shot = true
	_photo_timer.start(2.0)

func _on_photo_timer_timeout() -> void:
	_photo_popup.visible = false

# ── Audio ────────────────────────────────────────────────────────────────────

func _start_music() -> void:
	if not music_stream:
		return
	_music_player.stream    = music_stream
	_music_player.volume_db = SettingsManager.get_music_db()
	_music_player.play()

func _play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	_sfx_player.stream    = stream
	_sfx_player.volume_db = SettingsManager.get_sfx_db()
	_sfx_player.play()

# ── Navigation ───────────────────────────────────────────────────────────────

func _on_reintentar_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
