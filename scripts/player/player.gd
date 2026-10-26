extends CharacterBody2D

signal stats_changed(current_health: int, max_health: int, current_ki: float, max_ki: float)
signal transformation_changed(is_active: bool)

# Linhas da folha de sprites (assets/sprites/hero.png).
const ROW_DOWN := 0
const ROW_UP := 1
const ROW_SIDE := 2

# Colunas da folha de sprites.
const FRAME_IDLE := 0
const FRAME_STEP_A := 1
const FRAME_STEP_B := 2
const FRAME_PUNCH := 3

# Ciclo de caminhada: parado, passo A, parado, passo B.
const WALK_CYCLE := [FRAME_IDLE, FRAME_STEP_A, FRAME_IDLE, FRAME_STEP_B]
const WALK_FPS := 8.0

# Enquanto ataca, o jogador anda mais devagar.
const ATTACK_MOVE_FACTOR := 0.3

const CHARGE_AURA_COLOR := Color(0.45, 0.8, 1.0, 0.45)
const AWAKENED_AURA_COLOR := Color(0.75, 0.95, 1.0, 0.65)
const AURA_SCALE := 1.15

@export var speed: float = 180.0
@export var max_health: int = 5
@export var invulnerability_time: float = 0.8

@export_group("Combo corpo a corpo")
@export var attack_damage: int = 1
@export var finisher_damage: int = 2
@export var attack_time: float = 0.12
@export var attack_distance: float = 44.0
@export var combo_hits: int = 3
@export var combo_window: float = 0.35
@export var attack_knockback: float = 120.0
@export var finisher_knockback: float = 420.0

@export_group("Ki")
@export var max_ki: float = 100.0
@export var ki_charge_rate: float = 35.0
@export var ki_projectile_scene: PackedScene
@export var ki_spawn_distance: float = 40.0
@export var ki_blast_cost: float = 10.0
@export var ki_blast_damage: int = 1
@export var charged_blast_cost: float = 35.0
@export var charged_blast_damage: int = 4
@export var charged_blast_hold_time: float = 0.6

@export_group("Forma Desperta")
@export var transform_min_ki: float = 50.0
@export var transform_ki_drain: float = 5.0
@export var transform_speed_multiplier: float = 1.35
@export var transform_damage_multiplier: int = 2
@export var normal_texture: Texture2D
@export var awakened_texture: Texture2D

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var impact_sprite: Sprite2D = $AttackArea/Impact
@onready var sprite: Sprite2D = $Sprite
@onready var aura: Sprite2D = $Aura
@onready var ki_charge_orb: Sprite2D = $KiChargeOrb
@onready var camera: Camera2D = $Camera2D

var current_health: int
var current_ki: float
var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_invulnerable: bool = false
var controls_enabled: bool = true

var combo_step: int = 0
var combo_timer: float = 0.0
var punch_pose_time: float = 0.0
var walk_time: float = 0.0

var is_charging_ki: bool = false
var is_holding_ki_blast: bool = false
var ki_hold_time: float = 0.0

var is_transformed: bool = false
var is_transforming: bool = false
var aura_time: float = 0.0
var shake_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	current_ki = max_ki
	attack_area.monitoring = false
	attack_shape.disabled = true
	emit_stats_changed()


func _physics_process(delta: float) -> void:
	update_transformation(delta)
	update_aura(delta)
	update_camera_shake(delta)

	if not controls_enabled or is_transforming:
		stand_still(delta)
		return

	# Segurar "charge_ki" concentra energia: o jogador fica parado e o ki enche.
	is_charging_ki = Input.is_action_pressed("charge_ki") and not is_attacking
	if is_charging_ki:
		cancel_ki_blast_hold()
		charge_ki(delta)
		stand_still(delta)
		return

	# Usa as acoes padrao do Godot para movimento em quatro direcoes.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction != Vector2.ZERO:
		last_direction = direction.normalized()

	var current_speed := speed
	if is_transformed:
		current_speed *= transform_speed_multiplier
	if is_attacking:
		current_speed *= ATTACK_MOVE_FACTOR

	velocity = direction * current_speed
	move_and_slide()

	update_combo_timer(delta)

	if Input.is_action_just_pressed("attack"):
		attack()

	handle_ki_blast_input(delta)

	if Input.is_action_just_pressed("transform"):
		toggle_transformation()

	update_animation(direction, delta)


