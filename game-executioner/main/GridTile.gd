class_name GridTile
## Class that represents a single tile on the grid
## Contains information about the units on the tile and the type of the tile

# NOTE: Units are stored in both the grid tile and the game state object,
# you have to remember to remove it from both places
var units : Array[Unit] = [] ## Array of the units on the tile
var tile_type : TileType ## Reference to the type of tile


## Returns the array of all the units on the grid tile
func getUnits() -> Array[Unit]:
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
	var hasId = func(unit : Unit):
		return (unit.getId() == unit_id)
	
	var index = units.find_custom(hasId)
	return units.get(index)


## Gets the index of the unit in the unit array by the unit id
func getUnitIndexById(unit_id : int) -> int:
	var hasId = func(unit : Unit):
		return (unit.getId() == unit_id)
	
	return units.find_custom(hasId)


## Adds the unit to the unit array
func addUnit(unit : Unit) -> void:
	units.append(unit)
	

## Removes the unit from the tile
##
## This does not necessarily mean killing the unit, this happens
## when the unit moves
func removeUnitById(unit_id : int) -> void:
	var index = getUnitIndexById(unit_id)
	assert(index != -1, "Trying to remove unit that isn't there!")
	units.remove_at(index)


func _init(grid_tile_type : TileType) -> void:
	tile_type = grid_tile_type
