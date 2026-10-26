extends CanvasLayer

const AWAKENED_KI_COLOR := Color(0.6, 0.95, 1.0)

@onready var health_bar: ProgressBar = $Panel/VBoxContainer/HealthBar
@onready var ki_bar: ProgressBar = $Panel/VBoxContainer/KiBar
@onready var health_label: Label = $Panel/VBoxContainer/HealthLabel
@onready var ki_label: Label = $Panel/VBoxContainer/KiLabel
@onready var level_label: Label = $Panel/VBoxContainer/LevelLabel
@onready var xp_bar: ProgressBar = $Panel/VBoxContainer/XpBar
@onready var objective_label: Label = $Panel/VBoxContainer/ObjectiveLabel
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/BossNameLabel
@onready var boss_bar: ProgressBar = $BossPanel/BossBar
@onready var message_label: Label = $MessageLabel
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/MarginContainer/DialogueLabel

var is_awakened: bool = false
var message_tween: Tween


func _ready() -> void:
	add_to_group("player_status_ui")
	dialogue_panel.visible = false
	objective_label.visible = false
	boss_panel.visible = false
	message_label.visible = false

	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		return

	if not player.has_method("get_stats"):
		return

	player.connect("stats_changed", Callable(self, "update_bars"))
	player.connect("transformation_changed", Callable(self, "_on_transformation_changed"))
	player.connect("xp_changed", Callable(self, "update_xp"))

	var stats: Dictionary = player.call("get_stats")
	update_bars(stats["current_health"], stats["max_health"], stats["current_ki"], stats["max_ki"])
	update_xp(stats["level"], stats["xp"], stats["xp_to_next"])


func update_bars(current_health: int, max_health: int, current_ki: float, max_ki: float) -> void:
	health_label.text = "Vida: %d/%d" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.tooltip_text = "Vida: %d/%d" % [current_health, max_health]

	ki_label.text = "Ki: %d/%d" % [int(current_ki), int(max_ki)]
	if is_awakened:
		ki_label.text += "  - FORMA DESPERTA"
	ki_bar.max_value = max_ki
	ki_bar.value = current_ki
	ki_bar.tooltip_text = "Ki: %d/%d" % [int(current_ki), int(max_ki)]


func update_xp(level: int, xp: int, xp_to_next: int) -> void:
	level_label.text = "Nível %d   XP: %d/%d" % [level, xp, xp_to_next]
	xp_bar.max_value = xp_to_next
	xp_bar.value = xp


func _on_transformation_changed(is_active: bool) -> void:
	is_awakened = is_active
	ki_bar.modulate = AWAKENED_KI_COLOR if is_active else Color.WHITE


func show_dialogue_line(text: String) -> void:
	dialogue_label.text = text
	dialogue_panel.visible = true


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func show_objective(text: String) -> void:
	objective_label.text = text
	objective_label.visible = true


func show_boss_bar(boss_name: String, health: int, max_health: int) -> void:
	boss_name_label.text = boss_name
	update_boss_bar(health, max_health)
	boss_panel.visible = true


func update_boss_bar(health: int, max_health: int) -> void:
	boss_bar.max_value = max_health
	boss_bar.value = health


func hide_boss_bar() -> void:
	boss_panel.visible = false


# Mensagem grande no meio da tela que some sozinha depois de alguns segundos.
func show_message(text: String, duration: float = 2.5) -> void:
	if message_tween != null:
		message_tween.kill()

	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0

	message_tween = create_tween()
	message_tween.tween_interval(duration)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	message_tween.tween_callback(message_label.hide)
