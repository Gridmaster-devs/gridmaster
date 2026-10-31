extends GutTest

const GAME_EDITOR_SCENE: PackedScene = preload("res://editor/editors/game_editor/GameEditor.tscn")
const EDITOR_MAIN_SCENE: PackedScene = preload("res://editor/editors/editor_main/EditorMain.tscn")

func _edit_player_name(player_ui: PlayerUi, player_name: String) -> void:
	player_ui._player_name_ui.text = player_name
	player_ui._player_name_ui.text_changed.emit(player_name)

func test_removing_middle_player_erases_only_their_units_and_keeps_arrays_aligned() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	var player_a_ui := editor._add_new_player()
	var player_b_ui := editor._add_new_player()
	var player_c_ui := editor._add_new_player()
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
	await get_tree().process_frame
	assert_false(is_instance_valid(player_b_ui))

func test_reject_duplicate_player_name_before_removal_can_erase_survivors_units() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	var original_player_ui := editor._add_new_player()
	var duplicate_player_ui := editor._add_new_player()
	_edit_player_name(original_player_ui, "A")
	var previous_name: String = editor._players[1].get_name()
	var unit_layer: MapLayer = editor._unit_painter.layers[editor._unit_layer_id]
	unit_layer._attribute_grid.setItem(0, 0, {"unit": "infantry", "player": "A"})

	_edit_player_name(duplicate_player_ui, "A")

	assert_eq(editor._players[1].get_name(), previous_name)
	assert_eq(duplicate_player_ui._player_name_ui.text, previous_name)
	editor._remove_player(duplicate_player_ui)

	assert_eq(unit_layer._attribute_grid.getItem(0, 0), {"unit": "infantry", "player": "A"})
	await get_tree().process_frame
	assert_false(is_instance_valid(duplicate_player_ui))

func test_new_players_have_unique_nonblank_names_and_reject_blank_renames() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	var first_ui := editor._add_new_player()
	var first_name: String = editor._players[0].get_name()
	# A user-chosen name must also be excluded when generating the next default.
	_edit_player_name(first_ui, "Player 2")
	var second_ui := editor._add_new_player()
	var second_name: String = editor._players[1].get_name()
	assert_false(first_name.strip_edges().is_empty())
	assert_false(second_name.strip_edges().is_empty())
	assert_ne(second_name, "Player 2")
	assert_eq(first_ui.export().get_player_name(), "Player 2")
	assert_eq(second_ui.export().get_player_name(), second_name)
	for invalid_name in ["", " ", "\t"]:
		_edit_player_name(second_ui, invalid_name)
		assert_eq(editor._players[1].get_name(), second_name)
		assert_eq(second_ui.export().get_player_name(), second_name)
	_edit_player_name(second_ui, second_name)
	assert_eq(editor._players[1].get_name(), second_name, "Keeping one's own name is allowed")
	editor._remove_player(first_ui)
	var third_ui := editor._add_new_player()
	assert_ne(third_ui.export().get_player_name(), second_name)
	assert_false(third_ui.export().get_player_name().strip_edges().is_empty())

