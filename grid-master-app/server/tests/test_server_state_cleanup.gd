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
