## This is the entrypoint for the game server
## Handles incoming WebSocket multiplayer connections and maintains the list of connected clients.

extends Node



## Constants
const EXIT_FAILURE = 1

## Configurable server variables
const PORT = 443

## The file path to the game definition resource that the server uses always
const GAME_FILE_PATH = "user://game.tres"
## Persisted game state (survives server restarts)
const GAME_STATE_FILE_PATH = "user://game_state.json"

## The core game server instance
var server = WebSocketMultiplayerPeer.new()

## Server state object
var server_state: ServerState = null

## Dictionary that maps network peer IDs (int) to ClientInfo instances
var clients : Dictionary = {}

## Helpers
func exit(code: int) -> void:
	# TODO: Implement
	return

## Cached game definition for team info
#var game_definition : GameDefinitionResource = null
## Game state
# TODO: Implement the game state saving + loading functionality
# 		For game state saving functionality, refer to:
#		https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
#var game_state: GameState = null

## Turn tracking (TODO: This needs to be saved somewhere with the gamestate)
#var current_turn : int = 1
#var teams_ended_turn : Dictionary = {}  # team_index -> bool
#var turn_actions_by_team : Dictionary = {}  # team_index -> Array of actions

## Tracker for peers that have submitted their turn commands
# TODO: Remove this and use the team turns instead
var players_ended_turn: Array[int] = []

## Saves the current game state to disk as JSON.
func _save_game_state() -> void:
	if server_state == null:
		return
	var state: Dictionary = _create_state_update_dict()
	state["game_name"] = server_state.data_manager.get_game_name()
	state["message_log"] = server_state.get_message_log()
	# Vector2i doesn't serialize cleanly to JSON — convert to plain dicts.
	for u in state["units"]:
		u["position"] = {"x": u["position"].x, "y": u["position"].y}
	var file: FileAccess = FileAccess.open(GAME_STATE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		GML.log("Failed to save game state: %s" % FileAccess.get_open_error(), GML.LogLevel.ERROR)
		return
	file.store_string(JSON.stringify(state))
	file.close()
	GML.log("Game state saved (turn %d, %d units)." % [state["turn_number"], state["units"].size()], GML.LogLevel.DEBUG)

## Loads and applies a saved state from disk.
## Silently skips if no file exists or the game name does not match.
func _restore_saved_state() -> void:
	if not FileAccess.file_exists(GAME_STATE_FILE_PATH):
		GML.log("No saved game state found, starting fresh.", GML.LogLevel.INFO)
		return
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(GAME_STATE_FILE_PATH)) != OK:
		GML.log("Failed to parse saved game state.", GML.LogLevel.WARN)
		return
	var data: Dictionary = json.get_data()
	var saved_name: String = data.get("game_name", "")
	var current_name: String = server_state.data_manager.get_game_name()
	if saved_name != current_name:
		GML.log("Saved state is for '%s', current game is '%s'. Ignoring." % [saved_name, current_name], GML.LogLevel.WARN)
		return
	var dm: GameDataManager = server_state.data_manager
	# Apply turn number
	dm.set_turn_number(int(data.get("turn_number", 0)))
	# Build a set of alive unit IDs from the saved state
	var saved_ids: Dictionary = {}
	for u in data.get("units", []):
		saved_ids[int(u["id"])] = u
	# Remove units not present in the saved state (died in a previous session)
	var to_remove: Array[Unit] = []
	for unit in dm.get_units().values():
		if not saved_ids.has(unit.getId()):
			to_remove.append(unit)
	for unit in to_remove:
		dm.remove_unit(unit)
	# Apply position and HP for surviving units
	for id in saved_ids:
		var unit = dm.get_unit_by_id(id)
		if unit == null:
			GML.log("Saved state references unit %d which does not exist in the game definition. Skipping." % id, GML.LogLevel.WARN)
			continue
		var u_data: Dictionary = saved_ids[id]
		var pos: Vector2i = Vector2i(int(u_data["position"]["x"]), int(u_data["position"]["y"]))
		dm.move_unit(id, pos)
		unit._hp = int(u_data["hp"])
	# Restore message log
	for msg in data.get("message_log", []):
		server_state._message_log.push_back(msg)
	GML.log("Game state restored: turn %d, %d units, %d messages." % [dm.get_turn_number(), dm.get_units().size(), server_state._message_log.size()], GML.LogLevel.INFO)

