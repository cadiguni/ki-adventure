extends CanvasLayer

@onready var health_bar: ProgressBar = $Panel/VBoxContainer/HealthBar
@onready var ki_bar: ProgressBar = $Panel/VBoxContainer/KiBar
@onready var health_label: Label = $Panel/VBoxContainer/HealthLabel
@onready var ki_label: Label = $Panel/VBoxContainer/KiLabel


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		return

	if not player.has_method("get_stats"):
		return

	player.connect("stats_changed", Callable(self, "update_bars"))

	var stats: Dictionary = player.call("get_stats")
	update_bars(stats["current_health"], stats["max_health"], stats["current_ki"], stats["max_ki"])


func update_bars(current_health: int, max_health: int, current_ki: int, max_ki: int) -> void:
	health_label.text = "Vida: %d/%d" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.tooltip_text = "Vida: %d/%d" % [current_health, max_health]

	ki_label.text = "Ki: %d/%d" % [current_ki, max_ki]
	ki_bar.max_value = max_ki
	ki_bar.value = current_ki
	ki_bar.tooltip_text = "Ki: %d/%d" % [current_ki, max_ki]
