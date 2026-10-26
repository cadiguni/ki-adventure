extends Area2D

@export var speed: float = 360.0
@export var max_distance: float = 420.0
@export var knockback_force: float = 160.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var traveled_distance: float = 0.0
# A rajada carregada atravessa os inimigos em vez de sumir no primeiro.
var pierce: bool = false


func setup(new_direction: Vector2, new_damage: int = 1, size: float = 1.0, can_pierce: bool = false) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	scale = Vector2.ONE * size
	pierce = can_pierce


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	position += movement
	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("take_damage"):
		return

	area.take_damage(damage)

	if area.has_method("apply_knockback"):
		area.apply_knockback(direction, knockback_force * scale.x)

	if not pierce:
		queue_free()
