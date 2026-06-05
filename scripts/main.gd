extends Node2D

@export var scroll_speed := 180.0
@export var hazard_spawn_min := 0.3
@export var hazard_spawn_max := 0.6
@export var bonus_spawn_min := 0.8
@export var bonus_spawn_max := 1.5
@export var photo_texture: Texture2D
@export var music_stream: AudioStream
@export var hit_sfx: AudioStream
@export var bonus_sfx: AudioStream

const DAMAGE_FRACTION   := 0.25
const INVULNERABLE_TIME := 1.0
const SPAWN_MARGIN      := 16.0
const GOLDEN_CHANCE     := 0.20
const BONUS_DURATION    := 15.0
const FRENETIC_MIN      := 0.12
const FRENETIC_MAX      := 0.28

const MAP_SCORE_STEP    := 500      # puntos para cambiar de mapa
const DIFFICULTY_PERIOD := 120.0    # segundos
const DIFFICULTY_FACTOR := 1.15     # +15% por periodo
const MAP_FADE_TIME     := 1.0

const BOSS_SCENE := preload("res://scenes/Boss.tscn")
const BOSS_MAPS  := {0: "boss1", 2: "boss2", 3: "boss3"}   # jefe al terminar estos mapas
const BOSS_SOUND := {0: 0, 2: 1, 3: 2}                     # índice en _rare_streams (1/2/3.wav)
const DODGE_DMG  := 7.0

var _lives        := 3
var _health       := 1.0
var _score        := 0
var _coins        := 0
var _score_multiplier := 1
var _ceviche_timer := 0.0
var _cola_timer    := 0.0
var _state        := "playing"
var _level_passed := false
var _bonus_active := false
var _current_map  := 0
var _spondylus_to_spawn := 0
var _boss: Node = null
var _rng          := RandomNumberGenerator.new()

var _damage_fraction := DAMAGE_FRACTION
var _score_mult_base := 1.0
var _bonus_duration_mult := 1.0

var _combo_mult := 0.0
var _combo_timer := 0.0
var _combo_max_time := 0.0
var _combo_base_pos := Vector2(12.0, 210.0)

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
var _emerald_scene: PackedScene = preload("res://templates/emerald.tscn")
var _spondylus_scene: PackedScene = preload("res://templates/spondylus.tscn")

var _ost_stream: AudioStream
var _lost_stream: AudioStream
var _rare_streams: Array[AudioStream] = []
var _rare_player: AudioStreamPlayer

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
@onready var _coins_label: Label      = $HUD/CoinsLabel
@onready var _state_label: Label      = $HUD/StateLabel
@onready var _bonus_label: Label      = $HUD/BonusLabel
@onready var _combo_label: Label      = $HUD/ComboLabel
@onready var _btn_dodge: Button       = $HUD/BtnDodge
@onready var _dodge_bar: ProgressBar  = $HUD/DodgeBar
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
@onready var _map: TextureRect      = $BackgroundLayer/Map
@onready var _map_fade: TextureRect = $BackgroundLayer/MapFade
@onready var _boss_layer            = $BossLayer
@onready var _boss_projectiles      = $BossProjectiles
@onready var _boss_bar: ProgressBar = $HUD/BossBar
@onready var _boss_name: Label      = $HUD/BossName

