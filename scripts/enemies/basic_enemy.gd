extends Area2D

@export var max_health: int = 3
@export var move_speed: float = 80.0
@export var contact_damage: int = 1

var health: int
var target_player: Node2D


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if target_player == null:
		return

	var direction := global_position.direction_to(target_player.global_position)
	global_position += direction * move_speed * delta


func take_damage(amount: int) -> void:
	health -= amount

	# Remove o inimigo da cena quando a vida acaba.
	if health <= 0:
		queue_free()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null


func _on_contact_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
