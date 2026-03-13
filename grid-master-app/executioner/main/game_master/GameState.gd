class_name GameState
extends RefCounted
## Class that represents everything that makes up the current state of the game, ex. the units, the map, etc

# This should maybe be in the gamemaster if the gamestate is supposed to be practically
# identical between clients
## The player ID of the player currently playing on this instance of the game
var client_player_id : int = -1

var game_name : String

var _grid : GameGrid ## Grid that represents the map
var grid : GameGrid:
	get: return _grid
	set(v): return

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
	
	var player : Player
	if (player_id == -1):
		player = Player.DEBUG_new_player()
	else:
		player = players[player_id]
	
	var unit = Unit.new(unit_type, id, player, position)
	grid.addUnit(unit)
	units.set(id, unit)
	return unit
	

## Adds a unit by unit type id
## will fail if there is no unit type corresponding to the id
func addUnitByTypeId(id : int, position : Vector2i, player_id : int) -> Unit:
	var unit_type = unit_types.get(id)
	assert(unit_type != null, "Tried to add unit with invalid type ID!")
	return addUnit(unit_type, position, player_id)


func add_team(team_name : String, color : Color, team_units : Array[UnitType]) -> void:
	var team_id : int = teams.size()
	teams.append(Team.new(team_name, team_id, color, team_units))


func add_player(player_name : String, team_id : int, computer : bool):
	var player_id = players.size()
	players.append(Player.new(player_name, player_id, teams[team_id], computer))


# NOTE: There's no cheat handling anywhere right now.
# An opposing player could currently technically make their units have unlimited
# movement if they hacked their side of the client
## Moves a unit to a new position.
func move_unit(unit_id : int, new_position : Vector2i) -> void:
	var unit = get_unit_by_id(unit_id)
	var cur_pos = unit.getPosition()
	unit.set_position(new_position)
	grid.move_unit(cur_pos, new_position)


## Swaps the positions of two units. Currently only called
## by the step function in MoveAction
func swap_units(unit1 : Unit, unit2 : Unit) -> void:
	var u1_pos = unit1.grid_position
	var u2_pos = unit2.grid_position
	
	grid.remove_unit(u1_pos)
	grid.remove_unit(u2_pos)
	
	unit1.grid_position = u2_pos
	unit2.grid_position = u1_pos
	
	grid.addUnit(unit1)
	grid.addUnit(unit2)
	
	# The units' actions have to be move actions for this function to be called
	# so it's okay to do this
	var unit1_ma : MoveAction = unit1.current_action as MoveAction
	var unit2_ma : MoveAction = unit2.current_action as MoveAction
	
	unit1_ma.handle_swap()
	unit2_ma.handle_swap()


## Removes a unit from the map and the game
func remove_unit(unit : Unit) -> void:
	grid.remove_unit(unit.grid_position)
	units.erase(unit.unit_id)


## Ends the turn and processes all the actions that have been queued up.
## Unit actions are processed before other actions.
func end_turn() -> void:
	var unit_array = units.values()
	var sort_func : Callable = GameArgs.args.get(GameArgs.ArgType.UNIT_INITIATIVE_FUNC)
	sort_func.call(unit_array)
	
	var done = false
	while(done == false):
		done = true
		
		for unit : Unit in unit_array:
			if (unit.current_action is MoveAction and unit.has_stopped() == false):
				done = false
				(unit.current_action as MoveAction).step()
		
		# If any units have died we remove them from the array
		for unit : Unit in unit_array:
			if (unit.is_dead()):
				unit_array.erase(unit)
				remove_unit(unit)
	
	# Clear actions
	for unit : Unit in unit_array:
		unit.current_action = null
	
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
	game_state._grid = GameGrid.initFromMapResource(game_definition.loadMap())
	
	game_state._pathfinder = DijkstraPathfinder.new()
	game_state._pathfinder.initialize(game_state.grid, game_state.units)
	
	# TODO: Add import from game definition
	GameArgs.initialize(game_state)
	
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


## Returns the unit on the specified tile.
## Can return null if there is no unit on the tile.
func get_unit_on_tile(coords : Vector2i) -> Unit:
	return grid.get_unit_on_tile(coords)


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
