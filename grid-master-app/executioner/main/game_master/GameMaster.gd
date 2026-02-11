class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

signal units_changed

var game_state : GameState ## The state of the game
@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager
@onready var grid_graphics : GridGraphics = $"Grid Graphics"
@onready var game_name_box : Label = $UIElements/GameName
@onready var load_game_button : Button = $UIElements/LoadGameButton


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


## gets the game name
func getGameName() -> String:
	if game_state != null:
		return game_state.getGameName()
	else:
		return ""


## Initializes a game state from a game definition
func initGameStateFromGameDefinition(game_definition : GameDefinitionResource):
	game_state = GameState.initFromGameDefinition(game_definition)
	
	# DEBUG
	DEBUG_create_unit(0, Vector2i(0,0))
	# DEBUG

	initGraphics()
	initUIElements()


func initUIElements() -> void:
	game_name_box.text = game_state.getGameName()


## Initializes the user interface and graphics elements at the start of the game
func initGraphics() -> void:
	grid_graphics.initFromGameGrid(getGameGrid())


## Opens the load game dialog
func load_game_from_file() -> void:
	ftm.upload_data("*.tres", true)


## Called by the load game dialog
func load_game_definition(game_definition : Resource):
	assert(game_definition != null, "Invalid game definition in file!")
	initGameStateFromGameDefinition(game_definition)


## Prints the map into a log file
func printMap() -> void:
	if (game_state != null):
		game_state.printMap(true)


## Prints all the unit types into a log file
func printUnitTypes() -> void:
	if (game_state != null):
		game_state.printUnitTypes(true)


## Prints all of the tile types into a log file console
func printTileTypes() -> void:
	if (game_state != null):
		game_state.printTileTypes(true)


# TESTING FUNCTIONS BLOCK
# THESE FUNCTIONS ARE SOLELY FOR TESTING THE PROGRAM
# THEY ARE ALWAYS TEMPORARY AND MUST EVENTUALLY BE REMOVED

## Creates a debug game for testing
func DEBUG_init_game() -> void:
	game_state = GameState.debugInit(10, 10, "Test game")


## Creates a debug game, places some units, and prints the map
func DEBUG_test():
	DEBUG_init_game()
	game_state.createDebugUnit(Vector2i(0,0))
	game_state.createDebugUnit(Vector2i(5,5))
	printMap()


## Creates a default unit for testing
func DEBUG_create_default_unit(position : Vector2i) -> void:
	if game_state != null:
		game_state.createDebugUnit(position)


## Creates a unit from a unit id for testing
func DEBUG_create_unit(unit_type_id : int, position : Vector2i) -> void:
	if game_state != null:
		game_state.addUnitByTypeId(unit_type_id, position, -1)

# TESTING FUNCTIONS BLOCK END


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_graphics.linkGameMaster(self)
	ftm.resource_uploaded.connect(load_game_definition)
	load_game_button.pressed.connect(load_game_from_file)
