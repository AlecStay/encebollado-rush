extends Node2D

@export var scroll_speed := 80.0

var _height := 32.0

func _ready() -> void:
	var sprite := $Sprite2D as Sprite2D
	if sprite and sprite.texture:
		_height = sprite.texture.get_height() * sprite.scale.y

func _physics_process(delta: float) -> void:
	global_position.y += scroll_speed * delta
	var view := get_viewport_rect()
	if global_position.y > view.size.y + _height + 16.0:
		queue_free()
