extends Area2D
## A boss "bolita". Moves along a fixed velocity, culls offscreen, and reports when it
## touches the player. Hit resolution (perfect-dodge -> damage boss, else -> damage player)
## lives in main.gd so it can reuse the existing dodge/combo path.

signal hit(projectile)

const MAX_LIFE := 9.0

var velocity := Vector2.ZERO
var _life := 0.0

func _ready() -> void:
	collision_layer = 2   # hazard layer
	collision_mask  = 1   # player
	body_entered.connect(_on_body_entered)

func setup(tex: Texture2D, pos: Vector2, vel: Vector2) -> void:
	position = pos
	velocity = vel
	if tex:
		$Sprite2D.texture = tex

func _physics_process(delta: float) -> void:
	position += velocity * delta
	_life += delta
	var v := get_viewport_rect().size
	if _life > MAX_LIFE or position.x < -24 or position.x > v.x + 24 \
			or position.y < -24 or position.y > v.y + 24:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("hit", self)
