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
## With --check-dev-console, both players use the Executioner scene and wait to
## observe the same spawned unit before submitting their turn. Pass both clients
## the same fresh --join-ready-file path so player 1 can signal when it has joined.
extends SceneTree

const TIMEOUT_SECONDS := 30.0

var url := "ws://127.0.0.1:8082"
var upload_path := ""
var player_index := 0
var end_turn_delay := 3.0
var net: Node
var _finished := false
var _start_turn := -1
var _check_console: bool = false
var _join_ready_file: String = ""
var _game_master: Node
var _console: Node
var _spawned_unit_id: int = -1


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
		elif arg == "--check-dev-console":
			_check_console = true
		elif arg.begins_with("--join-ready-file="):
			_join_ready_file = arg.trim_prefix("--join-ready-file=")
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
	if _check_console:
		if _join_ready_file.is_empty():
			_done(false, "--check-dev-console requires a shared --join-ready-file path")
			return
		var settings: Node = root.get_node("Global")
		settings.game_type = settings.GameType.MULTIPLAYER
		var scene: PackedScene = load("res://executioner/main/game_master/GameMaster.tscn")
		_game_master = scene.instantiate()
		root.add_child(_game_master)
		_console = _game_master.get_node("DeveloperConsole")
		net.developer_console_rpc.unit_spawned.connect(_on_unit_spawned)
	net.connected_to_server_signal.connect(func(): _log("connected to %s" % url))
	net.teams_received.connect(_on_teams_received)
	net.game_file_received.connect(_on_game_file_received)
	net.game_state_received.connect(_on_game_state_received)
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
	if _check_console:
		_log("received game file (%d bytes) for team %d" % [data.size(), team_id])
		return
	_log("received game file (%d bytes) for team %d; ending turn in %.1f s" % [data.size(), team_id, end_turn_delay])
	await create_timer(end_turn_delay).timeout
	net.end_peer_turn.rpc_id(net.SERVER_PEER_ID, [])


func _on_game_state_received(state: Dictionary) -> void:
	_start_turn = int(state.get("turn_number", -1))
	if not _check_console:
		return
	# Wait until the Executioner has handled the same initial-state signal.
	await process_frame
	var perf: Dictionary = await _console.DEBUG_execute("perf")
	if not perf["ok"] or perf["data"]["fps"] != null or perf["data"]["turn_processing_ms"] != null:
		_done(false, "expected an available console with no samples before turn %d, got %s" % [_start_turn, perf])
		return
	_log("joined match on turn %d" % _start_turn)
	if player_index != 0:
		var ready_file: FileAccess = FileAccess.open(_join_ready_file, FileAccess.WRITE)
		if ready_file == null:
			_done(false, "could not signal join readiness: %s" % error_string(FileAccess.get_open_error()))
			return
		ready_file.close()
		return

	while not _finished and not FileAccess.file_exists(_join_ready_file):
		await create_timer(0.05).timeout
	if _finished:
		return
	var types: Dictionary = await _console.DEBUG_execute("types")
	var manager: Object = _game_master.data_manager
	var tile: Vector2i = _find_spawn_tile(manager)
	if not types["ok"] or types["data"]["types"].is_empty() or tile.x < 0:
		_done(false, "the game needs a registered unit type and an empty tile to test spawning")
		return
	var type_name: String = types["data"]["types"][0]
	var quoted_name: String = type_name.replace("\\", "\\\\").replace('"', '\\"')
	var spawn: Dictionary = await _console.DEBUG_execute('spawn "%s" %d %d' % [quoted_name, tile.x, tile.y])
	if not spawn["ok"] or spawn["data"]["unit_id"] != _spawned_unit_id:
		_done(false, "spawn reply does not match the unit observed on the board: %s" % spawn["message"])
		return
	_game_master.end_turn()


func _find_spawn_tile(manager: Object) -> Vector2i:
	var fallback := Vector2i(-1, -1)
	for y: int in range(manager.get_grid().height):
		for x: int in range(manager.get_grid().width):
			var tile := Vector2i(x, y)
			if manager.get_unit_by_position_nullable(tile) != null:
				continue
			fallback = tile
			# Prefer a tile every team can see through fog of war.
			var visible_to_all: bool = true
			for player_id: int in manager.get_players():
				if player_id >= 0 and not manager.is_tile_visible(tile, player_id):
					visible_to_all = false
					break
			if visible_to_all:
				return tile
	return fallback


func _on_unit_spawned(snapshot: Dictionary) -> void:
	var manager: Object = _game_master.data_manager
	var unit: Object = manager.get_unit_by_id(snapshot["id"])
	if unit == null or unit.grid_position != snapshot["position"] or manager.get_turn_number() != _start_turn:
		_done(false, "incremental unit update did not reach the board before the turn ended")
		return
	_spawned_unit_id = unit.getId()
	_log("spawned unit: %d" % _spawned_unit_id)
	if player_index != 0:
		# Let the current RPC finish before sending the turn.
		_game_master.end_turn.call_deferred()


func _on_turn_ended(state: Dictionary) -> void:
	var end_turn := int(state.get("turn_number", -1))
	if _check_console:
		var perf: Dictionary = await _console.DEBUG_execute("perf")
		if _spawned_unit_id < 0 or not perf["ok"] or not perf["data"]["turn_processing_ms"] is float:
			_done(false, "missing spawned unit or authoritative turn duration")
			return
		_log("turn processing ms: %.3f" % perf["data"]["turn_processing_ms"])
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