func stand_still(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	update_animation(Vector2.ZERO, delta)


# --- Animacao -----------------------------------------------------------------

func update_animation(direction: Vector2, delta: float) -> void:
	# Escolhe a linha da folha de sprites pela direcao em que o jogador olha.
	var row := ROW_DOWN
	if abs(last_direction.x) > abs(last_direction.y):
		row = ROW_SIDE
	elif last_direction.y < 0:
		row = ROW_UP

	# A folha so tem o lado direito; para a esquerda o sprite e espelhado.
	sprite.flip_h = row == ROW_SIDE and last_direction.x < 0

	var column := FRAME_IDLE
	if punch_pose_time > 0.0:
		punch_pose_time -= delta
		column = FRAME_PUNCH
	elif direction != Vector2.ZERO:
		walk_time += delta
		column = WALK_CYCLE[int(walk_time * WALK_FPS) % WALK_CYCLE.size()]
	else:
		walk_time = 0.0

	sprite.frame_coords = Vector2i(column, row)


# --- Combo corpo a corpo ------------------------------------------------------

func update_combo_timer(delta: float) -> void:
	if combo_timer <= 0.0:
		return

	combo_timer -= delta

	# Demorou demais para o proximo golpe: o combo recomeca.
	if combo_timer <= 0.0:
		combo_step = 0


func attack() -> void:
	if not controls_enabled:
		return

	if is_attacking:
		return

	is_attacking = true

	# Golpes 1, 2, 3, 1, 2, 3... O ultimo golpe do combo e mais forte.
	combo_step = combo_step % combo_hits + 1
	combo_timer = attack_time + combo_window
	var is_finisher := combo_step == combo_hits

	var damage := finisher_damage if is_finisher else attack_damage
	if is_transformed:
		damage *= transform_damage_multiplier
	var knockback := finisher_knockback if is_finisher else attack_knockback

	punch_pose_time = attack_time

	# Move a area de ataque para a ultima direcao em que o jogador andou.
	attack_area.position = last_direction * attack_distance
	attack_area.monitoring = true
	attack_shape.disabled = false

	await get_tree().physics_frame

	# Qualquer Area2D com take_damage pode receber dano deste ataque.
	var hit_something := false
	for area in attack_area.get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage)
			hit_something = true

			if area.has_method("apply_knockback"):
				area.apply_knockback(last_direction, knockback)

	if hit_something:
		show_impact(is_finisher)

	await get_tree().create_timer(attack_time).timeout

	attack_area.monitoring = false
	attack_shape.disabled = true
	is_attacking = false


func show_impact(is_finisher: bool) -> void:
	impact_sprite.visible = true
	impact_sprite.rotation = randf() * TAU
	impact_sprite.scale = Vector2.ONE * (4.5 if is_finisher else 2.5)

	if is_finisher:
		shake_camera(0.15)

	await get_tree().create_timer(0.08).timeout
	impact_sprite.visible = false


# --- Ki -----------------------------------------------------------------------

func charge_ki(delta: float) -> void:
	if current_ki >= max_ki:
		return

	current_ki = minf(current_ki + ki_charge_rate * delta, max_ki)
	emit_stats_changed()


func handle_ki_blast_input(delta: float) -> void:
	if Input.is_action_just_pressed("ki_blast"):
		is_holding_ki_blast = true
		ki_hold_time = 0.0

	if not is_holding_ki_blast:
		return

	if Input.is_action_pressed("ki_blast"):
		ki_hold_time += delta
		update_ki_charge_orb()
		return

	# Soltou o botao: toque rapido = rajada normal, segurar = rajada carregada.
	var held_long_enough := ki_hold_time >= charged_blast_hold_time
	cancel_ki_blast_hold()

	if held_long_enough and current_ki >= charged_blast_cost:
		shoot_ki_projectile(charged_blast_cost, charged_blast_damage, 2.5, true)
		shake_camera(0.2)
	else:
		shoot_ki_projectile(ki_blast_cost, ki_blast_damage, 1.0, false)


