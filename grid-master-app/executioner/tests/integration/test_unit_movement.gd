extends GutTest

const GAME_DEF_PATH = "res://executioner/test_resources/TestGame2x2.tres"
var game_master: GameMaster

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

# Test unit movement
func test_unit_movement():
	# Select unit at (0, 0)
	await emit_click_at(Vector2i(0, 0))
	# Move unit to (1, 1)
	await emit_click_at(Vector2i(1, 1))
	await emit_click_at(Vector2i(1, 1))
	# Select unit at (0, 1)
	await emit_click_at(Vector2i(0, 1))
	# Move unit to (1, 0)
	await emit_click_at(Vector2i(1, 0))
	await emit_click_at(Vector2i(1, 0))
	
	# End turn
	var end_turn_event = ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.END_TURN)
	game_master.receive_ui_event(end_turn_event)
	await wait(1)
	
	var unit_pos: Vector2i = game_master.data_manager.get_units().get(1).getPosition()
	var other_unit_pos = game_master.data_manager.get_units().get(2).getPosition()
	
	# Check that both units moved correctly
	assert_eq(unit_pos, Vector2i(1, 1), "Unit position should be at (1, 1)")
	assert_eq(other_unit_pos, Vector2i(1, 0), "Unit position should be at (1, 0)")
