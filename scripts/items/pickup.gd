class_name Pickup
extends Area2D

# Item que os inimigos soltam. Encostar nele recupera vida ou ki.
# Depois de um tempo ele pisca e some.

enum ItemType { HEALTH, KI }

@export var item_type: ItemType = ItemType.HEALTH
@export var health_amount: int = 1
@export var ki_amount: float = 25.0
@export var lifetime: float = 12.0
@export var health_texture: Texture2D
@export var ki_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var time_alive: float = 0.0


func _ready() -> void:
	sprite.texture = health_texture if item_type == ItemType.HEALTH else ki_texture

	# Pequeno "pulo" ao aparecer.
	sprite.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(3, 3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	time_alive += delta
	sprite.position.y = sin(time_alive * 5.0) * 3.0

	# Nos ultimos 3 segundos o item pisca para avisar que vai sumir.
	if time_alive > lifetime - 3.0:
		sprite.visible = int(time_alive * 10.0) % 2 == 0

	if time_alive >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if item_type == ItemType.HEALTH and body.has_method("heal"):
		body.heal(health_amount)
	elif item_type == ItemType.KI and body.has_method("restore_ki"):
		body.restore_ki(ki_amount)

	queue_free()
