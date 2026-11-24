extends GutTest

var game_state: GameState
var data_manager: GameDataManager
var unit_type: UnitType
var player: Player


func before_each() -> void:
	game_state = GameState.new({}, 7, 0)
	data_manager = GameDataManager.new(game_state, GameDefinition.new(), ClientAttributes.new())
	unit_type = UnitType.new()
	unit_type.attributes = {
		UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP: 10,
		UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE: 5,
	}
	var team := Team.new("Test team", 1, Color.WHITE, [])
	player = Player.new("Test player", 1, team, false)


func test_remove_dead_units_from_empty_state() -> void:
	var units: Array[Unit] = []
	var alias: Array[Unit] = units
	data_manager.remove_dead_units(units)
	assert_eq(units.size(), 0)
	assert_eq(alias.size(), 0)
	assert_eq(data_manager.get_units().size(), 0)


func test_remove_all_dead_units_in_one_pass() -> void:
	var units: Array[Unit] = DEBUG_create_units([0, -1, 0, -5])
	var original_units: Array[Unit] = units.duplicate()
	var alias: Array[Unit] = units
	data_manager.remove_dead_units(units)
	DEBUG_assert_cleanup(units, alias, [], original_units)


func test_keep_all_living_units_in_order() -> void:
	var units: Array[Unit] = DEBUG_create_units([10, 1, 6])
	# Supply a different order from the state's dictionary insertion order.
	units.reverse()
	var expected: Array[Unit] = units.duplicate()
	var alias: Array[Unit] = units
	data_manager.remove_dead_units(units)
	DEBUG_assert_cleanup(units, alias, expected, [])


func test_remove_consecutive_and_end_deaths_preserving_survivors() -> void:
	var units: Array[Unit] = DEBUG_create_units([0, 8, -2, 0, 3, 10, -1])
	units.reverse()
	var expected: Array[Unit] = [units[1], units[2], units[5]]
	var removed: Array[Unit] = [units[0], units[3], units[4], units[6]]
	var alias: Array[Unit] = units
	data_manager.remove_dead_units(units)
	DEBUG_assert_cleanup(units, alias, expected, removed)


func test_repeat_cleanup_then_remove_new_death() -> void:
	var units: Array[Unit] = DEBUG_create_units([0, 8, 3, -1])
	var expected: Array[Unit] = [units[1], units[2]]
	var removed: Array[Unit] = [units[0], units[3]]
	var alias: Array[Unit] = units
	data_manager.remove_dead_units(units)
	data_manager.remove_dead_units(units)
	DEBUG_assert_cleanup(units, alias, expected, removed)
	var newly_dead: Unit = expected.pop_front()
	newly_dead.take_damage(newly_dead.hp)
	removed.append(newly_dead)
	data_manager.remove_dead_units(units)
	DEBUG_assert_cleanup(units, alias, expected, removed)


func test_cleanup_only_mutates_replacement_state() -> void:
	var original_units: Array[Unit] = DEBUG_create_units([0, 8, -2, 3])
	var copied_state: GameState = game_state.deep_copy()
	data_manager.replace_game_state(copied_state)
	var units: Array[Unit] = copied_state.getUnits()
	var expected: Array[Unit] = [units[1], units[3]]
	var removed: Array[Unit] = [units[0], units[2]]
	# Kill a unit only in the copy to verify that its HP is independent too.
	expected[0].take_damage(8)
	removed.append(expected.pop_front())
	var alias: Array[Unit] = units
	data_manager.remove_dead_units(units)
	DEBUG_assert_cleanup(units, alias, expected, removed)
	assert_same(data_manager.get_game_state(), copied_state)
	assert_eq(game_state.getUnits(), original_units)
	assert_eq(original_units[1].hp, 8)
	assert_eq(game_state._turn_number, 7)
	assert_eq(copied_state._turn_number, 7)
	assert_ne(expected[0], original_units[3])


## TESTING Creates real units with deterministic HP through damage.
func DEBUG_create_units(hit_points: Array[int]) -> Array[Unit]:
	var units: Array[Unit] = []
	for index: int in range(hit_points.size()):
		var unit: Unit = game_state.addUnit(unit_type, Vector2i(index, 0), player)
		unit.take_damage(10 - hit_points[index])
		units.append(unit)
	return units


## TESTING Checks both array references and the mounted state's dictionary.
func DEBUG_assert_cleanup(units: Array[Unit], alias: Array[Unit], expected: Array[Unit],
		removed: Array[Unit]) -> void:
	assert_eq(units, expected, "Survivor references and order must be retained")
	assert_eq(alias, expected, "Cleanup must be visible through the supplied array's alias")
	assert_eq(data_manager.get_units().size(), expected.size())
	for unit: Unit in expected:
		assert_same(data_manager.get_unit_by_id(unit.getId()), unit)
	for unit: Unit in removed:
		assert_false(data_manager.get_units().has(unit.getId()))
