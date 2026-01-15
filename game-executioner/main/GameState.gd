class_name GameState
## Class that represents everything that makes up the current state of the game, ex. the units, the map, etc


var grid : GameGrid ## Grid that represents the map
var units : Array[Unit] = [] ## All the units in the game, NOTE: also stored in each map tile
var players : Array[Player] = [] ## All the players in the game
var teams : Array[Team] = [] ## All the teams in the game

var turn_number : int
var game_name : String

var tentative_actions : Array[GameAction] = []
var action_queue : Array[GameAction] = []


# TODO: This should take a map resource and turn it into the grid instead of asking for
# map width and height
func _init(map_width : int, map_height : int, players_p : Array[Player], teams_p : Array[Team], game_name_p : String):
	grid = GameGrid.new(map_width, map_height)
	players = players_p
	teams = teams_p
	game_name = game_name_p

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
