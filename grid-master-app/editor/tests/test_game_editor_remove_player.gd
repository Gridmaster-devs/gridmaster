extends GutTest

const GAME_EDITOR_SCENE: PackedScene = preload("res://editor/editors/game_editor/GameEditor.tscn")
const EDITOR_MAIN_SCENE: PackedScene = preload("res://editor/editors/editor_main/EditorMain.tscn")

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
