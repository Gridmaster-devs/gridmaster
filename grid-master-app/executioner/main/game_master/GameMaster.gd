class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

signal units_changed

# NOTE: The ui states could also be represented as instances of a UI state class
# where each subclass has a reference to the gamestate and handles the given input differently.
# This might end up being a lot cleaner as the amount of possible UI states expands, and might
# be needed to prevent the game master file being enormous.
enum UIState {LOAD_GAME, SERVER_BROWSER, TEAM_SELECT, IN_GAME_DEFAULT, UNIT_MOVE}

const LOAD_GAME_GUI : PackedScene = preload("res://executioner/main/game_master/gui_scenes/load_game_gui.tscn")
const SERVER_BROWSER_GUI : PackedScene = preload("res://executioner/main/game_master/gui_scenes/server_browser_gui.tscn")
const TEAM_SELECT_GUI : PackedScene = preload("res://executioner/main/game_master/gui_scenes/team_select_gui.tscn")
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

var data_manager: GameDataManager

var _pathfinder : DijkstraPathfinder ## The pathfinder for the game state

# Variables for the unit movement state
var moved_unit : Unit # Which unit is being moved
var movement_waypoints : Array[Vector2i] = [] # The user-defined waypoints for the path
var current_possible_tiles : Array[Vector2i] = [] # Which tiles the unit can move to right now
var current_path : Array[Vector2i] = [] # The cumulative path of the unit
var movement_left : int # How many points of movement the unit still has left


# ---
# INFO OVERRIDDEN GODOT ENGINE VIRTUAL METHODS
# ---

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	units_changed.connect(grid_graphics._unitsChanged)
	_click_tracker.clicked.connect(_clicked)
	_custom_graphics = grid_graphics.get_custom_graphics()
	ftm.resource_uploaded.connect(local_init_game)
	## Network functionality
	# TODO: If this causes issues, separate network vs. local signals
	Networking.connected_to_server_signal.connect(_on_connected_to_server)
	Networking.teams_received.connect(_on_teams_received)
	Networking.game_file_received.connect(_on_game_file_received)
	Networking.turn_ended.connect(_on_turn_ended)
	Networking.game_state_received.connect(_on_game_state_received)
	Networking.connected_for_upload_signal.connect(_on_connected_for_upload)
	Networking.game_upload_result_received.connect(_on_game_upload_result)
	switch_gui_scene(LOAD_GAME_GUI, null)

# ---
# INFO LOCAL (TO THIS CLIENT) METHODS
# ---

# TODO Make initial execution path clearer (e.g. who the heck calls this?)
## Initializes the data  when a [GameDefinitionResource] is available
func initGameDataFromGameDefinition(game_definition_resource : GameDefinitionResource) -> void:
	
	#Initialize state
	data_manager = GameDataManager.initFromGameDefinition(game_definition_resource)
	
	#Initialize pathfinder
	_pathfinder = DijkstraPathfinder.new(data_manager)
	
	# TODO: Add import from game definition (edit: INFO what does this mean??)
	GameArgs.initialize(data_manager, game_definition_resource.game_rules)

## Called by FTM when a game is loaded locally
func local_init_game(game_definition_resource: GameDefinitionResource):
	assert(game_definition_resource != null, "Invalid game definition in file!")
	initGameDataFromGameDefinition(game_definition_resource)
	
	switch_gui_scene(IN_GAME_DEFAULT_GUI, data_manager.get_game_name())
	ui_state = UIState.IN_GAME_DEFAULT
	
	initGraphics()
	
	MessageDispatcher.broadcast_message("Game \"%s\" loaded." % data_manager.get_game_name())


## Ends the turn and processes all the actions that have been queued up.
## Unit actions are processed before other actions.
## NOTE This method increments the game state by directly mutating game state. Contrast with [method GameMaster.process_end_turn_local_factory]
func process_end_turn_local() -> void:
	
	var unit_array = data_manager.get_units().values()
	var sort_func : Callable = GameArgs.args.get(GameArgs.ArgType.UNIT_INITIATIVE_FUNC)
	sort_func.call(unit_array)
	
	# Looping through the move actions until every unit has stopped
	# (reached their destination, or gotten stopped by a fight or something else)
	var done = false
	while(done == false):
		done = true
		
		# Advance one step in each MoveAction
		for unit : Unit in unit_array:
			if (unit.current_action is MoveAction and unit.has_stopped() == false):
				done = false
				(unit.current_action as MoveAction).step()
		
		var units_to_be_removed : Array[Unit] = []
		
		# If any units have died we remove them from the array
		# We can't erase units while iterating over the array or it will break
		for unit : Unit in unit_array:
			if (unit.is_dead()):
				units_to_be_removed.append(unit)
		
		# NOTE: Possible to improve efficiency by using indices of the units in the
		# unit array so that it doesn't have to search for the position each time
		for unit in units_to_be_removed:
			unit_array.erase(unit)
			data_manager.remove_unit(unit)
	
	# Clear actions
	for unit : Unit in unit_array:
		unit.current_action = null
		
	
	data_manager.increment_turn_number()

