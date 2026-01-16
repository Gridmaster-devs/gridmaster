class_name Unit
## Class that represents a single unit on the battlefield

# object with attributes shared by all units of the same type
var type : UnitType


var unit_id : int ## The ID of the unit
var player_id : int ## The ID of the player who owns the unit
var hp : int ## The current HP of the unit
var morale : int ## The current morale of the unit
var grid_position : Vector2i ## The current position of the unit on the grid


## Initializes the unit from a specific unit type
func initFromUnitType() -> void:
	assert(type != null, "Unit type should not be null!")
	hp = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP)
	morale = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE)


## Returns the ID of the unit
func getId() -> int:
	return unit_id


func getPosition() -> Vector2i:
	return grid_position


func _init(unit_type : UnitType, unit_id_p : int, player_id_p : int, position : Vector2i) -> void:
	grid_position = position
	unit_id = unit_id_p
	player_id = player_id_p
	type = unit_type
	initFromUnitType()
