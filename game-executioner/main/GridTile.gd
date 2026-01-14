class_name GridTile
## Class that represents a single tile on the grid
## Contains information about the units on the tile and the type of the tile

## Array of units on the tile
var units : Array[Unit] = []

# Reference to the type of tile
var tile_type : TileType

## Returns the array of all the units on the grid tile
func getUnits() -> Array[Unit]:
	return units


## Returns the type of the grid tile
func getTileType() -> TileType:
	return tile_type


## Returns the unit with the corresponding ID
## Returns null if no such unit exists
func getUnitById(unit_id : int) -> Variant:
	
	var hasId = func(unit : Unit):
		return (unit.getId() == unit_id)
	
	var index = units.find_custom(hasId)
	return units.get(index)


func _init(grid_tile_type : TileType) -> void:
	tile_type = grid_tile_type


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
