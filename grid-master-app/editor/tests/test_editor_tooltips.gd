extends GutTest

const BUTTON_STATES := ["normal", "hover", "pressed", "disabled", "hover_pressed"]


func after_each() -> void:
	EditorThemes.apply(false)
	await wait_process_frames(2)


func _themed_button(variation: StringName = &"") -> Button:
	var button := Button.new()
	button.theme = EditorThemes.ACTIVE
	button.theme_type_variation = variation
	button.text = "Movement"
	add_child_autofree(button)
	return button


func _assert_warning_styles(button: Button, original: Button) -> void:
	for state in BUTTON_STATES:
		var expected := original.get_theme_stylebox(state) as StyleBoxFlat
		var actual := button.get_theme_stylebox(state) as StyleBoxFlat
		assert_not_null(actual, state)
		if actual == null:
			continue
		assert_true(button.has_theme_stylebox_override(state), state)
		assert_ne(actual, expected, "%s must duplicate the theme resource" % state)
		assert_eq(actual.bg_color, expected.bg_color, "%s background" % state)
		assert_eq(actual.get_content_margin(SIDE_RIGHT), expected.get_content_margin(SIDE_RIGHT) + 18.0, "%s padding" % state)
	assert_false(button.has_theme_stylebox_override("focus"))
	assert_same(button.get_theme_stylebox("focus"), original.get_theme_stylebox("focus"))


func _check_warning_theme_switches(modes: Array, variation: StringName = &"") -> void:
	EditorThemes.apply(modes[0])
	var button := _themed_button(variation)
	var original := _themed_button(variation)
	TooltipHelper.apply(button, "unit", "movement_type")
	var warning := button.get_node("UnusedFeatureWarning") as Control
	assert_not_null(warning)
	assert_eq(warning.tooltip_text, EditorTooltips.WARNING_TEXT)
	assert_eq(button.tooltip_text, EditorTooltips.get_tooltip("unit", "movement_type"))
	var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	assert_eq(warning.anchor_left, 0.5)
	assert_eq(warning.anchor_top, 0.5)
	assert_eq(warning.offset_left, text_width / 2 - 5)
	assert_eq(warning.offset_right, text_width / 2 + 9)
	assert_eq(warning.offset_top, -7.0)
	assert_eq(warning.offset_bottom, 7.0)
	_assert_warning_styles(button, original)
	for mode in modes:
		EditorThemes.apply(mode)
		await wait_process_frames(2)
		_assert_warning_styles(button, original)
		# A refresh must settle rather than keep replacing overrides every frame.
		var settled := button.get_theme_stylebox("normal")
		await wait_process_frames(2)
		assert_same(button.get_theme_stylebox("normal"), settled)


# Isolate GUI hit testing from the GUT runner's own controls.
func _warning_input_viewport(control: Control) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 240)
	viewport.gui_embed_subwindows = true
	add_child_autofree(viewport)
	control.theme = EditorThemes.ACTIVE
	control.position = Vector2(40, 40)
	control.size = Vector2(260, 44)
	viewport.add_child(control)
	TooltipHelper.apply(control, "unit", "movement_type")
	viewport.notify_mouse_entered()
	return viewport


func _move_mouse(viewport: SubViewport, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)


