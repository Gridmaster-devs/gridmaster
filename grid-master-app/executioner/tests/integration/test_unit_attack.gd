extends GutTest

const GAME_DEF_PATH = "res://executioner/test_resources/TestGame5x5.tres"
var game_master: GameMaster
var last_message: String

func before_each():
	var game_def = preload(GAME_DEF_PATH)
	var scene = preload("res://executioner/main/game_master/GameMaster.tscn")
	var instance = scene.instantiate()
	add_child(instance)
	game_master = instance
	game_master.load_game_definition(game_def)

func after_each():
	game_master.queue_free()
	game_master = null

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func emit_click_at(coords: Vector2i) -> void:
	var event = GridTileClickedEvent.new(MOUSE_BUTTON_LEFT, coords)
	game_master.receive_ui_event(event)
	await wait(1)

func _capture_message(message: String) -> void:
	last_message = message

# Tests unit fight
func test_unit_attack():
	# Select unit at (0, 0)
	await emit_click_at(Vector2i(0, 0))
	# Move unit to (2, 2)
	await emit_click_at(Vector2i(2, 2))
	await emit_click_at(Vector2i(2, 2))
	# Select unit at (0, 4)
	await emit_click_at(Vector2i(0, 4))
	# Try to move unit to (2, 2)
	await emit_click_at(Vector2i(2, 2))
	await emit_click_at(Vector2i(2, 2))
	
	MessageDispatcher.message_broadcast.connect(_capture_message)
	
	# End turn
	var end_turn_event = ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.END_TURN)
	game_master.receive_ui_event(end_turn_event)
	await wait(1)

	var other_unit_pos: Vector2i = game_master.data_manager.get_units().get(2).getPosition()
	
	# Check that a fight happened
	assert_true(last_message.contains("[Unit 1 : T1] attacked [Unit 3 : T2]"))
	# Check that other unit did not move
	assert_eq(other_unit_pos, Vector2i(0, 4), "Unit position should still be at (0, 4)")