func update_ki_charge_orb() -> void:
	# Mostra uma esfera crescendo na frente do jogador enquanto o botao e segurado.
	var progress := minf(ki_hold_time / charged_blast_hold_time, 1.0)
	var is_ready := progress >= 1.0 and current_ki >= charged_blast_cost

	ki_charge_orb.visible = ki_hold_time > 0.12
	ki_charge_orb.position = last_direction * ki_spawn_distance
	ki_charge_orb.scale = Vector2.ONE * lerpf(2.0, 5.0, progress)

	if is_ready:
		ki_charge_orb.modulate = Color.WHITE
		ki_charge_orb.scale *= 1.0 + 0.1 * sin(aura_time * 30.0)
	else:
		ki_charge_orb.modulate = Color(1, 1, 1, 0.5)


func cancel_ki_blast_hold() -> void:
	is_holding_ki_blast = false
	ki_hold_time = 0.0
	ki_charge_orb.visible = false


func shoot_ki_projectile(cost: float, damage: int, size: float, pierce: bool) -> void:
	if not controls_enabled:
		return

	if ki_projectile_scene == null:
		return

	if current_ki < cost:
		return

	current_ki -= cost
	emit_stats_changed()

	if is_transformed:
		damage *= transform_damage_multiplier

	punch_pose_time = 0.15

	var projectile := ki_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + last_direction * ki_spawn_distance
	projectile.setup(last_direction, damage, size, pierce)


# --- Transformacao (Forma Desperta) ------------------------------------------

func toggle_transformation() -> void:
	if is_transformed:
		set_transformed(false)
	elif current_ki >= transform_min_ki:
		start_transformation()


func start_transformation() -> void:
	is_transforming = true
	is_invulnerable = true
	cancel_ki_blast_hold()
	shake_camera(0.6)

	# Explosao de energia: a aura cresce, o visual muda e a aura volta ao normal.
	set_aura_color(AWAKENED_AURA_COLOR)
	aura.visible = true
	var tween := create_tween()
	tween.tween_property(aura, "scale", sprite.scale * 2.2, 0.3)
	tween.tween_callback(set_transformed.bind(true))
	tween.tween_property(aura, "scale", sprite.scale * AURA_SCALE, 0.3)
	await tween.finished

	is_transforming = false
	is_invulnerable = false


func set_transformed(active: bool) -> void:
	is_transformed = active

	var texture := awakened_texture if active else normal_texture
	if texture != null:
		sprite.texture = texture
		aura.texture = texture

	transformation_changed.emit(active)


func update_transformation(delta: float) -> void:
	# Durante dialogos (controles desligados) a forma nao gasta ki.
	if not is_transformed or not controls_enabled:
		return

	current_ki = maxf(current_ki - transform_ki_drain * delta, 0.0)
	emit_stats_changed()

	if current_ki <= 0.0:
		set_transformed(false)


# --- Efeitos visuais ----------------------------------------------------------

func update_aura(delta: float) -> void:
	aura_time += delta

	# Durante a transformacao quem controla a aura e o tween.
	if is_transforming:
		aura.frame_coords = sprite.frame_coords
		aura.flip_h = sprite.flip_h
		return

	aura.visible = is_charging_ki or is_transformed
	if not aura.visible:
		return

	# A aura e uma copia do sprite, maior, de uma cor so e pulsando.
	aura.frame_coords = sprite.frame_coords
	aura.flip_h = sprite.flip_h
	aura.scale = sprite.scale * AURA_SCALE * (1.0 + 0.06 * sin(aura_time * 18.0))
	set_aura_color(AWAKENED_AURA_COLOR if is_transformed else CHARGE_AURA_COLOR)


func set_aura_color(color: Color) -> void:
	var aura_material := aura.material as ShaderMaterial
	if aura_material != null:
		aura_material.set_shader_parameter("aura_color", color)


func shake_camera(duration: float) -> void:
	shake_time = maxf(shake_time, duration)


func update_camera_shake(delta: float) -> void:
	if shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		return

	shake_time -= delta
	camera.offset = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))


# --- Vida ---------------------------------------------------------------------

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


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled

	if not controls_enabled:
		velocity = Vector2.ZERO
		attack_area.monitoring = false
		attack_shape.disabled = true
		is_attacking = false
		is_charging_ki = false
		punch_pose_time = 0.0
		cancel_ki_blast_hold()
