extends GutTest

var game_master: GameMaster
var game_state: GameState
var saved_initiative: Callable
var had_initiative: bool


func before_each() -> void:
	game_state = GameState.new({}, 7, 0)
	game_master = GameMaster.new()
	game_master.data_manager = GameDataManager.new(
		game_state, GameDefinition.new(), ClientAttributes.new())
	had_initiative = GameArgs.args.has(GameArgs.ArgType.UNIT_INITIATIVE_FUNC)
	saved_initiative = GameArgs.args.get(GameArgs.ArgType.UNIT_INITIATIVE_FUNC, Callable())
	GameArgs.args[GameArgs.ArgType.UNIT_INITIATIVE_FUNC] = func(units: Array[Unit]) -> void:
		units.reverse()


func after_each() -> void:
	if had_initiative:
		GameArgs.args[GameArgs.ArgType.UNIT_INITIATIVE_FUNC] = saved_initiative
	else:
		GameArgs.args.erase(GameArgs.ArgType.UNIT_INITIATIVE_FUNC)
	game_master.free()


func test_local_turn_with_empty_population() -> void:
	DEBUG_assert_turn_cleanup([], false)


func test_local_turn_with_all_dead_population() -> void:
	DEBUG_assert_turn_cleanup([0, -1, 0], false)


func test_local_turn_with_mixed_population() -> void:
	DEBUG_assert_turn_cleanup([0, 8, -2, 0, 3, -1], false)


func test_builder_turn_with_empty_population() -> void:
	DEBUG_assert_turn_cleanup([], true)


func test_builder_turn_with_all_dead_population() -> void:
	DEBUG_assert_turn_cleanup([0, -1, 0], true)


func test_builder_turn_with_mixed_population() -> void:
	DEBUG_assert_turn_cleanup([0, 8, -2, 0, 3, -1], true)


## TESTING Exercises local turn processing without scene-tree or graphics setup.
func DEBUG_assert_turn_cleanup(hit_points: Array[int], use_builder: bool) -> void:
	var unit_type := UnitType.new()
	unit_type.attributes = {
		UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP: 10,
		UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE: 5,
	}
	var team := Team.new("Test team", 1, Color.WHITE, [])
	var player := Player.new("Test player", 1, team, false)
	var expected_ids: Array[int] = []
	for index: int in range(hit_points.size()):
		var unit: Unit = game_state.addUnit(unit_type, Vector2i(index, 0), player)
		unit.take_damage(10 - hit_points[index])
		if hit_points[index] > 0:
			expected_ids.append(unit.getId())
	var original_units: Array[Unit] = game_state.getUnits()
	var result: GameState
	if use_builder:
		result = game_master.process_end_turn_local_builder()
		assert_same(game_master.data_manager.get_game_state(), result)
		assert_ne(result, game_state)
		assert_eq(game_state._turn_number, 7)
		assert_eq(game_state.getUnits(), original_units)
		for index: int in range(original_units.size()):
			assert_eq(original_units[index].hp, hit_points[index])
	else:
		game_master.process_end_turn_local()
		result = game_master.data_manager.get_game_state()
		assert_same(result, game_state)
	assert_eq(result._turn_number, 8, "Exactly one turn must elapse")
	assert_eq(result._units.keys(), expected_ids)
	for original: Unit in original_units:
		if original.hp <= 0:
			assert_false(result._units.has(original.getId()))
		else:
			var survivor: Unit = result.get_unit_by_id(original.getId())
			assert_not_null(survivor)
			if survivor == null:
				continue
			assert_eq(survivor.hp, original.hp)
			assert_eq(survivor.grid_position, original.grid_position)
			assert_same(survivor.player, original.player)
			assert_same(survivor.type, original.type)
			if use_builder:
				assert_ne(survivor, original)
			else:
				assert_same(survivor, original)