## Ends the turn and processes all the actions that have been queued up.
## Unit actions are processed before other actions.
## NOTE This method does not increment the game state on its own, but returns a new gamestate that can be mounted. Contrast with [method GameMaster.process_end_turn_local]
## INFO Essentially a proof of concept that game_state is now a completely portable object that can be mounted at will
func process_end_turn_local_builder() -> GameState:
	var new_game_state = data_manager.get_game_state().deep_copy()
	
	# Have to mount new game state here because actions rely on it right now
	data_manager.replace_game_state(new_game_state)
	
	var unit_array = new_game_state._units.values()
	var sort_func : Callable = GameArgs.args.get(GameArgs.ArgType.UNIT_INITIATIVE_FUNC)
	sort_func.call(unit_array)
	
	# Looping through the move actions until every unit has stopped
	# (reached their destination, or gotten stopped by a fight or something else)
	var done = false
	while(done == false):
		done = true
		
		# Advance one step in each MoveAction
		for unit : Unit in unit_array:
			if (unit.current_action is MoveAction and unit.has_stopped() == false):
				done = false
				(unit.current_action as MoveAction).step()
		
		var units_to_be_removed : Array[Unit] = []
		
		# If any units have died we remove them from the array
		# We can't erase units while iterating over the array or it will break
		for unit : Unit in unit_array:
			if (unit.is_dead()):
				units_to_be_removed.append(unit)
		
		# NOTE: Possible to improve efficiency by using indices of the units in the
		# unit array so that it doesn't have to search for the position each time
		for unit in units_to_be_removed:
			unit_array.erase(unit)
			new_game_state.remove_unit(unit)
	
	# Clear actions
	for unit : Unit in unit_array:
		unit.current_action = null


	new_game_state.increment_turn_number()
	
	return new_game_state

## Initializes the user interface and graphics elements at the start of the game
func initGraphics() -> void:
	grid_graphics.initFromGameGrid(data_manager.get_grid(), data_manager)


## Opens the load game dialog
func load_game_from_file() -> void:
	ftm.upload_data("*.tres", true)


func end_turn_local() -> void:
	_custom_graphics.clear()
	#process_end_turn_local()
	data_manager.replace_game_state(process_end_turn_local_builder())
	units_changed.emit()

func end_turn() -> void:
	if Global.game_type == Global.GameType.SINGLEPLAYER:
		end_turn_local()
	elif Global.game_type == Global.GameType.MULTIPLAYER:
		end_network_game_turn()
	else:
		GML.log("Unknown game type (%s)!" % Global.game_type, GML.LogLevel.FATAL)

# ---
# INFO MULTIPLAYER METHODS
# ---

var client_peer = WebSocketMultiplayerPeer.new()

func _set_load_game_status(text: String):
	if gui_scene is LoadGameGUI:
		gui_scene.set_connection_status(text)

func connect_to_server():
	_set_load_game_status("Attempting to connect to server...")
	# FIXME: Hardcoded server IP address and port
	var err = client_peer.create_client("ws://127.0.0.1:55555")
	if err == OK:
		multiplayer.multiplayer_peer = client_peer
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	else:
		_set_load_game_status("Failed to create client peer. Error code: %d" % err)

func _on_connected_to_server():
	_set_load_game_status("Successfully connected to the server!")
	_set_load_game_status("Loading game..")
	switch_gui_scene(TEAM_SELECT_GUI, null)
	ui_state = UIState.TEAM_SELECT

func _on_connection_failed():
	_set_load_game_status("Connection to the server failed.")

func _on_server_disconnected():
	_set_load_game_status("Disconnected from the server.")


func _on_game_file_received(file_path: String, team_id: int):
	print("Received game file from server: %s, team_id: %d" % [file_path, team_id])
	var game_definition_resource = load(file_path)
	if game_definition_resource != null:
		initGameDataFromGameDefinition(game_definition_resource)
		# Set the client player ID based on team selection
		for player in data_manager.get_players().values():
			if player.team != null and player.team.team_id == team_id:
				data_manager.get_client_attributes().client_player_id = player.player_id
				print("Set client_player_id to %d (team %d)" % [player.player_id, team_id])
				break
		switch_gui_scene(IN_GAME_DEFAULT_GUI, data_manager.get_game_name())
		ui_state = UIState.IN_GAME_DEFAULT
		initGraphics()
		MessageDispatcher.broadcast_message("Game \"%s\" loaded." % data_manager.get_game_name())
	else:
		if gui_scene is TeamSelectGUI:
			gui_scene.set_status("Failed to load game file!")