func _ready() -> void:
	_rng.randomize()
	_current_map = GameState.current_level
	
	var board = SettingsManager.equipped_board
	if board == "caparazon_spondylus": _damage_fraction = DAMAGE_FRACTION * 0.5
	if board == "rugido_jaguar": _score_mult_base = 1.5
	if board == "mistica_umina": _bonus_duration_mult = 1.5
	
	for i in range(_current_map):
		scroll_speed *= 1.25
		hazard_spawn_min *= 0.8
		hazard_spawn_max *= 0.8
		
	_apply_level_theme(_current_map, true)
	_update_ui()
	_setup_photo_popup()
	_load_audio()
	_start_music()
	_bonus_label.add_theme_font_size_override("font_size", 15)
	_bonus_label.add_theme_color_override("font_color", Color(0.078, 0.071, 0.157))
	_bonus_label.add_theme_constant_override("outline_size", 0)
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
	if _btn_dodge: _btn_dodge.pressed.connect(_on_btn_dodge_pressed)

	var btn_pausa = get_node_or_null("HUD/BtnPausa")
	if btn_pausa: btn_pausa.pressed.connect(_on_btn_pausa_pressed)
	var btn_reanudar = get_node_or_null("HUD/PauseMenu/BtnReanudar")
	if btn_reanudar: btn_reanudar.pressed.connect(_on_btn_reanudar_pressed)
	var btn_config = get_node_or_null("HUD/PauseMenu/BtnMenuPrincipalPausa")
	if btn_config: btn_config.pressed.connect(_on_menu_principal_pressed)

	var m_slider = get_node_or_null("HUD/PauseMenu/MusicSlider")
	if m_slider:
		m_slider.value = SettingsManager.music_volume
		m_slider.value_changed.connect(func(v):
			SettingsManager.music_volume = v
			_music_player.volume_db = SettingsManager.get_music_db()
		)
	var s_slider = get_node_or_null("HUD/PauseMenu/SfxSlider")
	if s_slider:
		s_slider.value = SettingsManager.sfx_volume
		s_slider.value_changed.connect(func(v):
			SettingsManager.sfx_volume = v
			_sfx_player.volume_db = SettingsManager.get_sfx_db()
		)


func _apply_level_theme(idx: int, instant: bool) -> void:
	var lvl: Dictionary = GameState.LEVELS[idx]
	if lvl.is_night:
		_sun.texture = load("res://sprites/moon.svg")
	else:
		_sun.texture = load("res://sprites/sun.svg")
	_sun.scale = Vector2(2.0, 2.0)
	var map_path := "res://sprites/maps/level%d.png" % idx
	var map_tex: Texture2D = load(map_path) if ResourceLoader.exists(map_path) else null
	if instant:
		if map_tex:
			_map.texture = map_tex
		_canvas_modulate.color = Color.WHITE
		_sun.position          = Vector2(lvl.sun_x, lvl.sun_y)
		return
	if map_tex:
		_map_fade.texture = map_tex
		_map_fade.modulate.a = 0.0
		var ft := create_tween()
		ft.tween_property(_map_fade, "modulate:a", 1.0, MAP_FADE_TIME)
		ft.tween_callback(func():
			_map.texture = map_tex
			_map_fade.modulate.a = 0.0)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_canvas_modulate, "color", Color.WHITE, MAP_FADE_TIME)
	tween.tween_property(_sun,   "position", Vector2(lvl.sun_x, lvl.sun_y), MAP_FADE_TIME)

func _process(delta: float) -> void:
	if _bonus_active and not _bonus_countdown.is_stopped():
		_bonus_label.text = "¡NIVEL BONUS!  %ds" % int(ceil(_bonus_countdown.time_left))

	if _ceviche_timer > 0.0:
		_ceviche_timer -= delta
		if _ceviche_timer <= 0.0:
			_score_multiplier = 1

	if _cola_timer > 0.0:
		_cola_timer -= delta
		if _cola_timer <= 0.0:
			for node in get_tree().get_nodes_in_group("spawnable"):
				if node.has_method("get_node"): # safe check
					node.scroll_speed = scroll_speed

	if _player and _btn_dodge and _dodge_bar:
		_btn_dodge.text = "Salto\n%d/%d" % [_player.dodges_left, _player.MAX_DODGES]
		if _player.dodges_left < _player.MAX_DODGES:
			_dodge_bar.value = 1.0 - (_player.dodge_timer / _player.DODGE_COOLDOWN)
		else:
			_dodge_bar.value = 1.0

	if _combo_timer > 0.0:
		_combo_timer -= delta
		var intensity = _combo_mult * 5.0 + 2.0
		_combo_label.position = _combo_base_pos + Vector2(_rng.randf_range(-intensity, intensity), _rng.randf_range(-intensity, intensity))
		_combo_label.modulate.a = _combo_timer / _combo_max_time
		if _combo_timer <= 0.0:
			_combo_label.position = _combo_base_pos
			_reset_combo()

# ── Spawning ─────────────────────────────────────────────────────────────────

