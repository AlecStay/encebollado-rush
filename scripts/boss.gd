extends Node2D
## Animated bullet-hell boss. Frames are loaded in code from sprites/bosses/<id>/.
## Health drains steadily (guarantees the fight ends ~35-45s even without skill) and faster
## from perfect dodges (main.gd routes those to take_damage). Patterns change by phase.

signal defeated
signal health_changed(ratio)
signal projectile_spawned(projectile)

const PROJ_SCENE := preload("res://scenes/BossProjectile.tscn")

const BOSS_DATA := {
	"boss1": {"name": "Monstruo de Piedra Manteño", "hp": 100.0, "drain": 2.3, "speed": 90.0,  "period": 1.40},
	"boss2": {"name": "Cabeza de Camarón",          "hp": 120.0, "drain": 2.1, "speed": 105.0, "period": 1.25},
	"boss3": {"name": "Monolito Manteño Ancestral", "hp": 160.0, "drain": 1.7, "speed": 120.0, "period": 1.05},
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

func display_name() -> String:
	return BOSS_DATA[_id].name

func start(boss_id: String, proj_container: Node, player: Node2D) -> void:
	_id = boss_id
	_proj_container = proj_container
	_player = player
	_max_hp = BOSS_DATA[boss_id].hp
	_hp = _max_hp
	_build_frames(boss_id)
	_load_projectiles(boss_id)
	_anim.animation_finished.connect(_on_anim_finished)
	z_index = 5

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
	# steady pressure: the fight always resolves in ~hp/drain seconds
	take_damage(BOSS_DATA[_id].drain * delta, false)
	# drift across the top + gentle bob
	var vw := get_viewport_rect().size.x
	position.x = _base_pos.x + sin(_t * 0.8) * (vw * 0.30)
	position.y = _base_pos.y + sin(_t * 2.0) * 4.0
	# fire on cadence
	_fire_accum += delta
	if _fire_accum >= float(BOSS_DATA[_id].period):
		_fire_accum = 0.0
		_attack()

func _attack() -> void:
	if not _alive:
		return
	_anim.play("attack")
	match _pattern():
		"rain":   _fire_rain()
		"spiral": _fire_spiral()
		"mixed":
			_fire_spiral()
			_fire_aimed()

func _on_anim_finished() -> void:
	# attack/hurt are non-looping; fall back to idle when they end
	if _alive and _fighting and _anim.animation != "idle":
		_anim.play("idle")

func _pattern() -> String:
	var r := _hp / _max_hp
	if r > 0.66:
		return "rain"
	elif r > 0.33:
		return "spiral"
	return "mixed"

func _fire_rain() -> void:
	var vw := get_viewport_rect().size.x
	var n := 6
	for i in n:
		var x := vw * (i + 0.5 + randf_range(-0.2, 0.2)) / n
		_spawn(Vector2(x, 14.0), Vector2(0.0, 1.0))

func _fire_spiral() -> void:
	var base := _t * 2.6
	var n := 9
	for i in n:
		var ang := base + TAU * i / n
		_spawn(position, Vector2(cos(ang), sin(ang)))

func _fire_aimed() -> void:
	if not is_instance_valid(_player):
		return
	var dir := _player.global_position - position
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	for off in [-0.22, 0.0, 0.22]:
		_spawn(position, dir.rotated(off))

func _spawn(pos: Vector2, dir: Vector2) -> void:
	if _proj_container == null or not is_instance_valid(_proj_container):
		return
	var p := PROJ_SCENE.instantiate()
	var tex: Texture2D = _proj_texs[randi() % _proj_texs.size()] if not _proj_texs.is_empty() else null
	p.setup(tex, pos, dir.normalized() * float(BOSS_DATA[_id].speed))
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
