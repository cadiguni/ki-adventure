extends Node2D

@export var dialogue_lines: Array[String] = [
	"Há criaturas estranhas aparecendo na floresta.",
	"Derrote três invasores e descubra quem está por trás disso.",
]
@export var objective_description: String = "Objetivo: Derrote os invasores"
@export var objective_target_count: int = 3

var player_nearby: Node = null
var player_in_range: bool = false
var dialogue_open: bool = false
var dialogue_index: int = 0
var quest_active: bool = false
var defeated_enemy_count: int = 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if not event.is_action_pressed("interact"):
		return

	if dialogue_open:
		advance_dialogue()
		get_viewport().set_input_as_handled()
		return

	if player_in_range and player_nearby != null:
		start_dialogue()
		get_viewport().set_input_as_handled()


func start_dialogue() -> void:
	dialogue_open = true
	dialogue_index = 0
	set_player_controls_enabled(false)
	show_current_dialogue_line()


func advance_dialogue() -> void:
	dialogue_index += 1

	if dialogue_index >= dialogue_lines.size():
		finish_dialogue()
		return

	show_current_dialogue_line()


func finish_dialogue() -> void:
	dialogue_open = false
	set_player_controls_enabled(true)
	start_quest()

	var hud := get_hud()
	if hud != null:
		hud.hide_dialogue()

	if not player_in_range:
		player_nearby = null


func start_quest() -> void:
	if quest_active:
		update_objective()
		return

	quest_active = true
	defeated_enemy_count = 0

	for enemy in get_tree().get_nodes_in_group("quest_enemies"):
		if enemy.has_signal("defeated"):
			enemy.connect("defeated", Callable(self, "_on_quest_enemy_defeated"))

	update_objective()


func _on_quest_enemy_defeated() -> void:
	if not quest_active:
		return

	defeated_enemy_count = min(defeated_enemy_count + 1, objective_target_count)
	update_objective()


func update_objective() -> void:
	var hud := get_hud()
	if hud != null:
		hud.show_objective("%s (%d/%d)" % [
			objective_description,
			defeated_enemy_count,
			objective_target_count,
		])


func show_current_dialogue_line() -> void:
	var hud := get_hud()
	if hud != null:
		hud.show_dialogue_line(dialogue_lines[dialogue_index])


func set_player_controls_enabled(enabled: bool) -> void:
	if player_nearby != null and player_nearby.has_method("set_controls_enabled"):
		player_nearby.set_controls_enabled(enabled)


func get_hud() -> Node:
	return get_tree().get_first_node_in_group("player_status_ui")


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = body
		player_in_range = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_in_range = false

		if not dialogue_open:
			player_nearby = null
