class_name PlayerUiRes
extends Resource




@export var _team_information: Dictionary[String, bool]
@export var _player_name: String


func init(unit_info: Dictionary[String, bool], player_name: String) -> void: 
	_team_information = unit_info
	_player_name = player_name

func get_teams() -> Dictionary:
	return _team_information

func get_player_name() -> String: 
	return _player_name





















#
