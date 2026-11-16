extends GutTest

const OLD_GAME_FILE := "res://test_games/Production test.tres"
const ROUND_TRIP_FILE := "user://test_move_cost_round_trip.tres"

var game_state : GameState
var game_def: GameDefinition
var game_manager: GameDataManager
var player_id: int


func before_each():
	game_state = GameState.new({}, 0, 0)
	game_def = GameDefinition.new()
	game_manager = GameDataManager.new(game_state, game_def, ClientAttributes.new())
	game_def.resources = ["Gold", "Wood"]

	var team_id: int = game_def.add_team("Team 1", Color(0, 0, 0), [])
	player_id = game_def.add_player("Player 1", team_id, false)


# A unit and its move action point at each other, so the moves are cleared to let them be freed
func after_each():
	for unit in game_state.getUnits():
		unit.current_action = null


func after_all():
	if FileAccess.file_exists(ROUND_TRIP_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ROUND_TRIP_FILE))


#Helper function to create a move cost
func create_move_cost(resource_name: String, amount: int, mode: MoveCost.Mode) -> MoveCost:
	var cost: MoveCost = MoveCost.new()
	cost.cost_resource = resource_name
	cost.amount = amount
	cost.mode = mode
	return cost

#Helper function to add a unit with a move cost (null for none) and a queued move one tile right
func add_moving_unit(cost: MoveCost, position: Vector2i = Vector2i(0, 0)) -> Unit:
	var unit_type: UnitType = UnitType.debugType()
	unit_type.move_cost = cost
	var unit: Unit = game_state.addUnit(unit_type, position, game_def.players.get(player_id))
	var path: Array[Vector2i] = [position, position + Vector2i(1, 0)]
	unit.current_action = MoveAction.new(path, player_id, unit, game_manager)
	return unit

#Helper function to run one whole single-player turn and return the units' positions afterwards
func run_local_turn(units: Array[Unit]) -> Array[Vector2i]:
	game_def._grid = GameGrid.new(5, 5)
	var tile_type: TileType = TileType.debugTile()
	tile_type.attributes[TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT] = 1
	game_def._grid.fillTiles(func(x: int, y: int): return GridTile.new(tile_type, Vector2i(x, y)))
	GameArgs.initialize(game_manager, {})
	game_manager.get_client_attributes().client_player_id = player_id
	var game_master: GameMaster = autofree(GameMaster.new())
	game_master.data_manager = game_manager
	game_manager.replace_game_state(game_master.process_end_turn_local_builder())
	var positions: Array[Vector2i] = []
	for unit in units:
		positions.append(game_manager.get_unit_by_id(unit.getId()).getPosition())
	# the turn works on a copy of the state, so its units are cleared here (see after_each)
	for unit in game_manager.get_game_state().getUnits():
		unit.current_action = null
	return positions

func gold() -> int:
	return game_manager.get_player_resources(player_id)["Gold"]


#can_afford
func test_can_afford_with_more_than_enough():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	assert_true(game_manager.can_afford(player_id, "Gold", 3))

func test_cannot_afford_with_too_little():
	game_manager.set_resource_amount(player_id, "Gold", 2)
	assert_false(game_manager.can_afford(player_id, "Gold", 3))

func test_can_afford_exact_amount():
	game_manager.set_resource_amount(player_id, "Gold", 3)
	assert_true(game_manager.can_afford(player_id, "Gold", 3))

func test_unknown_resource_name_cannot_be_afforded():
	assert_false(game_manager.can_afford(player_id, "Stone", 1))

func test_none_resource_is_free():
	assert_true(game_manager.can_afford(player_id, ConsumeProduce.NO_RESOURCE, 5))


#charge_move_costs
func test_consume_mode_subtracts_and_keeps_move():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var unit: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	var refused: Array[Unit] = game_manager.charge_move_costs()
	assert_eq(refused.size(), 0)
	assert_true(unit.current_action is MoveAction)
	assert_eq(gold(), 2)

func test_require_mode_keeps_amount_and_move():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var unit: Unit = add_moving_unit(create_move_cost("Gold", 5, MoveCost.Mode.REQUIRE))
	game_manager.charge_move_costs()
	assert_true(unit.current_action is MoveAction)
	assert_eq(gold(), 5)

func test_consume_mode_refuses_unaffordable_move():
	game_manager.set_resource_amount(player_id, "Gold", 2)
	var unit: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	var refused: Array[Unit] = game_manager.charge_move_costs()
	assert_eq(refused, [unit] as Array[Unit])
	assert_null(unit.current_action)
	assert_eq(gold(), 2)

func test_require_mode_refuses_unaffordable_move():
	game_manager.set_resource_amount(player_id, "Gold", 4)
	var unit: Unit = add_moving_unit(create_move_cost("Gold", 5, MoveCost.Mode.REQUIRE))
	var refused: Array[Unit] = game_manager.charge_move_costs()
	assert_eq(refused, [unit] as Array[Unit])
	assert_null(unit.current_action)
	assert_eq(gold(), 4)

func test_unknown_resource_refuses_move():
	var unit: Unit = add_moving_unit(create_move_cost("Stone", 1, MoveCost.Mode.CONSUME))
	game_manager.charge_move_costs()
	assert_null(unit.current_action)

func test_earlier_moves_are_paid_first_from_shared_pool():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var first: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	var second: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	var refused: Array[Unit] = game_manager.charge_move_costs()
	assert_true(first.current_action is MoveAction)
	assert_eq(refused, [second] as Array[Unit])
	assert_eq(gold(), 2)

func test_unit_without_move_cost_moves_free():
	var unit: Unit = add_moving_unit(null)
	assert_eq(game_manager.charge_move_costs().size(), 0)
	assert_true(unit.current_action is MoveAction)

