extends CharacterBody2D

@export var speed: float = 180.0
@export var attack_damage: int = 1
@export var attack_time: float = 0.12
@export var attack_distance: float = 96.0

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false


func _ready() -> void:
	attack_area.monitoring = false
	attack_shape.disabled = true


func _physics_process(_delta: float) -> void:
	# Usa as acoes padrao do Godot para movimento em quatro direcoes.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction != Vector2.ZERO:
		last_direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

	if Input.is_action_just_pressed("attack"):
		attack()


func attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	# Move a area de ataque para a ultima direcao em que o jogador andou.
	attack_area.position = last_direction * attack_distance
	attack_area.monitoring = true
	attack_shape.disabled = false

	await get_tree().physics_frame

	# Qualquer Area2D com take_damage pode receber dano deste ataque.
	for area in attack_area.get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(attack_damage)

	await get_tree().create_timer(attack_time).timeout

	attack_area.monitoring = false
	attack_shape.disabled = true
	is_attacking = false