func _on_teams_received(teams: Array):
	print("Received teams from server: ", teams)
	if gui_scene is TeamSelectGUI:
		gui_scene.populate_teams(teams)

func _on_game_state_received(state_update: Dictionary):
	_apply_state_update(state_update)
	switch_gui_scene(IN_GAME_DEFAULT_GUI, data_manager.get_game_name())
	
func end_network_game_turn() -> void:
	_custom_graphics.clear()

	# Compile locally assigned actions into the queue for server to process
	var outgoing_actions: Array = []
	for unit in data_manager.get_units().values():
		if unit.get_player_id() == data_manager.get_client_player_id() and unit.current_action != null:
			var action = unit.current_action
			if action is MoveAction:
				outgoing_actions.append({
					"type": "MoveAction",
					"path": action.path,
					"player_id": action.player_id,
					"unit_id": action.unit.getId()
				})
			# TODO: Implement other actions as well in addition to the MoveAction..

	print("[Client] Packing end_turn actions. Checked %d units. Found %d valid actions for player %d." % [data_manager.get_units().size(), outgoing_actions.size(), data_manager.get_client_player_id()])

	Networking.end_peer_turn.rpc_id(Networking.SERVER_PEER_ID, outgoing_actions)

	print("[Client] Turn ended, waiting for server...")

func _on_turn_ended(state_update: Dictionary):
	_apply_state_update(state_update)

func _apply_state_update(state_update: Dictionary) -> void:
	# Create units from the dictionary
	if data_manager != null:
		data_manager.increment_turn_number()

		var alive_unit_ids = []
		for u_state in state_update["units"]:
			alive_unit_ids.append(u_state["id"])

		var dead_units = []
		for unit in data_manager.get_units().values():
			if not alive_unit_ids.has(unit.getId()):
				dead_units.append(unit)

		for unit in dead_units:
			data_manager.remove_unit(unit)

		for u_state in state_update["units"]:
			var unit_id = u_state["id"]
			var unit = data_manager.get_unit_by_id(unit_id)
			if unit != null:
				if unit.grid_position != u_state["position"]:
					data_manager.move_unit(unit.getId(), u_state["position"])
				if u_state.has("hp"):
					unit._hp = u_state["hp"]
				unit.current_action = null

		units_changed.emit()
		# NOTE: most likely redundant call. Left since there is small possibility
		#		that some functions might change it in between calls to this function?
		ui_state = UIState.IN_GAME_DEFAULT

# ---
# INFO STATE MACHINE FUNCTIONS
# ---

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
		
		UIState.SERVER_BROWSER:
			_handle_event_server_browser(event)
		
		UIState.TEAM_SELECT:
			_handle_event_team_select(event)
		
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
		elif button_press.button_type == ButtonPressedEvent.ButtonType.CONNECT_TO_SERVER:
			switch_gui_scene(SERVER_BROWSER_GUI, null)
			ui_state = UIState.SERVER_BROWSER


## Handles input when in the server browser screen
func _handle_event_server_browser(event : StateMachineEvent):
	if event is ButtonPressedEvent:
		var button_press := event as ButtonPressedEvent
		if button_press.button_type == ButtonPressedEvent.ButtonType.BACK:
			switch_gui_scene(LOAD_GAME_GUI, null)
			ui_state = UIState.LOAD_GAME
		elif button_press.button_type == ButtonPressedEvent.ButtonType.PLAY_ON_SERVER:
			var ip := button_press.additional_args as String
			if gui_scene is ServerBrowserGUI:
				gui_scene.set_status("Connecting...")
			Networking.connect_to_server(ip)
		elif button_press.button_type == ButtonPressedEvent.ButtonType.UPLOAD_GAME:
			_pending_upload_ip = button_press.additional_args as String
			if gui_scene is ServerBrowserGUI:
				gui_scene.set_status("Select game file to upload...")
			# Temporarily disconnect local_init_game so selecting the upload
			# file doesn't start the game locally.
			ftm.resource_uploaded.disconnect(local_init_game)
			ftm.file_upload_cancelled.connect(_on_upload_cancelled, CONNECT_ONE_SHOT)
			ftm.resource_uploaded.connect(_on_upload_file_selected, CONNECT_ONE_SHOT)
			ftm.upload_data("*.tres", true)


var _pending_upload_ip: String = ""
var _pending_upload_resource: Resource = null