func _on_hazard_timer_timeout() -> void:
	if _state != "playing" or _bonus_active:
		return
	_spawn_from(_hazard_scenes)
	_schedule_hazard()

func _on_bonus_timer_timeout() -> void:
	if _state != "playing" or _bonus_active:
		return
	var r := _rng.randf()
	if r < GOLDEN_CHANCE:
		_spawn_scene(_golden_scene)
	elif r < GOLDEN_CHANCE + 0.05:
		_spawn_scene(_emerald_scene)
	elif r < GOLDEN_CHANCE + 0.05 + 0.35:
		_spawn_scene(_spondylus_scene)
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
	var b_mult := 1.5 if _bonus_active else 1.0
	var c_mult := 0.5 if _cola_timer > 0.0 else 1.0
	spawnable.scroll_speed = scroll_speed * b_mult * c_mult
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

	if spawnable.kind == "emerald":
		_play_sfx(bonus_sfx)
		_player.start_emerald_buff(15.0 * _bonus_duration_mult)
		return

	if spawnable.kind == "spondylus":
		_play_sfx(bonus_sfx)
		var extra = 0
		if _combo_mult > 0.0 and _rng.randf() < _combo_mult:
			extra = 1
		_coins += 1 + extra
		_score += spawnable.points * _score_mult_base
		_check_level_passed()
		_update_ui()
		return

	if spawnable.is_hazard:
		if _player.is_dodging:
			_player.refund_dodge()
			_increment_combo()
			return
		if _player.is_invulnerable():
			return
		_reset_combo()
		_apply_damage()
		_play_sfx(hit_sfx)
	else:
		var prev_score := _score
		_score += spawnable.points * _score_multiplier * _score_mult_base
		_play_sfx(bonus_sfx)

		if not _bonus_active:
			match spawnable.kind:
				"encebollado":
					_health = min(1.0, _health + 0.25)
				"ceviche":
					_score_multiplier = 2
					_ceviche_timer = 10.0 * _bonus_duration_mult
				"cola":
					_cola_timer = 1.0 * _bonus_duration_mult
					for node in get_tree().get_nodes_in_group("spawnable"):
						if node.has_method("get_node"):
							node.scroll_speed = scroll_speed * 0.5
				"corviche":
					_play_bomb_effect(_player.position)
					for node in get_tree().get_nodes_in_group("spawnable"):
						if node.get("is_hazard"): node.queue_free()

		if spawnable.kind == "photo":
			_show_photo_popup()
	_update_ui()

func _increment_combo() -> void:
	_combo_mult = min(1.0, _combo_mult + 0.1)
	_combo_label.text = "¡Esquive Perfecto!\nCombo x%.1f" % _combo_mult
	_combo_label.visible = true
	_combo_label.modulate.a = 1.0
	
	_combo_max_time = max(1.0, 4.5 - (_combo_mult * 3.5))
	_combo_timer = _combo_max_time

func _reset_combo() -> void:
	_combo_mult = 0.0
	_combo_timer = 0.0
	_combo_label.visible = false

func _get_coins_to_pass() -> int:
	if _current_map == 0: return 10
	elif _current_map == 1: return 20
	elif _current_map == 2: return 30
	else: return 40

func _check_level_passed() -> void:
	if _coins < _get_coins_to_pass():
		return
	if BOSS_MAPS.has(_current_map):
		_start_boss(_current_map)
	else:
		_advance_level()

func _advance_level() -> void:
	HighScoreManager.save_score(_current_map, _score, _coins)
	_coins = 0
	_level_passed = true
	_state_label.text = "¡NIVEL COMPLETADO!\nYa puedes volver al inicio"
	_state_label.visible = true
	get_tree().create_timer(4.0).timeout.connect(func(): if _state != "lose": _state_label.visible = false)
	_current_map = (_current_map + 1) % GameState.LEVELS.size()
	SettingsManager.unlock_level(_current_map)
	_apply_level_theme(_current_map, false)
	scroll_speed *= 1.25
	hazard_spawn_min *= 0.8
	hazard_spawn_max *= 0.8


