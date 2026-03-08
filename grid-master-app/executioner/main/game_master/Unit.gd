class_name Unit
extends RefCounted
## Class that represents a single unit on the battlefield

## object with attributes shared by all units of the same type
var type : UnitType


var unit_id : int ## The ID of the unit
var player : Player ## The player that owns the unit
var team : Team

var hp : int ## The current HP of the unit
var movement_speed : int ## The speed of the unit NOTE: Currently using this as initiative
var morale : int ## The current morale of the unit

var grid_position : Vector2i ## The current position of the unit on the grid

var current_action : UnitAction = null ## The action the unit is set to perform on this turn

## Initializes the unit from a specific unit type
func initFromUnitType() -> void:
	assert(type != null, "Unit type should not be null!")
	hp = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP)
	morale = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE)
	movement_speed = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED)


## Returns the ID of the unit
func getId() -> int:
	return unit_id


func getPosition() -> Vector2i:
	return grid_position
	

## Returns whether the unit has stopped moving or not
func has_stopped() -> bool:
	if (current_action is MoveAction):
		if (current_action.stopped == false):
			return false
	
	return true


func get_next_movement_tile() -> Vector2i:
	if (current_action is MoveAction):
		return current_action.next_movement_tile()
	
	else:
		return grid_position


func get_swap_suggested_unit() -> int:
	if (current_action is MoveAction):
		return current_action.swap_suggested_unit
	
	else:
		return -1


func is_dead() -> bool:
	if hp <= 0:
		return true
	else:
		return false


func set_fought(enemy_id : int) -> void:
	if (current_action is MoveAction):
		current_action.units_fought.set(enemy_id, true)
		
	else:
		return


func get_team_id() -> int:
	return team.team_id


func get_player_id() -> int:
	return player.player_id


# This exists solely to be a function parameter for sorting the unit array
## Gets a unit's speed
static func unit_compare(u1 : Unit, u2 : Unit) -> bool:
	return u1.movement_speed > u2.movement_speed


func set_position(new_pos : Vector2i) -> void:
	grid_position = new_pos


func _init(unit_type : UnitType, unit_id_p : int, player_p : Player, position : Vector2i) -> void:
	grid_position = position
	unit_id = unit_id_p
	player = player_p
	team = player.team
	type = unit_type
	initFromUnitType()
