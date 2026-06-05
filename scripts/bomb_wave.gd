extends Node2D
# Touhou-style bomb shockwave: an expanding ring + soft blast that fades out
# and frees itself. Drawn entirely in code (no texture assets needed).

var _max_radius := 360.0
var _duration   := 0.5
var _color      := Color(0.45, 0.9, 1.0)
var _radius     := 0.0
var _elapsed    := 0.0

func start(max_radius: float, duration: float, color: Color) -> void:
	_max_radius = max_radius
	_duration   = duration
	_color      = color

func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	# ease-out so it bursts fast then settles
	_radius = _max_radius * (1.0 - pow(1.0 - t, 3.0))
	queue_redraw()
	if t >= 1.0:
		queue_free()

func _draw() -> void:
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var alpha := 1.0 - t
	# soft filled blast
	draw_circle(Vector2.ZERO, _radius, Color(_color.r, _color.g, _color.b, 0.18 * alpha))
	# bright leading ring
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(_color.r, _color.g, _color.b, alpha), 3.0, true)
	# inner white ring for extra punch
	draw_arc(Vector2.ZERO, _radius * 0.72, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.6 * alpha), 2.0, true)
