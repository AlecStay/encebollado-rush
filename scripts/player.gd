extends CharacterBody2D

@export var move_speed := 220.0
@export var bounds_margin := 20.0

@export var tex_n:  Texture2D
@export var tex_ne: Texture2D
@export var tex_e:  Texture2D
@export var tex_se: Texture2D
@export var tex_s:  Texture2D
@export var tex_sw: Texture2D
@export var tex_w:  Texture2D
@export var tex_nw: Texture2D

var _target_position := Vector2.ZERO
var _has_target := false
var _input_enabled := true
var _invulnerable_time := 0.0
var _blink_time := 0.0
var _emerald_time := 0.0
var _base_move_speed := 0.0
var _bonus_blink_active := false
var _bonus_speed_active := false
var _single_blink_timer := 0.0
var _last_facing := Vector2.DOWN

const MAX_DODGES := 2
const DODGE_COOLDOWN := 3.0
var dodges_left := MAX_DODGES
var dodge_timer := 0.0
var is_dodging := false

@onready var _body: Sprite2D = $Body

func _ready() -> void:
	var board = SettingsManager.equipped_board
	if board == "corriente_nino":
		_base_move_speed = move_speed * 1.3
	else:
		_base_move_speed = move_speed
	_apply_skin(SettingsManager.equipped_skin)
	_target_position = global_position
	_set_facing(Vector2.DOWN)

# Swap the 8 directional textures for the equipped cosmetic skin. "default" keeps
# the sprites/scale authored in player.tscn. Loads atomically: a missing file in a
# skin folder leaves the default intact instead of a half-applied swap.
func _apply_skin(skin_id: String) -> void:
	var info: Dictionary = SettingsManager.SKINS.get(skin_id, {})
	var base: String = info.get("path", "")
	if base == "":
		return
	var loaded := {}
	for d: String in ["n", "ne", "e", "se", "s", "sw", "w", "nw"]:
		var path: String = base + d + ".png"
		if not ResourceLoader.exists(path):
			return
		loaded[d] = load(path)
	tex_n = loaded["n"]; tex_ne = loaded["ne"]; tex_e = loaded["e"]; tex_se = loaded["se"]
	tex_s = loaded["s"]; tex_sw = loaded["sw"]; tex_w = loaded["w"]; tex_nw = loaded["nw"]
	if _body:
		_body.scale   = Vector2.ONE   # skin sprites are pre-scaled to final on-screen size
		_body.texture = tex_s         # face south at spawn
	_last_facing = Vector2.DOWN

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_has_target = false
		velocity = Vector2.ZERO

func start_invulnerable(duration: float) -> void:
	_invulnerable_time = max(_invulnerable_time, duration)
	_single_blink_timer = 0.3
	modulate.a = 0.35

func start_dodge_invulnerable(duration: float) -> void:
	_invulnerable_time = max(_invulnerable_time, duration)

func start_bonus_blink(active: bool) -> void:
	_bonus_blink_active = active
	_bonus_speed_active = active
	if not active and _invulnerable_time <= 0 and _single_blink_timer <= 0:
		modulate.a = 1.0

func start_emerald_buff(duration: float) -> void:
	_emerald_time = max(_emerald_time, duration)
	start_invulnerable(duration)

func is_invulnerable() -> bool:
	return _invulnerable_time > 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_target_position = touch.position
			_has_target = true
		else:
			_has_target = false
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_target_position = drag.position
		_has_target = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_target_position = mb.position
				_has_target = true
			else:
				_has_target = false
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var mm := event as InputEventMouseMotion
			_target_position = mm.position
			_has_target = true

func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	
	if dodges_left < MAX_DODGES:
		if dodge_timer > 0.0:
			dodge_timer -= delta
			if dodge_timer <= 0.0:
				dodges_left += 1
				if dodges_left < MAX_DODGES:
					dodge_timer = DODGE_COOLDOWN
					
	if _emerald_time > 0.0:
		_emerald_time -= delta

	if _bonus_speed_active:
		move_speed = _base_move_speed * 1.8
	elif _emerald_time > 0.0:
		move_speed = _base_move_speed * 1.5
	else:
		move_speed = _base_move_speed

	if not _input_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var move_dir := Vector2.ZERO
	var keyboard_dir := _get_keyboard_dir()
	if keyboard_dir != Vector2.ZERO:
		_has_target = false
		move_dir = keyboard_dir
		velocity = keyboard_dir * move_speed
	elif _has_target:
		var to_target := _target_position - global_position
		if to_target.length() > 4.0:
			move_dir = to_target.normalized()
			velocity = move_dir * move_speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_clamp_to_view()

	if move_dir != Vector2.ZERO:
		_set_facing(move_dir)

func _set_facing(dir: Vector2) -> void:
	if dir == _last_facing:
		return
	_last_facing = dir
	if _body == null:
		return
	var angle := dir.angle()
	# Bucket into 8 octants. angle: -PI..PI (E=0, S=PI/2, W=PI, N=-PI/2)
	var octant := int(round(angle / (PI / 4.0))) % 8
	if octant < 0:
		octant += 8
	# octant: 0=E, 1=SE, 2=S, 3=SW, 4=W, 5=NW(or -3), 6=N(or -2), 7=NE(or -1)
	var tex: Texture2D = null
	match octant:
		0: tex = tex_e
		1: tex = tex_se
		2: tex = tex_s
		3: tex = tex_sw
		4: tex = tex_w
		5: tex = tex_nw
		6: tex = tex_n
		7: tex = tex_ne
	if tex:
		_body.texture = tex

func _get_keyboard_dir() -> Vector2:
	var x := 0
	if Input.is_key_pressed(KEY_LEFT)  or Input.is_key_pressed(KEY_A): x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): x += 1
	var y := 0
	if Input.is_key_pressed(KEY_UP)   or Input.is_key_pressed(KEY_W): y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): y += 1
	var dir := Vector2(x, y)
	if dir == Vector2.ZERO:
		return Vector2.ZERO
	return dir.normalized()

func _clamp_to_view() -> void:
	var view := get_viewport_rect()
	global_position.x = clamp(global_position.x, bounds_margin, view.size.x - bounds_margin)
	global_position.y = clamp(global_position.y, bounds_margin, view.size.y - bounds_margin)

func do_dodge() -> bool:
	if dodges_left > 0 and not is_dodging:
		dodges_left -= 1
		is_dodging = true
		start_dodge_invulnerable(1.0)
		
		var tween = create_tween()
		tween.tween_property(self, "rotation", rotation + TAU, 0.5)
		tween.tween_callback(func(): is_dodging = false; rotation = 0.0)
		
		if dodges_left < MAX_DODGES and dodge_timer <= 0.0:
			dodge_timer = DODGE_COOLDOWN
		return true
	return false

func refund_dodge() -> void:
	if dodges_left < MAX_DODGES:
		dodges_left += 1
		if dodges_left == MAX_DODGES:
			dodge_timer = 0.0

func _update_invulnerability(delta: float) -> void:
	if _invulnerable_time > 0.0:
		_invulnerable_time -= delta
		if _invulnerable_time <= 0.0:
			_invulnerable_time = 0.0

	if _single_blink_timer > 0.0:
		_single_blink_timer -= delta
		if _single_blink_timer <= 0.0:
			modulate.a = 1.0

	if _bonus_blink_active:
		_blink_time += delta
		if _blink_time >= 0.15:
			_blink_time = 0.0
			modulate.a = 0.35 if modulate.a > 0.5 else 1.0
	elif _single_blink_timer <= 0.0 and _invulnerable_time <= 0.0:
		modulate.a = 1.0