func _on_upload_cancelled() -> void:
	# User dismissed the file picker without selecting — restore normal load flow.
	if not ftm.resource_uploaded.is_connected(local_init_game):
		ftm.resource_uploaded.connect(local_init_game)
	if ftm.resource_uploaded.is_connected(_on_upload_file_selected):
		ftm.resource_uploaded.disconnect(_on_upload_file_selected)


func _on_upload_file_selected(resource: Resource) -> void:
	_pending_upload_resource = resource
	GML.log("Upload file selected, connecting to: %s" % _pending_upload_ip, GML.LogLevel.DEBUG)
	if gui_scene is ServerBrowserGUI:
		gui_scene.set_status("Connecting to server...")
	Networking.connect_for_upload(_pending_upload_ip)


func _on_connected_for_upload() -> void:
	GML.log("Connected for upload, sending file.", GML.LogLevel.DEBUG)
	if _pending_upload_resource == null:
		GML.log("No pending upload resource, aborting.", GML.LogLevel.ERROR)
		return
	if gui_scene is ServerBrowserGUI:
		gui_scene.set_status("Uploading game file...")
	const TEMP_PATH := "user://upload_temp.tres"
	ResourceSaver.save(_pending_upload_resource, TEMP_PATH)
	var file_data := FileAccess.get_file_as_bytes(TEMP_PATH)
	GML.log("Sending %d bytes to server." % file_data.size(), GML.LogLevel.DEBUG)
	Networking.upload_game_file.rpc_id(Networking.SERVER_PEER_ID, file_data)
	_pending_upload_resource = null


func _on_game_upload_result(success: bool) -> void:
	GML.log("Upload result received: %s" % ("success" if success else "failure"), GML.LogLevel.DEBUG)
	if gui_scene is ServerBrowserGUI:
		gui_scene.set_status("Upload successful! Refreshing..." if success else "Upload failed.")
	Networking._uploading = false
	multiplayer.multiplayer_peer = null
	# Close the upload socket and replace client_peer with a fresh object so
	# any subsequent connect_to_server / connect_for_upload starts clean.
	Networking.client_peer.close()
	Networking.client_peer = WebSocketMultiplayerPeer.new()
	# Restore local game-loading signal now that upload is complete.
	if not ftm.resource_uploaded.is_connected(local_init_game):
		ftm.resource_uploaded.connect(local_init_game)
	if success:
		# Wait one frame for the socket close to flush before reloading the browser.
		await get_tree().process_frame
		GML.log("Reloading server browser after upload.", GML.LogLevel.DEBUG)
		switch_gui_scene(SERVER_BROWSER_GUI, null)
		ui_state = UIState.SERVER_BROWSER


## Handles input when in the team selection screen
func _handle_event_team_select(event : StateMachineEvent):
	if event is ButtonPressedEvent:
		var button_press := event as ButtonPressedEvent
		if button_press.button_type == ButtonPressedEvent.ButtonType.SELECT_TEAM:
			var team_index = button_press.additional_args as int
			Networking.select_team(team_index)


## Default handler for in-game
func _handle_event_default_in_game(event : StateMachineEvent):
	if event is GridTileClickedEvent:
		if event.mouse_button == MOUSE_BUTTON_LEFT: # User left clicked on the grid
			if event.grid_pos == Vector2i(-1, -1): return # The user clicked outside the map
			
			var unit = data_manager.get_unit_by_position_nullable(event.grid_pos)
			if unit == null: return # There is no unit on the tile
			
			
			# The unit doesn't belong to the current player
			if unit.get_player_id() != data_manager.get_client_attributes().client_player_id: return
			
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
				moved_unit.current_action = MoveAction.new(current_path, data_manager.get_client_attributes().client_player_id, moved_unit, data_manager)
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
			if not movement_waypoints.is_empty():
				moved_unit.current_action = MoveAction.new(current_path, data_manager.get_client_attributes().client_player_id, moved_unit, data_manager)
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


# ---
# INFO LOGGING METHODS
# ---

## Prints the map into a log file
func printMap() -> void:
	data_manager.get_game_state().printMap(true)


## Prints all the unit types into a log file
func printUnitTypes() -> void:
	data_manager.get_game_state().printUnitTypes(true)


## Prints all of the tile types into a log file console
func printTileTypes() -> void:
	data_manager.get_game_state().printTileTypes(true)

# TESTING FUNCTIONS BLOCK
# THESE FUNCTIONS ARE SOLELY FOR TESTING THE PROGRAM
# THEY ARE ALWAYS TEMPORARY AND MUST EVENTUALLY BE REMOVED

## Creates a default unit for testing
func DEBUG_create_default_unit(position : Vector2i) -> void:
	data_manager.get_game_state().createDebugUnit(position)