func test_unit_without_queued_move_is_not_charged():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var unit: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	unit.current_action = null
	game_manager.charge_move_costs()
	assert_eq(gold(), 5)


func test_negative_cost_gives_nothing():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var unit: Unit = add_moving_unit(create_move_cost("Gold", -4, MoveCost.Mode.CONSUME))
	game_manager.charge_move_costs()
	assert_true(unit.current_action is MoveAction)
	assert_eq(gold(), 5)

func test_pay_ignores_resource_named_none():
	game_def.resources = ["Gold", ConsumeProduce.NO_RESOURCE]
	game_manager.set_resource_amount(player_id, ConsumeProduce.NO_RESOURCE, 0)
	game_manager.pay(player_id, ConsumeProduce.NO_RESOURCE, 2)
	assert_eq(game_manager.get_game_state().get_resource_amount(player_id, ConsumeProduce.NO_RESOURCE), 0)


#Whole single-player turn (the server calls charge_move_costs at the same point)
func test_turn_moves_paid_unit_and_keeps_refused_unit_in_place():
	game_manager.set_resource_amount(player_id, "Gold", 4)
	var paid: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME), Vector2i(0, 0))
	var refused: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME), Vector2i(0, 2))
	var positions: Array[Vector2i] = run_local_turn([paid, refused] as Array[Unit])
	assert_eq(positions, [Vector2i(1, 0), Vector2i(0, 2)] as Array[Vector2i])
	assert_eq(gold(), 1)

func test_turn_charges_before_require_only_check():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var consumer: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME), Vector2i(0, 0))
	var requirer: Unit = add_moving_unit(create_move_cost("Gold", 5, MoveCost.Mode.REQUIRE), Vector2i(0, 2))
	var positions: Array[Vector2i] = run_local_turn([consumer, requirer] as Array[Unit])
	assert_eq(positions, [Vector2i(1, 0), Vector2i(0, 2)] as Array[Vector2i])
	assert_eq(gold(), 2)


#can_afford_move (client hint)
func test_hint_refuses_move_that_would_break_an_ordered_move():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	var consumer: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME), Vector2i(0, 0))
	consumer.current_action = null
	add_moving_unit(create_move_cost("Gold", 5, MoveCost.Mode.REQUIRE), Vector2i(0, 2))
	assert_false(game_manager.can_afford_move(consumer))

func test_hint_matches_turn_for_require_after_consume():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME), Vector2i(0, 0))
	var requirer: Unit = add_moving_unit(create_move_cost("Gold", 5, MoveCost.Mode.REQUIRE), Vector2i(0, 2))
	assert_false(game_manager.can_afford_move(requirer))
	assert_true(game_manager.charge_move_costs().has(requirer))

func test_hint_allows_move_that_fits():
	game_manager.set_resource_amount(player_id, "Gold", 8)
	add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME), Vector2i(0, 0))
	var requirer: Unit = add_moving_unit(create_move_cost("Gold", 5, MoveCost.Mode.REQUIRE), Vector2i(0, 2))
	requirer.current_action = null
	assert_true(game_manager.can_afford_move(requirer))
	assert_eq(gold(), 8)
func test_can_afford_move_counts_queued_moves():
	game_manager.set_resource_amount(player_id, "Gold", 5)
	add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	var second: Unit = add_moving_unit(create_move_cost("Gold", 3, MoveCost.Mode.CONSUME))
	second.current_action = null
	assert_false(game_manager.can_afford_move(second))


#Loading
func test_unit_type_reads_move_cost_from_resource():
	var unit_resource: UnitResource = UnitResource.new()
	unit_resource.set_attribute("name", "Knight")
	unit_resource.set_attribute("description", "")
	unit_resource.set_attribute("is_production_unit", false)
	unit_resource.set_attribute("is_producible_unit", false)
	unit_resource.set_attribute("production_cost", 1)
	for a : String in UnitType.attribute_conversion_table.keys():
		unit_resource.set_attribute(a, 1)
	unit_resource.save_actions([create_move_cost("Gold", 3, MoveCost.Mode.REQUIRE)] as Array[Action])
	var unit_type: UnitType = UnitType.initFromUnitResource(unit_resource)
	assert_not_null(unit_type.move_cost)
	assert_eq(unit_type.move_cost.amount, 3)

func test_old_game_file_loads_without_move_costs():
	var old_game: GameDefinitionResource = load(OLD_GAME_FILE)
	assert_not_null(old_game)
	var manager: GameDataManager = GameDataManager.initFromGameDefinition(old_game)
	assert_gt(manager.get_game_defintion().unit_types.size(), 0)
	for unit_type in manager.get_game_defintion().unit_types.values():
		assert_null(unit_type.move_cost, "%s should have no move cost" % unit_type.unit_name)
	assert_eq(manager.charge_move_costs().size(), 0)

func test_move_cost_survives_save_and_load():
	var unit_resource: UnitResource = UnitResource.new()
	unit_resource.save_actions([create_move_cost("Gold", 7, MoveCost.Mode.REQUIRE)] as Array[Action])
	var game: GameDefinitionResource = GameDefinitionResource.new()
	game.save_units([unit_resource] as Array[UnitResource])
	assert_eq(ResourceSaver.save(game, ROUND_TRIP_FILE), OK)

	var loaded: GameDefinitionResource = ResourceLoader.load(ROUND_TRIP_FILE, "", ResourceLoader.CACHE_MODE_IGNORE)
	var cost: MoveCost = loaded.load_units()[0].load_actions()[0]
	assert_eq(cost.cost_resource, "Gold")
	assert_eq(cost.amount, 7)
	assert_eq(cost.mode, MoveCost.Mode.REQUIRE)
	assert_eq(cost.charge, MoveCost.Charge.PER_ORDER)
