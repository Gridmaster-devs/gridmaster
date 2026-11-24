extends GutTest

const Server = preload("res://server/server.gd")
const GAME = preload("res://Production test.tres")

var server: Node
var state: ServerState


func before_each() -> void:
	server = autofree(Server.new())
	state = ServerState.new(GAME)
	server.server_state = state


func test_console_requires_debug_loopback_server() -> void:
	assert_true(Server.allows_developer_console(true, "127.0.0.1"))
	assert_false(Server.allows_developer_console(false, "127.0.0.1"))
	for bind_address: String in ["0.0.0.0", "*", "", "localhost", "::1"]:
		assert_false(Server.allows_developer_console(true, bind_address))


func test_spawn_requires_enabled_console_and_joined_player() -> void:
	state.join(2)
	assert_eq(server._process_spawn_request(2, "Infantry", 0, 0)["code"], "unavailable")
	assert_false(server._create_state_update_dict().has("dev_console_revision"))
	server._dev_console_enabled = true
	assert_eq(server._process_spawn_request(2, "Infantry", 0, 0)["code"], "not_joined")
	assert_eq(server._process_spawn_request(3, "Infantry", 0, 0)["code"], "not_joined")
	state.assign_peer_to_team(2, 1)
	state.game_over = true
	assert_eq(server._process_spawn_request(2, "Infantry", 0, 0)["code"], "game_over")
	var update: Dictionary = server._create_state_update_dict()
	assert_eq(update["dev_console_revision"], DeveloperConsoleRPC.REVISION)
	assert_null(update["turn_processing_ms"])


func test_two_joined_peers_competing_for_a_tile_create_one_unit() -> void:
	server._dev_console_enabled = true
	state.join(2)
	state.assign_peer_to_team(2, 1)
	state.join(3)
	state.assign_peer_to_team(3, 2)
	var manager: GameDataManager = state.data_manager
	var original_count: int = manager.get_units().size()
	var original: Unit = manager.get_units().values()[0]
	var tile: Vector2i = DEBUG_find_empty_tile(manager)
	var first: Dictionary = server._process_spawn_request(2, original.type.unit_name, tile.x, tile.y)
	var second: Dictionary = server._process_spawn_request(3, original.type.unit_name, tile.x, tile.y)
	assert_true(first["ok"])
	assert_eq(second["code"], "occupied")
	var spawned: Unit = manager.get_unit_by_position_nullable(tile)
	if spawned != null:
		assert_eq(spawned.get_player_id(), state.get_peer_player_id(2))
		assert_eq(first["data"]["unit_id"], spawned.getId())
	assert_eq(manager.get_units().size(), original_count + 1)
	assert_eq(manager.get_turn_number(), 0)


## TESTING Finds an empty coordinate without depending on fixture layout.
func DEBUG_find_empty_tile(manager: GameDataManager) -> Vector2i:
	for y: int in range(manager.get_grid().height):
		for x: int in range(manager.get_grid().width):
			var tile := Vector2i(x, y)
			if manager.get_unit_by_position_nullable(tile) == null:
				return tile
	return Vector2i(-1, -1)
