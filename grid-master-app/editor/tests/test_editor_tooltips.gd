extends GutTest

func test_registry_and_warning_set() -> void:
	var count := 0
	var warnings := 0
	for context in EditorTooltips.TEXT:
		for key in EditorTooltips.TEXT[context]:
			count += 1
			var tip := EditorTooltips.get_tooltip(context, key)
			assert_false(tip.is_empty())
			for status in ["Currently used", "Display only", "Editor only"]:
				assert_false(status in tip)
			if EditorTooltips.has_warning(context, key):
				warnings += 1
	assert_eq(count, 77)
	assert_eq(warnings, 11)
	assert_eq(EditorTooltips.WARNING_TEXT, "Not yet used in gameplay")
	assert_eq(EditorTooltips.get_tooltip("unit", "health"), "How much damage the unit can take before being destroyed.")
	assert_eq(EditorTooltips.get_tooltip("game", "player_key_unit"), "The unit type this player must keep alive to avoid elimination. Leave blank to count any surviving unit.")
	assert_eq(EditorTooltips.get_tooltip("unit", "missing"), "")
	assert_eq(EditorTooltips.get_tooltip("map", "name"), "")
	assert_false(EditorTooltips.has_warning("unit", "health"))
	assert_false(EditorTooltips.has_warning("unit", "morale"))
	assert_false(EditorTooltips.has_warning("map", "save_map"))

func test_label_warning_is_separate_and_idempotent() -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	var input := LineEdit.new()
	label.text = "Producible"
	input.text = "preserved"
	row.add_child(label)
	row.add_child(input)
	add_child_autofree(row)
	TooltipHelper.apply(label, "unit", "is_producible_unit")
	TooltipHelper.apply(label, "unit", "is_producible_unit")
	assert_eq(label.tooltip_text, EditorTooltips.get_tooltip("unit", "is_producible_unit"))
	assert_ne(label.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(input.tooltip_text, "")
	assert_eq(input.text, "preserved")
	assert_eq(label.get_child_count(), 1)
	assert_eq(label.get_child(0).tooltip_text, EditorTooltips.WARNING_TEXT)
	assert_eq(row.get_child(1), input)

func test_action_fields_have_separate_warnings() -> void:
	var panel = load("res://editor/editors/unit_editor/Action panels/ConsumeProducePanel.tscn").instantiate()
	add_child_autofree(panel)
	for group in ["Consumes", "Produces"]:
		var row = panel.get_node(group)
		var count := 0
		for child in row.get_children():
			if child is Label and child.has_node("UnusedFeatureWarning"):
				count += 1
		assert_eq(count, 2)
		assert_eq(row.get_node("ResourceAmount").tooltip_text, "")
		assert_eq(row.get_node("ResourceName").tooltip_text, "")

func test_generated_team_and_player_rows_use_context() -> void:
	var team = load("res://editor/editors/game_editor/team_ui.tscn").instantiate()
	var player = load("res://editor/editors/game_editor/player_ui.tscn").instantiate()
	add_child_autofree(team)
	add_child_autofree(player)
	team.init_units(["Infantry"])
	player.init_teams(["Blue"])
	var team_label: Label = team._unit_uis["Infantry"].get_node("TeamUnitType/HBoxContainer/Label")
	var player_label: Label = player._team_uis["Blue"].get_node("TeamUnitType/HBoxContainer/Label")
	assert_eq(team_label.tooltip_text, EditorTooltips.get_tooltip("game", "team_unit_selection"))
	assert_true(team_label.has_node("UnusedFeatureWarning"))
	assert_eq(player_label.tooltip_text, EditorTooltips.get_tooltip("game", "player_team"))
	assert_false(player_label.has_node("UnusedFeatureWarning"))

func test_generated_terrain_hiding_field() -> void:
	var popup = load("res://editor/editors/map_editor_refactor/popup_windows/new_tile_popup.tscn").instantiate()
	add_child_autofree(popup)
	var attributes: Dictionary[String, Variant] = {"hiding": 0, "movement": 0}
	popup.init(attributes, "Terrain")
	var rows = popup.get_node("EditorPanel/TopVBox/ScrollContainer/ContentsVBox/AttributesVbox")
	var hiding: Label = rows.get_child(1).get_child(0)
	var movement: Label = rows.get_child(2).get_child(0)
	assert_eq(hiding.tooltip_text, EditorTooltips.get_tooltip("map", "tile.hiding"))
	assert_true(hiding.has_node("UnusedFeatureWarning"))
	assert_false(movement.has_node("UnusedFeatureWarning"))
	assert_eq(popup.get_ui_element("hiding").tooltip_text, "")

func test_editor_scenes_instantiate() -> void:
	for path in ["res://editor/editors/unit_editor/UnitEditor.tscn", "res://editor/editors/game_editor/GameEditor.tscn", "res://editor/editors/map_editor_refactor/map_editor.tscn"]:
		var editor = load(path).instantiate()
		add_child_autofree(editor)
		assert_not_null(editor)

func test_warning_keys() -> void:
	assert_eq(EditorTooltips.WARNINGS, {"unit": ["is_producible_unit", "action_name", "action_type", "consumed_resource", "consumed_amount", "produced_resource", "produced_amount"], "map": ["tile.hiding", "tactical_map"], "painter": ["crop_image"], "game": ["team_unit_selection"]})

func test_unit_description_has_no_added_label_or_tooltip() -> void:
	var panel = load("res://editor/editors/unit_editor/UnitInfoPanel.tscn").instantiate()
	add_child_autofree(panel)
	var row = panel.get_node("TopVBox/PanelContainer/ContentsVBox/HBoxContainer")
	assert_eq(row.get_child_count(), 2)
	assert_eq(panel.description_box.tooltip_text, "")
