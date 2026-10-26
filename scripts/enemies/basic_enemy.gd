class_name BasicEnemy
extends Area2D

# Inimigo base. Outros inimigos (Vigia, Colosso) herdam deste script e
# sobrescrevem so o que muda, como update_movement().

signal defeated

# Quanto o empurrao perde de velocidade por segundo.
const KNOCKBACK_FRICTION := 1400.0
const HURT_COLOR := Color(1.0, 0.35, 0.35)
const DAMAGE_NUMBER_COLOR := Color(1.0, 0.95, 0.6)
const PICKUP_SCENE := preload("res://scenes/items/pickup.tscn")

@export var max_health: int = 3
@export var move_speed: float = 80.0
@export var contact_damage: int = 1
@export var xp_reward: int = 4
# Inimigos que contam para a missao do mestre entram no grupo "quest_enemies".
@export var counts_for_quest: bool = true

@export_group("Itens")
# Chance (0 a 1) de cada item ser solto ao morrer.
@export var drop_chance: float = 0.5
@export var drop_count: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var contact_damage_area: Area2D = $ContactDamageArea

var health: int
var target_player: Node2D
var is_defeated: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var bob_time: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	if counts_for_quest:
		add_to_group("quest_enemies")
	health = max_health
	# Cada inimigo comeca o "pulinho" em um momento diferente.
	bob_time = randf() * TAU


func _physics_process(delta: float) -> void:
	bob_time += delta
	sprite.position.y = sin(bob_time * 6.0) * 3.0

	# Enquanto esta sendo empurrado, o inimigo nao persegue o jogador.
	if knockback_velocity != Vector2.ZERO:
		global_position += knockback_velocity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
		return

	if target_player == null:
		return

	update_movement(delta)


# Movimento padrao: vai direto na direcao do jogador.
func update_movement(delta: float) -> void:
	var direction := global_position.direction_to(target_player.global_position)
	global_position += direction * move_speed * delta


func take_damage(amount: int) -> void:
	if is_defeated:
		return

	health -= amount
	flash_hurt()
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -36), str(amount), DAMAGE_NUMBER_COLOR)

	if health <= 0:
		is_defeated = true
		defeated.emit()
		give_xp_to_player()
		spawn_drops()
		play_defeat()


func give_xp_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("gain_xp"):
		player.gain_xp(xp_reward)


func spawn_drops() -> void:
	for i in drop_count:
		if randf() > drop_chance:
			continue

		var pickup := PICKUP_SCENE.instantiate()
		# Metade das vezes cura, metade recupera ki.
		pickup.item_type = Pickup.ItemType.HEALTH if randf() < 0.5 else Pickup.ItemType.KI
		pickup.position = position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
		# call_deferred: a morte costuma acontecer dentro de um sinal de fisica.
		get_parent().add_child.call_deferred(pickup)


func apply_knockback(direction: Vector2, force: float) -> void:
	if is_defeated:
		return

	knockback_velocity = direction.normalized() * force


func flash_hurt() -> void:
	sprite.modulate = HURT_COLOR
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func play_defeat() -> void:
	# Para de se mexer e de causar dano, encolhe e some da cena.
	set_physics_process(false)
	set_deferred("monitorable", false)
	contact_damage_area.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(sprite, "rotation", PI, 0.25)
	await tween.finished
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
