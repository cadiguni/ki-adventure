extends BasicEnemy

# Colosso Rubro: chefe de teste.
# Repete um ciclo de ataques (maquina de estados):
#   PERSEGUIR -> PREPARAR (pisca) -> INVESTIDA -> DESCANSAR -> ANEL DE ESFERAS -> ...
# Com metade da vida ele fica furioso: mais rapido e com anel duplo.

enum State { CHASE, WINDUP, CHARGE, RECOVER, SHOOT }

const WINDUP_COLOR := Color(1.0, 0.45, 0.45)
const ENRAGED_COLOR := Color(1.0, 0.75, 0.75)

@export var boss_name: String = "Colosso Rubro"
@export var projectile_scene: PackedScene
@export var charge_speed: float = 520.0
@export var chase_duration: float = 2.5
@export var windup_duration: float = 0.7
@export var charge_duration: float = 0.6
@export var recover_duration: float = 0.8
@export var ring_projectile_count: int = 10
# Area onde o chefe pode andar (dentro da arena), em coordenadas globais.
@export var movement_bounds: Rect2 = Rect2(690, 140, 490, 300)

var state: State = State.CHASE
var state_time: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO
var is_enraged: bool = false


func _ready() -> void:
	super()
	# O chefe nao precisa "ver" o jogador: ja comeca perseguindo.
	target_player = get_tree().get_first_node_in_group("player")

	var hud := get_hud()
	if hud != null:
		hud.show_boss_bar(boss_name, health, max_health)


func _physics_process(delta: float) -> void:
	bob_time += delta
	sprite.position.y = sin(bob_time * 4.0) * 2.0

	if target_player == null:
		return

	state_time += delta

	match state:
		State.CHASE:
			update_movement(delta)
			if state_time >= chase_duration:
				change_state(State.WINDUP)

		State.WINDUP:
			# Aviso para o jogador: o chefe pisca antes de avancar.
			var blink_on := int(state_time * 12.0) % 2 == 0
			sprite.modulate = WINDUP_COLOR if blink_on else Color.WHITE
			if state_time >= windup_duration:
				charge_direction = global_position.direction_to(target_player.global_position)
				sprite.modulate = get_base_color()
				change_state(State.CHARGE)

		State.CHARGE:
			global_position += charge_direction * charge_speed * delta
			if state_time >= charge_duration:
				change_state(State.RECOVER)

		State.RECOVER:
			if state_time >= recover_duration:
				change_state(State.SHOOT)

		State.SHOOT:
			shoot_ring_attack()
			change_state(State.CHASE)

	global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)
	apply_contact_damage()


func change_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0


# O chefe causa dano enquanto o jogador estiver encostado nele
# (a invulnerabilidade do jogador evita dano a cada quadro).
func apply_contact_damage() -> void:
	for body in contact_damage_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage)


func shoot_ring_attack() -> void:
	shoot_ring(ring_projectile_count, 0.0)

	if is_enraged:
		# Segundo anel, girado meio passo, para fechar os buracos do primeiro.
		await get_tree().create_timer(0.4).timeout
		if not is_defeated:
			shoot_ring(ring_projectile_count, PI / ring_projectile_count)


func shoot_ring(count: int, angle_offset: float) -> void:
	if projectile_scene == null:
		return

	for i in count:
		var direction := Vector2.RIGHT.rotated(TAU * i / count + angle_offset)
		var projectile := projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position + direction * 50.0
		projectile.setup(direction)


func take_damage(amount: int) -> void:
	super(amount)

	var hud := get_hud()
	if hud != null:
		hud.update_boss_bar(max(health, 0), max_health)

	if not is_enraged and not is_defeated and health <= max_health / 2.0:
		become_enraged()


func become_enraged() -> void:
	is_enraged = true
	move_speed *= 1.4
	charge_speed *= 1.2
	chase_duration *= 0.6
	windup_duration *= 0.7
	sprite.modulate = ENRAGED_COLOR

	var hud := get_hud()
	if hud != null:
		hud.show_message("%s ficou furioso!" % boss_name)


func get_base_color() -> Color:
	return ENRAGED_COLOR if is_enraged else Color.WHITE


# O chefe e pesado demais para ser empurrado.
func apply_knockback(_direction: Vector2, _force: float) -> void:
	pass


func flash_hurt() -> void:
	sprite.modulate = HURT_COLOR
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", get_base_color(), 0.2)


func play_defeat() -> void:
	var hud := get_hud()
	if hud != null:
		hud.hide_boss_bar()
		hud.show_message("%s foi derrotado!" % boss_name)

	get_tree().call_group("quest_listeners", "on_boss_defeated")

	super()


func get_hud() -> Node:
	return get_tree().get_first_node_in_group("player_status_ui")
