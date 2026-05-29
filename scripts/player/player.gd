extends CharacterBody2D

signal stats_changed(current_health: int, max_health: int, current_ki: int, max_ki: int)

@export var speed: float = 180.0
@export var max_health: int = 5
@export var max_ki: int = 5
@export var attack_damage: int = 1
@export var attack_time: float = 0.12
@export var attack_distance: float = 96.0
@export var invulnerability_time: float = 0.8
@export var ki_projectile_scene: PackedScene
@export var ki_spawn_distance: float = 72.0
@export var ki_blast_cost: int = 1

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var sprite: Sprite2D = $AnimatedSprite2D

var current_health: int
var current_ki: int
var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_invulnerable: bool = false


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	current_ki = max_ki
	attack_area.monitoring = false
	attack_shape.disabled = true
	emit_stats_changed()


func _physics_process(_delta: float) -> void:
	# Usa as acoes padrao do Godot para movimento em quatro direcoes.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction != Vector2.ZERO:
		last_direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

	if Input.is_action_just_pressed("attack"):
		attack()

	if Input.is_action_just_pressed("ki_blast"):
		shoot_ki_projectile()


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


func shoot_ki_projectile() -> void:
	if ki_projectile_scene == null:
		return

	if current_ki < ki_blast_cost:
		return

	current_ki -= ki_blast_cost
	emit_stats_changed()

	var projectile := ki_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + last_direction * ki_spawn_distance
	projectile.setup(last_direction)


func take_damage(amount: int) -> void:
	if is_invulnerable:
		return

	current_health = max(current_health - amount, 0)
	print("Vida do Player: %d/%d" % [current_health, max_health])
	emit_stats_changed()

	if current_health <= 0:
		get_tree().reload_current_scene()
		return

	start_invulnerability()


func start_invulnerability() -> void:
	is_invulnerable = true

	var elapsed_time := 0.0
	var blink_interval := 0.1

	while elapsed_time < invulnerability_time:
		sprite.visible = not sprite.visible
		await get_tree().create_timer(blink_interval).timeout
		elapsed_time += blink_interval

	sprite.visible = true
	is_invulnerable = false


func get_stats() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"current_ki": current_ki,
		"max_ki": max_ki,
	}


func emit_stats_changed() -> void:
	stats_changed.emit(current_health, max_health, current_ki, max_ki)
