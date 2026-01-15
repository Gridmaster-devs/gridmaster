class_name GameMaster
extends Node

var game_state : GameState

# TODO: this should take the game definition as a parameter and initialize the game from that
# it will still need the players, however
## Initializes a game
func initGame(map_width : int, map_height : int, players : Array[Player], teams : Array[Team], game_name : String):
	game_state = GameState.new(map_width, map_height, players, teams, game_name)
	

# This is ONLY for drawing the map and the units!!
# Only the game master should EVER modify the game state
## Returns the game grid if the game state is initialized
func getGameGrid() -> Variant:
	if game_state == null:
		return null
	else:
		return game_state.getGameGrid()
		

# This is ONLY for drawing the map and the units!!
# Only the game master should EVER modify the game state
## Returns the units in the game if the game state is initialized
func getUnits() -> Variant:
	if game_state == null:
		return null
	else:
		return game_state.getUnits()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
