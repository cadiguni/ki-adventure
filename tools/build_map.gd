extends SceneTree

# Monta o TileSet e a cena do mapa (scenes/world/world_map.tscn) a partir
# de um desenho em texto, do mesmo jeito que generate_sprites.ps1 faz com os sprites.
#
# Uso (na raiz do projeto, com o editor do Godot fechado):
#   godot --headless --path . --script res://tools/build_map.gd
#
# ATENCAO: rodar de novo sobrescreve world_map.tscn. Se voce pintou o mapa
# no editor, edite por la mesmo e nao rode este script.

const TILES_TEXTURE := "res://assets/sprites/tiles.png"
const TILESET_PATH := "res://assets/tilesets/world_tileset.tres"
const SCENE_PATH := "res://scenes/world/world_map.tscn"
const MAP_SCRIPT := "res://scripts/world/world_map.gd"

const TILE_SIZE := 16
# Os tiles tem 16 px e sao desenhados 3x maiores, como os personagens.
const MAP_SCALE := 3.0

# Coluna de cada tile dentro de tiles.png.
enum Tile { GRASS, TALL_GRASS, FLOWERS, DIRT, FLOOR, FLOOR_CRACKED, WATER, TREE, ROCK, WALL }

# Tiles que bloqueiam a passagem (recebem colisao).
const SOLID_TILES := [Tile.WATER, Tile.TREE, Tile.ROCK, Tile.WALL]

# Legenda do desenho:
#   .  grama        ,  grama alta    *  flores     =  trilha de terra
#   _  piso arena   -  piso rachado  ~  agua
#   T  arvore       o  rocha         #  muro de pedra
# Cada caractere vira um tile de 48x48 px no jogo.
const LAYOUT := [
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"T~~~..,....*...TT..T.TTTTTTTTTTTTTTTTTTT",
	"T~~~~.....,....T.,....TT.,..T....,..T..T",
	"T.~~..*.......,..T..,..T###############T",
	"T..*.........,...T..,...#_____-_______#T",
	"T.,....,.....T......T...#_____________#T",
	"T....*....o....,.T....,.#___-_________#T",
	"T..,.......T.......o....#_________-___#T",
	"T.*..,..........T....,..#_____________#T",
	"T.======================_____________-#T",
	"T.======================______________#T",
	"T...,..*....T.....,..T..#__-__________#T",
	"T.o.....,.....T.o.......#_____________#T",
	"T..*..,....T.....,..T...#________-____#T",
	"T.......o.....,..T......#_____________#T",
	"T.,..*.....T.......,..T.#____-________#T",
	"T....,...,.....T..o...,.###############T",
	"T.*....T.....,.....T.......,.T...o...,.T",
	"T...,.....T....,.T..,...TT.....T.......T",
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
]


func _initialize() -> void:
	var tile_set := build_tile_set()
	DirAccess.make_dir_recursive_absolute(TILESET_PATH.get_base_dir())
	check(ResourceSaver.save(tile_set, TILESET_PATH), TILESET_PATH)
	# Recarrega para a cena apontar para o arquivo .tres (e nao embutir o TileSet).
	tile_set = load(TILESET_PATH)

	var map := build_map_scene(tile_set)
	var packed := PackedScene.new()
	packed.pack(map)
	DirAccess.make_dir_recursive_absolute(SCENE_PATH.get_base_dir())
	check(ResourceSaver.save(packed, SCENE_PATH), SCENE_PATH)

	map.free()
	quit()


func check(error: Error, path: String) -> void:
	if error == OK:
		print("Salvo: ", path)
	else:
		push_error("Falha ao salvar %s (erro %d)" % [path, error])


func build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Camada de fisica 0 = layer 1 ("paredes"), a mesma das paredes antigas.
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = load(TILES_TEXTURE)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, 0)

	for tile in Tile.values():
		var coords := Vector2i(tile, 0)
		source.create_tile(coords)
		if tile in SOLID_TILES:
			var data := source.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, get_collision_points(tile))

	return tile_set


# Pontos do poligono de colisao, com (0, 0) no centro do tile.
func get_collision_points(tile: int) -> PackedVector2Array:
	var half := TILE_SIZE / 2.0
	if tile == Tile.ROCK:
		# A rocha nao ocupa o tile inteiro.
		return PackedVector2Array([Vector2(-7, -5), Vector2(7, -5), Vector2(7, 6), Vector2(-7, 6)])
	return PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])


func build_map_scene(tile_set: TileSet) -> Node2D:
	var map := Node2D.new()
	map.name = "WorldMap"
	map.set_script(load(MAP_SCRIPT))

	# Chao embaixo e obstaculos (com fundo transparente) por cima.
	var ground := create_layer("Ground", tile_set)
	var obstacles := create_layer("Obstacles", tile_set)
	map.add_child(ground)
	map.add_child(obstacles)
	# O dono (owner) precisa ser a raiz para os nos serem salvos na cena.
	ground.owner = map
	obstacles.owner = map

	for y in LAYOUT.size():
		var row: String = LAYOUT[y]
		if row.length() != LAYOUT[0].length():
			push_error("Linha %d do mapa tem tamanho %d em vez de %d" % [y, row.length(), LAYOUT[0].length()])

		for x in row.length():
			var cell := Vector2i(x, y)
			var symbol := row[x]
			ground.set_cell(cell, 0, Vector2i(get_ground_tile(symbol), 0))

			var obstacle := get_obstacle_tile(symbol)
			if obstacle >= 0:
				obstacles.set_cell(cell, 0, Vector2i(obstacle, 0))

	return map


func create_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.scale = Vector2.ONE * MAP_SCALE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return layer


func get_ground_tile(symbol: String) -> int:
	match symbol:
		",": return Tile.TALL_GRASS
		"*": return Tile.FLOWERS
		"=": return Tile.DIRT
		"_", "#": return Tile.FLOOR
		"-": return Tile.FLOOR_CRACKED
		"~": return Tile.WATER
	# ".", "T", "o": grama embaixo.
	return Tile.GRASS


# Retorna -1 quando a celula nao tem obstaculo.
func get_obstacle_tile(symbol: String) -> int:
	match symbol:
		"T": return Tile.TREE
		"o": return Tile.ROCK
		"#": return Tile.WALL
	return -1
