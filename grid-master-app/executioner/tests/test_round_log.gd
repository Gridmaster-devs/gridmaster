extends GutTest

const GAME_MASTER_SCENE = preload("res://executioner/main/game_master/GameMaster.tscn")
const GAME = preload("res://Production test.tres")

# Capture the outgoing RPC without a server so the client remains waiting.
class WaitingMultiplayer extends MultiplayerAPIExtension:
	var submitted_actions: Array = []

	func _rpc(_peer: int, _object: Object, method: StringName, args: Array) -> Error:
		if method == &"end_peer_turn":
			submitted_actions.append(args[0])
		return OK


var game_master: GameMaster
var messages: Array[String] = []
var previous_game_type: Variant
var previous_popup_manager: PopupManager
var previous_multiplayer: MultiplayerAPI


func before_each():
	previous_game_type = Global.game_type
	previous_popup_manager = Global.popup_manager
	previous_multiplayer = get_tree().get_multiplayer()
	Global.game_type = Global.GameType.SINGLEPLAYER
	messages.clear()
	MessageDispatcher.message_broadcast.connect(_record_message)
	game_master = GAME_MASTER_SCENE.instantiate()
	add_child(game_master)
	# Each test needs its own atlas: GridGraphics adds sources during initialization.
	game_master.grid_graphics.tile_grid.tile_set = game_master.grid_graphics.tile_grid.tile_set.duplicate(true)


func after_each():
	MessageDispatcher.message_broadcast.disconnect(_record_message)
	# Unfinished actions hold the data manager, which also owns their units.
	if game_master.data_manager != null:
		for unit in game_master.data_manager.get_units().values():
			unit.current_action = null
	game_master.free()
	Global.game_type = previous_game_type
	Global.popup_manager = previous_popup_manager
	get_tree().set_multiplayer(previous_multiplayer)


func _record_message(message: String) -> void:
	messages.append(message)


func _log_text() -> Array[String]:
	var result: Array[String] = []
	for label in (game_master.gui_scene as InGameDefaultGUI).message_window_node.message_queue:
		result.append(label.text)
	return result


# Use the same unit fields as the server without relying on the client's turn counter.
func _state_update(completed_turns: int) -> Dictionary:
	var units: Array = []
	for unit in game_master.data_manager.get_units().values():
		units.append({
			"id": unit.getId(),
			"position": unit.grid_position,
			"hp": unit.hp,
			"player_id": unit.get_player_id(),
			"type_id": unit.type.type_id,
		})
	return {
		"turn_number": completed_turns,
		"units": units,
		"message_queue": [] as Array[String],
		"eliminated_players": [],
		"game_over": false,
	}


func _start_multiplayer(completed_turns: int) -> void:
	Global.game_type = Global.GameType.MULTIPLAYER
	# Exercise the real file-received -> state-received sequence, including GUI replacement.
	game_master._on_game_file_received(FileAccess.get_file_as_bytes("res://Production test.tres"), 1)
	game_master._on_game_state_received(_state_update(completed_turns))


func test_local_initial_round_follows_loaded_message_once():
	game_master.local_init_game(GAME)
	assert_eq(_log_text(), [
		'Game "Production Test" loaded.',
		"======= Round 1 started ==========",
	])
	assert_eq(messages, _log_text())
	assert_eq(game_master.data_manager.get_turn_number(), 0)


func test_local_completed_turns_announce_sequential_rounds_once():
	game_master.local_init_game(GAME)
	game_master.end_turn()
	game_master.end_turn()
	game_master.end_turn()
	assert_false(game_master._game_over)
	assert_eq(_log_text(), [
		'Game "Production Test" loaded.',
		"======= Round 1 started ==========",
		"======= Round 2 started ==========",
		"======= Round 3 started ==========",
		"======= Round 4 started ==========",
	])
	assert_eq(messages, _log_text())


