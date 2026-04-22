extends Node

## Server peer id is always 1 in Godot multiplayer.
## https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#managing-connections
const SERVER_PEER_ID = 1

# Connection
signal connected_to_server_signal
signal connected_for_upload_signal
# Server info (used by server browser)
signal server_info_requested(peer_id: int)
signal server_info_received(game_name: String)
# Teams
signal teams_requested(peer_id: int)
signal teams_received(teams: Array)
# Game file
signal game_file_requested(peer_id: int, team_index: int)
signal game_file_received(file_data: PackedByteArray, team_index: int)
# Game upload
signal game_upload_requested(peer_id: int, file_data: PackedByteArray)
signal game_upload_result_received(success: bool)
# Game state
signal game_state_requested(peer_id: int)
signal game_state_received(state_update: Dictionary)
# Turn
signal turn_actions_received(peer_id: int, actions: Array)
signal request_peer_turn_end(peer_id: int, action_queue: Array)
signal turn_ended(state_update: Dictionary)

var client_peer := WebSocketMultiplayerPeer.new()
var _uploading := false


# ---
# Client methods
# ---

## Queries a server for its loaded game name.
## Returns the game name, or empty string if offline/unreachable.
func query_server_info(ip: String) -> String:
	var ping_peer := WebSocketMultiplayerPeer.new()
	if ping_peer.create_client(ip) != OK:
		return ""

	var saved_peer = multiplayer.multiplayer_peer
	multiplayer.multiplayer_peer = ping_peer

	var result := ["", false]
	var rpc_sent := false
	var handler := func(name: String) -> void:
		result[0] = name
		result[1] = true
	server_info_received.connect(handler, CONNECT_ONE_SHOT)

	for i in 50:  # 5s timeout
		ping_peer.poll()
		var conn_state := ping_peer.get_connection_status()
		if not rpc_sent and conn_state == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc_sent = true
			request_server_info.rpc_id(SERVER_PEER_ID)
		if result[1]:
			break
		await get_tree().create_timer(0.1).timeout

	if not result[1] and server_info_received.is_connected(handler):
		server_info_received.disconnect(handler)

	multiplayer.multiplayer_peer = saved_peer
	## Must explicitly close the ping peer after polling, otherwise the connection lingers and can cause issues with subsequent connections.
	ping_peer.close()
	return result[0]


## Client side callback functions
func connect_to_server(ip: String = "wss://gridmaster-server.calmmeadow-c81c2c38.northeurope.azurecontainerapps.io") -> void:
	# Increase inbound buffer so the large game file sent by the server can be received.
	client_peer.inbound_buffer_size = 10 * 1024 * 1024  # 10 MB
	var err = client_peer.create_client(ip)
	if err == OK:
		multiplayer.multiplayer_peer = client_peer
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	else:
		GML.log("Error connecting to server: %s" % err, GML.LogLevel.ERROR)


func _on_connected_to_server() -> void:
	if _uploading:
		GML.log("Connected to server (upload mode), skipping game flow.", GML.LogLevel.DEBUG)
		return
	GML.log("Connected to server, requesting teams.", GML.LogLevel.DEBUG)
	connected_to_server_signal.emit()
	request_teams.rpc_id(SERVER_PEER_ID)


## Connects to a server solely to upload a game file, without entering team selection.
## Uses the same explicit-polling approach as query_server_info so the signal fires reliably.
func connect_for_upload(ip: String) -> void:
	_uploading = true
	GML.log("Connecting for upload to: %s" % ip, GML.LogLevel.DEBUG)
	# Increase outbound buffer so 1MB+ game files can be sent in a single packet.
	client_peer.outbound_buffer_size = 10 * 1024 * 1024  # 10 MB
	client_peer.inbound_buffer_size = 1 * 1024 * 1024   # 1 MB (for receiving result)
	GML.log("Upload peer buffer sizes set to 10MB out / 1MB in.", GML.LogLevel.DEBUG)
	var err := client_peer.create_client(ip)
	if err != OK:
		_uploading = false
		GML.log("Error connecting to server for upload: %s" % err, GML.LogLevel.ERROR)
		return
	multiplayer.multiplayer_peer = client_peer
	for i in 50:  # 5 second timeout
		client_peer.poll()
		if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			GML.log("Upload connection established, emitting signal.", GML.LogLevel.DEBUG)
			connected_for_upload_signal.emit()
			# Poll a few extra times to begin flushing the outgoing RPC payload.
			for _flush in 5:
				client_peer.poll()
				await get_tree().create_timer(0.05).timeout
			return
		await get_tree().create_timer(0.1).timeout
	# Timed out without connecting
	_uploading = false
	GML.log("Upload connection timed out.", GML.LogLevel.ERROR)
	multiplayer.multiplayer_peer = null
	client_peer.close()
	client_peer = WebSocketMultiplayerPeer.new()


func select_team(team_index: int) -> void:
	request_game_file.rpc_id(SERVER_PEER_ID, team_index)


func send_turn_actions(actions: Array) -> void:
	receive_turn_actions.rpc_id(SERVER_PEER_ID, actions)


# ---
# RPC declarations (must be declared on both client and server)
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls
# ---

@rpc("any_peer", "call_remote", "reliable")
func request_server_info() -> void:
	if multiplayer.is_server():
		server_info_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_server_info(game_name: String) -> void:
	server_info_received.emit(game_name)

@rpc("any_peer", "call_remote", "reliable")
func request_teams() -> void:
	if multiplayer.is_server():
		teams_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_teams(teams: Array) -> void:
	teams_received.emit(teams)

@rpc("any_peer", "call_remote", "reliable")
func request_game_file(team_index: int = 0) -> void:
	if multiplayer.is_server():
		game_file_requested.emit(multiplayer.get_remote_sender_id(), team_index)

@rpc("authority", "call_remote", "reliable")
func receive_game_file(file_data: PackedByteArray, team_index: int) -> void:
	game_file_received.emit(file_data, team_index)

@rpc("any_peer", "call_remote", "reliable")
func upload_game_file(file_data: PackedByteArray) -> void:
	GML.log("upload_game_file RPC received: %d bytes, is_server=%s" % [file_data.size(), str(multiplayer.is_server())], GML.LogLevel.DEBUG)
	if multiplayer.is_server():
		game_upload_requested.emit(multiplayer.get_remote_sender_id(), file_data)

@rpc("authority", "call_remote", "reliable")
func receive_upload_result(success: bool) -> void:
	game_upload_result_received.emit(success)

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
	if multiplayer.is_server():
		turn_actions_received.emit(multiplayer.get_remote_sender_id(), actions)
