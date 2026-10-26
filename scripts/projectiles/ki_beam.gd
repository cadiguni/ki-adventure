extends Node2D

# Lanca Celeste: feixe de ki continuo.
# O feixe e desenhado ao longo do eixo X local; quem cria o feixe gira
# este no para a direcao desejada. Um RayCast2D corta o feixe nas paredes.

@export var max_length: float = 560.0
@export var beam_width: float = 26.0
# O feixe causa dano em "pulsos", nao a cada quadro.
@export var damage_interval: float = 0.15
@export var knockback_force: float = 140.0

@onready var ray: RayCast2D = $RayCast2D
@onready var glow_line: Line2D = $GlowLine
@onready var core_line: Line2D = $CoreLine
@onready var start_orb: Sprite2D = $StartOrb
@onready var end_orb: Sprite2D = $EndOrb
@onready var hit_area: Area2D = $HitArea
@onready var hit_shape: CollisionShape2D = $HitArea/CollisionShape2D

var damage: int = 1
var damage_timer: float = 0.0
var time_alive: float = 0.0
var is_stopping: bool = false
# Vai de 0 a 1 quando o feixe aparece e de volta a 0 quando ele some.
var width_scale: float = 0.0


func setup(new_damage: int) -> void:
	damage = new_damage


func _ready() -> void:
	ray.target_position = Vector2(max_length, 0)
	# Cada feixe usa a propria forma, porque o tamanho muda o tempo todo.
	hit_shape.shape = RectangleShape2D.new()


func _physics_process(delta: float) -> void:
	time_alive += delta

	var target_scale := 0.0 if is_stopping else 1.0
	width_scale = move_toward(width_scale, target_scale, delta * 8.0)
	if is_stopping and width_scale <= 0.0:
		queue_free()
		return

	var length := max_length
	if ray.is_colliding():
		length = to_local(ray.get_collision_point()).length()

	update_visual(length)
	update_hitbox(length)

	if is_stopping:
		return

	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = damage_interval
		hit_enemies()


func update_visual(length: float) -> void:
	# A largura treme um pouco para o feixe parecer "vivo".
	var flicker := 1.0 + 0.12 * sin(time_alive * 40.0)
	var points := PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])

	glow_line.points = points
	glow_line.width = beam_width * width_scale * flicker
	core_line.points = points
	core_line.width = beam_width * 0.45 * width_scale * flicker

	start_orb.scale = Vector2.ONE * 5.0 * width_scale * flicker
	end_orb.position = Vector2(length, 0)
	end_orb.scale = Vector2.ONE * 4.0 * width_scale * flicker


func update_hitbox(length: float) -> void:
	var rectangle := hit_shape.shape as RectangleShape2D
	rectangle.size = Vector2(length, beam_width)
	hit_shape.position = Vector2(length / 2.0, 0)


func hit_enemies() -> void:
	var push_direction := Vector2.RIGHT.rotated(global_rotation)

	for area in hit_area.get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage)

			if area.has_method("apply_knockback"):
				area.apply_knockback(push_direction, knockback_force)


# Chamado pelo jogador ao soltar o botao: o feixe afina e some.
func stop() -> void:
	is_stopping = true
