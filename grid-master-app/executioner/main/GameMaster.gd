class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

var game_state : GameState ## The state of the game
@onready var user_interface : UserInterface = $"User Interface"

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


## Initializes a game state from a game definition
func initGameStateFromGameDefinition(game_definition : GameDefinitionResource):
	game_state = GameState.initFromGameDefinition(game_definition)


## Called by the user interface when the player has selected a game definition file and hit the load button
func playerSelectedGameDefinition(game_definition : GameDefinitionResource):
	initGameStateFromGameDefinition(game_definition)


# DEBUG ONLY!!
## Creates a debug game for testing
func debugInitGame() -> void:
	initGame(10, 10, "Test game")
	

## Prints the map into console
func printMap() -> void:
	if (game_state != null):
		game_state.printMap()
		

## Prints all the unit types into the console
func printUnitTypes() -> void:
	if (game_state != null):
		game_state.printUnitTypes()
		

## Prints all of the tile types into the console
func printTileTypes() -> void:
	if (game_state != null):
		game_state.printTileTypes()


## Creates a debug game, places some units, and prints the map
func debugTest():
	debugInitGame()
	game_state.createDebugUnit(Vector2i(0,0))
	game_state.createDebugUnit(Vector2i(5,5))
	printMap()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	user_interface.linkGameMaster(self)
	user_interface.openLoadGameDialog()
