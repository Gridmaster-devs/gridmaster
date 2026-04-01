extends Node

var client_peer = WebSocketMultiplayerPeer.new()



func connect_to_server(ip: String = "ws://127.0.0.1:55555") -> void:
	var err = client_peer.create_client(ip)
	if err == OK:
		multiplayer.multiplayer_peer = client_peer
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	else:
		print("Error connecting to server: ", err)

func _on_connected_to_server():
	Networking.request_game_file.rpc_id(Networking.SERVER_PEER_ID)

func send_turn_actions(actions: Array) -> void:
	# Send the turn actions to the server using an RPC call.
	print("Sending turn actions to server: ", actions)
	receive_turn_actions.rpc_id(Networking.SERVER_PEER_ID, actions)

@rpc("any_peer", "call_remote", "reliable")
func receive_turn_actions(actions: Array) -> void:
	# This function will be called on the server when it receives the turn actions from a client.
	# The server should process the actions and update the game state accordingly.
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		print("Received turn actions from peer %d: %s" % [peer_id, actions])
		turn_actions_received.emit(peer_id, actions)

## Server / client related definitions
# Server peer id, which is always 1 in Godot.
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#managing-connections
const SERVER_PEER_ID = 1

signal game_file_received(file_path: String)
signal game_file_requested(peer_id: int)
signal turn_actions_received(peer_id: int, actions: Array)

## RPC calls
# RPC call signatures need to be declared for both
# the client and the server.
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls

@rpc("any_peer", "call_remote", "reliable")
func request_game_file():
	if multiplayer.is_server():
		game_file_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_game_file(file_path: String):
	game_file_received.emit(file_path)