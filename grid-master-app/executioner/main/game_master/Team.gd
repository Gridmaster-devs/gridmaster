class_name Team
extends RefCounted
## Class that represents a team

#TODO: Eventually we'll have to add which units the team has access to and other stuff

static var NEUTRAL_TEAM = Team.new("Neutral", -1, Color(0.3, 0.3, 0.3), [])

var team_name : String ## The name of the team

## The numerical id of the team (currently just the index of the the team
## in the team array in the gamestate
var team_id : int 

## The color of the team. Used in, for example, unit outlines.
var color : Color

## Whether this team is controlled by the computer rather than a human player.
var is_computer: bool = false

# This will determine what types of units the team can produce throughout the game
## An array of unit types available to the team
var unit_types : Array[UnitType]


static func DEBUG_new_team() -> Team:
	return Team.new("Debug team", -1, Color(1,1,1), [])


func _init(team_name_p : String, team_id_p : int, color_p : Color, units_p : Array[UnitType], is_computer_p: bool = false) -> void:
	team_name = team_name_p
	team_id = team_id_p
	color = color_p
	is_computer = is_computer_p
	unit_types = units_p
