class_name GridTile
extends RefCounted
## Class that represents a single tile on the grid
## Contains information about the units on the tile and the type of the tile

# NOTE: Units are stored in both the grid tile and the game state object,
# you have to remember to remove it from both places
var tile_type : TileType ## Reference to the type of tile
var position : Vector2i ## Position of the tile on the map, currently unused

var protection : int:
	get: return tile_type.attributes.get(TileType.TILE_ATTRIBUTE_TYPE.PROTECTION)
	set(v): return

## Returns the type of the grid tile
func getTileType() -> TileType:
	return tile_type
	

## Sets the tile type of the grid tile
func setTileType(type : TileType) -> void:
	tile_type = type

func _to_string():
	var ret_string : String = ""
	ret_string += ("(")
	ret_string += ("Tile: ")
	if (tile_type == null):
		ret_string += ("N/A")
	else:
		ret_string += (tile_type.tile_name)
	
	ret_string += (" | ")
	
	ret_string += ("NOTE: Unit no longer stored on tile, rework this _to_string() method if you want it to print the unit on the tile again")
	
	ret_string += (")")
	
	return ret_string


func _init(grid_tile_type : TileType, position_p : Vector2i) -> void:
	tile_type = grid_tile_type
	position = position_p
