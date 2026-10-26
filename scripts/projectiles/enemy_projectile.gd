extends Area2D

# Projetil disparado pelos inimigos. Detecta corpos (jogador e paredes),
# por isso usa body_entered em vez de area_entered.

@export var speed: float = 200.0
@export var damage: int = 1
@export var max_distance: float = 700.0

@onready var sprite: Sprite2D = $Sprite2D

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0


func setup(new_direction: Vector2) -> void:
	direction = new_direction.normalized()


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	position += movement
	traveled_distance += movement.length()
	sprite.rotation += 8.0 * delta

	if traveled_distance >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

	# Some ao acertar o jogador ou uma parede.
	queue_free()
