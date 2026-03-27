extends Node

## Universal variables used in editors and executioner
const tile_width = 64
const tile_height = 64

const unit_width = 32
const unit_height = 32

##popup manager
var popup_manager: PopupManager = null

## Server / client related definitions
# Server peer id, which is always 1 in Godot.
# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#managing-connections
const SERVER_PEER_ID = 1

signal game_file_received(file_path: String)
signal game_file_requested(peer_id: int)

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
