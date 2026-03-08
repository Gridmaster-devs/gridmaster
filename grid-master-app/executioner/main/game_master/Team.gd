class_name Team
extends RefCounted
## Class that represents a team

#TODO: Eventually we'll have to add which units the team has access to and other stuff

var team_name : String ## The name of the team
var team_id : int
var color : Color
var units : Array[UnitType]

static func DEBUG_new_team() -> Team:
	return Team.new("Debug team", -1, Color(1,1,1), [])

func _init(team_name_p : String, team_id_p : int, color_p : Color, units_p : Array[UnitType]) -> void:
	team_name = team_name_p
	team_id = team_id_p
	color = color_p
	units = units_p
