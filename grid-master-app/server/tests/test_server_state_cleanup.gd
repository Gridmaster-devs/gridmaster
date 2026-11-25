extends GutTest

const Server = preload("res://server/server.gd")

var server_state: ServerState
var server_node: Node


func before_each() -> void:
	server_state = ServerState.new(DEBUG_create_game_definition())
	# Keep the server outside the tree: no _ready(), sockets, or RPCs.
	server_node = Server.new()
	server_node.server_state = server_state


func after_each() -> void:
	server_node.free()


func test_empty_cleanup_and_snapshot() -> void:
	DEBUG_assert_cleanup_and_snapshot([])


func test_all_dead_units_are_absent_from_state_and_snapshot() -> void:
	DEBUG_assert_cleanup_and_snapshot([0, -1, 0])


func test_mixed_cleanup_preserves_survivor_snapshot_fields() -> void:
	DEBUG_assert_cleanup_and_snapshot([0, 8, -2, 0, 3, -1])


func test_production_requests_require_an_idle_owned_producer_and_eligible_target() -> void:
	var manager := server_state.data_manager
	var definition := manager.get_game_defintion()
	var team_id := definition.add_team("Host", Color.WHITE, [])
	var enemy_id := definition.add_team("Guest", Color.RED, [])
	var player := definition.get_player_by_id(definition.add_player("Host", team_id, false))
	var enemy := definition.get_player_by_id(definition.add_player("Guest", enemy_id, false))
	for id in range(10, 14):
		var type := UnitType.debugType()
		type.type_id = id
		definition.unit_types[id] = type
	var producer_type := definition.unit_types[10]
	var allowed_target := definition.unit_types[11]
	allowed_target.is_producible_unit = true
	definition.unit_types[13].is_producible_unit = true
	producer_type.is_production_unit = true
	producer_type.producible_units_ids = [11, 12]
	producer_type.populate_producible_units(definition.unit_types)
	allowed_target.producible_units = [definition.unit_types[13]]
	var state := manager.get_game_state()
	var producer := state.addUnit(producer_type, Vector2i.ZERO, player)
	var non_producer := state.addUnit(allowed_target, Vector2i.RIGHT, player)
	var enemy_producer := state.addUnit(producer_type, Vector2i.DOWN, enemy)
	server_state.join(2)
	server_state.assign_peer_to_team(2, team_id)
	server_state.join(3) # Keep the server waiting for another peer after queueing actions.

	var requests: Array = []
	for target_id in [12, 13, 99, "11", null]:
		requests.append({"type": "ProductionAction", "unit_id": producer.getId(), "producible_unit_id": target_id})
	requests.append({"type": "ProductionAction", "unit_id": non_producer.getId(), "producible_unit_id": 13})
	requests.append({"type": "ProductionAction", "unit_id": enemy_producer.getId(), "producible_unit_id": 11})
	server_node._on_team_turn_end(2, requests)
	assert_null(producer.current_action)
	assert_null(non_producer.current_action)
	assert_null(enemy_producer.current_action)

	var valid_request := {"type": "ProductionAction", "unit_id": producer.getId(), "producible_unit_id": 11}
	server_state.clear_player_turns()
	server_node._on_team_turn_end(2, [valid_request])
	var action := producer.current_action as ProductionAction
	assert_not_null(action)
	if action != null:
		assert_same(action.producible_unit, allowed_target)
		server_state.clear_player_turns()
		server_node._on_team_turn_end(2, [valid_request])
		assert_same(producer.current_action, action)
	producer.current_action = null
	non_producer.current_action = null
	enemy_producer.current_action = null


## TESTING Builds a small map entirely in memory for real ServerState initialization.
func DEBUG_create_game_definition() -> GameDefinitionResource:
	var terrain := Array2D.new()
	terrain.init(3, 3)
	for x: int in range(3):
		for y: int in range(3):
			terrain.setItem(x, y, {
				"name": "Plain",
				"movement": 1,
				"hiding": 0,
				"protection": 0,
				"texture": null,
			})
	var strategic_map := MapPainterRes.new()
	strategic_map.init(3, 3, [terrain], {}, "Cleanup test map")
	var map_resource := MapResource.new()
	map_resource.init(strategic_map, {})
	var unit_layer := Array2D.new()
	unit_layer.init(3, 3)
	for x: int in range(3):
		for y: int in range(3):
			unit_layer.setItem(x, y, {})
	var definition := GameDefinitionResource.new()
	definition.game_name = "Cleanup test"
	definition.map = map_resource
	definition.unit_layer = unit_layer
	return definition


## TESTING Checks real manager cleanup and server serialization without networking.
func DEBUG_assert_cleanup_and_snapshot(hit_points: Array[int]) -> void:
	var manager: GameDataManager = server_state.data_manager
	var definition: GameDefinition = manager.get_game_defintion()
	var team_id: int = definition.add_team("Test team", Color.WHITE, [])
	var players: Array[Player] = []
	var unit_types: Array[UnitType] = []
	for index: int in range(2):
		var player_id: int = definition.add_player("Player %d" % index, team_id, false)
		players.append(definition.get_player_by_id(player_id))
		var unit_type := UnitType.new()
		unit_type.type_id = 20 + index
		unit_type.attributes = {
			UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP: 10,
			UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE: 5,
		}
		definition.unit_types[unit_type.type_id] = unit_type
		unit_types.append(unit_type)
	var expected_units: Array[Unit] = []
	var removed_ids: Array[int] = []
	var expected_snapshot: Array[Dictionary] = []
	for index: int in range(hit_points.size()):
		var position := Vector2i(index % 3, floori(index / 3.0))
		var player: Player = players[index % 2]
		var unit_type: UnitType = unit_types[index % 2]
		var unit: Unit = manager.get_game_state().addUnit(unit_type, position, player)
		unit.take_damage(10 - hit_points[index])
		if hit_points[index] <= 0:
			removed_ids.append(unit.getId())
		else:
			expected_units.append(unit)
			expected_snapshot.append({
				"id": unit.getId(),
				"position": position,
				"hp": hit_points[index],
				"player_id": player.player_id,
				"type_id": unit_type.type_id,
			})
	var units: Array[Unit] = manager.get_units().values()
	manager.remove_dead_units(units)
	assert_eq(units, expected_units)
	assert_eq(manager.get_game_state().getUnits(), expected_units)
	for unit: Unit in expected_units:
		assert_same(manager.get_unit_by_id(unit.getId()), unit)
	for unit_id: int in removed_ids:
		assert_false(manager.get_units().has(unit_id))
	var snapshot: Dictionary = server_node._create_state_update_dict()
	assert_eq_deep(snapshot["units"], expected_snapshot)
	assert_eq(snapshot["turn_number"], 0, "Cleanup must not advance the turn")
