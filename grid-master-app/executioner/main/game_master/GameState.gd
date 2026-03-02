class_name GameState
extends RefCounted
## Class that represents everything that makes up the current state of the game, ex. the units, the map, etc

## The function that determines what happens when two units fight.
## Its parameters MUST be (unit1, unit2)
static var fight_func : Callable

var client_player_id : int = -1
var client_player_team_id : int = -1

var game_name : String
var grid : GameGrid ## Grid that represents the map
var units : Dictionary[int, Unit] = {} ## All the units in the game, NOTE: also stored in each map tile
var players : Array[Player] = [] ## All the players in the game
var teams : Array[Team] = [] ## All the teams in the game
var unit_types : Dictionary[int, UnitType] = {} ## All the types of units in the game
var _pathfinder : DijkstraPathfinder ## Dijkstra pathfinder for unit pathing




## tracks the id to be given to the next unit that spawns
## increments by one each time
var unit_id_count : int = 0

var turn_number : int = 0 ## What turn it is

## Contains the actions of the players. The actions are executed when all players
## have pressed the "end turn" button.
var action_queue : Array[PlayerAction] = []


## Adds a unit to the game
func addUnit(unit_type : UnitType, position : Vector2i, player_id : int) -> Unit:
	var id = getNewUnitId()
	var unit = Unit.new(unit_type, id, player_id, position)
	grid.addUnit(unit)
	units.set(id, unit)
	return unit
	

## Adds a unit by unit type id
## will fail if there is no unit type corresponding to the id
func addUnitByTypeId(id : int, position : Vector2i, player_id : int) -> Unit:
	var unit_type = unit_types.get(id)
	assert(unit_type != null, "Tried to add unit with invalid type ID!")
	return addUnit(unit_type, position, player_id)


# NOTE: There's no cheat handling anywhere right now.
# An opposing player could currently technically make their units have unlimited
# movement if they hacked their side of the client
## Moves a unit to a new position.
func move_unit(unit_id : int, new_position : Vector2i) -> void:
	var unit = get_unit_by_id(unit_id)
	var cur_pos = unit.getPosition()
	unit.set_position(new_position)
	grid.move_unit(unit_id, cur_pos, new_position)


## Ends the turn and processes all the actions that have been queued up.
## Unit actions are processed before other actions.
func end_turn() -> void:
	var unit_array = units.values()
	unit_array.sort_custom(Unit.unit_compare)
	
	for unit : Unit in unit_array:
		if unit.current_action != null:
			unit.current_action.execute(self)
	
	for action : PlayerAction in action_queue:
		action.execute(self)
	
	turn_number += 1


## Initializes the unit types from a game definition
func initUnitTypesFromResource(game_definition : GameDefinitionResource) -> void:
	var gd_units : Array[UnitResource] = game_definition.load_units()
	var type_count : int = 0
	for unit in gd_units:
		unit_types.set(type_count, UnitType.initFromUnitResource(unit, type_count))
		type_count += 1


## Initializes and returns a game state object from a game definition
static func initFromGameDefinition(game_definition : GameDefinitionResource) -> GameState:
	var game_state = GameState.new()
	game_state.initUnitTypesFromResource(game_definition)
	game_state.game_name = game_definition.game_name
	game_state.grid = GameGrid.initFromMapResource(game_definition.loadMap())
	
	game_state._pathfinder = DijkstraPathfinder.new()
	game_state._pathfinder.initialize(game_state.grid, game_state.units)
	
	return game_state


# ---
# GETTERS AND SETTERS
# ---

func getGameName() -> String:
	return game_name


## Returns the game grid
func getGameGrid() -> GameGrid:
	return grid


## Returns the unit array
func getUnits() -> Array[Unit]:
	return units.values()


## Gets a unit id for a new unit
func getNewUnitId() -> int:
	unit_id_count += 1
	return unit_id_count


## gets the game grid width
func getGridWidth() -> int: 
	return grid.getHeight()


## gets the game grid height
func getGridHeight() -> int: 
	return grid.getWidth()
	

func get_unit_by_id(id : int) -> Unit:
	return units.get(id)


func get_pathfinder() -> DijkstraPathfinder:
	return _pathfinder


## Returns the first unit on the specified tile.
## Can return null if there are no units on the tile.
func get_first_unit_on_tile(coords : Vector2i) -> Unit:
	return grid.get_first_unit_on_tile(coords)


func get_client_player_id() -> int:
	return client_player_id



# ---
# DEBUG FUNCTIONS
# ---

## Creates a unit for testing
func createDebugUnit(position : Vector2i)-> Unit:
	return addUnit(UnitType.debugType(), position, -1)


## Creates a simple test game for debugging
static func debugInit(map_width : int, map_height : int, game_name_p : String) -> GameState:
	var gs = GameState.new()
	gs.grid = GameGrid.new(map_width, map_height)
	gs.grid.debugFill()
	gs.game_name = game_name_p
	return gs
	

## Prints the map into a logfile
func printMap(to_log : bool):
	if (grid != null):
		grid.printMap(to_log)


## Prints the unit types into a logfile
func printUnitTypes(to_log : bool):
	for type in unit_types.values():
		if (to_log == true):
			GML.log(type._to_string())
		else:
			print(type._to_string())


## Prints the tile types into a logfile
func printTileTypes(to_log : bool):
	if (grid != null):
		grid.printTileTypes(to_log)


# ---
# GODOT PREDEFINED
# ---

func _init():
	pass
