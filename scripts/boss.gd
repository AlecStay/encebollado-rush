extends Node2D
## Animated bullet-hell boss. Frames are loaded in code from sprites/bosses/<id>/.
## HP only drops when the player dodges (main.gd routes each dodge to take_damage).
## Each boss has its own attack set (ATTACKS), selected by phase; stats scale by level.

signal defeated
signal health_changed(ratio)
signal projectile_spawned(projectile)

const PROJ_SCENE := preload("res://scenes/BossProjectile.tscn")

const BOSS_DATA := {
	"boss1": {"name": "Monstruo de Piedra Manteño", "hp": 100.0, "speed": 90.0,  "period": 1.40},
	"boss2": {"name": "Cabeza de Camarón",          "hp": 120.0, "speed": 105.0, "period": 1.25},
	"boss3": {"name": "Monolito Manteño Ancestral", "hp": 160.0, "speed": 120.0, "period": 1.05},
}

# Ataques por jefe y por fase (0=>66% vida, 1=>33%, 2=resto). Identidad distinta c/u.
const ATTACKS := {
	"boss1": [ ["rain6"],            ["rain8", "aimed3"],            ["ring8", "aimed3"] ],
	"boss2": [ ["ring5"],            ["spiral5", "aimed3"],          ["double_spiral5", "ring8"] ],
	"boss3": [ ["spiral9", "aimed3"], ["double_spiral8", "wall_gap"], ["ring12", "spiral9", "aimed5"] ],
}

@onready var _anim: AnimatedSprite2D = $Anim

var _id := "boss1"
var _max_hp := 100.0
var _hp := 100.0
var _proj_container: Node = null
var _player: Node2D = null
var _proj_texs: Array[Texture2D] = []

var _alive := true
var _fighting := false
var _t := 0.0
var _fire_accum := 0.0
var _base_pos := Vector2.ZERO

var _sfx_player: AudioStreamPlayer
var _sfx_attacks: Array[AudioStream] = []
var _sfx_spiral: AudioStream

func display_name() -> String:
	return BOSS_DATA[_id].name

var _speed := 90.0
var _period := 1.4

func start(boss_id: String, proj_container: Node, player: Node2D, level := 0) -> void:
	_id = boss_id
	_proj_container = proj_container
	_player = player
	# Dificultad creciente por nivel: más HP, más veloz, dispara más seguido
	_max_hp = BOSS_DATA[boss_id].hp * (1.0 + 0.15 * level)
	_hp = _max_hp
	_speed  = float(BOSS_DATA[boss_id].speed) * (1.0 + 0.25 * level)
	_period = float(BOSS_DATA[boss_id].period) / (1.0 + 0.20 * level)
	_build_frames(boss_id)
	_load_projectiles(boss_id)
	_anim.animation_finished.connect(_on_anim_finished)
	z_index = 5

	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	for i in range(1, 5):
		var sp := "res://music/sfx_boss%d.wav" % i
		if ResourceLoader.exists(sp):
			_sfx_attacks.append(load(sp))
	if ResourceLoader.exists("res://music/sfx_boss_spiral.wav"):
		_sfx_spiral = load("res://music/sfx_boss_spiral.wav")

	var vw := get_viewport_rect().size.x
	_base_pos = Vector2(vw * 0.5, 64.0)
	position = Vector2(_base_pos.x, -90.0)
	_anim.play("idle")
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", _base_pos, 0.9)
	tw.tween_callback(func(): _fighting = true)

func _build_frames(boss_id: String) -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for a in ["idle", "attack", "hurt"]:
		sf.add_animation(a)
		sf.set_animation_loop(a, a == "idle")
		sf.set_animation_speed(a, 6.0 if a == "idle" else 11.0)
		var i := 0
		while true:
			var p := "res://sprites/bosses/%s/%s_%d.png" % [boss_id, a, i]
			if not ResourceLoader.exists(p):
				break
			sf.add_frame(a, load(p))
			i += 1
	_anim.sprite_frames = sf

func _load_projectiles(boss_id: String) -> void:
	var i := 0
	while true:
		var p := "res://sprites/bosses/%s/proj_%d.png" % [boss_id, i]
		if not ResourceLoader.exists(p):
			break
		_proj_texs.append(load(p))
		i += 1

func _process(delta: float) -> void:
	if not _alive or not _fighting:
		return
	_t += delta
	# La vida del jefe ya NO baja sola: solo baja con los esquives (perfect-dodge).
	# drift across the top + gentle bob
	var vw := get_viewport_rect().size.x
	position.x = _base_pos.x + sin(_t * 0.8) * (vw * 0.30)
	position.y = _base_pos.y + sin(_t * 2.0) * 4.0
	# fire on cadence
	_fire_accum += delta
	if _fire_accum >= _period:
		_fire_accum = 0.0
		_attack()

