extends Node2D

# A missao do mestre passa por etapas. Cada etapa tem a sua fala.
enum QuestStage { NOT_STARTED, DEFEAT_INVADERS, DEFEAT_BOSS, REPORT_BACK, COMPLETED }

@export var dialogue_lines: Array[String] = [
	"Há criaturas estranhas aparecendo na floresta.",
	"Derrote três invasores e descubra quem está por trás disso.",
]
@export var objective_description: String = "Objetivo: Derrote os invasores"
@export var objective_target_count: int = 3

@export_group("Falas por etapa")
@export var invaders_reminder_lines: Array[String] = [
	"Os invasores ainda rondam a arena a leste.",
	"Volte quando tiver derrotado todos eles.",
]
@export var boss_warning_lines: Array[String] = [
	"Sinto uma energia enorme vindo da arena!",
	"Quando aquela criatura piscar em vermelho, saia do caminho... ou defenda no momento certo.",
]
@export var victory_lines: Array[String] = [
	"Você derrotou o Colosso Rubro? Impressionante!",
	"Mas ele era só um batedor. Algo muito maior está por trás dessas criaturas.",
	"Tome, recupere suas forças. Seu ki cresceu bastante nessa luta.",
]
@export var after_quest_lines: Array[String] = [
	"Continue treinando. Logo vamos precisar de você de novo.",
]

@export_group("Etapas finais")
@export var boss_objective_description: String = "Objetivo: Derrote o Colosso Rubro"
@export var report_objective_description: String = "Objetivo: Volte e fale com o mestre"
@export var reward_xp: int = 20

var player_nearby: Node = null
var player_in_range: bool = false
var dialogue_open: bool = false
var dialogue_index: int = 0
var current_lines: Array[String] = []
var quest_stage: QuestStage = QuestStage.NOT_STARTED
var defeated_enemy_count: int = 0


func _ready() -> void:
	# O chefe e o spawner avisam este grupo quando algo acontece na missao.
	add_to_group("quest_listeners")


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
	current_lines = get_lines_for_stage()
	set_player_controls_enabled(false)
	show_current_dialogue_line()


func advance_dialogue() -> void:
	dialogue_index += 1

	if dialogue_index >= current_lines.size():
		finish_dialogue()
		return

	show_current_dialogue_line()


func finish_dialogue() -> void:
	dialogue_open = false
	set_player_controls_enabled(true)
	on_dialogue_finished()

	var hud := get_hud()
	if hud != null:
		hud.hide_dialogue()

	if not player_in_range:
		player_nearby = null


func get_lines_for_stage() -> Array[String]:
	match quest_stage:
		QuestStage.DEFEAT_INVADERS:
			return invaders_reminder_lines
		QuestStage.DEFEAT_BOSS:
			return boss_warning_lines
		QuestStage.REPORT_BACK:
			return victory_lines
		QuestStage.COMPLETED:
			return after_quest_lines
	return dialogue_lines


func on_dialogue_finished() -> void:
	match quest_stage:
		QuestStage.NOT_STARTED:
			start_quest()
		QuestStage.DEFEAT_INVADERS:
			update_objective()
		QuestStage.REPORT_BACK:
			give_reward()


func start_quest() -> void:
	quest_stage = QuestStage.DEFEAT_INVADERS

	# Conta tambem os inimigos que o jogador ja derrotou antes de falar com o mestre.
	var alive_count := 0
	for enemy in get_tree().get_nodes_in_group("quest_enemies"):
		if enemy.has_signal("defeated") and not enemy.is_defeated:
			enemy.connect("defeated", Callable(self, "_on_quest_enemy_defeated"))
			alive_count += 1

	defeated_enemy_count = max(objective_target_count - alive_count, 0)
	update_objective()


func give_reward() -> void:
	quest_stage = QuestStage.COMPLETED

	if player_nearby != null:
		if player_nearby.has_method("gain_xp"):
			player_nearby.gain_xp(reward_xp)
		if player_nearby.has_method("heal"):
			player_nearby.heal(player_nearby.max_health)
		if player_nearby.has_method("restore_ki"):
			player_nearby.restore_ki(player_nearby.max_ki)

	var hud := get_hud()
	if hud != null:
		hud.show_objective("Objetivo: Concluído!")
		hud.show_message("Missão concluída!")


# Chamado pelo BossSpawner com call_group("quest_listeners", ...).
func on_boss_spawned() -> void:
	quest_stage = QuestStage.DEFEAT_BOSS
	show_objective_text(boss_objective_description)


# Chamado pelo chefe ao ser derrotado.
func on_boss_defeated() -> void:
	quest_stage = QuestStage.REPORT_BACK
	show_objective_text(report_objective_description)


func show_objective_text(text: String) -> void:
	var hud := get_hud()
	if hud != null:
		hud.show_objective(text)


func _on_quest_enemy_defeated() -> void:
	if quest_stage != QuestStage.DEFEAT_INVADERS:
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
		hud.show_dialogue_line(current_lines[dialogue_index])


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
