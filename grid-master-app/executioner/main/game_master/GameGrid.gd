class_name GameGrid
extends RefCounted
## Represents the map, which is a grid of grid tiles


var tiles : Array2D ## all the tiles on the map, actual type signature should be Array2D[GridTile] but not supported by Godot
var strategic_tile_types : Dictionary[int, TileType] ## Maps tile type IDs to the tile types
var width : int ## The width of the grid
var height : int ## The height of the grid


func getWidth() -> int:
	return width 


func getHeight() -> int:
	return height


func get_tiles() -> Array2D:
	return tiles


## Returns the tile at the specified index
func getTile(x : int, y : int) -> GridTile:
	return tiles.getItem(x, y)


func get_tile_vec(pos : Vector2i) -> GridTile:
	return tiles.getItem(pos.x, pos.y)


## Returns the tile type of the grid tile at the specified index
func getTileType(x : int, y : int) -> TileType:
	return getTile(x, y).getTileType()


## Sets the type of tile at specified position
func setTileType(x : int, y : int, tile_type : TileType) -> void:
	getTile(x, y).setTileType(tile_type)


func is_empty(pos : Vector2i) -> bool:
	return get_tile_vec(pos).is_empty()


func initTileTypesFromMapResource(attribute_grid: Array2D) -> void:
	for x in attribute_grid.width: 
		for y in attribute_grid.height: 
			var tile = attribute_grid.getItem(x, y)
			var id: int = tile["id"]
			if strategic_tile_types.has(id):
				continue
			var grid_tile : TileType = TileType.new()
			grid_tile.attributes.set(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT, tile["movement"])
			grid_tile.attributes.set(TileType.TILE_ATTRIBUTE_TYPE.HIDING, tile["hiding"])
			grid_tile.attributes.set(TileType.TILE_ATTRIBUTE_TYPE.PROTECTION, tile["protection"])
			grid_tile.type_id = id
			grid_tile.texture = tile["texture"]
			grid_tile.tile_name = tile["name"]
			strategic_tile_types.set(id, grid_tile)

func _generate_ids(strategic: Array2D) -> Array2D: 
	#TODO: add ids inside tactical maps as well
	var id_map: Dictionary[String, int] = {}
	var count: int = 0
	for x in strategic.width:
		for y in strategic.height:
			var tile = strategic.getItem(x, y)
			if !id_map.has(tile["name"]):
				id_map[tile["name"]] = count
				count += 1
			tile["id"] = id_map[tile["name"]]
	return strategic
	

## Calls the tiles Array2D's fill method with the fill func as the parameter
func fillTiles(fill_func : Callable) -> void:
	tiles.fill(fill_func)


## Initializes a game grid from a map resource
static func initFromMapResource(map : MapResource) -> GameGrid:
	assert(map != null, "Map should not be null!")
	var grid: Array2D = map.get_strategic_map().get_attribute_grids()[0]
	var game_grid = GameGrid.new(grid.width, grid.height)
	grid = game_grid._generate_ids(grid)
	game_grid.initTileTypesFromMapResource(grid)
	
	var fill_func = func(x: int, y: int):
		var grid_tile : GridTile = GridTile.new(
			game_grid.strategic_tile_types.get(
				grid.getItem(x, y)["id"]
			), Vector2i(x, y)
		)
		return grid_tile
	
	game_grid.fillTiles(fill_func)
	return game_grid


## Prints the entire map into stdout
func printMap(to_log : bool):
	if (to_log == true):
		GML.log(tiles.contentToString())
	else:
		tiles.printAll()


## Fills the entire map with a debug tile
func debugFill():
	var fill_func = func(x : int, y : int):
		return GridTile.new(TileType.debugTile(), Vector2i(x, y))
	
	fillTiles(fill_func)


## Prints all the tile types into stdout
func printTileTypes(to_log : bool):
	for type : TileType in strategic_tile_types.values():
		if (to_log == true):
			GML.log(type._to_string())
		else:
			print(type._to_string())


# TODO: In the future should ask for a map to convert into a game grid
func _init(width_p : int, height_p : int):
	width = width_p
	height = height_p
	tiles = Array2D.new()
	tiles.init(width_p, height_p)
