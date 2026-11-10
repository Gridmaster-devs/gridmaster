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
	assert_eq(count, 78)
	assert_eq(warnings, 10)
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

func test_game_name_and_unit_placement_keep_original_layout() -> void:
	var editor = load("res://editor/editors/game_editor/GameEditor.tscn").instantiate()
	var name_line: LineEdit = editor.get_node("PanelContainer/VBoxContainer/Game name")
	var name_parent = name_line.get_parent()
	var name_children := name_parent.get_children()
	var painter = editor.get_node("PanelContainer/VBoxContainer/TabContainer/Map")
	var contents = painter.get_node("HBoxContainer/RightPanel/TopVBox/ScrollContainer/ContentsVBox")
	var contents_children: Array = contents.get_children()
	var canvas = painter.get_node("HBoxContainer/SubViewControl/SubViewportContainer")
	var canvas_filter: int = canvas.mouse_filter
	add_child_autofree(editor)
	assert_eq(name_parent.get_children(), name_children)
	assert_eq(name_line.placeholder_text, "Game name")
	assert_eq(name_line.tooltip_text, EditorTooltips.get_tooltip("game", "game_name"))
	assert_eq(contents.get_children(), contents_children)
	assert_eq(canvas.tooltip_text, EditorTooltips.get_tooltip("game", "unit_placement"))
	assert_eq(canvas.mouse_filter, canvas_filter)

func test_actions_header_has_one_warning() -> void:
	var panel = load("res://editor/editors/unit_editor/ActionPanel.tscn").instantiate()
	add_child_autofree(panel)
	var label = panel.get_node("VBoxContainer/Label")
	assert_eq(label.tooltip_text, "Define actions for this unit.")
	assert_eq(label.get_child_count(), 1)
	assert_eq(label.get_child(0).name, "UnusedFeatureWarning")
	assert_eq(label.get_child(0).tooltip_text, EditorTooltips.WARNING_TEXT)
	var text_width = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	var text_left = label.get_theme_stylebox("normal").get_content_margin(SIDE_LEFT)
	assert_almost_eq(label.get_child(0).position.x, text_left + text_width + 4, 0.01)

func test_action_name_keeps_original_layout() -> void:
	var panel = load("res://editor/editors/unit_editor/Action panels/ActionPanelItem.tscn").instantiate()
	var children: Array = panel.get_children()
	add_child_autofree(panel)
	assert_eq(panel.get_children(), children)
	assert_eq(panel.action_name_line.placeholder_text, "Action name")
	assert_eq(panel.action_name_line.tooltip_text, EditorTooltips.get_tooltip("unit", "action_name"))
	assert_false(panel.get_node("HBoxContainer/Label").has_node("UnusedFeatureWarning"))
	assert_eq(panel.get_node("HBoxContainer/Label").tooltip_text, EditorTooltips.get_tooltip("unit", "action_type"))
	assert_false(panel.action_name_line.has_node("UnusedFeatureWarning"))
	TooltipHelper.apply(panel.action_name_line, "unit", "action_name", false)
	assert_eq(panel.get_children(), children)
	assert_eq(panel.action_name_line.tooltip_text, EditorTooltips.get_tooltip("unit", "action_name"))

func test_action_fields_keep_original_rows_without_warnings() -> void:
	var panel = load("res://editor/editors/unit_editor/Action panels/ConsumeProducePanel.tscn").instantiate()
	add_child_autofree(panel)
	for fields in [["Consumes", "consumed_amount", "consumed_resource"], ["Produces", "produced_amount", "produced_resource"]]:
		var row = panel.get_node(fields[0])
		assert_eq(row.get_child_count(), 3)
		assert_eq(row.get_child(0), row.get_node(fields[0]))
		for field in [["ResourceAmount", fields[1]], ["ResourceName", fields[2]]]:
			var input = row.get_node(field[0])
			assert_eq(input.tooltip_text, EditorTooltips.get_tooltip("unit", field[1]))
			assert_false(input.has_node("UnusedFeatureWarning"))
			TooltipHelper.apply(input, "unit", field[1], false)
			assert_eq(input.tooltip_text, EditorTooltips.get_tooltip("unit", field[1]))
		assert_eq(row.get_child(1), row.get_node("ResourceAmount"))
		assert_eq(row.get_child(2), row.get_node("ResourceName"))
		assert_eq(row.get_child_count(), 3)

func test_unit_image_keeps_original_layout() -> void:
	var panel = load("res://editor/editors/unit_editor/UnitInfoPanel.tscn").instantiate()
	var column = panel.get_node("TopVBox/PanelContainer/ContentsVBox/HBoxContainer/VBoxContainer")
	var children: Array = column.get_children()
	var image: TextureRect = column.get_node("PanelContainer/ImageContainer")
	var image_filter := image.mouse_filter
	add_child_autofree(panel)
	assert_eq(column.get_children(), children)
	assert_eq(image.tooltip_text, EditorTooltips.get_tooltip("unit", "texture"))
	assert_eq(image.mouse_filter, image_filter)
	assert_eq(panel.name_line.placeholder_text, "Unit name")

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
	assert_false(team_label.has_node("UnusedFeatureWarning"))
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
	assert_eq(EditorTooltips.WARNINGS, {"unit": ["movement_type", "capturable", "victory_points", "perception", "is_producible_unit", "actions", "attack_range"], "map": ["tile.hiding", "tactical_map"], "painter": ["crop_image"]})

func test_unit_description_has_no_added_label_or_tooltip() -> void:
	var panel = load("res://editor/editors/unit_editor/UnitInfoPanel.tscn").instantiate()
	add_child_autofree(panel)
	var row = panel.get_node("TopVBox/PanelContainer/ContentsVBox/HBoxContainer")
	assert_eq(row.get_child_count(), 2)
	assert_eq(panel.description_box.tooltip_text, "")
