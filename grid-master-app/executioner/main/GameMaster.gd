class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

signal units_changed

var game_state : GameState ## The state of the game
@onready var user_interface : UserInterface = $"User Interface"
@onready var grid_graphics : GridGraphics = $"User Interface/GridGraphics"


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


## SOLELY FOR TESTING
## NEVER EVER USE IN ACTUAL PRODUCTION CODE
func createUnit(unit_type_id : int, position : Vector2i) -> void:
	if game_state != null:
		game_state.addUnitByTypeId(unit_type_id, position, -1)


## gets the game name
func getGameName() -> String:
	if game_state != null:
		return game_state.getGameName()
	else:
		return ""


## Initializes a game state from a game definition
func initGameStateFromGameDefinition(game_definition : GameDefinitionResource):
	game_state = GameState.initFromGameDefinition(game_definition)
	initGraphics()
	
	# DEBUG
	createUnit(0, Vector2i(0,0))
	printUnitTypes()
	printTileTypes()
	# DEBUG


## Called by the user interface when the player has selected a game definition file and hit the load button
func playerSelectedGameDefinition(game_definition : GameDefinitionResource):
	initGameStateFromGameDefinition(game_definition)


# DEBUG ONLY!!
## Creates a debug game for testing
func debugInitGame() -> void:
	game_state = GameState.debugInit(10, 10, "Test game")


## Initializes the graphics elements at the start of the game
func initGraphics() -> void:
	grid_graphics.linkGameMaster(self)
	grid_graphics.initFromGameGrid(getGameGrid())
	grid_graphics.getUnits()


## Prints the map into a log file
func printMap() -> void:
	if (game_state != null):
		game_state.printMap(true)


## Prints all the unit types into a log file
func printUnitTypes() -> void:
	if (game_state != null):
		game_state.printUnitTypes(true)


## Prints all of the tile types into the console
func printTileTypes() -> void:
	if (game_state != null):
		game_state.printTileTypes(true)


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
