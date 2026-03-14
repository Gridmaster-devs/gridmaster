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

const LOAD_GAME_GUI : PackedScene = preload("res://executioner/main/game_master/gui_scenes/load_game_gui.tscn")
const IN_GAME_DEFAULT_GUI : PackedScene = preload("res://executioner/main/game_master/gui_scenes/in_game_default_gui.tscn")

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
var _pathfinder : DijkstraPathfinder ## The pathfinder for the game state

# Variables for the unit movement state
var moved_unit : Unit # Which unit is being moved
var movement_waypoints : Array[Vector2i] = [] # The user-defined waypoints for the path
var current_possible_tiles : Array[Vector2i] = [] # Which tiles the unit can move to right now
var current_path : Array[Vector2i] = [] # The cumulative path of the unit
var movement_left : int # How many points of movement the unit still has left


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
	_pathfinder = game_state.get_pathfinder()
	
	# DEBUG
	game_state.add_team("blu team", Color.BLUE, [])
	game_state.add_team("red team", Color.RED, [])
	game_state.add_player("player1", 0, false)
	game_state.add_player("player2", 1, false)
	
	game_state.addUnitByTypeId(0, Vector2i(0,0), 0)
	game_state.addUnitByTypeId(0, Vector2i(0,1), 0)
	game_state.addUnitByTypeId(0, Vector2i(1,0), 1)
	game_state.addUnitByTypeId(0, Vector2i(1,1), 1)
	
	game_state.client_player_id = 0
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
	switch_gui_scene(IN_GAME_DEFAULT_GUI, getGameName())
	ui_state = UIState.IN_GAME_DEFAULT
	
	MessageDispatcher.broadcast_message("Game \"%s\" loaded." % game_state.getGameName()) 


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


func end_turn() -> void:
	_custom_graphics.clear()
	game_state.end_turn()
	units_changed.emit()



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
			_handle_event_unit_move(event)


## Handles input when in the load game screen
func _handle_event_load_game(event : StateMachineEvent):
	if event is ButtonPressedEvent:
		var button_press := event as ButtonPressedEvent
		if button_press.button_type == ButtonPressedEvent.ButtonType.LOAD_GAME:
			load_game_from_file()


## Default handler for in-game
func _handle_event_default_in_game(event : StateMachineEvent):
	if event is GridTileClickedEvent:
		if event.mouse_button == MOUSE_BUTTON_LEFT: # User left clicked on the grid
			if event.grid_pos == Vector2i(-1, -1): return # The user clicked outside the map
			
			var unit = game_state.get_unit_on_tile(event.grid_pos)
			if unit == null: return # There is no unit on the tile
			
			# The unit doesn't belong to the current player
			if unit.get_player_id() != game_state.client_player_id: return
			
			# The user clicked on a tile in the map limits and there is a unit on the tile
			
			moved_unit = unit
			moved_unit.current_action = null # clear the current action
			_custom_graphics.clear_id(moved_unit.getId())
			
			current_possible_tiles = _pathfinder.tiles_from_position(unit.getPosition(), unit.get_move_speed(), unit)
			movement_left = moved_unit.get_move_speed()
			
			_custom_graphics.draw_movement_tiles(current_possible_tiles, unit.getId())
			ui_state = UIState.UNIT_MOVE
	
	elif event is ButtonPressedEvent:
		if event.button_type == ButtonPressedEvent.ButtonType.END_TURN:
			end_turn()


## Handler for when the user has clicked on a unit and is moving it
func _handle_event_unit_move(event : StateMachineEvent) -> void:
	_custom_graphics.clear_id(moved_unit.getId())
	
	# User clicked on a tile
	if event is GridTileClickedEvent:
		# Right click cancels moving a unit
		if event.mouse_button == MOUSE_BUTTON_RIGHT:
			_exit_unit_move()
		
		# Left click cancels moving a unit if the user clicks outside
		# the possible tiles
		elif event.mouse_button == MOUSE_BUTTON_LEFT:
			
			# If the user clicks on the latest waypoint, accept the movement command
			if (!movement_waypoints.is_empty() and movement_waypoints.back() == event.grid_pos):
				moved_unit.current_action = MoveAction.new(current_path, game_state.get_client_player_id(), moved_unit, game_state)
				_exit_unit_move()
				return
			
			# If the user clicked outside of the possible tiles,
			# cancel movement
			var path = _pathfinder.get_path_to_pos(event.grid_pos)
			if path.is_empty():
				_exit_unit_move()
				return
				
			# The movement hasn't been accepted or cancelled, so the user has clicked
			# on a valid movement tile
			
			# If we don't have a current path yet
			if (current_path.is_empty()):
				path.reverse()
				current_path = path
				
			# If we do have a current path we need to remove the first element of the
			# new path to be added so we don't have duplicate tiles
			else:
				path.reverse()
				path.remove_at(0)
				current_path.append_array(path)
			
			movement_waypoints.append(event.grid_pos) # Add the clicked tile as a waypoint
			
			# Calculate how much movement the unit has left
			movement_left = movement_left - _pathfinder.movement_required_to_position(event.grid_pos)
			
			# Calculate the new valid movement tiles
			current_possible_tiles = _pathfinder.tiles_from_position(event.grid_pos, movement_left, moved_unit)
			
			
			_custom_graphics.draw_movement_path(current_path, moved_unit.getId())
			_custom_graphics.draw_waypoints(movement_waypoints, moved_unit.getId())
			_custom_graphics.draw_movement_tiles(current_possible_tiles, moved_unit.getId())
		
		
	elif event is MouseMovedToTileEvent:
		var path = _pathfinder.get_path_to_pos(event.new_pos)
		
		_custom_graphics.draw_waypoints(movement_waypoints, moved_unit.getId())
		_custom_graphics.draw_movement_tiles(current_possible_tiles, moved_unit.getId())
		_custom_graphics.draw_movement_path(current_path, moved_unit.getId())
		
		
		# If there is a path (i.e. the unit can path to the selected tile)
		if path.is_empty() == false:
			_custom_graphics.draw_movement_path(path, moved_unit.getId())
		
		# If there is no path (i.e. the unnit cannot path to the selected tile)
		else:
			pass
	
	
	elif event is ButtonPressedEvent:
		if event.button_type == ButtonPressedEvent.ButtonType.END_TURN:
			_exit_unit_move()
			end_turn()
		


func _exit_unit_move() -> void:
	_custom_graphics.clear_id(moved_unit.getId())
	
	# If the movement action was confirmed, draw the small path for the unit
	if (moved_unit.current_action is MoveAction):
		var action = moved_unit.current_action as MoveAction
		_custom_graphics.draw_movement_path_small(action.path, moved_unit.getId())
	
	# Clear movement parameters and change back to default state
	moved_unit = null
	movement_waypoints.clear()
	current_possible_tiles.clear()
	current_path = []
	movement_left = 0
	ui_state = UIState.IN_GAME_DEFAULT


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
	_click_tracker.clicked.connect(_clicked)
	_custom_graphics = grid_graphics.get_custom_graphics()
	ftm.resource_uploaded.connect(load_game_definition)
	switch_gui_scene(LOAD_GAME_GUI, null)
