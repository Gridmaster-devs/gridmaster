class_name TeamUiRes
extends Resource




@export var _unit_information: Dictionary[String, bool]
@export var _team_name: String
@export var _team_color: Color


func init(unit_info: Dictionary[String, bool], team_name: String, team_color: Color) -> void: 
	_unit_information = unit_info
	_team_name = team_name
	_team_color = team_color

func get_units() -> Dictionary:
	return _unit_information

func get_team_color() -> Color: 
	return _team_color

func get_team_name() -> String: 
	return _team_name





















#
