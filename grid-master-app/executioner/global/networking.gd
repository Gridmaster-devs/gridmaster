extends Node

var client_peer = WebSocketMultiplayerPeer.new()


## Client side callback functions
func connect_to_server(ip: String = "ws://127.0.0.1:8082") -> void:
	var err = client_peer.create_client(ip)
	if err == OK:
		multiplayer.multiplayer_peer = client_peer
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	else:
		print("Error connecting to server: ", err)

func _on_connected_to_server():
	# Don't request game file immediately - wait for team selection
	connected_to_server_signal.emit()
	# Request available teams from server
	request_teams.rpc_id(Networking.SERVER_PEER_ID)

func select_team(team_index: int) -> void:
	# Request the game file with the selected team
	request_game_file.rpc_id(Networking.SERVER_PEER_ID, team_index)

func send_turn_actions(actions: Array) -> void:
	# Send the turn actions to the server using an RPC call.
	print("Sending turn actions to server: ", actions)
	receive_turn_actions.rpc_id(Networking.SERVER_PEER_ID, actions)

## Server / client related definitions
# Server peer id, which is always 1 in Godot.
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#managing-connections
const SERVER_PEER_ID = 1

# Initial connection
signal connected_to_server_signal
# Game definition
signal game_file_received(file_path: String, team_index: int)
signal game_file_requested(peer_id: int, team_index: int)
signal turn_actions_received(peer_id: int, actions: Array)
signal teams_requested(peer_id: int)
signal teams_received(teams: Array)

# Game state
signal game_state_requested(peer_id: int)
signal game_state_received(state_update: Dictionary)

# Signals related to ending the turn
# Note that action_queue is typed as a Array instead of Array[PlayerAction]
# due to Godot having strict serialization limitations regarding custom object
# types. That's why we declare action_queue as generic Array (in this way
# Godot will implicitly handle the serialization).
signal request_peer_turn_end(peer_id: int, action_queue: Array)
signal turn_ended(state_update: Dictionary)

## RPC calls
# RPC call signatures need to be declared for both
# the client and the server.
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls

@rpc("any_peer", "call_remote", "reliable")
func request_teams():
	if multiplayer.is_server():
		teams_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_teams(teams: Array):
	teams_received.emit(teams)

@rpc("any_peer", "call_remote", "reliable")
func request_game_file(team_index: int = 0):
	if multiplayer.is_server():
		game_file_requested.emit(multiplayer.get_remote_sender_id(), team_index)

@rpc("authority", "call_remote", "reliable")
func receive_game_file(file_path: String, team_index: int):
	game_file_received.emit(file_path, team_index)

@rpc("any_peer", "call_remote", "reliable")
func request_game_state() -> void:
	if multiplayer.is_server():
		game_state_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_game_state(state_update: Dictionary) -> void:
	game_state_received.emit(state_update)

@rpc("any_peer", "call_remote", "reliable")
func end_peer_turn(action_queue: Array) -> void:
	if multiplayer.is_server():
		request_peer_turn_end.emit(multiplayer.get_remote_sender_id(), action_queue)

@rpc("authority", "call_remote", "reliable")
func end_turn(state_update: Dictionary) -> void:
	turn_ended.emit(state_update)

@rpc("any_peer", "call_remote", "reliable")
func receive_turn_actions(actions: Array) -> void:
	# This function will be called on the server when it receives the turn actions from a client.
	# The server should process the actions and update the game state accordingly.
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		print("Received turn actions from peer %d: %s" % [peer_id, actions])
		turn_actions_received.emit(peer_id, actions)
