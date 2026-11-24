class_name DeveloperConsoleRPC
extends Node
## Reliable messages on /root/Networking/DeveloperConsoleRPC.

signal spawn_requested(peer_id: int, request_id: int, type_name: String, x: int, y: int)
signal unit_spawned(snapshot: Dictionary)
signal _spawn_resolved(result: Dictionary)

const REVISION: int = 1
const SPAWN_TIMEOUT_SECONDS: float = 5.0

var _last_request_id: int = 0
var _pending_request_id: int = 0


func spawn(type_name: String, x: int, y: int) -> Dictionary:
	if _pending_request_id != 0:
		return DeveloperCommands.result("spawn_pending", "A spawn request is already pending.")
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server() \
			or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return DeveloperCommands.result("disconnected", "The server is disconnected.")

	_last_request_id += 1
	var request_id: int = _last_request_id
	_pending_request_id = request_id
	if rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, &"request_spawn", request_id, type_name, x, y) != OK:
		_pending_request_id = 0
		return DeveloperCommands.result("request_failed", "Could not send the spawn request.")
	var deadline_usec: int = Time.get_ticks_usec() + int(SPAWN_TIMEOUT_SECONDS * 1000000)
	_schedule_spawn_timeout(request_id, deadline_usec)
	return await _spawn_resolved


func cancel_pending_spawn(code: String, message: String) -> void:
	_resolve_spawn(_pending_request_id, DeveloperCommands.result(code, message))


@rpc("any_peer", "call_remote", "reliable")
func request_spawn(request_id: int, type_name: String, x: int, y: int) -> void:
	if multiplayer.is_server():
		spawn_requested.emit(multiplayer.get_remote_sender_id(), request_id, type_name, x, y)


@rpc("authority", "call_remote", "reliable")
func receive_spawn_reply(request_id: int, result: Dictionary) -> void:
	_resolve_spawn(request_id, result)


@rpc("authority", "call_remote", "reliable")
func receive_spawned_unit(snapshot: Dictionary) -> void:
	unit_spawned.emit(snapshot)


func _resolve_spawn(request_id: int, result: Dictionary) -> void:
	if request_id == 0 or request_id != _pending_request_id:
		return
	_pending_request_id = 0
	_spawn_resolved.emit(result)


func _schedule_spawn_timeout(request_id: int, deadline_usec: int) -> void:
	var remaining_usec: int = deadline_usec - Time.get_ticks_usec()
	if remaining_usec <= 0:
		_resolve_spawn(request_id, DeveloperCommands.result(
			"timeout", "The server did not reply within five seconds. Check units before retrying."))
		return
	get_tree().create_timer(remaining_usec / 1000000.0, true, false, true).timeout.connect(
		_on_spawn_timeout.bind(request_id, deadline_usec))


func _on_spawn_timeout(request_id: int, deadline_usec: int) -> void:
	if request_id == _pending_request_id:
		# A scene timer can count the portion of the frame before the request.
		_schedule_spawn_timeout(request_id, deadline_usec)
