class_name GridTile
## Class that represents a single tile on the grid
## Contains information about the units on the tile and the type of the tile

# NOTE: Units are stored in both the grid tile and the game state object,
# you have to remember to remove it from both places
var units : Dictionary[int, Unit] = {} ## Dictionary from Unit ID to the Units on the tile
var tile_type : TileType ## Reference to the type of tile


## Returns the array of all the units on the grid tile
func getUnits() -> Dictionary[int, Unit]:
	return units


## Returns the type of the grid tile
func getTileType() -> TileType:
	return tile_type
	

## Sets the tile type of the grid tile
func setTileType(type : TileType) -> void:
	tile_type = type


## Returns the unit with the corresponding ID
## Returns null if no such unit exists
func getUnitById(unit_id : int) -> Variant:
	return units.get(unit_id)


## Adds the unit to the unit array
func addUnit(unit : Unit) -> void:
	units.set(unit.getId(), unit)
	

## Removes the unit from the tile
##
## This does not necessarily mean killing the unit, this happens
## when the unit moves
func removeUnitById(unit_id : int) -> void:
	var success : bool = units.erase(unit_id)
	assert(success == true, "Trying to remove unit that isn't there!")


func _to_string():
	var ret_string : String = ""
	ret_string += ("(")
	ret_string += ("Tile: ")
	if (tile_type == null):
		ret_string += ("N/A")
	else:
		ret_string += (tile_type.tile_name)
	
	ret_string += (" | ")
	var unit : Unit
	
	if units.values().is_empty():
		unit = null
	else:
		unit = units.values().front()
	
	ret_string += ("Unit: ")
	if (unit == null):
		ret_string += ("N/A")
	else:
		ret_string += str(unit.unit_id) # bad
	
	ret_string += (")")
	
	return ret_string


func _init(grid_tile_type : TileType) -> void:
	tile_type = grid_tile_type
