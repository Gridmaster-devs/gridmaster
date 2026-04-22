class_name Player
extends RefCounted
## Class that represenets a player connected to the game

static var NEUTRAL_PLAYER = Player.new("Neutral", -1, Team.NEUTRAL_TEAM, false)

var player_name : String ## The name of the player
var player_id : int ## The ID of the player
var team : Team ## The ID of the team the player is part of
var computer : bool ## Whether the player is computer or human controlled

# Keeps track of how many of each UnitTypes the player has
var unit_type_counts: Dictionary[UnitType, int] = {}


func increment_unit_count(unit_type: UnitType) -> int:
	if not unit_type_counts.has(unit_type):
		unit_type_counts[unit_type] = 1
	else:
		unit_type_counts[unit_type] += 1
	
	return unit_type_counts[unit_type]


static func DEBUG_new_player() -> Player:
	return Player.new("Debug player", -1, Team.DEBUG_new_team(), false)


func _init(player_name_p : String, player_id_p : int, team_p : Team, computer_p : bool) -> void:
	player_name = player_name_p
	player_id = player_id_p
	team = team_p
	computer = computer_p
