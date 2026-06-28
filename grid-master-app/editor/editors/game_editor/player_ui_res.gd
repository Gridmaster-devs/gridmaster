class_name PlayerUiRes
extends Resource




@export var _team_information: Dictionary[String, bool]
@export var _player_name: String
@export var _key_unit_type_name: String = ""


func init(unit_info: Dictionary[String, bool], player_name: String, key_unit_type_name: String = "") -> void: 
	_team_information = unit_info
	_player_name = player_name
	_key_unit_type_name = key_unit_type_name

func get_teams() -> Dictionary:
	return _team_information

func get_player_name() -> String: 
	return _player_name

func get_key_unit_type_name() -> String:
	return _key_unit_type_name





















#
