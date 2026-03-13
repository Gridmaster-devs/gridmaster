class_name Unit
extends RefCounted
## Class that represents a single unit on the battlefield

## object with attributes shared by all units of the same type
var type : UnitType


var unit_id : int ## The ID of the unit
var player : Player ## The player that owns the unit
var team : Team

var _hp : int ## The current HP of the unit
var hp : int:
	get: return _hp
	set(v): return

var _morale : int ## The current morale of the unit
var morale : int:
	get: return _morale
	set(v): return

var attack : int:
	get: return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.ATTACK)
	set(v): return

var movement_speed : int:
	get: return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED)
	set(v): return

var accuracy : int:
	get: return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.ACCURACY)
	set(v): return

var dodge : int:
	get: return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.DODGE)
	set(v): return

var piercing : int:
	get: return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.ARMOR_PIERCING)
	set(v): return

var armor : int:
	get: return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.ARMOR)
	set(v): return

var grid_position : Vector2i ## The current position of the unit on the grid

var current_action : UnitAction = null ## The action the unit is set to perform on this turn

## Initializes the unit from a specific unit type
func initFromUnitType() -> void:
	assert(type != null, "Unit type should not be null!")
	_hp = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP)
	_morale = type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE)


## Returns the ID of the unit
func getId() -> int:
	return unit_id


func getPosition() -> Vector2i:
	return grid_position
	

func get_damage() -> int:
	return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.ATTACK)


func get_move_speed() -> int:
	return type.attributes.get(UnitType.UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED)
	

## Returns whether the unit has stopped moving for this turn or not
func has_stopped() -> bool:
	if (current_action is MoveAction):
		if (current_action.stopped == false):
			return false
	
	return true


## Returns the next tile the unit wants to move to.
##
## The next movement tile is not necessarily the next tile on the path if,
## for instance, there's a friendly unit on the next tile, in which the unit
## will try to skip over it
func get_next_movement_tile() -> Vector2i:
	if (current_action is MoveAction):
		return current_action.next_movement_tile()
	
	else:
		return grid_position


## If the unit is moving, it returns the unit id of the unit that this unit wants to swap with.
##
## Swapping is a form of gridlock prevention, with the implementation found in the step
## function of the MoveAction. If the unit is not moving or is not trying to swap with anyone,
## returns -1.

func get_swap_suggested_unit() -> int:
	if (current_action is MoveAction):
		return current_action.swap_suggested_unit
	
	else:
		return -1


func is_dead() -> bool:
	if _hp <= 0:
		return true
	else:
		return false


## Called by the fight function when the unit has been in a battle to let it
## know it has been in a battle. This might cause the unit to stop, for example,
## if the "stop after fighting" flag has been set.
func set_fought(enemy_id : int) -> void:
	if (current_action is MoveAction):
		current_action.fought(enemy_id)
		
	else:
		return


## Returns true if the unit is currently in the middle of
## executing the next_movement_tile function.
##
## This exists as a form of gridlock prevention.
func searching_next_tile() -> bool:
	if (current_action is MoveAction):
		return current_action.searching_next_tile
	else:
		return false


func get_team_id() -> int:
	return team.team_id


func get_player_id() -> int:
	return player.player_id


# In the future units can maybe have special behavior when they take damage
## Called to signal the unit to take damage
func take_damage(damage : int):
	# remove damage from health
	_hp -= damage
	
	print("Unit %s with id %s from team %s took %s damage" % [type.unit_name, unit_id, team.team_name, damage])
	
	# making sure we won't process actions of dead units
	if (_hp <= 0):
		print("Unit %s with id %s from team %s died" % [type.unit_name, unit_id, team.team_name])
		current_action = null


func set_position(new_pos : Vector2i) -> void:
	grid_position = new_pos


func _init(unit_type : UnitType, unit_id_p : int, player_p : Player, position : Vector2i) -> void:
	grid_position = position
	unit_id = unit_id_p
	player = player_p
	team = player.team
	type = unit_type
	initFromUnitType()
