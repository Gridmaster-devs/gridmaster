class_name Player
extends RefCounted
## Class that represenets a player connected to the game

var player_name : String ## The name of the player
var player_id : int ## The ID of the player
var team : Team ## The ID of the team the player is part of
var computer : bool ## Whether the player is computer or human controlled


static func DEBUG_new_player() -> Player:
	return Player.new("Debug player", -1, Team.DEBUG_new_team(), false)


func _init(player_name_p : String, player_id_p : int, team_p : Team, computer_p : bool) -> void:
	player_name = player_name_p
	player_id = player_id_p
	team = team_p
	computer = computer_p
