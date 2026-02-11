class_name GameGrid
## Represents the map, which is a grid of grid tiles


var tiles : Array2D ## all the tiles on the map
var strategic_tile_types : Dictionary[int, TileType] ## Maps tile type IDs to the tile types
var width : int
var height : int


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


## Returns the units that are on the specified tile
func getUnitsOnTile(x : int, y : int) -> Dictionary[int, Unit]:
	return getTile(x, y).getUnits()


# There's no error checking here because this SHOULD crash if
# it gets wrong information
## Removes a unit from the start tile, and adds it to the end tile.
## Does NOT edit the unit's information at all.
func move_unit(unit_id : int, start_pos : Vector2i, end_pos : Vector2i) -> void:
	var start_tile = get_tile_vec(start_pos)
	var end_tile = get_tile_vec(end_pos)
	var unit = start_tile.getUnitById(unit_id)
	
	start_tile.removeUnitById(unit_id)
	end_tile.addUnit(unit)

## Adds a unit to the grid
func addUnit(unit : Unit) -> void:
	var pos = unit.getPosition()
	assert(pos != null, "Unit's position cannot be null!")
	getTile(pos.x, pos.y).addUnit(unit)


func initTileTypesFromMapResource(map : GameMap) -> void:
	for tile : StrategicTileInformation in map.strategic_tile_information_map.values():
		var grid_tile : TileType = TileType.new()
		grid_tile.attributes.set(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT, tile.movement)
		grid_tile.attributes.set(TileType.TILE_ATTRIBUTE_TYPE.HIDING, tile.hiding)
		grid_tile.attributes.set(TileType.TILE_ATTRIBUTE_TYPE.PROTECTION, tile.protection)
		grid_tile.type_id = tile.source
		grid_tile.texture = tile.texture
		grid_tile.tile_name = tile.name
		strategic_tile_types.set(tile.source, grid_tile)
		

## Calls the tiles Array2D's fill method with the fill func as the parameter
func fillTiles(fill_func : Callable) -> void:
	tiles.fill(fill_func)


## Initializes a game grid from a map resource
static func initFromMapResource(map : GameMap) -> GameGrid:
	assert(map != null, "Map should not be null!")
	
	var grid = map.grid
	var game_grid = GameGrid.new(grid.width, grid.height)
	game_grid.initTileTypesFromMapResource(map)
	
	var fill_func = func(x: int, y: int):
		var grid_tile : GridTile =  GridTile.new(
			game_grid.strategic_tile_types.get(
				grid.grid[grid.width * y + x]
			)
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
	var fill_func = func(_x : int, _y : int):
		return GridTile.new(TileType.debugTile())
	
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
	tiles = Array2D.new(width_p, height_p)
