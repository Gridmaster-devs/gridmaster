extends GutTest

const GAME_MASTER_SCENE = preload("res://executioner/main/game_master/GameMaster.tscn")
const GAME = preload("res://Production test.tres")

class SpawnMultiplayer extends MultiplayerAPIExtension:
	var peer := OfflineMultiplayerPeer.new()
	var requests: Array = []

	func _get_multiplayer_peer() -> MultiplayerPeer:
		return peer

	func _get_unique_id() -> int:
		return 2

	func _rpc(_peer: int, _object: Object, method: StringName, args: Array) -> Error:
		if method == &"request_spawn":
			requests.append(args)
		return OK


var game_master: GameMaster
var console: Node
var previous_game_type: Variant
var previous_popup_manager: PopupManager
var previous_game_args: Dictionary
var previous_endpoint: String
var previous_multiplayer: MultiplayerAPI


func before_each() -> void:
	previous_game_type = Global.game_type
	previous_popup_manager = Global.popup_manager
	previous_game_args = GameArgs.args.duplicate()
	previous_endpoint = Networking._server_endpoint
	previous_multiplayer = get_tree().get_multiplayer()
	Global.game_type = Global.GameType.SINGLEPLAYER
	game_master = GAME_MASTER_SCENE.instantiate()
	add_child_autofree(game_master)
	game_master.grid_graphics.tile_grid.tile_set = game_master.grid_graphics.tile_grid.tile_set.duplicate(true)
	console = game_master.get_node_or_null("DeveloperConsole")
	assert_not_null(console, "The Executioner scene has a developer console")


func after_each() -> void:
	Global.game_type = previous_game_type
	Global.popup_manager = previous_popup_manager
	GameArgs.args = previous_game_args
	Networking._server_endpoint = previous_endpoint
	get_tree().set_multiplayer(previous_multiplayer)


func test_availability_and_inspection() -> void:
	if console == null:
		return
	var before: Dictionary = await console.DEBUG_execute("help")
	assert_eq(before["code"], "unavailable")
	game_master.local_init_game(GAME)
	var help: Dictionary = await console.DEBUG_execute(" help ")
	assert_eq(help.keys(), ["ok", "code", "message", "data"])
	assert_true(help["ok"])
	assert_eq(help["code"], "ok")
	assert_has(help["data"]["commands"], "spawn")
	var state: Dictionary = (await console.DEBUG_execute("state"))["data"]
	var manager: GameDataManager = game_master.data_manager
	assert_eq_deep(state, {
		"game_name": "Production Test",
		"mode": "singleplayer",
		"turn_number": 0,
		"width": manager.get_grid().width,
		"height": manager.get_grid().height,
		"active_player_id": manager.get_client_player_id(),
		"unit_count": manager.get_units().size(),
		"game_over": false,
	})
	var units: Array = (await console.DEBUG_execute("units"))["data"]["units"]
	assert_eq(units.size(), manager.get_units().size())
	var unit: Unit = manager.get_units().values()[0]
	assert_eq_deep(units[0], {
		"id": unit.getId(), "type": unit.type.unit_name, "player_id": unit.get_player_id(),
		"x": unit.grid_position.x, "y": unit.grid_position.y, "hp": unit.hp,
	})


func test_quoted_spawn_uses_local_player_and_refreshes_board() -> void:
	if console == null:
		return
	game_master.local_init_game(GAME)
	var manager: GameDataManager = game_master.data_manager
	var unit: Unit = manager.get_units().values()[0]
	unit.type.unit_name = "Heavy Infantry"
	var types: Array = (await console.DEBUG_execute("types"))["data"]["types"]
	assert_has(types, "Heavy Infantry")
	var tile: Vector2i = DEBUG_find_empty_tile()
	watch_signals(game_master)
	var result: Dictionary = await console.DEBUG_execute('spawn "Heavy Infantry" %d %d' % [tile.x, tile.y])
	assert_true(result["ok"])
	var spawned: Unit = manager.get_unit_by_position_nullable(tile)
	assert_not_null(spawned)
	if spawned != null:
		assert_eq(spawned.getId(), result["data"]["unit_id"])
		assert_eq(spawned.get_player_id(), manager.get_client_player_id())
		assert_same(spawned.type, unit.type)
	assert_signal_emitted(game_master, "units_changed")
	assert_eq(manager.get_turn_number(), 0)
	unit.type.unit_name = 'Heavy "Infantry" \\ Support'
	tile = DEBUG_find_empty_tile()
	result = await console.DEBUG_execute('spawn "Heavy \\"Infantry\\" \\\\ Support" %d %d' % [tile.x, tile.y])
	assert_true(result["ok"])


