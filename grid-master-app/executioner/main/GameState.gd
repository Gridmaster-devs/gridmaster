class_name GameState
## Class that represents everything that makes up the current state of the game, ex. the units, the map, etc


var game_name : String
var grid : GameGrid ## Grid that represents the map
var units : Dictionary[int, Unit] = {} ## All the units in the game, NOTE: also stored in each map tile
var players : Array[Player] = [] ## All the players in the game
var teams : Array[Team] = [] ## All the teams in the game
var unit_types : Dictionary[int, UnitType] = {} ## All the types of units in the game


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
	return units.values()


## Gets a unit id for a new unit
func getNewUnitId() -> int:
	unit_id_count += 1
	return unit_id_count


## Creates a unit for testing
func createDebugUnit(position : Vector2i) -> void:
	addUnit(UnitType.debugType(), position, -1)
	

## Adds a unit to the game
func addUnit(unit_type : UnitType, position : Vector2i, player_id : int):
	var id = getNewUnitId()
	var unit = Unit.new(unit_type, id, player_id, position)
	grid.addUnit(unit)
	units.set(id, unit)
	

## Adds a unit by unit type id
## will fail if there is no unit type corresponding to the id
func addUnitByTypeId(id : int, position : Vector2i, player_id : int):
	var unit_type = unit_types.get(id)
	addUnit(unit_type, position, player_id)


## Initializes the unit types from a game definition
func initUnitTypesFromResource(game_definition : GameDefinitionResource) -> void:
	var gd_units : Array[UnitResourceDict] = game_definition.load_units()
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
	
	return game_state
	

## Creates a simple test game for debugging
static func debugInit(map_width : int, map_height : int, game_name_p : String) -> GameState:
	var gs = GameState.new()
	gs.grid = GameGrid.new(map_width, map_height)
	gs.grid.debugFill()
	gs.game_name = game_name_p
	return gs
	

## Prints the map into stdout
func printMap(to_log : bool):
	if (grid != null):
		grid.printMap(to_log)


## Prints the unit types into stdout
func printUnitTypes(to_log : bool):
	for type in unit_types.values():
		if (to_log == true):
			GML.log(type._to_string())
		else:
			print(type._to_string())


## Prints the tile types into stdout
func printTileTypes(to_log : bool):
	if (grid != null):
		grid.printTileTypes(to_log)


func getGameName() -> String:
	return game_name


func _init():
	pass
