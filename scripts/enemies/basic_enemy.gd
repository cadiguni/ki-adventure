extends Area2D

@export var max_health: int = 3

var health: int


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	health -= amount

	# Remove o inimigo da cena quando a vida acaba.
	if health <= 0:
		queue_free()
