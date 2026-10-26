class_name FloatingText
extends Label

# Texto que sobe e desaparece no mundo do jogo (numeros de dano, "NIVEL 2!", etc).
# Uso: FloatingText.spawn(get_parent(), global_position, "3", Color.WHITE)

const RISE_DISTANCE := 40.0
const DURATION := 0.7
const BOX_SIZE := Vector2(160, 32)


static func spawn(parent: Node, at_position: Vector2, message: String, color: Color = Color.WHITE, font_size: int = 20) -> void:
	var label := FloatingText.new()
	label.text = message
	label.modulate = color
	label.size = BOX_SIZE
	label.position = at_position - BOX_SIZE / 2.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 10
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	parent.add_child(label)


func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)
