class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

signal units_changed

# NOTE: The ui states could also be represented as instances of a UI state class
# where each subclass has a reference to the gamestate and handles the given input differently.
# This might end up being a lot cleaner as the amount of possible UI states expands, and might
# be needed to prevent the game master file being enormous.
enum UIState {LOAD_GAME, IN_GAME_DEFAULT, UNIT_MOVE}

const load_game_gui : PackedScene = preload("res://executioner/main/grid_graphics/gui_scenes/load_game_gui.tscn")
const in_game_default_gui : PackedScene = preload("res://executioner/main/grid_graphics/gui_scenes/in_game_default_gui.tscn")

static var GROUP_NAME : String = "GameMaster"
static var EVENT_INPUT_FUNC_NAME : String = "receive_ui_event"
const RAW_INPUT_FUNC_NAME : String = "receive_raw_input"

@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager
@onready var grid_graphics : GridGraphics = $"Grid Graphics"

var _custom_graphics : CustomGraphics
var _click_tracker := ClickTracker.new()
var ui_state : UIState = UIState.LOAD_GAME
var gui_scene : GUIScene

var game_state : GameState ## The state of the game

var moved_unit : Unit
var movement_waypoints : Array[Vector2i] = []
var current_possible_tiles : Array[Vector2i] = []


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


## Initializes the user interface and graphics elements at the start of the game
func initGraphics() -> void:
	grid_graphics.initFromGameGrid(getGameGrid())


## Opens the load game dialog
func load_game_from_file() -> void:
	ftm.upload_data("*.tres", true)


## Called by the FTM when file is loaded
func load_game_definition(game_definition : Resource):
	assert(game_definition != null, "Invalid game definition in file!")
	initGameStateFromGameDefinition(game_definition)
	switch_gui_scene(in_game_default_gui, getGameName())
	ui_state = UIState.IN_GAME_DEFAULT
	


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



# STATE MACHINE FUNCTIONS

## Receives input from the graphics element.
##
## Called by the graphics element or its children via a group.
## Calls the appropriate input handler based on the UI state.
func receive_ui_event(event : StateMachineEvent):
	
	if (event is MouseMovedToTileEvent):
		_custom_graphics.draw_tile_cursor(event.new_pos)
	
	match ui_state:
		UIState.LOAD_GAME:
			_handle_event_load_game(event)
		
		UIState.IN_GAME_DEFAULT:
			_handle_event_default_in_game(event)
		
		UIState.UNIT_MOVE:
			_handle_event_default_in_game(event)


func _handle_event_load_game(event : StateMachineEvent):
	if event is ButtonPressedEvent:
		var button_press := event as ButtonPressedEvent
		if button_press.button_type == ButtonPressedEvent.ButtonType.LOAD_GAME:
			load_game_from_file()


func _handle_event_default_in_game(event : StateMachineEvent):
	if event is GridTileClickedEvent:
		if event.grid_pos == Vector2i(-1, -1): return # The user clicked outside the map
		
		var unit = game_state.get_first_unit_on_tile(event.grid_pos)
		if unit == null: return # There is no unit on the tile
		
		moved_unit = unit
		movement_waypoints.clear()
		# TODO: Add graphics stuff here


func _handle_event_unit_move(event : StateMachineEvent):
	pass


## Switches the GUI scene to a new one and initializes it with the args.
##
## Frees the current GUI scene if there is one.
func switch_gui_scene(new_scene : PackedScene, args : Variant):
	if gui_scene != null:
		gui_scene.queue_free()
	gui_scene = new_scene.instantiate()
	self.add_child(gui_scene)
	gui_scene.initialize(args)


func _clicked(button : MouseButton):
	var tile_coords = grid_graphics.get_current_hovered_tile_coords()
	receive_ui_event(GridTileClickedEvent.new(button, tile_coords))


func receive_raw_input(event : InputEvent):
	if event is InputEventMouseButton:
		_click_tracker.handle_input(event)
	else:
		if event is InputEventMouseMotion:
			receive_ui_event(MouseMovedToTileEvent.new(grid_graphics.get_current_hovered_tile_coords()))


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



# GODOT PREDEFINED FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_graphics.linkGameMaster(self)
	_custom_graphics = grid_graphics.get_custom_graphics()
	ftm.resource_uploaded.connect(load_game_definition)
	switch_gui_scene(load_game_gui, null)