func test_local_action_messages_precede_next_round():
	game_master.local_init_game(GAME)
	var producer: Unit = game_master.data_manager.get_units().values()[0]
	var produced_type := UnitType.new()
	produced_type.unit_name = "Test unit"
	produced_type.production_cost = 2
	producer.current_action = ProductionAction.new(producer.get_player_id(), producer, game_master.data_manager, produced_type)
	messages.clear()
	game_master.end_turn()
	# Turn processing copies units; release the action on the original unit too.
	producer.current_action = null
	assert_eq(messages, [
		"[Unit %s] producing [Test unit] (1 turns remaining)" % producer.getId(),
		"======= Round 2 started ==========",
	])


func test_local_victory_does_not_start_another_round():
	game_master.local_init_game(GAME)
	var my_id := game_master.data_manager.get_client_player_id()
	for unit in game_master.data_manager.get_units().values():
		if unit.get_player_id() != my_id:
			game_master.data_manager.remove_unit(unit)
	messages.clear()
	game_master.end_turn()
	assert_true(game_master._game_over)
	assert_gt(messages.size(), 0, "Elimination and victory messages should still be emitted")
	for message in messages:
		assert_false(message.begins_with("======= Round"))
	var final_messages := messages.duplicate()
	game_master.end_turn()
	assert_eq(messages, final_messages, "Ending an already finished game should emit nothing")


func test_multiplayer_initial_round_appears_once_in_new_gui():
	_start_multiplayer(0)
	assert_eq(_log_text(), ["======= Round 1 started =========="])
	assert_eq(messages.count("======= Round 1 started =========="), 1)


func test_multiplayer_sync_uses_server_round():
	_start_multiplayer(3)
	assert_eq(_log_text(), ["======= Round 4 started =========="])
	assert_eq(messages.count("======= Round 4 started =========="), 1)


func test_multiplayer_rejoin_announces_current_round_in_recreated_log():
	_start_multiplayer(0)
	game_master._on_game_state_received(_state_update(4))
	assert_eq(_log_text(), ["======= Round 5 started =========="])
	assert_eq(messages.count("======= Round 5 started =========="), 1)


func test_multiplayer_events_precede_next_round_once():
	_start_multiplayer(0)
	var state := _state_update(3)
	state["message_queue"] = ["[Unit 3] attacked [Unit 7]", "[Unit 4] captured [Unit 8]"] as Array[String]
	messages.clear()
	game_master._on_turn_ended(state)
	assert_eq(messages, [
		"[Unit 3] attacked [Unit 7]",
		"[Unit 4] captured [Unit 8]",
		"======= Round 4 started ==========",
	])
	assert_eq(_log_text(), ["======= Round 1 started =========="] + messages)
	game_master._on_turn_ended(_state_update(4))
	assert_eq(messages.count("======= Round 5 started =========="), 1)


func test_multiplayer_submitting_turn_waits_without_announcing_round():
	_start_multiplayer(0)
	var waiting_multiplayer := WaitingMultiplayer.new()
	get_tree().set_multiplayer(waiting_multiplayer)
	messages.clear()
	game_master.end_turn()
	assert_eq(waiting_multiplayer.submitted_actions.size(), 1, "The turn should be submitted")
	assert_eq(messages, [], "Submitting actions must wait for the server before announcing a round")
	assert_eq(_log_text(), ["======= Round 1 started =========="])
	game_master._on_turn_ended(_state_update(1))
	assert_eq(messages, ["======= Round 2 started =========="])


func test_multiplayer_game_over_preserves_events_without_next_round():
	_start_multiplayer(0)
	var state := _state_update(1)
	state["game_over"] = true
	state["winner_player_id"] = game_master.data_manager.get_client_player_id()
	state["message_queue"] = ["Player1 wins!"] as Array[String]
	messages.clear()
	game_master._on_turn_ended(state)
	assert_true(game_master._game_over)
	assert_eq(messages, ["Player1 wins!"])


func test_multiplayer_finished_initial_state_does_not_announce_round():
	game_master.local_init_game(GAME)
	var state := _state_update(3)
	state["game_over"] = true
	messages.clear()
	game_master._on_game_state_received(state)
	assert_eq(_log_text(), [])
	assert_eq(messages, [])
