class_name GameGrid
## Represents the map, which is a grid of grid tiles


var tiles : Array2D ## all the tiles on the map


## Returns the tile at the specified index
func getTile(width : int, height : int) -> GridTile:
	return tiles.getItem(width, height)


## Returns the tile type of the grid tile at the specified index
func getTileType(width : int, height : int) -> TileType:
	return getTile(width, height).getTileType()
	
	
func setTileType(width : int, height : int, tile_type : TileType) -> void:
	getTile(width, height).setTileType(tile_type)
	
	
func getUnitsOnTile(width : int, height : int) -> Array[Unit]:
	return getTile(width, height).getUnits()
	
	



# TODO: In the future should ask for a map to convert into a game grid
func _init(width : int, height : int):
	tiles = Array2D.new(width, height)
