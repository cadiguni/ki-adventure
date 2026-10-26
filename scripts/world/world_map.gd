extends Node2D

# Mapa do mundo, feito com duas camadas de tiles:
#   Ground    - chao (grama, terra, piso, agua)
#   Obstacles - arvores, rochas e muros, com colisao (layer 1)
# Para editar: abra scenes/world/world_map.tscn, selecione uma camada
# e pinte com os tiles na aba "TileMap" la embaixo no editor.

@onready var ground: TileMapLayer = $Ground


func _ready() -> void:
	# Espera um quadro para o jogador ja estar no grupo "player".
	await get_tree().process_frame
	limit_player_camera()


# Impede a camera de mostrar o vazio fora do mapa.
func limit_player_camera() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	var used_cells := ground.get_used_rect()
	var tile_size := Vector2(ground.tile_set.tile_size) * ground.scale
	var top_left := ground.global_position + Vector2(used_cells.position) * tile_size
	var bottom_right := top_left + Vector2(used_cells.size) * tile_size

	camera.limit_left = int(top_left.x)
	camera.limit_top = int(top_left.y)
	camera.limit_right = int(bottom_right.x)
	camera.limit_bottom = int(bottom_right.y)
