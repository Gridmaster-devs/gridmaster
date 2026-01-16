class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

var game_state : GameState

# TODO: this should take the game definition as a parameter and initialize the game from that
# it will still need the players, however
## Initializes a game
func initGame(map_width : int, map_height : int, game_name : String):
	game_state = GameState.debugInit(map_width, map_height, game_name)
	

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
		

# DEBUG ONLY!!
## Creates a debug unit for testing
func createDebugUnit(position : Vector2i) -> void:
	if game_state != null:
		game_state.createDebugUnit(position)


# DEBUG ONLY!!
## Creates a debug game for testing
func debugInitGame() -> void:
	initGame(10, 10, "Test game")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
