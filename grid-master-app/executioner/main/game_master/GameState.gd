class_name GameState
extends RefCounted
## Stores the information about the state of the game i.e. data that changes 
## during runtime (= as the game is played). Contrast with [GameDefinition].

var _units : Dictionary[int, Unit] = {} ## All the units in the game, NOTE: also stored in each map tile

## tracks the id to be given to the next unit that spawns
## increments by one each time
var _unit_id_count : int = 0

## What turn it is
var _turn_number : int = 0 


## Adds a unit to the game.
##
## Adding a unit with the player id of -1 makes it a neutral unit
func addUnit(unit_type : UnitType, position : Vector2i, player : Player) -> Unit:
	var id = getNewUnitId()
	
	var unit = Unit.new(unit_type, id, player, position)
	_units.set(id, unit)
	return unit


# NOTE: There's no cheat handling anywhere right now.
# An opposing player could currently technically make their units have unlimited
# movement if they hacked their side of the client
## Moves a unit to a new position.
func move_unit(unit_id : int, new_position : Vector2i) -> void:
	var unit = get_unit_by_id(unit_id)
	unit.set_position(new_position)


## Swaps the positions of two units. Currently only called
## by the step function in MoveAction
func swap_units(unit1 : Unit, unit2 : Unit) -> void:
	var u1_pos = unit1.grid_position
	var u2_pos = unit2.grid_position
	
	unit1.grid_position = u2_pos
	unit2.grid_position = u1_pos
	
	# The units' actions have to be move actions for this function to be called
	# so it's okay to do this
	var unit1_ma : MoveAction = unit1.current_action as MoveAction
	var unit2_ma : MoveAction = unit2.current_action as MoveAction
	
	unit1_ma.handle_swap()
	unit2_ma.handle_swap()


## Removes a unit from the map and the game
func remove_unit(unit : Unit) -> void:
	_units.erase(unit.unit_id)

func increment_turn_number() -> void:
	_turn_number += 1


func deep_copy() -> GameState:
	var new_units: Dictionary[int, Unit] = {}
	
	for unit in _units.values():
		var new_unit = unit.deep_copy()
		new_units[new_unit.unit_id] = new_unit
	
	var new_state = GameState.new(new_units, self._turn_number, self._unit_id_count)
	
	return new_state

# ---
# GETTERS AND SETTERS
# ---

## Returns the unit array
func getUnits() -> Array[Unit]:
	return _units.values()


## Gets a unit id for a new unit
func getNewUnitId() -> int:
	_unit_id_count += 1
	return _unit_id_count
	

func get_unit_by_id(id : int) -> Unit:
	return _units.get(id)

## Returns the unit in the specified position or null if the tile does not contain a unit at all
func get_unit_by_position_nullable(pos: Vector2i) -> Unit:
	for unit in _units.values():
		if unit.getPosition() == pos:
			return unit
	return null

# ---
# DEBUG FUNCTIONS
# ---

## Creates a unit for testing
#func createDebugUnit(position : Vector2i)-> Unit:
	#return addUnit(UnitType.debugType(), position, -1)


## Creates a simple test game for debugging
#static func DEBUG_init(map_width : int, map_height : int, game_name_p : String) -> GameState:
	#var gs = GameState.new()
	#gs.grid = GameGrid.new(map_width, map_height)
	#gs.grid.debugFill()
	#gs.game_name = game_name_p
	#return gs

# ---
# GODOT PREDEFINED
# ---

func _init(units : Dictionary[int, Unit], turn_number : int, unit_id_count : int):
	_units = units
	_unit_id_count = unit_id_count
	_turn_number = turn_number
