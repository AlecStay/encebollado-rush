extends Node2D

@export var target_score := 100
@export var scroll_speed := 120.0
@export var hazard_spawn_min := 0.7
@export var hazard_spawn_max := 1.3
@export var bonus_spawn_min := 0.8
@export var bonus_spawn_max := 1.6
@export var photo_texture: Texture2D
@export var music_stream: AudioStream
@export var hit_sfx: AudioStream
@export var bonus_sfx: AudioStream

const DAMAGE_FRACTION := 0.25
const INVULNERABLE_TIME := 1.0
const SPAWN_MARGIN := 16.0

var _lives := 3
var _health := 1.0
var _score := 0
var _state := "playing"
var _rng := RandomNumberGenerator.new()

var _hazard_scenes: Array[PackedScene] = [
	preload("res://templates/boat.tscn"),
	preload("res://templates/shark.tscn"),
]

var _bonus_scenes: Array[PackedScene] = [
	preload("res://templates/encebollado.tscn"),
	preload("res://templates/ceviche.tscn"),
	preload("res://templates/photo.tscn"),
	preload("res://templates/fish.tscn"),
]

@onready var _player = $Player
@onready var _spawnables_root = $Spawnables
@onready var _hazard_timer: Timer = $Spawner/HazardTimer
@onready var _bonus_timer: Timer = $Spawner/BonusTimer
@onready var _health_bar: ProgressBar = $HUD/HealthBar
@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _state_label: Label = $HUD/StateLabel
@onready var _photo_popup: Panel = $HUD/PhotoPopup
@onready var _photo_rect: TextureRect = $HUD/PhotoPopup/PhotoRect
@onready var _photo_timer: Timer = $HUD/PhotoPopup/HideTimer
@onready var _music_player: AudioStreamPlayer = $Audio/MusicPlayer
@onready var _sfx_player: AudioStreamPlayer = $Audio/SfxPlayer
@onready var _btn_reintentar: Button = $HUD/BtnReintentar
@onready var _btn_menu_principal: Button = $HUD/BtnMenuPrincipal

func _ready() -> void:
	_rng.randomize()
	_update_ui()
	_setup_photo_popup()
	_start_music()
	_hazard_timer.timeout.connect(_on_hazard_timer_timeout)
	_bonus_timer.timeout.connect(_on_bonus_timer_timeout)
	_photo_timer.timeout.connect(_on_photo_timer_timeout)
	_schedule_hazard()
	_schedule_bonus()
	_btn_reintentar.pressed.connect(_on_reintentar_pressed)
	_btn_menu_principal.pressed.connect(_on_menu_principal_pressed)

func _on_hazard_timer_timeout() -> void:
	if _state != "playing":
		return
	_spawn_from_scenes(_hazard_scenes)
	_schedule_hazard()

func _on_bonus_timer_timeout() -> void:
	if _state != "playing":
		return
	_spawn_from_scenes(_bonus_scenes)
	_schedule_bonus()

func _schedule_hazard() -> void:
	_hazard_timer.one_shot = true
	_hazard_timer.wait_time = _rng.randf_range(hazard_spawn_min, hazard_spawn_max)
	_hazard_timer.start()

func _schedule_bonus() -> void:
	_bonus_timer.one_shot = true
	_bonus_timer.wait_time = _rng.randf_range(bonus_spawn_min, bonus_spawn_max)
	_bonus_timer.start()

func _spawn_from_scenes(scenes: Array[PackedScene]) -> void:
	if scenes.is_empty():
		return
	var scene: PackedScene = scenes[_rng.randi_range(0, scenes.size() - 1)]
	var spawnable := scene.instantiate() as Area2D
	spawnable.scroll_speed = scroll_speed
	var sprite := spawnable.get_node("Sprite2D") as Sprite2D
	var width := 24.0
	var height := 24.0
	if sprite and sprite.texture:
		width = sprite.texture.get_width()
		height = sprite.texture.get_height()
	spawnable.position = Vector2(_rand_x(width), -height)
	_spawnables_root.add_child(spawnable)
	spawnable.touched.connect(_on_spawnable_touched)

func _rand_x(obj_width: float) -> float:
	var view := get_viewport_rect()
	var min_x := SPAWN_MARGIN + obj_width * 0.5
	var max_x := view.size.x - SPAWN_MARGIN - obj_width * 0.5
	return _rng.randf_range(min_x, max_x)

func _on_spawnable_touched(spawnable: Area2D) -> void:
	if _state != "playing":
		return

	if spawnable.is_hazard:
		if _player.is_invulnerable():
			return
		_apply_damage()
		_play_sfx(hit_sfx)
	else:
		_score += spawnable.points
		_play_sfx(bonus_sfx)
		if spawnable.kind == "photo":
			_show_photo_popup()
		if _score >= target_score:
			_win_game()
	_update_ui()

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

func _update_ui() -> void:
	_health_bar.value = _health
	_lives_label.text = "Vidas: %d" % _lives
	_score_label.text = "Puntos: %d / %d" % [_score, target_score]

func _win_game() -> void:
	_state = "win"
	_end_game("GANASTE!")

func _lose_game() -> void:
	_state = "lose"
	_end_game("GAME OVER")

func _end_game(message: String) -> void:
	_hazard_timer.stop()
	_bonus_timer.stop()
	_player.set_input_enabled(false)
	for node in get_tree().get_nodes_in_group("spawnable"):
		node.queue_free()
	_state_label.text = message
	_state_label.visible = true
	_btn_reintentar.visible = true
	_btn_menu_principal.visible = true

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

func _start_music() -> void:
	if not music_stream:
		return
	_music_player.stream = music_stream
	_music_player.play()

func _play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	_sfx_player.stream = stream
	_sfx_player.play()

func _on_reintentar_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
