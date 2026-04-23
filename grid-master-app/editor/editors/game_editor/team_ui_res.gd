class_name TeamUiRes
extends Resource




@export var _unit_information: Dictionary[String, bool]
@export var _team_name: String
@export var _team_color: Color
@export var _is_computer: bool = false


func init(unit_info: Dictionary[String, bool], team_name: String, team_color: Color, is_computer: bool = false) -> void: 
	_unit_information = unit_info
	_team_name = team_name
	_team_color = team_color
	_is_computer = is_computer

func get_units() -> Dictionary:
	return _unit_information

func get_team_color() -> Color: 
	return _team_color

func get_team_name() -> String: 
	return _team_name

func get_is_computer() -> bool:
	return _is_computer





















#
