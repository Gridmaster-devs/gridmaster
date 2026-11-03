## Headless client for smoke-testing a game server. It drives the real
## Networking autoload, so it exercises the same RPCs as the game client.
## local-multiplayer.sh --smoke runs it; it can also be run by hand from
## grid-master-app/:
##
##   Upload a game:  godot --headless --path . -s res://tools/multiplayer_smoke_client.gd -- --url=ws://127.0.0.1:8082 "--upload=/abs/path/game.tres"
##   Join and play:  godot --headless --path . -s res://tools/multiplayer_smoke_client.gd -- --url=ws://127.0.0.1:8082 --player=0
##
## A player joins the Nth non-neutral team, waits --end-turn-delay seconds so
## other players can join, ends its turn and exits 0 once the server finishes
## the turn. It prints "[smoke] turns: start=N end=M" so the launcher can check
## that all players shared the same turn. Any failure or a 30 s timeout exits 1.
extends SceneTree

const TIMEOUT_SECONDS := 30.0

var url := "ws://127.0.0.1:8082"
var upload_path := ""
var player_index := 0
var end_turn_delay := 3.0
var net: Node
var _finished := false
var _start_turn := -1


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--url="):
			url = arg.trim_prefix("--url=")
		elif arg.begins_with("--upload="):
			upload_path = arg.trim_prefix("--upload=")
		elif arg.begins_with("--player="):
			player_index = int(arg.trim_prefix("--player="))
		elif arg.begins_with("--end-turn-delay="):
			end_turn_delay = float(arg.trim_prefix("--end-turn-delay="))
	create_timer(TIMEOUT_SECONDS).timeout.connect(func(): _done(false, "timed out after %d s" % TIMEOUT_SECONDS))
	# Autoloads are added to the tree after _initialize, so wait a frame.
	await process_frame
	net = root.get_node_or_null("Networking")
	if net == null:
		_done(false, "Networking autoload not found; run with --path pointing at grid-master-app")
		return
	if upload_path != "":
		_start_upload()
	else:
		_start_player()


func _start_upload() -> void:
	if not FileAccess.file_exists(upload_path):
		_done(false, "game file not found: %s" % upload_path)
		return
	net.connected_for_upload_signal.connect(_send_upload)
	net.game_upload_result_received.connect(func(ok: bool): _done(ok, "server %s the upload" % ("accepted" if ok else "rejected")))
	net.connect_for_upload(url)


func _send_upload() -> void:
	var bytes := FileAccess.get_file_as_bytes(upload_path)
	_log("uploading %s (%d bytes)" % [upload_path.get_file(), bytes.size()])
	net.upload_game_file.rpc_id(net.SERVER_PEER_ID, bytes)


func _start_player() -> void:
	net.connected_to_server_signal.connect(func(): _log("connected to %s" % url))
	net.teams_received.connect(_on_teams_received)
	net.game_file_received.connect(_on_game_file_received)
	net.game_state_received.connect(func(state: Dictionary): _start_turn = int(state.get("turn_number", -1)))
	net.turn_ended.connect(_on_turn_ended)
	root.multiplayer.connection_failed.connect(func(): _done(false, "could not connect to %s" % url))
	root.multiplayer.server_disconnected.connect(func(): _done(false, "server disconnected"))
	net.connect_to_server(url)


func _on_teams_received(teams: Array) -> void:
	var playable := teams.filter(func(t: Dictionary): return t.get("id") != -1)
	if player_index >= playable.size():
		_done(false, "player %d needs a team but the game only has %d playable teams" % [player_index, playable.size()])
		return
	var team: Dictionary = playable[player_index]
	_log("joining team '%s' (id %d)" % [team.get("name"), team.get("id")])
	net.select_team(team.get("id"))


func _on_game_file_received(data: PackedByteArray, team_id: int) -> void:
	_log("received game file (%d bytes) for team %d; ending turn in %.1f s" % [data.size(), team_id, end_turn_delay])
	await create_timer(end_turn_delay).timeout
	net.end_peer_turn.rpc_id(net.SERVER_PEER_ID, [])


func _on_turn_ended(state: Dictionary) -> void:
	var end_turn := int(state.get("turn_number", -1))
	# local-multiplayer.sh compares these lines across players.
	_log("turns: start=%d end=%d" % [_start_turn, end_turn])
	_done(true, "turn ended, server moved from turn %d to %d" % [_start_turn, end_turn])


func _log(msg: String) -> void:
	print("[smoke] %s" % msg)


func _done(ok: bool, msg: String) -> void:
	if _finished:
		return
	_finished = true
	_log("%s: %s" % ["PASS" if ok else "FAIL", msg])
	quit(0 if ok else 1)
