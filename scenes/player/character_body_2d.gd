extends CharacterBody2D

@export var speed: float = 180.0

func _physics_process(delta):
	var direction = Vector2.ZERO

	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()