extends Node2D

# Faz o chefe aparecer na posicao deste no quando todos os inimigos
# da missao ("quest_enemies") forem derrotados.

@export var boss_scene: PackedScene
@export var spawn_delay: float = 1.5

var remaining_enemies: int = 0
var boss_spawned: bool = false


func _ready() -> void:
	# Espera um quadro para que todos os inimigos ja tenham entrado nos grupos.
	await get_tree().process_frame

	for enemy in get_tree().get_nodes_in_group("quest_enemies"):
		if enemy.has_signal("defeated"):
			enemy.connect("defeated", Callable(self, "_on_quest_enemy_defeated"))
			remaining_enemies += 1


func _on_quest_enemy_defeated() -> void:
	remaining_enemies -= 1

	if remaining_enemies <= 0 and not boss_spawned:
		spawn_boss()


func spawn_boss() -> void:
	boss_spawned = true

	var hud := get_tree().get_first_node_in_group("player_status_ui")
	if hud != null:
		hud.show_message("Algo enorme se aproxima...")

	await get_tree().create_timer(spawn_delay).timeout

	if boss_scene == null:
		return

	var boss := boss_scene.instantiate() as Node2D
	boss.position = position
	# call_deferred: adicionar areas de fisica no meio de um sinal de fisica da erro.
	get_parent().add_child.call_deferred(boss)
	get_tree().call_group("quest_listeners", "on_boss_spawned")