func test_rename_moves_ownership_before_the_old_name_can_be_reused_and_deleted() -> void:
	var editor_main := EDITOR_MAIN_SCENE.instantiate() as EditorMain
	add_child_autofree(editor_main)
	var editor: GameEditor = editor_main.game_editor
	var image := Image.create_empty(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var unit := UnitResource.new()
	unit.set_attribute("name", "infantry")
	unit.set_attribute("texture", ImageTexture.create_from_image(image))
	editor_main.set_units([unit])
	var team_ui := editor._add_new_team()
	team_ui._team_name_ui.text = "T"
	team_ui._team_name_ui.text_changed.emit("T")
	team_ui._unit_checked("infantry")
	var original_ui := editor._add_new_player()
	_edit_player_name(original_ui, "A")
	original_ui._team_checked("T")
	editor._sync_player_libraries()
	var painter: MapPainter = editor._unit_painter
	var tile: Dictionary[String, Variant] = painter._lib_items_data["A"][0].duplicate()
	var unit_layer: MapLayer = painter.layers[editor._unit_layer_id]
	unit_layer._attribute_grid.setItem(0, 0, tile)
	unit_layer.update_tile_map()
	painter.on_lib_item_pressed({}, tile, true, editor._unit_layer_id)

	_edit_player_name(original_ui, "B")

	assert_eq(tile[MapAttributes.UNIT_PLAYER_ID], "B")
	assert_eq(tile[MapAttributes.UNIT_UNIT_LIB_ITEM_ID], "infantry")
	assert_true(tile.has(MapAttributes.UNIT_TEXTURE_ID))
	assert_true(painter._paint_libraries.has("B"))
	assert_false(painter._paint_libraries.has("A"))
	assert_eq(painter._input_state, MapPainter.InputState.INTERACT)
	var replacement_ui := editor._add_new_player()
	_edit_player_name(replacement_ui, "A")
	editor._remove_player(replacement_ui)
	assert_eq(unit_layer._attribute_grid.getItem(0, 0), tile)
	assert_eq(tile[MapAttributes.UNIT_PLAYER_ID], "B")
	editor._remove_player(original_ui)
	assert_eq(unit_layer._attribute_grid.getItem(0, 0), {})

func test_import_rejects_duplicate_or_blank_names_before_changing_editor_state() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	editor.set_game_name("Keep this game")
	var original_ui := editor._add_new_player()
	var original_name: String = editor._players[0].get_name()
	var unit_grid: Array2D = editor._unit_painter.get_layer(editor._unit_layer_id)
	unit_grid.setItem(0, 0, {"unit": "infantry", "player": original_name})
	for names in [["A", "A"], [""], ["   "]]:
		var resource := GameDefinitionResource.new()
		resource.game_name = "Invalid import"
		for player_name in names:
			var player_resource := PlayerUiRes.new()
			player_resource.init({}, player_name)
			resource.player_uis.append(player_resource)

		var error_count_before := get_errors().size()
		editor.load_from_resource(resource)
		var import_errors: Array = get_errors().slice(error_count_before)
		assert_eq(import_errors.size(), 1, "Each rejected import should report one warning")
		for import_error in import_errors:
			if import_error.is_engine_error() and import_error.code == "Cannot load game: player names must be nonblank and unique.":
				import_error.handled = true

		assert_eq(editor.get_game_name(), "Keep this game")
		assert_eq(editor._player_uis, [original_ui])
		assert_eq(editor._players[0].get_name(), original_name)
		assert_eq(unit_grid.getItem(0, 0), {"unit": "infantry", "player": original_name})

func test_import_preserves_saved_ownership_when_names_overlap_generated_defaults() -> void:
	var editor_main := EDITOR_MAIN_SCENE.instantiate() as EditorMain
	add_child_autofree(editor_main)
	var editor: GameEditor = editor_main.game_editor
	editor._add_new_player()
	var resource := GameDefinitionResource.new()
	resource.game_name = "Imported game"
	resource.map = editor_main.getMap()
	resource.unit_layer = Array2D.new()
	resource.unit_layer.init(2, 1)
	resource.unit_layer.setItem(0, 0, {"unit": "infantry", "player": "A"})
	resource.unit_layer.setItem(1, 0, {"unit": "infantry", "player": "Player 1"})
	for player_name in ["A", "Player 1"]:
		var player_resource := PlayerUiRes.new()
		player_resource.init({}, player_name)
		resource.player_uis.append(player_resource)

	editor.load_from_resource(resource)

	assert_eq(editor._players[0].get_name(), "A")
	assert_eq(editor._players[1].get_name(), "Player 1")
	assert_eq(editor._player_uis[0].export().get_player_name(), "A")
	assert_eq(editor._player_uis[1].export().get_player_name(), "Player 1")
	var unit_grid: Array2D = editor._unit_painter.get_layer(editor._unit_layer_id)
	assert_eq(unit_grid.getItem(0, 0)["player"], "A")
	assert_eq(unit_grid.getItem(1, 0)["player"], "Player 1")
	assert_eq(resource.unit_layer.getItem(1, 0)["player"], "Player 1")

func test_removing_team_unassigns_players_clears_key_units_and_erases_their_units() -> void:
	var editor_main := EDITOR_MAIN_SCENE.instantiate() as EditorMain
	add_child_autofree(editor_main)
	var editor: GameEditor = editor_main.game_editor
	var team_ui := preload("res://editor/editors/game_editor/team_ui.tscn").instantiate() as TeamUi
	editor._teams_container.add_child(team_ui)
	team_ui._team_name_ui.text = "T"
	team_ui.init_units(["infantry"])
	var removed_unit_checkbox: LabelCheckbox = team_ui._unit_uis["infantry"]
	team_ui.sync_units(["cavalry"])
	var other_team_ui := preload("res://editor/editors/game_editor/team_ui.tscn").instantiate() as TeamUi
	editor._teams_container.add_child(other_team_ui)
	other_team_ui._team_name_ui.text = "U"
	other_team_ui.init_units([])
	var team := GameTeam.new("T", Color.RED, 0, ["infantry", "cavalry"])
	var other_team := GameTeam.new("U", Color.BLUE, 1, ["spear"])
	editor._team_uis.append(team_ui)
	editor._team_uis.append(other_team_ui)
	editor._teams.append(team)
	editor._teams.append(other_team)
	var player_a_ui := editor._add_new_player()
	var player_b_ui := editor._add_new_player()
	var player_c_ui := editor._add_new_player()
	editor._players[0].set_name("A")
	editor._players[1].set_name("B")
	editor._players[2].set_name("C")
	editor._players[0].set_team(team)
	editor._players[1].set_team(team)
	editor._players[2].set_team(other_team)
	player_a_ui._teams["T"] = true
	player_b_ui._teams["T"] = true
	player_c_ui._teams["U"] = true
	var removed_team_checkbox: LabelCheckbox = player_a_ui._team_uis["T"]
	for player_ui in [player_a_ui, player_b_ui, player_c_ui]:
		var key_unit_option: OptionButton = player_ui._get_key_unit_option()
		key_unit_option.add_item("spear" if player_ui == player_c_ui else "infantry")
		key_unit_option.select(1)
	var unit_layer: MapLayer = editor._unit_painter.layers[editor._unit_layer_id]
	unit_layer._attribute_grid.setItem(0, 0, {"unit": "infantry", "player": "A"})
	unit_layer._attribute_grid.setItem(1, 0, {"unit": "cavalry", "player": "B"})
	unit_layer._attribute_grid.setItem(2, 0, {"unit": "infantry", "player": "C"})
	var terrain_layer: MapLayer = editor._unit_painter.layers[editor._base_layer_id]
	terrain_layer._attribute_grid.setItem(0, 0, {"name": "forest"})
	editor._unit_painter._input_state = MapPainter.InputState.PAINT

	editor._remove_team(team_ui)

	assert_eq(editor._teams, [other_team])
	assert_eq(editor._team_uis, [other_team_ui])
	assert_eq(editor._players[0].get_team(), null)
	assert_eq(editor._players[1].get_team(), null)
	assert_eq(editor._players[2].get_team(), other_team)
	assert_eq(player_a_ui.get_selected_team_name(), "")
	assert_eq(player_b_ui.get_selected_team_name(), "")
	assert_eq(player_c_ui.get_selected_team_name(), "U")
	assert_eq(player_a_ui._get_selected_key_unit_name(), "")
	assert_eq(player_b_ui._get_selected_key_unit_name(), "")
	assert_eq(player_c_ui._get_selected_key_unit_name(), "spear")
	assert_eq(unit_layer._attribute_grid.getItem(0, 0), {})
	assert_eq(unit_layer._attribute_grid.getItem(1, 0), {})
	assert_eq(unit_layer._attribute_grid.getItem(2, 0), {"unit": "infantry", "player": "C"})
	assert_eq(terrain_layer._attribute_grid.getItem(0, 0), {"name": "forest"})
	assert_eq(editor._unit_painter._input_state, MapPainter.InputState.INTERACT)
	await get_tree().process_frame
	assert_false(is_instance_valid(team_ui))
	assert_false(is_instance_valid(removed_team_checkbox))
	assert_false(is_instance_valid(removed_unit_checkbox))

func test_removing_team_without_assigned_players_succeeds() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	var team_ui := preload("res://editor/editors/game_editor/team_ui.tscn").instantiate() as TeamUi
	editor._teams_container.add_child(team_ui)
	team_ui._team_name_ui.text = "Empty team"
	team_ui.init_units([])
	editor._team_uis.append(team_ui)
	editor._teams.append(GameTeam.new("Empty team", Color.RED, 0, []))

	editor._remove_team(team_ui)

	assert_eq(editor._teams, [])
	assert_eq(editor._team_uis, [])
	await get_tree().process_frame
	assert_false(is_instance_valid(team_ui))

func test_clear_player_and_team_panels_queues_all_nodes_for_deletion() -> void:
	var editor := GAME_EDITOR_SCENE.instantiate() as GameEditor
	add_child_autofree(editor)
	var player_ui := editor._add_new_player()
	var team_ui := preload("res://editor/editors/game_editor/team_ui.tscn").instantiate() as TeamUi
	editor._teams_container.add_child(team_ui)
	team_ui.init_units(["infantry"])
	editor._team_uis.append(team_ui)
	editor._teams.append(GameTeam.new("Test team", Color.RED, 0, ["infantry"]))
	var team_checkbox: LabelCheckbox = team_ui._unit_uis["infantry"]
	var player_node: PlayerUi = player_ui
	var team_node: TeamUi = team_ui

	editor._clear_players()
	editor._clear_teams()
	assert_eq(editor._player_uis, [])
	assert_eq(editor._players, [])
	assert_eq(editor._team_uis, [])
	assert_eq(editor._teams, [])
	await get_tree().process_frame
	assert_false(is_instance_valid(player_node))
	assert_false(is_instance_valid(team_node))
	assert_false(is_instance_valid(team_checkbox))
