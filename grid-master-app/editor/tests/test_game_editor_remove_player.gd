extends GutTest

const GAME_EDITOR_SCENE: PackedScene = preload("res://editor/editors/game_editor/GameEditor.tscn")

func test_removing_middle_player_erases_only_their_units_and_keeps_arrays_aligned() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	var player_a_ui := editor._add_new_player()
	var player_b_ui := editor._add_new_player()
	var player_c_ui := editor._add_new_player()
	autoqfree(player_b_ui)
	editor._players[0].set_name("A")
	editor._players[1].set_name("B")
	editor._players[2].set_name("C")
	var unit_layer: MapLayer = editor._unit_painter.layers[editor._unit_layer_id]
	var terrain_layer: MapLayer = editor._unit_painter.layers[editor._base_layer_id]
	unit_layer._attribute_grid.setItem(0, 0, {"unit": "infantry", "player": "A"})
	unit_layer._attribute_grid.setItem(1, 0, {"unit": "cavalry", "player": "A"})
	unit_layer._attribute_grid.setItem(2, 0, {"unit": "infantry", "player": "B"})
	terrain_layer._attribute_grid.setItem(0, 0, {"name": "forest"})
	terrain_layer._attribute_grid.setItem(1, 0, {"name": "plain"})
	editor._unit_painter._input_state = MapPainter.InputState.PAINT
	editor._unit_painter._overwrite_attribute_list = {"unit": "infantry", "player": "A"}

	editor._remove_player(player_b_ui)

	assert_eq(editor._unit_painter._input_state, MapPainter.InputState.INTERACT)
	assert_eq(unit_layer._attribute_grid.getItem(0, 0), {"unit": "infantry", "player": "A"})
	assert_eq(unit_layer._attribute_grid.getItem(1, 0), {"unit": "cavalry", "player": "A"})
	assert_eq(unit_layer._attribute_grid.getItem(2, 0), {})
	assert_eq(terrain_layer._attribute_grid.getItem(0, 0), {"name": "forest"})
	assert_eq(terrain_layer._attribute_grid.getItem(1, 0), {"name": "plain"})
	assert_eq(editor._players.size(), 2)
	assert_eq(editor._player_uis.size(), 2)
	assert_eq(editor._players[0].get_name(), "A")
	assert_eq(editor._players[1].get_name(), "C")

	editor._players[1].set_name("C edited")
	editor._add_new_player()
	assert_eq(editor._players.size(), 3)
	assert_eq(editor._player_uis.size(), 3)
	assert_eq(editor._players[1].get_name(), "C edited")
	assert_true(is_instance_valid(player_a_ui))
	assert_true(is_instance_valid(player_c_ui))