func _assert_hover_tooltip(viewport: SubViewport, control: Control, expected: String) -> void:
	_move_mouse(viewport, control.get_global_rect().get_center())
	assert_same(viewport.gui_get_hovered_control(), control)
	# Wait for the engine's tooltip timer, rather than calling show_tooltip().
	await wait_seconds(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec")) + 0.1)
	var popups := control.find_children("*", "PopupPanel", false, false)
	assert_eq(popups.size(), 1, "Hover must display a tooltip popup")
	if popups.size() == 1:
		var popup := popups[0] as PopupPanel
		assert_true(popup.visible)
		var labels := popup.find_children("*", "Label", false, false)
		assert_eq(labels.size(), 1)
		if labels.size() == 1:
			assert_eq(labels[0].text, expected)


func test_warning_hover_displays_new_text_on_buttons_and_labels() -> void:
	for control in [Button.new(), Label.new()]:
		control.text = "Movement"
		var viewport := _warning_input_viewport(control)
		var warning := control.get_node("UnusedFeatureWarning") as Control
		for light_mode in [false, true, false]:
			EditorThemes.apply(light_mode)
			await wait_process_frames(2)
			await _assert_hover_tooltip(viewport, warning, "This feature is not fully implemented yet.")
			# Moving off the triangle must still show the feature description.
			_move_mouse(viewport, Vector2(41, 41))
			await wait_process_frames(2)
			await _assert_hover_tooltip(viewport, control, EditorTooltips.get_tooltip("unit", "movement_type"))
		viewport.queue_free()
		await wait_process_frames(2)


func test_clicking_warning_activates_parent_button_exactly_once() -> void:
	var button := Button.new()
	button.text = "Movement"
	var viewport := _warning_input_viewport(button)
	var warning := button.get_node("UnusedFeatureWarning") as Control
	watch_signals(button)
	var clicks := 0
	for light_mode in [false, true, false]:
		EditorThemes.apply(light_mode)
		await wait_process_frames(2)
		var point := warning.get_global_rect().get_center()
		assert_true(button.get_global_rect().has_point(point))
		_move_mouse(viewport, point)
		viewport.push_input(GutInputFactory.mouse_left_button_down(point, point), true)
		assert_signal_emit_count(button, "pressed", clicks, "Default buttons activate on release")
		assert_true(button.is_pressed(), "The parent button must receive the press")
		viewport.push_input(GutInputFactory.mouse_left_button_up(point, point), true)
		await wait_process_frames(2)
		clicks += 1
		assert_signal_emit_count(button, "pressed", clicks, "One activation per click on the triangle")
		assert_false(button.is_pressed())


func test_warning_button_dark_to_light() -> void:
	await _check_warning_theme_switches([false, true])


func test_warning_button_light_to_dark() -> void:
	await _check_warning_theme_switches([true, false])


func test_warning_button_repeated_theme_switches_keep_padding() -> void:
	await _check_warning_theme_switches([false, true, false, true, false])


func test_warning_button_preserves_theme_variation() -> void:
	await _check_warning_theme_switches([false, true, false], &"PrimaryButton")


func test_warning_button_apply_is_idempotent() -> void:
	var button := _themed_button()
	var original := _themed_button()
	var initial_connections := button.theme_changed.get_connections().size()
	TooltipHelper.apply(button, "unit", "movement_type")
	var connections := button.theme_changed.get_connections().size()
	assert_eq(connections, initial_connections + 1)
	TooltipHelper.apply(button, "unit", "movement_type")
	assert_eq(button.theme_changed.get_connections().size(), connections)
	var warnings := button.find_children("UnusedFeatureWarning", "", false, false)
	assert_eq(warnings.size(), 1)
	_assert_warning_styles(button, original)
	for mode in [true, false]:
		EditorThemes.apply(mode)
		await wait_process_frames(2)
		_assert_warning_styles(button, original)
		assert_eq(button.theme_changed.get_connections().size(), connections)


func test_ordinary_button_keeps_theme_styles_and_padding() -> void:
	var button := _themed_button()
	TooltipHelper.apply(button, "unit", "health")
	assert_false(button.has_node("UnusedFeatureWarning"))
	assert_eq(button.tooltip_text, EditorTooltips.get_tooltip("unit", "health"))
	for mode in [false, true, false]:
		EditorThemes.apply(mode)
		await wait_process_frames(2)
		for state in BUTTON_STATES:
			assert_false(button.has_theme_stylebox_override(state), state)
			assert_same(button.get_theme_stylebox(state), EditorThemes.ACTIVE.get_stylebox(state, "Button"), state)


func test_warning_button_coalesces_theme_changes() -> void:
	var button := _themed_button()
	var original := _themed_button()
	TooltipHelper.apply(button, "unit", "movement_type")
	await wait_process_frames(2)
	var before := button.get_theme_stylebox("normal")
	for mode in [true, false, true]:
		EditorThemes.apply(mode)
	assert_same(button.get_theme_stylebox("normal"), before, "Refresh waits for the completed theme")
	await wait_process_frames(2)
	_assert_warning_styles(button, original)
	var settled := button.get_theme_stylebox("normal")
	await wait_process_frames(2)
	assert_same(button.get_theme_stylebox("normal"), settled)


func test_warning_button_freed_before_deferred_refresh() -> void:
	var button := Button.new()
	button.theme = EditorThemes.ACTIVE
	add_child(button)
	TooltipHelper.apply(button, "unit", "movement_type")
	EditorThemes.apply(true)
	button.free()
	await wait_process_frames(2)
	# GUT's error tracking also catches invalid deferred calls.
	assert_false(is_instance_valid(button))

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
	assert_eq(count, 91)
	assert_eq(warnings, 14)
	assert_eq(EditorTooltips.WARNING_TEXT, "This feature is not fully implemented yet.")
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
	assert_eq(EditorTooltips.WARNINGS, {"unit": ["movement_type", "capturable", "victory_points", "perception", "is_producible_unit", "actions", "attack_range", "production_cost", "producible_units_add"], "map": ["tile.hiding", "tactical_map"], "painter": ["crop_image"], "tactical_library": ["tactical_map"], "game_painter": ["settings"]})


func test_save_tooltips_follow_map_mode() -> void:
	var editor = load("res://editor/editors/map_editor_refactor/map_editor.tscn").instantiate()
	var popup = load("res://editor/editors/map_editor_refactor/popup_windows/save_name_popup.tscn").instantiate()
	add_child_autofree(editor)
	add_child_autofree(popup)
	var name_label = popup.get_node("EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/Label")
	for context in ["map", "tactical", "map"]:
		popup.set_tooltip_context(context)
		assert_eq(editor._save_button.tooltip_text, EditorTooltips.get_tooltip(context, "save_map"))
		assert_eq(name_label.tooltip_text, EditorTooltips.get_tooltip(context, "save_name"))
		assert_eq(popup._save_button.tooltip_text, EditorTooltips.get_tooltip(context, "save_name_confirm"))
		assert_false(editor._save_button.has_node("UnusedFeatureWarning"))
		editor._change_map_mode()


func test_game_settings_warning_and_context_stay_in_popup() -> void:
	var editor = load("res://editor/editors/game_editor/GameEditor.tscn").instantiate()
	add_child_autofree(editor)
	var painter = editor._unit_painter
	assert_eq(painter.settings_tooltip_context, "game_painter")
	assert_eq(painter._settings_button.tooltip_text, EditorTooltips.get_tooltip("game_painter", "settings"))
	assert_true(painter._settings_button.has_node("UnusedFeatureWarning"))
	for context in ["map", painter.settings_tooltip_context]:
		var popup = load("res://editor/editors/map_editor_refactor/popup_windows/settings_popup.tscn").instantiate()
		add_child_autofree(popup)
		popup.tooltip_context = context
		var settings: Dictionary[String, Variant] = {"width": 10, "height": 10, "map_name": "Test"}
		popup.init(settings)
		var header = popup.get_node("EditorPanel/TopVBox/TopLabel")
		assert_eq(header.has_node("UnusedFeatureWarning"), context == "game_painter")
		var rows = popup.get_node("EditorPanel/TopVBox/ScrollContainer/ContentsVBox/SettingsVbox")
		for row in rows.get_children():
			var label = row.get_child(0)
			assert_eq(label.tooltip_text, EditorTooltips.get_tooltip(context, label.text))
			assert_false(label.has_node("UnusedFeatureWarning"))
		assert_eq(popup._save_button.tooltip_text, EditorTooltips.get_tooltip("painter" if context == "map" else context, "settings_save"))
		assert_false(popup._save_button.has_node("UnusedFeatureWarning"))


func test_library_tooltips_use_item_kind() -> void:
	for kind in ["name", "tactical_map", "unit"]:
		var library = load("res://editor/editors/map_editor_refactor/user_interfaces/paint_library/paint_library.tscn").instantiate()
		add_child_autofree(library)
		var attributes: Dictionary[String, Variant] = {}
		library.init("Test", "texture", kind, attributes, attributes, 0, true)
		var context = {"name": "painter", "tactical_map": "tactical_library", "unit": "game_painter"}[kind]
		assert_eq(library._remove_button.tooltip_text, EditorTooltips.get_tooltip(context, "remove_library_tile"))
		assert_false(library._remove_button.has_node("UnusedFeatureWarning"))
		if kind == "tactical_map":
			assert_eq(library._new_button.tooltip_text, EditorTooltips.get_tooltip(context, "new_library_tile"))
			assert_false(library._new_button.has_node("UnusedFeatureWarning"))
			var item_data: Dictionary[String, Variant] = {"tactical_map": "Test", "texture": GradientTexture2D.new()}
			library._add_lib_item(item_data)
			var item = library._items[0]
			assert_eq(item.get_node("Label").tooltip_text, EditorTooltips.get_tooltip(context, "tactical_map"))
			assert_true(item.get_node("Label").has_node("UnusedFeatureWarning"))
			assert_eq(item.get_button().tooltip_text, EditorTooltips.get_tooltip(context, "tactical_map_thumbnail"))
			assert_false(item.get_button().has_node("UnusedFeatureWarning"))

func test_unit_description_has_no_added_label_or_tooltip() -> void:
	var panel = load("res://editor/editors/unit_editor/UnitInfoPanel.tscn").instantiate()
	add_child_autofree(panel)
	var row = panel.get_node("TopVBox/PanelContainer/ContentsVBox/HBoxContainer")
	assert_eq(row.get_child_count(), 2)
	assert_eq(panel.description_box.tooltip_text, "")
