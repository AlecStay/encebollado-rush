extends CharacterBody2D

@export var move_speed := 220.0
@export var bounds_margin := 20.0

var _target_position := Vector2.ZERO
var _has_target := false
var _input_enabled := true
var _invulnerable_time := 0.0
var _blink_time := 0.0

func _ready() -> void:
	_target_position = global_position

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_has_target = false
		velocity = Vector2.ZERO

func start_invulnerable(duration: float) -> void:
	_invulnerable_time = max(_invulnerable_time, duration)
	_blink_time = 0.0

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

	if not _input_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var keyboard_dir := _get_keyboard_dir()
	if keyboard_dir != Vector2.ZERO:
		_has_target = false
		velocity = keyboard_dir * move_speed
	elif _has_target:
		var to_target := _target_position - global_position
		if to_target.length() > 4.0:
			velocity = to_target.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_clamp_to_view()

func _get_keyboard_dir() -> Vector2:
	var x := 0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		x += 1
	var y := 0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		y += 1
	var dir := Vector2(x, y)
	if dir == Vector2.ZERO:
		return Vector2.ZERO
	return dir.normalized()

func _clamp_to_view() -> void:
	var view := get_viewport_rect()
	global_position.x = clamp(global_position.x, bounds_margin, view.size.x - bounds_margin)
	global_position.y = clamp(global_position.y, bounds_margin, view.size.y - bounds_margin)

func _update_invulnerability(delta: float) -> void:
	if _invulnerable_time <= 0.0:
		if modulate.a < 1.0:
			modulate.a = 1.0
		return

	_invulnerable_time -= delta
	_blink_time += delta
	if _blink_time >= 0.1:
		_blink_time = 0.0
		modulate.a = 0.35 if modulate.a > 0.5 else 1.0

	if _invulnerable_time <= 0.0:
		_invulnerable_time = 0.0
		modulate.a = 1.0
