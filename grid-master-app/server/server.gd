## This is the entrypoint for the game server
## Handles incoming WebSocket multiplayer connections and maintains the list of connected players.

extends Node

## Configurable server variables
const PORT = 55555

## The core game server instance
var server = WebSocketMultiplayerPeer.new()

## Game state
# TODO: Implement the game state saving + loading functionality
# 		For game state saving functionality, refer to:
#		https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
var game_state: GameState = null

## Dictionary that maps network peer IDs (int) to Player representations (Player.gd)
var players : Dictionary = {}

## Tracker for peers that have submitted their turn commands
var players_ended_turn: Array[int] = []

## Create and initialize the server object
func start_server():
	GML.log("Starting server..", GML.LogLevel.INFO)
	multiplayer.multiplayer_peer = null
	var err = server.create_server(PORT)
	if err != OK:
		GML.log("Failed to create the server instance. Error code: %d" % err, GML.LogLevel.ERROR)
	multiplayer.multiplayer_peer = server
	
	if game_state == null:
		var game_def = load("res://game_cats_dogs.tres") as GameDefinitionResource
		game_state = GameState.initFromGameDefinition(game_def)

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	Global.game_file_requested.connect(_on_game_file_requested)
	Global.game_state_requested.connect(_on_game_state_requested)
	Global.request_peer_turn_end.connect(_on_player_turn_end)
	start_server()

# TODO: In order to continue an existing game, we can just set the clients
#		to load the game file and then send the saved game state, which
#		will be most likely the easiest way to implement this feature.
func _on_game_file_requested(peer_id: int):
	GML.log("Peer %d requested game file. Sending..." % peer_id, GML.LogLevel.INFO)
	Global.receive_game_file.rpc_id(peer_id, "res://game_cats_dogs.tres")

func _on_game_state_requested(peer_id: int) -> void:
	GML.log("Peer %d requested the game state." % peer_id, GML.LogLevel.INFO)
	GML.log("Creating new gamestate from the game definition...", GML.LogLevel.INFO)
	if game_state == null:
		var game_def = load("res://game_cats_dogs.tres") as GameDefinitionResource
		game_state = GameState.initFromGameDefinition(game_def)

	if !game_state:
		GML.log("Failed to create the game state from the game definition.", GML.LogLevel.ERROR)
		GML.log("Closing peer connection with peer_id = %d" % peer_id, GML.LogLevel.ERROR)
		server.get_peer(peer_id).close()
	else:
		Global.receive_game_state.rpc_id(peer_id, _create_state_update_dict())

# Returns the dictionary that is used to update
# the game state within the client side.
func _create_state_update_dict() -> Dictionary:
	var units_state = []
	for unit in game_state.units.values():
		units_state.append({
			"id": unit.getId(),
			"position": unit.grid_position,
			"hp": unit.hp
		})
	return {
		"turn_number": game_state.turn_number,
		"units": units_state
	}

# End the player turn
# TODO: Refactor if needed, make sure that this actually works.
func _on_player_turn_end(peer_id: int, action_queue: Array) -> void:
	GML.log("Peer %d requested turn end with %d actions." % [peer_id, action_queue.size()], GML.LogLevel.INFO)
	if not players_ended_turn.has(peer_id):
		players_ended_turn.append(peer_id)
		GML.log("Validated turn end for peer %d. Players ended: %d/%d" % [peer_id, players_ended_turn.size(), players.size()], GML.LogLevel.INFO)

		if typeof(action_queue) == TYPE_ARRAY:
			for dict_action in action_queue:
				if typeof(dict_action) == TYPE_DICTIONARY and dict_action.get("path") != null and dict_action.get("unit_id") != null:
					var unit_id = dict_action.get("unit_id")
					var real_unit = game_state.get_unit_by_id(unit_id)
					var logical_p_id = dict_action.get("player_id", -1)

					GML.log("Action queued for unit_id: %d (player %d)" % [unit_id, logical_p_id], GML.LogLevel.INFO)

					# We use logical player_id because peer_id is Godot's networking ID
					if real_unit != null and real_unit.get_player_id() == logical_p_id:
						var path_raw = dict_action.get("path")
						var typed_path: Array[Vector2i] = []
						for p in path_raw:
							typed_path.append(p)

						GML.log("Resolving path %s for unit %d" % [typed_path, unit_id], GML.LogLevel.INFO)

						# Move the units
						real_unit.current_action = load("res://executioner/main/game_actions/unit_actions/MoveAction.gd").new(
							typed_path,
							logical_p_id,
							real_unit,
							game_state
						)
					elif real_unit == null:
						GML.log("Could not find unit with id %d" % unit_id, GML.LogLevel.ERROR)
					else:
						GML.log("Unit %d player_id %d does not match logical %d" % [unit_id, real_unit.get_player_id(), logical_p_id], GML.LogLevel.ERROR)

	# Process the turn only when all peers have submitted their actions
	if players_ended_turn.size() < players.size():
		GML.log("Still waiting for other players to end turn.", GML.LogLevel.INFO)
		return

	GML.log("All players have ended their turn. Processing actions...", GML.LogLevel.INFO)
	players_ended_turn.clear()

	var unit_array = game_state.units.values()
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
			game_state.remove_unit(unit)

	# Clear actions
	for unit : Unit in unit_array:
		unit.current_action = null

	game_state.turn_number += 1
	Global.end_turn.rpc(_create_state_update_dict())

## Called when a peer connects to the server
# FIXME: The player should be the one who sends the server their real
#		 player id within a join "handshake" process.
func _peer_connected(peer_id):
	GML.log("Connected %d" % peer_id, GML.LogLevel.INFO)
	var PlayerClass = load("res://executioner/main/game_master/Player.gd")
	var TeamClass = load("res://executioner/main/game_master/Team.gd")

	var empty_units: Array[UnitType] = []
	# TODO: Get the team ID by assigning the joining players a team that they can (must)
	#		choose from a list of options.
	var team = TeamClass.new("Test team", 1111, Color.PEACH_PUFF, empty_units)
	var new_player = PlayerClass.new("player %d" % peer_id, peer_id, team, false)

	players[peer_id] = new_player

## Called when a peer disconnects from the server
# TODO: When re-joining, give the players option to choose the player / team
#		(e.g. show team color and player name, so that they can recognize
#		who they were in the previous session. Other option is to use
#		persistent storage to save the player ID. E.g. something like:
#		https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Client-side_APIs/Client-side_storage
# 		but via Godot.
func _peer_disconnected(id):
	if players.has(id):
		players.erase(id)
	GML.log("Disconnected %d" % id, GML.LogLevel.INFO)