## Create and initialize the server object
func start_server():
	GML.log("Starting server..", GML.LogLevel.INFO)
	multiplayer.multiplayer_peer = null
	# Increase buffers to handle large game file transfers (default is 65536 = 64KB)
	server.inbound_buffer_size = 10 * 1024 * 1024   # 10 MB — for receiving uploads
	server.outbound_buffer_size = 10 * 1024 * 1024  # 10 MB — for sending game file to clients
	var err = server.create_server(PORT)
	if err != OK:
		GML.log("Failed to create the server instance. Error code: %d" % err, GML.LogLevel.FATAL)
		exit(EXIT_FAILURE)
	multiplayer.multiplayer_peer = server

	# Ensure user:// directory exists (may be absent on first Docker run).
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())

	# If a game file was persisted from a previous run, resume it automatically.
	if FileAccess.file_exists(GAME_FILE_PATH):
		var game_def: GameDefinitionResource = ResourceLoader.load(GAME_FILE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GameDefinitionResource
		if game_def != null:
			server_state = ServerState.new(game_def)
			GameArgs.initialize(server_state.data_manager, game_def.game_rules)
			_restore_saved_state()
			GML.log("Resumed game: '%s' at turn %d." % [game_def.game_name, server_state.data_manager.get_turn_number()], GML.LogLevel.INFO)
		else:
			GML.log("Found %s but failed to load it. Waiting for upload." % GAME_FILE_PATH, GML.LogLevel.WARN)
	else:
		GML.log("Server started. Upload a game file to begin.", GML.LogLevel.INFO)

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	# TODO: Handle this correctly with the new changes
	Networking.teams_requested.connect(_on_teams_requested)
	Networking.game_file_requested.connect(_on_game_file_requested)
	Networking.game_state_requested.connect(_on_game_state_requested)
	Networking.request_peer_turn_end.connect(_on_team_turn_end)

	Networking.game_upload_requested.connect(_on_game_upload_requested)

	# Connect message dispatcher to local callback that collects all
	# event messages that are sent to all players when the turn ends.
	MessageDispatcher.message_broadcast.connect(_on_message_broadcast)
	start_server()

func _on_game_upload_requested(peer_id: int, file_data: PackedByteArray) -> void:
	GML.log("[Upload] Signal received from peer %d, %d bytes" % [peer_id, file_data.size()], GML.LogLevel.INFO)
	if file_data.is_empty():
		GML.log("[Upload] Received empty file data from peer %d. Rejecting." % peer_id, GML.LogLevel.ERROR)
		Networking.receive_upload_result.rpc_id(peer_id, false)
		return
	GML.log("[Upload] Writing to: %s" % ProjectSettings.globalize_path(GAME_FILE_PATH), GML.LogLevel.DEBUG)
	var file: FileAccess = FileAccess.open(GAME_FILE_PATH, FileAccess.WRITE)
	if file == null:
		GML.log("[Upload] Failed to open game file path for writing. Error: %s" % FileAccess.get_open_error(), GML.LogLevel.ERROR)
		Networking.receive_upload_result.rpc_id(peer_id, false)
		return
	file.store_buffer(file_data)
	file.close()
	var written: PackedByteArray = FileAccess.get_file_as_bytes(GAME_FILE_PATH)
	if written.size() != file_data.size():
		GML.log("[Upload] Size mismatch after write: expected %d bytes, got %d bytes." % [file_data.size(), written.size()], GML.LogLevel.ERROR)
		Networking.receive_upload_result.rpc_id(peer_id, false)
		return
	GML.log("[Upload] File verified on disk (%d bytes). Attempting to load as GameDefinitionResource." % written.size(), GML.LogLevel.DEBUG)
	# CACHE_MODE_IGNORE forces Godot to re-read from disk rather than returning
	# a cached resource from a prior load() of the same path.
	var game_def: GameDefinitionResource = ResourceLoader.load(GAME_FILE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GameDefinitionResource
	if game_def == null:
		GML.log("[Upload] Loaded resource is null or not a GameDefinitionResource.", GML.LogLevel.ERROR)
		Networking.receive_upload_result.rpc_id(peer_id, false)
		return
	GML.log("[Upload] GameDefinitionResource loaded: '%s'. Reinitializing server state." % game_def.game_name, GML.LogLevel.INFO)
	server_state = ServerState.new(game_def)
	GameArgs.initialize(server_state.data_manager, game_def.game_rules)
	# New upload = fresh game; remove any stale persisted state.
	if FileAccess.file_exists(GAME_STATE_FILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GAME_STATE_FILE_PATH))
	GML.log("[Upload] Game updated to: %s" % game_def.game_name, GML.LogLevel.INFO)
	Networking.receive_upload_result.rpc_id(peer_id, true)


func _on_message_broadcast(message: String) -> void:
	server_state.push_message(message)

# TODO: In order to continue an existing game, we can just set the clients
#		to load the game file and then send the saved game state, which
#		will be most likely the easiest way to implement this feature.
func _on_game_file_requested(peer_id: int, team_id: int):
	GML.log("Peer %d requested game file. Sending..." % peer_id, GML.LogLevel.INFO)
	if server_state == null:
		GML.log("Peer %d requested game file but no game is loaded yet." % peer_id, GML.LogLevel.WARN)
		return
	if server_state.clients.keys().has(peer_id) and server_state.clients[peer_id] == server_state.TEAM_ID_NOT_SELECTED:
		# TODO: Check that the given team_id exists.
		server_state.clients[peer_id] = team_id
		GML.log("Assigned peer %d to team %d" % [peer_id, team_id])
	else:
		GML.error(
			"Failed to assign the peer %d a team (%d). " + 
			"Client either not connected or is already part of a team." % [peer_id, team_id]
		)
		return

	var file_data: PackedByteArray = FileAccess.get_file_as_bytes(GAME_FILE_PATH)
	if file_data.is_empty():
		GML.log("Failed to read game file bytes from: %s" % GAME_FILE_PATH, GML.LogLevel.ERROR)
		return
	GML.log("Sending game file to peer %d (%d bytes)" % [peer_id, file_data.size()], GML.LogLevel.INFO)
	Networking.receive_game_file.rpc_id(peer_id, file_data, team_id)
	var rejoin_state: Dictionary = _create_state_update_dict()
	rejoin_state["message_log"] = server_state.get_message_log()
	rejoin_state["teams_ended_turn"] = server_state.teams_ended_turn.duplicate()
	Networking.receive_game_state.rpc_id(peer_id, rejoin_state)

func _on_teams_requested(peer_id: int):
	GML.log("Peer %d requested teams list" % peer_id, GML.LogLevel.INFO)
	if server_state == null:
		GML.log("Peer %d requested teams but no game is loaded yet." % peer_id, GML.LogLevel.WARN)
		return

	var teams_data: Array[Dictionary] = []
	for team_id in server_state.data_manager.get_teams().keys():
		var team: Team = server_state.data_manager.get_teams()[team_id]
		teams_data.append({
			"id": team_id,
			"name": team.team_name,
			"color": team.color.to_html(),
			"is_computer": team.is_computer
		})

	GML.log("Sending %d teams: %s" % [teams_data.size(), teams_data], GML.LogLevel.INFO)
	Networking.receive_teams.rpc_id(peer_id, teams_data)

func _on_game_state_requested(peer_id: int) -> void:
	GML.log("Peer %d requested the game state." % peer_id, GML.LogLevel.INFO)
	if !server_state.game_state:
		GML.log("Player requested game state which doesn't exist on server. Check whether initialization of the server failed.", GML.LogLevel.FATAL)
		exit(EXIT_FAILURE)
	else:
		Networking.receive_game_state.rpc_id(peer_id, _create_state_update_dict())

# Returns the dictionary that is used to update
# the game state within the client side.
func _create_state_update_dict() -> Dictionary:
	var units_state = []
	for unit in server_state.data_manager.get_units().values():
		units_state.append({
			"id": unit.getId(),
			"position": unit.grid_position,
			"hp": unit.hp
		})
	return {
		"turn_number": server_state.data_manager.get_turn_number(),
		"message_queue": server_state.get_message_queue(),
		"units": units_state
	}

# End the player turn
func _on_team_turn_end(peer_id: int, action_queue: Array) -> void:
	if !server_state.clients.keys().has(peer_id):
		GML.log("Unknown client tried to end turn. Rejecting.", GML.LogLevel.ERROR)
		return

	var player_team: Team = server_state.get_player_team_nullable(peer_id)
	if !player_team:
		GML.log("Player %d tried to end turn but isn't part of any team." % peer_id, GML.LogLevel.ERROR)
		return

	GML.log("Peer %d requested team '%s' turn end with %d actions." % [peer_id, player_team.team_name, action_queue.size()], GML.LogLevel.INFO)
	if !server_state.team_has_ended_turn(player_team.team_id):
		server_state.end_team_turn(player_team.team_id)
		GML.log("Validated turn end for peer team %s." % [player_team.team_name], GML.LogLevel.INFO)

		# Auto-submit any computer-controlled teams that haven't ended yet.
		for team in server_state.data_manager.get_teams().values():
			if team.is_computer and not server_state.team_has_ended_turn(team.team_id):
				_process_computer_team_actions(team)
				server_state.end_team_turn(team.team_id)
				GML.log("Auto-submitted turn for computer team '%s'." % team.team_name, GML.LogLevel.INFO)

		if typeof(action_queue) == TYPE_ARRAY:
			for dict_action in action_queue:
				if typeof(dict_action) == TYPE_DICTIONARY and dict_action.get("path") != null and dict_action.get("unit_id") != null:
					var unit_id = dict_action.get("unit_id")
					var real_unit = server_state.data_manager.get_unit_by_id(unit_id)
					#var logical_p_id = dict_action.get("player_id", -1)

					GML.log("Action queued for unit_id: %d (player %d)" % [unit_id, peer_id], GML.LogLevel.INFO)

					# Use team id instead of player id
					if real_unit != null and real_unit.get_team_id() == player_team.team_id:
						var path_raw = dict_action.get("path")
						var typed_path: Array[Vector2i] = []
						for p in path_raw:
							typed_path.append(p)

						GML.log("Resolving path %s for unit %d" % [typed_path, unit_id], GML.LogLevel.INFO)

						## Create actions for units.
						# MoveAction
						real_unit.current_action = MoveAction.new(
							typed_path,
							peer_id,  # Seems that this is not used, so shouldn't matter even if we move units as teams and not as players.
							real_unit,
							server_state.data_manager
						)
					elif !real_unit:
						GML.log("Could not find unit with id %d" % unit_id, GML.LogLevel.ERROR)
					else:
						GML.log("Unit %d does not match team_id %d" % [unit_id, player_team.team_id], GML.LogLevel.ERROR)
		else:
			GML.log("Team turn already have been ended.", GML.LogLevel.WARN)
			return

	# Process the turn only when all peers have submitted their actions
	if server_state.teams_ended() < server_state.total_teams():
		GML.log("%d/%d teams have ended their turn. Waiting for the rest to finish their turns." % [server_state.teams_ended(), server_state.total_teams()], GML.LogLevel.INFO)
		return

	GML.log("All players have ended their turn. Processing actions..", GML.LogLevel.INFO)
	
	# Clear the array of all the teams that have ended their turn
	server_state.clear_turns()
	
	## Finally execute all the actions
	var unit_array = server_state.data_manager.get_units().values()
	var sort_func : Callable = GameArgs.args.get(GameArgs.ArgType.UNIT_INITIATIVE_FUNC)
	sort_func.call(unit_array)
	
	# Looping through the move actions until every unit has stopped
	# (reached their destination, or gotten stopped by a fight or something else)
	var done = false
	while not done:
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
			server_state.data_manager.remove_unit(unit)

	## Clear turn related information and increment the turn number
	# Clear actions
	for unit : Unit in unit_array:
		unit.current_action = null
	server_state.data_manager.increment_turn_number()

	# Send the state update dict to all the clients.
	Networking.end_turn.rpc(_create_state_update_dict())

	# Persist state so it survives a server restart.
	_save_game_state()

	# Clear the action message queue
	server_state.clear_message_queue()

## Placeholder for computer-controlled team AI.
## Called once per computer team per turn before the turn is processed.
## [param team] is the Team object for the computer team whose turn is being submitted.
func _process_computer_team_actions(team: Team) -> void:
	GML.log("Computer team '%s' taking no action (AI not yet implemented)." % team.team_name, GML.LogLevel.INFO)

## Called when a peer connects to the server
func _peer_connected(peer_id):
	GML.log("Connected %d" % peer_id, GML.LogLevel.INFO)
	if server_state == null:
		GML.log("Peer %d connected but no game is loaded yet." % peer_id, GML.LogLevel.WARN)
		return
	server_state.join(peer_id)
	GML.log("Active clients: %d" % server_state.active_clients())

## Called when a peer disconnects from the server
# TODO: When re-joining, give the players option to choose the player / team
#		(e.g. show team color and player name, so that they can recognize
#		who they were in the previous session. Other option is to use
#		persistent storage to save the player ID. E.g. something like:
#		https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Client-side_APIs/Client-side_storage
# 		but via Godot.
func _peer_disconnected(id):
	GML.log("Disconnected %d" % id, GML.LogLevel.INFO)
	if server_state == null:
		return
	server_state.clients.erase(id)
	GML.log("Active clients: %d" % server_state.active_clients())