func _attack() -> void:
	if not _alive:
		return
	_anim.play("attack")
	var list: Array = ATTACKS.get(_id, [["ring8"]])
	var phase: int = clampi(_phase(), 0, list.size() - 1)
	var attacks: Array = list[phase]
	var has_spiral := false
	for a in attacks:
		if "spiral" in str(a):
			has_spiral = true
		_do_attack(str(a))
	_play_attack_sfx(has_spiral)

func _phase() -> int:
	var r := _hp / _max_hp
	if r > 0.66:
		return 0
	elif r > 0.33:
		return 1
	return 2

func _do_attack(name: String) -> void:
	match name:
		"rain6":          _rain(6)
		"rain8":          _rain(8)
		"aimed3":         _aimed(3, 0.22)
		"aimed5":         _aimed(5, 0.30)
		"ring5":          _ring(5)
		"ring8":          _ring(8)
		"ring12":         _ring(12)
		"spiral5":        _spiral(5)
		"spiral9":        _spiral(9)
		"double_spiral5": _double_spiral(5)
		"double_spiral8": _double_spiral(8)
		"wall_gap":       _wall_gap(9)
		_:                _ring(8)

func _play_attack_sfx(is_spiral: bool) -> void:
	if not _sfx_player:
		return
	var s: AudioStream = null
	if is_spiral:
		s = _sfx_spiral
	elif not _sfx_attacks.is_empty():
		s = _sfx_attacks[randi() % _sfx_attacks.size()]
	if s == null:
		return
	_sfx_player.stream    = s
	_sfx_player.volume_db = SettingsManager.get_sfx_db()
	_sfx_player.play()

func _on_anim_finished() -> void:
	# attack/hurt are non-looping; fall back to idle when they end
	if _alive and _fighting and _anim.animation != "idle":
		_anim.play("idle")

# ── Primitivas de ataque ──────────────────────────────────────────────────────
func _ring(count: int) -> void:
	for i in count:
		var ang := TAU * i / count
		_spawn(position, Vector2(cos(ang), sin(ang)))

func _spiral(arms: int) -> void:
	var base := _t * 2.6
	for i in arms:
		var ang := base + TAU * i / arms
		_spawn(position, Vector2(cos(ang), sin(ang)))

func _double_spiral(arms: int) -> void:
	var base := _t * 2.6
	for i in arms:
		var a1 := base + TAU * i / arms
		var a2 := -base + TAU * i / arms
		_spawn(position, Vector2(cos(a1), sin(a1)))
		_spawn(position, Vector2(cos(a2), sin(a2)))

func _aimed(count: int, spread: float) -> void:
	if not is_instance_valid(_player):
		return
	var dir := _player.global_position - position
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var start := -spread * (count - 1) * 0.5
	for i in count:
		_spawn(position, dir.rotated(start + spread * i))

func _rain(n: int) -> void:
	var vw := get_viewport_rect().size.x
	for i in n:
		var x := vw * (i + 0.5 + randf_range(-0.2, 0.2)) / n
		_spawn(Vector2(x, 14.0), Vector2(0.0, 1.0))

func _wall_gap(n: int) -> void:
	var vw := get_viewport_rect().size.x
	var gap := randi() % n   # columna sin bala = corredor para esquivar
	for i in n:
		if i == gap:
			continue
		var x := vw * (i + 0.5) / n
		_spawn(Vector2(x, 14.0), Vector2(0.0, 1.0))

func _spawn(pos: Vector2, dir: Vector2) -> void:
	if _proj_container == null or not is_instance_valid(_proj_container):
		return
	var p := PROJ_SCENE.instantiate()
	var tex: Texture2D = _proj_texs[randi() % _proj_texs.size()] if not _proj_texs.is_empty() else null
	p.setup(tex, pos, dir.normalized() * _speed)
	_proj_container.add_child(p)
	projectile_spawned.emit(p)

func take_damage(amount: float, flash := true) -> void:
	if not _alive:
		return
	_hp = max(0.0, _hp - amount)
	health_changed.emit(_hp / _max_hp)
	if flash:
		_flash_hurt()
	if _hp <= 0.0:
		_die()

func _flash_hurt() -> void:
	if not _alive:
		return
	_anim.play("hurt")
	modulate = Color(1.0, 0.55, 0.55)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)

func _die() -> void:
	_alive = false
	_fighting = false
	_anim.play("hurt")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_property(self, "scale", scale * 1.25, 0.8)
	tw.chain().tween_callback(func():
		defeated.emit()
		queue_free())