func test_rejected_spawns_leave_state_unchanged() -> void:
	if console == null:
		return
	game_master.local_init_game(GAME)
	var manager: GameDataManager = game_master.data_manager
	var unit: Unit = manager.get_units().values()[0]
	unit.type.unit_name = "Heavy Infantry"
	var before: Dictionary = (await console.DEBUG_execute("units"))["data"]
	var cases: Dictionary = {
		" ": "empty_command",
		"unknown": "unknown_command",
		"state extra": "invalid_arguments",
		'spawn "Heavy Infantry': "invalid_syntax",
		'spawn "Heavy Infantry"x 0 0': "invalid_syntax",
		'spawn "Heavy Infantry" 1': "invalid_arguments",
		'spawn "Heavy Infantry" 1.5 0': "invalid_coordinates",
		'spawn "Heavy Infantry" 4294967296 0': "out_of_bounds",
		'spawn "Heavy Infantry" -1 0': "out_of_bounds",
		'spawn "heavy infantry" 0 0': "unknown_unit_type",
		'spawn "Heavy Infantry" %d %d' % [unit.grid_position.x, unit.grid_position.y]: "occupied",
	}
	for line: String in cases:
		var result: Dictionary = await console.DEBUG_execute(line)
		assert_false(result["ok"], line)
		assert_eq(result["code"], cases[line], line)
	game_master._game_over = true
	var result: Dictionary = await console.DEBUG_execute('spawn "Heavy Infantry" 0 0')
	assert_eq(result["code"], "game_over")
	assert_eq_deep((await console.DEBUG_execute("units"))["data"], before)
	assert_eq(manager.get_turn_number(), 0)


func test_performance_before_and_after_turn_and_reload() -> void:
	if console == null:
		return
	game_master.local_init_game(GAME)
	var before: Dictionary = await console.DEBUG_execute("perf")
	assert_null(before["data"]["turn_processing_ms"])
	if DisplayServer.get_name() == "headless":
		assert_null(before["data"]["fps"])
	game_master.end_turn()
	var after: Dictionary = (await console.DEBUG_execute("perf"))["data"]
	assert_typeof(after["turn_processing_ms"], TYPE_FLOAT)
	assert_gte(after["turn_processing_ms"], 0.0)
	assert_eq((await console.DEBUG_execute("state"))["data"]["turn_number"], 1)
	var next_game: GameDefinitionResource = GAME.duplicate()
	next_game.game_name = "Second match"
	game_master.local_init_game(next_game)
	assert_null((await console.DEBUG_execute("perf"))["data"]["turn_processing_ms"])
	assert_eq((await console.DEBUG_execute("state"))["data"]["game_name"], "Second match")


func test_spawn_falls_back_to_the_neutral_player() -> void:
	game_master.local_init_game(GAME)
	var manager: GameDataManager = game_master.data_manager
	manager.get_client_attributes().client_player_id = -1
	var unit: Unit = manager.get_units().values()[0]
	var tile: Vector2i = DEBUG_find_empty_tile()
	var result: Dictionary = await console.DEBUG_execute('spawn "%s" %d %d' % [
		unit.type.unit_name, tile.x, tile.y,
	])
	assert_true(result["ok"])
	assert_same(manager.get_unit_by_position_nullable(tile).player, Player.NEUTRAL_PLAYER)


func test_console_focus_submission_and_gameplay_input() -> void:
	# Isolate GUI hit testing from the GUT runner's own controls.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 540)
	add_child_autofree(viewport)
	game_master.reparent(viewport)
	viewport.notify_mouse_entered()
	DEBUG_push_key(KEY_F2)
	assert_false(console.visible)
	game_master.local_init_game(GAME)
	await get_tree().process_frame
	var end_turn: Button = game_master.gui_scene.get_node("EndTurnButton")
	end_turn.grab_focus()
	watch_signals(end_turn)
	DEBUG_push_key(KEY_F2)
	assert_true(console.visible)
	var input: LineEdit = console.get_node("%CommandLine")
	assert_true(input.has_focus())
	input.text = "state"
	DEBUG_push_key(KEY_ENTER)
	var transcript: RichTextLabel = console.get_node("%Transcript")
	assert_string_contains(transcript.get_parsed_text(), "Completed turns: 0")
	assert_true(input.has_focus())
	DEBUG_click(end_turn.get_global_rect().get_center())
	assert_signal_not_emitted(end_turn, "pressed")
	game_master.receive_ui_event(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.END_TURN))
	assert_eq(game_master.data_manager.get_turn_number(), 0)
	DEBUG_push_key(KEY_ESCAPE)
	assert_false(console.visible)
	assert_true(end_turn.has_focus())
	DEBUG_click(end_turn.get_global_rect().get_center())
	assert_signal_emitted(end_turn, "pressed")
	assert_eq(game_master.data_manager.get_turn_number(), 1)


