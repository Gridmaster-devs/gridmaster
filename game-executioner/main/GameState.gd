class_name GameState
## Class that represents everything that makes up the current state of the game, ex. the units, the map, etc


var game_name : String
var grid : GameGrid ## Grid that represents the map
var units : Array[Unit] = [] ## All the units in the game, NOTE: also stored in each map tile
var players : Array[Player] = [] ## All the players in the game
var teams : Array[Team] = [] ## All the teams in the game
var unit_types : Array[UnitType] ## All the types of units in the game


## tracks the id to be given to the next unit that spawns
## increments by one each time
var unit_id_count : int = 0

var turn_number : int = 0 ## What turn it is

## The actions the player plans to do
var tentative_actions : Array[GameAction] = []

## The actions the player locked in by pressing "end turn"
var action_queue : Array[GameAction] = []


# These functions exist so that the graphics element can request the
# map and units so it can draw them
## Returns the game grid
func getGameGrid() -> GameGrid:
	return grid


# These functions exist so that the graphics element can request the
# map and units so it can draw them
## Returns the unit array
func getUnits() -> Array[Unit]:
	return units
	

## Gets a unit id for a new unit
func getNewUnitId() -> int:
	unit_id_count += 1
	return unit_id_count


## Creates a unit for testing
func createDebugUnit(position : Vector2i) -> void:
	var unit = Unit.new(UnitType.debugType(), getNewUnitId(), -1, position)
	addUnit(unit)
	

## Adds a unit to the game
func addUnit(unit : Unit):
	grid.addUnit(unit)
	units.append(unit)


## Initializes the unit types from a game definition
func initUnitTypesFromResource(game_definition : GameDefinitionResource) -> void:
	var gd_units : Array[UnitResourceDict] = game_definition.load_units()
	var type_count : int = 0
	for unit in gd_units:
		unit_types.append(UnitType.initFromUnitResource(unit, type_count))
		type_count += 1


## Initializes and returns a game state object from a game definition
static func initFromGameDefinition(game_definition : GameDefinitionResource) -> GameState:
	var game_state = GameState.new()
	game_state.initUnitTypesFromResource(game_definition)
	game_state.game_name = game_definition.game_name
	# TODO: Add map stuff
	
	return game_state
	

## Creates a simple test game for debugging
static func debugInit(map_width : int, map_height : int, game_name_p : String) -> GameState:
	var gs = GameState.new()
	gs.grid = GameGrid.new(map_width, map_height)
	gs.game_name = game_name_p
	return gs



func _init():
	pass