func _apply_damage() -> void:
	_health = max(0.0, _health - _damage_fraction)
	_player.start_invulnerable(INVULNERABLE_TIME)
	if _health > 0.0:
		return
	_lives -= 1
	if _lives <= 0:
		_lose_game()
		return
	_health = 1.0

# ── Boss fight ───────────────────────────────────────────────────────────────

func _start_boss(map: int) -> void:
	_state = "boss"
	_hazard_timer.stop()
	_bonus_timer.stop()
	_decor_timer.stop()
	_frenetic_timer.stop()
	_reset_combo()
	for node in get_tree().get_nodes_in_group("spawnable"):
		node.queue_free()
	_boss = BOSS_SCENE.instantiate()
	_boss_layer.add_child(_boss)
	_boss.health_changed.connect(_on_boss_health_changed)
	_boss.projectile_spawned.connect(_connect_boss_projectile)
	_boss.defeated.connect(_on_boss_defeated.bind(map))
	_boss.start(BOSS_MAPS[map], _boss_projectiles, _player)
	_boss_name.text = _boss.display_name()
	_boss_name.visible = true
	_boss_bar.visible = true
	_boss_bar.value = 1.0
	_state_label.text = "¡JEFE!"
	_state_label.visible = true
	get_tree().create_timer(1.5).timeout.connect(func(): if _state == "boss": _state_label.visible = false)

func _connect_boss_projectile(proj) -> void:
	proj.hit.connect(_on_boss_projectile_hit)

func _on_boss_projectile_hit(proj) -> void:
	if _state != "boss":
		return
	if _player.is_dodging:
		if _boss and is_instance_valid(_boss):
			_boss.take_damage(DODGE_DMG)
		_player.refund_dodge()
		_increment_combo()
		proj.queue_free()
		return
	if _player.is_invulnerable():
		return
	_reset_combo()
	_apply_damage()
	_play_sfx(hit_sfx)
	proj.queue_free()

func _on_boss_health_changed(ratio: float) -> void:
	_boss_bar.value = ratio

func _on_boss_defeated(map: int) -> void:
	_play_boss_sound(BOSS_SOUND.get(map, 0))
	for p in _boss_projectiles.get_children():
		p.queue_free()
	_boss = null
	_boss_bar.visible = false
	_boss_name.visible = false
	var is_last := (map == GameState.LEVELS.size() - 1)
	_advance_level()
	if is_last:
		_state_label.text = "¡JUEGO COMPLETADO!"
		_state_label.visible = true
	_state = "playing"
	_schedule_hazard()
	_schedule_bonus()
	_schedule_decor()

# ── Bonus level ──────────────────────────────────────────────────────────────

func _enter_bonus_level() -> void:
	_bonus_active = true
	_hazard_timer.stop()
	_bonus_timer.stop()
	for node in get_tree().get_nodes_in_group("spawnable"):
		node.queue_free()
	if _current_map == 0: _spondylus_to_spawn = _rng.randi_range(1, 3)
	elif _current_map == 1: _spondylus_to_spawn = _rng.randi_range(3, 6)
	elif _current_map == 2: _spondylus_to_spawn = _rng.randi_range(10, 15)
	else: _spondylus_to_spawn = _rng.randi_range(20, 25)
	
	_bonus_label.text = "¡NIVEL BONUS!  %ds" % int(BONUS_DURATION * _bonus_duration_mult)
	_bonus_label.visible = true
	_bonus_countdown.start(BONUS_DURATION * _bonus_duration_mult)
	_player.start_bonus_blink(true)
	_frenetic_timer.wait_time = hazard_spawn_min * 0.3
	_frenetic_timer.start()

func _on_frenetic_timer_timeout() -> void:
	if _state != "playing" or not _bonus_active:
		_frenetic_timer.stop()
		return
	if _spondylus_to_spawn > 0 and (_rng.randf() < 0.25 or _bonus_countdown.time_left < _spondylus_to_spawn * 0.5):
		_spondylus_to_spawn -= 1
		_spawn_scene(_spondylus_scene)
	else:
		_spawn_from(_bonus_scenes)
	_frenetic_timer.wait_time = _rng.randf_range(hazard_spawn_min * 0.25, hazard_spawn_max * 0.35)

