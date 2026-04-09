class_name GameDefinition
extends RefCounted
## Stores the static (does not change during runtime) definitions of the currently played game. 
## Contrast with [GameState].
## NOTE that this game definition object is a distinct type and concept from [GameDefinitionResource]

var game_name : String:
	get:
		return game_name
	set(new_name):
		game_name = new_name
		
var unit_types : Dictionary[int, UnitType] = {} ## All the types of units in the game

var players : Dictionary[int, Player] = {-1 : Player.NEUTRAL_PLAYER} ## All the players in the game
var teams : Dictionary[int, Team] = {-1 : Team.NEUTRAL_TEAM} ## All the teams in the game

# These are used for generating team and player ids
var teams_index = 0 # Count for how many teams there are
var players_index = 0 # Count for how many players there are

## Initializes the unit types from a game definition
func initUnitTypesFromResource(game_definition : GameDefinitionResource, 
								unit_name_type_dict: Dictionary[String, int]) -> void:
	var gd_units : Array[UnitResource] = game_definition.load_units()
	var type_count : int = 0
	for unit in gd_units:
		var cur_unit_type = UnitType.initFromUnitResource(unit, type_count)
		unit_types.set(type_count, cur_unit_type)
		unit_name_type_dict[ cur_unit_type.unit_name] = type_count
		type_count += 1
		
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
	
func get_player_by_id(id: int) -> Player:
	return players[id]

func get_new_team_id() -> int:
	teams_index += 1
	return teams_index

func get_new_player_id() -> int:
	players_index += 1
	return players_index

# INFO DEBUG methods
 
## Prints the unit types into a logfile
func printUnitTypes(to_log : bool):
	for type in unit_types.values():
		if (to_log == true):
			GML.log(type._to_string())
		else:
			print(type._to_string())
