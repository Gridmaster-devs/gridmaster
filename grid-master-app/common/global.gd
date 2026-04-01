extends Node

## Universal variables used in editors and executioner
const tile_width = 64
const tile_height = 64

const unit_width = 32
const unit_height = 32

enum GameType {SINGLEPLAYER, MULTIPLAYER}
var game_type = null

##popup manager
var popup_manager: PopupManager = null

## Server / client related definitions
# Server peer id, which is always 1 in Godot.
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#managing-connections
const SERVER_PEER_ID = 1

signal game_file_requested(peer_id: int)
signal game_file_received(file_path: String)

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
func request_game_file() -> void:
	if multiplayer.is_server():
		game_file_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_game_file(file_path: String) -> void:
	game_file_received.emit(file_path)

@rpc("any_peer", "call_remote", "reliable")
func request_game_state() -> void:
	if multiplayer.is_server():
		game_state_requested.emit(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func receive_game_state(state_update: Dictionary) -> void:
	game_state_received.emit(state_update)

@rpc("any_peer", "call_remote", "reliable")
func end_peer_turn(peer_id: int, action_queue: Array) -> void:
	if multiplayer.is_server():
		request_peer_turn_end.emit(multiplayer.get_remote_sender_id(), action_queue)

@rpc("authority", "call_remote", "reliable")
func end_turn(state_update: Dictionary) -> void:
	turn_ended.emit(state_update)
