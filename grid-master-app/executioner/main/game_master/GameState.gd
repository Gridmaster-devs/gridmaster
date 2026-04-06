class_name GameState
extends RefCounted
## Stores the information about the state of the game i.e. data that changes 
## during runtime (= as the game is played). Contrast with [GameDefinition].


var _grid : GameGrid ## Grid that represents the map
var grid : GameGrid:
	get: return _grid
	set(v): return

# These are used for generating team and player ids
var teams_index = 0 # Count for how many teams there are
var players_index = 0 # Count for how many players there are

var units : Dictionary[int, Unit] = {} ## All the units in the game, NOTE: also stored in each map tile
var players : Dictionary[int, Player] = {-1 : Player.NEUTRAL_PLAYER} ## All the players in the game
var teams : Dictionary[int, Team] = {-1 : Team.NEUTRAL_TEAM} ## All the teams in the game

## tracks the id to be given to the next unit that spawns
## increments by one each time
var unit_id_count : int = 0

var turn_number : int = 0 ## What turn it is

## Contains the actions of the players. The actions are executed when all players
## have pressed the "end turn" button.
var action_queue : Array[PlayerAction] = []


## Adds a unit to the game.
##
## Adding a unit with the player id of -1 makes it a neutral unit
func addUnit(unit_type : UnitType, position : Vector2i, player_id : int) -> Unit:
	var id = getNewUnitId()
	
	var player : Player = players.get(player_id)
	
	var unit = Unit.new(unit_type, id, player, position)
	grid.addUnit(unit)
	units.set(id, unit)
	return unit

#CAUTION commented out but possibly still used by something
## Adds a unit by unit type id.
## Will fail if there is no unit type corresponding to the id.
#func addUnitByTypeId(id : int, position : Vector2i, player_id : int) -> Unit:
	#var unit_type = unit_types.get(id)
	#assert(unit_type != null, "Tried to add unit with invalid type ID!")
	#return addUnit(unit_type, position, player_id)


## Adds a team to the game.
func add_team(team_name : String, color : Color, team_units : Array[UnitType]) -> int:
	var team_id : int = get_new_team_id()
	teams.set(team_id, Team.new(team_name, team_id, color, team_units))
	return team_id


## Adds a player to the game.
func add_player(player_name : String, team_id : int, computer : bool) -> int:
	var player_id = get_new_player_id()
	players.set(player_id, Player.new(player_name, player_id, teams.get(team_id), computer))
	return player_id


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

# ---
# GETTERS AND SETTERS
# ---

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


func get_new_team_id() -> int:
	teams_index += 1
	return teams_index


func get_new_player_id() -> int:
	players_index += 1
	return players_index


## gets the game grid width
func getGridWidth() -> int: 
	return grid.getHeight()


## gets the game grid height
func getGridHeight() -> int: 
	return grid.getWidth()
	

func get_unit_by_id(id : int) -> Unit:
	return units.get(id)


## Returns the unit on the specified tile.
## Can return null if there is no unit on the tile.
func get_unit_on_tile(coords : Vector2i) -> Unit:
	return grid.get_unit_on_tile(coords)

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




## Prints the tile types into a logfile
func printTileTypes(to_log : bool):
	if (grid != null):
		grid.printTileTypes(to_log)


# ---
# GODOT PREDEFINED
# ---

func _init():
	pass