func test_network_console_requires_both_loopback_and_matching_revision() -> void:
	var update: Dictionary = DEBUG_prepare_network_game()
	update["dev_console_revision"] = DeveloperConsoleRPC.REVISION
	Networking._server_endpoint = "ws://example.test:8082"
	game_master._on_game_state_received(update)
	assert_eq((await console.DEBUG_execute("help"))["code"], "unavailable")
	Networking._server_endpoint = "ws://127.0.0.1:8082@example.test"
	game_master._on_game_state_received(update)
	assert_eq((await console.DEBUG_execute("help"))["code"], "unavailable")
	Networking._server_endpoint = "ws://127.0.0.1:8082"
	update["dev_console_revision"] = DeveloperConsoleRPC.REVISION + 1
	game_master._on_game_state_received(update)
	assert_eq((await console.DEBUG_execute("help"))["code"], "unavailable")
	update.erase("dev_console_revision")
	game_master._on_game_state_received(update)
	assert_eq((await console.DEBUG_execute("help"))["code"], "unavailable")
	update["dev_console_revision"] = DeveloperConsoleRPC.REVISION
	update["turn_processing_ms"] = 1.25
	assert_eq((await console.DEBUG_execute("help"))["code"], "unavailable")
	game_master._on_game_state_received(update)
	assert_eq((await console.DEBUG_execute("state"))["data"]["turn_number"], 4)
	assert_eq((await console.DEBUG_execute("perf"))["data"]["turn_processing_ms"], 1.25)
	previous_multiplayer.server_disconnected.emit()
	assert_null(game_master.turn_processing_ms)
	assert_eq((await console.DEBUG_execute("perf"))["code"], "unavailable")


func test_incremental_spawn_preserves_turn_and_queued_action() -> void:
	var update: Dictionary = DEBUG_prepare_network_game()
	update["dev_console_revision"] = DeveloperConsoleRPC.REVISION
	game_master._on_game_state_received(update)
	var manager: GameDataManager = game_master.data_manager
	var original: Unit = manager.get_units().values()[0]
	var empty_tile: Vector2i = DEBUG_find_empty_tile()
	var action := MoveAction.new([empty_tile], original.get_player_id(), original, manager)
	original.current_action = action
	game_master.moved_unit = original
	game_master.ui_state = GameMaster.UIState.UNIT_MOVE
	game_master.current_path = [empty_tile]

	var snapshot: Dictionary = {
		"id": 1000, "position": empty_tile, "hp": 2,
		"player_id": original.get_player_id(), "type_id": original.type.type_id,
	}
	Networking.developer_console_rpc.receive_spawned_unit(snapshot)
	Networking.developer_console_rpc.receive_spawned_unit(snapshot)
	assert_eq(manager.get_turn_number(), 4)
	assert_eq(manager.get_units().size(), update["units"].size() + 1)
	assert_eq(manager.get_unit_by_id(1000).hp, 2)
	assert_same(original.current_action, action)
	assert_null(game_master.moved_unit)
	assert_eq(game_master.current_path, [] as Array[Vector2i])
	original.current_action = null


func test_spawn_update_requires_joined_match_but_not_console_access() -> void:
	var update: Dictionary = DEBUG_prepare_network_game()
	update["dev_console_revision"] = DeveloperConsoleRPC.REVISION
	Networking._server_endpoint = "ws://localhost:8082"
	var manager: GameDataManager = game_master.data_manager
	var original: Unit = manager.get_units().values()[0]
	var snapshot: Dictionary = {
		"id": 1000, "position": DEBUG_find_empty_tile(), "hp": original.hp,
		"player_id": original.get_player_id(), "type_id": original.type.type_id,
	}
	var rpc: DeveloperConsoleRPC = Networking.developer_console_rpc
	rpc.receive_spawned_unit(snapshot)
	assert_null(manager.get_unit_by_id(1000))
	game_master._on_game_state_received(update)
	assert_eq((await console.DEBUG_execute("help"))["code"], "unavailable")
	rpc.receive_spawned_unit(snapshot)
	assert_not_null(manager.get_unit_by_id(1000))
	assert_eq(manager.get_turn_number(), 4)
	previous_multiplayer.server_disconnected.emit()
	snapshot["id"] = 1001
	snapshot["position"] = DEBUG_find_empty_tile()
	rpc.receive_spawned_unit(snapshot)
	assert_null(manager.get_unit_by_id(1001))