func _on_bonus_countdown_timeout() -> void:
	_exit_bonus_level()

func _exit_bonus_level() -> void:
	_bonus_active = false
	_frenetic_timer.stop()
	_bonus_countdown.stop()
	_player.start_bonus_blink(false)
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
	hazard_spawn_min *= 0.90
	hazard_spawn_max *= 0.90

# ── Game state ───────────────────────────────────────────────────────────────

func _update_ui() -> void:
	_health_bar.value = _health
	_lives_label.text = "%d" % _lives
	_score_label.text = "%d" % _score
	if _coins_label:
		_coins_label.text = "%d / %d" % [_coins, _get_coins_to_pass()]

func _lose_game() -> void:
	_state = "lose"
	_music_player.stop()
	if _lost_stream:
		_play_sfx(_lost_stream)
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
	if _boss and is_instance_valid(_boss):
		_boss.queue_free()
		_boss = null
	for p in _boss_projectiles.get_children():
		p.queue_free()
	_boss_bar.visible = false
	_boss_name.visible = false
	HighScoreManager.save_score(_current_map, _score, _coins)
	SettingsManager.ancestral_energy += _score
	SettingsManager.save_settings()
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

func _load_audio() -> void:
	if ResourceLoader.exists("res://music/ost.wav"):  _ost_stream  = load("res://music/ost.wav")
	if ResourceLoader.exists("res://music/lost.wav"): _lost_stream = load("res://music/lost.wav")
	for p in ["res://music/1.wav", "res://music/2.wav", "res://music/3.wav"]:
		if ResourceLoader.exists(p): _rare_streams.append(load(p))
	# dedicated player so the jingle isn't cut off by hit/bonus SFX on _sfx_player
	_rare_player = AudioStreamPlayer.new()
	$Audio.add_child(_rare_player)

func _start_music() -> void:
	var stream = music_stream if music_stream else _ost_stream
	if not stream:
		return
	_music_player.stream    = stream
	_music_player.volume_db = SettingsManager.get_music_db()
	if not _music_player.finished.is_connected(_start_music):
		_music_player.finished.connect(_start_music)
	_music_player.play()

func _play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	_sfx_player.stream    = stream
	_sfx_player.volume_db = SettingsManager.get_sfx_db()
	_sfx_player.play()

func _play_boss_sound(index: int) -> void:
	if index < 0 or index >= _rare_streams.size() or not _rare_player:
		return
	_rare_player.stream    = _rare_streams[index]
	_rare_player.volume_db = SettingsManager.get_sfx_db()
	_rare_player.play()

# ── VFX ────────────────────────────────────────────────────────────────────────

func _play_bomb_effect(center: Vector2) -> void:
	# Touhou-style screen-clear: an expanding shockwave from the player plus a
	# quick screen flash. Both nodes free themselves when the tween/anim ends.
	var wave := Node2D.new()
	wave.set_script(preload("res://scripts/bomb_wave.gd"))
	wave.position = center
	wave.z_index  = 100
	add_child(wave)
	wave.start(360.0, 0.5, Color(0.45, 0.9, 1.0))

	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.55)
	flash.anchor_right  = 1.0
	flash.anchor_bottom = 1.0
	flash.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)

# ── Navigation ───────────────────────────────────────────────────────────────

func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_btn_dodge_pressed() -> void:
	if (_state == "playing" or _state == "boss") and _player:
		_player.do_dodge()

func _on_btn_pausa_pressed() -> void:
	_toggle_pause()

func _toggle_pause() -> void:
	if _state == "lose": return
	var p := not get_tree().paused
	get_tree().paused = p
	var pm = get_node_or_null("HUD/PauseMenu")
	if pm:
		pm.visible = p

func _on_btn_reanudar_pressed() -> void:
	get_tree().paused = false
	var pm = get_node_or_null("HUD/PauseMenu")
	if pm:
		pm.visible = false

# ── Debug hooks (called by the DebugCommands autoload) ─────────────────────────

func debug_complete_level() -> void:
	if _state != "playing":
		return
	_coins = _get_coins_to_pass()
	_check_level_passed()

func debug_refresh() -> void:
	_update_ui()


