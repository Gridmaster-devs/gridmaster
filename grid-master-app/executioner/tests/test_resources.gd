extends GutTest

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


#Helper function to add a unit that consumes and produces resources
func add_unit(consumed: String, consumed_amount: int, produced: String, produced_amount: int) -> Unit:
	var unit_type: UnitType = UnitType.debugType()
	var cp: ConsumeProduce = ConsumeProduce.new()
	cp.consumed_resource = consumed
	cp.consumed_amount = consumed_amount
	cp.produced_resource = produced
	cp.produced_amount = produced_amount
	unit_type.consume_produce_actions.append(cp)
	return game_state.addUnit(unit_type, Vector2i(0, 0), game_def.players.get(player_id))

#Test that players start with none of every resource
func test_players_start_with_no_resources():
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 0, "Wood": 0})

#Test that a unit that consumes nothing produces every turn
func test_unit_produces_resource():
	add_unit(ConsumeProduce.NO_RESOURCE, 0, "Gold", 2)
	game_manager.process_resources()
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id)["Gold"], 4)

#Test that a unit consumes a resource to produce another
func test_unit_consumes_resource():
	game_manager.set_resource_amount(player_id, "Wood", 3)
	add_unit("Wood", 2, "Gold", 1)
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 1, "Wood": 1})

#Test that a unit doesn't produce if the player can't pay for it
func test_unit_does_not_produce_without_resources():
	game_manager.set_resource_amount(player_id, "Wood", 1)
	add_unit("Wood", 2, "Gold", 1)
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 0, "Wood": 1})

#Test that resources the game doesn't define are ignored
func test_undefined_resource_is_ignored():
	add_unit(ConsumeProduce.NO_RESOURCE, 0, "Stone", 5)
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 0, "Wood": 0})

#Test that resources are kept when the game state is copied
func test_resources_survive_deep_copy():
	game_manager.set_resource_amount(player_id, "Gold", 7)
	var copy: GameState = game_state.deep_copy()
	assert_eq(copy.get_resource_amount(player_id, "Gold"), 7)
