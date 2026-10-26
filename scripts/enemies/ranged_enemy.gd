extends BasicEnemy

# Vigia: fica a uma distancia segura do jogador e atira esferas de energia.

@export var projectile_scene: PackedScene
@export var preferred_distance: float = 190.0
@export var shoot_interval: float = 1.8

var shoot_timer: float = 1.0


func update_movement(delta: float) -> void:
	var to_player := target_player.global_position - global_position
	var distance := to_player.length()
	var direction := to_player.normalized()

	# Foge se o jogador chega perto, se aproxima se ele se afasta.
	if distance < preferred_distance - 40.0:
		global_position -= direction * move_speed * delta
	elif distance > preferred_distance + 40.0:
		global_position += direction * move_speed * delta

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval
		shoot(direction)


func shoot(direction: Vector2) -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * 30.0
	projectile.setup(direction)
