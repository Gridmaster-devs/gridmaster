class_name GridTile
extends RefCounted
## Class that represents a single tile on the grid
## Contains information about the units on the tile and the type of the tile

# NOTE: Units are stored in both the grid tile and the game state object,
# you have to remember to remove it from both places
var unit : Unit = null ## Dictionary from Unit ID to the Units on the tile
var tile_type : TileType ## Reference to the type of tile
var position : Vector2i


## Returns the array of all the units on the grid tile
func get_unit() -> Unit:
	return unit


## Returns the type of the grid tile
func getTileType() -> TileType:
	return tile_type
	

## Sets the tile type of the grid tile
func setTileType(type : TileType) -> void:
	tile_type = type


## Adds the unit to the unit array
func addUnit(unit_p : Unit) -> void:
	unit = unit_p


func is_empty() -> bool:
	return (unit == null)


func remove_unit() -> void:
	unit = null


func _to_string():
	var ret_string : String = ""
	ret_string += ("(")
	ret_string += ("Tile: ")
	if (tile_type == null):
		ret_string += ("N/A")
	else:
		ret_string += (tile_type.tile_name)
	
	ret_string += (" | ")
	
	ret_string += ("Unit: ")
	if (unit == null):
		ret_string += ("N/A")
	else:
		ret_string += str(unit.unit_id) # bad
	
	ret_string += (")")
	
	return ret_string


func _init(grid_tile_type : TileType, position_p : Vector2i) -> void:
	tile_type = grid_tile_type
	position = position_p
