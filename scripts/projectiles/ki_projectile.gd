extends Area2D

@export var speed: float = 360.0
@export var damage: int = 1
@export var max_distance: float = 420.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0


func setup(new_direction: Vector2) -> void:
	direction = new_direction.normalized()


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	position += movement
	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
