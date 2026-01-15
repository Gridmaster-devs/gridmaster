class_name GameGrid
## Represents the map, which is a grid of grid tiles


var tiles : Array2D ## all the tiles on the map


## Returns the tile at the specified index
func getTile(x : int, y : int) -> GridTile:
	return tiles.getItem(x, y)


## Returns the tile type of the grid tile at the specified index
func getTileType(x : int, y : int) -> TileType:
	return getTile(x, y).getTileType()
	

## Sets the type of tile at specified position
func setTileType(x : int, y : int, tile_type : TileType) -> void:
	getTile(x, y).setTileType(tile_type)
	

## Returns the units that are on the specified tile
func getUnitsOnTile(x : int, y : int) -> Array[Unit]:
	return getTile(x, y).getUnits()


## Adds a unit to the grid
func addUnit(unit : Unit):
	var pos = unit.getPosition()
	assert(pos != null, "Unit's position cannot be null!")
	getTile(pos.x, pos.y).addUnit(unit)



# TODO: In the future should ask for a map to convert into a game grid
func _init(width : int, height : int):
	tiles = Array2D.new(width, height)
