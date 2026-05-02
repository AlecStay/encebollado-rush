extends Area2D

signal touched(spawnable: Area2D)

@export var kind := ""
@export var is_hazard := true
@export var points := 10
@export var scroll_speed := 120.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("spawnable")
	collision_mask = 1
	collision_layer = 2 if is_hazard else 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position.y += scroll_speed * delta
	var view := get_viewport_rect()
	var cull := 32.0
	if _sprite and _sprite.texture:
		cull = _sprite.texture.get_height()
	if global_position.y > view.size.y + cull:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("touched", self)
		queue_free()