func test_spawn_waits_for_matching_reply_and_resolves_on_disconnect() -> void:
	var mock := SpawnMultiplayer.new()
	get_tree().set_multiplayer(mock)
	var rpc: DeveloperConsoleRPC = Networking.developer_console_rpc
	var replies: Array[Dictionary] = []
	DEBUG_record_spawn_reply(rpc, replies)
	assert_eq(mock.requests.size(), 1)
	var first_request_id: int = mock.requests[0][0]
	assert_eq((await rpc.spawn("Infantry", 0, 0))["code"], "spawn_pending")
	rpc.receive_spawn_reply(first_request_id + 1, DeveloperCommands.result("ok", "Wrong ID"))
	assert_eq(replies.size(), 0)
	rpc.receive_spawn_reply(first_request_id, DeveloperCommands.result("ok", "Correct ID"))
	assert_eq(replies[0]["message"], "Correct ID")
	DEBUG_record_spawn_reply(rpc, replies)
	previous_multiplayer.server_disconnected.emit()
	assert_eq(replies[1]["code"], "disconnected")
	rpc.receive_spawn_reply(mock.requests[1][0], DeveloperCommands.result("ok", "Late"))
	assert_eq(replies.size(), 2)


func test_spawn_timeout_releases_request_without_retrying() -> void:
	var mock := SpawnMultiplayer.new()
	get_tree().set_multiplayer(mock)
	var rpc: DeveloperConsoleRPC = Networking.developer_console_rpc
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = await rpc.spawn("Infantry", 0, 0)
	assert_eq(result["code"], "timeout")
	assert_gte(Time.get_ticks_msec() - started, 4900)
	assert_eq(mock.requests.size(), 1)


## TESTING Pushes a key through the viewport to exercise the overlay's input routing.
func DEBUG_push_key(key: Key) -> void:
	var viewport: Viewport = game_master.get_viewport()
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	viewport.push_input(event)
	event = event.duplicate()
	event.pressed = false
	viewport.push_input(event)


## TESTING Sends a click through the real viewport overlay and button.
func DEBUG_click(position: Vector2) -> void:
	var viewport: Viewport = game_master.get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	viewport.push_input(motion, true)
	viewport.push_input(GutInputFactory.mouse_left_button_down(position, position), true)
	viewport.push_input(GutInputFactory.mouse_left_button_up(position, position), true)


## TESTING Loads the game file and prepares an authoritative initial state.
func DEBUG_prepare_network_game() -> Dictionary:
	Global.game_type = Global.GameType.MULTIPLAYER
	Networking._server_endpoint = "ws://127.0.0.1:8082"
	game_master._on_game_file_received(FileAccess.get_file_as_bytes("res://Production test.tres"), 1)
	var units: Array[Dictionary] = []
	for unit: Unit in game_master.data_manager.get_units().values():
		units.append({
			"id": unit.getId(), "position": unit.grid_position, "hp": unit.hp,
			"player_id": unit.get_player_id(), "type_id": unit.type.type_id,
		})
	return {"turn_number": 4, "units": units, "game_over": false}


## TESTING Starts a request so the test can deliver unrelated and matching replies.
func DEBUG_record_spawn_reply(rpc: DeveloperConsoleRPC, replies: Array[Dictionary]) -> void:
	replies.append(await rpc.spawn("Infantry", 0, 0))


## TESTING Finds an empty coordinate without depending on fixture layout.
func DEBUG_find_empty_tile() -> Vector2i:
	var manager: GameDataManager = game_master.data_manager
	for y: int in range(manager.get_grid().height):
		for x: int in range(manager.get_grid().width):
			var tile := Vector2i(x, y)
			if manager.get_unit_by_position_nullable(tile) == null:
				return tile
	return Vector2i(-1, -1)
